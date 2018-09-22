function varargout = generateFRETInterface(varargin)
    if nargin && ischar(varargin{1})
        if nargout
            [varargout{1:nargout}] = feval(str2func(varargin{1}), varargin{2:end});
        else
            feval(str2func(varargin{1}), varargin{2:end});
        end
    end
end

%% Creation
function handles = createInterface(handles)
    setappdata(handles.f,'Playing_Video', 0);
    setappdata(handles.f,'fret_mode','Source');
    setappdata(handles.f,'fret_currentFrame',1);
    setappdata(handles.f,'data_fret_plt',[])

    handles.fret = struct();
    handles.fret.leftPanel = uix.VBox( 'Parent', handles.leftPanel);
    
    %% back
    handles.fret.backButtonPanel = uix.Panel('Parent', handles.fret.leftPanel);
    handles.fret.backButton = uicontrol(     'Parent', handles.fret.backButtonPanel,...
                                          	'String', 'Back',...
                                          	'Callback', @(hObject,~) onRelease(hObject,guidata(hObject)));
                                        
    %% Source
    handles.fret.sourcePanel = uix.BoxPanel('Parent', handles.fret.leftPanel,...
                                           'Title','Source',...
                                           'Padding',5);
    handles.fret.sourceBox = uix.VBox('Parent', handles.fret.sourcePanel);
    
    % source popupmenu
    handles.fret.sourcePopUpMenuBox = uix.HBox('Parent', handles.fret.sourceBox);
    uicontrol(  'Parent', handles.fret.sourcePopUpMenuBox,...
                'style', 'text',...
                'String', 'Source');
    handles.fret.sourcePopUpMenu = uicontrol('Parent', handles.fret.sourcePopUpMenuBox,...
                                            'style', 'popupmenu',...
                                          	'String', {'None','Current video','Import new video'},...
                                          	'Callback', @(hObject,~) selectSource(hObject,guidata(hObject)));
    % import textbox
    handles.fret.importVideoTextbox = uicontrol( 'Parent', handles.fret.sourceBox,...
                                                    'style', 'edit',...
                                                    'String', 'No video selected',...
                                                    'Visible','off',...
                                                    'Callback', @(hObject,~) importVideoTextBoxCallback(hObject,hObject.String));
    % pre-processbox
    handles.fret.preProcBox = uix.VBox('Parent', handles.fret.sourceBox,...
                                      'Visible','off');
    
    % channel
    handles.fret.channelBox = uix.HBox('Parent', handles.fret.preProcBox,...
                                                    'Visible','off');
    uicontrol(  'Parent', handles.fret.channelBox,...
                'style', 'text',...
                'String', 'Channel');
    handles.fret.sourceChannelPopUpMenu = uicontrol( 'Parent', handles.fret.channelBox,...
                                                    'style', 'popupmenu',...
                                                    'String', {''},...
                                                    'Callback', @(hObject,~) selectSourceChannel(hObject,guidata(hObject)));
    % time average
    handles.fret.sourceTimeAvgCheckBox = uicontrol( 'Parent', handles.fret.preProcBox,...
                                                    'style', 'checkbox',...
                                                    'String', 'Time Average',...
                                                    'Callback', @(hObject,~) changeTimeAverage(hObject,guidata(hObject),hObject.Value));
    
    % brightness
    uicontrol( 'Parent', handles.fret.preProcBox,...
               'Style' , 'text', ...
               'String', 'Brightness');
    [~, handles.fret.brightness] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.fret.brightness.set('Parent', handles.fret.preProcBox);
    handles.fret.brightness.JavaPeer.set('Maximum', 1e6);
    handles.fret.brightness.JavaPeer.set('Minimum', 0);
    handles.fret.brightness.JavaPeer.set('LowValue', 0);
    handles.fret.brightness.JavaPeer.set('HighValue', 1e6);
    handles.fret.brightness.JavaPeer.set('PaintTicks',true);
    handles.fret.brightness.JavaPeer.set('MajorTickSpacing',1e5);
    handles.fret.brightness.JavaPeer.set('MouseReleasedCallback', @(~,~) setBrightness(handles.fret.brightness));
    
    % auto brightness and invert box
    handles.fret.autoAndInvertHBox = uix.HBox('Parent', handles.fret.preProcBox);
    
    % invert
    handles.fret.invertCheckbox = uicontrol(     'Parent', handles.fret.autoAndInvertHBox,...
                                                'Style', 'checkbox',...
                                                'String', 'Invert',...
                                                'Callback', @(hObject,~) setInvert(hObject, guidata(hObject),hObject.Value));
    
    % auto brightness
    handles.fret.autoBrightnessButton = uicontrol('Parent', handles.fret.autoAndInvertHBox,...
                                                 'String', 'Auto Brightness',...
                                                 'Callback', @(hObject,~) autoBrightness(hObject, guidata(hObject)));
                                                
    handles.fret.preProcBox.set('Heights',[25 25 15 25 25]);
    handles.fret.sourceBox.set('Heights',[25 25 150]);
    
    %% Auto Detection
    handles.fret.autoPanel = uix.BoxPanel('Parent', handles.fret.leftPanel,...
                                           'Title','Auto Detection',...
                                           'Padding',5,...
                                           'Visible','off');
    handles.fret.autoBox = uix.VBox('Parent', handles.fret.autoPanel);
    
    % filter
    uicontrol( 'Parent', handles.fret.autoBox,...
               'Style' , 'text', ...
               'String', 'Gaussina Filter Size');
    [~, handles.fret.particleFilter] = javacomponent('javax.swing.JSlider');
    handles.fret.particleFilter.set('Parent', handles.fret.autoBox);
    handles.fret.particleFilter.JavaPeer.set('Maximum', 5e5);
    handles.fret.particleFilter.JavaPeer.set('Minimum', 0);
    handles.fret.particleFilter.JavaPeer.set('Value', 0);
    handles.fret.particleFilter.JavaPeer.set('MouseReleasedCallback', @(~,~) updateDisplay(handles.fret.particleFilter));
    % add filter lables
    parFilLabels = java.util.Hashtable();
    parFilLabels.put( int32( 0 ),   javax.swing.JLabel('0') );
    parFilLabels.put( int32( 1e5 ), javax.swing.JLabel('1') );
    parFilLabels.put( int32( 2e5 ), javax.swing.JLabel('2') );
    parFilLabels.put( int32( 3e5 ), javax.swing.JLabel('3') );
    parFilLabels.put( int32( 4e5 ), javax.swing.JLabel('4') );
    parFilLabels.put( int32( 5e5 ), javax.swing.JLabel('5') );
    handles.fret.particleFilter.JavaPeer.setLabelTable( parFilLabels );
    handles.fret.particleFilter.JavaPeer.setPaintLabels(true);
    
    % intensity
    uicontrol( 'Parent', handles.fret.autoBox,...
               'Style' , 'text', ...
               'String', 'Selected Intensities');
    [~, handles.fret.particleIntensity] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.fret.particleIntensity.set('Parent', handles.fret.autoBox);
    handles.fret.particleIntensity.JavaPeer.set('Maximum', 1e6);
    handles.fret.particleIntensity.JavaPeer.set('Minimum', 0);
    handles.fret.particleIntensity.JavaPeer.set('LowValue', 9e5);
    handles.fret.particleIntensity.JavaPeer.set('HighValue', 1e6);
    handles.fret.particleIntensity.JavaPeer.set('MouseReleasedCallback', @(~,~) updateDisplay(handles.fret.particleIntensity));
    
    handles.fret.autoBox.set('Heights',[15, 45 15 35]);
    %% Remove Clusters
    handles.fret.clusterPanel = uix.BoxPanel('Parent', handles.fret.leftPanel,...
                                           'Title','Remove Clusters',...
                                           'Padding',5,...
                                           'Visible','off');
    handles.fret.clusterBox = uix.VBox('Parent', handles.fret.clusterPanel);
    
    % on/off and count HBox
    handles.fret.clusterCheckAndCountBox = uix.HBox('Parent', handles.fret.clusterBox);
    
    % on/off
    handles.fret.clusterCheckBox = uicontrol(   'Parent', handles.fret.clusterCheckAndCountBox,...
                                                'Style' , 'checkbox', ...
                                                'String', 'Enable',...
                                                'Callback', @(hObject,~) updateDisplay(hObject,guidata(hObject)));
                                            
    % count
    handles.fret.clusterCount = uicontrol(   'Parent', handles.fret.clusterCheckAndCountBox,...
                                             'Style' , 'text',...
                                             'String', '0/0');
    
    % Eccentricity
    % text
    uicontrol( 'Parent', handles.fret.clusterBox,...
               'Style' , 'text', ...
               'String', 'Eccentricity');
    % box
    handles.fret.eccentricityBox = uix.HBox('Parent', handles.fret.clusterBox);
    % textbox
    handles.fret.eccentricityTextBox = uicontrol(   'Parent', handles.fret.eccentricityBox,...
                                                    'Style' , 'edit', ...
                                                    'String', '0',...
                                                    'Callback', @(hObject,~) setEccentricity(hObject,str2double(hObject.String)));
    % slider
    [~, handles.fret.eccentricitySlider] = javacomponent('javax.swing.JSlider');
    handles.fret.eccentricitySlider.set('Parent', handles.fret.eccentricityBox);
    handles.fret.eccentricitySlider.JavaPeer.set('Maximum', 1e6);
    handles.fret.eccentricitySlider.JavaPeer.set('Minimum', 0);
    handles.fret.eccentricitySlider.JavaPeer.set('Value', 0);
    handles.fret.eccentricitySlider.JavaPeer.set('MouseReleasedCallback', @(~,~) setEccentricity(handles.fret.eccentricitySlider, handles.fret.eccentricitySlider.JavaPeer.get('Value')/handles.fret.eccentricitySlider.JavaPeer.get('Maximum')));
    % widths
    handles.fret.eccentricityBox.set('Widths', [30, -1]);
    
    % Minimum Distance
    % text
    uicontrol( 'Parent', handles.fret.clusterBox,...
               'Style' , 'text', ...
               'String', 'Minimum Distance');
    % box
    handles.fret.minDistanceBox = uix.HBox( 'Parent', handles.fret.clusterBox);
    % textbox
    handles.fret.minDistanceTextBox = uicontrol(    'Parent', handles.fret.minDistanceBox,...
                                                	'Style' , 'edit', ...
                                                    'String', '5',...
                                                    'Callback', @(hObject,~) setMinDistance(hObject,str2double(hObject.String)));
    % slider
    [~, handles.fret.minDistanceSlider] = javacomponent('javax.swing.JSlider');
    handles.fret.minDistanceSlider.set('Parent', handles.fret.minDistanceBox);
    handles.fret.minDistanceSlider.JavaPeer.set('Maximum', 20e6);
    handles.fret.minDistanceSlider.JavaPeer.set('Minimum', 0);
    handles.fret.minDistanceSlider.JavaPeer.set('Value', 5e6);
    handles.fret.minDistanceSlider.JavaPeer.set('MouseReleasedCallback', @(~,~) setMinDistance(handles.fret.minDistanceSlider,handles.fret.minDistanceSlider.JavaPeer.get('Value')/handles.fret.minDistanceSlider.JavaPeer.get('Maximum')*20));
    % widths
    handles.fret.minDistanceBox.set('Widths', [30, -1]);
    
    % Edge size slider
    % text
    uicontrol( 'Parent', handles.fret.clusterBox,...
               'Style' , 'text', ...
               'String', 'Distance from edge');
    % box
    handles.fret.edgeDistanceBox = uix.HBox( 'Parent', handles.fret.clusterBox);
    % textbox
    handles.fret.edgeDistanceTextBox = uicontrol(   'Parent', handles.fret.edgeDistanceBox,...
                                                    'Style' , 'edit', ...
                                                    'String', '5',...
                                                    'Callback', @(hObject,~) setEdgeDistance(hObject,str2double(hObject.String)));
    % slider
    [~, handles.fret.edgeDistanceSlider] = javacomponent('javax.swing.JSlider');
    handles.fret.edgeDistanceSlider.set('Parent', handles.fret.edgeDistanceBox);
    handles.fret.edgeDistanceSlider.JavaPeer.set('Maximum', 20e6);
    handles.fret.edgeDistanceSlider.JavaPeer.set('Minimum', 0);
    handles.fret.edgeDistanceSlider.JavaPeer.set('Value', 5e6);
    handles.fret.edgeDistanceSlider.JavaPeer.set('MouseReleasedCallback', @(~,~) setEdgeDistance(handles.fret.edgeDistanceSlider, handles.fret.edgeDistanceSlider.JavaPeer.get('Value')/handles.fret.edgeDistanceSlider.JavaPeer.get('Maximum')*20));
    % widths
    handles.fret.edgeDistanceBox.set('Widths', [30, -1]);
    
    
    %% Traces
    handles.fret.tracePanel = uix.BoxPanel( 'Parent', handles.fret.leftPanel,...
                                            'Title','Traces',...
                                            'Padding',5,...
                                            'Visible','off');
    handles.fret.traceBox = uix.VButtonBox( 'Parent', handles.fret.tracePanel,...
                                        	'ButtonSize',[120 25],...
                                          	'Spacing',2);
    % button
    handles.fret.traceButton = uicontrol(   'Parent', handles.fret.traceBox,...
                                            'String', 'Generate Traces',...
                                            'Callback', @(hObject,~) openTraces(hObject, guidata(hObject)));
                                                 
    %% 
    handles.fret.leftPanel.set('Heights',[25 200 135 175 60]);
end

%% Load from session
function handles = loadFromSession(hObject,handles,session)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    % source
    handles.fret.sourcePopUpMenu.Value = session.fret_source;
    
    % channel
    if isappdata(handles.f,'data_video_originalSeperatedStacks')
        numChannels = size(getappdata(handles.f,'data_video_originalSeperatedStacks'),1);
        names = getappdata(handles.f,'ROINames');
        handles.fret.sourceChannelPopUpMenu.String = names(1:numChannels);
        handles.fret.channelBox.Visible = 'on';
    else
        handles.fret.sourceChannelPopUpMenu.String = {''};
        handles.fret.channelBox.Visible = 'off';
    end
    handles.fret.sourceChannelPopUpMenu.Value = session.fret_channel;
    
    % time average
    handles.fret.sourceTimeAvgCheckBox.Value = session.fret_timeAvg;
    
    % get the stack
    switch handles.fret.sourcePopUpMenu.Value
        case 2 % Current 
            
        case 3 % Import
            handles = setVideoFile(hObject, handles, session.fret_videoFilePath);
            mappingInterface('collocalizeFRETImport',hObject,handles);
    end
    stack = getSourceStack(hObject,handles);
    
    % frame controls
    % set max before values
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    
    % frame
    handles.axesControl.currentFrameTextbox.String = num2str(session.fret_currentFrame);
    set(handles.axesControl.currentFrame.JavaPeer, 'Value', session.fret_currentFrame);
    setappdata(handles.f,'fret_currentFrame',session.fret_currentFrame)
    
    % brightness controls
    set(handles.fret.brightness.JavaPeer, 'LowValue', session.fret_lowBrightness);
    set(handles.fret.brightness.JavaPeer, 'HighValue', session.fret_highBrightness);
    handles.fret.invertCheckbox.Value = session.fret_invertImage;
    
    % auto detection
    handles.fret.particleIntensity.JavaPeer.set('LowValue',session.fret_particleIntensityLow);
    handles.fret.particleIntensity.JavaPeer.set('HighValue',session.fret_particleIntensityHigh);
    handles.fret.particleFilter.JavaPeer.set('Value',session.fret_particleFilter);
    
    % cluster settings
    handles.fret.clusterCheckBox.Value = session.fret_clustering;
    handles.fret.eccentricitySlider.JavaPeer.set('Value', session.fret_eccentricity);
    handles.fret.minDistanceSlider.JavaPeer.set('Value', session.fret_minDistance);
    handles.fret.edgeDistanceSlider.JavaPeer.set('Value', session.fret_edgeDistance);
    handles.fret.eccentricityTextBox.String = num2str(session.fret_eccentricity / handles.fret.eccentricitySlider.JavaPeer.get('Maximum'));
    handles.fret.minDistanceTextBox.String = num2str(session.fret_minDistance / handles.fret.minDistanceSlider.JavaPeer.get('Maximum') * 20);
    handles.fret.edgeDistanceTextBox.String = num2str(session.fret_edgeDistance / handles.fret.edgeDistanceSlider.JavaPeer.get('Maximum') * 20);
        
    switchMode(hObject, handles, session.fret_mode);
end

%% Source
function selectSource(hObject,handles)
    switch handles.fret.sourcePopUpMenu.Value
        case 1 % None
            switchMode(hObject, handles, 'Select Source');
        case 2 % Current vid
            if ~strcmp(handles.vid.selectVideoTextBox.String, 'No video selected')
                setappdata(handles.f,'fretImport_maxIntensity',getappdata(handles.f,'video_maxIntensity'));
                setControlsForNewVideo(hObject, handles);
                switchMode(hObject, handles, 'Edit Current');
            else
                msgbox('The video has not been imported. Go to video settings.');
            end
        case 3 % Import
            handles.fret.importVideoTextbox.Visible = 'on';
            
            [fileName, fileDir, ~] = uigetfile([getappdata(handles.f,'savePath') '*.tif;*.tiff;*.TIF;*.TIFF'], 'Select the video file'); % prompt user for file
            if fileName ~= 0 % if user does not presses cancel
                importVideoTextBoxCallback(hObject, [fileDir fileName]);
            else
                handles.fret.sourcePopUpMenu.Value = 1;
            end
    end
end

function selectSourceChannel(hObject,handles)
    autoBrightness(hObject,handles); % this will also update the display
end

%% Import Video
function importVideoTextBoxCallback(hObject, filePath)
    handles = guidata(hObject);
    handles = setVideoFile(hObject, handles, filePath);
    setControlsForNewVideo(hObject, handles);
    switchMode(hObject, handles, 'Edit Import');
end

function handles = setControlsForNewVideo(hObject, handles)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    % channel
    if getappdata(handles.f,'isMapped')
        numChannels = size(getappdata(handles.f,'ROI'),1);
        names = getappdata(handles.f,'ROINames');
        handles.fret.sourceChannelPopUpMenu.String = names(1:numChannels);
        handles.fret.channelBox.Visible = 'on';
        
        mappingInterface('collocalizeFRETImport',hObject,handles);
    else
        handles.fret.sourceChannelPopUpMenu.String = {''};
        handles.fret.channelBox.Visible = 'off';
    end
    
    % requires a video to have been saved
    stack = getSourceStack(hObject,handles);
    maxIntensity = getappdata(handles.f,'fretImport_maxIntensity');
    
    % frame controls
    % set max before values
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    handles.fret.particleIntensity.JavaPeer.set('Maximum', maxIntensity);
    handles.fret.particleIntensity.JavaPeer.set('LowValue', 0.9*maxIntensity);
    handles.fret.particleIntensity.JavaPeer.set('HighValue', maxIntensity);
    
    % frame
    set(handles.axesControl.currentFrame.JavaPeer,'Value',1);
    setappdata(handles.f,'fret_currentFrame',1)
    handles.axesControl.currentFrameTextbox.String = '1';
    
    % brightness controls
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
    I = stack(:,:,1);
    autoImAdjust = stretchlim(I(combinedROIMask)); % get the auto brightness values    
    autoImAdjust = round(autoImAdjust * get(handles.fret.brightness.JavaPeer,'Maximum'));
    set(handles.fret.brightness.JavaPeer,'LowValue',autoImAdjust(1));
    set(handles.fret.brightness.JavaPeer,'HighValue',autoImAdjust(2));
    
    % invet
    handles.fret.invertCheckbox.Value   = 0;
    
    autoBrightness(hObject,handles); % this will also update the display
end
    
function handles = setVideoFile(hObject, handles, filePath)
    hWaitBar = waitbar(0,'Loading in video...', 'WindowStyle', 'modal');
    [stack, maxIntensity] = getStackFromFile(filePath, hWaitBar);
    if stack == 0 % an error was encountored
        filePath = 'No video selected';
    end
    
    % save
    handles.fret.importVideoTextbox.String = filePath;
    setappdata(handles.f,'data_fretImport_originalStack',stack);
    setappdata(handles.f,'fretImport_maxIntensity',maxIntensity);
    
    close(hWaitBar);
end

%% Display
function onDisplay(hObject,handles)
    % current frame
    stack = getSourceStack(hObject,handles);
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    set(handles.axesControl.currentFrame.JavaPeer,'Value', getappdata(handles.f,'fret_currentFrame'));
    set(handles.axesControl.currentFrameTextbox,'String', num2str(getappdata(handles.f,'fret_currentFrame')));
    handles.axesControl.currentFrame.JavaPeer.set('MouseReleasedCallback', ...
        @(~,~) setCurrentFrame(handles.axesControl.currentFrame, get(handles.axesControl.currentFrame.JavaPeer,'Value')));
    handles.axesControl.currentFrameTextbox.set('Callback', @(hObject,~) setCurrentFrame( hObject, str2num(hObject.String)));
    handles.axesControl.playButton.set('Callback', @(hObject,~) playVideo( hObject, guidata(hObject)));
    
    % overlap mode
    handles.axesControl.seperateButtonGroup.Visible =  'off';
    handles.axesPanel.Selection = 1; % overlap channels mode for one axes
    
    switchMode(hObject, handles, getappdata(handles.f,'fret_mode'));
end

function onRelease(hObject,handles)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    % current frame
    setappdata(handles.f,'fret_currentFrame', get(handles.axesControl.currentFrame.JavaPeer,'Value'));
    
    % remove detected particles graphic
    plt = getappdata(handles.f,'data_fret_plt');
    if ~isempty(plt)
        delete(plt);
    end
    plt = [];
    setappdata(handles.f,'data_fret_plt',plt);
    
    homeInterface('openHome',hObject);
end

function updateDisplay(hObject,handles) 
    if ~exist('handles','var')
        handles = guidata(hObject);
    end
    
    % get data
    I = getCurrentImage(hObject,handles);
    
    filterSize = handles.fret.particleFilter.JavaPeer.get('Value') / handles.fret.particleFilter.JavaPeer.get('Maximum') * 5;
    particleMinInt = handles.fret.particleIntensity.JavaPeer.get('LowValue');
    particleMaxInt = handles.fret.particleIntensity.JavaPeer.get('HighValue');
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
    
    particleClustering = handles.fret.clusterCheckBox.Value;

    % filter image
    if filterSize > 0.1
        I = imgaussfilt(I, filterSize);
    end
    I = imadjust(I);
    
    % display filtered image
    handles.oneAxes.AxesAPI.replaceImage(I,'PreserveView',true);
    
    % detect particles
    if particleClustering
        particleMaxEccentricity = handles.fret.eccentricitySlider.JavaPeer.get('Value') / handles.fret.eccentricitySlider.JavaPeer.get('Maximum');
        particleMinDistance = handles.fret.minDistanceSlider.JavaPeer.get('Value') / handles.fret.minDistanceSlider.JavaPeer.get('Maximum') * 20;
        edgeDistance = handles.fret.edgeDistanceSlider.JavaPeer.get('Value') / handles.fret.edgeDistanceSlider.JavaPeer.get('Maximum') * 20;

        particles = findParticles(I, particleMinInt, particleMaxInt,...
                                    'EdgeDistance', edgeDistance,...
                                    'Mask', combinedROIMask,...
                                    'MaxEccentricity',particleMaxEccentricity,...
                                    'MinDistance', particleMinDistance);
                                
        totalParticles = findParticles(I, particleMinInt, particleMaxInt, 'Mask', combinedROIMask);
        
        totalParticlesCount = size(totalParticles{1},1);
    else
        particles = findParticles(I, particleMinInt, particleMaxInt, 'Mask', combinedROIMask);
        totalParticlesCount = size(particles{1},1);
    end
    centers = particles{1};

    % display particles
    hWaitBar = waitbar(0,'Loading ...');
    hold(handles.oneAxes.Axes,'on');
    plt = getappdata(handles.f,'data_fret_plt');
    if ~isempty(plt)
        delete(plt);
    end
    plt = plot( handles.oneAxes.Axes, centers(:,1), centers(:,2), '+r');
    hold(handles.oneAxes.Axes,'off');
    setappdata(handles.f,'data_fret_plt',plt);
    
    % display count
    handles.fret.clusterCount.String = [num2str(size(centers,1)) ' / ' num2str(totalParticlesCount) ' = ' num2str(size(centers,1)/totalParticlesCount*100,'%2.2f') '%'];
    
    
    delete(hWaitBar);
end

function switchMode(hObject, handles, value)
    setappdata(handles.f,'fret_mode',value);

    handles.rightPanel.Visible = 'off';
    handles.axesControl.seperateButtonGroup.Visible = 'off';
    handles.fret.preProcBox.Visible = 'off';
    handles.fret.importVideoTextbox.Visible = 'off';
    handles.fret.autoPanel.Visible = 'off';
    handles.fret.manualDNAPanel.Visible = 'off';
    handles.fret.tracePanel.Visible = 'off';
    handles.fret.clusterPanel.Visible = 'off';
    handles.fret.edgePanel.Visible = 'off';
    
    switch value
        case 'Select Source'
            
        case 'Edit Current'
            handles.rightPanel.Visible = 'on';
            handles.fret.preProcBox.Visible = 'on';
            handles.axesControl.currentFramePanel.Visible = 'on';
            handles.fret.autoPanel.Visible = 'on';
            handles.fret.manualDNAPanel.Visible = 'on';
            handles.fret.tracePanel.Visible = 'on';
            handles.fret.clusterPanel.Visible = 'on';
            handles.fret.edgePanel.Visible = 'on';
            if strcmp(getappdata(handles.f,'mode'),'Select FRET')
                updateDisplay(hObject,handles);
            end
            handles.oneAxes.AxesAPI.setMagnification(handles.oneAxes.AxesAPI.findFitMag()); % update magnification
        case 'Edit Import'
            handles.rightPanel.Visible = 'on';
            handles.fret.preProcBox.Visible = 'on';
            handles.fret.importVideoTextbox.Visible = 'on';
            handles.fret.autoPanel.Visible = 'on';
            handles.fret.manualDNAPanel.Visible = 'on';
            handles.fret.tracePanel.Visible = 'on';
            handles.fret.clusterPanel.Visible = 'on';
            handles.fret.edgePanel.Visible = 'on';
            if strcmp(getappdata(handles.f,'mode'),'Select FRET')
                updateDisplay(hObject,handles);
            end
            handles.oneAxes.AxesAPI.setMagnification(handles.oneAxes.AxesAPI.findFitMag()); % update magnification
    end
    
    if handles.fret.sourceTimeAvgCheckBox.Value
        handles.axesControl.currentFramePanel.Visible =  'off';
    else
        handles.axesControl.currentFramePanel.Visible =  'on';
    end
end

function stack = getSourceStack(hObject,handles)
    if handles.fret.sourcePopUpMenu.Value == 1
        stack = 1;
        return;
    end
    
    if isempty(handles.fret.sourceChannelPopUpMenu.String{1})
        switch handles.fret.sourcePopUpMenu.Value
            case 2 % Current vid
                stack = getappdata(handles.f,'data_video_originalStack');

            case 3 % Import
                stack = getappdata(handles.f,'data_fretImport_originalStack');
        end
    else
        switch handles.fret.sourcePopUpMenu.Value
            case 2 % Current vid
                stacks = getappdata(handles.f,'data_video_seperatedStacks');

            case 3 % Import
                stacks = getappdata(handles.f,'data_fretImport_seperatedStacks');
        end
        stack = stacks{handles.fret.sourceChannelPopUpMenu.Value};
    end
end

function I = getCurrentImage(hObject,handles,brightnessflag)
    % get values
    currentFrame = getappdata(handles.f,'fret_currentFrame');
    timeAverage = handles.fret.sourceTimeAvgCheckBox.Value;
    lowBrightness = get(handles.fret.brightness.JavaPeer,'LowValue')/get(handles.fret.brightness.JavaPeer,'Maximum');
    highBrightness = get(handles.fret.brightness.JavaPeer,'HighValue')/get(handles.fret.brightness.JavaPeer,'Maximum');
    invertImage = handles.fret.invertCheckbox.Value;
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
    stack = getSourceStack(hObject,handles);
    
    % current frame/timeAverage
    if timeAverage
        I = timeAvgStack(stack);
    else
        I = stack(:,:,currentFrame);
    end
    % invert
    if invertImage
        I = imcomplement(I);
    end
    % brightness
    if ~exist('brightnessflag','var') % used for autobrightness
        I = imadjust(I,[lowBrightness,highBrightness]);
    end
    % crop overlay
    I(~combinedROIMask) = 0;
end

%% Play/pause Current Frame
function setCurrentFrame(hObject, value)
    handles = guidata(hObject);
    set(handles.axesControl.currentFrame.JavaPeer,'Value',value);
    handles.axesControl.currentFrameTextbox.String = num2str(value);
    setappdata(handles.f,'fret_currentFrame', value);
    updateDisplay(hObject,handles);
end

function playVideo(hObject,handles)
    % switch play button to pause button
    handles.axesControl.playButton.String = 'Pause';
    handles.axesControl.playButton.Callback = @(hObject,~) pauseVideo(hObject,guidata(hObject));
    
    % play loop
    setappdata(handles.f,'Playing_Video',1);
    currentFrame = handles.axesControl.currentFrame.JavaPeer.get('Value');
    while getappdata(handles.f,'Playing_Video')
        playSpeed = getappdata(handles.f,'playSpeed');
        if currentFrame+playSpeed <= handles.axesControl.currentFrame.JavaPeer.get('Maximum')
            currentFrame = currentFrame+playSpeed;
        else
            currentFrame = 1;
        end
        setCurrentFrame(hObject, currentFrame);
        drawnow;
    end
end

function pauseVideo(hObject,handles)
    % switch pause button to play button
    handles.axesControl.playButton.String = 'Play';
    handles.axesControl.playButton.Callback = @(hObject,~) playVideo(hObject,guidata(hObject));
    
    % flag to stop play loop
    setappdata(handles.f,'Playing_Video',0);
end

%% Pre-proccess Callbacks
function setBrightness(hObject)
    handles = guidata(hObject);
    lowBrightness = get(handles.fret.brightness.JavaPeer,'LowValue');
    highBrightness = get(handles.fret.brightness.JavaPeer,'HighValue');
    if lowBrightness==highBrightness
        if lowBrightness==0
            set(handles.fret.brightness.JavaPeer,'HighValue',highBrightness+1)
        else
            set(handles.fret.brightness.JavaPeer,'LowValue',lowBrightness-1)
        end
    end
    
    updateDisplay(hObject,handles);
end

function autoBrightness(hObject, handles)
    I = getCurrentImage(hObject,handles,1); % 1 is for no brightness flag
    
    if isappdata(handles.f,'data_video_originalSeperatedStacks')
        combinedROIMask = getappdata(handles.f,'combinedROIMask');
        autoImAdjust = stretchlim(I(combinedROIMask));
    else
        autoImAdjust = stretchlim(I);
    end
    
    autoImAdjust = round(autoImAdjust * get(handles.fret.brightness.JavaPeer,'Maximum'));
    
    set(handles.fret.brightness.JavaPeer,'LowValue',autoImAdjust(1));
    set(handles.fret.brightness.JavaPeer,'HighValue',autoImAdjust(2));

    updateDisplay(hObject,handles);
end

function setInvert(hObject, handles, value)
    handles.fret.invertCheckbox.Value = value;
    autoBrightness(hObject,handles); % this will also update the display
end

function changeTimeAverage(hObject, handles, value)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    handles.fret.sourceTimeAvgCheckBox.Value = value;
    
    % hide current frame slider if time average is on
    if handles.fret.sourceTimeAvgCheckBox.Value
        handles.axesControl.currentFramePanel.Visible =  'off';
    else
        handles.axesControl.currentFramePanel.Visible =  'on';
    end
    
    autoBrightness(hObject,handles); % this will also update the display
end

%% Clustering Callbacks
function setEccentricity(hObject, value)
    handles = guidata(hObject);
    
    value = value * handles.fret.eccentricitySlider.JavaPeer.get('Maximum');
    handles.fret.eccentricitySlider.JavaPeer.set('Value', value);
    value = handles.fret.eccentricitySlider.JavaPeer.get('Value') / handles.fret.eccentricitySlider.JavaPeer.get('Maximum');
    handles.fret.eccentricityTextBox.String = num2str(value);
    
    updateDisplay(hObject, handles);
end

function setMinDistance(hObject, value)
    handles = guidata(hObject);
    
    value = value * handles.fret.minDistanceSlider.JavaPeer.get('Maximum') / 20;
    handles.fret.minDistanceSlider.JavaPeer.set('Value', value);
    value = handles.fret.minDistanceSlider.JavaPeer.get('Value') / handles.fret.minDistanceSlider.JavaPeer.get('Maximum') * 20;
    handles.fret.minDistanceTextBox.String = num2str(value);
    
    updateDisplay(hObject, handles);
end

function setEdgeDistance(hObject, value)
    handles = guidata(hObject);
    
    value = value * handles.fret.edgeDistanceSlider.JavaPeer.get('Maximum') / 20;
    handles.fret.edgeDistanceSlider.JavaPeer.set('Value', value);
    value = handles.fret.edgeDistanceSlider.JavaPeer.get('Value') / handles.fret.edgeDistanceSlider.JavaPeer.get('Maximum') * 20;
    handles.fret.edgeDistanceTextBox.String = num2str(value);
    
    updateDisplay(hObject, handles);
end

%% Auto Dectect
function autoDetect(hObject, handles)
    hWaitBar = waitbar(0,'Finding ...');
    
    
    
    close(hWaitBar);
end

%% Traces
function openTraces(hObject,handles,loadingSession)
    if ~exist('handles') || ~isstruct(handles)
        handles = guidata(hObject);
    end
    
    if strcmp(handles.vid.selectVideoTextBox.String, 'No video selected')
        msgbox('The video has not been imported. Go to video settings.');
        return;
    end
    
    onRelease(hObject,handles);
    
    if exist('loadingSession','var')
        analyzeFRETInterface('onDisplay',hObject,handles,loadingSession);
    else
        analyzeFRETInterface('onDisplay',hObject,handles);
    end
    handles.leftPanel.Selection = 7;
end

