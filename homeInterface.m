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
    handles.home.leftPanel.set('Heights',[100, -1]);

    handles.home.vidButton = uicontrol( 'Parent', handles.home.VButtonBox,...
                                    'String', 'Video Settings',...
                                    'Callback', @(hObject,~) openVideoSettings(hObject));
    handles.home.mapButton = uicontrol( 'Parent', handles.home.VButtonBox,...
                                    'String', 'Register Channels',...
                                    'Callback', @(hObject,~) openMapping(hObject));
    handles.home.dnaButton = uicontrol( 'Parent', handles.home.VButtonBox,...
                                        'String', 'Select DNA',...
                                        'Callback', @(hObject,~) openSelectDNA(hObject));
    handles.home.fretButton = uicontrol('Parent', handles.home.VButtonBox,...
                                        'String', 'Select FRET',...
                                        'Callback', @(hObject,~) openSelectFRET(hObject));
end

%% Callbacks
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

function openSelectDNA(hObject)
    handles = guidata(hObject);
    setappdata(handles.f,'mode','Select DNA');
    onRelease(hObject,handles)
    
    handles.leftPanel.Selection = 4;
    selectDNAInterface('onDisplay',hObject,handles);
end

function openSelectFRET(hObject)
    handles = guidata(hObject);
    setappdata(handles.f,'mode','Select FRET');
    onRelease(hObject,handles)
    
    handles.leftPanel.Selection = 6;
    selectFRETInterface('onDisplay',hObject,handles);
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
    
    if getappdata(handles.f,'isMapped')
        colors = getappdata(handles.f,'colors');
        seperatedStacks = getappdata(handles.f,'data_video_treatedSeperatedStacks');
        
        seperatedFrames = cell(length(seperatedStacks),1); % pre-aloc
        for i=1:length(seperatedStacks)
            seperatedFrames{i} = seperatedStacks{i}(:,:,currentFrame);
        end
        I = rgbCombineSeperatedImages(seperatedFrames, colors);
            
    else
        stack = getappdata(handles.f,'data_video_stack');
        combinedROIMask = getappdata(handles.f,'combinedROIMask');
        
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
            
        else
            stack = getappdata(handles.f,'data_video_stack');
            set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
        end
        
        % current frame
        set(handles.axesControl.currentFrame.JavaPeer,'Value', getappdata(handles.f,'home_currentFrame'));
        set(handles.axesControl.currentFrameTextbox,'String', num2str(getappdata(handles.f,'home_currentFrame')));
        handles.axesControl.currentFrame.JavaPeer.set('MouseReleasedCallback', @(~,~) setCurrentFrame(handles.axesControl.currentFrame, get(handles.axesControl.currentFrame.JavaPeer,'Value')));
        handles.axesControl.currentFrameTextbox.set('Callback', @(hObject,~) setCurrentFrame( hObject, str2num(hObject.String)));
        % play button
        handles.axesControl.playButton.set('Callback', @(hObject,~) playVideo( hObject, guidata(hObject)));
        % axes control
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