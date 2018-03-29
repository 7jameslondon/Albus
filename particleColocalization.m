function indexes = particleColocalization( A, B, boxDistance )
    C = zeros(0,2);
    indexA = zeros(0,1);
    indexB = zeros(0,1);
    iA = 1;
    while  iA <= size(A,1)
        distances = ( B - A(iA,:) ).^2;
        distances = distances(:,1) + distances(:,2);
        [~, closestBIndex] = min( distances );
        withInBox = abs(B(closestBIndex,:) - A(iA,:)) <= boxDistance;
        withInBox = withInBox(:,1) & withInBox(:,2);
        if withInBox
            C(end+1,:) = A(iA,:);
            indexA(end+1) = iA;
            indexB(end+1) = closestBIndex;
        end
        iA = iA + 1;
    end
    
    indexes = struct('indexA', indexA, 'indexB', indexB);
end