function[averaged_depth] = depth_av_filt(curr_depth, frameDat,  avLen)

% should be able now to just use all of frameDat
ff = fieldnames(frameDat);

for n = 1:length(ff)
    lag(:,:,n) = frameDat.(ff{n});
    curr_depth = curr_depth + lag(:,:,n);
end

averaged_depth = curr_depth/(avLen+1);
