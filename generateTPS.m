function W = generateTPS(A,B,l)
    % Where A are fixed points, B are moving points and l is a smothing
    % parameter.
    if ~exist('l','var')
        l = 0;
    end
    
    U = @(r) r.^2 .* log(r);
    mag = @(u,v) sqrt(sum((u-v).^2,2));

    num_p = size(A,1);

    % K
    K = zeros(num_p);
    for i=1:num_p
        for j=1:num_p
            if i ~= j
                K(i,j) = U(mag(B(i,:),B(j,:)));
            else
                K(i,i) = l;
            end
        end
    end
    % P
    P = [ones(num_p,1),B];
    % O
    O = zeros(3);
    % o
    o = zeros(3,1);
    % L
    L = [K,P; P', O];
    L_inv = inv(L);
    % A_plus
    A_plus = [A; zeros(3,2)];
    % W
    W = L_inv*A_plus;
end