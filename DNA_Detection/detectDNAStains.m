function detectDNAStains(hObject, handles)
    %% Setup
    hWaitBar = waitbar(0,'Finding DNA...', 'WindowStyle', 'modal');
    
    generateKymographInterface('updateDNAKernal',hObject, handles);
    dnaKernal = getappdata(handles.f,'dnaKernal');
    I = generateKymographInterface('getCurrentImage',hObject, handles);
    dnaMatchingStrength = get(handles.dna.dnaMatchingStrengthSlider.JavaPeer,'Value');
    
    %% Prepare image
    I = adapthisteq(I,'Distribution','rayleigh','ClipLimit',0.005);

    c = normxcorr2(dnaKernal,I);
    c = mat2gray(c); % normalize between 0 and 1

    c = imhmax(c,mean(c(:)));
    regMax = imregionalmax(c);

    CC = bwconncomp(regMax);
    S = regionprops(CC,'Centroid');
    
    numTotalFound = size(S,1);
    
    corrs = zeros(size(S,1),1);
    rects = zeros(size(S,1),4);

    for i=1:numTotalFound
        center = S(i,:).Centroid;
        rects(i,:) = [center(1)-size(dnaKernal,2)/2, center(2)-size(dnaKernal,1)/2, size(dnaKernal,2), size(dnaKernal,1)];

        dnaImage = imcrop(I,rects(i,:));

        corrs(i) = max(max(xcorr2(dnaImage,dnaKernal)));
    end

    for i=1:numTotalFound
        if corrs(i) > dnaMatchingStrength * sum(sum(dnaKernal))*2^16 / 100
            % create new dan at pos found
            generateKymographInterface('addNewDNA',hObject, handles, [rects(i,1:2)+[0 rects(i,4)/2]; rects(i,1:2)+[rects(i,3) rects(i,4)/2]]);
        end

        % update loading bar
        waitbar(i/numTotalFound);
    end
    
    delete(hWaitBar);
end