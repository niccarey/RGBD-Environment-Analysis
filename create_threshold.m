function[] = create_threshold()

% select file
disp('Select RGB image to base threshold on');
[threshfile, folder] = uigetfile('*.jpg');
thresh_im = imread(fullfile(folder, threshfile));

% select RGB preset values
load_preproc = input('Use rgb preprocessing? [] = no, other = yes ', 's');
if ~isempty(load_preproc)
    rgb_pre = input('Enter image adjustment matrix ([r g b; r g b]): ');
    thresh_im = imadjust( thresh_im, rgb_pre, [] );
end

% open colourThresholder
colorThresholder(thresh_im);