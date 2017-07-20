% termite_depth_analysis: load calibration file for realsense cameras
% need fc, kc, ... 
% for both IR and colour cameras

calibfile = uigetfile;
calibStruct = load(calibfile);