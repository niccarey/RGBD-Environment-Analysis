% Pre-cloud preparation script for Termite Build Analysis

% run param_precheck to set up some basic stuff
termite_proc_flag = 1;
param_precheck;

prefix_name = '';

% Generate a background frame
disp('Creating a background frame ...')
if ~exist('bg_frame', 'var')
    bg_frame_create;
end

% Generate a noise pixel map, decide which sequences we want to remove
% noisy pixels from:
disp('Creating noise mask ...');
if ~exist('noiseMask', 'var')
    noiseCalculator;
end

disp('Generate a template for automatic termite detection');

% Calculate a termite template (if none exists)
if ~exist('template_mean', 'var')
    termite_volume_estimate;
end

% Set start frame
start_frame = input('Enter frame number to start cloud analysis: ','s');
current_frame = str2num(start_frame);

disp('Cloud analysis filtering parameters ...');
% depth extraction and soil movement require averaging filter:
average_frames = input('Number of frames to average over? [default = 1] ');
if isempty(average_frames)
    average_frames = 1;
end

if ~exist('fw_frame', 'var')
    fw_frame = input('Enter persistence frame parameter: ');
end

prefix_name = '';

% save ALL flags and parameters


disp('Select location to save parameter file');
preload_storefolder = uigetdir('./');

param_store.rgbdir = rgbdir;
param_store.rgbfiles = rgbfiles;
param_store.depthdir = depthdir;
param_store.dispfiles = dispfiles;
param_store.rgb_preproc = rgb_preproc;
param_store.dish_thresh = dish_thresh;
param_store.depth_est = depth_est;
param_store.soil_height = soil_height;
param_store.termite_thresh = termite_thresh;
param_store.alpha0 = alpha0;
param_store.alpha1 = alpha1;
param_store.alpha_vec = alpha_vec;
param_store.calibStruct = calibStruct;
param_store.plate_om = plate_om;
param_store.plate_tc = plate_tc;
param_store.depth_error = depth_error;
param_store.bg_frame = bg_frame;
param_store.template_mean = template_mean;
param_store.dmin_th = dmin_th;
param_store.dmax_th = dmax_th;
param_store.current_frame = current_frame;
param_store.fw_frame = fw_frame;
param_store.average_frames = average_frames;
param_store.template_mean = template_mean;
param_store.noiseMask = noiseMask;
param_store.termite_proc_flag = termite_proc_flag;
param_store.tlength = tlength;
param_store.imwidth = imwidth;
param_store.imheight = imheight;
param_store.bfill_param = bfill_param;
param_store.prefix_name = prefix_name;



save(fullfile(preload_storefolder, 'cloud_param_set.mat'), '-struct', 'param_store');
