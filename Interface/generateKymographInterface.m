function varargout = generateKymographInterface(varargin)
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
    setappdata(handles.f,'dna_mode', 'Select Source');
    setappdata(handles.f,'dna_currentFrame', 1);
    setappdata(handles.f,'dna_dnaImlines', cell(0));
    setappdata(handles.f,'dna_manualMode', false);
    setappdata(handles.f,'data_dna_plt',[]);

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
    handles.dna.brightness.JavaPeer.set('StateChangedCallback', @(~,~) setBrightness(handles.dna.brightness));
    
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
                                       
    handles.dna.autoDNAVBox = uix.VBox('Parent', handles.dna.autoDNAPanel);
    
    handles.dna.autoDNAAlgorthimDropdown = uicontrol(   'Parent', handles.dna.autoDNAVBox,...
                                                        'style', 'popupmenu',...
                                                        'String', {'Staining/Timelaps','Particle Tracking'},...
                                                        'Callback', @(hObject,~) changeDNADetectionAlgorthim(hObject,guidata(hObject)));
                                       
    handles.dna.autoDNACardPanel = uix.CardPanel('Parent', handles.dna.autoDNAVBox);
    
    handles.dna.autoDNAOverlapButton = uicontrol(  'Parent', handles.dna.autoDNAVBox,...
                                                   'String', 'Remove Overlaped DNA',...
                                                   'Callback', @(hObject,~) removeOverlapedDNA(hObject, guidata(hObject)));
    
    handles.dna.autoDNAStainBox = uix.VBox('Parent', handles.dna.autoDNACardPanel);
    handles.dna.autoDNATrackingBox = uix.VBox('Parent', handles.dna.autoDNACardPanel);
        
    handles.dna.autoDNACardPanel.Selection = 1;
    handles.dna.autoDNAVBox.set('Heights',[25, 260, 25]);
    
    %% DNA Width
    % text
    uicontrol(  'Parent', handles.dna.autoDNAStainBox,...
                'style', 'text',...
                'String', 'DNA Width');
    % hbox
    handles.dna.dnaWidthBox = uix.HBox('Parent', handles.dna.autoDNAStainBox);
    % slider
    [~, handles.dna.dnaWidthSlider] = javacomponent('javax.swing.JSlider');
    handles.dna.dnaWidthSlider.set('Parent', handles.dna.dnaWidthBox);
    handles.dna.dnaWidthSlider.JavaPeer.set('Maximum', 10);
    handles.dna.dnaWidthSlider.JavaPeer.set('Minimum', 1);
    handles.dna.dnaWidthSlider.JavaPeer.set('Value', 2);
    handles.dna.dnaWidthSlider.JavaPeer.set('StateChangedCallback',...
                                            @(~,~) setDNAWidth(handles.dna.dnaWidthSlider,...
                                            get(handles.dna.dnaWidthSlider.JavaPeer,'Value')));
    % texbox
    handles.dna.dnaWidthTextbox = uicontrol('Parent', handles.dna.dnaWidthBox,...
                                            'Style','edit',...
                                            'String', '2',...
                                            'Callback', @(hObject,~) setDNAWidth(hObject, str2double(hObject.String)));
    % widths
    handles.dna.dnaWidthBox.set('Widths',[-1 50]);
                                                        
    %% DNA Length
    % text
    uicontrol(  'Parent', handles.dna.autoDNAStainBox,...
                'style', 'text',...
                'String', 'DNA Length');
    % hbox
    handles.dna.dnaLengthBox = uix.HBox('Parent', handles.dna.autoDNAStainBox);
    % slider
    [~, handles.dna.dnaLengthSlider] = javacomponent('javax.swing.JSlider');
    handles.dna.dnaLengthSlider.set('Parent', handles.dna.dnaLengthBox);
    handles.dna.dnaLengthSlider.JavaPeer.set('Maximum', 100);
    handles.dna.dnaLengthSlider.JavaPeer.set('Minimum', 1);
    handles.dna.dnaLengthSlider.JavaPeer.set('Value', 10);
    handles.dna.dnaLengthSlider.JavaPeer.set('StateChangedCallback',...
                                            @(~,~) setDNALength(handles.dna.dnaLengthSlider,...
                                            get(handles.dna.dnaLengthSlider.JavaPeer,'Value')));
    % texbox
    handles.dna.dnaLengthTextbox = uicontrol('Parent', handles.dna.dnaLengthBox,...
                                            'Style','edit',...
                                            'String', '10',...
                                            'Callback', @(hObject,~) setDNALength(hObject, str2double(hObject.String)));
    % widths
    handles.dna.dnaLengthBox.set('Widths',[-1 50]);
    
    %% DNA Matching Strength
    % text
    uicontrol(  'Parent', handles.dna.autoDNAStainBox,...
                'style', 'text',...
                'String', 'DNA Matching Strength');
    % hbox
    handles.dna.dnaMatchingStrengthBox = uix.HBox('Parent', handles.dna.autoDNAStainBox);
    % slider
    [~, handles.dna.dnaMatchingStrengthSlider] = javacomponent('javax.swing.JSlider');
    handles.dna.dnaMatchingStrengthSlider.set('Parent', handles.dna.dnaMatchingStrengthBox);
    handles.dna.dnaMatchingStrengthSlider.JavaPeer.set('Maximum', 100);
    handles.dna.dnaMatchingStrengthSlider.JavaPeer.set('Minimum', 1);
    handles.dna.dnaMatchingStrengthSlider.JavaPeer.set('Value', 10);
    handles.dna.dnaMatchingStrengthSlider.JavaPeer.set('StateChangedCallback',...
                                            @(~,~) setDNAMatchingStrength(handles.dna.dnaMatchingStrengthSlider,...
                                            get(handles.dna.dnaMatchingStrengthSlider.JavaPeer,'Value')));
    % textbox
    handles.dna.dnaMatchingStrengthTextbox = uicontrol('Parent', handles.dna.dnaMatchingStrengthBox,...
                                            'Style','edit',...
                                            'String', '10',...
                                            'Callback', @(hObject,~) setDNAMatchingStrength(hObject, str2double(hObject.String)));
    % widths
    handles.dna.dnaMatchingStrengthBox.set('Widths',[-1 50]);

    %% Auto button
    uix.Empty('Parent', handles.dna.autoDNAStainBox);
    handles.dna.autoDnaDetectionButton = uicontrol(  'Parent', handles.dna.autoDNAStainBox,...
                                                     'String', 'Auto Detect DNA',...
                                                     'Callback', @(hObject,~) autoDetectDNA(hObject, guidata(hObject)));
                                                 
    %% DNA kernal preview
    handles.dna.dnaKernalBox    = uix.HButtonBox('Parent', handles.dna.autoDNAStainBox, 'ButtonSize',[250 100]);    
    handles.dna.dnaKernalPanel  = uipanel('Parent', handles.dna.dnaKernalBox,...
                                          'BorderType', 'none');
    handles.dna.dnaKernalAxes   = axes(handles.dna.dnaKernalPanel);
    
    hImage = imshow(rand(1000),'Parent',handles.dna.dnaKernalAxes);
    
    handles.dna.dnaKernalAxesScrollPanel = imscrollpanel(handles.dna.dnaKernalPanel,hImage);
    handles.dna.dnaKernalAxesAPI = iptgetapi(handles.dna.dnaKernalAxesScrollPanel);
    handles.dna.dnaKernalAxesAPI.setMagnification(1001);
    handles.dna.dnaKernalAxesScrollPanel.BackgroundColor = [0 0 0];
                                                 
    % Heights             
    handles.dna.autoDNAStainBox.set('Heights',[15 20 15 20 15 20 10 25 120]);
    
    %% Auto Tracking
    
    % filter
    uicontrol( 'Parent', handles.dna.autoDNATrackingBox,...
               'Style' , 'text', ...
               'String', 'Gaussina Filter Size');
    [~, handles.dna.particleFilter] = javacomponent('javax.swing.JSlider');
    handles.dna.particleFilter.set('Parent', handles.dna.autoDNATrackingBox);
    handles.dna.particleFilter.JavaPeer.set('Maximum', 5e5);
    handles.dna.particleFilter.JavaPeer.set('Minimum', 0);
    handles.dna.particleFilter.JavaPeer.set('Value', 0);
    handles.dna.particleFilter.JavaPeer.set('MouseReleasedCallback', @(~,~) updateDisplay(handles.dna.particleFilter));
    % add filter lables
    parFilLabels = java.util.Hashtable();
    parFilLabels.put( int32( 0 ),   javax.swing.JLabel('0') );
    parFilLabels.put( int32( 1e5 ), javax.swing.JLabel('1') );
    parFilLabels.put( int32( 2e5 ), javax.swing.JLabel('2') );
    parFilLabels.put( int32( 3e5 ), javax.swing.JLabel('3') );
    parFilLabels.put( int32( 4e5 ), javax.swing.JLabel('4') );
    parFilLabels.put( int32( 5e5 ), javax.swing.JLabel('5') );
    handles.dna.particleFilter.JavaPeer.setLabelTable( parFilLabels );
    handles.dna.particleFilter.JavaPeer.setPaintLabels(true);
    
    % intensity
    uicontrol( 'Parent', handles.dna.autoDNATrackingBox,...
               'Style' , 'text', ...
               'String', 'Selected Intensities');
    [~, handles.dna.particleIntensity] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.dna.particleIntensity.set('Parent', handles.dna.autoDNATrackingBox);
    handles.dna.particleIntensity.JavaPeer.set('Maximum', 1e6);
    handles.dna.particleIntensity.JavaPeer.set('Minimum', 0);
    handles.dna.particleIntensity.JavaPeer.set('LowValue', 9e5);
    handles.dna.particleIntensity.JavaPeer.set('HighValue', 1e6);
    handles.dna.particleIntensity.JavaPeer.set('MouseReleasedCallback', @(~,~) updateDisplay(handles.dna.particleIntensity));
            
    % max tracking distance
    handles.dna.trackingDistanceBox = uix.HBox( 'Parent', handles.dna.autoDNATrackingBox);
    uicontrol(  'Parent', handles.dna.trackingDistanceBox,...
                'String', 'Maximum Track Distance',...
                'Style', 'text');
    handles.dna.trackingDistance = uicontrol(  'Parent', handles.dna.trackingDistanceBox,...
                                                'String', '2',...
                                                'Style', 'edit');
    
    % button
    uix.Empty('Parent', handles.dna.autoDNATrackingBox);
    handles.dna.autoDnaDetectionTrackingButton = uicontrol(  'Parent', handles.dna.autoDNATrackingBox,...
                                                     'String', 'Auto Detect DNA',...
                                                     'Callback', @(hObject,~) autoDetectDNA(hObject, guidata(hObject)));
                                                 
    % Heights             
    handles.dna.autoDNATrackingBox.set('Heights',[15 35 15 20 25 25 25]);
                                                 
    %% Manual DNA Detection
    handles.dna.manualDNAPanel = uix.BoxPanel(  'Parent', handles.dna.leftPanel,...
                                                'Title','Manual DNA Detection',...
                                                'Padding',5,...
                                                'Visible','off');
    % vertical box
    handles.dna.manualDNABox = uix.VBox('Parent', handles.dna.manualDNAPanel);

    % Delete note
    handles.dna.manualDNADeleteText = uicontrol('Parent', handles.dna.manualDNABox,...
                                                'Style','text',...
                                                'String', 'Delete any DNA by right clicking the line and selecting ''Delete''');
    % button box
    handles.dna.manualDNAButtonBox = uix.HBox('Parent', handles.dna.manualDNABox);
    % Clear
    handles.dna.manualDNAClearButton = uicontrol(   'Parent', handles.dna.manualDNAButtonBox,...
                                                    'String', 'Clear All DNA',...
                                                    'Callback', @(hObject,~) removeAllDNA_Callback(hObject, guidata(hObject)));
    % Add
    handles.dna.manualDNAAddButton = uicontrol( 'Parent', handles.dna.manualDNAButtonBox,...
                                                'String', 'Manually Add DNA Mode',...
                                                'Callback', @(hObject,~) activateManualMode(hObject, guidata(hObject)));
    % widths
    handles.dna.manualDNAButtonBox.set('Widths',[-1 -2]);
                                                
    %% Kymographs
    handles.dna.kymPanel = uix.BoxPanel(    'Parent', handles.dna.leftPanel,...
                                            'Title','Kymographs',...
                                            'Padding',5,...
                                            'Visible','off');
    handles.dna.kymBox = uix.VButtonBox(    'Parent', handles.dna.kymPanel,...
                                            'ButtonSize',[120 30],...
                                            'Spacing',2);
    % kym button
    handles.dna.kymButton = uicontrol(  'Parent', handles.dna.kymBox,...
                                      	'String', 'Generate Kymographs',...
                                       	'Callback', @(hObject,~) openKymographs(hObject, guidata(hObject)));
                                                 
    %% 
    handles.dna.leftPanel.set('Heights',[25 200 340 80 60]);
end

%% Load from session
function handles = loadFromSession(hObject,handles,session)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    % deactivate manual mode if its on
    deactivateManualMode(hObject, handles);
    
    % source
    handles.dna.sourcePopUpMenu.Value = session.dna_source;
    
    % channel
    if isappdata(handles.f,'data_video_originalSeperatedStacks')
        numChannels = size(getappdata(handles.f,'data_video_originalSeperatedStacks'),1);
        names = getappdata(handles.f,'ROINames');
        handles.dna.sourceChannelPopUpMenu.String = names(1:numChannels);
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
    setDNAWidth(hObject, session.dna_dnaWidth);
    setDNALength(hObject, session.dna_dnaLength);
    setDNAMatchingStrength(hObject, session.dna_dnaMatchingStrength);

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
            
            [fileName, fileDir, ~] = uigetfile([getappdata(handles.f,'savePath') '*.tif;*.tiff;*.TIF;*.TIFF'], 'Select the video file'); % prompt user for file
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
    if getappdata(handles.f,'isMapped')
        numChannels = size(getappdata(handles.f,'ROI'),1);
        names = getappdata(handles.f,'ROINames');
        handles.dna.sourceChannelPopUpMenu.String = names(1:numChannels);
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
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
    I = stack(:,:,1);
    autoImAdjust = stretchlim(I(combinedROIMask)); % get the auto brightness values    
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
    handles.axesControl.currentFrame.JavaPeer.set('StateChangedCallback', @(~,~) setCurrentFrame(handles.axesControl.currentFrame, get(handles.axesControl.currentFrame.JavaPeer,'Value')));
    handles.axesControl.currentFrameTextbox.set('Callback', @(hObject,~) setCurrentFrame( hObject, str2num(hObject.String)));
    handles.axesControl.playButton.set('Callback', @(hObject,~) playVideo( hObject, guidata(hObject)));
    
    % overlap mode
    handles.axesControl.seperateButtonGroup.Visible =  'off';
    handles.axesPanel.Selection = 1; % overlap channels mode for one axes
    
    % tracking settings
    handles.dna.particleIntensity.JavaPeer.set('Maximum',getappdata(handles.f,'video_maxIntensity'));
    
    % staining settings
    oneAxesCallbackID = handles.oneAxes.AxesAPI.addNewMagnificationCallback(@(~) updateDNAKernal(handles.dna.dnaKernalAxes, guidata(handles.dna.dnaKernalAxes)));
    setappdata(handles.f,'oneAxesCallbackID',oneAxesCallbackID);
    updateDNAKernal(hObject, handles);
    
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
    
    % tracking settings
    plt = getappdata(handles.f,'data_dna_plt');
    if ~isempty(plt)
        delete(plt);
    end
    setappdata(handles.f,'data_dna_plt',plt);
    
    % staining setting
    oneAxesCallbackID = getappdata(handles.f,'oneAxesCallbackID');
    handles.oneAxes.AxesAPI.removeNewMagnificationCallback(oneAxesCallbackID);
    
    homeInterface('openHome',hObject);
end

function updateDisplay(hObject,handles) 
    if ~exist('handles','var')
        handles = guidata(hObject);
    end
    
    I = getCurrentImage(hObject,handles);
    
    % remove old particles
    plt = getappdata(handles.f,'data_dna_plt');
    if ~isempty(plt)
        delete(plt);
    end
    
    % apply the gaussian filter and show selected particles if the user is using the tracking algrothim
    if handles.dna.autoDNAAlgorthimDropdown.Value==2
        % get tracking settings
        filterSize = handles.dna.particleFilter.JavaPeer.get('Value') / ...
                        handles.dna.particleFilter.JavaPeer.get('Maximum') * 5;
        particleMinInt = handles.dna.particleIntensity.JavaPeer.get('LowValue');
        particleMaxInt = handles.dna.particleIntensity.JavaPeer.get('HighValue');
        combinedROIMask = getappdata(handles.f,'combinedROIMask');
        
        % apply gaussian filter
        if filterSize > 0.1
            I = imgaussfilt(I, filterSize);
        end
        
        % detect particles
        particles = findParticles(I, particleMinInt, particleMaxInt, 'Mask', combinedROIMask);
        centers = particles{1};

        %% display particles
        hWaitBar = waitbar(0,'Loading ...');
        hold(handles.oneAxes.Axes,'on');
        
        % if too many particles were found only show some
        if size(centers,1) > 5000 
            pauseVideo(hObject,handles);
            msgbox('Too many particles found!');
            plt = [];
        else
            plt = plot( handles.oneAxes.Axes, centers(:,1), centers(:,2), '+r');
        end

        hold(handles.oneAxes.Axes,'off');
        setappdata(handles.f,'data_dna_plt',plt);
        delete(hWaitBar);
    end
    
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
            if ~getappdata(handles.f,'dna_manualMode') && strcmp(getappdata(handles.f,'mode'),'Select DNA')
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
            if ~getappdata(handles.f,'dna_manualMode') && strcmp(getappdata(handles.f,'mode'),'Select DNA')
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
                stack = getappdata(handles.f,'data_video_stack');

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
        I(~combinedROIMask) = 0;
        I(combinedROIMask) = imadjust(I(combinedROIMask),[lowBrightness,highBrightness]);
    else
        % crop overlay
        I(~combinedROIMask) = 0;
    end
end

function saveImlinesToKyms(hObject,handles)
    % Find the position of each DNA imline and save the position rather
    % then the whole graphics object.
    kyms = getappdata(handles.f,'kyms');
    dnaImlines = getappdata(handles.f,'dna_dnaImlines');
    removeInd = (1:size(kyms,1))';
    
    warning('off','MATLAB:table:RowsAddedExistingVars');
    
    for i=1:size(dnaImlines,2)
        row = get(dnaImlines{i},'UserData');
        pos = reshape(getPosition(dnaImlines{i})',1,[]);
        % if position has changed
        if size(kyms,1)<row || any(kyms.Position(row,1:4) ~= pos)
            kyms.ImageGenerated(row) = false;
            kyms.Brightness(row) = {-1};
            kyms.Position(row,1:4) = pos;
        end
        
        removeInd(removeInd==row) = [];
    end
    
    warning('on','MATLAB:table:RowsAddedExistingVars');
    
    % remove all kyms that with no corresponding Imline
    kyms(removeInd,:) = [];
    
    setappdata(handles.f,'kyms',kyms);
end

function changeDNADetectionAlgorthim(hObject,handles)
    handles.dna.autoDNACardPanel.Selection = handles.dna.autoDNAAlgorthimDropdown.Value;
    updateDisplay(hObject,handles); 
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
    
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
    autoImAdjust = stretchlim(I(combinedROIMask));
    
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
    %% Confirm current DNAs can first be removed
    
%         % are there any imlines to remove?
%     dnaImlines = getappdata(handles.f,'dna_dnaImlines');
%     if size(dnaImlines,2)~=0
%         removeAns = questdlg(   'Are you sure? This will clear all DNAs.',...
%                                 'Are you sure? This will clear all DNAs.',...
%                                 'Yes, clear all','No','No');
%         if strcmp(removeAns, 'No')
%             return; % stop
%         else
%             removeAllDNA(hObject,handles); % remove the old DNAs
%         end
%     end    
    
    switch handles.dna.autoDNAAlgorthimDropdown.Value
        case 1 % Stain
            detectDNAStains(hObject, handles);
        case 2 % Tracking
            detectDNAByTracking(hObject, handles);
    end
    
end

function setDNAWidth(hObject, value)
    handles = guidata(hObject);
        
    set(handles.dna.dnaWidthSlider.JavaPeer,'Value', value);
    
    value = get(handles.dna.dnaWidthSlider.JavaPeer,'Value');
    
    handles.dna.dnaWidthTextbox.String = num2str(value);
    
    updateDNAKernal(hObject, handles);
end

function setDNALength(hObject, value)
    handles = guidata(hObject);
        
    set(handles.dna.dnaLengthSlider.JavaPeer,'Value', value);
    
    value = get(handles.dna.dnaLengthSlider.JavaPeer,'Value');
    
    handles.dna.dnaLengthTextbox.String = num2str(value);
    
    updateDNAKernal(hObject, handles);
end

function setDNAMatchingStrength(hObject, value)
    handles = guidata(hObject);
        
    set(handles.dna.dnaMatchingStrengthSlider.JavaPeer,'Value', value);
    
    value = get(handles.dna.dnaMatchingStrengthSlider.JavaPeer,'Value');
    
    handles.dna.dnaMatchingStrengthTextbox.String = num2str(value);
end

function updateDNAKernal(hObject, handles)
    dnaWidth  = get(handles.dna.dnaWidthSlider.JavaPeer,'Value');
    dnaLength = get(handles.dna.dnaLengthSlider.JavaPeer,'Value');
    
    dnaKernal = strel('line',dnaLength,0); % length
    dnaKernal = dnaKernal.Neighborhood;
    dnaKernal = padarray(dnaKernal, dnaWidth); % width
    dnaKernal = padarray(dnaKernal',dnaWidth)';% width
    dnaKernal = imgaussfilt(double(dnaKernal),dnaWidth^(1/2));
    dnaKernal = im2uint16(dnaKernal);    
    
    dnaKernalImage = imadjust(dnaKernal);
    handles.dna.dnaKernalAxesAPI.replaceImage(dnaKernalImage,'PreserveView',true);
    handles.dna.dnaKernalAxesAPI.setMagnification(handles.oneAxes.AxesAPI.getMagnification());
    
    setappdata(handles.f,'dnaKernal',dnaKernal);
end

function removeOverlapedDNA(hObject, handles)
    hWaitBar = waitbar(0,'Checking for overlaping DNA...', 'WindowStyle', 'modal');

    dnaImlines = getappdata(handles.f,'dna_dnaImlines');
    
    overlapRadius = 5;

    prevX = zeros(size(dnaImlines,2),1);
    prevY = zeros(size(dnaImlines,2),1);
    i = 1;
    while i <= size(dnaImlines,2)
        waitbar(i/size(dnaImlines,2));
        
        pos = getPosition(dnaImlines{i});
        x1 = pos(1,1);
        y1 = pos(1,2);
        x2 = pos(2,1);
        y2 = pos(2,2);
        
        if any(abs(prevX(1:i-1) - mean([x2,x1])) < overlapRadius & abs(prevY(1:i-1) - mean([y2,y1])) < overlapRadius)
            deleteDNA(dnaImlines{i}, 0);
            dnaImlines = getappdata(handles.f,'dna_dnaImlines');
        else
            prevX(i) = mean([x1,x2]);
            prevY(i) = mean([y1,y2]);
            i = i+1;
        end
    end
    
    delete(hWaitBar);
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
            addNewDNA(hObject,handles);
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
    
    hWaitBar = waitbar(0,'Displaying DNA...', 'WindowStyle', 'modal');
    
    handles.oneAxes.AxesScrollPanel.Visible = 'off';
    
    kyms = getappdata(handles.f,'kyms');
    linePos = kyms.Position;
    
    % add a dna for each row in linePos
    for i = 1:size(linePos,1)
        waitbar(i/size(linePos,1));
        addNewDNA(hObject, handles, reshape(linePos(i,:),2,[])');
    end
    
    handles.oneAxes.AxesScrollPanel.Visible = 'on';
    delete(hWaitBar);
end

function removeAllDNA(hObject,handles)
    hWaitBar = waitbar(0,'Clearing DNA Display...', 'WindowStyle', 'modal');
    
    handles.oneAxes.AxesScrollPanel.Visible = 'off';

    dnaImlines = getappdata(handles.f,'dna_dnaImlines');
    % delete each imline graphic object
    for i=1:length(dnaImlines)
        delete(dnaImlines{i});
        waitbar(i/length(dnaImlines));
    end
    
    handles.oneAxes.AxesScrollPanel.Visible = 'on';
    setappdata(handles.f,'dna_dnaImlines',cell(0));
    delete(hWaitBar);
end

function removeAllDNA_Callback(hObject,handles)
    % ask the user if it is fine to remove the lines
    removeAns = questdlg('Are you sure you want to clear all DNAs?','Are you sure you want to clear all DNAs?','Yes, clear all','No','No');
    if strcmp(removeAns, 'Yes, clear all')
        removeAllDNA(hObject,handles);
    end
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
        
        num_dnaImlines = size(getappdata(handles.f,'dna_dnaImlines'),1);
        if num_dnaImlines == 0
            msgbox('No lines to generate kymographs from.');
            return;
        end
        
        saveSession(handles.f, 1); % auto save
        onRelease(hObject,handles); 
    end
    
    analyzeKymographInterface('onDisplay',hObject,handles);
    handles.leftPanel.Selection = 5;
end


