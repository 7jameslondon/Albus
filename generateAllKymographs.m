function generateAllKymographs( hObject, handles)
    %% Get data
    kyms = getappdata(handles.f,'kyms');
    
    kyms_images = getappdata(handles.f,'data_kym_images');
    
    if getappdata(handles.f,'isMapped')
        seperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');
        colors = getappdata(handles.f,'colors');
    else
        seperatedStacks = {getappdata(handles.f,'data_video_stack')};
        colors = [1 1 1];
    end
    
    width = str2num(handles.kym.widthTextbox.String);
    
    centerLines = kyms.Position;
    
    kymIndex = find(~kyms.ImageGenerated); % which kymographs need to be generated
    numKyms = size(kymIndex,1); % how many kymographs will be generated
    
    if numKyms==0
        return;
    end
    
    hWaitBar = waitbar(0,'Generating kymographs...', 'WindowStyle', 'modal');
    totalWait = numKyms + (numKyms*length(seperatedStacks)) + numKyms;

    %% Setup all the line that will be iterated over
    imageClass = class(seperatedStacks{1}(1,1,1)); % class of the stacks
    
    lines = cell(numKyms,1); % pre-aloc
    layerSize = zeros(numKyms,1); % pre-aloc
    for i=1:numKyms
        waitbar(i/totalWait);
        k = kymIndex(i);
        % for each centerline set up the "lines" to make the kymograph along acording to the 'width'
        lineVector = [centerLines(k,3)-centerLines(k,1) centerLines(k,4)-centerLines(k,2)];
        normalVetor = [lineVector(2) -lineVector(1)]/norm(lineVector);
        normalVetors = repmat(normalVetor, width, 2) .* repmat([-((width-1)/2):((width-1)/2)]', 1, 4);
        lines(i) = {repmat(centerLines(k,:), width, 1) + normalVetors};
        
        % get the size each layer will be to pre-aloc array sizes
        layerSize(i) = length(improfile(seperatedStacks{1}(:,:,1), centerLines(k,[1 3]), centerLines(k,[2 4]), 'bilinear'));
    end

    %% Interpolate over the lines for each stack to create each channel layer
    % "kymLayers" cell array of gray image of each stack's kymograph
    kymLayers = cell(numKyms, length(seperatedStacks)); % pre-aloc
    for s=1:length(seperatedStacks)        
        waitbar(((s*numKyms)+numKyms)/totalWait);
        % pre-allocate the sizes of kymLayers
        for i=1:numKyms
            kymLayers{i,s} = zeros(layerSize(i), size(seperatedStacks{1},3)*width); % pre-aloc
        end
        
        for f=1:size(seperatedStacks{s},3) % durration of stack
            % setup the interpolator for this image
            GI = griddedInterpolant(im2double(seperatedStacks{s}(:,:,f)) ,'linear');
            
            for i=1:numKyms
                for w=1:width
                    x = linspace(lines{i}(w,1), lines{i}(w,3), layerSize(i))';
                    y = linspace(lines{i}(w,2), lines{i}(w,4), layerSize(i))';

                    kymLayers{i,s}(:,(f-1)*width+w) = GI(y,x); % y comes first
                end
            end
        end
    end    
    
    %% Combine the channel layers into an RGB image
    for i=1:numKyms
        waitbar((i+totalWait-numKyms)/totalWait);
        
        k = kymIndex(i);
        
        % Adjust the brighteness of the kymograph layers
        if any(kyms.Brightness{k} == -1) 
            brightness = zeros(length(seperatedStacks),2);
            
            if ~handles.kym.syncBrightness.Value % used as a flag for autobrightness
                for s=1:length(seperatedStacks)
                    brightness(s,:) = stretchlim(kymLayers{i,s})';
                    kymLayers{i,s} = imadjust(kymLayers{i,s}, brightness(s,:));
                end
            else
                for s=1:length(seperatedStacks)
                    brightness(s,:) = stretchlim(kymLayers{i,s})';
                end
                brightnessValues = mean(brightness,1);
                for s=1:length(seperatedStacks)
                    brightness(s,:) = brightnessValues;
                    kymLayers{i,s} = imadjust(kymLayers{i,s}, brightnessValues);
                end
            end
            
            kyms.Brightness{k} = brightness;
        else
            for s=1:length(seperatedStacks)
                kymLayers{i,s} = imadjust(kymLayers{i,s}, kyms.Brightness{k}(s,:));
            end
        end
        
        % combine the layers from each seperatedStack into an RGB image
        I = rgbCombineSeperatedImages(kymLayers(i,:), colors);
        
        % convert image to original class
        switch imageClass
            case 'uint8'
                kymograph = im2uint8(I);
            case 'uint16'
                kymograph = im2uint16(I);
        end
        
        kyms_images{k} = kymograph;
    end
    
    %% save
    kyms.ImageGenerated = ones(size(kyms.ImageGenerated),'logical');
    
    setappdata(handles.f,'data_kym_images',kyms_images);
    setappdata(handles.f,'kyms',kyms);
    
    delete(hWaitBar);
end

