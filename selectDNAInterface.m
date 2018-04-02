function varargout = selectDNAInterface(varargin)
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
    setappdata(handles.f,'dna_mode', 'Source');
    setappdata(handles.f,'dna_currentFrame', 1);
    setappdata(handles.f,'dna_dnaImlines', cell(0));
    setappdata(handles.f,'dna_manualMode', false);

    handles.dna = struct();
    handles.dna.leftPanel = uix.VBox( 'Parent', handles.leftPanel);
    
    %% back
    handles.dna.backButtonPanel = uix.Panel('Parent', handles.dna.leftPanel);
    handles.dna.backButton = uicontrol(     'Parent', handles.dna.backButtonPanel,...
                                          	'String', 'Back',...
                                          	'Callback', @(hObject,~) onRelease(hObject,guidata(hObject)));
                                        
    %% Source
    handles.dna.sourcePanel = uix.BoxPanel('Parent', handles.dna.leftPanel,...
                                           'Title','Source',...
                                           'Padding',5);
    handles.dna.sourceBox = uix.VBox('Parent', handles.dna.sourcePanel);
    
    % source popupmenu
    handles.dna.sourcePopUpMenuBox = uix.HBox('Parent', handles.dna.sourceBox);
    handles.dna.sourceText = uicontrol( 'Parent', handles.dna.sourcePopUpMenuBox,...
                                        'style', 'text',...
                                        'String', 'Source: ');
    handles.dna.sourcePopUpMenu = uicontrol('Parent', handles.dna.sourcePopUpMenuBox,...
                                            'style', 'popupmenu',...
                                          	'String', {'None','Current video','Import new video'},...
                                          	'Callback', @(hObject,~) selectSource(hObject,guidata(hObject)));
    handles.dna.sourcePopUpMenuBox.set('Width', [60, -1]);
    % import textbox
    handles.dna.importVideoTextbox = uicontrol( 'Parent', handles.dna.sourceBox,...
                                                    'style', 'edit',...
                                                    'String', 'No video selected',...
                                                    'Visible','off',...
                                                    'Callback', @(hObject,~) importVideoTextBoxCallback(hObject,hObject.String));
    % pre-processbox
    handles.dna.preProcBox = uix.VBox('Parent', handles.dna.sourceBox,...
                                      'Visible','off');
    
    % channel
    handles.dna.channelBox = uix.HBox('Parent', handles.dna.preProcBox,...
                                                    'Visible','off');
    uicontrol(  'Parent', handles.dna.channelBox,...
                'style', 'text',...
                'String', 'Channel');
    handles.dna.sourceChannelPopUpMenu = uicontrol( 'Parent', handles.dna.channelBox,...
                                                    'style', 'popupmenu',...
                                                    'String', {''},...
                                                    'Callback', @(hObject,~) selectSourceChannel(hObject,guidata(hObject)));
    % time average
    handles.dna.sourceTimeAvgCheckBox = uicontrol( 'Parent', handles.dna.preProcBox,...
                                                    'style', 'checkbox',...
                                                    'String', 'Time Average',...
                                                    'Callback', @(hObject,~) changeTimeAverage(hObject,guidata(hObject),hObject.Value));
    
    % brightness
    uicontrol( 'Parent', handles.dna.preProcBox,...
               'Style' , 'text', ...
               'String', 'Brightness');
    [~, handles.dna.brightness] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.dna.brightness.set('Parent', handles.dna.preProcBox);
    handles.dna.brightness.JavaPeer.set('Maximum', 1e6);
    handles.dna.brightness.JavaPeer.set('Minimum', 0);
    handles.dna.brightness.JavaPeer.set('LowValue', 0);
    handles.dna.brightness.JavaPeer.set('HighValue', 1e6);
    handles.dna.brightness.JavaPeer.set('MouseReleasedCallback', @(~,~) setBrightness(handles.dna.brightness));
    
    % auto brightness and invert box
    handles.dna.autoAndInvertHBox = uix.HBox('Parent', handles.dna.preProcBox);
    
    % invert
    handles.dna.invertCheckbox = uicontrol(     'Parent', handles.dna.autoAndInvertHBox,...
                                                'Style', 'checkbox',...
                                                'String', 'Invert',...
                                                'Callback', @(hObject,~) setInvert(hObject, guidata(hObject),hObject.Value));
    
    % auto brightness
    handles.dna.autoBrightnessButton = uicontrol('Parent', handles.dna.autoAndInvertHBox,...
                                                 'String', 'Auto Brightness',...
                                                 'Callback', @(hObject,~) autoBrightness(hObject, guidata(hObject)));
                                                
    handles.dna.preProcBox.set('Heights',[25 25 15 25 25]);
    handles.dna.sourceBox.set('Heights',[25 25 150]);
    
    %% Auto DNA Detection
    handles.dna.autoDNAPanel = uix.BoxPanel('Parent', handles.dna.leftPanel,...
                                           'Title','Auto DNA Detection',...
                                           'Padding',5,...
                                           'Visible','off');
    handles.dna.autoDNABox = uix.VBox('Parent', handles.dna.autoDNAPanel);
    
    % Binary threshold
    handles.dna.autoDnaBinaryThresholdBox = uix.HBox('Parent', handles.dna.autoDNABox);
    uicontrol(  'Parent', handles.dna.autoDnaBinaryThresholdBox,...
                'style', 'text',...
                'String', 'Binary Threshold');
    handles.dna.autoDnaBinaryThresholdTextBox = uicontrol(  'Parent', handles.dna.autoDnaBinaryThresholdBox,...
                                                            'Style','edit',...
                                                            'String', '0.5');
    % Binary threshold
    handles.dna.autoDnaMinLengthBox = uix.HBox('Parent', handles.dna.autoDNABox);
    uicontrol(  'Parent', handles.dna.autoDnaMinLengthBox,...
                'style', 'text',...
                'String', 'Min Length of DNA');
    handles.dna.autoDnaMinLengthTextBox = uicontrol(        'Parent', handles.dna.autoDnaMinLengthBox,...
                                                            'Style','edit',...
                                                            'String', '10');
    % Min eccentricity
    handles.dna.autoDnaMinEccentricityBox = uix.HBox('Parent', handles.dna.autoDNABox);
    uicontrol(  'Parent', handles.dna.autoDnaMinEccentricityBox,...
                'style', 'text',...
                'String', 'Min eccentricity');
    handles.dna.autoDnaMinEccentricityTextBox = uicontrol(  'Parent', handles.dna.autoDnaMinEccentricityBox,...
                                                            'Style','edit',...
                                                            'String', '0.75');
    % Auto button
    handles.dna.autoDnaDetectionButton = uicontrol(  'Parent', handles.dna.autoDNABox,...
                                                     'String', 'Auto Detect DNA',...
                                                     'Callback', @(hObject,~) autoDetectDNA(hObject, guidata(hObject)));
                                                 
    %% Manual DNA Detection
    handles.dna.manualDNAPanel = uix.BoxPanel(  'Parent', handles.dna.leftPanel,...
                                                'Title','Manual DNA Detection',...
                                                'Padding',5,...
                                                'Visible','off');
    handles.dna.manualDNABox = uix.VButtonBox('Parent', handles.dna.manualDNAPanel,...
                                                'ButtonSize',[120 30],...
                                                'Spacing',2);
    % Delete note
    handles.dna.manualDNADeleteText = uicontrol('Parent', handles.dna.manualDNABox,...
                                                'Style','text',...
                                                'String', 'Delete any DNA by right clicking the line and selecting "Delete"');
    % Add
    handles.dna.manualDNAAddButton = uicontrol( 'Parent', handles.dna.manualDNABox,...
                                                'String', 'Manually Add DNA',...
                                                'Callback', @(hObject,~) activateManualMode(hObject, guidata(hObject)));
    % Clear
    handles.dna.manualDNAClearButton = uicontrol(   'Parent', handles.dna.manualDNABox,...
                                                    'String', 'Clear All DNA',...
                                                    'Callback', @(hObject,~) removeAllDNA(hObject, guidata(hObject)));
                                                
                                                
    %% Kymographs
    handles.dna.kymPanel = uix.BoxPanel(  'Parent', handles.dna.leftPanel,...
                                          'Title','Kymographs',...
                                          'Padding',5,...
                                          'Visible','off');
    handles.dna.kymBox = uix.VButtonBox('Parent', handles.dna.kymPanel,...
                                                'ButtonSize',[120 30],...
                                                'Spacing',2);
    % kym button
    handles.dna.kymButton = uicontrol( 'Parent', handles.dna.kymBox,...
                                                'String', 'Generate Kymographs',...
                                                'Callback', @(hObject,~) openKymographs(hObject, guidata(hObject)));
                                                 
    %% 
    handles.dna.leftPanel.set('Heights',[25 200 125 100 50]);
end

%% Load from session
function handles = loadFromSession(hObject,handles,session)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    % deactivate manule mode if its on
    deactivateManualMode(hObject, handles);
    
    % source
    handles.dna.sourcePopUpMenu.Value = session.dna_source;
    
    % channel
    if isappdata(handles.f,'data_video_originalSeperatedStacks')
        numChannels = size(getappdata(handles.f,'data_video_originalSeperatedStacks'),1);
        str = cell(numChannels,1);
        for i=1:numChannels
            str{i} = num2str(i);
        end
        handles.dna.sourceChannelPopUpMenu.String = str;
        handles.dna.channelBox.Visible = 'on';
    else
        handles.dna.sourceChannelPopUpMenu.String = {''};
        handles.dna.channelBox.Visible = 'off';
    end
    handles.dna.sourceChannelPopUpMenu.Value = session.dna_channel;
    
    % time average
    handles.dna.sourceTimeAvgCheckBox.Value = session.dna_timeAvg;
    
    % get the stack
    switch handles.dna.sourcePopUpMenu.Value
        case 2 % Current 
            
        case 3 % Import
            handles = setVideoFile(hObject, handles, session.dna_videoFilePath);
            mappingInterface('collocalizeDNAImport',hObject,handles);
    end
    stack = getSourceStack(hObject,handles);
    
    % frame controls
    % set max before values
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    
    % frame
    handles.axesControl.currentFrameTextbox.String = num2str(session.dna_currentFrame);
    set(handles.axesControl.currentFrame.JavaPeer, 'Value', session.dna_currentFrame);
    setappdata(handles.f,'dna_currentFrame',session.dna_currentFrame)
    
    % brightness controls
    set(handles.dna.brightness.JavaPeer, 'LowValue', session.dna_lowBrightness);
    set(handles.dna.brightness.JavaPeer, 'HighValue', session.dna_highBrightness);
    handles.dna.invertCheckbox.Value = session.dna_invertImage;
    
    % auto dna settings
    handles.dna.autoDnaBinaryThresholdTextBox.String   = session.dna_autoDnaBinaryThreshold;
    handles.dna.autoDnaMinLengthTextBox.String         = session.dna_autoDnaMinLength;
    handles.dna.autoDnaMinEccentricityTextBox.String   = session.dna_autoDnaMinEccentricity;
        
    switchMode(hObject, handles, session.dna_mode);
end

%% Source
function selectSource(hObject,handles)
    switch handles.dna.sourcePopUpMenu.Value
        case 1 % None
            switchMode(hObject, handles, 'Select Source');
        case 2 % Current vid
            if ~strcmp(handles.vid.selectVideoTextBox.String, 'No video selected')
                setControlsForNewVideo(hObject, handles);
                switchMode(hObject, handles, 'Edit Current');
            else
                msgbox('The video has not been imported. Go to video settings.');
            end
        case 3 % Import
            handles.dna.importVideoTextbox.Visible = 'on';
            
            [fileName, fileDir, ~] = uigetfile({'*.tif';'*.tiff';'*.TIF';'*.TIFF'}, 'Select the video file'); % prompt user for file
            if fileName ~= 0 % if user does not presses cancel
                importVideoTextBoxCallback(hObject, [fileDir fileName]);
            else
                handles.dna.sourcePopUpMenu.Value = 1;
            end
    end
end

function selectSourceChannel(hObject,handles)
    autoBrightness(hObject,handles); % this will also update the display
    updateDisplay(hObject,handles);
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
    if isappdata(handles.f,'data_mapping_originalSeperatedStacks')
        numChannels = size(getappdata(handles.f,'data_mapping_originalSeperatedStacks'),1);
        str = cell(numChannels,1);
        for i=1:numChannels
            str{i} = num2str(i);
        end
        handles.dna.sourceChannelPopUpMenu.String = str;
        handles.dna.channelBox.Visible = 'on';
        
        mappingInterface('collocalizeDNAImport',hObject,handles);
    else
        handles.dna.sourceChannelPopUpMenu.String = {''};
        handles.dna.channelBox.Visible = 'off';
    end
    
    % requires a video to have been saved
    stack = getSourceStack(hObject,handles);
    
    % frame controls
    % set max before values
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    
    % frame
    set(handles.axesControl.currentFrame.JavaPeer,'Value',1);
    setappdata(handles.f,'dna_currentFrame',1)
    handles.axesControl.currentFrameTextbox.String = '1';
    
    % brightness controls
    autoImAdjust = stretchlim(stack(:,:,1)); % get the auto brightness values    
    autoImAdjust = round(autoImAdjust * get(handles.dna.brightness.JavaPeer,'Maximum'));
    set(handles.dna.brightness.JavaPeer,'LowValue',autoImAdjust(1));
    set(handles.dna.brightness.JavaPeer,'HighValue',autoImAdjust(2));
    
    % invet
    handles.dna.invertCheckbox.Value   = 0;
end
    
function handles = setVideoFile(hObject, handles, filePath)
    hWaitBar = waitbar(0,'Loading in video...', 'WindowStyle', 'modal');
    [stack, maxIntensity] = getStackFromFile(filePath, hWaitBar);
    if stack == 0 % an error was encountored
        filePath = 'No video selected';
    end
    
    % save
    handles.dna.importVideoTextbox.String = filePath;
    setappdata(handles.f,'data_dnaImport_originalStack',stack);
    setappdata(handles.f,'dnaImport_maxIntensity',maxIntensity);
    
    close(hWaitBar);
end

%% Display
function onDisplay(hObject,handles)
    % current frame
    stack = getSourceStack(hObject,handles);
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    set(handles.axesControl.currentFrame.JavaPeer,'Value', getappdata(handles.f,'dna_currentFrame'));
    set(handles.axesControl.currentFrameTextbox,'String', num2str(getappdata(handles.f,'dna_currentFrame')));
    handles.axesControl.currentFrame.JavaPeer.set('MouseReleasedCallback', @(~,~) setCurrentFrame(handles.axesControl.currentFrame, get(handles.axesControl.currentFrame.JavaPeer,'Value')));
    handles.axesControl.currentFrameTextbox.set('Callback', @(hObject,~) setCurrentFrame( hObject, str2num(hObject.String)));
    handles.axesControl.playButton.set('Callback', @(hObject,~) playVideo( hObject, guidata(hObject)));
    
    % overlap mode
    handles.axesControl.seperateButtonGroup.Visible =  'off';
    handles.axesPanel.Selection = 1; % overlap channels mode for one axes
    
    switchMode(hObject, handles, getappdata(handles.f,'dna_mode'));
end

function onRelease(hObject,handles)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    deactivateManualMode(hObject, handles);
    
    % save dna lines
    saveImlinesToKyms(hObject,handles);
    removeAllDNA(hObject,handles);
    
    % current frame
    setappdata(handles.f,'dna_currentFrame', get(handles.axesControl.currentFrame.JavaPeer,'Value'));
    
    homeInterface('openHome',hObject);
end

function updateDisplay(hObject,handles) 
    if ~exist('handles','var')
        handles = guidata(hObject);
    end
    
    I = getCurrentImage(hObject,handles);
    
    % display
    handles.oneAxes.AxesAPI.replaceImage(I,'PreserveView',true);
            
end

function switchMode(hObject, handles, value)
    setappdata(handles.f,'dna_mode',value);

    handles.rightPanel.Visible = 'off';
    handles.axesControl.seperateButtonGroup.Visible = 'off';
    handles.dna.preProcBox.Visible = 'off';
    handles.dna.importVideoTextbox.Visible = 'off';
    handles.dna.autoDNAPanel.Visible = 'off';
    handles.dna.manualDNAPanel.Visible = 'off';
    handles.dna.kymPanel.Visible = 'off';
    handles.dna.manualDNAClearButton.Enable = 'on';
    handles.dna.sourcePanel.Visible = 'off';
    handles.dna.backButtonPanel.Visible = 'off';
    
    switch value
        case 'Select Source'
            handles.dna.sourcePanel.Visible = 'on';
            handles.dna.backButtonPanel.Visible = 'on';
            
        case 'Edit Current'
            handles.dna.backButtonPanel.Visible = 'on';
            handles.dna.sourcePanel.Visible = 'on';
            handles.rightPanel.Visible = 'on';
            handles.dna.preProcBox.Visible = 'on';
            handles.axesControl.currentFramePanel.Visible = 'on';
            handles.dna.autoDNAPanel.Visible = 'on';
            handles.dna.manualDNAPanel.Visible = 'on';
            handles.dna.kymPanel.Visible = 'on';
            if ~getappdata(handles.f,'dna_manualMode')
                updateDisplay(hObject,handles);
                resetDNAGraphics(hObject,handles);
                handles.oneAxes.AxesAPI.setMagnification(handles.oneAxes.AxesAPI.findFitMag()); % update magnification
            end
        case 'Edit Import'
            handles.dna.backButtonPanel.Visible = 'on';
            handles.dna.sourcePanel.Visible = 'on';
            handles.rightPanel.Visible = 'on';
            handles.dna.preProcBox.Visible = 'on';
            handles.dna.importVideoTextbox.Visible = 'on';
            handles.dna.autoDNAPanel.Visible = 'on';
            handles.dna.manualDNAPanel.Visible = 'on';
            handles.dna.kymPanel.Visible = 'on';
            if ~getappdata(handles.f,'dna_manualMode')
                updateDisplay(hObject,handles);
                resetDNAGraphics(hObject,handles);
                handles.oneAxes.AxesAPI.setMagnification(handles.oneAxes.AxesAPI.findFitMag()); % update magnification
            end
        case 'Manual Mode'
            handles.rightPanel.Visible = 'on';
            handles.dna.manualDNAPanel.Visible = 'on';
            handles.dna.manualDNAClearButton.Enable = 'off';
    end
    
    if handles.dna.sourceTimeAvgCheckBox.Value
        handles.axesControl.currentFramePanel.Visible =  'off';
    else
        handles.axesControl.currentFramePanel.Visible =  'on';
    end
end

function stack = getSourceStack(hObject,handles)
    if handles.dna.sourcePopUpMenu.Value == 1
        stack = 1;
        return;
    end
    
    if isempty(handles.dna.sourceChannelPopUpMenu.String{1})
        switch handles.dna.sourcePopUpMenu.Value
            case 2 % Current vid
                stack = getappdata(handles.f,'data_video_originalStack');

            case 3 % Import
                stack = getappdata(handles.f,'data_dnaImport_originalStack');
        end
    else
        switch handles.dna.sourcePopUpMenu.Value
            case 2 % Current vid
                stacks = getappdata(handles.f,'data_video_seperatedStacks');

            case 3 % Import
                stacks = getappdata(handles.f,'data_dnaImport_seperatedStacks');
        end
        stack = stacks{handles.dna.sourceChannelPopUpMenu.Value};
    end
end

function I = getCurrentImage(hObject,handles,brightnessflag)
    % get values
    currentFrame = getappdata(handles.f,'dna_currentFrame');
    timeAverage = handles.dna.sourceTimeAvgCheckBox.Value;
    lowBrightness = get(handles.dna.brightness.JavaPeer,'LowValue')/get(handles.dna.brightness.JavaPeer,'Maximum');
    highBrightness = get(handles.dna.brightness.JavaPeer,'HighValue')/get(handles.dna.brightness.JavaPeer,'Maximum');
    invertImage = handles.dna.invertCheckbox.Value;
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
    stack = getSourceStack(hObject,handles);
    
    % current frame/timeAverage
    if timeAverage
        I = cast(mean(stack,3), class(stack));
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

function saveImlinesToKyms(hObject,handles)
    % Find the position of each DNA imline and save the position rather
    % then the whole graphics object.
    kyms = getappdata(handles.f,'kyms');
    dnaImlines = getappdata(handles.f,'dna_dnaImlines');
    removeInd = (1:size(kyms,1))';
    for i=1:size(dnaImlines,2)
        row = get(dnaImlines{i},'UserData');
        kyms.Position(row,1:4) = reshape(getPosition(dnaImlines{i})',1,[]);
        removeInd(removeInd==row) = [];
    end
    
    % remove all kyms that with no corresponding Imline
    kyms(removeInd,:) = [];
    
    setappdata(handles.f,'kyms',kyms);
end

%% Play/pause
function playVideo(hObject,handles)
    % switch play button to pause button
    handles.axesControl.playButton.String = 'Pause';
    handles.axesControl.playButton.Callback = @(hObject,~) pauseVideo(hObject,guidata(hObject));
    
    % play loop
    setappdata(handles.f,'Playing_Video',1);
    currentFrame = handles.axesControl.currentFrame.JavaPeer.get('Value');
    while getappdata(handles.f,'Playing_Video')
        if currentFrame < handles.axesControl.currentFrame.JavaPeer.get('Maximum')
            currentFrame = currentFrame+1;
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

%% Brightness Callbacks
function setBrightness(hObject)
    handles = guidata(hObject);
    lowBrightness = get(handles.dna.brightness.JavaPeer,'LowValue');
    highBrightness = get(handles.dna.brightness.JavaPeer,'HighValue');
    if lowBrightness==highBrightness
        if lowBrightness==0
            set(handles.dna.brightness.JavaPeer,'HighValue',highBrightness+1)
        else
            set(handles.dna.brightness.JavaPeer,'LowValue',lowBrightness-1)
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
    
    autoImAdjust = round(autoImAdjust * get(handles.dna.brightness.JavaPeer,'Maximum'));
    
    set(handles.dna.brightness.JavaPeer,'LowValue',autoImAdjust(1));
    set(handles.dna.brightness.JavaPeer,'HighValue',autoImAdjust(2));

    updateDisplay(hObject,handles);
end

function setInvert(hObject, handles, value)
    handles.dna.invertCheckbox.Value = value;
    autoBrightness(hObject,handles); % this will also update the display
end

%% Time average
function changeTimeAverage(hObject, handles, value)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    handles.dna.sourceTimeAvgCheckBox.Value = value;
    
    % hide current frame slider if time average is on
    if handles.dna.sourceTimeAvgCheckBox.Value
        handles.axesControl.currentFramePanel.Visible =  'off';
    else
        handles.axesControl.currentFramePanel.Visible =  'on';
    end
    
    autoBrightness(hObject,handles); % this will also update the display
end

%% Current Frame
function setCurrentFrame(hObject, value)
    handles = guidata(hObject);
    set(handles.axesControl.currentFrame.JavaPeer,'Value',value);
    handles.axesControl.currentFrameTextbox.String = num2str(value);
    setappdata(handles.f,'dna_currentFrame', value);
    updateDisplay(hObject,handles);
end

%% Auto Dectect DNA
function autoDetectDNA(hObject, handles)
    hWaitBar = waitbar(0,'Finding DNA ...');
    
    binaryThreshold = str2num(handles.dna.autoDnaBinaryThresholdTextBox.String);
    minLength = str2num(handles.dna.autoDnaMinLengthTextBox.String);
    minEccentricity = str2num(handles.dna.autoDnaMinEccentricityTextBox.String);

    I = getCurrentImage(hObject, handles);
    
    binaryI = imbinarize(I,'adaptive','ForegroundPolarity','bright','Sensitivity',binaryThreshold);
    stats = regionprops(binaryI,'Eccentricity','PixelList','MajorAxisLength');
    componets = bwconncomp(binaryI);
    labledI = labelmatrix(componets);
    validIds = find([stats.Eccentricity] > minEccentricity & [stats.MajorAxisLength] > minLength); 
    
    
    removeAllDNA(hObject,handles); % remove the old DNAs
    dnaLines = zeros(length(validIds),4); % pre-aloc
    for i=1:length(validIds)
        % get all pixles of each valid serpated object
        cords = stats(validIds(i)).PixelList;
        
        % use a linear fit to find where dna line should be
        p = polyfit(cords(:,1),cords(:,2),1);
        x1 = min(cords(:,1));
        x2 = max(cords(:,1));
        y1 = polyval(p, x1);
        y2 = polyval(p, x2);
        
        % create new dan at pos found
        addNewDNA(hObject, handles, [x1 y1; x2 y2])
        
        % update loading bar
        waitbar(i/length(validIds));
    end 
    
    close(hWaitBar);
end

%% DNA
function activateManualMode(hObject, handles)
    % switch on manual controls
    handles.dna.manualDNAAddButton.Callback = @(hObject,~) deactivateManualMode(hObject, guidata(hObject));
    handles.dna.manualDNAAddButton.BackgroundColor = [0.54 0.94 0.54];
    setappdata(handles.f,'dna_manualMode',true);
    
    % disable delete controls
    setappdata(handles.f,'dna_prevMode', getappdata(handles.f,'dna_mode'));
    switchMode(hObject, handles, 'Manual Mode');
    
    % create a new DNA everytime one is finished
    while getappdata(handles.f,'dna_manualMode')
        addNewDNA(hObject, handles);
    end
end

function deactivateManualMode(hObject, handles)
    if getappdata(handles.f,'dna_manualMode')
        % disable delete controls
        switchMode(hObject, handles, getappdata(handles.f,'dna_prevMode')); % must happen first
        
        % remove the unstarted imline
        delete(handles.oneAxes.Axes.Children(1));
        
        % switch off manual controls
        handles.dna.manualDNAAddButton.Callback = @(hObject,~) activateManualMode(hObject, guidata(hObject));
        handles.dna.manualDNAAddButton.BackgroundColor = [0.94 0.94 0.94];
        setappdata(handles.f,'dna_manualMode',false);
    end
end

function addNewDNA(hObject, handles, initPos)
    dnaImlines = getappdata(handles.f,'dna_dnaImlines');
    
    row = size(dnaImlines,2) + 1;
    if exist('initPos')
        h = imline(handles.oneAxes.Axes, initPos); % line drawn from initPos
    else 
        h = imline(handles.oneAxes.Axes); % user draws line
    end
    
    if isempty(isvalid(h))
        return;
    end
    
    dnaImlines{row} = h;
    
    api = iptgetapi(dnaImlines{row});
    api.setColor('red');
    api.set('UserData',row);
    
    ch = api.get('Children');
    cm = get(ch(1),'UIContextMenu');
    delete(cm.Children(1:3)); % remove the defualt menu
    uimenu(cm, 'Label', 'Remove', 'Callback', @(~,~)deleteDNA(api)); 
    
    % callbacks
    api.set('Deletefcn',@deleteDNA); % delete callback
    
    % save line handle in cell array
    setappdata(handles.f,'dna_dnaImlines',dnaImlines);
end

function deleteDNA(hObject, ~)
    handles = guidata(hObject.get('Parent'));
    
    if getappdata(handles.f,'dna_manualMode')
        msgbox('You can not delete in manual mode');
        return;
    end
        
    dnaImlines = getappdata(handles.f,'dna_dnaImlines');

    row = get(hObject,'UserData');
    dnaImlines(row) = []; 
    
    % The dnaImlines UserData must now be updated as the rows for  
    % have shifted after the deletion
    for i=row:length(dnaImlines)
        set(dnaImlines{i},'UserData',i);
    end
    
    % save cell array of handles
    setappdata(handles.f,'dna_dnaImlines',dnaImlines);
    
    % remove the graphic object
    hObject.set('Deletefcn',[]);
    delete(hObject);
end

function resetDNAGraphics(hObject,handles)
    % delete the old ones first
    removeAllDNA(hObject,handles);
    
    kyms = getappdata(handles.f,'kyms');
    linePos = kyms.Position;
    
    % add a dna for each row in linePos
    for i = 1:size(linePos,1)
        addNewDNA(hObject, handles, reshape(linePos(i,:),2,[])');
    end
end

function removeAllDNA(hObject,handles)
    dnaImlines = getappdata(handles.f,'dna_dnaImlines');
    % delete each imline graphic object
    for i=1:length(dnaImlines)
        delete(dnaImlines{i});
    end
    
    setappdata(handles.f,'dna_dnaImlines',cell(0));
end

%% Kymographs
function openKymographs(hObject,handles,loadSessionFlag)
    if ~exist('handles','var')
        handles = guidata(hObject);
    end
    
    if strcmp(handles.vid.selectVideoTextBox.String, 'No video selected')
        msgbox('The video has not been imported. Go to video settings.');
        return;
    end
    
    if ~exist('loadSessionFlag','var')
        % onRelase overwrites the appdata kyms so it must be
        % suppressed when loading from session
        saveSession(handles.f, 1); % auto save
        onRelease(hObject,handles); 
    end
    
    kymographInterface('onDisplay',hObject,handles);
    handles.leftPanel.Selection = 5;
end

