% termite_build_analysis: get depth directory

depthdir = uigetdir;
dispfiles = dir([depthdir '/*.dat']);


if isempty(dispfiles)
    print('error: no identified depth files in directory - make sure files have .dat extension');
    % we could expand to use any colour image format but ignore for now
end
