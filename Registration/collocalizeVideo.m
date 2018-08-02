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
    % Collocalize stacks
    collocalisedSeperatedStacks = seperateStack(ROI,stack);
    collocalisedSeperatedStacks(2:end) = arrayfun( ...
        @(i) colocalizeStack(collocalisedSeperatedStacks{i}, displacmentFields{i}), ...
        (2:numChannels) , 'UniformOutput' , false );
    
    %% Get adjusted seperatedStacks
    seperatedStacks = cell(size(collocalisedSeperatedStacks));
    for s = 1:numChannels
        stack = collocalisedSeperatedStacks{s}(:,:,startCut:endCut);
        % drift
        stack = applyDriftCorrection(stack,drift);
        
        for f = 1:size(stack,3)
            I = stack(:,:,f);
            % invert
            if invertImage
                I = imcomplement(I);
            end
            % mask
            I(~combinedROIMask) = 0;
            stack(:,:,f) = I;
        end
        
        seperatedStacks{s} = stack;
    end

    
    % save
    setappdata(handles.f,'data_video_originalSeperatedStacks', collocalisedSeperatedStacks);
    setappdata(handles.f,'data_video_seperatedStacks', seperatedStacks);
    
    waitbar(10/10);
    delete(hWaitBar);
end