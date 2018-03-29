function closeProgram(hObject,handles)
% Everything that runs when the program closes

    % Remove the timer for autosave
    delete(handles.tim);

    % Auto save one last time
    saveSession(handles.f, 1);
end

