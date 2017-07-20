function[dmap_ret] = termite_removal(termiteLoc, depthRaw, DepthCircMask)

dmap_temp = depthRaw;
dmap_temp(isnan(dmap_temp)) = 0;


rb = 22; % heuristic, could use as function input
w = 640; h = 480;

for k = 1:length(termiteLoc)
    ttx = termiteLoc(1,k); tty = termiteLoc(2,k);
    
    [txm, tym] = meshgrid(-(ttx-1):(w-ttx), -(tty-1):(h-tty));
    termMask = (((txm/rb).^2 + (tym/rb).^2) <= 1);
    
    termite_index = find(termMask>0);
    depthRaw(DepthCircMask < 1) = NaN;
    
    dmap_termitezone = depthRaw(termMask);
    tzone_mean = nanmean(dmap_termitezone);
    dmap_k = dmap_temp;
    
    posdiff = dmap_termitezone - tzone_mean; % only used for debugging
    heightmap = find(dmap_k > (tzone_mean+0.3));
    
    termite_ind2 = intersect(termite_index, heightmap);
    dmap_temp(termite_ind2) = NaN;
end

dmap_ret= dmap_temp;