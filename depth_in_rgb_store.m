% termite_build_analysis: extract depth data, convert to RGB frame, store
% as array of floats

% Check function: leave termites in

debug_check = input('Debug mode? (warning: slower) [N]', 's');
if isempty(debug_check)
    debug_flag = 0;
else
    debug_flag = 1;
end

% where to start
start_frame = input('Enter frame number of start: ','s');

current_frame = str2num(start_frame);

% check necessary parameters exist:
prefix_name = 'rgb';
termite_proc_input = input('Do you want use termite identification filtering on the RGB image? [] = no, other = yes ', 's');
if ~isempty(termite_proc_input)
    termite_proc_flag = 1;
else
    termite_proc_flag = 0;
end

param_precheck;
bg_flag = 0;

if exist('bg_frame', 'var')
    use_bg = input('Do you want to use background frame subtraction to eliminate steady-state noise? [] = no, other = yes ', 's');
    if ~isempty(use_bg)
        bg_flag = 1;
    end
else
    bg_stop = input('Warning: No background frame to subtract - results could be confounded with steady-state noise. Continue? [] = yes, other = no ', 's');
    if ~isempty(bg_stop)
        return
    end
end


average_frames = 1;

if debug_flag
    debug_fig = figure;
end

while current_frame < length(dispfiles)

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
    diskMask = rgb_filt_dat.dishMask;
    currentRGB = rgb_filt_dat.currentRGB;
    bwMask = rgb_filt_dat.bwMask;
    
    % read in current depth image:
    cd(depthdir);
    depthname = dispfiles(current_frame).name;
    cd('../');
    
    % Depth processing
    [depthmap_raw, dStruct] = termite_depth_extraction(depthname, calibStruct, plate_om, plate_tc, alpha_vec, depth_error, dmin_th, dmax_th);

     % Calculate masking area from RGB
    DepthCircMask = calc_depth_mask(bwMask, calibStruct, plate_tc, depth_est);
        
    depthmap = depthmap_raw;
    
    if bg_flag
        depthmap = depthmap - bg_frame;
    end
        
    % Convert to RGB coordinates
    rgbsize = size(currentRGB);
    rgb_depth = depth2rgbpix(depthmap, calibStruct, plate_om, plate_tc, dStruct, rgbsize);
    store_current_frame('rgbdepth_raw_', storedir, current_frame, rgb_depth);
 
    % apply noise mask (if data exists) and store
    if exist('noiseMask', 'var')
        depthmap_noise_rem = depthmap;
        depthmap_noise_rem(noiseMask > 0 ) = NaN;
        rgb_depth_nonoise = depth2rgbpix(depthmap_noise_rem, calibStruct, plate_om, plate_tc, dStruct, rgbsize);
        store_current_frame('rgbdepth_nonoise_', storedir, current_frame, rgb_depth_nonoise);    
    end
          
    % store frames
    
    % update current frame number
    current_frame = current_frame + 1;
    
    % if debug: display output

    % four plots: 1) RGB 2) BW filtered RGB 3) raw depth 4) depth to store
    if debug_flag
        figure(debug_fig);
        subplot(2,2,1); imshow(currentRGB);
        subplot(2,2,2); showDepth(depthmap, DepthCircMask, dmin_th, dmax_th);
        subplot(2,2,3); mesh(rgb_depth); view(0,-90);
        subplot(2,2,4); showDepth(depthmap_noise_rem, DepthCircMask, dmin_th, dmax_th);
        drawnow;
    end
    
    clear frameDat;
    
end

% clean up parameters that aren't needed or may need resetting
clear bw_debug 
clear fw_frame
clear timefilt_flag
clear depthmap_raw
clear depthmap_noterm
clear rgb_depth
clear rgb_depth_nonoise

% ... PROBABLY MORE