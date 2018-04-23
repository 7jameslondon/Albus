function  C = approximatelyCorrectParticles( A, B, searchBoxSize, percentMatching, accuracy, hWaitBar )

    %set up some basic matrix manipulation functions
    removeThirdCol = @(M) M(:,1:2);
    transformMatrixWithT = @(M,T) removeThirdCol((T*[M,ones(size(M,1),1)]')');
    transformMatrix = @(M,x,y,r) transformMatrixWithT(M,[cos(r) -sin(r) x; sin(r) cos(r) y; 0 0 1]);
    getTransformationMatrix = @(M,N) [N,ones(size(N,1),1)]'/[M,ones(size(M,1),1)]'; % T*M=N

    C = B;
    searchBox = ( max(max([A;B])) - min(min([A;B])) ) * searchBoxSize;
    
    attempts = 0;
    flag = 0;
    
    while ~flag  % corectly correlated 
        flag = 0;
        attempts = attempts+1;
        % randomly select a point
        selectedIndexesA = zeros(3,1);
        while selectedIndexesA(1) == selectedIndexesA(2) || selectedIndexesA(1) == selectedIndexesA(3) || selectedIndexesA(2) == selectedIndexesA(3)
            selectedIndexesA = ceil(rand(3,1)*size(A,1));
        end

        selectedPointsA = A(selectedIndexesA,:);

        indexsInSearchBox1 = abs(B-selectedPointsA(1,:)) <= searchBox;
        indexsInSearchBox2 = abs(B-selectedPointsA(2,:)) <= searchBox;
        indexsInSearchBox3 = abs(B-selectedPointsA(3,:)) <= searchBox;

        indexsInSearchBox1 = indexsInSearchBox1(:,1) & indexsInSearchBox1(:,2);
        indexsInSearchBox2 = indexsInSearchBox2(:,1) & indexsInSearchBox2(:,2);
        indexsInSearchBox3 = indexsInSearchBox3(:,1) & indexsInSearchBox3(:,2);

        selectedPointsB1 = B(find(indexsInSearchBox1),:);
        selectedPointsB2 = B(find(indexsInSearchBox2),:);
        selectedPointsB3 = B(find(indexsInSearchBox3),:);

        for iPoint1 = 1:size(selectedPointsB1,1)
            for iPoint2 = 1:size(selectedPointsB2,1)
                for iPoint3 = 1:size(selectedPointsB3,1)                
                    BtoATransMat = getTransformationMatrix([selectedPointsB1(iPoint1,:); selectedPointsB2(iPoint2,:); selectedPointsB3(iPoint3,:)], selectedPointsA);
                    C = transformMatrixWithT(B,BtoATransMat);
                    
                    % check if particles are now matching
                    tempA = A;
                    tempC = C;
                    numberOfMatches = 0;
                    smallerTotalParticles = min(size(A,1),size(C,1));
                    iA = 1;
                    while iA <= size(tempA,1) && ~flag
                        iC = 1;
                        matchFlag = false;
                        while iC <= size(tempC,1) && iA <= size(tempA,1) && ~flag
                            if min(abs(tempA(iA,:) - tempC(iC,:)) <= accuracy)
                                tempA(iA,:) = [];
                                tempC(iC,:) = [];
                                matchFlag = true;
                                numberOfMatches = numberOfMatches+1;
                                if numberOfMatches/smallerTotalParticles >= percentMatching
                                    flag = true;
                                    break
                                end
                            else
                                iC = iC+1;
                            end
                        end
                        if ~matchFlag
                            iA = iA+1;
                        end
                    end
                    
                    if flag
                        break
                    end
                end
                if flag
                    break
                end
            end
            if flag
                break
            end
        end
    end
end

