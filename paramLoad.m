% load a stored parameter file

[loadFile, loadPath] = uigetfile;

load(fullfile(loadPath, loadFile), '-mat');