function detectDNAByTracking(hObject, handles)
    %% get data
    stack               = generateKymographInterface('getSourceStack',hObject,handles);
    filterSize          = handles.dna.particleFilter.JavaPeer.get('Value') / handles.dna.particleFilter.JavaPeer.get('Maximum') * 5;
    particleMinInt      = handles.dna.particleIntensity.JavaPeer.get('LowValue');
    particleMaxInt      = handles.dna.particleIntensity.JavaPeer.get('HighValue');
    combinedROIMask     = getappdata(handles.f,'combinedROIMask');
    maxDistance         = str2double(handles.dna.trackingDistance.String);
    
    %% generate tracks
    hWaitBar = waitbar(0,'Detecting particles ...');
    particlesByFrame = findParticles(stack, particleMinInt, particleMaxInt, filterSize, 'Mask', combinedROIMask,'Waitbar',hWaitBar);
    delete(hWaitBar);

    tracks = triTrackTracking( particlesByFrame, maxDistance );
    
    goodTracks = tracks(tracks.Length>10,:);
    
    overlapRadius = 3;

    prevX = zeros(size(goodTracks,1), 1);
    prevY = zeros(size(goodTracks,1), 1);
    for i=1:size(goodTracks,1) 
        x = goodTracks.Positions{i}(:,1); 
        y = goodTracks.Positions{i}(:,2); 

        [~, I] = min(x); 
        x1=x(I); 
        y1=y(I); 
        [~, I] = max(x); 
        x2=x(I); 
        y2=y(I); 

        if abs(x2-x1) > 5 && ~any(abs(prevX(1:i-1) - mean([x2,x1])) < overlapRadius & abs(prevY(1:i-1) - mean([y2,y1])) < overlapRadius)
            generateKymographInterface('addNewDNA',hObject,handles,[x1-(x2-x1) mean([y2,y1]); x2+(x2-x1) mean([y2,y1])]);
        end
        
        prevX(i) = mean([x1,x2]);
        prevY(i) = mean([y1,y2]);
    end
end
