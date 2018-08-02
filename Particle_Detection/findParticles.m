%% Find particles in each frame of a stack
%
% Returns a cell array with one cell for each frame. Each cell contains a 
% double of the particle centers. Each paticle is a row and the first 
% column is the x position and the second column is the y position.
% Works fine with one image rather then a stack but the final return is a
% cell array with the first cell containing all the particle centers.
% Speed: Runs at optimal speeds. Does not depend or number of particles in
%        frame but does depend on size of frame. 

% ( S, gaussFilterSigma, minMeanPeakIntensity, maxMeanPeakIntensity )
%
% Names-Value pairs
% Method            Default: 'WeightedCentroid'
% DisplayAxes       Default: []

function particlesByFrame = findParticles( varargin )
    %% Parse inputs
    p = inputParser;
    
    p.addRequired('S');
    p.addRequired('minMeanPeakIntensity');
    p.addRequired('maxMeanPeakIntensity');
    p.addOptional('gaussFilterSigma',0);
    
    p.addParameter('Method','Centroid');
    p.addParameter('DisplayAxes',[]);
    p.addParameter('Color','r');
    
    p.addParameter('Mask',-1);
    p.addParameter('EdgeDistance',0);
    
    p.addParameter('MaxEccentricity',1); % this can not be used with tracking or with multiple stacks
    p.addParameter('MinDistance',-1); % this can not be used with tracking or with multiple stacks
    
    p.addParameter('Waitbar',[]); % only for gaussian methods

    p.parse(varargin{:});
    v = p.Results;
    
    % set defualt of mask
    if v.Mask(1) == -1
        v.Mask = ones(size(v.S(:,:,1)),'logical');
    end

    %% Select Method
    particlesByFrame = cell(size(v.S,3),1); % pre-aloc

    if strcmp(v.Method,'Centroid')
        %% WeightedCentroid method
        if size(v.S,3) > 10
            parfor f = 1:size(v.S,3) % iterate through frames
                I = v.S(:,:,f);
                particlesByFrame{f} = findByCentroid(I, v.Mask, v.gaussFilterSigma, v.minMeanPeakIntensity, v.maxMeanPeakIntensity, v.MaxEccentricity);
            end
        else
            for f = 1:size(v.S,3) % iterate through frames
                I = v.S(:,:,f);
                particlesByFrame{f} = findByCentroid(I, v.Mask, v.gaussFilterSigma, v.minMeanPeakIntensity, v.maxMeanPeakIntensity, v.MaxEccentricity);
            end
        end
        
    elseif strcmp(v.Method,'GaussianFit')
        %% GaussianFit method
        [meshX,meshY] = meshgrid(1:size(v.S(:,:,1),2), 1:size(v.S(:,:,1),1));
        XY = [meshX(:),meshY(:)];
        gauss2d = fittype(@(a,mu1,mu2,sig,x1,y1) a*exp(-((x1-mu1).^2 + (y1-mu2).^2)/(2*sig^2)), 'independent', {'x1','y1'});
        
        for f = 1:size(v.S,3) % iterate through frames
            if ~isempty(v.Waitbar)
                waitbar(f/size(v.S,3),v.Waitbar);
            end
            I = v.S(:,:,f);
            particlesByFrame{f} = findByGauss(I, v.Mask, v.gaussFilterSigma, v.minMeanPeakIntensity, v.maxMeanPeakIntensity, v.MaxEccentricity);
        end

    elseif strcmp(v.Method,'FastGaussianFit')
        %% GaussianFit method
        [meshX,meshY] = meshgrid(1:size(v.S(:,:,1),2), 1:size(v.S(:,:,1),1));
        
        for f = 1:size(v.S,3) % iterate through frames
            if ~isempty(v.Waitbar)
                waitbar(f/size(v.S,3),v.Waitbar);
            end
            I = v.S(:,:,f);
            particlesByFrame{f} = findByFastGauss(I, v.Mask, v.gaussFilterSigma, v.minMeanPeakIntensity, v.maxMeanPeakIntensity, v.MaxEccentricity);
        end

    end
   
    
    %% Remove Clustering
    % only for images, not stacks
    if v.MinDistance ~=-1
        % Error if this is a stack
        if size(v.S,3) > 1
            error('This is for single images only!');
        end
        
        if strcmp(v.Method,'Centroid')
            centers = particlesByFrame{1};
        elseif strcmp(v.Method,'GaussianFit') || strcmp(v.Method,'FastGaussianFit')
            centers = particlesByFrame{1}.Center;
        end

        % remove particle id's that are seperated from others by MinDistance
        d_r = zeros(size(centers,1)); % pre-aloc, distances between centers
        for i=1:size(centers,1)
            c = centers(i,:);
            d_xy = centers - c; % calculate x and y distance
            d_r(i,:) = sqrt(sum(d_xy.^2,2)); % calculate euclidian distance
            d_r(i,i) = inf; % set distance to self to inf
        end
        
        % Remove clustered particles
        removedInd = any( d_r < v.MinDistance ,2);
        particlesByFrame{1}(removedInd,:) = [];
    end
    
    %% Remove particles too close to edge
    if v.EdgeDistance > 0
        % create a new mask with EdgeDistance pixels removed from sides
        maskWDist = bwmorph(v.Mask,'thin',v.EdgeDistance);
        
        for f = 1:size(v.S,3)
            % get centers
            if strcmp(v.Method,'Centroid')
                centers = particlesByFrame{f};
            elseif strcmp(v.Method,'GaussianFit') || strcmp(v.Method,'FastGaussianFit')
                centers = particlesByFrame{f}.Center;
            end
            
            centers = round(centers);
            centers(centers < 1) = 1;
            centers_x = centers(:,2);
            centers_x(centers_x > size(maskWDist,1)) = size(maskWDist,1);
            centers_y = centers(:,1);
            centers_y(centers_y > size(maskWDist,2)) = size(maskWDist,2);
            
            % remove particles who center are not on the 'maskWDist' mask
            centerInd = sub2ind(size(maskWDist), centers_x, centers_y);
            removedInd = ~maskWDist(centerInd);
            particlesByFrame{f}(removedInd,:) = [];
        end
    end
    
    
    %% Optional: Mark particles
    % Optionaly, display the filtered image and mark the particles on 
    % the image in provided axes with a red dot. This is intended to 
    % only be used when a single image is provided.
    if ~isempty(v.DisplayAxes)
        hold on;
        if strcmp(v.Method,'GaussianFit')
            plt = plot(v.DisplayAxes, particlesByFrame{1}.Center(:,1), particlesByFrame{1}.Center(:,2), '.');
        else
            plt = plot(v.DisplayAxes, particlesByFrame{1}(:,1), particlesByFrame{1}(:,2), '.');
        end
        set(plt,'Color',v.Color)
        hold off;
    end
    
    varargout{1} = particlesByFrame;
    varargout{2} = v.S(:,:,1);
    
    %% Functions

    function particles = findByGauss( I, Mask, gaussFilterSigma, minMeanPeakIntensity, maxMeanPeakIntensity, maxEccentricity )
        % gaussian filter image
        if gaussFilterSigma > 0.1
            J = imgaussfilt(I, gaussFilterSigma);
        else
            J = I;
        end
        % auto brightness filtered image
        J(~Mask) = 0;
        J(Mask) = imadjust(J(Mask));
        % get just the local peaks
        BW = imregionalmax(J);
        % for each peak get the 'WeightedCentroid','MeanIntensity'
        stats = regionprops('Table',BW,J,'WeightedCentroid','MeanIntensity','BoundingBox','MajorAxisLength','MinorAxisLength','Eccentricity');
        % select peaks with mean intensity between min and max parameter
        selectedIdx = stats.MeanIntensity >= minMeanPeakIntensity & stats.MeanIntensity <= maxMeanPeakIntensity  & stats.Eccentricity <= maxEccentricity;
        selectedStats = stats(selectedIdx,:);

        numParticles = size(selectedStats,1);
        particles = table(zeros(numParticles,2),zeros(numParticles,1),zeros(numParticles,1),zeros(numParticles,4),'VariableNames',{'Center','HalfWidth','PeakIntensity','FitBox'}); % pre-aloc
        Z = double(I(:));
        
        parfor p=1:numParticles
            centerEst      = selectedStats.WeightedCentroid(p,:);
            halfWidthEst   = (selectedStats.MajorAxisLength(p) + selectedStats.MinorAxisLength(p))/4;
            heightEst      = double(I(ceil(centerEst(2)),ceil(centerEst(1))));
            boundingBox    = selectedStats.BoundingBox(p,:);
            fitBox         = [boundingBox(1)-boundingBox(3), boundingBox(1)+boundingBox(3)*2, boundingBox(2)-boundingBox(4), boundingBox(2)+boundingBox(4)*2];
            fitBox         = fitBox + round([-halfWidthEst, halfWidthEst, -halfWidthEst, halfWidthEst]);
            
            fitExc = excludedata(meshX(:), meshY(:), 'box', fitBox);
            startPoint = [heightEst, centerEst(1), centerEst(2), halfWidthEst];
            
            f = fit(XY, Z, gauss2d, 'StartPoint', startPoint, 'Exclude', fitExc);

            particles(p,:) = {[f.mu1,f.mu2],f.sig,f.a,fitBox}; % center, halfwidth, peak, fitbox
        end

    end


    function particles = findByFastGauss( I, Mask, gaussFilterSigma, minMeanPeakIntensity, maxMeanPeakIntensity, maxEccentricity )
        % gaussian filter image
        if gaussFilterSigma > 0.1
            J = imgaussfilt(I, gaussFilterSigma);
        else
            J = I;
        end
        % auto brightness filtered image
        J(~Mask) = 0;
        J(Mask) = imadjust(J(Mask));
        % get just the local peaks
        BW = imregionalmax(J);
        % for each peak get the 'WeightedCentroid','MeanIntensity'
        stats = regionprops('Table',BW,J,'MeanIntensity','BoundingBox','MajorAxisLength','MinorAxisLength','Eccentricity');
        % select peaks with mean intensity between min and max parameter
        selectedIdx = stats.MeanIntensity >= minMeanPeakIntensity & stats.MeanIntensity <= maxMeanPeakIntensity  & stats.Eccentricity <= maxEccentricity;
        selectedStats = stats(selectedIdx,:);

        numParticles = size(selectedStats,1);
        particles = table(zeros(numParticles,2),zeros(numParticles,1),zeros(numParticles,1),zeros(numParticles,4),'VariableNames',{'Center','HalfWidth','PeakIntensity','FitBox'}); % pre-aloc
        Z = double(I(:));
        
        parfor p=1:numParticles
            halfWidthEst   = (selectedStats.MajorAxisLength(p) + selectedStats.MinorAxisLength(p))/4;
            boundingBox    = selectedStats.BoundingBox(p,:);
            fitBox         = [boundingBox(1)-boundingBox(3), boundingBox(1)+boundingBox(3)*2, boundingBox(2)-boundingBox(4), boundingBox(2)+boundingBox(4)*2];
            fitBox         = fitBox + round([-halfWidthEst, halfWidthEst, -halfWidthEst, halfWidthEst]);
            
            fitInd = ~excludedata(meshX(:), meshY(:), 'box', fitBox);
            
            [xc,yc,Amp,width] = gaussMLH( meshX(fitInd), meshY(fitInd), Z(fitInd), .2 );

            particles(p,:) = {[xc,yc],width,Amp,fitBox}; % center, halfwidth, peak, fitbox
        end

    end

end


function particleCenters = findByCentroid( I, Mask, gaussFilterSigma, minMeanPeakIntensity, maxMeanPeakIntensity, maxEccentricity)
    % gaussian filter image
    if gaussFilterSigma > 0.1
        I = imgaussfilt(I, gaussFilterSigma);
    end
    % auto brightness filtered image
    I(~Mask) = 0;
    I(Mask) = imadjust(I(Mask));
    % get just the local peaks
    BW = imregionalmax(I);
    % for each peak get the 'Centroid','MeanIntensity'
    stats = regionprops('Table',BW,I,'WeightedCentroid','MeanIntensity','Eccentricity');
    % select peaks with mean intensity between min and max parameter
    selectedIdx = stats.MeanIntensity >= minMeanPeakIntensity & stats.MeanIntensity <= maxMeanPeakIntensity & stats.Eccentricity <= maxEccentricity;
    selectedStats = stats(selectedIdx,:);
    % add all centers to 'particlesByFrame'
    particleCenters = selectedStats.WeightedCentroid;
end