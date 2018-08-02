function varargout = generateFlowStrechingInterface(varargin)
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
    setappdata(handles.f,'flow_mode','Source');
    setappdata(handles.f,'flow_currentFrame',1);
    setappdata(handles.f,'data_flow_plt',[]);
    setappdata(handles.f,'data_flow_trackingPlt',[]);

    handles.flow = struct();
    handles.flow.leftPanel = uix.VBox( 'Parent', handles.leftPanel);
    
    %% back
    handles.flow.backButtonPanel = uix.Panel('Parent', handles.flow.leftPanel);
    handles.flow.backButton = uicontrol(     'Parent', handles.flow.backButtonPanel,...
                                          	 'String', 'Back',...
                                          	 'Callback', @(hObject,~) onRelease(hObject,guidata(hObject)));
    
    handles.flow.preProcPanel = uix.Panel('Parent', handles.flow.leftPanel);
    % pre-processbox
    handles.flow.preProcBox = uix.VBox('Parent', handles.flow.preProcPanel);
    
    % time average
    handles.flow.sourceTimeAvgCheckBox = uicontrol( 'Parent', handles.flow.preProcBox,...
                                                    'style', 'checkbox',...
                                                    'String', 'Time Average',...
                                                    'Callback', @(hObject,~) changeTimeAverage(hObject,guidata(hObject),hObject.Value));
    
    % brightness
    uicontrol( 'Parent', handles.flow.preProcBox,...
               'Style' , 'text', ...
               'String', 'Brightness');
    [~, handles.flow.brightness] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.flow.brightness.set('Parent', handles.flow.preProcBox);
    handles.flow.brightness.JavaPeer.set('Maximum', 1e6);
    handles.flow.brightness.JavaPeer.set('Minimum', 0);
    handles.flow.brightness.JavaPeer.set('LowValue', 0);
    handles.flow.brightness.JavaPeer.set('HighValue', 1e6);
    handles.flow.brightness.JavaPeer.set('PaintTicks',true);
    handles.flow.brightness.JavaPeer.set('MajorTickSpacing',1e5);
    handles.flow.brightness.JavaPeer.set('MouseReleasedCallback', @(~,~) setBrightness(handles.flow.brightness));
    
    % auto brightness and invert box
    handles.flow.autoAndInvertHBox = uix.HBox('Parent', handles.flow.preProcBox);
    
    % invert
    handles.flow.invertCheckbox = uicontrol(     'Parent', handles.flow.autoAndInvertHBox,...
                                                'Style', 'checkbox',...
                                                'String', 'Invert',...
                                                'Callback', @(hObject,~) setInvert(hObject, guidata(hObject),hObject.Value));
    
    % auto brightness
    handles.flow.autoBrightnessButton = uicontrol('Parent', handles.flow.autoAndInvertHBox,...
                                                 'String', 'Auto Brightness',...
                                                 'Callback', @(hObject,~) autoBrightness(hObject, guidata(hObject)));
                                                
    handles.flow.preProcBox.set('Heights',[25 15 25 25]);
    
    %% Auto Detection
    handles.flow.autoPanel = uix.BoxPanel('Parent', handles.flow.leftPanel,...
                                           'Title','Auto Detection',...
                                           'Padding',5,...
                                           'Visible','off');
    handles.flow.autoBox = uix.VBox('Parent', handles.flow.autoPanel);
    
    % filter
    uicontrol( 'Parent', handles.flow.autoBox,...
               'Style' , 'text', ...
               'String', 'Gaussina Filter Size');
    [~, handles.flow.particleFilter] = javacomponent('javax.swing.JSlider');
    handles.flow.particleFilter.set('Parent', handles.flow.autoBox);
    handles.flow.particleFilter.JavaPeer.set('Maximum', 5e5);
    handles.flow.particleFilter.JavaPeer.set('Minimum', 0);
    handles.flow.particleFilter.JavaPeer.set('Value', 0);
    handles.flow.particleFilter.JavaPeer.set('MouseReleasedCallback', @(~,~) updateDisplay(handles.flow.particleFilter));
    % add filter lables
    parFilLabels = java.util.Hashtable();
    parFilLabels.put( int32( 0 ),   javax.swing.JLabel('0') );
    parFilLabels.put( int32( 1e5 ), javax.swing.JLabel('1') );
    parFilLabels.put( int32( 2e5 ), javax.swing.JLabel('2') );
    parFilLabels.put( int32( 3e5 ), javax.swing.JLabel('3') );
    parFilLabels.put( int32( 4e5 ), javax.swing.JLabel('4') );
    parFilLabels.put( int32( 5e5 ), javax.swing.JLabel('5') );
    handles.flow.particleFilter.JavaPeer.setLabelTable( parFilLabels );
    handles.flow.particleFilter.JavaPeer.setPaintLabels(true);
    
    % intensity
    uicontrol( 'Parent', handles.flow.autoBox,...
               'Style' , 'text', ...
               'String', 'Selected Intensities');
    [~, handles.flow.particleIntensity] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.flow.particleIntensity.set('Parent', handles.flow.autoBox);
    handles.flow.particleIntensity.JavaPeer.set('Maximum', 1e6);
    handles.flow.particleIntensity.JavaPeer.set('Minimum', 0);
    handles.flow.particleIntensity.JavaPeer.set('LowValue', 9e5);
    handles.flow.particleIntensity.JavaPeer.set('HighValue', 1e6);
    handles.flow.particleIntensity.JavaPeer.set('MouseReleasedCallback', @(~,~) updateDisplay(handles.flow.particleIntensity));
    
    %% Remove background
    handles.flow.removeBgPanel = uix.BoxPanel(  'Parent', handles.flow.leftPanel,...
                                                'Title','Remove Background',...
                                                'Padding',5,...
                                                'Visible','off');
                                            
    handles.flow.removeBgBox = uix.VButtonBox('Parent', handles.flow.removeBgPanel,...
                                                'ButtonSize', [200 25]);
                                            
    handles.flow.selectBackgroundVideoButton = uicontrol( 'Parent', handles.flow.removeBgBox,...
                                                'String', 'Select Background Video/Image',...
                                                'Callback', @(hObject,~) selectBackgroundVideoButtonCallback(hObject));
                                            
    handles.flow.selectBackgroundVideoTextBox = uicontrol( 'Parent', handles.flow.removeBgBox,...
                                                'Style' , 'edit', ...
                                                'String', 'No background video selected',...
                                                'Callback', @(hObject,~) selectBackgroundVideoTextBoxCallback(hObject,hObject.String));
    
    
    %% Profiles
    handles.flow.profilePanel = uix.BoxPanel('Parent', handles.flow.leftPanel,...
                                             'Title','Traces',...
                                             'Padding',5);
    handles.flow.profileBox = uix.VBox( 'Parent', handles.flow.profilePanel);
    
    % max tracking distance
    handles.flow.trackingDistanceBox = uix.HBox( 'Parent', handles.flow.profileBox);
    
    uicontrol(  'Parent', handles.flow.trackingDistanceBox,...
                'String', 'Maximum Track Distance',...
                'Style', 'text');
    
    handles.flow.trackingDistance = uicontrol(  'Parent', handles.flow.trackingDistanceBox,...
                                                'String', '2',...
                                                'Style', 'edit');
                                            
                                            
    % view tracks
    handles.flow.trackingButton = uicontrol( 'Parent', handles.flow.profileBox,...
                                            'String', 'View Tracks (takes a few mins)',...
                                            'Callback', @(hObject,~) updateTracking(hObject, guidata(hObject)));
                                            
    % gernerate profiles
    handles.flow.profileButton = uicontrol( 'Parent', handles.flow.profileBox,...
                                            'String', 'Generate Profiles',...
                                            'Callback', @(hObject,~) openAnalyzeFlowStreching(hObject, guidata(hObject)));
                                                 
    %% 
    handles.flow.leftPanel.set('Heights',[25 100 125 75 130]);
end

%% Load from session
function handles = loadFromSession(hObject,handles,session)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    % profiles
    setappdata(handles.f,'flowStrechingProfiles',session.flowStrechingProfiles);
    
    % time average
    handles.flow.sourceTimeAvgCheckBox.Value = session.flow_timeAvg;
    
    stack = getSourceStack(hObject,handles);
    
    % frame controls
    % set max before values
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    
    % frame
    handles.axesControl.currentFrameTextbox.String = num2str(session.flow_currentFrame);
    set(handles.axesControl.currentFrame.JavaPeer, 'Value', session.flow_currentFrame);
    setappdata(handles.f,'flow_currentFrame',session.flow_currentFrame)
    
    % brightness controls
    set(handles.flow.brightness.JavaPeer, 'LowValue', session.flow_lowBrightness);
    set(handles.flow.brightness.JavaPeer, 'HighValue', session.flow_highBrightness);
    handles.flow.invertCheckbox.Value = session.flow_invertImage;
    
    % auto detection
    handles.flow.particleIntensity.JavaPeer.set('LowValue',session.flow_particleIntensityLow);
    handles.flow.particleIntensity.JavaPeer.set('HighValue',session.flow_particleIntensityHigh);
    handles.flow.particleFilter.JavaPeer.set('Value',session.flow_particleFilter);
    
    % background video path
    handles.flow.selectBackgroundVideoTextBox.String = session.flow_backgroundFilePath;
    
    % max tracking distance
    handles.flow.trackingDistance.String = num2str(session.flow_trackingDistance);
        
    switchMode(hObject, handles, session.flow_mode);
end

%% Select Background Image Callback
function selectBackgroundVideoButtonCallback(hObject)
    [fileName, fileDir, ~] = uigetfile([getappdata(handles.f,'savePath') '*.tif;*.tiff;*.TIF;*.TIFF'], 'Select the background video file'); % prompt user for file
    if fileName ~= 0 % if user does not presses cancel
        selectBackgroundVideoTextBoxCallback(hObject, [fileDir fileName]);
    end
end

function selectBackgroundVideoTextBoxCallback(hObject, filePath)
    handles = guidata(hObject);
    handles = setBackgroundVideoFile(hObject, handles, filePath);
    updateDisplay(hObject,handles);
end
    
function handles = setBackgroundVideoFile(hObject, handles, filePath)
    hWaitBar = waitbar(0,'Loading in video...', 'WindowStyle', 'modal');
    [stack, maxIntensity] = getStackFromFile(filePath, hWaitBar, true);
    if stack == 0 % an error was encountored
        filePath = 'No background video selected';
    end
    
    I = timeAvgStack(stack);
    
    % save
    handles.flow.selectBackgroundVideoTextBox.String = filePath;
    setappdata(handles.f,'data_flow_backgroundImage',I);
    setappdata(handles.f,'flow_maxIntensity',maxIntensity);
    
    close(hWaitBar);
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
        handles.flow.sourceChannelPopUpMenu.String = names(1:numChannels);
        handles.flow.channelBox.Visible = 'on';
        
        mappingInterface('collocalizeflowImport',hObject,handles);
    else
        handles.flow.sourceChannelPopUpMenu.String = {''};
        handles.flow.channelBox.Visible = 'off';
    end
    
    % requires a video to have been saved
    stack = getSourceStack(hObject,handles);
    maxIntensity = getappdata(handles.f,'flowImport_maxIntensity');
    
    % frame controls
    % set max before values
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    handles.flow.particleIntensity.JavaPeer.set('Maximum', maxIntensity);
    handles.flow.particleIntensity.JavaPeer.set('LowValue', 0.9*maxIntensity);
    handles.flow.particleIntensity.JavaPeer.set('HighValue', maxIntensity);
    
    % frame
    set(handles.axesControl.currentFrame.JavaPeer,'Value',1);
    setappdata(handles.f,'flow_currentFrame',1)
    handles.axesControl.currentFrameTextbox.String = '1';
    
    % brightness controls
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
    I = stack(:,:,1);
    autoImAdjust = stretchlim(I(combinedROIMask)); % get the auto brightness values    
    autoImAdjust = round(autoImAdjust * get(handles.flow.brightness.JavaPeer,'Maximum'));
    set(handles.flow.brightness.JavaPeer,'LowValue',autoImAdjust(1));
    set(handles.flow.brightness.JavaPeer,'HighValue',autoImAdjust(2));
    
    % invet
    handles.flow.invertCheckbox.Value   = 0;
    
    autoBrightness(hObject,handles); % this will also update the display
end
    
function handles = setVideoFile(hObject, handles, filePath)
    hWaitBar = waitbar(0,'Loading in video...', 'WindowStyle', 'modal');
    [stack, maxIntensity] = getStackFromFile(filePath, hWaitBar);
    if stack == 0 % an error was encountored
        filePath = 'No video selected';
    end
    
    % save
    handles.flow.importVideoTextbox.String = filePath;
    setappdata(handles.f,'data_flowImport_originalStack',stack);
    setappdata(handles.f,'flowImport_maxIntensity',maxIntensity);
    
    close(hWaitBar);
end

%% Display
function onDisplay(hObject,handles)
    % current frame
    stack = getSourceStack(hObject,handles);
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    set(handles.axesControl.currentFrame.JavaPeer,'Value', getappdata(handles.f,'flow_currentFrame'));
    set(handles.axesControl.currentFrameTextbox,'String', num2str(getappdata(handles.f,'flow_currentFrame')));
    handles.axesControl.currentFrame.JavaPeer.set('StateChangedCallback', ...
        @(~,~) setCurrentFrame(handles.axesControl.currentFrame, get(handles.axesControl.currentFrame.JavaPeer,'Value')));
    handles.axesControl.currentFrameTextbox.set('Callback', @(hObject,~) setCurrentFrame( hObject, str2num(hObject.String)));
    handles.axesControl.playButton.set('Callback', @(hObject,~) playVideo( hObject, guidata(hObject)));
    
    % brightness
    handles.flow.particleIntensity.JavaPeer.set('Maximum',getappdata(handles.f,'video_maxIntensity'));
    
    % overlap mode
    handles.axesControl.seperateButtonGroup.Visible =  'off';
    handles.axesPanel.Selection = 1; % overlap channels mode for one axes
    
    switchMode(hObject, handles, getappdata(handles.f,'flow_mode'));
end

function onRelease(hObject,handles)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    % current frame
    setappdata(handles.f,'flow_currentFrame', get(handles.axesControl.currentFrame.JavaPeer,'Value'));
    
    % remove detected particles graphic
    plt = getappdata(handles.f,'data_flow_plt');
    if ~isempty(plt)
        delete(plt);
    end
    trackingPlt = getappdata(handles.f,'data_flow_trackingPlt');
    if ~isempty(trackingPlt)
        for i = 1:size(trackingPlt,1)
            delete(trackingPlt{i});
        end
    end
    setappdata(handles.f,'data_flow_plt',plt);
    setappdata(handles.f,'data_flow_trackingPlt',trackingPlt);
    
    homeInterface('openHome',hObject);
end

function updateDisplay(hObject,handles) 
    if ~exist('handles','var')
        handles = guidata(hObject);
    end
    
    if getappdata(handles.f,'isLoading')
        if ~isappdata(handles.f,'data_video_stack')
            return;
        end
    end
    
    % get data
    I = getCurrentImage(hObject,handles);
    
    filterSize = handles.flow.particleFilter.JavaPeer.get('Value') / ...
        handles.flow.particleFilter.JavaPeer.get('Maximum') * 5;
    particleMinInt = handles.flow.particleIntensity.JavaPeer.get('LowValue');
    particleMaxInt = handles.flow.particleIntensity.JavaPeer.get('HighValue');
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
        
    % filter image
    if filterSize > 0.1
        I = imgaussfilt(I, filterSize);
    end
        
    % display filtered image
    handles.oneAxes.AxesAPI.replaceImage(I,'PreserveView',true);
    
    % detect particles
    particles = findParticles(I, particleMinInt, particleMaxInt, 'Mask', combinedROIMask);
    centers = particles{1};

    % display particles
    hWaitBar = waitbar(0,'Loading ...');
    hold(handles.oneAxes.Axes,'on');
    plt = getappdata(handles.f,'data_flow_plt');
    if ~isempty(plt)
        delete(plt);
    end
    
    % remove plot of tracks
    trackingPlt = getappdata(handles.f,'data_flow_trackingPlt');
    if ~isempty(trackingPlt)
        for i = 1:size(trackingPlt,1)
            delete(trackingPlt{i});
        end
    end
    
    % if too many particles were found only show some
    if size(centers,1) > 5000
        pauseVideo(hObject,handles);
        msgbox('Too many particles found!');
        plt = [];
    else
        plt = plot( handles.oneAxes.Axes, centers(:,1), centers(:,2), '+r');
    end
    
    hold(handles.oneAxes.Axes,'off');
    setappdata(handles.f,'data_flow_plt',plt);
    setappdata(handles.f,'data_flow_trackingPlt',trackingPlt);
    
    
    delete(hWaitBar);
end

function switchMode(hObject, handles, value)
    setappdata(handles.f,'flow_mode',value);

    handles.rightPanel.Visible = 'on';
    handles.axesControl.currentFramePanel.Visible = 'on';
    handles.flow.autoPanel.Visible = 'on';
    handles.flow.manualDNAPanel.Visible = 'on';
    handles.flow.tracePanel.Visible = 'on';
    handles.flow.removeBgPanel.Visible = 'on';
    handles.flow.edgePanel.Visible = 'on';
    updateDisplay(hObject,handles);
    handles.oneAxes.AxesAPI.setMagnification(handles.oneAxes.AxesAPI.findFitMag()); % update magnification
    
    if handles.flow.sourceTimeAvgCheckBox.Value
        handles.axesControl.currentFramePanel.Visible =  'off';
    else
        handles.axesControl.currentFramePanel.Visible =  'on';
    end
end

function stack = getSourceStack(hObject,handles)
    stack = getappdata(handles.f,'data_video_stack');
end

function I = getCurrentImage(hObject,handles,brightnessflag)
    % get values
    currentFrame = getappdata(handles.f,'flow_currentFrame');
    timeAverage = handles.flow.sourceTimeAvgCheckBox.Value;
    lowBrightness  = get(handles.flow.brightness.JavaPeer,'LowValue')  / get(handles.flow.brightness.JavaPeer,'Maximum');
    highBrightness = get(handles.flow.brightness.JavaPeer,'HighValue') / get(handles.flow.brightness.JavaPeer,'Maximum');
    invertImage = handles.flow.invertCheckbox.Value;
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
    % remove background
    if ~strcmp(handles.flow.selectBackgroundVideoTextBox.String,'No background video selected')
        bgI = getappdata(handles.f,'data_flow_backgroundImage');
        I = imsubtract(I,bgI);
    end
    % brightness
    if ~exist('brightnessflag','var') % used for autobrightness
        I(combinedROIMask) = imadjust(I(combinedROIMask),[lowBrightness,highBrightness]);
    end
    % crop overlay
    I(~combinedROIMask) = 0;
end

%% Play/pause Current Frame
function setCurrentFrame(hObject, value)
    handles = guidata(hObject);
    set(handles.axesControl.currentFrame.JavaPeer,'Value',value);
    handles.axesControl.currentFrameTextbox.String = num2str(value);
    setappdata(handles.f,'flow_currentFrame', value);
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
    lowBrightness  = get(handles.flow.brightness.JavaPeer,'LowValue');
    highBrightness = get(handles.flow.brightness.JavaPeer,'HighValue');
    if lowBrightness==highBrightness
        if lowBrightness==0
            set(handles.flow.brightness.JavaPeer,'HighValue',highBrightness+1)
        else
            set(handles.flow.brightness.JavaPeer,'LowValue',lowBrightness-1)
        end
    end
    
    updateDisplay(hObject,handles);
end

function autoBrightness(hObject, handles)
    I = getCurrentImage(hObject,handles,1); % 1 is for no brightness flag
    
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
        
    autoImAdjust = stretchlim(I(combinedROIMask));
    
    autoImAdjust = round(autoImAdjust * get(handles.flow.brightness.JavaPeer,'Maximum'));
    
    set(handles.flow.brightness.JavaPeer,'LowValue',autoImAdjust(1));
    set(handles.flow.brightness.JavaPeer,'HighValue',autoImAdjust(2));

    updateDisplay(hObject,handles);
end

function setInvert(hObject, handles, value)
    handles.flow.invertCheckbox.Value = value;
    autoBrightness(hObject,handles); % this will also update the display
end

function changeTimeAverage(hObject, handles, value)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    handles.flow.sourceTimeAvgCheckBox.Value = value;
    
    % hide current frame slider if time average is on
    if handles.flow.sourceTimeAvgCheckBox.Value
        handles.axesControl.currentFramePanel.Visible =  'off';
    else
        handles.axesControl.currentFramePanel.Visible =  'on';
    end
    
    autoBrightness(hObject,handles); % this will also update the display
end

%% Auto Dectect
function autoDetect(hObject, handles)
    hWaitBar = waitbar(0,'Finding ...');
    
    
    
    close(hWaitBar);
end

%% Tracking
function updateTracking(hObject,handles)
    generateFlowStrechingProfiles(hObject,handles);
    
    profiles = getappdata(handles.f,'flowStrechingProfiles');
    
    % remove plot of detected particles
    plt = getappdata(handles.f,'data_flow_plt');
    if ~isempty(plt)
        delete(plt);
    end
    
    % remove old plot of tracks
    trackingPlt = getappdata(handles.f,'data_flow_trackingPlt');
    if ~isempty(trackingPlt)
        for i = 1:size(trackingPlt,1)
            delete(trackingPlt{i});
        end
    end
    
    % plot
    hWaitBar = waitbar(0,'Plotting tracks ...');
    handles.oneAxes.Axes.Parent.Visible = 'off';
    hold(handles.oneAxes.Axes,'on');
    trackingPlt = cell(size(profiles,1),1);
    for i = 1:size(profiles,1)
        waitbar(i/size(profiles,1));
        trackingPlt{i} = plot(handles.oneAxes.Axes,profiles.Positions{i}(:,1),profiles.Positions{i}(:,2),'--');
    end
    hold(handles.oneAxes.Axes,'off');
    handles.oneAxes.Axes.Parent.Visible = 'on';
    delete(hWaitBar);
    
    % save
    setappdata(handles.f,'data_flow_trackingPlt',trackingPlt);
end

%% Analysis
function openAnalyzeFlowStreching(hObject,handles,loadingSession)
    if ~exist('handles') || ~isstruct(handles)
        handles = guidata(hObject);
    end
    
    if strcmp(handles.vid.selectVideoTextBox.String, 'No video selected')
        msgbox('The video has not been imported. Go to video settings.');
        return;
    end
    
    onRelease(hObject,handles);
    
    if exist('loadingSession','var')
        analyzeFlowStrechingInterface('onDisplay',hObject,handles,loadingSession);
    else
        analyzeFlowStrechingInterface('onDisplay',hObject,handles);
    end
    handles.leftPanel.Selection = 10;
end
