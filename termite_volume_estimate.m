% Extracts termite locations in depth frame, identifies termite pixels and
% creates a volumetric template

start_frame = input('Enter frame number of start: ','s');
current_frame = str2num(start_frame);
end_frame = input('Enter frame number of end: ', 's');
finish_frame = str2num(end_frame);

param_precheck;

noiseflag = 0;
isnoise = input('Remove noisy pixels? [] = no, other = yes] ', 's');
if ~isempty(isnoise)
    noiseflag = 1;
end

% superposition template, sized to padded bounding box
template_super = zeros(50,50);
tcount = 0;

% in depth frame, estimates a termite perimeter
while current_frame < finish_frame+1
    % read in current rgb image:
    cd(rgbdir);
    if length(rgbfiles) < current_frame
        disp('Reached end of file list');
        break
    end
    imname = rgbfiles(current_frame).name;
    cd('../');
    
    % identifies termite locations RGB->Depth
    rgb_filt_dat = termite_rgb_preprocess(imname, dish_thresh, rgb_preproc, imwidth, imheight);
    dishMask = rgb_filt_dat.dishMasked;
    currentRGB = rgb_filt_dat.currentRGB;
    bwMask = rgb_filt_dat.bwMask;

     % Termite location:
    [tCent, tRad, bw_debug] = termite_rgb_localisation(termite_thresh, currentRGB, bfill_param, tlength);
    
    % read in current depth image:
    cd(depthdir);
    depthname = dispfiles(current_frame).name;
    cd('../');
    
    % Depth processing
    
    
    [depthmap_raw, dStruct] = termite_depth_extraction(depthname, calibStruct, plate_om, plate_tc, alpha_vec, depth_error, dmin_th, dmax_th);
    
    % Repurpose code from adding termites: select termite locations
    % manually.
    depthmap_termfind = depthmap_raw;
    depthmap_termfind(depthmap_termfind>12) = 12;
    figure; mesh(depthmap_termfind); view(0,90);
    [xt, yt] = getpts(gca);
    lpick = length(xt);
    t_depthLoc = [xt(1:lpick-1), yt(1:lpick-1)]';

    % Calculate masking area from RGB
    DepthCircMask = calc_depth_mask(bwMask, calibStruct, plate_tc, depth_est);
    
    % look for pixels around each termite centroid that are higher than the
    % soil average
    rb = 22; % heuristic, could use as function input
    w = 640; h = 480;

    depthmap_termfind(isnan(depthmap_termfind)) = 0;    

    
    % For each termite:
    for k = 1:length(t_depthLoc)
        
        dmap_k = depthmap_raw;
        % identify centroid
        ttx = t_depthLoc(1,k); tty = t_depthLoc(2,k);
    
        % create masked circle radius rb around centroid
        [txm, tym] = meshgrid(-(ttx-1):(w-ttx), -(tty-1):(h-tty));
        termMask = (((txm/rb).^2 + (tym/rb).^2) <= 1);

        dmap_termitezone = zeros(size(depthmap_raw));
        dmap_termitezone(termMask>0) = 1;
        tzone_mean = nanmean(dmap_k(termMask>0));
    
        heightmap = depthmap_termfind > (tzone_mean+0.2);

        % Termite pixels
        termite_map = (dmap_termitezone>0) &  (heightmap>0);

        if sum(sum(termite_map)) > 0
            % create a mask and find the orientation of the major axis
            termiteID = imfill(termite_map, 'holes');
            termiteIDStats = regionprops('table', termiteID, 'Orientation', 'BoundingBox', 'Area');
            % hopefully there's only one obvious termite candidate
            % nope! of course not. Choose largest
            [termsize, ind] = max(termiteIDStats.Area);
            
            termite_orientation = termiteIDStats.Orientation(ind);
            termite_ul = termiteIDStats.BoundingBox(ind,1:2);
            termite_dim = termiteIDStats.BoundingBox(ind,3:4);
            
            % extract image segment containing termite:
            dmap_k(~termite_map) = 0;
            % crop to bounding box
            termite_cropbox = dmap_k(floor(termite_ul(2)):ceil((termite_ul(2)+termite_dim(2))), floor(termite_ul(1)):ceil((termite_ul(1)+termite_dim(1))));
            
            % Rotate to zero
            template_match = imrotate(termite_cropbox, -termite_orientation);
            %figure; mesh(template_match); view(0,90);
            % problem: template size might be irregular
            % solution: pad bounding box?
            
            % rb = 22 -> there should be no termite template larger than
            % 50px.            
            termite_tempbox = zeros(50,50);
            boxsize = size(template_match);
            if boxsize(1) > 49
                % skip everything
                continue;
            else
                termite_leftpad = floor((50-boxsize(1))/2);
                termite_toppad = floor((50-boxsize(2))/2);
            
                termite_tempbox(termite_leftpad:(boxsize(1)+termite_leftpad)-1, termite_toppad:(boxsize(2)+termite_toppad)-1) = template_match;

                % subtract mean soil height
                termite_tempbox = termite_tempbox-(tzone_mean-0.5);
                termite_tempbox(termite_tempbox<0) = 0;
            
                template_super = template_super+termite_tempbox;
                tcount = tcount+1;
            end
        else
            continue
        end
        
    end

    
    current_frame = current_frame+1;
end


template_mean = template_super/tcount;
    
figure; mesh(template_mean); view(0,90);

% subtracts background soil height 
% calculate volume in px^2mm
