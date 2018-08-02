function varargout = analyzeFlowStrechingInterface(varargin)
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
    profiles = table;
    setappdata(handles.f,'flowStrechingProfiles',profiles);
    setappdata(handles.f,'flowStreching_currentProfile',1);
    setappdata(handles.f,'analyzeFlowStreching_mode','default');
    
    handles.prof.leftPanel = uix.VBox( 'Parent', handles.leftPanel);
    
    %% back
    handles.prof.backButtonPanel = uix.Panel('Parent', handles.prof.leftPanel);
    handles.prof.backButton = uicontrol(     'Parent', handles.prof.backButtonPanel,...
                                          	'String', 'Back',...
                                          	'Callback', @(hObject,~) onRelease(hObject,guidata(hObject)));
                                    
    %% selection
    handles.prof.selectionPanel = uix.BoxPanel( 'Parent', handles.prof.leftPanel,...
                                                'Title','Selection',...
                                                'Padding',5);
                                            
    handles.prof.selectionBox = uix.VBox('Parent', handles.prof.selectionPanel);
    
    % arrows
    handles.prof.arrowsBox = uix.HBox('Parent', handles.prof.selectionBox);
    handles.prof.backArrow = uicontrol(  'Parent', handles.prof.arrowsBox,...
                                        'String', '<--',...
                                        'Callback', @(hObject,~) prevProfile(hObject,guidata(hObject)));
    handles.prof.nextArrow = uicontrol(  'Parent', handles.prof.arrowsBox,...
                                        'String', '-->',...
                                        'Callback', @(hObject,~) nextProfile(hObject,guidata(hObject)));
    %
    handles.prof.currentProfileBox = uix.HBox('Parent', handles.prof.selectionBox);
    uicontrol(  'Parent', handles.prof.currentProfileBox,...
                'style', 'text',...
                'String', 'Current');
    handles.prof.currentProfileTextbox = uicontrol(  'Parent', handles.prof.currentProfileBox,...
                                                'String', '1',...
                                                'Style', 'edit',...
                                                'Callback', @(hObject,~) currentProfileTextboxCallback(hObject,guidata(hObject),str2num(hObject.String)));
    handles.prof.maxProfileText = uicontrol(   'Parent', handles.prof.currentProfileBox,...
                                            'String', '/1',...
                                            'Style', 'text',...
                                            'HorizontalAlignment', 'left');
                                        
    uicontrol(  'Parent', handles.prof.selectionBox,...
                'String', 'You can use the arrow keys to quickly navigate.',...
                'Style', 'text');
                                    
    %% 
    handles.prof.leftPanel.set('Heights',[25 200]);
    
    
    %% Right panel
    handles.prof.rightPanel    = uix.Panel('Parent', handles.rightPanel, 'BorderType', 'none');
    handles.prof.MainHBox      = uix.HBoxFlex('Parent', handles.prof.rightPanel, 'Spacing', 5);
    handles.prof.tablePanel    = uix.Panel('Parent', handles.prof.MainHBox);
    handles.prof.plotsVBox     = uix.VBoxFlex('Parent', handles.prof.MainHBox);
    handles.prof.MainHBox.set('Widths',[-1 -4]);
    
    handles.prof.profilePlotPanel  = uix.Panel('Parent', handles.prof.plotsVBox);
    handles.prof.videoPlotPanel    = uix.Panel('Parent', handles.prof.plotsVBox);
    
    %% Table
    handles.prof.profileTable = uitable(handles.prof.tablePanel);
    
    %% Video
    % framework
    handles.prof.vidVBox            = uix.VBox('Parent', handles.prof.videoPlotPanel);
    handles.prof.vidContorlsHBox    = uix.HBox('Parent', handles.prof.vidVBox);
    % play button
    handles.prof.playButton = uicontrol('Parent', handles.prof.vidContorlsHBox,...
                                       'String', 'Play',...
                                       'Callback', @(hObject,~) playVideo(hObject,guidata(hObject)));
    % slider
    [~, handles.prof.vidCurrentFrame] = javacomponent('javax.swing.JSlider');
    handles.prof.vidCurrentFrame.set('Parent', handles.prof.vidContorlsHBox);
    handles.prof.vidCurrentFrame.JavaPeer.set('Maximum', 2);
    handles.prof.vidCurrentFrame.JavaPeer.set('Minimum', 1);
    handles.prof.vidCurrentFrame.JavaPeer.set('Value', 1);
    handles.prof.vidCurrentFrame.JavaPeer.set('StateChangedCallback',...
        @(~,~) setVidCurrentFrame(handles.prof.vidCurrentFrame, get(handles.prof.vidCurrentFrame.JavaPeer,'Value')));
    % scroll-able axes
    handles.prof.vidAxesPanel = uipanel('Parent', handles.prof.vidVBox,...
                                       'BorderType', 'none');
    handles.prof.vidAxes = axes(handles.prof.vidAxesPanel);
    hVidImage = imshow(rand(1000),'Parent',handles.prof.vidAxes);
    handles.prof.vidAxesScrollPanel = imscrollpanel(handles.prof.vidAxesPanel,hVidImage);
    handles.prof.vidAxesAPI = iptgetapi(handles.prof.vidAxesScrollPanel);
    % magnification box
    handles.prof.vidMagBox = immagbox(handles.prof.vidAxesPanel, hVidImage);
    % framework size
    handles.prof.vidContorlsHBox.set('Widths',[50, -1]);
    handles.prof.vidVBox.set('Heights',[25 -1]);
    vidMagBoxPos = get(handles.prof.vidMagBox,'Position');
    set(handles.prof.vidMagBox,'Position',[0 0 vidMagBoxPos(3) vidMagBoxPos(4)]);
    
    %% Profile Plot
    handles.prof.profileAxes = axes(handles.prof.profilePlotPanel);
end

%% Load from session
function handles = loadFromSession(hObject,handles,session)
	setappdata(handles.f,'traces', session.prof_traces);
    
    if isempty(session.prof_traces) || any(~session.prof_traces.Calculated)
        handles.prof.preCalButton.Enable = 'on';
    else
        handles.prof.preCalButton.Enable = 'off';
    end
    
    setappdata(handles.f,'trace_mode', session.prof_mode);
    setappdata(handles.f,'trace_currentTrace', session.prof_currentTrace);
    set(handles.prof.currentDNATextBox, 'String', num2str(session.prof_currentTrace));
    
    set(handles.prof.cutSlider.JavaPeer, 'LowValue', session.prof_lowCut);
    set(handles.prof.cutSlider.JavaPeer, 'HighValue', session.prof_highCut);
    set(handles.prof.meanSlider.JavaPeer, 'Value', session.prof_mean);
    set(handles.prof.highCutTextBox, 'String', num2str(session.prof_highCut));
    set(handles.prof.lowCutTextBox, 'String', num2str(session.prof_lowCut));
    set(handles.prof.meanTextBox, 'String', num2str(session.prof_mean));
   
    set(handles.prof.hmmStatesSlider.JavaPeer, 'LowValue', session.prof_lowStates);
    set(handles.prof.hmmStatesSlider.JavaPeer, 'HighValue', session.prof_highStates);
    set(handles.prof.hmmStatesLowTextBox, 'String', num2str(session.prof_lowStates));
    set(handles.prof.hmmStatesHighTextBox, 'String', num2str(session.prof_highStates));
    
    handles.prof.removeBGCheckbox.Value = session.prof_removeBG;
    
    set(handles.prof.DAScale.JavaPeer, 'Value', session.prof_DAScale);
end

%% Updates
function onDisplay(hObject,handles,loadingSession)
    setappdata(handles.f,'mode','Analyze Flow Streching');
    
    % get stack
    stack = generateFlowStrechingInterface('getSourceStack',hObject,handles);
    
    % set sliders
    set(handles.prof.vidCurrentFrame.JavaPeer,'Maximum', size(stack,3));
    set(handles.prof.vidCurrentFrame.JavaPeer,'Value', getappdata(handles.f,'flow_currentFrame'));
    
    % updates
    if ~exist('loadingSession','var') || ~loadingSession
        generateFlowStrechingProfiles(hObject,handles);
    end
    setProfile(hObject,handles,1);
    updateMaxProfiles(hObject,handles);
    
    % key presses, these get turned off by onRelease
    set(handles.f,'WindowKeyPressFcn',@keyPressCallback);
    
    handles.rightPanel.Selection = 4;
    handles.rightPanel.Visible = 'on';
end

function onRelease(hObject,handles)
    handles.rightPanel.Selection = 1;
    
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    % key presses, these get turned on by onDisplay
    set(handles.f,'WindowKeyPressFcn','');
    
    homeInterface('openGenerateFlowStreching',hObject);
end

function updateDisplay(hObject,handles,videoOnlyFlag)
    if ~exist('handles')
        handles = guidata(hObject);
    end
    
    curFrame = getappdata(handles.f,'flow_currentFrame');

    % Video image
    I = generateFlowStrechingInterface('getCurrentImage',hObject,handles);
    handles.prof.vidAxesAPI.replaceImage(I,'PreserveView',true);
    
    if ~exist('videoOnlyFlag','var') % this is excluded when playing the video        
        profiles = getappdata(handles.f,'flowStrechingProfiles');
        currentProfile = getappdata(handles.f,'flowStreching_currentProfile');

        plot(handles.prof.profileAxes,  profiles.Profile{currentProfile}(:,1),...
                                        profiles.Profile{currentProfile}(:,2),'b');
    end
end

%% Selected Profile
function setProfile(hObject,handles,c)
    handles.prof.currentProfileTextbox.String = num2str(c);
    setappdata(handles.f,'flowStreching_currentProfile',c);
end

function prevProfile(hObject,handles)
    c = getappdata(handles.f,'flowStreching_currentProfile');
    if c>1
        c=c-1;
    else
        c=1;
    end
    setProfile(hObject,handles,c);
    updateDisplay(hObject,handles);
end

function nextProfile(hObject,handles)
    max_c = size(getappdata(handles.f,'flowStrechingProfiles'),1);
    c = getappdata(handles.f,'flowStreching_currentProfile');
    if c<max_c
        c=c+1;
    end
    setProfile(hObject,handles,c);
    updateDisplay(hObject,handles);
end

function keyPressCallback(hObject,eventdata)
    switch eventdata.Key
        case {'n','rightarrow','downarrow','d','s'}
            handles = guidata(hObject);
            nextTrace(hObject,handles);
        case {'p','leftarrow','uparrow','w','a'}
            handles = guidata(hObject);
            prevTrace(hObject,handles);
    end
end

function currentProfileTextboxCallback(hObject,handles,c)
    max_c = size(getappdata(handles.f,'flowStrechingProfiles'),1);
    c = round(c);
    if c>max_c && c<1
        c = getappdata(handles.f,'flowStreching_currentProfile');
    end
    setProfile(hObject,handles,c);
    updateDisplay(hObject,handles);
end

function updateMaxProfiles(hObject,handles)
    max_c = size(getappdata(handles.f,'flowStrechingProfiles'),1);
    handles.prof.maxProfileText.String = ['/' num2str(max_c)];
end

%% Play/pause Current Frame
function setVidCurrentFrame(hObject, value, videoOnlyFlag)
    handles = guidata(hObject);
    handles.prof.vidCurrentFrame.JavaPeer.set('Value', value);
    setappdata(handles.f,'home_currentFrame', value);
    
    if exist('videoOnlyFlag','var')
        updateDisplay(hObject,handles,videoOnlyFlag);
    else
        updateDisplay(hObject,handles);
    end
end

function playVideo(hObject,handles)
    % switch play button to pause button
    handles.prof.playButton.String = 'Pause';
    handles.prof.playButton.Callback = @(hObject,~) pauseVideo(hObject,guidata(hObject));
    
    % play loop
    setappdata(handles.f,'Playing_Video',1);
    currentFrame = getappdata(handles.f,'home_currentFrame');
    while getappdata(handles.f,'Playing_Video')
        if currentFrame < handles.axesControl.currentFrame.JavaPeer.get('Maximum')
            currentFrame = currentFrame+1;
        else
            currentFrame = 1;
        end
        setVidCurrentFrame(hObject, currentFrame, 1);
        drawnow;
    end
end

function pauseVideo(hObject,handles)
    % switch pause button to play button
    handles.prof.playButton.String = 'Play';
    handles.prof.playButton.Callback = @(hObject,~) playVideo(hObject,guidata(hObject));
    
    % flag to stop play loop
    setappdata(handles.f,'Playing_Video',0);
end
