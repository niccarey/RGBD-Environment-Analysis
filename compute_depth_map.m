function[DepthMap, DTrans] = compute_depth_map(DepthFile, fcD, ccD, kcD, omc, T_c, oma, T_a, alpha)

% may want to return DTrans also

% Convert camera transform info into transformation matrix
R_C = rodrigues(omc);
TF_CD = [R_C, T_c; 0 0 0 1];

% Depth frame in camera frame:
TF_DC = [R_C', -(R_C')*T_c; 0 0 0 1];

% Plate in colour frame:
R_A = rodrigues(oma);
TF_CA = [R_A, T_a; 0 0 0 1];

% Plate in depth frame
TF_DA = TF_CA*TF_DC;

% Inverse plate->depth frame transformation
TF_AD = [TF_DA(1:3,1:3)', -(TF_DA(1:3,1:3)')*TF_DA(1:3,4); 0 0 0 1];


% Acquire the depth map
depthArray = read_disparity(DepthFile);
depth_image = depthArray(:);

% Convert to x,y,z mm array

% Start with pixels:

xgv = 1:640;
ygv = 1:480;
[Xval, Yval] = meshgrid(xgv, ygv);
PP = [Xval(:), Yval(:)];
 
% Normalize using the depth camera internals
alpha_cD = 0;
 
% output is x,y location in mm
xn = normalize(PP',fcD,ccD,kcD,alpha_cD);

cart_depth = alpha(1) + alpha(2)*depth_image;

% Check IR-Depth mapping (raw)
% depth_raw = reshape(cart_depth, 480,640);

Xw = xn(1,:).*cart_depth';
Yw = xn(2,:).*cart_depth';
wPat = [Xw; Yw; cart_depth'];

% Apply known inverse transform to bring the depth image into line with the
% IR camera plane. 

DTrans = zeros(4,length(depth_image));

for i=1:length(depth_image)
     DTrans(:,i) = TF_AD*[wPat(:,i);1];
end

% DepthFile has now been rectified to the camera frame.
DepthMap = DTrans(3,:);
DepthMap = reshape(DepthMap, 480,640);