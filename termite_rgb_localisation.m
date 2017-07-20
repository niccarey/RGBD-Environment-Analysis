function[termiteCent, term_radius, BW_filled] = termite_rgb_localisation(termite_thresh, currentRGB, bwfillparam, termite_length)

%termite_func = str2func(termite_thresh);
[bwTermiteDetect, ~] = termite_thresh(currentRGB);

% dilate mask
se = strel('disk', 1);
BW_dilated = imdilate(bwTermiteDetect, se);

BW_filled = bwareaopen(BW_dilated, bwfillparam);

% locate centroids
termiteStats = regionprops('table', BW_filled, 'Centroid');
termiteCent = termiteStats.Centroid;

term_radius = (termite_length./2)*ones(length(termiteCent),1);
