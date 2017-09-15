function [soildata] = soil_identifier(bwMask, bw_term_map, calibStruct, depth_est, soildata, template_mean)

% Identify termite locations:

% Exclude pixels outside image mask
bw_term_map(bwMask<1) = 0;
[tpix_I, tpix_J] = find(bw_term_map>0);

% Get ALL termite pixels: bw_term_map-> termite_pix_loc
termite_pix_loc = termite_depth_localisation([tpix_J, tpix_I], calibStruct, depth_est);

% exclude pixels outside data range
termite_pix_loc(:,(termite_pix_loc(1,:) <= 0.5)) = [];

% create mask from termite_pix_loc
termite_bwmask = zeros(size(soildata));
termite_pix_loc = round(termite_pix_loc);

% masking using pixel location is always a bit shit
termite_pix_ind = sub2ind(size(termite_bwmask),termite_pix_loc(2,:), termite_pix_loc(1,:));
termite_bwmask(termite_pix_ind) = 1;
        
% There is very likely to be a fence ring around the projected
% image. Erode and dilate:
se = strel('line', 3,2);
term_erode = imerode(termite_bwmask, se);
term_dilate = imdilate(term_erode, se);

% fill holes
termite_bwmask = imfill(term_dilate, 'holes');

% identify discrete areas
termiteRegionInf = regionprops('table', termite_bwmask, 'Centroid', 'Area', 'Orientation');

for jj = 1:length(termiteRegionInf.Area)
    if termiteRegionInf.Area(jj) < 200
        % probably not a termite, ignore
        continue;
    else
        % accurate but complex way of doing this is to ID the
        % termite, rotate template to match, then subtract the
        % template pixels. 
        
        % Ignore scaling,
        
        % Rotate template to appropriate orientation:
        termite_orientation = termiteRegionInf.Orientation(jj);
        template_match = imrotate(template_mean, termite_orientation);
        
        % get size of template_match
        template_size = size(template_match);
        
        % grab a chunk of data and subtract template:
        termite_centre = termiteRegionInf.Centroid(jj,:);
        soillim_lr = [(round(termite_centre(1))-floor(template_size(1)/2)) : (round(termite_centre(1))+ceil(template_size(1)/2-1))];
        soillim_ud = [(round(termite_centre(2))-floor(template_size(2)/2)) : (round(termite_centre(2))+ceil(template_size(2)/2-1))];
        
        soildata(soillim_lr, soillim_ud) = soildata(soillim_lr, soillim_ud) - template_match;
    end
end