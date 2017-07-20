% Termite_build_analysis has similar functionality to BuildExtractGUI but
% is more streamlined and less memory intensive.
%
% You will need:
% - a stereo calibration file containing RGB and depth camera stereo data
% (see Calib_Results_stereo in RS1 Calib Data)
% - the precise depth/disparity mapping for the depth camera
% (see DepthDisparityMapping in RS1 Calib Data)
% - the plate rotation (plate_om) and translation (plate_tc) vectors for
% the baseline of the filming arena
% (see DepthDisparityMapping in RS1 Calib Data for the calibration image
% number. Once Calib_Results_stereo has been loaded, call
% plate_om = calibStruct.omc_left_xx
% plate_tc = calibStruct.tc_left_xx
% where xx is the calibration image number)
%
% Optional but useful:
% - a residual depth error array, which removes any sensor tilt in the
% depth camera (load DepthError.mat in RS1 Calib Data)
% - a thresholding function to isolate the dish in the RGB array (example
% threshold function included, or define a new threshold from within the GUI)
% - a vector of RGB limits to use when processing the RGB image (can be
% constructed from within the GUI)
% - a thresholding function to isolate the termites (example function
% included, or define a new function from within the GUI)
% - a background frame (termites removed) which can be subtracted to remove
% any remaining steady-state errors in the depth. This can be constructed
% from within the GUI. Recommend running in debug mode so script can be
% killed when background frame has reached an optimal point.
% - an array mask identifying noisy pixels. This can also be constructed
% from within the GUI. Usually 300 frames is sufficient to identify noisy
% pixels.
%
% The script will ask you to create a mask for the depth image: if termites
% are not being removed from the depth, this is only useful for
% visualization purposes. It is defined by clicking three points on the
% outer rim of the region of interest.
%
% OUTPUT: two arrays the same size as the RGB images, containing projected
% and interpolated depth values for (1) the raw depth image and (2) the
% depth image with non-steady-state noise removed. Including a background
% subtraction step will remove steady-state noise from both arrays.
%
% These depth maps are ready to be overlaid on colour images with no
% further transformation needed. Use the mesh function with option 'CData'=
% rgb_image to view the RGBD output.
%
% Output options yet to be coded: 3D point cloud, depth projected to RGB
% camera frame, RGBD in depth camera frame. Coming soon!

% Create an interactive cell array
cell_list = {};
fig_num = 1;
title_figure = 'Extract termite build data';

cell_list{1,1} = {'Load RGB files', 'rgb_loader;'};
cell_list{1,2} = {'Load depth files', 'depth_loader;'};
cell_list{1,3} = {'Select calibration data', 'calib_load'};
cell_list{1,4} = {'Enter depth/disparity coefficients', 'alpha_load'};

cell_list{2,1} = {'Select dish thresholder', 'dishThresholding;'};
cell_list{2,2} = {'Load termite-locating thresholder', 'select_threshold;'};
cell_list{2,3} = {'Create a thresholding function', 'create_threshold;'};
cell_list{2,4} = {'Adjust RGB filter', 'rgb_sliders;'};

cell_list{3,1} = {'Load arena transform', 'plate_data;'};
cell_list{3,2} = {'Define soil depth', 'depth_mask_create;'};
cell_list{3,3} = {'Load (ss) depth error', 'loadErrorFile;'};
cell_list{3,4} = {'Load depth BG', 'loadBGFile;'};

cell_list{4,1} = {'Adjust overlay RGB display', 'rgb_o_sliders;'};
cell_list{4,2} = {'Create background frame', 'bg_frame_create;'};
cell_list{4,3} = {'Noise analysis', 'noiseCalculator;'};
cell_list{4,4} = {'Generate RGBD pointcloud', 'rgbdPointCloudExtraction;'};

cell_list{5,1} = {'Depth in RGB sequence', 'depth_in_rgb_store;'};
cell_list{5,2} = {'Rectified depth extraction', 'depth_extraction;'};
cell_list{5,3} = {'Termite volume estimation', 'termite_volume_estimate;'};
cell_list{5,4} = {'Soil movement analysis', 'soil_movement;'};

cell_list{6,4} = {'Create movie', 'create_movie'};


cell_list{7,1} = {'Save all parameters', 'paramSave'};
cell_list{7,2} = {'Load saved parameter file', 'paramLoad'};
cell_list{7,4} = {'Quit', 'close_all_windows'};

show_window(cell_list ,fig_num, title_figure, 289,18,0, 'clean');

