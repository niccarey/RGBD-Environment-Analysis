function [rgbout] = calc_rgb_overlay(mmcloud, calibStruct, oma, Ta, rgbin)

% mm cloud is 3D mm position in depth frame

omc = calibStruct.om;
Tc = calibStruct.T;

% Prepare necessary transformation matrices

R_C = rodrigues(omc);
TF_DC = [R_C', -(R_C')*Tc; 0 0 0 1];

R_A = rodrigues(oma);
TF_CA = [R_A, Ta; 0 0 0 1];

TF_DA = TF_CA*TF_DC;

buildExp = ones(4, length(mmcloud));
buildExp(1:3, :) = mmcloud';

% First need to convert from depth to plate frame
cmap_plate = TF_DA*buildExp;

% Now plate-depth frame to plate-colour frame
buildRGB = TF_DC*cmap_plate;

buildPixels = round(project_points2(buildRGB(1:3,:), rodrigues(eye(3)), [0 ; 0 ; 0], calibStruct.fc_left, calibStruct.cc_left, calibStruct.kc_left, 0));
pixXMesh = buildPixels(1,:);
pixYMesh = buildPixels(2,:);

RGBRemapped = NaN([length(mmcloud), 3]);
size_rgb = size(rgbin);
width = size_rgb(2); height = size_rgb(1);

for kcmap = 1:length(pixXMesh)
    if ( ( pixXMesh(kcmap) < width ) && (pixXMesh(kcmap) > 1) && (pixYMesh(kcmap)< height) && (pixYMesh(kcmap) > 1))
        RGBRemapped(kcmap, :) = rgbin(pixYMesh(kcmap), pixXMesh(kcmap), :);
    end
end

% for each pixel in mmcloud, we now have an associated colour vector
rgbout = uint8(RGBRemapped);
