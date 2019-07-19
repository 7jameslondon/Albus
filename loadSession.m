function flag = loadSession(hObject)
    flag = false;
    handles = guidata(hObject);
    [loadName, loadPath, ~] = uigetfile({'*.mat'}, 'Select the session to load'); 
    if loadName == 0 % if user presses cancel
        flag = true;
        return;
    end
    hWaitBar = waitbar(0,'Loading in session...', 'WindowStyle', 'modal');
    setappdata(handles.f,'isLoading',true);
    load([loadPath loadName]);    
    
    %% Handles changes from old versions 0.44 and forward
    if ~isfield(session,'playSpeed')
        session.playSpeed = 1;
    end
    if ~isfield(session,'flow_trackingDistance')
        session.flow_mode            = getappdata(handles.f,'flow_mode');
        session.flow_currentFrame    = 1;
        session.flow_invertImage     = false;
        session.flow_lowBrightness   = 0;
        session.flow_highBrightness  = 1;
        session.flow_timeAvg         = false;

        session.flow_particleIntensityLow   = 100;
        session.flow_particleIntensityHigh  = 100;
        session.flow_particleFilter         = 1;
        
        session.flow_trackingDistance       = 2;
        
        session.flow_backgroundFilePath = 'No background video selected';
        
        session.flowStrechingProfiles = table; 
    end
    if ~isfield(session,'kym_lowBrightness1')    
        session.kym_lowBrightness1 = 100;
        session.kym_lowBrightness2 = 100;
        session.kym_lowBrightness3 = 100;
        session.kym_lowBrightness4 = 100;
        session.kym_lowBrightness5 = 100;
        session.kym_lowBrightness6 = 100;
        
        session.kym_highBrightness1 = 101;
        session.kym_highBrightness2 = 101;
        session.kym_highBrightness3 = 101;
        session.kym_highBrightness4 = 101;
        session.kym_highBrightness5 = 101;
        session.kym_highBrightness6 = 101;
        
        session.kym_syncBrightness = 0;
    end
    if ~isfield(session,'tra_DAScaleAuto')
        session.tra_DAScaleAuto = 1;
    end
    if ~isfield(session,'fret_width')
        session.fret_width = 5;
    end
    if isfield(session,'tra_traces') && isfield(session.tra_traces, 'Donor')
        if ~any(strcmp('MovingMeanWidth', session.tra_traces.Properties.VariableNames))
            numTraces = size(session.tra_traces,1);
            dur = size(session.tra_traces.Donor,2);
            session.tra_traces.LowCut           = ones(numTraces,1);
            session.tra_traces.HighCut          = dur * ones(numTraces,1);
            session.tra_traces.MovingMeanWidth  = ones(numTraces,1);
            session.tra_traces.MinHMM           = ones(numTraces,1);
            session.tra_traces.MaxHMM           = ones(numTraces,1);
        end
    end
    
    
    %% Setup general variables
    setappdata(handles.f,'version',session.version);
    setappdata(handles.f,'autoSavePath', [loadPath loadName]);
    %setappdata(handles.f,'autoSavePath',session.autoSavePath);
    setappdata(handles.f,'savePath',session.savePath);
    setappdata(handles.f,'ROI',session.ROI); % ROI will each get updated by updateDisplay calls in the GUIs
    setappdata(handles.f,'colors',session.colors);
    setappdata(handles.f,'ROINames',session.ROINames);
    setappdata(handles.f,'mode',session.mode);
    setappdata(handles.f,'isMapped',session.isMapped);
    setappdata(handles.f,'drift',session.drift);
    setappdata(handles.f,'kyms',session.kyms);
    setappdata(handles.f,'combinedROIMask',session.combinedROIMask);
    createInterface('setPlaySpeed',hObject, handles, session.playSpeed);
    if isfield(session,'displacmentFields') ~= 0
        setappdata(handles.f,'displacmentFields',session.displacmentFields);
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
    handles = driftInterface('loadFromSession',hObject,handles,session);
    
    videoSettingInterface('postProcessVideo',hObject,handles);
    waitbar(3/5,hWaitBar)
    
    %% Setup all the other interfaces
    handles = generateKymographInterface('loadFromSession', hObject,handles,session);
    handles = generateFRETInterface('loadFromSession', hObject,handles,session);
    handles = analyzeFRETInterface('loadFromSession', hObject,handles,session);
    handles = analyzeKymographInterface('loadFromSession',hObject,handles,session);
    handles = generateFlowStrechingInterface('loadFromSession',hObject,handles,session);
    waitbar(4/5,hWaitBar)
    
    %% Move to correct interface
    switch session.mode
        case 'Home'
            homeInterface('openHome',hObject);
        case 'Mapping'
            homeInterface('openMapping',hObject);
        case 'Video Settings'
            homeInterface('openVideoSettings',hObject);
        case 'Drift'
            homeInterface('openDriftCorrection',hObject);
        case 'Select DNA'
            homeInterface('openSelectDNA',hObject);
        case 'Kymographs'
            generateKymographInterface('openKymographs',hObject,handles,1); % 1 is a flag to suppress dna_linePos appdata overide
        case 'Select FRET'
            homeInterface('openSelectFRET',hObject);
        case 'Traces'
            generateFRETInterface('openTraces',hObject,0,1); % 0, is to stop handles, 1 is a flag to suppress recalculation of trace data
        case 'Generate Flow Streching'
            homeInterface('openGenerateFlowStreching',hObject);
        case 'Analyze Flow Streching'
            generateFlowStrechingInterface('openAnalyzeFlowStreching',hObject);
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
    setappdata(handles.f,'isLoading',false);
    waitbar(5/5,hWaitBar)
    delete(hWaitBar);
end
