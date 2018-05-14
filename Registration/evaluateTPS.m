function X_tps = evaluateTPS(X,W,A)

    % mag - Euclidian norm
    mag = @(u,v) sqrt(sum((u(:,1)-v(:,1)).^2 + (u(:,2)-v(:,2)).^2,2));
    
    % X_tps - the TPS transformed points of X
    X_tps = zeros(size(X,1),2); % pre-allocate array
    
    % Iterate through each pair of points in X
    for i=1:size(X,1)
        % calculate bending energy at each control point
        E = energyTPS(mag(A,X(i,:)));
        % calculate the x corrdinate
        X_tps(i,1) = W(end-2,1) + W(end-1,1)*X(i,1) + W(end,1)*X(i,2) + sum( W(1:end-3,1) .* E ,1);
        % calculate the y corrdinate
        X_tps(i,2) = W(end-2,2) + W(end-1,2)*X(i,1) + W(end,2)*X(i,2) + sum( W(1:end-3,2) .* E ,1);
    end
    
end