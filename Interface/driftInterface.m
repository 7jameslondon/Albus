function varargout = driftInterface(varargin)
    if nargin && ischar(varargin{1})
        if nargout
            [varargout{1:nargout}] = feval(str2func(varargin{1}), varargin{2:end});
        else
            feval(str2func(varargin{1}), varargin{2:end});
        end
    end
end

%% Create Interface
function handles = createInterface(handles)
    setappdata(handles.f,'data_drift_plt',[]);

    handles.drift = struct();
    handles.drift.leftPanel  = uix.VBox('Parent', handles.leftPanel);
    
    %% back
    handles.drift.backButtonPanel = uix.Panel('Parent',   handles.drift.leftPanel);
    handles.drift.backButton      = uicontrol('Parent',   handles.drift.backButtonPanel,...
                                              'String',   'Back',...
                                          	  'Callback', @(hObject,~) onRelease(hObject,guidata(hObject)));
                                          
    %% Brightness/Invert
    handles.drift.preProcPanel = uix.BoxPanel(  'Parent', handles.drift.leftPanel,...
                                                'Title', 'Brightness Settings');
    handles.drift.preProcVBox = uix.VButtonBox( 'Parent', handles.drift.preProcPanel, ...
                                                'ButtonSize', [280 25]);
                                            
    % channel
    handles.drift.channelBox = uix.HBox('Parent', handles.drift.preProcVBox,...
                                        'Visible','off');
    uicontrol(  'Parent', handles.drift.channelBox,...
                'style', 'text',...
                'String', 'Channel');
    handles.drift.sourceChannelPopUpMenu = uicontrol(   'Parent', handles.drift.channelBox,...
                                                        'style', 'popupmenu',...
                                                        'String', {''},...
                                                        'Callback', @(hObject,~) selectSourceChannel(hObject,guidata(hObject)));
                                            
    % brightness
    uicontrol( 'Parent', handles.drift.preProcVBox,...
               'Style' , 'text', ...
               'String', 'Brightness');
    [~, handles.drift.brightness] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.drift.brightness.set('Parent', handles.drift.preProcVBox);
    handles.drift.brightness.JavaPeer.set('Maximum', 1e6);
    handles.drift.brightness.JavaPeer.set('Minimum', 0);
    handles.drift.brightness.JavaPeer.set('LowValue', 0);
    handles.drift.brightness.JavaPeer.set('HighValue', 1e6);
    handles.drift.brightness.JavaPeer.set('PaintTicks',true);
    handles.drift.brightness.JavaPeer.set('MajorTickSpacing',1e5);
    handles.drift.brightness.JavaPeer.set('MouseReleasedCallback', @(~,~) setBrightness(handles.drift.brightness));
    
    % box for auto, invert and time average
    handles.drift.autoAndInvertHBox = uix.HBox('Parent', handles.drift.preProcVBox);
    
    % invert
    handles.drift.invertCheckbox = uicontrol(   'Parent', handles.drift.autoAndInvertHBox,...
                                                'Style', 'checkbox',...
                                                'String', 'Invert',...
                                                'Callback', @(hObject,~) setInvertVideo(hObject, guidata(hObject),hObject.Value));
    
    % auto brightness
    handles.drift.autoBrightnessButton = uicontrol( 'Parent', handles.drift.autoAndInvertHBox,...
                                                    'String', 'Auto Brightness',...
                                                    'Callback', @(hObject,~) autoBrightness(hObject, guidata(hObject)));
                                                
    % moving mean
    uicontrol( 'Parent', handles.drift.preProcVBox,...
               'Style' , 'text', ...
               'String', 'Moving Mean (this is only used to calculate drift)');
    handles.drift.meanBox = uix.HBox('Parent', handles.drift.preProcVBox);
    handles.drift.meanTextBox = uicontrol('Parent', handles.drift.meanBox,...
                                    	'String', '1',...
                                        'Style', 'edit',...
                                       	'Callback', @(hObject,~) setMean_Textbox(hObject));
    [~, handles.drift.meanSlider] = javacomponent('javax.swing.JSlider');
    handles.drift.meanSlider.set('Parent', handles.drift.meanBox);
    handles.drift.meanSlider.JavaPeer.set('Maximum', 20);
    handles.drift.meanSlider.JavaPeer.set('Minimum', 1);
    handles.drift.meanSlider.JavaPeer.set('Value', 1);
    handles.drift.meanSlider.JavaPeer.set('MouseReleasedCallback', @(~,~) setMean_Slider(handles.drift.meanSlider));
    handles.drift.meanBox.set('Widths',[30, -1]);
                                                
    %% Particle Selection
    handles.drift.particleSelectionPanel = uix.BoxPanel(    'Parent', handles.drift.leftPanel,...
                                                            'Title', 'Particle Selection');
    handles.drift.particleSelectionVBox = uix.VBox( 'Parent', handles.drift.particleSelectionPanel);
    
    % mark particles
    handles.drift.markParticles = uicontrol(    'Parent', handles.drift.particleSelectionVBox, ...
                                                'Style', 'checkbox', ...
                                                'String', 'Mark Particles (slows down display)', ...
                                                'Value', 1, ...
                                                'Callback', @(hObject,~) setMarkParticles(hObject, guidata(hObject),hObject.Value));
                                            
    % particle filter size
    uicontrol( 'Parent', handles.drift.particleSelectionVBox,...
               'Style' , 'text', ...
               'String', 'Gaussina Filter Size');
    [~, handles.drift.particleFilter] = javacomponent('javax.swing.JSlider');
    handles.drift.particleFilter.set('Parent', handles.drift.particleSelectionVBox);
    handles.drift.particleFilter.JavaPeer.set('Maximum', 5e5);
    handles.drift.particleFilter.JavaPeer.set('Minimum', 0);
    handles.drift.particleFilter.JavaPeer.set('Value', 0);
    handles.drift.particleFilter.JavaPeer.set('MouseReleasedCallback', @(~,~) updateDisplay(handles.drift.particleFilter));
    % add filter lables
    parFilLabels = java.util.Hashtable();
    parFilLabels.put( int32( 0 ),   javax.swing.JLabel('0') );
    parFilLabels.put( int32( 1e5 ), javax.swing.JLabel('1') );
    parFilLabels.put( int32( 2e5 ), javax.swing.JLabel('2') );
    parFilLabels.put( int32( 3e5 ), javax.swing.JLabel('3') );
    parFilLabels.put( int32( 4e5 ), javax.swing.JLabel('4') );
    parFilLabels.put( int32( 5e5 ), javax.swing.JLabel('5') );
    handles.drift.particleFilter.JavaPeer.setLabelTable( parFilLabels );
    handles.drift.particleFilter.JavaPeer.setPaintLabels(true);
    
    uix.Empty('Parent', handles.drift.particleSelectionVBox);
                                            
    % particle brightness
    uicontrol( 'Parent', handles.drift.particleSelectionVBox,...
               'Style' , 'text', ...
               'String', 'Particle Intensity');
    [~, handles.drift.particleIntensity] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.drift.particleIntensity.set('Parent', handles.drift.particleSelectionVBox);
    handles.drift.particleIntensity.JavaPeer.set('Maximum', 1e6);
    handles.drift.particleIntensity.JavaPeer.set('Minimum', 0);
    handles.drift.particleIntensity.JavaPeer.set('LowValue', 0);
    handles.drift.particleIntensity.JavaPeer.set('HighValue', 1e6);
    handles.drift.particleIntensity.JavaPeer.set('PaintTicks',true);
    handles.drift.particleIntensity.JavaPeer.set('MajorTickSpacing',1e5);
    handles.drift.particleIntensity.JavaPeer.set('MouseReleasedCallback', @(~,~) setBrightness(handles.drift.particleIntensity));
    
    uix.Empty('Parent', handles.drift.particleSelectionVBox);
    
    % max distance
    uicontrol( 'Parent', handles.drift.particleSelectionVBox,...
               'Style' , 'text', ...
               'String', 'Max Distance');
    [~, handles.drift.maxDistance] = javacomponent('javax.swing.JSlider');
    handles.drift.maxDistance.set('Parent', handles.drift.particleSelectionVBox);
    handles.drift.maxDistance.JavaPeer.set('Maximum', 10e5);
    handles.drift.maxDistance.JavaPeer.set('Minimum', 0);
    handles.drift.maxDistance.JavaPeer.set('Value', 0);
    handles.drift.maxDistance.JavaPeer.set('MouseReleasedCallback', @(~,~) updateDisplay(handles.drift.maxDistance));
    % add max distance lables
    parFilLabels = java.util.Hashtable();
    parFilLabels.put( int32( 0 ),   javax.swing.JLabel('0') );
    parFilLabels.put( int32( 2e5 ), javax.swing.JLabel('2') );
    parFilLabels.put( int32( 4e5 ), javax.swing.JLabel('4') );
    parFilLabels.put( int32( 6e5 ), javax.swing.JLabel('6') );
    parFilLabels.put( int32( 8e5 ), javax.swing.JLabel('8') );
    parFilLabels.put( int32( 10e5 ), javax.swing.JLabel('10') );
    handles.drift.maxDistance.JavaPeer.setLabelTable( parFilLabels );
    handles.drift.maxDistance.JavaPeer.setPaintLabels(true);
    
    handles.drift.particleSelectionVBox.set('Heights',[25 15, 35, 15, 15, 35, 15 15, 35]);
    
    %% Apply Correction
    handles.drift.applyCorrectionPanel = uix.Panel(     'Parent', handles.drift.leftPanel);
    handles.drift.applyCorrectionVBox  = uix.VBox( 'Parent', handles.drift.applyCorrectionPanel);

    handles.drift.applyCorrection = uicontrol(  'Parent', handles.drift.applyCorrectionVBox,...
                                                'Style', 'checkbox',...
                                                'String', 'Apply Drift Correction (takes a few minutes)',...
                                                'Callback', @(hObject,~) applyCorrection(hObject, guidata(hObject),hObject.Value));
                                            
    handles.drift.driftVectorAxes = polaraxes(handles.drift.applyCorrectionVBox);
    polarplot(handles.drift.driftVectorAxes,0,0);
    handles.drift.driftVectorAxes.ThetaTickLabel = [];
    
    uix.Empty('Parent', handles.drift.applyCorrectionVBox);
                                            
    handles.drift.doneButton      = uicontrol('Parent',   handles.drift.applyCorrectionVBox,...
                                              'String',   'Done',...
                                          	  'Callback', @(hObject,~) onRelease(hObject,guidata(hObject)));
                                          
    handles.drift.applyCorrectionVBox.set('Heights',[30, 150, 10, 25]);
    %%
    handles.drift.leftPanel.set('Heights',[25, 210, 240, 220]);
end

%% Load session
function handles = loadFromSession(hObject,handles,session)    
    handles.drift.invertCheckbox.Value = session.drift_invertImage;
    set(handles.drift.brightness.JavaPeer, 'LowValue', session.drift_lowBrightness);
    set(handles.drift.brightness.JavaPeer, 'HighValue', session.drift_highBrightness);

    handles.drift.markParticles.Value = session.drift_markParticles;
    handles.drift.particleIntensity.JavaPeer.set('LowValue', session.drift_particleIntensityLow);
    handles.drift.particleIntensity.JavaPeer.set('HighValue', session.drift_particleIntensityHigh);
    handles.drift.particleFilter.JavaPeer.set('Value', session.drift_particleFilter);
    handles.drift.maxDistance.JavaPeer.set('Value', session.drift_maxDistance);

    handles.drift.applyCorrection.Value = session.drift_isDriftCorrected;
    
    handles.drift.meanSlider.JavaPeer.set('Value', session.drift_meanLength);
end

%% Display
function onDisplay(hObject,handles)
    % get the current video file and make a temporary copy for drift
    meanLength = handles.drift.meanSlider.JavaPeer.get('Value');
    calculateMovingMeanOfVideo(hObject,handles,meanLength);
    isMapped = getappdata(handles.f,'isMapped');
    if isMapped
        speratedStacks = getappdata(handles.f,'data_drift_seperatedStacks');
    else
        stack = getappdata(handles.f,'data_drift_stack');
    end

    % how many channels are there (if any)
    if isMapped % fill channel selector with list of channels
        numChannels = size(speratedStacks,1);
        names = getappdata(handles.f,'ROINames');
        handles.drift.sourceChannelPopUpMenu.String = names(1:numChannels);
        handles.drift.channelBox.Visible = 'on';
    else % do not show channel selector
        handles.drift.sourceChannelPopUpMenu.String = {''};
        handles.drift.channelBox.Visible = 'off';
    end
    
    % transfer current frame slider control to driftInterface
    if isMapped
        stackLength = size(speratedStacks{1},3);
    else
        stackLength = size(stack,3);
    end
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum', stackLength);
    set(handles.axesControl.currentFrame.JavaPeer,'Value', getappdata(handles.f,'home_currentFrame'));
    set(handles.axesControl.currentFrameTextbox,'String', num2str(getappdata(handles.f,'home_currentFrame')));
    handles.axesControl.currentFrame.JavaPeer.set('MouseReleasedCallback', ...
        @(~,~) setCurrentFrame(handles.axesControl.currentFrame, get(handles.axesControl.currentFrame.JavaPeer,'Value')));
    handles.axesControl.currentFrameTextbox.set('Callback', @(hObject,~) setCurrentFrame( hObject, str2num(hObject.String)));
    handles.axesControl.playButton.set('Callback', @(hObject,~) playVideo( hObject, guidata(hObject)));
    
    % remove overlap mode controls
    handles.axesControl.seperateButtonGroup.Visible =  'off';
    handles.axesPanel.Selection = 1; % overlap channels mode for one axes
    
    % set max brightness of brightness slider and particle intensity slider
    maxIntensity = getappdata(handles.f,'video_maxIntensity');
    set(handles.drift.brightness.JavaPeer, 'Maximum', maxIntensity);
    set(handles.drift.particleIntensity.JavaPeer, 'Maximum', maxIntensity);
    
    % update the display
    autoBrightness(hObject, handles);
    updateDisplay(hObject,handles);
end

function onRelease(hObject,handles)    
    plt = getappdata(handles.f,'data_drift_plt');
    if ~isempty(plt)
        delete(plt);
    end
    plt = [];
    setappdata(handles.f,'data_drift_plt',plt);
    
    setappdata(handles.f,'data_drift_stack',[]);
    setappdata(handles.f,'data_drift_seperatedStacks',[]);
    homeInterface('openHome',hObject);
end

function updateDisplay(hObject,handles) 
    if ~exist('handles','var')
        handles = guidata(hObject);
    end
    
    % get data
    I = getCurrentImage(hObject,handles);
    
    filterSize = handles.drift.particleFilter.JavaPeer.get('Value') / handles.drift.particleFilter.JavaPeer.get('Maximum') * 5;
    particleMinInt = handles.drift.particleIntensity.JavaPeer.get('LowValue');
    particleMaxInt = handles.drift.particleIntensity.JavaPeer.get('HighValue');
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
    
    % filter image
    if filterSize > 0.1
        I = imgaussfilt(I, filterSize);
    end
    
    % display filtered image
    handles.oneAxes.AxesAPI.replaceImage(I,'PreserveView',true);
    
    if handles.drift.markParticles.Value
    
        % detect particles
        particles = findParticles(I, particleMinInt, particleMaxInt, 'Mask', combinedROIMask);
        centers = particles{1};

        % display particles
        hold(handles.oneAxes.Axes,'on');
        plt = getappdata(handles.f,'data_drift_plt');
        if ~isempty(plt)
            delete(plt);
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
        setappdata(handles.f,'data_drift_plt',plt);
        
    else
        plt = getappdata(handles.f,'data_drift_plt');
        if ~isempty(plt)
            delete(plt);
        end
        plt = [];
        setappdata(handles.f,'data_drift_plt',plt);
    end
    
    % plot the current drift vector
    drift = getappdata(handles.f,'drift');
    if isempty(drift)
        polarplot(handles.drift.driftVectorAxes,[]);
    else
        [driftTheta, driftR] = cart2pol(drift(:,1),drift(:,2));
        polarplot(handles.drift.driftVectorAxes, driftTheta, driftR);
    end
    handles.drift.driftVectorAxes.ThetaTickLabel = [];
end

function I = getCurrentImage(hObject,handles,brightnessflag)
    % get values
    currentFrame    = getappdata(handles.f,'home_currentFrame');
    
    lowBrightness   = get(handles.drift.brightness.JavaPeer,'LowValue')/get(handles.drift.brightness.JavaPeer,'Maximum');
    highBrightness  = get(handles.drift.brightness.JavaPeer,'HighValue')/get(handles.drift.brightness.JavaPeer,'Maximum');
    invertImage     = handles.drift.invertCheckbox.Value;
    
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
    stack           = getCurrentStack(hObject,handles);
    
    % current frame
    I = stack(:,:,currentFrame);
    % invert
    if invertImage
        I = imcomplement(I);
    end
    % brightness
    if ~exist('brightnessflag','var') % used for autobrightness
        I(combinedROIMask) = imadjust(I(combinedROIMask),[lowBrightness,highBrightness]);
    end
    % crop overlay
    I(~combinedROIMask) = 0;
end

function S = getCurrentStack(hObject,handles)
    % get current stack
    if getappdata(handles.f,'isMapped')
        speratedStacks = getappdata(handles.f,'data_drift_seperatedStacks');
        S = speratedStacks{handles.drift.sourceChannelPopUpMenu.Value};
    else
        S = getappdata(handles.f,'data_drift_stack');
    end
end

function selectSourceChannel(hObject,handles)
    autoBrightness(hObject,handles); % this will also update the display
end

%% Brightness Callbacks
function setBrightness(hObject)
    handles = guidata(hObject);
    lowBrightness = get(handles.drift.brightness.JavaPeer,'LowValue');
    highBrightness = get(handles.drift.brightness.JavaPeer,'HighValue');
    if lowBrightness==highBrightness
        if lowBrightness==0
            set(handles.drift.brightness.JavaPeer,'HighValue',highBrightness+1)
        else
            set(handles.drift.brightness.JavaPeer,'LowValue',lowBrightness-1)
        end
    end
    
    updateDisplay(hObject,handles);
end

function autoBrightness(hObject, handles)    
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
    
    % current frame
    I = getCurrentImage(hObject,handles,1); % the 1 suppresses brightness settings

    % auto brightness
    autoImAdjust = stretchlim(I(combinedROIMask));
    autoImAdjust = round(autoImAdjust * get(handles.drift.brightness.JavaPeer,'Maximum'));

    % set slider values
    set(handles.drift.brightness.JavaPeer,'LowValue',autoImAdjust(1));
    set(handles.drift.brightness.JavaPeer,'HighValue',autoImAdjust(2));
    
    % display autoed image
    updateDisplay(hObject,handles);
end

function setInvertVideo(hObject, handles, value)
    handles.map.invertCheckbox.Value = value;
    autoBrightness(hObject,handles); % this will also update the display
end

%% Moving Mean

function setMean_Textbox(hObject)
    handles = guidata(hObject);

    % parse the given value
    value_min = handles.drift.meanSlider.JavaPeer.get('Minimum');
    value_max = handles.drift.meanSlider.JavaPeer.get('Maximum');
    value = str2double(handles.drift.meanTextBox.String);
    value = round(value);
    value = max(value,value_min);
    value = min(value,value_max);
    
    % update value of controls
    handles.drift.meanSlider.JavaPeer.set('Value',value);
    handles.drift.meanTextBox.String = num2str(value);
    
    % perform the mean
    calculateMovingMeanOfVideo(hObject,handles,value);
    
    % display the updated mean image
    autoBrightness(hObject, handles);
    updateDisplay(hObject,handles);
end

function setMean_Slider(hObject)
    handles = guidata(hObject);
    
    % update value of controls
    value = handles.drift.meanSlider.JavaPeer.get('Value');
    handles.drift.meanTextBox.String = num2str(value);
    
    % perform the mean
    calculateMovingMeanOfVideo(hObject,handles,value);
    
    % display the updated mean image
    autoBrightness(hObject, handles);
    updateDisplay(hObject,handles);
end

function calculateMovingMeanOfVideo(hObject,handles,value)
    hWaitBar = waitbar(0,'Calculating ...', 'WindowStyle', 'modal');

    if getappdata(handles.f,'isMapped')
        speratedStacks = getappdata(handles.f,'data_video_seperatedStacks');
        for s=1:size(speratedStacks,3)
            speratedStacks{s} = cast(movmean(speratedStacks{s},value,3),class(speratedStacks{s}));
        end
        setappdata(handles.f,'data_drift_seperatedStacks',speratedStacks);
    else
        stack = getappdata(handles.f,'data_video_stack');
        stack = cast(movmean(stack,value,3),class(stack));
        setappdata(handles.f,'data_drift_stack',stack);
    end
    
    delete(hWaitBar);
end

%% Frames
function setCurrentFrame(hObject, value)
    handles = guidata(hObject);
    set(handles.axesControl.currentFrame.JavaPeer,'Value',value);
    handles.axesControl.currentFrameTextbox.String = num2str(value);
    setappdata(handles.f,'home_currentFrame', value);
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
        playSpeed = getappdata(handles.f, 'playSpeed');
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

%% Mark Particles
function setMarkParticles(hObject,handles,value)
    handles.drift.markParticles.Value = value;
    
    % remove current marked particles, if any
    plt = getappdata(handles.f,'data_drift_plt');
    if ~isempty(plt)
        delete(plt);
    end
    plt = [];
    setappdata(handles.f,'data_drift_plt',plt);
    
    % update display
    updateDisplay(hObject,handles);
end

%% Drift Callbacks
function applyCorrection(hObject, handles, value)
    % Hide/show particles
    setMarkParticles(hObject,handles,(~value));
        
    % Apply or remove drift correction
    if value
        hWaitBar = waitbar(0,'Calculating Drift ...', 'WindowStyle', 'modal');
        
        % Get data
        filterSize      = handles.drift.particleFilter.JavaPeer.get('Value') / handles.drift.particleFilter.JavaPeer.get('Maximum') * 5;
        particleMinInt  = handles.drift.particleIntensity.JavaPeer.get('LowValue');
        particleMaxInt  = handles.drift.particleIntensity.JavaPeer.get('HighValue');
        maxDistance     = handles.drift.maxDistance.JavaPeer.get('Value') / handles.drift.maxDistance.JavaPeer.get('Maximum') * 10;
        selectedStack  = getCurrentStack(hObject,handles);

        % Calculate the drift correction
        drift = calculateDrift(selectedStack, particleMinInt, particleMaxInt, filterSize, maxDistance);

        % Save
        setappdata(handles.f,'drift',drift);
        
        % Update the ROI mask
        calculateROIMask(0,handles);

        waitbar(0.5,hWaitBar,'Correcting Drift ...');
        
        if getappdata(handles.f,'isMapped')
            collocalizeVideo(hObject,handles);
        else
            videoSettingInterface('postProcessVideo',hObject,handles);
        end
        
        %% plot drift vector
        [driftTheta, driftR] = cart2pol(drift(:,1),drift(:,2));
        polarplot(handles.drift.driftVectorAxes, driftTheta, driftR);

        delete(hWaitBar);
    else
        setappdata(handles.f,'drift',[]);
        
        if getappdata(handles.f,'isMapped')
            collocalizeVideo(hObject,handles);
        else
            videoSettingInterface('postProcessVideo',hObject,handles);
        end
        
        polarplot(handles.drift.driftVectorAxes,0,0);
    end
    
    handles.drift.driftVectorAxes.ThetaTickLabel = [];
end

