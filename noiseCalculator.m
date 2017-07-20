% termite_build_analysis: analyse frames for spiking noise 

% First, store a frame sequence for later analysis (same as
% bg_frame_create)

debug_check = input('Debug mode? (warning: slower) [N]/y = anything ', 's');
if isempty(debug_check)
    debug_flag = 0;
else
    debug_flag = 1;
end

% enter duration (note that killing the script before ending will still
% result in a background object)

start_frame = input('Enter frame number of start: ','s');
end_frame = input('Enter frame number of end: ','s');

current_frame = str2num(start_frame);
final_frame = str2num(end_frame);

% check necessary parameters exist:
% -- run a 'check inputs' function? how flexible do we need this to be?
termite_proc_flag = 1;
param_precheck;

% ask about persistence filter
timefilt_input = input('Use persistence filter? [N]/other ', 's');
if isempty(timefilt_input)
    timefilt_flag = 0;
    fw_frame = 0;
else
    timefilt_flag = 1;
    if ~exist('fw_frame', 'var')
        fw_frame = input('Enter persistence frame parameter: ');
    end
end
clear timefilt_input

% ask about averaging filter
average_frames = input('Number of frames to average over? [default = 1] ');
if isempty(average_frames)
    average_frames = 1;
end

if debug_flag
    debug_fig = figure;
end
    
% find extremes of DepthCircMask
%depthmask_stats = regionprops('table', DepthCircMask, 'BoundingBox');
%bb_dets = depthmask_stats.BoundingBox;
%cropymin = floor(bb_dets(1));
%if cropymin == 0
%    cropymin = 1;
%end
%cropxmin = floor(bb_dets(2));
%if cropxmin == 0
%    cropxmin = 1;
%end


%cropymax = cropymin + bb_dets(3);
%cropxmax = cropxmin + bb_dets(4);
noiseSeq.frames = [];

while current_frame < final_frame

    % read in current rgb image:
    cd(rgbdir);
    if length(rgbfiles) < current_frame
        disp('Reached end of file list');
        break
    end
    imname = rgbfiles(current_frame).name;
    cd('../');
    
    % RGB preparation:
    rgb_filt_dat = termite_rgb_preprocess(imname, dish_thresh, rgb_preproc, imwidth, imheight);
    dishMask = rgb_filt_dat.dishMasked;
    currentRGB = rgb_filt_dat.currentRGB;
    bwMask = rgb_filt_dat.bwMask;
    
    % Termite location:
    [tCent, tRad, bw_debug] = termite_rgb_localisation(termite_thresh, currentRGB, bfill_param, tlength);
    
    % read in current depth image:
    cd(depthdir);
    depthname = dispfiles(current_frame).name;
    cd('../');
    
    % Depth processing
    [depthmap_raw, dStruct] = termite_depth_extraction(depthname, calibStruct, plate_om, plate_tc, alpha_vec, depth_error, dmin_th, dmax_th);
    t_depthLoc = termite_depth_localisation(tCent, calibStruct, depth_est);
    
    % Calculate masking area from RGB
    DepthCircMask = calc_depth_mask(bwMask, calibStruct, plate_tc, depth_est);
    
    % remove termites from depth frame
    depthmap_noterm = termite_removal(t_depthLoc, depthmap_raw, DepthCircMask);
    
    % If frame data exists in workspace, load depthmap? probably not really
    % necessary, presumably if I'm running a sequence again it's for a good
    % reason
    
    % Load (average frames) previous files. 
    if (current_frame > 1)
        frameDat = load_prev_frames(prefix_name, storedir, average_frames, current_frame);
    end
    
    % store, then clear current. frameDat should only contain at most (average
    % frames) number of frames at any one time.
    if current_frame < 2
        depthmap = depthmap_noterm;
    else 
        if timefilt_flag 
            depthmap = persistence_filter(depthmap_noterm, dispfiles, fw_frame, current_frame, average_frames, frameDat, calibStruct, plate_om, plate_tc, alpha_vec, depth_error, dmin_th, dmax_th);
        else
            % don't average if not using persistence filter - end up with too
            % many residual termite bits. Just fill with previous data.
            depthmap = no_filt_update(current_frame, depthmap_noterm, frameDat);
        end
    end
    
    % return current depthmap as a frame to store for noise analysis
    % purposes
    % crop each frame to minimize vector length
    % If not already stored in memory 
    checkfile = [storedir '/' prefix_name 'depth_frame_' num2str(current_frame, '%04d')];
    if ~exist(checkfile, 'file')
        store_current_frame([prefix_name 'depth_frame_'], storedir, current_frame, depthmap);
    end
    
    noiseSeq.frames = cat(3, noiseSeq.frames, depthmap);
    %eval(['noiseSeq.storeframe_' num2str(current_frame) '= depthmap;']);
    % update current frame number
    current_frame = current_frame + 1;
    
    % if debug: display output
    % four plots: 1) RGB 2) BW filtered RGB 3) raw depth 4) depth to store
    if debug_flag
        figure(debug_fig);
        subplot(2,2,1); imshow(currentRGB);
        subplot(2,2,2); imshow(bw_debug);
        subplot(2,2,3); mesh(depthmap_raw); view(0,90); plotCentroids(t_depthLoc, DepthCircMask);
        subplot(2,2,4); showDepth(depthmap, DepthCircMask, dmin_th, dmax_th);
        drawnow;
    end
    
    clear frameDat;
    
end

size(noiseSeq.frames)

% Examine noise sequence:
noise_sequence = cat(3, noiseSeq.frames);

% create a noise variance matrix across all pixel positions
sigSize = size(noise_sequence);
noisevar = zeros(sigSize(1), sigSize(2));

for ic = 1:sigSize(1)
    for jc = 1:sigSize(2)
        noisePix = noise_sequence(ic, jc, :);
        noisePix = squeeze(noisePix);
        
        noisevar(ic,jc) = var(noisePix, 'omitnan');
    end
end

% display

%nvarcrop = noisevar(cropxmin:cropxmax, cropymin:cropymax);
%cap output
%nvarcrop(nvarcrop>10) = 10;
figure; surf(noisevar, 'EdgeColor', 'none'); colorbar

% Get a threshold as input
noise_thresh = input('Enter noise variance threshold value');

% assign pixels to noise mask based on variance threshold
noiseMask = zeros(size(depthmap));
noiseMask(noisevar > noise_thresh) = 1;

figure; imshow(noiseMask);

% clean up parameters that aren't needed or may need resetting
clear bw_debug 
clear fw_frame
clear timefilt_flag
clear noisevar
clear noisePix
clear noise_sequence
clear storedir
% ... PROBABLY MORE