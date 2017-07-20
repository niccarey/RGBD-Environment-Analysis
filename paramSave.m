% what do we need to save?
% anything in param_check, primarily

[param_file, save_folder] = uiputfile;

% termite_build_analysis: 
% script to ensure we have necessary parameters and thresholding functions, etc

if exist('rgbdir', 'var')
    param_store.rgbdir = rgbdir;
    param_store.rgbfiles = rgbfiles;
end

if exist('depthdir', 'var')
    param_store.depthdir = depthdir;
    param_store.dispfiles = dispfiles;
end

if exist('storedir', 'var')
    param_store.storedir = storedir;
end


if exist('store_cloud_dir', 'var')
    param_store.store_cloud_dir =store_cloud_dir;
end

if exist('rgb_preproc', 'var')
   param_store.rgb_preproc = rgb_preproc;
end

if exist('dish_thresh', 'var')
    param_store.dish_thresh = dish_thresh;
end

if exist('depth_est', 'var')
    param_store.depth_est = depth_est;
end

if exist('soil_height', 'var')
    param_store.soil_height = soil_height;
end

if exist('termite_thresh', 'var')
    param_store.termite_thresh = termite_thresh;
end

if exist('alpha0', 'var')
    param_store.alpha0 = alpha0;
end

if exist('alpha1', 'var')
    param_store.alpha1 = alpha1;
end

if exist('alpha_vec', 'var')
    param_store.alpha_vec = alpha_vec;
end

if exist('calibStruct', 'var')
    param_store.calibStruct = calibStruct;
end

if exist('plate_om', 'var')
    param_store.plate_om = plate_om;
end

if exist('plate_tc', 'var')
    param_store.plate_tc = plate_tc;
end

%if exist('DepthCircMask', 'var')
%    param_store.DepthCircMask = DepthCircMask;
%end

if exist('depth_error', 'var')
    param_store.depth_error = depth_error;
end

if exist('bg_frame', 'var')
    param_store.bg_frame = bg_frame;
end

if exist('template_mean', 'var')
    param_store.template_mean = template_mean;
end


if exist('dmin_th', 'var')
    param_store.dmin_th = dmin_th;
end

if exist('dmax_th', 'var')
    param_store.dmax_th = dmax_th;
end


if exist('rempos_plot', 'var')
    param_store.rempos_plot = rempos_plot;
end

if exist('remneg_plot', 'var')
    param_store.remneg_plot = remneg_plot;
end

if exist('soilvol', 'var')
    param_store.remneg_plot = soilvol;
end


save(fullfile(save_folder, param_file), '-struct', 'param_store');
