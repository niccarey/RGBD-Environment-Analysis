% termite_build_analysis: load existing threshold function

tr_loc = uigetfile;
% strip off externals
[~,tr_file,~]=fileparts(tr_loc);

% thresholding function
termite_thresh = str2func(tr_file);