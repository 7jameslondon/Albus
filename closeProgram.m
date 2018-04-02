function closeProgram(hObject,handles)
% Everything that runs when the program closes

    % Exit manual mode if your in it
    if getappdata(handles.f,'dna_manualMode')
        deactivateManualMode(hObject, handles);
    end

    % Remove the timer for autosave
    if isfield(handles,'tim')
        delete(handles.tim);
    end

    % Auto save one last time
    if isfield(handles,'f')
        saveSession(handles.f, 1);
    end
    
end

