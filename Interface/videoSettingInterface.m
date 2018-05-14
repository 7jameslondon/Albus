function varargout = videoSettingInterface(varargin)
    if nargin && ischar(varargin{1})
        if nargout
            [varargout{1:nargout}] = feval(str2func(varargin{1}), varargin{2:end});
        else
            feval(str2func(varargin{1}), varargin{2:end});
        end
    end
end

%% CreateInterface
function handles = createInterface(handles)
    setappdata(handles.f,'video_mode','Select Video');
    setappdata(handles.f, 'vid_imrect', []);
    setappdata(handles.f, 'vid_imrectPos', []);

    handles.vid = struct();
        
    handles.vid.leftPanel = uix.VBox( 'Parent', handles.leftPanel);
    
    %% back
    handles.vid.backButtonPanel = uix.Panel('Parent', handles.vid.leftPanel);
    handles.vid.backButton = uicontrol(     'Parent', handles.vid.backButtonPanel,...
                                          	'String', 'Back',...
                                          	'Callback', @(hObject,~) onRelease(hObject,guidata(hObject)));
                                        
    %% select video
    handles.vid.seletVideoPanel = uix.BoxPanel('Parent', handles.vid.leftPanel,...
                                               'Title', 'Select the video');
                                            
    handles.vid.selectVideoBox = uix.VBox('Parent', handles.vid.seletVideoPanel,...
                                             'Padding', 5);
                                            
    handles.vid.selectVideoButtonBox = uix.VButtonBox('Parent', handles.vid.selectVideoBox,...
                                                'ButtonSize', [100 25]);
                                        
    handles.vid.selectVideoButton = uicontrol(  'Parent', handles.vid.selectVideoButtonBox,...
                                                'String', 'Select Video',...
                                                'Callback', @(hObject,~) selectVideoFileButtonCallback(hObject));
                                            
    handles.vid.selectVideoTextBox = uicontrol( 'Parent', handles.vid.selectVideoBox,...
                                                'Style' , 'edit', ...
                                                'String', 'No video selected',...
                                                'Callback', @(hObject,~) selectVideoFileTextBoxCallback(hObject,hObject.String));
                                            
    handles.vid.selectVideoBox.set('Heights',[25 25]);
    
    %% edit
    handles.vid.editPanel = uix.BoxPanel('Parent', handles.vid.leftPanel,...
                                                'Title', 'Settings',...
                                                'Visible', 'off');
                                            
    handles.vid.editBox = uix.VBox('Parent', handles.vid.editPanel,...
                                             'Padding', 5);
                                            
    % invert
    handles.vid.invertCheckbox = uicontrol(     'Parent', handles.vid.editBox,...
                                                'Style', 'checkbox',...
                                                'String', 'Invert',...
                                                'Callback', @(hObject,~) setInvertVideo(hObject, guidata(hObject),hObject.Value));
    % brightness
    uicontrol( 'Parent', handles.vid.editBox,...
               'Style' , 'text', ...
               'String', 'Brightness');
    [~, handles.vid.brightness] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.vid.brightness.set('Parent', handles.vid.editBox);
    handles.vid.brightness.JavaPeer.set('Maximum', 1e6);
    handles.vid.brightness.JavaPeer.set('Minimum', 0);
    handles.vid.brightness.JavaPeer.set('LowValue', 0);
    handles.vid.brightness.JavaPeer.set('HighValue', 1e6);
    handles.vid.brightness.JavaPeer.set('PaintTicks',true);
    handles.vid.brightness.JavaPeer.set('MajorTickSpacing',1e5);
    handles.vid.brightness.JavaPeer.set('MouseReleasedCallback', @(~,~) setBrightness(handles.vid.brightness));
    
    % auto brightness
    handles.vid.autoBrightnessButton = uicontrol(  'Parent', handles.vid.editBox,...
                                                'String', 'Auto Brightness',...
                                                'Callback', @(hObject,~) autoBrightness(hObject, guidata(hObject)));
                                            
    % cut
    uicontrol( 'Parent', handles.vid.editBox,...
               'Style' , 'text', ...
               'String', 'Cutting');
    [~, handles.vid.cutting] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.vid.cutting.set('Parent', handles.vid.editBox);
    handles.vid.cutting.JavaPeer.set('Maximum', 2);
    handles.vid.cutting.JavaPeer.set('Minimum', 1);
    handles.vid.cutting.JavaPeer.set('LowValue', 1);
    handles.vid.cutting.JavaPeer.set('HighValue', 2);
    handles.vid.cutting.JavaPeer.set('PaintTicks',true);
    handles.vid.cutting.JavaPeer.set('MouseReleasedCallback', @(~,~) setCutting(handles.vid.cutting));
    
    handles.vid.editBox.set('Heights',[25 25 25 25 25 25 ]);

    %%
    handles.vid.leftPanel.set('Heights',[25 80 200]);
    
    setappdata(handles.f,'video_currentFrame',1);
    setappdata(handles.f,'home_currentFrame',1);
end

%% Select File Callback
function selectVideoFileButtonCallback(hObject)
    [fileName, fileDir, ~] = uigetfile({'*.tif';'*.tiff';'*.TIF';'*.TIFF'}, 'Select the video file'); % prompt user for file
    if fileName ~= 0 % if user does not presses cancel
        selectVideoFileTextBoxCallback(hObject, [fileDir fileName]);
    end
end

function selectVideoFileTextBoxCallback(hObject, filePath)
    handles = guidata(hObject);
    handles = setVideoFile(hObject, handles, filePath);
    handles = setControlsForNewVideo(hObject, handles);
end

function handles = setControlsForNewVideo(hObject, handles)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    % requires a video to have been saved
    stack = getappdata(handles.f,'data_video_originalStack');
    
    % frame controls
    % set max before values
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    set(handles.vid.cutting.JavaPeer,'Maximum',size(stack,3));
    handles.vid.cutting.JavaPeer.set('MajorTickSpacing',round(size(stack,3)/10));
    
    % frame
    set(handles.axesControl.currentFrame.JavaPeer,'Value',1);
    setappdata(handles.f,'video_currentFrame',1);
    setappdata(handles.f,'home_currentFrame',1);
    handles.axesControl.currentFrameTextbox.String = '1';
    
    % cutting
    set(handles.vid.cutting.JavaPeer,'LowValue',1);
    set(handles.vid.cutting.JavaPeer,'HighValue',size(stack,3));
    
    % brightness controls
    autoImAdjust = stretchlim(stack(:,:,1)); % get the auto brightness values    
    autoImAdjust = round(autoImAdjust * get(handles.vid.brightness.JavaPeer,'Maximum'));
    set(handles.vid.brightness.JavaPeer,'LowValue',autoImAdjust(1));
    set(handles.vid.brightness.JavaPeer,'HighValue',autoImAdjust(2));
    
    % invet
    handles.vid.invertCheckbox.Value   = 0;
        
    % collocalize
    if getappdata(handles.f,'isMapped')
        mappingInterface('collocalizeVideo',hObject,handles);
    end
    
    switchMode(hObject, handles, 'Edit');
end

function handles = loadFromSession(hObject,handles,session)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    % get the stack
    handles = setVideoFile(hObject, handles, session.vid_videoFilePath);
    stack = getappdata(handles.f,'data_video_originalStack');
    if stack==0 % the file could not be located
        uiwait(msgbox('The original video file could not be found. Please locate the new location of the video and select it.'));
        
        [fileName, fileDir, ~] = uigetfile({'*.tif';'*.tiff';'*.TIF';'*.TIFF'}, 'Select the video file'); % prompt user for file
        if fileName ~= 0 % if user does not presses cancel
            handles = setVideoFile(hObject, handles, [fileDir fileName]);
        else
            handles.vid.selectVideoTextBox.String = session.vid_videoFilePath;
            delete(handles.f);
        end
        stack = getappdata(handles.f,'data_video_originalStack');
    end
    
    % frame controls
    % set max before values
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    set(handles.vid.cutting.JavaPeer,'Maximum',size(stack,3));
    handles.vid.cutting.JavaPeer.set('MajorTickSpacing',round(size(stack,3)/10));
    
    % frame
    handles.axesControl.currentFrameTextbox.String = num2str(session.vid_currentFrame);
    set(handles.axesControl.currentFrame.JavaPeer, 'Value', session.vid_currentFrame);
    setappdata(handles.f,'video_currentFrame',session.vid_currentFrame)
    
    set(handles.vid.cutting.JavaPeer, 'LowValue', session.vid_startFrame);
    set(handles.vid.cutting.JavaPeer, 'HighValue', session.vid_endFrame);
    
    % brightness controls
    set(handles.vid.brightness.JavaPeer, 'LowValue', session.vid_lowBrightness);
    set(handles.vid.brightness.JavaPeer, 'HighValue', session.vid_highBrightness);
    handles.vid.invertCheckbox.Value = session.vid_invertVideo;
    
    % crop
    setappdata(handles.f, 'vid_imrectPos', session.vid_imrectPos);
    
    setappdata(handles.f,'video_mode',session.vid_mode);
end
    
function handles = setVideoFile(hObject, handles, filePath)
    hWaitBar = waitbar(0,'Loading in video...', 'WindowStyle', 'modal');
    [stack, maxIntensity] = getStackFromFile(filePath, hWaitBar);
    if stack == 0 % an error was encountored
        filePath = 'No video selected';
    end
    
    % save
    handles.vid.selectVideoTextBox.String = filePath;
    setappdata(handles.f,'data_video_originalStack',stack);
    setappdata(handles.f,'video_maxIntensity',maxIntensity);
    
    close(hWaitBar);
end

%% Brightness Callbacks
function setBrightness(hObject)
    handles = guidata(hObject);
    lowBrightness = get(handles.vid.brightness.JavaPeer,'LowValue');
    highBrightness = get(handles.vid.brightness.JavaPeer,'HighValue');
    if lowBrightness==highBrightness
        if lowBrightness==0
            set(handles.vid.brightness.JavaPeer,'HighValue',highBrightness+1)
        else
            set(handles.vid.brightness.JavaPeer,'LowValue',lowBrightness-1)
        end
    end
    
    updateDisplay(hObject,handles);
end

function autoBrightness(hObject, handles)
    stack = getappdata(handles.f,'data_video_originalStack');
    curretFrame = get(handles.axesControl.currentFrame.JavaPeer,'Value');
    I = stack(:,:,curretFrame);
    if handles.vid.invertCheckbox.Value
        I = imcomplement(I);
    end
    autoImAdjust = stretchlim(I);
    
    autoImAdjust = round(autoImAdjust * get(handles.vid.brightness.JavaPeer,'Maximum'));
    
    set(handles.vid.brightness.JavaPeer,'LowValue',autoImAdjust(1));
    set(handles.vid.brightness.JavaPeer,'HighValue',autoImAdjust(2));

    updateDisplay(hObject,handles);
end

function setInvertVideo(hObject, handles, value)
    handles.vid.invertCheckbox.Value = value;
    autoBrightness(hObject,handles); % this will also update the display
end

%% Frames
function setCurrentFrame(hObject, value)
    handles = guidata(hObject);
    set(handles.axesControl.currentFrame.JavaPeer,'Value',value);
    handles.axesControl.currentFrameTextbox.String = num2str(value);
    setappdata(handles.f,'video_currentFrame', value);
    updateDisplay(hObject,handles);
end

function setCutting(hObject)
    handles = guidata(hObject);
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

%% Cropping
function moveCropImRect(hParent,hObject)
    handles = guidata(hParent);
    setappdata(handles.f,'combinedROIMask',createMask(hObject));
    autoBrightness(hParent, handles);
end

%% Update Display
function updateDisplay(hObject,handles) 
    if ~exist('handles','var')
        handles = guidata(hObject);
    end
    
    if  handles.axesPanel.Selection == 1
        I = getCurrentOneAxesImage(hObject,handles);
        handles.oneAxes.AxesAPI.replaceImage(I,'PreserveView',true);
        
    elseif handles.axesPanel.Selection == 2
        curretFrame = get(handles.axesControl.currentFrame.JavaPeer,'Value');
        seperatedStacks = getappdata(handles.f,'data_video_originalSeperatedStacks');
        lowCut = get(handles.vid.cutting.JavaPeer,'LowValue');
        highCut = get(handles.vid.cutting.JavaPeer,'HighValue');
        invertImage = handles.vid.invertCheckbox.Value;
        combinedROIMask = getappdata(handles.f,'combinedROIMask');
        
        for i=1:length(seperatedStacks)
            % current frame
            I = seperatedStacks{i}(:,:,curretFrame);
            % invert
            if invertImage
                I = imcomplement(I);
            end
            % overalp mask
            I(~combinedROIMask) = 0;
            % brightness
            I(combinedROIMask) = imadjust(I(combinedROIMask));
            % color the frame red if it is in the cut region
            if curretFrame < lowCut || curretFrame > highCut
                I = cat(3,I,I*0,I*0);
            end
            % display
            handles.multiAxes.AxesAPI{i}.replaceImage(I,'PreserveView',true);
        end
    end
end

function I = getCurrentOneAxesImage(hObject,handles)
    curretFrame = get(handles.axesControl.currentFrame.JavaPeer,'Value');
    lowCut = get(handles.vid.cutting.JavaPeer,'LowValue');
    highCut = get(handles.vid.cutting.JavaPeer,'HighValue');
    invertImage = handles.vid.invertCheckbox.Value;
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
    
    if getappdata(handles.f,'isMapped')
        colors = getappdata(handles.f,'colors');
        seperatedStacks = getappdata(handles.f,'data_video_originalSeperatedStacks');
        
        seperatedFrames = cell(length(seperatedStacks),1); % pre-aloc
        for i=1:length(seperatedStacks)
            % current frame
            I = seperatedStacks{i}(:,:,curretFrame);
            % invert
            if invertImage
                I = imcomplement(I);
            end
            % overalp mask
            I(~combinedROIMask) = 0;
            % brightness
            I(combinedROIMask) = imadjust(I(combinedROIMask));

            seperatedFrames{i} = I;
        end
        I = rgbCombineSeperatedImages(seperatedFrames, colors);
            
    else
        lowBrightness = get(handles.vid.brightness.JavaPeer,'LowValue')/get(handles.vid.brightness.JavaPeer,'Maximum');
        highBrightness = get(handles.vid.brightness.JavaPeer,'HighValue')/get(handles.vid.brightness.JavaPeer,'Maximum');
        stack = getappdata(handles.f,'data_video_originalStack');
        
        % current frame
        I = stack(:,:,curretFrame);
        % invert
        if invertImage
            I = imcomplement(I);
        end
        % overalp mask
        I(~combinedROIMask) = 0;
        % brightness
        I(combinedROIMask) = imadjust(I(combinedROIMask),[lowBrightness highBrightness]);
        
        % color the frame red if it is in the cut region
        if curretFrame < lowCut || curretFrame > highCut
            I = cat(3,I,I*0,I*0);
        end
    end
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

function switchMode(hObject, handles, value)
    setappdata(handles.f,'video_mode',value);

    handles.rightPanel.Visible = 'off';
    handles.map.editPanel.Visible = 'off';
    handles.axesControl.currentFramePanel.Visible = 'off';
    
    switch value
        case 'Select Video'
            
        case 'Edit'
            handles.rightPanel.Visible = 'on';
            handles.vid.editPanel.Visible = 'on';
            handles.axesControl.currentFramePanel.Visible = 'on';
            updateDisplay(hObject,handles);
            % zoom axes
            handles.oneAxes.AxesAPI.setMagnification(handles.oneAxes.AxesAPI.findFitMag());
            
            if ~getappdata(handles.f,'isMapped')
                % create croping imrect
                hImrect = getappdata(handles.f, 'vid_imrect');
                if isempty(hImrect)
                    pos = getappdata(handles.f, 'vid_imrectPos');
                    if isempty(pos)
                        pos = [handles.oneAxes.Axes.XLim(1), handles.oneAxes.Axes.YLim(1), diff(handles.oneAxes.Axes.XLim), diff(handles.oneAxes.Axes.YLim)];
                        setappdata(handles.f, 'vid_imrectPos', pos);
                    end

                    constFcn = makeConstrainToRectFcn('imrect',get(handles.oneAxes.Axes,'XLim'),get(handles.oneAxes.Axes,'YLim'));

                    hImrect = imrect(handles.oneAxes.Axes, pos, 'PositionConstraintFcn',constFcn);
                    hImrect.addNewPositionCallback(@(pos) moveCropImRect(handles.f,hImrect));
                    hImrect.setColor('red');

                    setappdata(handles.f, 'vid_imrect', hImrect);
                    moveCropImRect(handles.f,hImrect);
                end
            end
    end
    
    if getappdata(handles.f,'isMapped')
        handles.axesControl.seperateButtonGroup.Visible =  'on';
    else
        handles.axesControl.seperateButtonGroup.Visible =  'off';
    end
end

function onDisplay(hObject,handles)
    % current frame
    stack = getappdata(handles.f,'data_video_originalStack');
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    set(handles.axesControl.currentFrame.JavaPeer,'Value', getappdata(handles.f,'video_currentFrame'));
    set(handles.axesControl.currentFrameTextbox,'String', num2str(getappdata(handles.f,'video_currentFrame')));
    handles.axesControl.currentFrame.JavaPeer.set('MouseReleasedCallback', @(~,~) setCurrentFrame(handles.axesControl.currentFrame, get(handles.axesControl.currentFrame.JavaPeer,'Value')));
    handles.axesControl.currentFrameTextbox.set('Callback', @(hObject,~) setCurrentFrame( hObject, str2num(hObject.String)));
    handles.axesControl.playButton.set('Callback', @(hObject,~) playVideo( hObject, guidata(hObject)));
    
    % axes control
    handles.axesControl.seperateButtonGroup.set('SelectionChangedFcn', @(hObject,event) switchDisplayAxes(hObject,str2num(event.NewValue.Tag))); 
    
    switchMode(hObject, handles, getappdata(handles.f,'video_mode'));
end

function onRelease(hObject,handles)
    % stop video playing
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    setappdata(handles.f,'video_currentFrame', get(handles.axesControl.currentFrame.JavaPeer,'Value'));
        
    % cut video and map it if nessasary
    postProcessVideo(hObject,handles);
    
    % remove the croping imrect
    hImrect = getappdata(handles.f, 'vid_imrect');
    if ~isempty(hImrect)
        setappdata(handles.f, 'vid_imrectPos', hImrect.getPosition());
        delete(hImrect);
        setappdata(handles.f, 'vid_imrect', []);
        
    end
    
    homeInterface('openHome',hObject);
end

function postProcessVideo(hObject,handles)
    if ~strcmp(handles.vid.selectVideoTextBox.String, 'No video selected')
        if getappdata(handles.f,'isMapped')
            mappingInterface('collocalizeVideo',hObject,handles);
        else
            originalStack = getappdata(handles.f,'data_video_originalStack');
            lowCut = get(handles.vid.cutting.JavaPeer,'LowValue');
            highCut = get(handles.vid.cutting.JavaPeer,'HighValue');
            
            % cut
            stack = originalStack(:,:,lowCut:highCut); 
            
            % invert
            invertImage = handles.vid.invertCheckbox.Value;
            if invertImage
                for f=1:size(stack,3) 
                    stack(:,:,f) = imcomplement(stack(:,:,f));
                end
            end
            
            % save
            setappdata(handles.f,'data_video_stack',stack);
        end
    end
end
