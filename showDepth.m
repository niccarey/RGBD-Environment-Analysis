function[] = showDepth(depthmap, depthCircMask, dmin, dmax)

depthmap(~depthCircMask) = NaN;

axes(gca);

hold off % probably don't need this but just in case
hd = surf(depthmap);
set(hd, 'Edgecolor', 'none'); axis equal;
colorbar; view(0,-90);
caxis([dmin, dmax]);

