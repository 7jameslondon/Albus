function main

    close all;
    
    hWaitBar = waitbar(0,'Starting up...', 'WindowStyle', 'modal');

    %% Include files
    mpath = fileparts(which(mfilename));
    addpath([mpath '/Registration']);
    addpath([mpath '/Interface']);
    addpath([mpath '/Tracking']);
    addpath([mpath '/Particle_Detection']);
    addpath([mpath '/DNA_Detection']);
    addpath([mpath '/Drift_Correction']);
    addpath([mpath '/Miscellaneous']);
    
    addpath([mpath '/vbfret']);
    addpath([mpath '/vbfret/src']);
    addpath([mpath '/vbfret/ext_src']);
        
    addpath([mpath '/GUI Layout Toolbox 2/layout/']);
    
    set(groot,'defaultFigureCreateFcn','addToolbarExplorationButtons(gcf)');
    set(groot,'defaultAxesCreateFcn','set(get(gca,''Toolbar''),''Visible'',''off'')');

    %% Interface
    handles = createInterface;

    %% Inialize settings
    colors = [[0 1 0]; [1 0 0]; [0 0 1]; [0 1 1]; [1 1 0]; [1 0 1]];
    names  = [{'Channel 1'}, {'Channel 2'}, {'Channel 3'}, {'Channel 4'}, {'Channel 5'}, {'Channel 6'}];
    setappdata(handles.f,'colors',colors);
    setappdata(handles.f,'ROINames',names);
    setappdata(handles.f,'ROI',[]);
    setappdata(handles.f,'drift',[]);
    setappdata(handles.f,'mode','Home');
    setappdata(handles.f,'isMapped',0);
    setappdata(handles.f, 'playSpeed', 1);
    setappdata(handles.f,'isLoading',false)

    particleSettings = struct('filterSize',[],'minIntensity',[],'maxIntensity',[]);
    setappdata(handles.f,'mapping_particleSettings',particleSettings);

    %% Start Parelle Pool
    try 
        parpool('local', 'IdleTimeout', Inf);
    catch
    end
    
    delete(hWaitBar);

    %% Load?
    cancelFlag = true;
    while cancelFlag
        loadOrNew = questdlg('Would you like to load a previous session or start a new session?','Load','Load Session','New Session','New Session');
        if strcmp(loadOrNew,'Load Session')
            cancelFlag = loadSession(handles.f);
            if cancelFlag
                break;
            end
        elseif strcmp(loadOrNew,'New Session')
            %% Auto save
            uiwait(msgbox('Where should this session be saved?','Save'));
            cancelFlag = saveSession(handles.f);
            if cancelFlag
                break;
            end

            handles.tim = timer;
            handles.tim.StartDelay = 15*60;
            handles.tim.Period = 15*60;
            handles.tim.ExecutionMode = 'fixedSpacing';
            handles.tim.TimerFcn = @(~, ~) saveSession(handles.f, 1); % '1' is to flag it as an autosave
            start(handles.tim);
            guidata(handles.f,handles); % save

        else % quit
            cancelFlag = true;
            delete(handles.f);
            return;
        end
    end
    
    handles.f.set('Visible', 'on');
end