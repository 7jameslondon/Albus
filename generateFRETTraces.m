function generateFRETTraces(hObject, handles, refresh)
    hWaitBar = waitbar(0,'Generating traces ...', 'WindowStyle', 'modal');
    
    %% Grab relevent data
    % get stack
    if getappdata(handles.f,'isMapped')
        seperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');
        dur = size(seperatedStacks{1},3);
        numStacks = length(seperatedStacks);
    else
        seperatedStacks = getappdata(handles.f,'data_video_stack');
        dur = size(seperatedStacks,3);
        numStacks = 1;
    end
    
    refresh = exist('refresh','var') && refresh;
    
    if refresh
        traces = getappdata(handles.f,'traces');
        width = handles.fret.widthSlider.JavaPeer.get('Value')/2;
    else

        %% Find particles
        I = generateFRETInterface('getCurrentImage',hObject,handles,1); % 1 stops brightness setting being applied
    
        particleMinInt = handles.fret.particleIntensity.JavaPeer.get('LowValue');
        particleMaxInt = handles.fret.particleIntensity.JavaPeer.get('HighValue');
        combinedROIMask = getappdata(handles.f,'combinedROIMask');
        width = handles.fret.widthSlider.JavaPeer.get('Value')/2;
        particleClustering = handles.fret.clusterCheckBox.Value;
                            
        if particleClustering
            particleMaxEccentricity = handles.fret.eccentricitySlider.JavaPeer.get('Value') / handles.fret.eccentricitySlider.JavaPeer.get('Maximum');
            particleMinDistance = handles.fret.minDistanceSlider.JavaPeer.get('Value') / handles.fret.minDistanceSlider.JavaPeer.get('Maximum') * 20;
            edgeDistance = handles.fret.edgeDistanceSlider.JavaPeer.get('Value') / handles.fret.edgeDistanceSlider.JavaPeer.get('Maximum') * 20;

            particles = findParticles(I, particleMinInt, particleMaxInt,...
                                        'EdgeDistance', edgeDistance,...
                                        'Mask', combinedROIMask,...
                                        'MaxEccentricity',particleMaxEccentricity,...
                                        'MinDistance', particleMinDistance);
        else
            particles = findParticles(I_raw, particleMinInt, particleMaxInt, 'Mask', combinedROIMask);
        end


        traces = array2table(particles{1});    

        traces.Center = [traces.Var1, traces.Var2];
        traces.Var1 = [];
        traces.Var2 = [];
    end
    traces.HalfWidth = width/2 * ones(size(traces,1),1);
    
    %% Calculate the donor and acceptor raw traces
    numTraces = size(traces,1);
    Donor_raw = zeros(numTraces,dur); % pre-aloc;
    Acceptor_raw = zeros(numTraces,dur); % pre-aloc;
    for f=1:dur % no parfor becuase seperatedStacks is too big :(
        waitbar(f/dur);
                
        if numStacks == 2
            I_donor    = double(seperatedStacks{1}(:,:,f));
            I_acceptor = double(seperatedStacks{2}(:,:,f));

            %% interperolate at maskpoints
            F_donor    = griddedInterpolant(I_donor);
            F_acceptor = griddedInterpolant(I_acceptor);
            
            % create 7 by 7 area mask
            F_del = repmat((-1:1/3:1),numTraces,1) .* repmat(traces.HalfWidth*2, 1, 7);
            F_x = reshape( repmat( repmat(traces.Center(:,2), 1, 7) + F_del , 1, 7) ,[],1);
            F_y = reshape( imresize( repmat(traces.Center(:,1), 1, 7) + F_del, [numTraces 49], 'nearest') ,[],1);

            W = (1:49);
            W = (mod(W,7)-1-3).^2 + (floor(W/7)-3).^2;
            W = repmat(W,numTraces,1);
            W = W ./ repmat( 2*(traces.HalfWidth.^2) ,1,49);
            W = exp(-W);

            Donor_raw(:,f)      = mean((reshape( F_donor(F_x,F_y), [], 49 ) ) .* W ,2);
            Acceptor_raw(:,f)  	= mean((reshape( F_acceptor(F_x,F_y), [], 49 ) ) .* W ,2);
            
        elseif numStacks == 1
            I_donor    = double(seperatedStacks(:,:,f));

            %% interperolate at maskpoints
            F_donor    = griddedInterpolant(I_donor);

            % create 7 by 7 area mask
            F_del = ( repmat((-1:1/3:1),numTraces,1) .* repmat(traces.HalfWidth*2, 1, 7) );
            F_x = reshape( repmat( repmat(traces.Center(:,2), 1, 7) + F_del , 1, 7) ,[],1);
            F_y = reshape( imresize( repmat(traces.Center(:,1), 1, 7) + F_del, [numTraces 49], 'nearest') ,[],1);

            W = (1:49);
            W = (mod(W,7)-1-3).^2 + (floor(W/7)-3).^2;
            W = repmat(W,numTraces,1);
            W = W ./ repmat( 2*(traces.HalfWidth.^2) ,1,49);
            W = exp(-W);

            Donor_raw(:,f)      = mean((reshape( F_donor(F_x,F_y), [], 49 ) ) .* W ,2);
            traces.Acceptor_raw(:,f) = zeros(size(Donor_raw(:,f)));
        end
            

    end
    traces.Donor_raw = Donor_raw;
    traces.Acceptor_raw = Acceptor_raw;

    % pre-alocs
    preAloc = zeros(numTraces, dur);
    if ~refresh
        traces.Donor        = preAloc;
        traces.Donor_hmm    = preAloc;
        traces.Acceptor     = preAloc;
        traces.Acceptor_hmm = preAloc;
        traces.FRET         = preAloc;
        traces.FRET_hmm     = preAloc;
        traces.Donor_bg     = zeros(numTraces,1);
        traces.Acceptor_bg  = zeros(numTraces,1);
        traces.Calculated   = zeros(numTraces,1,'logical');
        traces.Groups       = zeros(numTraces,0,'logical');
        traces.MinHMM       = ones(numTraces,1);
        traces.MaxHMM       = ones(numTraces,1);
        traces.LowCut       = ones(numTraces,1);
        traces.HighCut      = dur * ones(numTraces,1);
        traces.MovingMeanWidth = ones(numTraces,1);
    else
        traces.Donor        = preAloc;
        traces.Donor_hmm    = preAloc;
        traces.Acceptor     = preAloc;
        traces.Acceptor_hmm = preAloc;
        traces.FRET         = preAloc;
        traces.FRET_hmm     = preAloc;
        traces.Calculated   = zeros(numTraces,1,'logical');
    end

    setappdata(handles.f,'traces',traces);
    
    donorLimits = stretchlim(traces.Donor_raw,[0.1,0.90]);
    acceptorLimits = stretchlim(traces.Acceptor_raw,[0.1,0.90]);
    
    setappdata(handles.f,'donorLimits',donorLimits);
    setappdata(handles.f,'acceptorLimits',acceptorLimits);
    
    delete(hWaitBar);