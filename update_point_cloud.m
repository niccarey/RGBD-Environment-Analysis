function [cloud_update, cloud_mm_update] = update_point_cloud(dStr, depthmap, prev_cloud, prev_mm_cloud, circmask)

% To construct a pixel-pixel-mm grid, use this:
xgv = 1:640;
ygv = 1:480;
[Xval, Yval] = meshgrid(xgv, ygv);

depthmap(:,500:640) = NaN;
depthmap(~circmask) = NaN;

newcloud = [Xval(:), Yval(:), depthmap(:)];
newmmcloud = [dStr.depthXmap(:), dStr.depthYmap(:), depthmap(:)];

[INDrow, ~] = find(isnan(newcloud));
newcloud(INDrow,:) = [];

newmmcloud(INDrow,:) = [];

newPos = [newcloud(:,1) newcloud(:,2)];

current_cloud = prev_cloud;
current_mm_cloud = prev_mm_cloud;

if ~isempty(prev_cloud)
    currentPos = current_cloud(:,1:2);
    
    [~, indexLocate] = ismember(currentPos, newPos, 'rows');
    idPtr = find(indexLocate > 0);
    
    intersection = [];
    for jj = 1:length(idPtr)
        intID = indexLocate(idPtr(jj));
        newDepth = newcloud(intID,3);
        currentDepth = current_cloud(idPtr(jj),3);
        
        if newDepth < currentDepth
            intersection = [intersection idPtr(jj)];
        end
    end
    
    current_cloud(intersection,:) = [];
    current_mm_cloud(intersection,:) = [];
    % depth data is probably full of noise:
    % if norm(xi - xj) < 0.2mm , remove. Use rangesearch:

    [idx, dist]  = rangesearch(current_cloud, newcloud, 0.05);
    % find non-empty elements of idx
    idx_filled = find(~cellfun(@isempty, idx));
    
    remove_points = [idx{idx_filled}];
    current_cloud(remove_points,:) = [];
    current_mm_cloud(remove_points,:) = [];
end

full_cloud = [current_cloud; newcloud];
full_cloud_mm = [current_mm_cloud; newmmcloud];

% Remove any redundances that have crept through?
[TUN, IA, ~] = unique(full_cloud, 'rows');

disp('Nearby points eliminated:')

cloud_update = full_cloud(IA,:);
cloud_mm_update = full_cloud_mm(IA,:);
