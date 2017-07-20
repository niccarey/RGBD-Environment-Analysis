function[ret_struct] = termite_rgb_preprocess(rgbfilename, dish_thresh, sliderparams, width, height)

rgb_im = imread(rgbfilename);

% identify dish area
dish_func = str2func(dish_thresh);
[BWblue, ~] = dish_func(rgb_im);
BWdishdetect = imfill(BWblue,4, 'holes');
dishStats = regionprops('table', BWdishdetect, 'Centroid', 'MajorAxisLength', 'MinorAxisLength');
imSize = size(rgb_im);
if imSize(1) > 1000
    ind = intersect(find(dishStats.MajorAxisLength > 630), find(dishStats.MinorAxisLength > 630));
else
    ind = intersect(find(dishStats.MajorAxisLength > 450), find(dishStats.MinorAxisLength > 450));
end

w = width; h = height;
centre_dish = dishStats.Centroid(ind,:);
dish_rad = (dishStats.MajorAxisLength(ind) + dishStats.MinorAxisLength(ind))/4;

% Create mask for dish area
cx = centre_dish(1); cy = centre_dish(2);

r = dish_rad;
[xmask, ymask] = meshgrid(-(cx-1):(w-cx), -(cy-1):(h-cy));
AMask = (((xmask/r).^2 + (ymask/r).^2) <= 1);
rgbMask = rgb_im;
rgbMask(repmat(~AMask, [1,1,3])) = NaN; % may wish to return rgbMask

rgb_adjusted = imadjust( rgbMask, sliderparams ,[]);

ret_struct.dishMasked = rgbMask;
ret_struct.currentRGB = rgb_adjusted;
ret_struct.bwMask = AMask;
ret_struct.drad = dish_rad;