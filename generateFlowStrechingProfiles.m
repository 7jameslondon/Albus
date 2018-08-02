function generateFlowStrechingProfiles(hObject, handles)
    %% get data
    stack               = generateFlowStrechingInterface('getSourceStack',hObject,handles);
    filterSize          = handles.flow.particleFilter.JavaPeer.get('Value') / handles.flow.particleFilter.JavaPeer.get('Maximum') * 5;
    particleMinInt      = handles.flow.particleIntensity.JavaPeer.get('LowValue');
    particleMaxInt      = handles.flow.particleIntensity.JavaPeer.get('HighValue');
    combinedROIMask     = getappdata(handles.f,'combinedROIMask');
    maxDistance         = str2double(handles.flow.trackingDistance.String);
    
    %% generate tracks
    hWaitBar = waitbar(0,'Detecting particles ...');
    particlesByFrame = findParticles(stack, particleMinInt, particleMaxInt, filterSize, 'Mask', combinedROIMask,'Method','FastGaussianFit','Waitbar',hWaitBar);
    delete(hWaitBar);
    centers = cell(size(particlesByFrame));
    for i=1:size(particlesByFrame,1)
        centers{i} = particlesByFrame{i}.Center;
    end
    profiles = triTrackTracking( centers, maxDistance );
    
    %% calculate profile specifc data
    % displacement
    for i = 1:size(profiles,1)
        pos = profiles.Positions{i};
        pos1D = sqrt(pos(:,1).^2 + pos(:,2).^2);
        dispacment1D = [0; diff(pos1D)];
        times = profiles.StartFrame(i):profiles.StartFrame(i)+profiles.Length(i)-1;
        profile = [times', pos1D];
        profiles.Profile{i} = profile;
    end
    
    
    %% save
    setappdata(handles.f,'flowStrechingProfiles',profiles);
end