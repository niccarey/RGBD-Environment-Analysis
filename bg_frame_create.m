% termite_build_analysis: create a background frame to use for subtraction.

% a lot of this is common to several functions, so probably can be
% streamlined.

debug_check = input('Debug mode? (warning: slower) [N]', 's');
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
    % We need to store data in a structure we can pass
    if current_frame > 1
        frameDat = load_prev_frames(prefix_name, storedir, average_frames, current_frame);
    end
    
    if current_frame < 2
        depthmap = depthmap_noterm;
    else 
        if timefilt_flag  % shouldn't need >1 condition but anyway
            depthmap = persistence_filter(depthmap_noterm, dispfiles, fw_frame, current_frame, average_frames, frameDat, calibStruct, plate_om, plate_tc, alpha_vec, depth_error, dmin_th, dmax_th);
        else
            % don't average if not using persistence filter - end up with too
            % many residual termite bits. Just fill with previous data.
            depthmap = no_filt_update(current_frame, depthmap_noterm);
        end
    end
    % Problem somewhere in here! NaNs are appearing (this should never
    % happen)
    
    % apply noise mask (if data exists)
    if exist('noiseMask', 'var')
        depthmap(noiseMask > 0 ) = NaN;
    end
    
    
    % return current depthmap as the background frame
    bg_frame = depthmap;
    % store frame 
    store_current_frame([prefix_name 'depth_frame_'], storedir, current_frame, depthmap);
    % eval(['frameDat.storeframe_' num2str(current_frame) '= depthmap;']);
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

figure; showDepth(depthmap, DepthCircMask, dmin_th, dmax_th);
% clean up parameters that aren't needed or may need resetting
clear bw_debug 
clear fw_frame
clear timefilt_flag
clear depthmap_raw
clear depthmap_noterm
% ... PROBABLY MORE