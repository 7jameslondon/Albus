function particles = MLDetector(I,minJ,logWidth,boundRadius,method)

    %% Centroid
    % Apply a 1 pixel width guassian filter to reduse noice when fitting
    I = imgaussfilt(I,0.5);
    % Apply a laplassian of the gussian filter to remove noise when finding
    % canndiates
    J = imfilter(I, fspecial('log',boundRadius*2,logWidth), 'symmetric');
    
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
        particles = struct('x',num2cell(centroids(:,1)'),...
                            'y',num2cell(centroids(:,2)'));
        return;
    end
    
    %% ML Fitting setup    
    % Grab info for fitting
    [meshX,meshY] = meshgrid(1:size(I(:,:,1),2), 1:size(I(:,:,1),1));
    dI = double(I);
    
    % Calcualte the bounding box around the canidate centers
    boxY1 = max(round(centroids(:,2) - boundRadius), 1);
    boxY2 = min(round(centroids(:,2) + boundRadius), size(I,1));
    boxX1 = max(round(centroids(:,1) - boundRadius), 1);
    boxX2 = min(round(centroids(:,1) + boundRadius), size(I,2));

    %% ML Fitting
    if strcmp(method,'MLE Center Only')
        
        particles = struct( 'x',[],...
                            'y',[]);
        particles(numCanidates).x = [];
                        
        for i = 1:numCanidates
            Z =    dI(boxY1(i):boxY2(i), boxX1(i):boxX2(i));
            X = meshX(boxY1(i):boxY2(i), boxX1(i):boxX2(i));
            Y = meshY(boxY1(i):boxY2(i), boxX1(i):boxX2(i));

            [x, y] = MLFitNoBg( Z, X, Y);
            particles(i).x = x;
            particles(i).y = y;
        end
        
    elseif strcmp(method,'MLE Full')
        
        particles = struct( 'x',[],...
                            'y',[],...
                            's', [],...
                            'A', [],...
                            'B', [],...
                            'L', []);
        particles(numCanidates).x = [];
            
        gauss = gauss2DWBgFun;
        q = 0;
        
        for i = 1:numCanidates
            Z =    dI(boxY1(i):boxY2(i), boxX1(i):boxX2(i));
            X = meshX(boxY1(i):boxY2(i), boxX1(i):boxX2(i));
            Y = meshY(boxY1(i):boxY2(i), boxX1(i):boxX2(i));
            
            [x, y, s, A, B] = MLFitWBg( Z, X, Y);
            
            gaussP = gauss(X,Y,x,y,s,A,B) / (A + B*numel(Z));
            gaussL = sum(Z .* gaussP, 'all');
            noiseL = sum(Z / numel(Z), 'all');
            
            if gaussL > noiseL 
                q = q + 1;
                
                particles(q).x = x;
                particles(q).y = y;
                particles(q).s = s;
                particles(q).A = A;
                particles(q).B = B;
                particles(q).L = gaussL;
            end
        end
        
        particles = particles(1:q);
        
    end
end