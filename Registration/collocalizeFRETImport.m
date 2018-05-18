function collocalizeFRETImport(hObject,handles)
    hWaitBar = waitbar(0,'Collocalizing FRET video ...', 'WindowStyle', 'modal');
    
    switch handles.fret.sourcePopUpMenu.Value
        case 2 % Current vid
            collocalisedSeperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');

        case 3 % Import
            stack = getappdata(handles.f,'data_fretImport_originalStack');
            
            ROI = getappdata(handles.f,'ROI');
            numChannels = size(ROI,1);
            displacmentFields = getappdata(handles.f,'displacmentFields');

            %% Seperate Stacks
            seperatedStacks = seperateStack(ROI,stack);

            % Collocalize stacks
            collocalisedSeperatedStacks = seperatedStacks;
            collocalisedSeperatedStacks(2:end) = arrayfun( ...
                @(i) colocalizeStack(seperatedStacks{i}, displacmentFields{i}), ...
                (2:numChannels) , 'UniformOutput' , false );
    end
    
    % save
    setappdata(handles.f,'data_fretImport_seperatedStacks', collocalisedSeperatedStacks);
    
    waitbar(10/10);
    delete(hWaitBar);
end