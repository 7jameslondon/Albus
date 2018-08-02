function generateRegistration(hObject,handles)
    % uses a thin-plate spline to regiester channels

    %% Setup
    hWaitBar = waitbar(0,'Generating map ...', 'WindowStyle', 'modal');
    
    seperatedStacks = getappdata(handles.f,'data_mapping_originalSeperatedStacks');
    particleSettings = getappdata(handles.f,'mapping_particleSettings');
    currentFrame = get(handles.axesControl.currentFrame.JavaPeer,'Value');
    colors = getappdata(handles.f,'colors');
    invertImage = handles.map.invertCheckbox.Value;
    numChannels = size(seperatedStacks,1);
    
    displacmentFields = cell(numChannels,1); % pre-aloc
    
    %% Find the postition of the particles in the first channel
    I = seperatedStacks{1}(:,:,currentFrame);
    % invert
    if invertImage
        I = imcomplement(I);
    end
    % this will  filter and adjust brightness as needed
    particles = findParticles(I, ...
                        particleSettings(1).minIntensity, ...
                        particleSettings(1).maxIntensity, ...
                        particleSettings(1).filterSize, ...
                        'Method', 'GaussianFit');
    initPositions = particles{1}.Center;
    
    waitbar(1/numChannels);
    
                
    %% Iterate through each channel to find the TSP weights
    for s = 2:numChannels % no parfor as findParticles has parfor
        
        %% Find particle positions in each channel
        I = seperatedStacks{s}(:,:,currentFrame);
        % invert
        if invertImage
            I = imcomplement(I);
        end
        % this will  filter and adjust brightness as needed
        particles = findParticles(I, ...
                            particleSettings(s).minIntensity, ...
                            particleSettings(s).maxIntensity, ...
                            particleSettings(s).filterSize, ...
                            'Method', 'GaussianFit');
        positions = particles{1}.Center; % just one frame of particles
        
        
        %% Find the TPS transformation from this channel to the first channel
        % First approximatly transform the the particles in each channel so
        % they are mostly alighed with the first channel using an affine 
        % transformation.
        [affine_positions, flag] = findAffine(initPositions, positions, 250, size(initPositions,1)/3, mean(size(I))/30);
        if flag % a flag is returned if no transformation was found
            error('Try findAffine with looser parameters');
        end
        
        % Using the approximatly alighned positions, find the indexes of the
        % overlaping particles in each channel.
        [initPositions_idx, affine_positions_idx] = matchPoints(initPositions, affine_positions);
        
        % Select the particles that were matched
        initPositions_matching = initPositions(initPositions_idx,:);
        positions_matching = positions(affine_positions_idx,:);
        
        
        % Calculate the TPS transformation using the now matched particles
        smoothing = size(positions_matching,1);
        TPSWeights = calculateTPS(initPositions_matching, positions_matching, smoothing);
        
        %% Apply the TPS transformation to a mesh grid to find the displacment field
        [X,Y] = meshgrid(1:size(I,2),1:size(I,1)); 
    
        XY_tps = evaluateTPS([X(:),Y(:)], TPSWeights, positions_matching); % transform the grid with the TPS
        X_tps = X - reshape(XY_tps(:,1),size(X,1),size(X,2)); % extract the transform x corridnates 
        Y_tps = Y - reshape(XY_tps(:,2),size(Y,1),size(Y,2)); % extract the transform y corridnates 
        
        displacmentFields{s} = cat(3,X_tps,Y_tps);

        waitbar(s/numChannels);
    end
    
    %% Save data
    setappdata(handles.f,'displacmentFields',displacmentFields);
    
    calculateROIMask(hObject,handles);
    
    waitbar(10/10);
    delete(hWaitBar);
end