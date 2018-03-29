function C = evaluateTPS(X,W,A)
    U = @(r) r.^2 .* log(r);
    mag = @(u,x,y) sqrt(sum((u(:,1)-x).^2 + (u(:,2)-y).^2,2));
    
    C = zeros(size(X,1),2);
    for i=1:size(X,1)
        C(i,1) = W(end-2,1) + W(end-1,1)*X(i,1) + W(end,1)*X(i,2) + sum( W(1:end-3,1).*U(mag(A,X(i,1),X(i,2))) ,1);
        C(i,2) = W(end-2,2) + W(end-1,2)*X(i,1) + W(end,2)*X(i,2) + sum( W(1:end-3,2).*U(mag(A,X(i,1),X(i,2))) ,1);
    end
end