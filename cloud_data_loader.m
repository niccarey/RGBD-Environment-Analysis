% Can be run with a single command. 
addpath('../CloudScripts');

% Requires a parameter file
% (cloud_param_set.m) and the following scripts in the same folder:

test_files = min(min([exist('termite_rgb_preprocess', 'file'), exist('termite_rgb_localisation', 'file'), ...
    exist('termite_depth_extraction', 'file'), exist('termite_depth_localisation', 'file'), ...
    exist('calc_depth_mask', 'file'), exist('soil_identifier', 'file'), exist('load_prev_frames', 'file'), ...
    exist('persistence_filter', 'file')]));

if ~test_files
    disp('One or more required functions missing');
    return
end


% load cloud_param_set and check for necessary files. If something is
% missing, immediately throw an error.

if ~(exist('cloud_param_set.mat', 'file'))
    disp('Parameter file missing');
    return
end

load('cloud_param_set.mat', '-mat');

disp('Please select a directory of rgb images.')
rgb_loader;

disp('Please select a directory of depth images.')
depth_loader;

% set up the following directories:
% - a directory for raw depth data
disp('Please select a directory to store the raw rectified depth images.')
    raw_storedir = uigetdir;

    % - a directory for extracted depth info

disp('Please select a directory to store the filtered depth images.')
    dext_storedir = uigetdir;

% - a directory for depth info with background removed

disp('Please select a directory to store the depth with background subtraction.')
    bgrem_storedir = uigetdir;

% - a directory for rgb_overlay files

disp('Please select a directory to store the rgb overlay images.')
    rgb_storedir = uigetdir;

    % Cloud data
disp('Please select a directory to store the point cloud images.')
    cloud_storedir = uigetdir;
    
    prefix_name = '';

    disp('Create/select a folder and file to store soil movement data')
    [data_file, soil_storedir] = uiputfile;    
    
    prefix_name = '';

required_params = min(min([exist('template_mean', 'var'), exist('current_frame', 'var'), ...
    exist('tlength', 'var'), exist('depth_est', 'var'), exist('imwidth', 'var'), exist('imheight', 'var'), ...
    exist('dext_storedir', 'var'), exist('bgrem_storedir', 'var'), exist('rgb_storedir', 'var'), ...
    exist('raw_storedir', 'var'), exist('soil_storedir', 'var'), exist('bfill_param', 'var'), ...
    exist('cloud_storedir', 'var')]));


if ~required_params
    disp('One or more required parameters missing');
    return
end

% re-store parameters
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

param_store.soil_storedir = soil_storedir;
param_store.rgb_storedir = rgb_storedir;
param_store.bgrem_storedir = bgrem_storedir;
param_store.dext_storedir = dext_storedir;
param_store.raw_storedir = raw_storedir;
param_store.cloud_storedir = cloud_storedir;

save(fullfile(preload_storefolder, 'cloud_param_set.mat'), '-struct', 'param_store');

% Store current_frame separately in case of crashes
save(fullfile(preload_storefolder, 'cframe.mat'), 'current_frame');

%termite_build_cloudscript;