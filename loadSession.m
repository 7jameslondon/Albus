function loadSession(hObject)
    handles = guidata(hObject);
    [loadName, loadPath, ~] = uigetfile({'*.mat'}, 'Select the session to load'); 
    if loadName == 0 % if user presses cancel
        return
    end
    hWaitBar = waitbar(0,'Loading in session...', 'WindowStyle', 'modal');
    load([loadPath loadName]);
    
    %% Handles changes from old versions
    if ~isfield(session,'savePath')
        uiwait(msgbox('What folder should data be saved in?','Save'));
        session.savePath = uigetdir('Where should the data be saved'); 
    end
    
    if ~isfield(session.kyms, 'Traces')
        session.kyms.Traces(:,1) = cell(size(session.kyms,1),1);
    end
    
    %% Setup general variables
    setappdata(handles.f,'autoSavePath',session.autoSavePath);
    setappdata(handles.f,'savePath',session.savePath);
    setappdata(handles.f,'ROI',session.ROI); % ROI will each get updated by updateDisplay calls in the GUIs
    setappdata(handles.f,'colors',session.colors);
    setappdata(handles.f,'mode',session.mode);
    setappdata(handles.f,'isMapped',session.isMapped);
    setappdata(handles.f,'kyms',session.kyms);
    if isfield(session,'tForm') ~= 0
        setappdata(handles.f,'tForm',session.tForm);
        setappdata(handles.f,'combinedROIMask',session.combinedROIMask);
    end
    
    %% Setup video interface
    if isfield(session,'vid_videoFilePath') ~= 0
        handles = videoSettingInterface('loadFromSession', hObject,handles,session);
    end
    waitbar(1/5,hWaitBar)
    
    %% Setup mapping interface and colocalize mapping video
    if isfield(session,'map_videoFilePath') ~= 0
        handles = mappingInterface('loadFromSession', hObject,handles,session);
    end
    waitbar(2/5,hWaitBar)
    
    %% Colocalize video/treat it
    videoSettingInterface('postProcessVideo',hObject,handles);
    waitbar(3/5,hWaitBar)
    
    %% Setup all the other interfaces
    selectDNAInterface('loadFromSession', hObject,handles,session);
    selectFRETInterface('loadFromSession', hObject,handles,session);
    tracesInterface('loadFromSession', hObject,handles,session);
    waitbar(4/5,hWaitBar)
    
    %% Move to correct interface
    switch session.mode
        case 'Home'
            homeInterface('openHome',hObject);
        case 'Mapping'
            homeInterface('openMapping',hObject);
        case 'Video Settings'
            homeInterface('openVideoSettings',hObject);
        case 'Select DNA'
            homeInterface('openSelectDNA',hObject);
        case 'Kymographs'
            selectDNAInterface('openKymographs',hObject,handles,1); % 1 is a flag to suppress dna_linePos appdata overide
        case 'Select FRET'
            homeInterface('openSelectFRET',hObject);
        case 'Traces'
            selectFRETInterface('openTraces',hObject);
    end
    handles.oneAxes.AxesAPI.setMagnification(handles.oneAxes.AxesAPI.findFitMag());
    
    %% Setup autosave
    if isfield(handles,'tim')
        delete(handles.tim);
    end
    handles.tim = timer;
    handles.tim.StartDelay = 15*60;
    handles.tim.Period = 15*60;
    handles.tim.ExecutionMode = 'fixedSpacing';
    handles.tim.TimerFcn = @(~, ~) saveSession(handles.f, 1);  % '1' is to flag it as an autosave
    start(handles.tim);
    guidata(handles.f,handles); % save
    
    %% Exit
    waitbar(5/5,hWaitBar)
    delete(hWaitBar);
end
