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
    
    session.video_maxIntensity   = getappdata(handles.f,'video_maxIntensity');

    
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
                selectDNAInterface('saveImlinesToKyms',handles.f,handles);
            elseif strcmp(getappdata(handles.f,'mode'),'Kymographs')
                kymographInterface('refreshKymAxes',hObject,handles);
            end
            session.kyms = getappdata(handles.f,'kyms');
            
        %% Analyze Kymographs
        % this data will always be saved unlike the above        
            session.kym_invertImage     = handles.kym.invertCheckbox.Value;
            session.kym_lowBrightness   = get(handles.kym.brightness.JavaPeer, 'LowValue');
            session.kym_highBrightness  = get(handles.kym.brightness.JavaPeer, 'HighValue');
            
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
            
            session.tra_DAScale         = get(handles.tra.DAScale.JavaPeer, 'Value');
            
            session.tra_removeBG        = handles.tra.removeBGCheckbox.Value;
    end
    
    save(saveFullPath,'session');
    close(hWaitBar);
end