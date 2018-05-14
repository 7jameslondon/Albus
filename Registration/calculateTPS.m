function W = calculateTPS(A,B,wiggle)
% Calculates the thin-plate spline(TPS) weights to transform points of A 
% to the points of B. There is a optional "wiggle" paramerter to allow for 
% small diffrences between the points if transformed by a "perfect" TPS.
%
% The varibles follow convension as described in the refrence.
%
% Bases in part on:
% G. Donato and S. Belongie, Approximate thin plate spline mappings, in 
% Proceedings of the European Conference on Computer Vision, 2002, 
% pp. 13-31.
    warning('off','MATLAB:singularMatrix');

    %% Setup varibles and functions
    % if the wiggle parameter was not passed then set it to zero
    if ~exist('wiggle','var')
        wiggle = 0;
    end
    % number of point in A and B
    num_p = size(A,1);

    %% Calculate the sections of the L matrix
    % K - the bending energies between the points in B.
    %     Where the element K_ij = U( mag(B_i,B_j) ) where i~=j
    %     and the diagonal elments are all the wiggle parameter.
    K = zeros(num_p); % pre-allocate matrix
    for i=1:num_p
        for j=1:num_p
            if i ~= j
                K(i,j) = energyTPS(norm(B(i,:)-B(j,:)));
            else
                K(i,i) = energyTPS(wiggle); % wiggle=0 => energyTPS=0
            end
        end
    end
    
    % P - a column of ones joined with the points of B.
    %     Where the row i of P is [ 1 Bx_i By_i ].
    P = [ones(num_p,1),B];
    
    % O - 3x3 of zeros
    O = zeros(3);
    
    % L - the partitioned matrix of possible bending modes between points
    L = [K, P; P', O];
    
    %% Solve for the TPS weights
    % A_plus - three rows of zeros joined with the bottom of points A.
    A_plus = [A; zeros(3,2)];
    % W
    W = L\A_plus; % not inv(L)*A_plus
    
    warning('on','MATLAB:singularMatrix');
end

