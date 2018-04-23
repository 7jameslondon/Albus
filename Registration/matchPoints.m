function [A_idx,B_idx] = matchPoints(A,B,maxNeighbor)
    % matchPoints - finds all the points in A within a radius 
    % 'maxNeighbor' of a point in B. It returns two lists of indexs with the
    % points corrisponding by row. Points with multiple neighbores have only
    % the closest point returned.

    % setup a defult value for maxNeighbor
    if ~exist('maxNeighbor','var')
        maxNeighbor = 2;
    end
    
    % fill A_idx with all posible indexs
    A_idx = (1:size(A,1));

    % Calculate the distance between all points in A and B where the rows
    % are the points in A and the colunms are the points in B.
    dist_AB_x = abs( repmat(A(:,2),1,size(B,1)) - repmat(B(:,2),1,size(A,1))' );
    dist_AB_y = abs( repmat(A(:,1),1,size(B,1)) - repmat(B(:,1),1,size(A,1))' );
    dist_AB = sqrt(dist_AB_x.^2 + dist_AB_y.^2);

    % Gind the closest point of each B to each A
    [min_dist, B_idx] = min(dist_AB,[],2);
    
    % remove indexs where the closest point is farther then maxNeighbor
    A_idx(min_dist > maxNeighbor) = [];
    B_idx(min_dist > maxNeighbor) = [];
    
    % if there are multiple points in A claiming one point in B then remove
    % them from A and B
    uniqueIdx = unique(B_idx); % the unique set of B_idx
    numRepeats = histc(B_idx,uniqueIdx); % the count of repeates of uniqueIdx
    i = ismember(B_idx, uniqueIdx(numRepeats>1)); % the indexs of repeated elements
    A_idx(i) = [];
    B_idx(i) = [];

end

