function[rgb_interp] = depth2rgbpix(depthmap, calibStruct, p_om, p_tc, dStruct, rgbsize)

warning off

% remove rgbim when finished debugging
width = rgbsize(2); height = rgbsize(1);

rgb_projected = NaN*ones(height, width);

% depth [px, py, dz] -> depth [x,y,z]
dx = dStruct.depthXmap;
dy = dStruct.depthYmap;

% Rectified coordinates (camera frame)
depth_mm = [dx(:), dy(:), depthmap(:)];

% Convert to plate frame
om = calibStruct.om;
T = calibStruct.T;

fc_left = calibStruct.fc_left;
cc_left = calibStruct.cc_left;
kc_left = calibStruct.kc_left;

% Convert camera transform info into transformation matrix
R_C = rodrigues(om);
%TF_CD = [R_C, T; 0 0 0 1];

% Depth frame in camera frame:
TF_DC = [R_C', -(R_C')*T; 0 0 0 1];

% Plate in colour frame:
R_A = rodrigues(p_om);
TF_CA = [R_A, p_tc; 0 0 0 1];

TF_DA = TF_CA*TF_DC;

D_cam = NaN*ones(3, length(depth_mm));
D_cam(1:3,:) = depth_mm';
D_cam(4,:) = 1;

% Now: project plate back to original depth frame (ie unrectified)
D_plate = TF_DA*D_cam;

% plate in colour frame
RGB_plate = TF_DC*D_plate;
% Now project into RGB camera coordinates
RGBPix = round(project_points2(RGB_plate(1:3,:), rodrigues(eye(3)), [0;0;0], fc_left, cc_left, kc_left, 0));
pixXMesh = RGBPix(1,:);
pixYMesh = RGBPix(2,:);

% Something going wrong (probably transformation related) - all pixels
% outside viewing area
checkpix = 0;
sparse_int = 1;

for kcmap = 1:length(pixXMesh)
    if ( (pixXMesh(kcmap) < width ) && (pixXMesh(kcmap) > 1) && (pixYMesh(kcmap) < height) && (pixYMesh(kcmap) > 1) )
        rgb_projected(pixYMesh(kcmap), pixXMesh(kcmap)) = RGB_plate(3, kcmap);
        pixX(sparse_int) = pixXMesh(kcmap);
        pixY(sparse_int) = pixYMesh(kcmap);
        storeZ(sparse_int) = RGB_plate(3,kcmap);
        sparse_int = sparse_int+1;
        checkpix = checkpix +1;
    end
end

% check
Fx = scatteredInterpolant(pixX', pixY', storeZ');
[queryX, queryY] = meshgrid(1:1920, 1:1080);
rgb_interp = Fx(queryX, queryY);

%figure; mesh(rgb_projected); view(0,90);
%figure; mesh(rgb_interp, 'CData', rgbim); view(0,90);

