function [B_affine, flag] = findAffine(A, B, tol, maxIter, maxNeighbor)
%% findAffine - attempts to approximatly match the points in B to A within a
% tolerance of 'tol' within a maximum number of iterations of 'maxIter'.
%
% Todo this three points are randomly selected from B. For each of the 
% points the corrisponding neighbors in A within a square with radius of 
% 'maxNeighbor' are then selected. For every combination of points the  
% affine transformation is calculated and then applied to the entier set B.
% The distances to the points in A are then calculated. If their sum is
% less than the tolerance then the affine transformed set B is returned. If
% the transfomation is not found within maxIter then a flag is returned
% true.

%% Setup variables, functions and safty check values
% setup default values
if ~exist('tol','var')
    tol = 1e-3;
end
if ~exist('maxIter','var')
    maxIter = 1000;
end
if ~exist('maxNeighbor','var')
    maxNeighbor = 25;
end

flag = false;

if size(B,1) < 4 || size(B,1) < 4
    error('There must be atleast 4 points in each channel.');
end

% turn on errors for singular matrix warning so it can be caught
warning('error','MATLAB:nearlySingularMatrix');

%%
for iter=1:maxIter
    %% Select three points in B and find the corrsponding neighbors in A
    % three random points from B
    b = B(randperm(size(B,1),3),:);
    
    % the distance from A to each of these 3 B points
    b_dist1 = A - b(1,:);
    b_dist2 = A - b(2,:);
    b_dist3 = A - b(3,:);
    
    % the indexs of points in A within maxNeighbor of each b
    A_idx1 = find(sum(abs(b_dist1) <= maxNeighbor,2) == 2);
    A_idx2 = find(sum(abs(b_dist2) <= maxNeighbor,2) == 2);
    A_idx3 = find(sum(abs(b_dist3) <= maxNeighbor,2) == 2);
    
    %% Iterate through all the neighboring points
    for idx1=1:size(A_idx1,1)
        for idx2=1:size(A_idx2,1)
            for idx3=1:size(A_idx3,1)
                % get the three neighboring points in A
                a = A([A_idx1(idx1), A_idx2(idx2), A_idx3(idx3)],:);
                    
                % calculate the affine transformation from b to a
                try
                    T = fitgeotrans(b,a,'affine');
                catch
                    continue;
                end
                
                % transform the points in b 
                B_affine = transformPointsForward(T,B);
                
                %% Calculate the closest distance between points in A and B
                dist_AB_x = min(abs( repmat(A(:,2),1,size(B_affine,1)) - repmat(B_affine(:,2),1,size(A,1))' ));
                dist_AB_y = min(abs( repmat(A(:,1),1,size(B_affine,1)) - repmat(B_affine(:,1),1,size(A,1))' ));
                dist_AB = sum(sqrt(dist_AB_x.^2 + dist_AB_y.^2));
                
                if dist_AB <= tol
                    return;
                end
            end
        end
    end
    
    % if the maximum number of iterations is met then return a flag
    if iter==maxIter
        B_affine = B;
        flag = true;
    end
end

end

