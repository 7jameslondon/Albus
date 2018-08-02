function varargout = homeInterface(varargin)
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
    handles.home = struct();
    handles.home.leftPanel = uix.VBox('Parent', handles.leftPanel);
    handles.home.VButtonBox = uix.VButtonBox(   'Parent', handles.home.leftPanel, ...
                                                'ButtonSize', [200 25]);
    handles.home.bottomSpace = uix.Empty('Parent', handles.home.leftPanel );
    handles.home.leftPanel.set('Heights',[200, -1]);

    handles.home.vidButton = uicontrol(     'Parent', handles.home.VButtonBox,...
                                            'String', 'Import Video',...
                                            'Callback', @(hObject,~) openVideoSettings(hObject));
                                
    handles.home.mapButton = uicontrol(     'Parent', handles.home.VButtonBox,...
                                            'String', 'Register Channels',...
                                            'Callback', @(hObject,~) openMapping(hObject));
                                
    handles.home.driftButton = uicontrol(   'Parent', handles.home.VButtonBox,...
                                            'String', 'Correct Drift',...
                                            'Callback', @(hObject,~) openDriftCorrection(hObject),...
                                            'Enable', 'off');
                                
    handles.home.dnaButton = uicontrol(     'Parent', handles.home.VButtonBox,...
                                            'String', 'Generate Kymographs',...
                                            'Callback', @(hObject,~) openSelectDNA(hObject),...
                                            'Enable', 'off');
                                    
    handles.home.fretButton = uicontrol(    'Parent', handles.home.VButtonBox,...
                                            'String', 'Generate FRET Traces',...
                                            'Callback', @(hObject,~) openSelectFRET(hObject),...
                                            'Enable', 'off');
                                        
    handles.home.fretButton = uicontrol(    'Parent', handles.home.VButtonBox,...
                                            'String', 'Generate Flow Streching Profiles',...
                                            'Callback', @(hObject,~) openGenerateFlowStreching(hObject),...
                                            'Enable', 'off');
end

%% Callbacks
% handles.leftPanel.Selection = #
% 1  - home
% 2  - video
% 3  - mapping
% 4  - generate kymographs
% 5  - analyze kymographs
% 6  - generate fret
% 7  - analyze fret
% 8  - drift
% 9  - generate flow streching
% 10 - analyze flow streching

function openVideoSettings(hObject)
    handles = guidata(hObject);
    setappdata(handles.f,'mode','Video Settings');
    onRelease(hObject,handles)
    
    handles.leftPanel.Selection = 2;
    videoSettingInterface('onDisplay',hObject,handles);
end

function openHome(hObject)
    handles = guidata(hObject);
    setappdata(handles.f,'mode','Home');
    
    % disable/enable buttons if video is avalible
    if strcmp(handles.vid.selectVideoTextBox.String, 'No video selected')
        handles.home.driftButton.Enable = 'off';
        handles.home.dnaButton.Enable   = 'off';
        handles.home.fretButton.Enable  = 'off';
    else
        handles.home.driftButton.Enable = 'on';
        handles.home.dnaButton.Enable   = 'on';
        handles.home.fretButton.Enable  = 'on';
    end
    
    handles.leftPanel.Selection = 1;
    onDisplay(hObject,handles);
end

function openMapping(hObject)
    handles = guidata(hObject);
    setappdata(handles.f,'mode','Mapping');
    onRelease(hObject,handles)
    
    handles.leftPanel.Selection = 3;
    mappingInterface('onDisplay',hObject,handles);
end

function openDriftCorrection(hObject)
    handles = guidata(hObject);
    setappdata(handles.f,'mode','Drift');
    onRelease(hObject,handles)
    
    handles.leftPanel.Selection = 8;
    driftInterface('onDisplay',hObject,handles);
end

function openSelectDNA(hObject)
    handles = guidata(hObject);
    setappdata(handles.f,'mode','Select DNA');
    onRelease(hObject,handles)
    
    handles.leftPanel.Selection = 4;
    generateKymographInterface('onDisplay',hObject,handles);
end

function openSelectFRET(hObject)
    handles = guidata(hObject);
    setappdata(handles.f,'mode','Select FRET');
    onRelease(hObject,handles)
    
    handles.leftPanel.Selection = 6;
    generateFRETInterface('onDisplay',hObject,handles);
end

function openGenerateFlowStreching(hObject)
    handles = guidata(hObject);
    setappdata(handles.f,'mode','Generate Flow Streching');
    onRelease(hObject,handles)
    
    handles.leftPanel.Selection = 9;
    generateFlowStrechingInterface('onDisplay',hObject,handles);
end

%% Updates
function updateDisplay(hObject,handles) 
    if ~exist('handles','var')
        handles = guidata(hObject);
    end
    
    if  handles.axesPanel.Selection == 1
        I = getCurrentOneAxesImage(hObject,handles);
        handles.oneAxes.AxesAPI.replaceImage(I,'PreserveView',true);
        
    elseif handles.axesPanel.Selection == 2
        curretFrame = get(handles.axesControl.currentFrame.JavaPeer,'Value');
        seperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');
        combinedROIMask = getappdata(handles.f,'combinedROIMask');
        
        for i=1:length(seperatedStacks)
            % current frame
            I = seperatedStacks{i}(:,:,curretFrame);
            % overalp mask
            I(~combinedROIMask) = 0;
            % brightness
            I(combinedROIMask) = imadjust(I(combinedROIMask));
            % display
            handles.multiAxes.AxesAPI{i}.replaceImage(I,'PreserveView',true);
        end
    end
end

function I = getCurrentOneAxesImage(hObject,handles)
    currentFrame = getappdata(handles.f,'home_currentFrame');
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
    
    if getappdata(handles.f,'isMapped')
        colors = getappdata(handles.f,'colors');
        seperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');
        
        seperatedFrames = cell(length(seperatedStacks),1); % pre-aloc
        for i=1:length(seperatedStacks)
            I = seperatedStacks{i}(:,:,currentFrame);
            
            % overalp mask
            I(~combinedROIMask) = 0;
            % brightness
            I(combinedROIMask) = imadjust(I(combinedROIMask));
            
            seperatedFrames{i} = I;
        end
        I = rgbCombineSeperatedImages(seperatedFrames, colors);
            
    else
        stack = getappdata(handles.f,'data_video_stack');
        
        % current frame
        I = stack(:,:,currentFrame);
        % overalp mask
        I(~combinedROIMask) = 0;
        % brightness
        I(combinedROIMask) = imadjust(I(combinedROIMask));
    end
end

function onDisplay(hObject,handles)
    handles.rightPanel.Visible = 'off';
    
    if ~strcmp(handles.vid.selectVideoTextBox.String, 'No video selected')
        handles.rightPanel.Visible = 'on';
        if getappdata(handles.f,'isMapped')
            seperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');
            set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(seperatedStacks{1},3));
            handles.axesControl.seperateButtonGroup.Visible =  'on';
        else
            stack = getappdata(handles.f,'data_video_stack');
            set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
        end
        
        % current frame
        set(handles.axesControl.currentFrame.JavaPeer,'Value', getappdata(handles.f,'home_currentFrame'));
        set(handles.axesControl.currentFrameTextbox,'String', num2str(getappdata(handles.f,'home_currentFrame')));
        handles.axesControl.currentFrame.JavaPeer.set('StateChangedCallback', @(~,~) setCurrentFrame(handles.axesControl.currentFrame, get(handles.axesControl.currentFrame.JavaPeer,'Value')));
        handles.axesControl.currentFrameTextbox.set('Callback', @(hObject,~) setCurrentFrame( hObject, str2num(hObject.String)));
        % play button
        handles.axesControl.playButton.set('Callback', @(hObject,~) playVideo( hObject, guidata(hObject)));
        % axes control
        handles.axesControl.currentFramePanel.Visible = 'on';
        handles.axesControl.seperateButtonGroup.set('SelectionChangedFcn', @(hObject,event) switchDisplayAxes(hObject,str2num(event.NewValue.Tag))); 
        % update display
        updateDisplay(hObject,handles);
    end
end

function onRelease(hObject,handles)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    setappdata(handles.f,'home_currentFrame', get(handles.axesControl.currentFrame.JavaPeer,'Value'));
end

function switchDisplayAxes(hObject, value)
    handles = guidata(hObject);
    
    switch value
        case 1
            handles.axesControl.seperateButtonGroup.SelectedObject = handles.axesControl.overlapAxesButton;
        case 2
            handles.axesControl.seperateButtonGroup.SelectedObject = handles.axesControl.seperateAxesButton;
    end
    
    handles.axesPanel.Selection = value;
    updateDisplay(hObject,handles);
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