function[filledDepth] = no_filt_update(kk, depthmap, frameDat)

prevname = ['storeframe_' num2str(kk-1)];

if isfield(frameDat, prevname)
    eval(['prevdat = frameDat.storeframe_' num2str(kk-1) ';']);
    nanIndexMap = isnan(depthmap);
    filledDepth = depthmap;
    filledDepth(nanIndexMap) = prevdat(nanIndexMap);
else
    filledDepth = depthmap;
end


