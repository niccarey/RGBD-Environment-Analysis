% Generate RGBD point-cloud

% need to check if actually want termite removal or not 

debug_check = input('Debug mode? (warning: slower) [N]', 's');
if isempty(debug_check)
    debug_flag = 0;
else
    debug_flag = 1;
end

% enter duration (note that killing the script before ending will still
% result in a background object)

start_frame = input('Enter frame number of start: ','s');
current_frame = str2num(start_frame);

% check necessary parameters exist:
termite_proc_input = input('Do you want use termite identification filtering on the RGB image? [] = no, other = yes ', 's');
if ~isempty(termite_proc_input)
    termite_proc_flag = 1;
else
    termite_proc_flag = 0;
end

bg_flag = 0;
col_correct_flag = 0;

param_precheck;

disp('Select a directory to store cloud data');
store_cloud_dir = uigetdir;

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

% ask about persistence filter
timefilt_input = input('Use persistence filter? [] = no, other = yes ', 's');
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

% noise elimination?
noiseflag = 0;
isnoise = input('Remove noisy pixels? [] = no, other = yes] ', 's');
if ~isempty(isnoise)
    noiseflag = 1;
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
    dishMask = rgb_filt_dat.dishMasked;
    bwMask = rgb_filt_dat.bwMask;
    
    if termite_proc_flag
        currentRGB = rgb_filt_dat.currentRGB;    
        % Termite location:
        [tCent, tRad, bw_debug] = termite_rgb_localisation(termite_thresh, currentRGB, bfill_param, tlength);
    else
        currentRGB = dishMask;
    end
    
    if (exist('rgb_overlay', 'var')) && col_correct_flag
        overlayRGB =  imadjust( dishMask, rgb_overlay ,[]);
    else
        overlayRGB = dishMask;
    end
    
    
    % read in current depth image:
    cd(depthdir);
    depthname = dispfiles(current_frame).name;
    cd('../');
    
    % Depth processing
    [depthmap_raw, dStruct] = termite_depth_extraction(depthname, calibStruct, plate_om, plate_tc, alpha_vec, depth_error, dmin_th, dmax_th);
    
    % Calculate masking area from RGB
    DepthCircMask = calc_depth_mask(bwMask, calibStruct, plate_tc, depth_est);
    
    if termite_proc_flag
        t_depthLoc = termite_depth_localisation(tCent, calibStruct, plate_om, plate_tc, depth_est);
    
        % remove termites from depth frame
        depthmap_noterm = termite_removal(t_depthLoc, depthmap_raw, DepthCircMask);
    else
        depthmap_noterm = depthmap;
    end
    
    
    if bg_flag
        depthmap_noterm = depthmap - bg_frame;
    end
    

    % We need to store data in a structure we can pass
    if current_frame > 1
        frameDat = load_prev_frames(storedir, average_frames, current_frame);
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
    
    % apply noise mask (if data exists)
    if (exist('noiseMask', 'var')) && noiseflag
        depthmap(noiseMask > 0 ) = NaN;
    end
    
    prevcloud = []; prev_mm_cloud = [];
    if current_frame > 1
        % load previous point cloud
        cloud_name = ['cloud_frame_' num2str(current_frame-1)];
        prev_3d_frame = load(cloud_name);
        prevcloud = prev_3d_frame.pxcloud;
        prev_mm_cloud = prev_3d_frame.mmcloud;
    end
    
    % call update_point_cloud 
    % we do NOT CARE about stuff outside the depth mask
    [pxcloud, mmcloud] = update_point_cloud(dStruct, depthmap, prevcloud, prev_mm_cloud, DepthCircMask);
    
    % Things look ok here
    
    % store frame
    store_current_frame([prefix_name '_depth_frame_'], storedir, current_frame, depthmap);    
    % store cloud
    store_cloud('cloud_frame_', store_cloud_dir, current_frame, pxcloud, mmcloud);

    
    % if debug: display output
    % Convert and save RGB in depth FoV, for overlay
    % Problem is happening here
    rgbmat = calc_rgb_overlay(mmcloud, calibStruct, plate_om, plate_tc, overlayRGB);
    
    % Store rgb overlay
    % Note that this could be weird if removing termites from depth frame -
    % you will see them in colour frame but have no volume.
    store_overlay('rgbover_frame_', store_cloud_dir, current_frame, rgbmat);
    
        % update current frame number
    current_frame = current_frame + 1;
    
    if debug_flag
    
        col_display = pointCloud([mmcloud(:,1), mmcloud(:,2), mmcloud(:,3)], 'Color', rgbmat);
        figure(debug_fig);
        subplot(2,2,1); imshow(currentRGB);
        subplot(2,2,2); imshow(bw_debug);
        subplot(2,2,3); showDepth(depthmap, DepthCircMask, dmin_th, dmax_th);
        subplot(2,2,4); pcshow(col_display); view(0,90);
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
clear pxcloud
clear mmcloud
clear prev_mm_cloud;
clear prev_cloud;
clear rgbmat;

% ... PROBABLY MORE