% termite_build_analysis: select cropping mask for displaying relevant
% portions of depth image

disp('Please select .dat file to estimate soil depth from');
dcropfile = uigetfile('*.dat');
depthCropIm = read_disparity(dcropfile);

depthCropIm(:, 500:640) = NaN;
% note that the caxis limits here may need adjusting

soil_height_vec = height_ident(depthCropIm);
if ~exist('alpha0', 'var')
    alpha_load;
end

mm_vec = soil_height_vec.*alpha1 + alpha0;
soil_height = mean(mm_vec);

function[dEst_vec] = height_ident(depthIm)

    hd = figure; mesh(depthIm); view(0,90); caxis([1000 1100]);

    disp('Hit any key when ready to select soil points');
    w = 0;
    while w == 0
        w = waitforbuttonpress;
    end
    
    disp('Please select five points on the soil surface');
    [x_roi, y_roi] = ginput(5);
    idx = sub2ind(size(depthIm), floor(x_roi), floor(y_roi));
    dEst_vec = depthIm(idx);
    close(hd);
    
    % Identify intersection 
    %[sel_cen, sel_rad] = calcCircle([x_roi(1), y_roi(1)], [x_roi(2), y_roi(2)], [x_roi(3), y_roi(3)]);
    %cx = sel_cen(1);
    %cy = sel_cen(2);
    %r = sel_rad;
    %w = 640; h = 480;   
    %[xmask, ymask] = meshgrid(-(cx-1):(w-cx), -(cy-1): (h-cy));
    
    %cMask = (((xmask/r).^2 + (ymask/r).^2) <= 1);
end
