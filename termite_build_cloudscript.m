% cloud_build_analysis
addpath('../CloudScripts/');
addpath('../TOOLBOX_calib/');

% problem: entering/exiting directories with large files is a problem
% solution: use list more cleverly

% Load parameters
load('cloud_param_set.mat', '-mat');

% make sure folders are on matlab path
addpath(rgbdir);
addpath(depthdir);
addpath(bgrem_storedir);
addpath(cloud_storedir);
addpath(dext_storedir);
addpath(raw_storedir);
addpath(rgb_storedir);
addpath(soil_storedir);


% Load current frame
load('cframe.mat');
current_frame

% load pos_track, neg_track
if exist('soil_movement_data.mat', 'file')
    load('soil_movement_data.mat');
    postotal = sum(pos_track);
    negtotal = sum(neg_track);
else
pos_track = [];
neg_track = [];
postotal = 0;
negtotal = 0;
end

prefix_name = '';

% parallelisation DOES NOT HELP

while current_frame < length(dispfiles)+1
    tic
    if length(rgbfiles) < current_frame
        break
    end
    
    imname = [rgbdir '/' rgbfiles(current_frame).name];
    
    % Prepare RGB data:
    rgb_filt_dat = termite_rgb_preprocess(imname, dish_thresh, rgb_preproc, imwidth, imheight);
    dishMask = rgb_filt_dat.dishMasked;
    currentRGB = rgb_filt_dat.currentRGB;
    bwMask = rgb_filt_dat.bwMask;
    if (exist('rgb_overlay', 'var'))
        overlayRGB =  imadjust( dishMask, rgb_overlay ,[]);
    else
        overlayRGB = dishMask;
    end
    
    % Termite location:
    [tCent, tRad, bw_debug] = termite_rgb_localisation(termite_thresh, currentRGB, bfill_param, tlength);
    
    % read in current depth image:
    depthname = [depthdir '/' dispfiles(current_frame).name];
    
    % Depth processing
    [depthmap_raw, dStruct] = termite_depth_extraction(depthname, calibStruct, plate_om, plate_tc, alpha_vec, depth_error, dmin_th, dmax_th);
    t_depthLoc = termite_depth_localisation(tCent, calibStruct, depth_est);
    
    % Calculate masking area from RGB
    DepthCircMask = calc_depth_mask(bwMask, calibStruct, plate_tc, depth_est);
    
    % Change to an rgb->depth pixel-based termite finder - scoops up
    % less soil. May need to rotate template, though.
    
    depthmap_noterm = soil_identifier(bwMask, bw_debug, calibStruct, depth_est, depthmap_raw, template_mean);
    
    % Cruder method - identify termite, remove raised points. Can be
    % problematic.
    %depthmap_noterm = termite_removal(t_depthLoc, depthmap_raw, DepthCircMask);
    
    if current_frame > 1
        frameDat = load_prev_frames(prefix_name, dext_storedir, average_frames, current_frame);
    end
    
    depthmap_noterm_bgrem = depthmap_noterm - bg_frame;
    
    if current_frame < 2
        depthmap = depthmap_noterm;
        depthmap_bgrem = depthmap_noterm_bgrem;
        % initialize soil movement data
        postotal = 0;
        pos_track = [];
        negtotal = 0;
        neg_track = [];
    else
        disp('entering persistence filter');
        depthmap = persistence_filter(depthmap_noterm, dispfiles, fw_frame, current_frame, average_frames, frameDat, calibStruct, plate_om, plate_tc, alpha_vec, depth_error, dmin_th, dmax_th);
        depthmap_bgrem = persistence_filter(depthmap_noterm_bgrem, dispfiles, fw_frame, current_frame, average_frames, frameDat, calibStruct, plate_om, plate_tc, alpha_vec, depth_error, dmin_th, dmax_th);
        eval(['prevdepth = frameDat.storeframe_' num2str(current_frame-1) ';']);
    end
    
    % use depthmap_bgrem for soil movement analysis
    
    % Previously, we integrated over depth changes. With continuous data,
    % we can be more delicate:
    
    prevcloud = []; prev_mm_cloud = [];
    
        % Set pixels unchanged from previous frame to zero
    if current_frame > 1
        
        disp('entering soil removal')
        new_pix = depthmap_bgrem - prevdepth;
        
        % Try and get rid of noise and irrelevant data:
        new_pix(abs(new_pix)<0.35) = NaN; % threshold at noise level
        new_pix(~DepthCircMask) = NaN;
        if (exist('noiseMask', 'var'))
            depthmap(noiseMask > 0 ) = NaN;
            new_pix(noiseMask > 0 ) = NaN;
        end
        
            % remaining non-zero pixels must be build or excavation
            
            % Build:
            pos_pix = new_pix;
            pos_pix(pos_pix<0) = NaN;
            % Continuous build: can integrate
            pos_cont_ind = find(pos_pix <= 1.0);
            possum_c = sum(sum(pos_pix(pos_cont_ind), 'omitnan'));
            % discontinuous build: represents a likely ceiling or tunnel
            pos_disc_ind = find(pos_pix > 1.0);
            possum_d = length(pos_disc_ind); % assume 1mm build height for each pellet (this is fairly representative)
            % running total displacement:
            postotal = postotal + possum_c + possum_d;
            
            % Excavation: (we can assume continuous)
            neg_pix = new_pix;
            neg_pix(neg_pix>0) = NaN;
            negsum = sum(sum(neg_pix, 'omitnan'));
            % Note that we cannot track any digging taking place after a tunnel
            % ceiling is in place
            negtotal = negtotal + negsum;
            
            % store volumes
            pos_track(current_frame) = postotal;
            neg_track(current_frame) = negtotal;

        % store new pixel frame data
        store_current_frame('soil_move_frame', soil_storedir, current_frame, new_pix);

        if mod(current_frame,30) < 1
            % Point cloud calculation:
            prevcloud = []; prev_mm_cloud = [];
        
            % load previous point cloud
            cloud_name = [cloud_storedir '/cloud_frame_' num2str(current_frame-30, '%06d')];
            prev_3d_frame = load(cloud_name);
            prevcloud = prev_3d_frame.pxcloud;
            prev_mm_cloud = prev_3d_frame.mmcloud;
        end
    end
    
    % call update_point_cloud
    % we do NOT CARE about stuff outside the depth mask

    if mod(current_frame,30) < 1   
        disp('storing cloud frame');
        mod(current_frame,30)
        [pxcloud, mmcloud] = update_point_cloud(dStruct, depthmap, prevcloud, prev_mm_cloud, DepthCircMask);
    
        % store cloud
        store_cloud('cloud_frame_', cloud_storedir, current_frame, pxcloud, mmcloud);    
    
        % Convert and save RGB in depth FoV, for overlay
        rgbmat = calc_rgb_overlay(mmcloud, calibStruct, plate_om, plate_tc, overlayRGB);
    
        % Store rgb overlay
        % Note that this could be weird if removing termites from depth frame -
        % you will see them in colour frame but have no volume.
        store_overlay('rgbover_frame_', rgb_storedir, current_frame, rgbmat);
    end
    
    % store raw rectified image, no termite removal
    store_current_frame('raw_depth_frame', raw_storedir, current_frame, depthmap_raw);
    % store depthmap (soil, averaged, no termites)
    store_current_frame('depth_frame_', dext_storedir, current_frame, depthmap);
    % store frame with background removed
    store_current_frame('bg_depth_frame_', bgrem_storedir, current_frame, depthmap_bgrem);
    
    toc
    current_frame = current_frame+1;
    % store current frame
    save('cframe.mat', 'current_frame');
    data_store.pos_track = pos_track;
    data_store.neg_track = neg_track;
    
    % anything else

    save('soil_movement_data.mat', '-struct', 'data_store');
end
    

% store non-frame data:
