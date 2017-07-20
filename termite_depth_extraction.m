function[depthmap, depth_struct] = termite_depth_extraction(dname, calibStruct, plate_om, plate_tc, a_vec, d_err, dmin, dmax)

fc = calibStruct.fc_right;
cc = calibStruct.cc_right;
kc = calibStruct.kc_right;
om = calibStruct.om;
T = calibStruct.T;

[depthmap_raw, dTr] = compute_depth_map(dname, fc, cc, kc, om, T, plate_om, plate_tc, a_vec);

depth_struct.depthXmap = reshape(dTr(1,:), 480,640);
depth_struct.depthYmap = reshape(dTr(2,:), 480,640);

depthmap = depthmap_raw - d_err;

depthmap(depthmap < dmin) = dmin;
depthmap(depthmap > dmax) = dmax;

