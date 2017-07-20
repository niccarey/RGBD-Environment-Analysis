% termite_build_analysis subfunction: get rgb directory

rgbdir = uigetdir;
rgbfiles = dir([rgbdir '/*.jpg']);

if isempty(rgbfiles)
    disp('error: no jpeg files in directory');
    % we could expand to use any colour image format but ignore for now
end
