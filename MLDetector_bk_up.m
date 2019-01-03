function particles = MLDetector_bk_up(I,minJ,sizeP,centroidFlag,centerFlag)

    % Apply a guassian filter to reduse noice when finding canidates
    J = imgaussfilt(I, sizeP/5);
    
    % Find local maximum
    localM = imregionalmax(J);
    
    % Remove local maximum less than threshold parameter
    localM(J<minJ) = 0;
    
    % If there are no canidate positions then exit
    if sum(localM,'all') < 1
        particles = [];
        return;
    end
    
    % Find center of canidates
    pixelIdx = label2idx(bwlabel(localM));
    numCanidates = size(pixelIdx,2);
    centroids = zeros(numCanidates,2);
    for i = 1:numCanidates
        [pixelY, pixelX] = ind2sub(size(localM), pixelIdx{i});
        centroids(i,:) = mean([pixelX, pixelY],1);
    end
    
    % If only centroid center is desired return the values
    if centroidFlag
        particles = struct('ux',num2cell(centroids(:,1)'),...
                            'uy',num2cell(centroids(:,2)'));
        return;
    end
    
    % Pre-alocate particles
    p = 1;
    if centerFlag
        particles = struct( 'ux',[],...
                            'uy',[]);
    else
        particles = struct( 'ux',[],...
                            'uy',[],...
                            's', [],...
                            'A', [],...
                            'B', [],...
                            'L', []);
    end
    particles(numCanidates).ux = [];
    
    % Grab info for fitting
    [meshX,meshY] = meshgrid(1:size(I(:,:,1),2), 1:size(I(:,:,1),1));
    dI = double(I);
    gauss = gauss2DWBgFun;
    B = 0;
    
    % Calcualte the bounding box around the canidate centers
    boxY1 = max(round(centroids(:,2) - sizeP/2), 1);
    boxY2 = min(round(centroids(:,2) + sizeP/2), size(dI,1));
    boxX1 = max(round(centroids(:,1) - sizeP/2), 1);
    boxX2 = min(round(centroids(:,1) + sizeP/2), size(dI,2));
    
    for i = 1:numCanidates
        Z =    dI(boxY1(i):boxY2(i), boxX1(i):boxX2(i));
        X = meshX(boxY1(i):boxY2(i), boxX1(i):boxX2(i));
        Y = meshY(boxY1(i):boxY2(i), boxX1(i):boxX2(i));
        
        if centerFlag
            [ux, uy] = MLFitNoBg( Z, X, Y);
            particles(i).ux = ux;
            particles(i).uy = uy;
        else
            [ux, uy, s, A, B] = MLFitWBg( Z, X, Y);
            
            gaussP = gauss(X,Y,ux,uy,s,1,0);
            gaussL = mean(Z .* gaussP, [1 2]);
            %noiseL = mean(Z  / numel(Z), [1 2]);
            
            particles(i).ux = ux;
            particles(i).uy = uy;
            particles(i).s = s;
            particles(i).A = A;
            particles(i).B = B;
            particles(i).L = gaussL;
        end
    end
end