function[tdLoc] = termite_depth_localisation(tCentroids, calibStruct, depth_est)

fc = calibStruct.fc_left;
cc = calibStruct.cc_left;
kc = calibStruct.kc_left;
om = calibStruct.om;
T = calibStruct.T;

dirt_depth = depth_est*ones(length(tCentroids), 1);

xn = normalize(tCentroids', fc, cc, kc, 0);

Xw = xn(1,:).*dirt_depth';
Yw = xn(2,:).*dirt_depth';
wPat = [Xw; Yw; dirt_depth'];

termiteTemp = zeros(4,length(wPat));
tdLoc = zeros(4, length(wPat));

% two camera transform: depth in colour frame
R_C = rodrigues(om);
TF_CD = [R_C, T; 0 0 0 1];

% For completeness: other useful transforms
% --------
% Plate in colour frame:
%R_P_RGB = rodrigues(plate_om);
%TF_CP = [R_P_RGB, plate_tc; 0 0 0 1];

% color in depth frame
%TF_DC = [R_C', -(R_C')*T; 0 0 0 1];

% plate in depth frame
%TF_DP = TF_CP*TF_DC;

% Calculate inverse transformation 
%TF_AD = [TF_DP(1:3,1:3)', -(TF_DP(1:3, 1:3)')*TF_DP(1:3,4); 0 0 0 1];

% ---------

% Calculate approximate termite location in depth frame, rectify to align
% with camera plane
for j=1:length(tCentroids)
    termiteTemp(:,j) = TF_CD*[wPat(:,j);1];
end

fc_right = calibStruct.fc_right;
cc_right = calibStruct.cc_right;
kc_right = calibStruct.kc_right;

% project to pixel locations
Xdp = project_points2(termiteTemp(1:3,:), rodrigues(eye(3)), [0 ; 0 ; 0], fc_right, cc_right, kc_right, 0);
tdLoc = Xdp;