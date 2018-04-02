function kymographs = generateAllKymographs( centerLines, width, seperatedStacks, colors)

    %% Setup all the line that will be iterated over
    numKyms = size(centerLines,1); % how many kymographs will be generated
    imageClass = class(seperatedStacks{1}(1,1,1)); % class of the stacks
    
    lines = cell(numKyms,1); % pre-aloc
    layerSize = zeros(numKyms,1); % pre-aloc
    for k=1:numKyms
        % for each centerline set up the "lines" to make the kymograph along acording to the 'width'
        lineVector = [centerLines(k,3)-centerLines(k,1) centerLines(k,4)-centerLines(k,2)];
        normalVetor = [lineVector(2) -lineVector(1)]/norm(lineVector);
        normalVetors = repmat(normalVetor, width, 2) .* repmat([-((width-1)/2):((width-1)/2)]', 1, 4);
        lines(k) = {repmat(centerLines(k,:), width, 1) + normalVetors};
        
        % get the size each layer will be to pre-aloc array sizes
        layerSize(k) = length(improfile(seperatedStacks{1}(:,:,1), centerLines(k,[1 3]), centerLines(k,[2 4]), 'bilinear'));
    end

    %% Interpolate over the lines for each stack to create each channel layer
    % "kymLayers" cell array of gray image of each stack's kymograph
    kymLayers = cell(numKyms, length(seperatedStacks)); % pre-aloc
    kymographs = cell(numKyms,1); % pre-aloc
    for s=1:length(seperatedStacks)        
        % pre-allocate the sizes of kymLayers
        for k=1:numKyms
            kymLayers{k,s} = zeros(layerSize(k), size(seperatedStacks{1},3)*width); % pre-aloc
        end
        
        for f=1:size(seperatedStacks{s},3) % durration of stack
            % setup the interpolator for this image
            GI = griddedInterpolant(im2double(seperatedStacks{s}(:,:,f)) ,'linear');
            
            for k=1:numKyms
                for w=1:width
                    x = linspace(lines{k}(w,1), lines{k}(w,3), layerSize(k))';
                    y = linspace(lines{k}(w,2), lines{k}(w,4), layerSize(k))';

                    kymLayers{k,s}(:,(f-1)*width+w) = GI(y,x); % y comes first
                end
            end
        end
        
        % auto adjust brightness
        for k=1:numKyms
            kymLayers{k,s} = imadjust(kymLayers{k,s});
        end
    end
    
    %% Combine the channel layers into an RGB image
    for k=1:numKyms
        % combine the layers from each seperatedStack into an RGB image
        I = rgbCombineSeperatedImages(kymLayers(k,:), colors);
        
        % convert image to original class
        switch imageClass
            case 'uint8'
                kymographs{k} = im2uint8(I);
            case 'uint16'
                kymographs{k} = im2uint16(I);
        end
    end
    
end

