% Select files to make a movie out of:
disp('Select a folder of depth-related data files: ')
moviedir = uigetdir;
moviefiles = dir([moviedir '/*.mat']);

% Load a related parameter file
disp('Select a parameter file associated with this recording');
paramLoad;

meshflag = 0 ;
pcflag = 0 ;
surfflag = 0;

% Select type of movie
movtype = input('Select [m] mesh data, [p] pointcloud data, [s] surface data: ' ,'s');
switch(movtype)
    case 'm'
        meshflag = 1;
    case 'p'
        pcflag = 1;
    case 's'
        surfflag = 1;
    otherwise
        disp('Please enter a valid data display type')
        return           
end


% test input
inputcheck = moviefiles(1);
loadfile = load(inputcheck.name);
loadnames = fieldnames(loadfile);
multiple_flag = 0;

if length(loadnames) > 1
    disp('More than one data array is stored. Names: ');
    disp(loadnames);
    whichload = input('Select number of array to use: [] = 1 ');
    multiple_flag = 1;
end


% overlay colour?
move_over = input('Overlay colour data on depth? [] = no, other = yes ', 's');
if ~isempty(move_over)
    cd moviedir
    disp('Colour overlays must be the same size as depth files, and in the same directory.');
    colfile_base = input('Enter base name of overlay files: ', 's');
    cd ../
    overlay_flag = 1;
else
    overlay_flag = 0;
end

% Select camera views
viewmove_flag = 0;
viewin = input('Static or moving camera view? [] = static, other = moving ', 's');

if isempty(viewin)
    viewvec = input('Please enter viewing angle as vector [azimuth, elevation] :');
else
    viewmove_flag = 1;
    % set up starting condition
    viewvec = [0,0];
    viewdir = 1;
end

startmov_frame = input('Frame number to start movie? [] = 1 ');
if isempty(startmov_frame)
    startmov_frame = 1;
end

skipframe = input('Record only every nth frame? Enter n ([] = 1) ');
if isempty(skipframe)
    skipframe = 1;
end

endframe = input('Frame number to end movie? [] = end of file list ');
if isempty(endframe)
    endframe = length(moviefiles);
end

% open/create movie
moviename = input('Enter name for movie output: ', 's');
framerate = input('Enter framerate: ');
outputVideo = VideoWriter(moviename);
outputVideo.FrameRate = framerate;
open(outputVideo);

% HISTORICALLY: very long movie files could cause issues. find out where
% limit is, may have to break into chunks.

figure(2)
% for each file in moviedir: 
for filmframe = 1:skipframe:endframe
    
    filename = moviefiles(filmframe).name;

    % - load whatever data set is contained therein
    cd(moviedir);

    loadfile = load(filename);
    loadnames = fieldnames(loadfile);
    if multiple_flag
        datname = loadnames{whichload};
    else
        datname = loadnames{1};
    end
    eval(['plotdata = loadfile.' datname ';']);
    
    % - load associated overlay file, if it exists
    if overlay_flag
        overlayname = [colfile_base num2str(filmframe)];
        overlaydat = load(overlayname);
        overlaynames = fieldnames(overlaydat);
        coldatname = overlaydat{overlaynames(1)};
        eval(['coldat = overlaydat.' coldatname ';']);
    end
    
    cd ../
    
    cd(rgbdir);
    
    cd(rgb_dir);
    im_mask_calc = imread(rgbfiles(current_frame).name);
    rgb_filt_dat = termite_rgb_preprocess(imname, dish_thresh, rgb_preproc, imwidth, imheight);
    dishMask = rgb_filt_dat.dishMask;
    bwMask = rgb_filt_dat.bwMask;
    cd ../
    
    % Calculate masking area from RGB    
    DepthCircMask = calc_depth_mask(bwMask, calibStruct, plate_tc, depth_est);
    
    plotdata(~DepthCircMask) = NaN;
    
    % - create figure
    if overlay_flag
        if meshflag
            figure(2); mesh(plotdata, coldat); axis equal;
        elseif surfflag
            figure(2); surf(plotdata, coldat, 'EdgeColor', 'none');axis equal;
        elseif pcflag
            cloudplot = pointcloud([plotdata(1,:),plotdata(2,:), plotdata(3,:)], 'Color', coldat); 
            figure(2); pcshow(cloudplot);axis equal;
        end
    else
        if meshflag
            figure(2); mesh(plotdata); axis equal;
        elseif surfflag
            figure(2); surf(plotdata, 'EdgeColor', 'none');axis equal;
        elseif pcflag
            cloudplot = pointcloud([plotdata(1,:),plotdata(2,:), plotdata(3,:)]); 
            figure(2); pcshow(cloudplot);axis equal;
        end
    end
        
    % - set viewing angle
    if ~viewmove_flag
        view(viewvec);
    else        
        prev_view = viewvec(2);
        if viewdir == 1
            viewvec = [filmframe, prev_view + 0.05*filmframe];
        else
            viewvec = [filmframe, prev_view - 0.05*filmframe];
        end
        if viewvec(2) > 90
            viewdir = 0;
        end
        if viewvec(2) < 0
            viewdir = 1;
        end
        view(viewvec);
        
    end

    % - store in movie file
    writeVideo(outputVideo, getframe(gca));
    
    % - clear variables?
end
cd ../

% close movie
close(outputVideo);