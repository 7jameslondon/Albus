function collocalizeMapping(hObject,handles)
    hWaitBar = waitbar(0,'Collocalizing mapping video ...', 'WindowStyle', 'modal');
    
    seperatedStacks = getappdata(handles.f,'data_mapping_originalSeperatedStacks');
    invertImage = handles.map.invertCheckbox.Value;
    numChannels = size(seperatedStacks,1);
    displacmentFields = getappdata(handles.f,'displacmentFields');
    
    % Get adjusted seperatedStacks
    for s = 1:numChannels
        for f = 1:size(seperatedStacks{s},3)
            I = seperatedStacks{s}(:,:,f);
            % invert
            if invertImage
                I = imcomplement(I);
            end
            % brightness
            seperatedStacks{s}(:,:,f) = imadjust(I);
        end
    end
    waitbar(1/10);
    
    % Collocalize stacks
    collocalisedSeperatedStacks = seperatedStacks;
    collocalisedSeperatedStacks(2:end) = arrayfun( ...
        @(i) colocalizeStack(seperatedStacks{i}, displacmentFields{i}), ...
        (2:numChannels) , 'UniformOutput' , false );
    setappdata(handles.f,'data_mapping_collocalisedSeperatedStacks',collocalisedSeperatedStacks);
    
    waitbar(10/10);
    delete(hWaitBar);
end