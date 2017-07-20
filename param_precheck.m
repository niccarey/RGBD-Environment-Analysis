% termite_build_analysis: 
% script to ensure we have necessary parameters and thresholding functions, etc

if ~exist('rgbdir', 'var')
    % this should already have existed?
    disp('Please select a directory of rgb images.')
    rgb_loader;
end

if ~exist('depthdir', 'var')
    % this should already have existed?
    disp('Please select a directory of depth images.')
    depth_loader;
end

disp('Please select a directory to store data');
storedir = uigetdir;

prefix_name = input('Please input a prefix string for this set of data: ', 's');

if ~exist('rgb_preproc', 'var')
    disp('Using default image filtering parameters, adjust RGB filter to change') 
    rgb_preproc = [0 0 0 ; 1 1 1];
end

if ~exist('imheight', 'var')
    temp_rgb =imread(fullfile(rgbdir, rgbfiles(1).name));
    imsize = size(temp_rgb);
    imheight = imsize(1);
    imwidth = imsize(2);
    clear imsize;
    clear temp_rgb;
end

col_correct = input('Colour correct RGB? [] = N, other = Y ', 's');
if ~isempty(col_correct)
    rgb_o_sliders;
    col_correct_flag = 1;
end


if imwidth > 1000
    bfill_param = 350;
    tlength = 90;
else
    bfill_param = 100;
    tlength = 34;
end

if termite_proc_flag
    if ~exist('dish_thresh', 'var')
        disp('Please create or load a dish thresholding function');
        choosefile = input('Do you want to choose an existing dish thresholding function y/n? [Y] ', 's');
        if (isempty(choosefile) || (choosefile == 'y'))
            dish_thresh_file = uigetfile;
            [~, dish_thresh, ~] = fileparts(dish_thresh_file);        
            clear dish_thresh_file;
        else
            thresh_str = input('Enter an image number to use as basis for dish detection: ');
            thresh_num = str2num(thresh_str);
            temp_rgb = imread(fullfile(rgbfir, rgbfiles(thresh_num).name));
            disp('Please export resulting mask as Function, save .m file, and choose file at the prompt')
            hg = colorThresholder(temp_rgb);
            while isgraphics(hg)
                pause(0.1)
            end
            dishThresholding;
            clear temp_rgb;
            clear thresh_str;
            clear thresh_num;
            clear hg;
        end    
        clear choosefile
    end
    if ~exist('termite_thresh', 'var')
        disp('Please create or load a termite detection function');
        choosefile = input('Do you want to choose an existing function y/n? [Y] ', 's');
        if (isempty(choosefile) || (choosefile == 'y'))
            term_thresh_file = uigetfile;
            [~, termite_thresh, ~] = fileparts(term_thresh_file);
            clear term_thresh_file;
        else
            thresh_str = input('Enter an image name to use as basis for termite detection: ');
            thresh_num = str2num(thresh_str);
           temp_rgb = imread(fullfile(rgbfir, rgbfiles(thresh_num).name));
            % filter rgb according to preproc params
            temp_rgb2 = imadjust(temp_rgb, rgb_preproc ,[]);
            hg = colorThresholder(temp_rgb2);
            disp('Please export resulting mask as Function, save .m file, and choose file at the prompt');
            while isgraphics(hg)
                pause(0.1)
            end
            select_threshold;
            clear temp_rgb;
            clear thresh_str;
            clear thresh_num;
        end    
        clear choosefile
    end
end

if ~exist('alpha0', 'var')
    alpha_load;
end

if ~exist('calibStruct', 'var')
    calib_load;
end

if ~exist('soil_height', 'var')
    depth_mask_create;
end


if ~exist('plate_om', 'var')
    plate_data;
end

if ~exist('depth_error', 'var')
    % ask about error compensation
    depth_error_check = input('Do you want to include a steady-state depth error correction y/n? [Y]', 's');
    if (isempt(depth_error_check) || (depth_error_check == 'y'))
        loadErrorFile;
    else
        disp('You have chosen not to correct for steady-state depth error. \n If you wish to use error correction in the future, please run loadErrorFile.');
        depth_error = zeros(480,640);
    end
end

if ~exist('dmin_th', 'var')
    dmin_th = input('Enter minimum depth cutoff value (default = 0) ');
    if isempty(dmin_th)
        dmin_th = 0;
    end
    dmax_th = input('Enter maximum depth cutoff value (default = 30) ');
    if isempty(dmax_th)
        dmax_th = 30;
    end
end


    
