function kymograph = generateKymograph( centerLine, width, seperatedStacks, colors)
    % two quick checks that the centerLine is valid
    if xy2r(diff(centerLine([1 3])),diff(centerLine([2 4]))) <= 1 % too small for improfile
        kymograph = 0;
        return;
    end
    if any(isnan(centerLine)) % line is not acutally on image
        kymograph = 0;
        return;
    end

    % set up the lines to make the kymograph along acording to the 'width'
    lineVector = [centerLine(3)-centerLine(1) centerLine(4)-centerLine(2)];
    normalVetor = [lineVector(2) -lineVector(1)]/norm(lineVector);
    normalVetors = repmat(normalVetor, width, 2) .* repmat([-((width-1)/2):((width-1)/2)]', 1, 4);
    lines = repmat(centerLine, width, 1) + normalVetors;
    
    % get the size each layer will be to pre-aloc array sizes
    layerSize = [length(improfile(seperatedStacks{1}(:,:,1), centerLine([1 3]), centerLine([2 4]), 'bilinear')), size(seperatedStacks{1},3)*width];
    % get class of stack
    imageClass = class(seperatedStacks{1}(1,1,1));
    
    % cell array of gray image of each stack's kymograph
    kymLayers = cell(length(seperatedStacks),1); % pre-aloc
    
    for s=1:length(seperatedStacks)
        kymLayers{s} = zeros(layerSize,imageClass); % pre-aloc
        
        for f=1:size(seperatedStacks{s},3) % durration of stack
            for w=1:width
                kymLayers{s}(:,(f-1)*width+w) = improfile(seperatedStacks{s}(:,:,f), lines(w,[1 3]), lines(w,[2 4]), layerSize(1), 'bilinear');
            end
        end
        
        % auto adjust brightness
        kymLayers{s} = imadjust(kymLayers{s});
    end
    
    % colors each layer and combines them into an RGB image
    kymograph = rgbCombineSeperatedImages(kymLayers, colors);
    %kymograph = cat(1,kymograph,ones(3,size(kymograph,2),3),cat(3,kymLayers{1}.*0,kymLayers{1},kymLayers{1}.*0),ones(3,size(kymograph,2),3),cat(3,kymLayers{2},kymLayers{2}.*0,kymLayers{2}.*0));
end