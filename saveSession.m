function cancelFlag = saveSession(hObject, autoSaveFlag)
    handles = guidata(hObject);
    cancelFlag = false;
    if ~exist('autoSaveFlag','var')
        [saveName, savePath, ~] = uiputfile({'*.mat'}, 'Save session', 'session.mat'); 
        if saveName == 0 % if user presses cancel
            cancelFlag = true;
            return
        end
        saveFullPath = [savePath saveName];
        setappdata(handles.f,'autoSavePath',saveFullPath);
        setappdata(handles.f,'savePath',savePath);
    else
        saveFullPath = getappdata(handles.f,'autoSavePath');
    end
    
    hWaitBar = waitbar(0,'Saving...', 'WindowStyle', 'modal');
    
    session = struct();
    
    session.version             = 0.44;
    session.ROI                 = getappdata(handles.f,'ROI');
    session.colors              = getappdata(handles.f,'colors');
    session.ROINames            = getappdata(handles.f,'ROINames');
    session.mode                = getappdata(handles.f,'mode');
    session.isMapped            = getappdata(handles.f,'isMapped');
    session.drift               = getappdata(handles.f,'drift');
    session.autoSavePath        = saveFullPath;
    session.savePath            = getappdata(handles.f,'savePath');
    session.combinedROIMask     = getappdata(handles.f,'combinedROIMask');
    session.playSpeed           = getappdata(handles.f,'playSpeed');
    session.video_maxIntensity  = getappdata(handles.f,'video_maxIntensity');

    
    %% Register Channels
    if ~strcmp(handles.map.selectVideoTextBox.String, 'No mapping video selected') % is there mapping data to save
        session.map_mode            = getappdata(handles.f,'mapping_mode');
        session.map_videoFilePath   = handles.map.selectVideoTextBox.String;
        session.map_currentFrame    = getappdata(handles.f,'mapping_currentFrame');
        session.map_lowBrightness   = handles.map.brightness.JavaPeer.get('LowValue');
        session.map_highBrightness  = handles.map.brightness.JavaPeer.get('HighValue');
        session.map_invertVideo     = handles.map.invertCheckbox.Value;
        session.map_timeAvg         = handles.map.timeAvgCheckbox.Value;
        session.map_numberROI       = handles.map.numberROITextBox.Value;
        session.map_particleChannel = handles.map.particleChannel.Value;
        session.map_particleSettings = getappdata(handles.f,'mapping_particleSettings');
    end
    
    %% displacmentFields
    if isappdata(handles.f,'displacmentFields')
        session.displacmentFields = getappdata(handles.f,'displacmentFields');
    end
    
    if ~exist('mappingOnlyFlag','var')
    
        %% Video Settings
        if ~strcmp(handles.vid.selectVideoTextBox.String, 'No video selected') % is there video data to save
            session.vid_mode            = getappdata(handles.f,'video_mode');
            session.vid_videoFilePath   = handles.vid.selectVideoTextBox.String;
            session.vid_currentFrame    = getappdata(handles.f,'video_currentFrame');
            session.vid_startFrame      = handles.vid.cutting.JavaPeer.get('LowValue');
            session.vid_endFrame        = handles.vid.cutting.JavaPeer.get('HighValue');
            session.vid_lowBrightness   = handles.vid.brightness.JavaPeer.get('LowValue');
            session.vid_highBrightness  = handles.vid.brightness.JavaPeer.get('HighValue');
            session.vid_invertVideo     = handles.vid.invertCheckbox.Value;
            session.vid_imrectPos       = getappdata(handles.f, 'vid_imrectPos');
        end
        
        %% Drift Correction
            session.drift_isDriftCorrected = handles.drift.applyCorrection.Value;
            
            session.drift_invertImage     = handles.drift.invertCheckbox.Value;
            session.drift_lowBrightness   = get(handles.drift.brightness.JavaPeer, 'LowValue');
            session.drift_highBrightness  = get(handles.drift.brightness.JavaPeer, 'HighValue');
            
            session.drift_markParticles           = handles.drift.markParticles.Value;
            session.drift_particleIntensityLow    = handles.drift.particleIntensity.JavaPeer.get('LowValue');
            session.drift_particleIntensityHigh   = handles.drift.particleIntensity.JavaPeer.get('HighValue');
            session.drift_particleFilter          = handles.drift.particleFilter.JavaPeer.get('Value');
            session.drift_maxDistance             = handles.drift.maxDistance.JavaPeer.get('Value');
            
            session.drift_selectedChannel = handles.drift.sourceChannelPopUpMenu.Value;
            
            session.drift_meanLength      = handles.drift.meanSlider.JavaPeer.get('Value');

        %% Generate Kymographs
        % this data will always be saved unlike the above
            session.dna_mode            = getappdata(handles.f,'dna_mode');
            session.dna_source          = handles.dna.sourcePopUpMenu.Value;
            session.dna_channel         = handles.dna.sourceChannelPopUpMenu.Value;
            session.dna_videoFilePath   = handles.dna.importVideoTextbox.String;
            session.dna_currentFrame    = getappdata(handles.f,'dna_currentFrame');
            session.dna_invertImage     = handles.dna.invertCheckbox.Value;
            session.dna_lowBrightness   = get(handles.dna.brightness.JavaPeer, 'LowValue');
            session.dna_highBrightness  = get(handles.dna.brightness.JavaPeer, 'HighValue');
            session.dna_timeAvg         = handles.dna.sourceTimeAvgCheckBox.Value;
            
            session.dna_dnaWidth            = get(handles.dna.dnaWidthSlider.JavaPeer,'Value');
            session.dna_dnaLength           = get(handles.dna.dnaLengthSlider.JavaPeer,'Value');
            session.dna_dnaMatchingStrength = get(handles.dna.dnaMatchingStrengthSlider.JavaPeer,'Value');
            
            % update any changes that result from Imline moves
            if strcmp(getappdata(handles.f,'mode'),'Select DNA')
                generateKymographInterface('saveImlinesToKyms',handles.f,handles);
            elseif strcmp(getappdata(handles.f,'mode'),'Kymographs')
                analyzeKymographInterface('refreshKymAxes',hObject,handles);
            end
            session.kyms = getappdata(handles.f,'kyms');
            
        %% Analyze Kymographs
        % this data will always be saved unlike the above        
            session.kym_invertImage     = handles.kym.invertCheckbox.Value;
            session.kym_syncBrightness  = handles.kym.syncBrightness.Value;
            
        %% Generate FRET Traces
        % this data will always be saved unlike the above
            session.fret_mode            = getappdata(handles.f,'fret_mode');
            session.fret_source          = handles.fret.sourcePopUpMenu.Value;
            session.fret_channel         = handles.fret.sourceChannelPopUpMenu.Value;
            session.fret_videoFilePath   = handles.fret.importVideoTextbox.String;
            session.fret_currentFrame    = getappdata(handles.f,'fret_currentFrame');
            session.fret_invertImage     = handles.fret.importVideoTextbox.Value;
            session.fret_lowBrightness   = get(handles.fret.brightness.JavaPeer, 'LowValue');
            session.fret_highBrightness  = get(handles.fret.brightness.JavaPeer, 'HighValue');
            session.fret_timeAvg         = handles.fret.sourceTimeAvgCheckBox.Value;
            session.fret_width           = handles.fret.widthSlider.JavaPeer.get('Value')/2;
            
            session.fret_particleIntensityLow   = handles.fret.particleIntensity.JavaPeer.get('LowValue');
            session.fret_particleIntensityHigh  = handles.fret.particleIntensity.JavaPeer.get('HighValue');
            session.fret_particleFilter         = handles.fret.particleFilter.JavaPeer.get('Value');
            
            session.fret_clustering      = handles.fret.clusterCheckBox.Value;
            session.fret_eccentricity    = handles.fret.eccentricitySlider.JavaPeer.get('Value');
            session.fret_minDistance     = handles.fret.minDistanceSlider.JavaPeer.get('Value');
            session.fret_edgeDistance    = handles.fret.edgeDistanceSlider.JavaPeer.get('Value');
            
       %% Analyze FRET Traces
        % this data will always be saved unlike the above
            session.tra_traces          = getappdata(handles.f,'traces');
            
            session.tra_mode            = getappdata(handles.f,'trace_mode');
            session.tra_currentTrace    = getappdata(handles.f,'trace_currentTrace');
            session.tra_lowCut          = get(handles.tra.cutSlider.JavaPeer, 'LowValue');
            session.tra_highCut         = get(handles.tra.cutSlider.JavaPeer, 'HighValue');
            session.tra_mean            = get(handles.tra.meanSlider.JavaPeer, 'Value');
            
            session.tra_lowStates       = get(handles.tra.hmmStatesSlider.JavaPeer, 'LowValue');
            session.tra_highStates     	= get(handles.tra.hmmStatesSlider.JavaPeer, 'HighValue');
            
%             session.tra_DAScaleAuto     = handles.tra.DAScaleAuto.Value;
%             session.tra_DAScale         = [get(handles.tra.DAScale.JavaPeer, 'LowValue'), get(handles.tra.DAScale.JavaPeer, 'HighValue')];
            
            session.tra_donorBGRule     = getappdata(handles.f,'trace_donorBGRule');
            session.tra_acceptorBGRule  = getappdata(handles.f,'trace_acceptorBGRule');
            
            groupHandles = getappdata(handles.f,'trace_groupHandles');
            tra_groups = cell(size(groupHandles,1),3);
            for i = 1:size(groupHandles,1)
                tra_groups{i,1} = groupHandles{i,1}.get('Value');
                tra_groups{i,2} = groupHandles{i,2}.get('String');
                tra_groups{i,3} = groupHandles{i,3}.get('String');
                tra_groups{i,5} = groupHandles{i,5}.get('UserData');
            end
            session.tra_groups = tra_groups;
            
            session.tra_skipHiddenGroups = handles.tra.skipHiddenGroups.Value;
            
       %% Analyze FRET Traces
        % this data will always be saved unlike the above
            session.flowStrechingProfiles= getappdata(handles.f,'flowStrechingProfiles');
            
            session.flow_mode            = getappdata(handles.f,'flow_mode');
            session.flow_currentFrame    = getappdata(handles.f,'flow_currentFrame');
            session.flow_invertImage     = handles.flow.invertCheckbox.Value;
            session.flow_lowBrightness   = get(handles.flow.brightness.JavaPeer, 'LowValue');
            session.flow_highBrightness  = get(handles.flow.brightness.JavaPeer, 'HighValue');
            session.flow_timeAvg         = handles.flow.sourceTimeAvgCheckBox.Value;
            
            session.flow_particleIntensityLow   = handles.flow.particleIntensity.JavaPeer.get('LowValue');
            session.flow_particleIntensityHigh  = handles.flow.particleIntensity.JavaPeer.get('HighValue');
            session.flow_particleFilter         = handles.flow.particleFilter.JavaPeer.get('Value');
            
            session.flow_trackingDistance       = str2double(handles.flow.trackingDistance.String);
            
            session.flow_backgroundFilePath      = handles.flow.selectBackgroundVideoTextBox.String;
            
    end
    
    try
        save(saveFullPath,'session');
    catch
        msgbox('There was a problem saving. Select a save location.','There was a problem saving.');
        [saveName, savePath, ~] = uiputfile({'*.mat'}, 'Save session', 'session.mat'); 
        saveFullPath = [savePath saveName];
        setappdata(handles.f,'autoSavePath',saveFullPath);
        setappdata(handles.f,'savePath',savePath);
        save(saveFullPath,'session');
    end
    close(hWaitBar);
end