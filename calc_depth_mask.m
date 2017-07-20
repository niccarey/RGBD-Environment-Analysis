function[depthMask] = calc_depth_mask(bwMask, calibStruct, plate_tc, est_height)

% obtain points on the perimeter of bwMask
[prows, pcols] = find(bwperim(bwMask));
circumpoints = [pcols, prows];
% cols is y, rows is x
%figure; plot(pcols, prows, 'r.');

% project points into depth frame
% as with termite projection, we need to assume a height

fc = calibStruct.fc_left;
cc = calibStruct.cc_left;
kc = calibStruct.kc_left;
om = calibStruct.om;
T = calibStruct.T;

dirt_depth = est_height*ones(length(prows), 1);

xn = normalize(circumpoints', fc, cc, kc, 0);

Xw = xn(1,:).*dirt_depth';
Yw = xn(2,:).*dirt_depth';
wPat = [Xw; Yw; dirt_depth'];

circumTemp = zeros(4,length(wPat));

% two camera transform: depth in colour frame
R_C = rodrigues(om);
TF_CD = [R_C, T; 0 0 0 1];

for j=1:length(circumpoints)
    circumTemp(:,j) = TF_CD*[wPat(:,j);1];
end

fc_right = calibStruct.fc_right;
cc_right = calibStruct.cc_right;
kc_right = calibStruct.kc_right;

% project to pixel locations
Xdp = project_points2(circumTemp(1:3,:), rodrigues(eye(3)), [0 ; 0 ; 0], fc_right, cc_right, kc_right, 0);
circumProject = Xdp';

%figure; mesh(depthmap); view(0,90);hold on; plot(circumProject(:,1), circumProject(:,2), 'r.');
%figure; plot(circumProject(:,1), circumProject(:,2), 'r.');
% fine so far

% calculate circle from perimeter
nn = length(circumProject);
x = circumProject(:,1);
y = circumProject(:,2);

% use three points:
nc = floor(nn/3);

[sel_cen, sel_rad] = calcCircle([x(1), y(1)], [x(nc), y(nc)], [x(2*nc),y(2*nc)]);
cx = sel_cen(1);
cy = sel_cen(2);
%plot(cx,cy, 'gx');

r_est = sel_rad;
% calculate masked region

w = 640; h = 480;   
[xmask, ymask] = meshgrid(-(cx-1):(w-cx), -(cy-1): (h-cy));
    
depthMask = (((xmask/r_est).^2 + (ymask/r_est).^2) <= 1);