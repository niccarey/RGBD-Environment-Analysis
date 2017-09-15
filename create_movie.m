% Select files to make a movie out of:
% disp('Select a folder of depth-related data files: ')
% moviedir = uigetdir;
% moviefiles = dir([moviedir '/*.mat']);
% 
% % Load a related parameter file
% disp('Select a parameter file associated with this recording');
% paramLoad;
% 
% meshflag = 0 ;
% pcflag = 0 ;
% surfflag = 0;
% 
% % Select type of movie
% movtype = input('Select [m] mesh data, [p] pointcloud data, [s] surface data: ' ,'s');
% switch(movtype)
%     case 'm'
%         meshflag = 1;
%     case 'p'
%         pcflag = 1;
%     case 's'
%         surfflag = 1;
%     otherwise
%         disp('Please enter a valid data display type')
%         return           
% end
% 
% 
% % test input
% init_file = moviefiles(1).name;
% loadfile = load([moviedir '/' init_file]);
% loadnames = fieldnames(loadfile);
% multiple_flag = 0;
% 
% if length(loadnames) > 1
%     disp('More than one data array is stored. Names: ');
%     disp(loadnames);
%     whichload = input('Select number of array to use: [] = 1 ');
%     multiple_flag = 1;
%     if isempty(whichload)
%         whichload = multiple_flag;
%     end
%     
% end
% 
% 
% % overlay colour?
% move_over = input('Overlay colour data on depth? [] = no, other = yes ', 's');
% if ~isempty(move_over)
%     if pcflag
%         disp('Select rgb_overlay');
%         overlay_dir = uigetdir;
%         disp('Colour overlays must be the same size as depth files');
%         overlayfiles = dir([overlay_dir '/*.mat']);
%     else
%         disp('Select rgb folder');       
%         rgb_loader;
%         disp('select depth file folder');
%         depth_loader;        
%     end
%     overlay_flag = 1;
% else
%     overlay_flag = 0;
% end
% 
% % Show initial image to select angle and axis limits
% figure(1)
% % Initial data
% if multiple_flag
%     init_dat = loadnames{whichload};
% else
%     init_dat = loadnames{1};
% end
% eval(['plot_init = loadfile.' init_dat ';']);

if meshflag
        mesh(plot_init); %axis equal;
elseif surfflag
        surf(plot_init, 'EdgeColor', 'none');% axis equal;
elseif pcflag
       cloudplot = pointCloud([plot_init(:,1),plot_init(:,2), plot_init(:,3)]); 
       pcshow(cloudplot);axis equal;
end

disp('Check axis limits and viewing angles. Press any key to proceed.');
w = 0;
while w == 0
    w = waitforbuttonpress;
end

axisLims = input('Enter axis limits as a vector [XMIN XMAX YMIN YMAX ZMIN ZMAX] ');
if isempty(axisLims)
    disp('Warning: without static axis limits, the video may not process properly.')
    axischeck = input('Proceed [] or set axis limits [other] ?' , 's');
    if ~isempty(axischeck)
        axisLims = input('Enter axis limits as a vector [XMIN XMAX YMIN YMAX ZMIN ZMAX] ');
    end
end

init_view = campos(gca);
view_store = input('Use current camera angle? [] = yes, other = no ', 's');

% Select camera views
viewmove_flag = 0;
viewin = input('Static or moving camera view? [] = static, other = moving ', 's');

if isempty(viewin)
    if isempty(view_store)
        viewvec = init_view;
    else
        viewvec = input('Please enter viewing angle as vector [azimuth, elevation] :');
    end
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
for filmframe = 1:skipframe:endframe %length(moviefiles)
    
    filename = moviefiles(filmframe).name;

    % - load whatever data set is contained therein
    loadfile = load([moviedir '/' filename]);
    loadnames = fieldnames(loadfile);
    if multiple_flag
        datname = loadnames{whichload};
    else
        datname = loadnames{1};
    end
    eval(['plotdata = loadfile.' datname ';']);
    imname = [rgbdir '/' rgbfiles(filmframe).name];
    im_mask_calc = imread([rgbdir '/' rgbfiles(current_frame).name]);
    rgb_filt_dat = termite_rgb_preprocess(imname, dish_thresh, rgb_preproc, imwidth, imheight);
    dishMask = rgb_filt_dat.dishMasked;
    overlayRGB = dishMask;
    
    % - load associated overlay file, if it exists
    if overlay_flag 
        if pcflag
            overlay_fname = overlayfiles(filmframe).name;
            overfile = load([overlay_dir '/' overlay_fname]);
            coldat = overfile.rgbmat;
        else
            % RGB->surface
            % This works only for 3D data: so need to generate or retrieve X,Y positions
            fc = calibStruct.fc_right;
            cc = calibStruct.cc_right;
            kc = calibStruct.kc_right;
            om = calibStruct.om;
            T = calibStruct.T;
            
            dname = [depthdir '/' dispfiles(filmframe).name];
            [depthmap_raw, dTr] = compute_depth_map(dname, fc, cc, kc, om, T, plate_om, plate_tc, alpha_vec);
            coldat = calc_rgb_overlay(dTr(1:3,:)', calibStruct, plate_om, plate_tc, overlayRGB);
            coldat = reshape(coldat, [480,640,3]);
        end
        
    end

    bwMask = rgb_filt_dat.bwMask;
    
    % Calculate masking area from RGB
    if filmframe==1
        DepthCircMask = calc_depth_mask(bwMask, calibStruct, plate_tc, depth_est);
    end
    
    if ~pcflag
        plotdata(~DepthCircMask) = NaN;
    end
    
    if overlay_flag
    % - create figure
        if meshflag
            figure(2); mdisp = mesh(plotdata*4); mdisp.CData = coldat; 
                     axis equal; ax = gca; ax.Visible = 'off'; axis(axisLims);
        elseif surfflag
            figure(2); sdisp = surf(plotdata, 'EdgeColor', 'none'); sdisp.CData = coldat;
                    axis(axisLims); 
                    mdisp.DataAspectRatio = [1,1,4];

        elseif pcflag
            cloudplot = pointCloud([plotdata(:,1),plotdata(:,2), plotdata(:,3)], 'Color', coldat); 
            figure(2); pcshow(cloudplot);axis equal;
                        axis(axisLims);

        end
    else
        if meshflag
            figure(2); mesh(plotdata); caxis([0,20]); axis equal;
                        axis(axisLims);

        elseif surfflag
            figure(2); surf(plotdata, 'EdgeColor', 'none');axis equal;
                        axis(axisLims);

        elseif pcflag
            cloudplot = pointCloud([plotdata(:,1),plotdata(:,2), plotdata(:,3)]); 
            figure(2); pcshow(cloudplot);axis equal;
                        axis(axisLims);

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

% close movie
close(outputVideo);