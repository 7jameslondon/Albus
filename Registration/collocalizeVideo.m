function collocalizeVideo(hObject,handles)
    hWaitBar = waitbar(0,'Collocalizing video ...', 'WindowStyle', 'modal');
    
    ROI                 = getappdata(handles.f,'ROI');
    stack               = getappdata(handles.f,'data_video_originalStack');
    invertImage         = handles.vid.invertCheckbox.Value;
    numChannels         = size(ROI,1);
    displacmentFields   = getappdata(handles.f,'displacmentFields');
    startCut            = handles.vid.cutting.JavaPeer.get('LowValue');
    endCut              = handles.vid.cutting.JavaPeer.get('HighValue');
    combinedROIMask     = getappdata(handles.f,'combinedROIMask');
    drift               = getappdata(handles.f,'drift');
    
    %% Seperate Stacks
    seperatedStacks = seperateStack(ROI,stack);
    
    % Collocalize stacks
    collocalisedSeperatedStacks = seperatedStacks;
    collocalisedSeperatedStacks(2:end) = arrayfun( ...
        @(i) colocalizeStack(seperatedStacks{i}, displacmentFields{i}), ...
        (2:numChannels) , 'UniformOutput' , false );
    
    %% Get adjusted seperatedStacks
    seperatedStacks = collocalisedSeperatedStacks;
    for s = 1:numChannels
        % drift
        seperatedStacks{s} = applyDriftCorrection(seperatedStacks{s},drift);
        
        for f = startCut:endCut
            I = seperatedStacks{s}(:,:,f);
            % invert
            if invertImage
                I = imcomplement(I);
            end
            % mask
            I(~combinedROIMask) = 0;
            seperatedStacks{s}(:,:,f) = I;
        end
    end

    
    % save
    setappdata(handles.f,'data_video_originalSeperatedStacks', collocalisedSeperatedStacks);
    setappdata(handles.f,'data_video_seperatedStacks', seperatedStacks);
    
    waitbar(10/10);
    delete(hWaitBar);
end