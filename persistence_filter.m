function[depth_pfilt] = persistence_filter(depthmap, dispfiles, nn, kk, jj, frameDat, calibStruct, pOm, pT, alpha, depth_error, dmin, dmax)

prevname = ['storeframe_' num2str(kk-1)];

if isfield(frameDat, prevname) %exist(prevname, 'var')
    eval(['prevdepth = frameDat.storeframe_' num2str(kk-1) ';']);

    depthdiff = depthmap  - prevdepth;
    depthdiffPos = find(depthdiff > 0.2);
    depthdiffNeg = find(depthdiff < -0.2);

    build_pix = union(depthdiffPos, depthdiffNeg);

    newNaNMap = ~isnan(depthmap);
    prevNaNMap = isnan(prevdepth);
    updatedNaN = newNaNMap & prevNaNMap;

    new_pix = find(updatedNaN);
    changed_pix = union(build_pix, new_pix);

    % forward filter:
    filtFile = dispfiles(nn+kk);
    filtName = filtFile.name;

    fc = calibStruct.fc_right;
    cc = calibStruct.cc_right;
    kc = calibStruct.kc_right;
    om = calibStruct.om;
    T = calibStruct.T;

    [filtMap_raw, ~] = compute_depth_map(filtName, fc, cc, kc, om, T, pOm, pT, alpha);

    filtMap = filtMap_raw - depth_error;

    filtMap(filtMap < dmin) = dmin;
    filtMap(filtMap > dmax) = dmax;

    filtDiff = NaN(size(depthmap));
    filtDiff(changed_pix) = filtMap(changed_pix) - depthmap(changed_pix);
    
    filtDiff(filtDiff > 0.2) = NaN;
    filtDiff(filtDiff < -0.2) = NaN;

    updatePix = ~isnan(filtDiff);

    filteredDepth = prevdepth;
    filteredDepth(updatePix) = depthmap(updatePix);

    % averaging window
    avLen = min(kk,jj);
    avDepth = depth_av_filt(filteredDepth, frameDat, avLen);

    nanIndexMap_new = isnan(avDepth);
    avDepth(nanIndexMap_new) = filteredDepth(nanIndexMap_new);

    depth_pfilt = avDepth;

else
    % if this is the start of the averaging, just return the existing frame
    depth_pfilt = depthmap;
end
