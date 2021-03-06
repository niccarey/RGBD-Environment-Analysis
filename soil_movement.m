% Create a soil displacement metric and dynamic plot

% Requires: 
% Rectified depth scans (without background subtraction), a
% background frame, a noise mask, a residual smoothing filter

% Select files to make a movie out of:
disp('Select a folder of rectified depth files: ')
soil_disp_dir = uigetdir;
soilfiles = dir([soil_disp_dir '/*.mat']);

% Load a related parameter file
paramin = input('Need to load parameter file? [] = no, other = yes: ', 's');
if ~isempty(paramin)
    disp('Select a parameter file associated with this recording');
    paramLoad;
end

% Just in case:
param_precheck;

if ~exist('bg_frame', 'var')
    disp('No background frame to subtract. Cancelling - please load a background frame or run bg_frame_create');
    return
end

term_rem_flag = 0;

vol_est = input('Remove termite volume from soil movement estimate? [] = no, other = yes', 's');
if ~isempty(vol_est)
    term_rem_flag = 1;
    
    if ~exist('template_mean', 'var')
        termite_volume_estimate;
    end
end

% noise elimination
noiseflag = 0;
isnoise = input('Remove noisy pixels (recommended)? [] = no, other = yes] ', 's');
if ~isempty(isnoise)
    noiseflag = 1;
end

start_frame = input('Enter frame number of start: ','s');
current_frame = str2num(start_frame);


end_frame = input('Enter frame number of end ([] = all files): ','s');
if ~isempty(end_frame)
    finish_frame = str2num(end_frame);
else
    finish_frame = length(soilfiles);
end

% Need to record movie
plotfig = figure; 

rb = 25;

plot_index = 1;

while current_frame < finish_frame
    % load frame
    cd(soil_disp_dir);
    filename = soilfiles(current_frame).name;

    % - load whatever data set is contained therein
    loadfile = load(filename);
    loadnames = fieldnames(loadfile);
    soildatname = loadnames{1};
    
    eval(['soildata = loadfile.' soildatname ';']);
    cd ../
    
    
    cd(rgbdir);
    rgbfiles(current_frame).name;
    im_mask_calc = imread(rgbfiles(current_frame).name);
    rgb_filt_dat = termite_rgb_preprocess(imname, dish_thresh, rgb_preproc, imwidth, imheight);
    bwMask = rgb_filt_dat.bwMask;
    dishrad = rgb_filt_dat.drad;
    currentRGB = rgb_filt_dat.currentRGB;
    
    cd ../
    
    % Calculate masking area from RGB
    DepthCircMask = calc_depth_mask(bwMask, calibStruct, plate_tc, depth_est);
    
    if term_rem_flag        
        % Identify termite locations
        % debug:
        %figure; mesh(soildata); view(0,90);
        %drawnow;
        % bw_debug returns termite pixels
        [tCent, tRad, bw_term_map] = termite_rgb_localisation(termite_thresh, currentRGB, bfill_param, tlength);
        
        % Get depth location OR calculate all likely termite pixels from RGB?
        % Latter is more effective.
        % Exclude pixels outside image mask
        bw_term_map(bwMask<1) = 0;
        [tpix_I, tpix_J] = find(bw_term_map>0);
        % Get termite pixels: bw_term_map-> termite_pix_loc
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
        
        % debug:
        %figure; imshow(termite_bwmask);
        %drawnow;
        
        % Make sure the overlap is correct: debug only
        %dmap_k = soildata;
        %dmap_k(~termite_bwmask) = 0;
        %figure; mesh(dmap_k); view(0,90);
        
        % identify discrete areas
        termiteRegionInf = regionprops('table', termite_bwmask, 'Centroid', 'Area');
        
        for jj = 1:length(termiteRegionInf.Area)
            if termiteRegionInf.Area(jj) < 200
                % probably not a termite, ignore
                continue;
            else
                % accurate but complex way of doing this is to ID the
                % termite, rotate template to match, then subtract the
                % template pixels. A quick hack would be to just centre the
                % template on the termite ID'd location, and subtract,
                % assuming that any weird depth noise will even out in the
                % long term.
                
                % try that first:
                
                % grab a chunk of data:
                termite_centre = termiteRegionInf.Centroid(jj,:);
                soillim_lr = [(round(termite_centre(1))-rb) : (round(termite_centre(1))+rb-1)];
                soillim_ud = [(round(termite_centre(2))-rb) : (round(termite_centre(2))+rb-1)];
                soildata(soillim_lr, soillim_ud) = soildata(soillim_lr, soillim_ud) - template_mean;
            end
        end
        % debug: 
        %figure; mesh(soildata); view(0,90);
    end
    
    % proceed as normal:
    
    % subtract background
    rempix = soildata - bg_frame;
    figure; mesh(rempix); view(0,90);
    
    rempix(abs(rempix) < 0.4) = NaN;
    rempix(~DepthCircMask) = NaN;
    
    % eliminate noise
    % apply noise mask (if data exists)
    if (exist('noiseMask', 'var')) && noiseflag
        rempix(noiseMask > 0 ) = NaN;
    end
    
    
    
    % sum +ve difference pixels
    %( effectively integrating)
    rempos = rempix;
    rempos(rempos<0) = NaN;
    rempossum = sum(sum(rempos, 'omitnan'));
    
    % sum -ve difference pixels
    remneg = rempix;
    remneg(remneg>=0) = NaN;
    remnegsum = sum(sum(remneg, 'omitnan'));

    % Calculate positive volume displacement
    pVol = rempossum; % *16 in mm^3
    % calculate negative volume displacement
    nVol = remnegsum; % *16 in mm^3
    
    % pVol + nVol should = roughly 100% of disturbed soil 
    tVol = abs(pVol)+abs(nVol);
    
    % can subtract disturbed soil volume from overall volume to get a
    % percentage
    calcVol = (1 - (pi*(dishrad)^2*4 - tVol)/(pi*(dishrad)^2*4));

    % plot ONLY new pixels
    figure(plotfig)
    subplot(2,2,[1,3]); mesh(rempix); view(0,90); colorbar;
    
    if (finish_frame - str2num(start_frame)) < 3
        subplot(2,2,2); barh([[tVol, nVol]; [tVol, pVol]]);
        subplot(2,2,4); barh(calcVol, 'BarWidth', 0.5);
    else    
        subplot(2,2,2); hold on; plot(current_frame, rempossum, 'r.', 'MarkerSize', 14); plot(current_frame, abs(remnegsum), 'b.','MarkerSize', 14);
        subplot(2,2,4); hold on; plot(current_frame, calcVol, 'k.', 'MarkerSize', 14);
    end
    drawnow;
    
    % store data
    rempos_plot(plot_index) = rempossum;
    remneg_plot(plot_index) = remnegsum;
    soilvol(plot_index) = calcVol;
    current_frame = current_frame+1;
    
    plot_index = plot_index+1;
end

