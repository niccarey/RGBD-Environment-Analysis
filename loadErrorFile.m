% termite_build_analysis: load a file to use for steady state depth error
% subtraction

errorfile = uigetfile;
DE = load(errorfile);
depth_error = DE.DepthErrorCorrected;

clear DE