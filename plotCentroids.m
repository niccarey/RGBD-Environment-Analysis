function[] = plotCentroids(termiteLoc, depthCircMask)

list = [];
% generate exclusion list for centroids outside the mask
for jj = 1:length(termiteLoc)
    if depthCircMask(round(termiteLoc(2,jj)), round(termiteLoc(1,jj)))<1
        list = [list jj];
    end
end

termiteLoc(:,list) = [];
termite2Disp = 25*ones(length(termiteLoc),1);
axes(gca);
hold on;
plot3(termiteLoc(1,:), termiteLoc(2,:), termite2Disp, 'rx');
hold off
