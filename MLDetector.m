function particles = MLDetector(I,minJ,sizeP,method)
    %% Centroid
    % Apply a guassian filter to reduse noice when finding canidates
    J = imgaussfilt(I, sizeP/5);
    %J = I;
    
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
    if strcmp(method,'Centroid')
        particles = struct('ux',num2cell(centroids(:,1)'),...
                            'uy',num2cell(centroids(:,2)'));
        return;
    end
    
    %% ML Fitting setup    
    % Grab info for fitting
    [meshX,meshY] = meshgrid(1:size(I(:,:,1),2), 1:size(I(:,:,1),1));
    dI = double(I);
    gauss = gauss2DWBgFun;
    B = 0;
    
    % Calcualte the bounding box around the canidate centers
    boxY1 = max(round(centroids(:,2) - sizeP), 1);
    boxY2 = min(round(centroids(:,2) + sizeP), size(dI,1));
    boxX1 = max(round(centroids(:,1) - sizeP), 1);
    boxX2 = min(round(centroids(:,1) + sizeP), size(dI,2));

    %% ML Fitting
    if strcmp(method,'MLE Center Only')
        
        particles = struct( 'ux',[],...
                            'uy',[]);
        particles(numCanidates).ux = [];
                        
        for i = 1:numCanidates
            Z =    dI(boxY1(i):boxY2(i), boxX1(i):boxX2(i));
            X = meshX(boxY1(i):boxY2(i), boxX1(i):boxX2(i));
            Y = meshY(boxY1(i):boxY2(i), boxX1(i):boxX2(i));

            [ux, uy] = MLFitNoBg( Z, X, Y);
            particles(i).ux = ux;
            particles(i).uy = uy;
        end
        
    elseif strcmp(method,'MLE Full')
        
        particles = struct( 'ux',[],...
                            'uy',[],...
                            's', [],...
                            'A', [],...
                            'B', [],...
                            'L', []);
        particles(numCanidates).ux = [];
                        
        q = 0;
        
        for i = 1:numCanidates
            Z =    dI(boxY1(i):boxY2(i), boxX1(i):boxX2(i));
            X = meshX(boxY1(i):boxY2(i), boxX1(i):boxX2(i));
            Y = meshY(boxY1(i):boxY2(i), boxX1(i):boxX2(i));
            
            [ux, uy, s, A, B] = MLFitWBg( Z, X, Y);
            
            gaussP = gauss(X,Y,ux,uy,s, A , B) / (A + B*numel(Z));
            gaussL = sum(Z .* gaussP, 'all');
            noiseL = sum(Z / numel(Z), 'all');
            
            if gaussL > noiseL 
                q = q + 1;
                
                particles(q).ux = ux;
                particles(q).uy = uy;
                particles(q).s = s;
                particles(q).A = A;
                particles(q).B = B;
                particles(q).L = gaussL;
            end
        end
        
        particles = particles(1:q);
        
    end
end


%             XY = zeros(sum(Z,'all'),2);
%             q = 1;
%             for j = 1:numel(Z)
%                 [x,y] = ind2sub(size(Z),j);
%                 XY(q:q+Z(j)-1,:) = repmat([x + boxX1(i), y + boxY1(i)], Z(j), 1);
%                 q = q + Z(j);
%             end
%             G = fitgmdist(XY,2)
%             particles(i)