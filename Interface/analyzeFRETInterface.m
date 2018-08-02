function varargout = analyzeFRETInterface(varargin)
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
    traces = table;
    setappdata(handles.f,'traces',traces);
    setappdata(handles.f,'trace_currentTrace',1);
    setappdata(handles.f,'trace_mode','default');
    
    handles.tra.leftPanel = uix.VBox( 'Parent', handles.leftPanel);
    
    %% back
    handles.tra.backButtonPanel = uix.Panel('Parent', handles.tra.leftPanel);
    handles.tra.backButton = uicontrol(     'Parent', handles.tra.backButtonPanel,...
                                          	'String', 'Back',...
                                          	'Callback', @(hObject,~) onRelease(hObject,guidata(hObject)));
    
    %% settings
    handles.tra.settingsPanel = uix.BoxPanel('Parent', handles.tra.leftPanel,...
                                           'Title','Settings',...
                                           'Padding',5);
    handles.tra.settingsBox = uix.VBox('Parent', handles.tra.settingsPanel);
    
    % pre-calculate all
    handles.tra.preCalButton = uicontrol(   'Parent', handles.tra.settingsBox,...
                                            'String', 'Pre-calculate',...
                                            'Callback', @(hObject,~) preCalculateAllTraces(hObject,guidata(hObject)));
    
    % cutting
    uicontrol( 'Parent', handles.tra.settingsBox,...
               'Style' , 'text', ...
               'String', 'Cutting');
    handles.tra.cutBox = uix.HBox('Parent', handles.tra.settingsBox);
    handles.tra.lowCutTextBox = uicontrol(  'Parent', handles.tra.cutBox,...
                                            'String', '1',...
                                            'Style', 'edit',...
                                            'Callback', @(hObject,~) setLowCut(hObject));
    [~, handles.tra.cutSlider] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.tra.cutSlider.set('Parent', handles.tra.cutBox);
    handles.tra.cutSlider.JavaPeer.set('Maximum', 2);
    handles.tra.cutSlider.JavaPeer.set('Minimum', 1);
    handles.tra.cutSlider.JavaPeer.set('LowValue', 1);
    handles.tra.cutSlider.JavaPeer.set('HighValue', 2);
    handles.tra.cutSlider.JavaPeer.set('StateChangedCallback', @(~,~) setCut(handles.tra.cutSlider));
    handles.tra.highCutTextBox = uicontrol( 'Parent', handles.tra.cutBox,...
                                            'String', '2',...
                                            'Style', 'edit',...
                                            'Callback', @(hObject,~) setHighCut(hObject));
    handles.tra.cutBox.set('Widths',[30, -1, 30]);
                                        
    % moving mean
    uicontrol( 'Parent', handles.tra.settingsBox,...
               'Style' , 'text', ...
               'String', 'Moving Mean');
    handles.tra.meanBox = uix.HBox('Parent', handles.tra.settingsBox);
    handles.tra.meanTextBox = uicontrol('Parent', handles.tra.meanBox,...
                                    	'String', '1',...
                                        'Style', 'edit',...
                                       	'Callback', @(hObject,~) setMean_Textbox(hObject));
    [~, handles.tra.meanSlider] = javacomponent('javax.swing.JSlider');
    handles.tra.meanSlider.set('Parent', handles.tra.meanBox);
    handles.tra.meanSlider.JavaPeer.set('Maximum', 20);
    handles.tra.meanSlider.JavaPeer.set('Minimum', 1);
    handles.tra.meanSlider.JavaPeer.set('Value', 1);
    handles.tra.meanSlider.JavaPeer.set('StateChangedCallback', @(~,~) setMean_Slider(handles.tra.meanSlider));
    handles.tra.meanBox.set('Widths',[30, -1]);
    
    % remove background
    handles.tra.removeBGCheckbox = uicontrol(   'Parent', handles.tra.settingsBox,...
                                                'String', 'Remove Background',...
                                                'Style', 'checkbox',...
                                                'Callback', @(hObject,~) setRemoveBG(hObject));
                                            
    handles.tra.settingsBox.set('Heights',[25,20,20,20,20,20]);
                                    
    %% selection
    handles.tra.selectionPanel = uix.BoxPanel(  'Parent', handles.tra.leftPanel,...
                                                'Title','Selection',...
                                                'Padding',5);
    handles.tra.selectionBox = uix.VBox('Parent', handles.tra.selectionPanel);
    
    % arrows
    handles.tra.arrowsBox = uix.HBox('Parent', handles.tra.selectionBox);
    handles.tra.backArrow = uicontrol(  'Parent', handles.tra.arrowsBox,...
                                        'String', '<--',...
                                        'Callback', @(hObject,~) prevTrace(hObject,guidata(hObject)));
    handles.tra.nextArrow = uicontrol(  'Parent', handles.tra.arrowsBox,...
                                        'String', '-->',...
                                        'Callback', @(hObject,~) nextTrace(hObject,guidata(hObject)));
    %
    handles.tra.currentTraceBox = uix.HBox('Parent', handles.tra.selectionBox);
    uicontrol(  'Parent', handles.tra.currentTraceBox,...
                'style', 'text',...
                'String', 'Current');
    handles.tra.currentDNATextBox = uicontrol(  'Parent', handles.tra.currentTraceBox,...
                                                'String', '1',...
                                                'Style', 'edit',...
                                                'Callback', @(hObject,~) currentTraceTextBoxCallback(hObject,guidata(hObject),str2num(hObject.String)));
    handles.tra.maxTraceText = uicontrol(   'Parent', handles.tra.currentTraceBox,...
                                            'String', '/1',...
                                            'Style', 'text',...
                                            'HorizontalAlignment', 'left');
                                    
    %% HMM Settings
    handles.tra.hmmPanel = uix.BoxPanel(  'Parent', handles.tra.leftPanel,...
                                                'Title','Hidden Markov Modeling',...
                                                'Padding',5);
    handles.tra.hmmBox = uix.VBox('Parent', handles.tra.hmmPanel);
    
    % HMM
    uicontrol( 'Parent', handles.tra.hmmBox,...
               'Style' , 'text', ...
               'String', 'Range of States');
    handles.tra.hmmStatesBox = uix.HBox('Parent', handles.tra.hmmBox);
    handles.tra.hmmStatesLowTextBox = uicontrol('Parent', handles.tra.hmmStatesBox,...
                                                'String', '1',...
                                                'Style', 'edit',...
                                                'Callback', @(hObject,~) setHMMStates_LowTextBox(hObject));
    [~, handles.tra.hmmStatesSlider] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.tra.hmmStatesSlider.set('Parent', handles.tra.hmmStatesBox);
    handles.tra.hmmStatesSlider.JavaPeer.set('Maximum', 9);
    handles.tra.hmmStatesSlider.JavaPeer.set('Minimum', 1);
    handles.tra.hmmStatesSlider.JavaPeer.set('LowValue', 1);
    handles.tra.hmmStatesSlider.JavaPeer.set('HighValue', 2);
    handles.tra.hmmStatesSlider.JavaPeer.set('StateChangedCallback', @(~,~) setHMMStates_Slider(handles.tra.hmmStatesSlider));
    handles.tra.hmmStatesHighTextBox = uicontrol(   'Parent', handles.tra.hmmStatesBox,...
                                                    'String', '2',...
                                                    'Style', 'edit',...
                                                    'Callback', @(hObject,~) setHMMStates_HighTextBox(hObject));
    handles.tra.hmmStatesBox.set('Widths',[30, -1, 30]);
    
    %% Exports
    handles.tra.exportPanel = uix.BoxPanel(  'Parent', handles.tra.leftPanel,...
                                                'Title','Export',...
                                                'Padding',5);
    handles.tra.exportBox = uix.VButtonBox('Parent', handles.tra.exportPanel,...
                                           'ButtonSize', [140 30]);
    
    handles.tra.exportTraces = uicontrol(   'Parent', handles.tra.exportBox,...
                                                'String', 'Export Traces',...
                                                'Callback', @(hObject,~) exportTraces(hObject,guidata(hObject)));
                                            
    handles.tra.exportTraceImages = uicontrol(   'Parent', handles.tra.exportBox,...
                                                'String', 'Export Trace Images',...
                                                'Callback', @(hObject,~) exportTraceImages(hObject,guidata(hObject)));
                                            
    handles.tra.showDwellTimes = uicontrol(   'Parent', handles.tra.exportBox,...
                                                'String', 'Show Dwell Times',...
                                                'Callback', @(hObject,~) showDwellTime(hObject,guidata(hObject)));
                                            
    handles.tra.exportDwellTimes = uicontrol(   'Parent', handles.tra.exportBox,...
                                                'String', 'Export Dwell Times',...
                                                'Callback', @(hObject,~) exportDwellTime(hObject,guidata(hObject)));
                                            
    handles.tra.exportTransitionCounts = uicontrol(   'Parent', handles.tra.exportBox,...
                                                'String', 'Export Transition Counts',...
                                                'Callback', @(hObject,~) exportTransCounts(hObject,guidata(hObject)));
                                            
    handles.tra.showTDP = uicontrol(            'Parent', handles.tra.exportBox,...
                                                'String', 'Show Transition Density Plot',...
                                                'Callback', @(hObject,~) showTDP(hObject,guidata(hObject)));
                                            
    handles.tra.showPSH = uicontrol(            'Parent', handles.tra.exportBox,...
                                                'String', 'Show Post-Sync Histogram',...
                                                'Callback', @(hObject,~) showPSH(hObject,guidata(hObject)));
                                                 
    %% 
    handles.tra.leftPanel.set('Heights',[25 200 80 75 250]);
    
    
    %% Right panel
    handles.tra.MainHBox      = uix.HBoxFlex('Parent', handles.rightPanelTra, 'Spacing', 5);
    handles.tra.graphPanel    = uix.Panel('Parent', handles.tra.MainHBox);
    handles.tra.videoPanel    = uix.Panel('Parent', handles.tra.MainHBox);
    handles.tra.MainHBox.set('Widths',[-4 -1]);
    
    %% Video
    % framework
    handles.tra.vidVBox    = uix.VBox('Parent', handles.tra.videoPanel);
    handles.tra.vidHBox    = uix.HBox('Parent', handles.tra.vidVBox);
    % play button
    handles.tra.playButton = uicontrol('Parent', handles.tra.vidHBox,...
                                       'String', 'Play',...
                                       'Callback', @(hObject,~) playVideo(hObject,guidata(hObject)));
    % slider
    [~, handles.tra.vidCurrentFrame] = javacomponent('javax.swing.JSlider');
    handles.tra.vidCurrentFrame.set('Parent', handles.tra.vidHBox);
    handles.tra.vidCurrentFrame.JavaPeer.set('Maximum', 2);
    handles.tra.vidCurrentFrame.JavaPeer.set('Minimum', 1);
    handles.tra.vidCurrentFrame.JavaPeer.set('Value', 1);
    handles.tra.vidCurrentFrame.JavaPeer.set('StateChangedCallback',...
        @(~,~) setVidCurrentFrame(handles.tra.vidCurrentFrame, get(handles.tra.vidCurrentFrame.JavaPeer,'Value')));
    % scroll-able axes
    handles.tra.vidAxesPanel = uipanel('Parent', handles.tra.vidVBox,...
                                       'BorderType', 'none');
    handles.tra.vidAxes = axes(handles.tra.vidAxesPanel);
    hVidImage = imshow(rand(1000),'Parent',handles.tra.vidAxes);
    handles.tra.vidAxesScrollPanel = imscrollpanel(handles.tra.vidAxesPanel,hVidImage);
    handles.tra.vidAxesAPI = iptgetapi(handles.tra.vidAxesScrollPanel);
    % magnification box
    handles.tra.vidMagBox = immagbox(handles.tra.vidAxesPanel, hVidImage);
    % framework size
    handles.tra.vidHBox.set('Widths',[50, -1]);
    handles.tra.vidVBox.set('Heights',[25 -1]);
    vidMagBoxPos = get(handles.tra.vidMagBox,'Position');
    set(handles.tra.vidMagBox,'Position',[0 0 vidMagBoxPos(3) vidMagBoxPos(4)]);
    
    %% Graphs
    % grid
    handles.tra.graphGrid = uix.GridFlex('Parent', handles.tra.graphPanel, 'Spacing', 5);
    
    [~, handles.tra.DAScale] = javacomponent('javax.swing.JSlider');
    handles.tra.DAScale.set('Parent', handles.tra.graphGrid);
    handles.tra.DAScale.JavaPeer.set('Maximum', 10e6);
    handles.tra.DAScale.JavaPeer.set('Minimum', 0);
    handles.tra.DAScale.JavaPeer.set('Value', 0);
    handles.tra.DAScale.JavaPeer.set('StateChangedCallback', @(~,~) setScale(handles.tra.DAScale, handles.tra.DAScale.JavaPeer.get('Value')/handles.tra.DAScale.JavaPeer.get('Maximum')*10));
    handles.tra.DAScale.JavaPeer.set('Orientation',handles.tra.DAScale.JavaPeer.VERTICAL);
    
    uix.Empty('Parent', handles.tra.graphGrid);
    handles.tra.DAAxes              = axes(handles.tra.graphGrid);
    handles.tra.FRETAxes            = axes(handles.tra.graphGrid);
    handles.tra.graphGrid.set('Widths',[30 -1],'Heights',[-1 -1]);
    
    % plots
    handles.tra.DonorPlot           = plot(handles.tra.DAAxes, 1, '-');
    hold(handles.tra.DAAxes,'on');
    handles.tra.AcceptorPlot        = plot(handles.tra.DAAxes, 1, '-');
    handles.tra.DonorStatePlot      = plot(handles.tra.DAAxes, 1, '-');
    handles.tra.AcceptorStatePlot 	= plot(handles.tra.DAAxes, 1, '-', 'color', [0 0 0]);
    hold(handles.tra.DAAxes,'off');
    
    handles.tra.DonorPlot.LineWidth         = 2;
    handles.tra.AcceptorPlot.LineWidth      = 2;
    handles.tra.DonorStatePlot.LineWidth    = 1;
    handles.tra.AcceptorStatePlot.LineWidth = 1;
    
    handles.tra.DonorPlot.Color         = [38.8, 58.4, 00.0]/100;
    handles.tra.AcceptorPlot.Color      = [85.5, 13.7, 13.7]/100;
    handles.tra.DonorStatePlot.Color    = [58.8, 88.4, 30.0]/100;
    handles.tra.AcceptorStatePlot.Color = [100., 13.7, 40.0]/100;

    % fret
    handles.tra.FRETPlot        = plot(handles.tra.FRETAxes, 1, '-');
    hold(handles.tra.FRETAxes,'on');
    handles.tra.FRETStatePlot   = plot(handles.tra.FRETAxes, 1, '-','color', [0 0 0]/256);
    hold(handles.tra.FRETAxes,'off');
    
    handles.tra.FRETPlot.LineWidth      = 2;
    handles.tra.FRETStatePlot.LineWidth = 1;
    
    handles.tra.FRETPlot.Color      = [9.8, 54.1, 54.1]/100;
    handles.tra.FRETStatePlot.Color = [0.0, 00.0, 00.0]/100;
    
    % current frame arrows on traces
    handles.tra.curFrameArrowDA   = text(handles.tra.DAAxes,   1,0,char(8593),'HorizontalAlignment','center','VerticalAlignment','top');
    handles.tra.curFrameArrowFRET = text(handles.tra.FRETAxes, 1,0,char(8593),'HorizontalAlignment','center','VerticalAlignment','top');
end

%% Load from session
function handles = loadFromSession(hObject,handles,session)
	setappdata(handles.f,'traces', session.tra_traces);
    
    if isempty(session.tra_traces) || any(~session.tra_traces.Calculated)
        handles.tra.preCalButton.Enable = 'on';
    else
        handles.tra.preCalButton.Enable = 'off';
    end
    
    setappdata(handles.f,'trace_mode', session.tra_mode);
    setappdata(handles.f,'trace_currentTrace', session.tra_currentTrace);
    set(handles.tra.currentDNATextBox, 'String', num2str(session.tra_currentTrace));
    
    set(handles.tra.cutSlider.JavaPeer, 'LowValue', session.tra_lowCut);
    set(handles.tra.cutSlider.JavaPeer, 'HighValue', session.tra_highCut);
    set(handles.tra.meanSlider.JavaPeer, 'Value', session.tra_mean);
    set(handles.tra.highCutTextBox, 'String', num2str(session.tra_highCut));
    set(handles.tra.lowCutTextBox, 'String', num2str(session.tra_lowCut));
    set(handles.tra.meanTextBox, 'String', num2str(session.tra_mean));
   
    set(handles.tra.hmmStatesSlider.JavaPeer, 'LowValue', session.tra_lowStates);
    set(handles.tra.hmmStatesSlider.JavaPeer, 'HighValue', session.tra_highStates);
    set(handles.tra.hmmStatesLowTextBox, 'String', num2str(session.tra_lowStates));
    set(handles.tra.hmmStatesHighTextBox, 'String', num2str(session.tra_highStates));
    
    handles.tra.removeBGCheckbox.Value = session.tra_removeBG;
    
    set(handles.tra.DAScale.JavaPeer, 'Value', session.tra_DAScale);
end

%% Updates
function onDisplay(hObject,handles,loadingSession)
    setappdata(handles.f,'mode','Traces');
    
    % get stack
    if getappdata(handles.f,'isMapped')
        seperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');
        vidMax = size(seperatedStacks{1},3);
    else
        seperatedStacks = getappdata(handles.f,'data_video_stack');
        vidMax = size(seperatedStacks,3);
    end
    
    % set sliders
    set(handles.tra.vidCurrentFrame.JavaPeer,'Maximum', vidMax);
    set(handles.tra.vidCurrentFrame.JavaPeer,'Value', getappdata(handles.f,'home_currentFrame'));
    handles.tra.cutSlider.JavaPeer.set('Maximum', vidMax);
    handles.tra.cutSlider.JavaPeer.set('HighValue', vidMax);
    handles.tra.cutSlider.JavaPeer.set('LowValue', 1);
    handles.tra.highCutTextBox.String = num2str(vidMax);
    handles.tra.lowCutTextBox.String = num2str(1);
    set(handles.tra.vidHBox,'Visible','on');
    
    % updates
    if ~exist('loadingSession','var') || ~loadingSession
        generateFRETTraces(hObject, handles);
    end
    updateMaxTraces(hObject, handles);
    setTrace(hObject,handles,1);
    setVidCurrentFrame(hObject, getappdata(handles.f,'home_currentFrame'));
    scale = handles.tra.DAScale.JavaPeer.get('Value') / handles.tra.DAScale.JavaPeer.get('Maximum')*10;
    scale = 10^-scale;
    axis(handles.tra.DAAxes, [1, vidMax, -scale*0.1, scale*1.1]);
    
    % key presses, these get turned off by onRelease
    set(handles.f,'WindowKeyPressFcn',@keyPressCallback);
    
    handles.rightPanel.Selection = 3;
    handles.rightPanel.Visible = 'on';
end

function onRelease(hObject,handles)
    handles.rightPanel.Selection = 1;
    
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    % key presses, these get turned on by onDisplay
    set(handles.f,'WindowKeyPressFcn','');
    
    homeInterface('openSelectFRET',hObject);
end

function updateDisplay(hObject,handles,videoOnlyFlag)
    if ~exist('handles')
        handles = guidata(hObject);
    end
    
    curFrame = getappdata(handles.f,'home_currentFrame');

    % Video image
    I = homeInterface('getCurrentOneAxesImage',hObject,handles);
    handles.tra.vidAxesAPI.replaceImage(I,'PreserveView',true);
    
    % Mark current video time with up arrow on traces
    handles.tra.curFrameArrowDA.set('Position',[curFrame 0]);
    handles.tra.curFrameArrowFRET.set('Position',[curFrame 0]);
    
    if ~exist('videoOnlyFlag','var') % this is excluded when playing the video        
        % Get required data
        c = getappdata(handles.f,'trace_currentTrace');
        traces = getappdata(handles.f,'traces');
        startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
        endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
        x = (startT:endT);
        
        % Calculate fret, background and hmm
        if ~traces.Calculated(c)
            hWaitBar = waitbar(0,'loading...', 'WindowStyle', 'modal');
            
            movMeanWidth    = handles.tra.meanSlider.JavaPeer.get('Value');
            minStates       = handles.tra.hmmStatesSlider.JavaPeer.get('LowValue');
            maxStates       = handles.tra.hmmStatesSlider.JavaPeer.get('HighValue');
            
            donorLimits     = getappdata(handles.f,'donorLimits');
            acceptorLimits  = getappdata(handles.f,'acceptorLimits');
            
            removeBG        = handles.tra.removeBGCheckbox.Value;
    
            traces(c,:) = calculateTraceData(traces(c,:), movMeanWidth, x, minStates, maxStates, donorLimits(2), acceptorLimits(2), removeBG);
            setappdata(handles.f,'traces',traces); % save
            
            delete(hWaitBar);
        end
        
        % Donor Trace
        handles.tra.DonorPlot.XData         = x;
        handles.tra.DonorPlot.YData         = traces.Donor(c,x);
        handles.tra.DonorStatePlot.XData    = x;
        handles.tra.DonorStatePlot.YData    = traces.Donor_hmm(c,x);
        
        % Acceptor Trace
        handles.tra.AcceptorPlot.XData      = x;
        handles.tra.AcceptorPlot.YData      = traces.Acceptor(c,x);
        handles.tra.AcceptorStatePlot.XData = x;
        handles.tra.AcceptorStatePlot.YData = traces.Acceptor_hmm(c,x);

        % FRET Trace
        handles.tra.FRETPlot.XData          = x;
        handles.tra.FRETPlot.YData          = traces.FRET(c,x);
        handles.tra.FRETStatePlot.XData     = x;
        handles.tra.FRETStatePlot.YData     = traces.FRET_hmm(c,x);
        axis(handles.tra.FRETAxes, [startT, endT, -0.05, 1.05]);
        
        % Video peak circle
        if isappdata(handles.f,'data_trace_plt')
            delete(getappdata(handles.f,'data_trace_plt'));
        end
        hold(handles.tra.vidAxes,'on');
        plt = viscircles(handles.tra.vidAxes, [traces.Center(c,:);traces.Center(c,:)], [traces.HalfWidth(c)/3,traces.HalfWidth(c)*2], 'Color', 'white', 'LineWidth', .1);
        hold(handles.tra.vidAxes,'off');
        setappdata(handles.f,'data_trace_plt',plt);
        mag = handles.tra.vidAxesAPI.getMagnification();
        handles.tra.vidAxesAPI.setMagnificationAndCenter(mag,traces.Center(c,1),traces.Center(c,2)); % center video scroll on current peak
    end
end

%% Selected Trace
function setTrace(hObject,handles,c)
    handles.tra.currentDNATextBox.String = num2str(c);
    setappdata(handles.f,'trace_currentTrace',c);
end

function prevTrace(hObject,handles)
    c = getappdata(handles.f,'trace_currentTrace');
    if c>1
        c=c-1;
    else
        c=1;
    end
    setTrace(hObject,handles,c);
    updateDisplay(hObject,handles);
end

function nextTrace(hObject,handles)
    max_c = size(getappdata(handles.f,'traces'),1);
    c = getappdata(handles.f,'trace_currentTrace');
    if c<max_c
        c=c+1;
    end
    setTrace(hObject,handles,c);
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

function currentTraceTextBoxCallback(hObject,handles,c)
    max_c = size(getappdata(handles.f,'traces'),1);
    c = round(c);
    if c>max_c && c<1
        c = getappdata(handles.f,'trace_currentTrace');
    end
    setTrace(hObject,handles,c);
    updateDisplay(hObject,handles);
end

function updateMaxTraces(hObject,handles)
    max_c = size(getappdata(handles.f,'traces'),1);
    handles.tra.maxTraceText.String = ['/' num2str(max_c)];
end

%% Play/pause Current Frame
function setVidCurrentFrame(hObject, value, videoOnlyFlag)
    handles = guidata(hObject);
    handles.tra.vidCurrentFrame.JavaPeer.set('Value', value);
    setappdata(handles.f,'home_currentFrame', value);
    
    if exist('videoOnlyFlag','var')
        updateDisplay(hObject,handles,videoOnlyFlag);
    else
        updateDisplay(hObject,handles);
    end
end

function playVideo(hObject,handles)
    % switch play button to pause button
    handles.tra.playButton.String = 'Pause';
    handles.tra.playButton.Callback = @(hObject,~) pauseVideo(hObject,guidata(hObject));
    
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
    handles.tra.playButton.String = 'Play';
    handles.tra.playButton.Callback = @(hObject,~) playVideo(hObject,guidata(hObject));
    
    % flag to stop play loop
    setappdata(handles.f,'Playing_Video',0);
end

%% Trace Data

function preCalculateAllTraces(hObject, handles)
    % Get data
    traces          = getappdata(handles.f,'traces');
    movMeanWidth    = handles.tra.meanSlider.JavaPeer.get('Value');
    startT          = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT            = handles.tra.cutSlider.JavaPeer.get('HighValue');
    x               = (startT:endT);
    numTraces       = size(traces,1);
    minStates       = handles.tra.hmmStatesSlider.JavaPeer.get('LowValue');
    maxStates       = handles.tra.hmmStatesSlider.JavaPeer.get('HighValue');
    donorLimits     = getappdata(handles.f,'donorLimits');
    acceptorLimits  = getappdata(handles.f,'acceptorLimits');
    removeBG        = handles.tra.removeBGCheckbox.Value;
    
    % run calcualtions
    uncalculatedTraces = ~traces.Calculated;
    parfor_progress(numTraces);
    parfor c=1:numTraces
        if uncalculatedTraces(c)
            traces(c,:) = calculateTraceData(traces(c,:), movMeanWidth, x, minStates, maxStates, donorLimits(2), acceptorLimits(2), removeBG);
        end
        
        parfor_progress;
    end
	parfor_progress(0);
        
    
    % save
    handles.tra.preCalButton.Enable = 'off';
    setappdata(handles.f,'traces',traces);
end

function trace = calculateTraceData(trace, movMeanWidth, x, minStates, maxStates, donorScale, acceptorScale, removeBG)
    % Get original traces
    Donor       = movmean(trace.Donor_raw(1,x), movMeanWidth);
    Acceptor    = movmean(trace.Acceptor_raw(1,x), movMeanWidth);

    % Hmm
    trace.Donor_hmm(1,x)       = vbFRETWrapper(Donor/donorScale, minStates, maxStates) * donorScale;
    trace.Acceptor_hmm(1,x)    = vbFRETWrapper(Acceptor/acceptorScale, minStates, maxStates) * acceptorScale;
    % Background
    trace.Donor_bg(1)          = min(trace.Donor_hmm(1,x));
    trace.Acceptor_bg(1)       = min(trace.Acceptor_hmm(1,x));
    if removeBG
        trace.Donor_hmm(1,x)       = trace.Donor_hmm(1,x) - trace.Donor_bg(1);
        trace.Acceptor_hmm(1,x)    = trace.Acceptor_hmm(1,x) - trace.Acceptor_bg(1);
        trace.Donor(1,x)           = Donor - trace.Donor_bg(1);
        trace.Acceptor(1,x)        = Acceptor - trace.Acceptor_bg(1);
    else
        trace.Donor(1,x)           = Donor;
        trace.Acceptor(1,x)        = Acceptor;
    end
    % Fret
    trace.FRET(1,x)            = trace.Acceptor(1,x) ./ (trace.Acceptor(1,x) + trace.Donor(1,x));
    noFRETInd                  = (trace.Donor_hmm(1,:)==0 | trace.Acceptor_hmm(1,:)==0);
    trace.FRET(noFRETInd)      = 0;
    trace.FRET_hmm(1,x)        = vbFRETWrapper(trace.FRET(1,x), minStates, maxStates);
    % Calculated
    trace.Calculated(1) = true;
end

%% Settings
function setScale(hObject,value)
    handles = guidata(hObject);
    ax = axis(handles.tra.DAAxes);        
    scale = 10^-value;
    axis(handles.tra.DAAxes,[ax(1), ax(2), -.1*scale, 1.01*scale]);
end

function setCut(hObject)
    handles = guidata(hObject);
    handles.tra.preCalButton.Enable = 'on';
    traces = getappdata(handles.f,'traces');
    
    low = handles.tra.cutSlider.JavaPeer.get('LowValue');
    high = handles.tra.cutSlider.JavaPeer.get('HighValue');
    handles.tra.lowCutTextBox.String = num2str(low);
    handles.tra.highCutTextBox.String = num2str(high);
    
    ax = axis(handles.tra.DAAxes);
    axis(handles.tra.DAAxes, [low, high, ax(3), ax(4)]);
    
    traces.Calculated  = zeros(size(traces,1),1,'logical');
    
    donorLimits = stretchlim(traces.Donor_raw(:,low:high));
    acceptorLimits = stretchlim(traces.Acceptor_raw(:,low:high));
    
    setappdata(handles.f,'donorLimits',donorLimits);
    setappdata(handles.f,'acceptorLimits',acceptorLimits);
    
    setappdata(handles.f,'traces',traces); % save first
    updateDisplay(hObject,handles);
end

function setHighCut(hObject)
    handles = guidata(hObject);
    handles.tra.preCalButton.Enable = 'on';
    traces = getappdata(handles.f,'traces');
    
    high = str2double(handles.tra.highCutTextBox.String);
    low = handles.tra.cutSlider.JavaPeer.get('LowValue');
    max_cut = handles.tra.cutSlider.JavaPeer.get('Maximum');
    high = max(low,high);
    high = min(high,max_cut);
    handles.tra.cutSlider.JavaPeer.set('HighValue',high);
    handles.tra.highCutTextBox.String = num2str(high);
    
    ax = axis(handles.tra.DAAxes);
    axis(handles.tra.DAAxes, [low, high, ax(3), ax(4)]);
    
    traces.Calculated  = zeros(size(traces,1),1,'logical');
    
    donorLimits = stretchlim(traces.Donor_raw(:,low:high));
    acceptorLimits = stretchlim(traces.Acceptor_raw(:,low:high));
    
    setappdata(handles.f,'donorLimits',donorLimits);
    setappdata(handles.f,'acceptorLimits',acceptorLimits);
    
    setappdata(handles.f,'traces',traces); % save first
    updateDisplay(hObject,handles);
end

function setLowCut(hObject)
    handles = guidata(hObject);
    handles.tra.preCalButton.Enable = 'on';
    traces = getappdata(handles.f,'traces');
    
    low = str2double(handles.tra.lowCutTextBox.String);
    high = handles.tra.cutSlider.JavaPeer.get('HighValue');
    low = min(low,high);
    low = max(low,1);
    handles.tra.cutSlider.JavaPeer.set('LowValue',low);
    handles.tra.lowCutTextBox.String = num2str(low);
    
    ax = axis(handles.tra.DAAxes);
    axis(handles.tra.DAAxes, [low, high, ax(3), ax(4)]);
    
    traces.Calculated  = zeros(size(traces,1),1,'logical');
    
    donorLimits = stretchlim(traces.Donor_raw(:,low:high));
    acceptorLimits = stretchlim(traces.Acceptor_raw(:,low:high));
    
    setappdata(handles.f,'donorLimits',donorLimits);
    setappdata(handles.f,'acceptorLimits',acceptorLimits);
    
    setappdata(handles.f,'traces',traces); % save first
    updateDisplay(hObject,handles);
end

function setMean_Textbox(hObject)
    handles = guidata(hObject);
    handles.tra.preCalButton.Enable = 'on';
    traces = getappdata(handles.f,'traces');
    
    value_min = handles.tra.meanSlider.JavaPeer.get('Minimum');
    value_max = handles.tra.meanSlider.JavaPeer.get('Maximum');
    value = str2double(handles.tra.meanTextBox.String);
    value = round(value);
    value = max(value,value_min);
    value = min(value,value_max);
    handles.tra.meanSlider.JavaPeer.set('Value',value);
    handles.tra.meanTextBox.String = num2str(value);
    
    traces.Calculated  = zeros(size(traces,1),1,'logical');
    setappdata(handles.f,'traces',traces); % save first
    updateDisplay(hObject,handles);
end

function setMean_Slider(hObject)
    handles = guidata(hObject);
    handles.tra.preCalButton.Enable = 'on';
    traces = getappdata(handles.f,'traces');
    
    value     = handles.tra.meanSlider.JavaPeer.get('Value');
    handles.tra.meanTextBox.String = num2str(value);
    
    traces.Calculated  = zeros(size(traces,1),1,'logical');
    
    setappdata(handles.f,'traces',traces); % save first
    updateDisplay(hObject,handles);
end

function setRemoveBG(hObject)
    handles = guidata(hObject);
    
    % reset all pre-calculations
    handles.tra.preCalButton.Enable = 'on';
    traces = getappdata(handles.f,'traces');
    traces.Calculated  = zeros(size(traces,1),1,'logical');
    setappdata(handles.f,'traces',traces); % save before updating
    
    updateDisplay(hObject,handles);
end

%% HMM Settings
function setHMMStates_LowTextBox(hObject)
    handles = guidata(hObject);
    
    low = str2double(handles.tra.hmmStatesLowTextBox.String);
    handles.tra.hmmStatesSlider.JavaPeer.set('LowValue',low);
    
    setHMMStates_Slider(hObject);
end

function setHMMStates_HighTextBox(hObject)
    handles = guidata(hObject);
    
    high = str2double(handles.tra.hmmStatesHighTextBox.String);
    handles.tra.hmmStatesSlider.JavaPeer.set('HighValue',high);
    
    setHMMStates_Slider(hObject);
end

function setHMMStates_Slider(hObject)
    handles = guidata(hObject);
    handles.tra.preCalButton.Enable = 'on';
    traces = getappdata(handles.f,'traces');
        
    low = handles.tra.hmmStatesSlider.JavaPeer.get('LowValue');
    high = handles.tra.hmmStatesSlider.JavaPeer.get('HighValue');
    handles.tra.hmmStatesLowTextBox.String = num2str(low);
    handles.tra.hmmStatesHighTextBox.String = num2str(high);
    
    traces.Calculated  = zeros(size(traces,1),1,'logical');
    setappdata(handles.f,'traces',traces); % save first
    updateDisplay(hObject,handles);
end

%% Exports
function exportTraces(hObject,handles)
    preCalculateAllTraces(hObject, handles);
    
    % get relevent data
    traces = getappdata(handles.f,'traces');
    startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
    x = (startT:endT);
    savePath = getappdata(handles.f,'savePath');
    
    % Set save path to be in a folder "traces".
    % Add this folder to the save directory.
    % If this folder alread exist remove it then add it.
    
    mkdir(savePath,'traces');
    rmdir([savePath, '/traces/'], 's');
    mkdir(savePath,'traces');
    savePath = [savePath, '/traces/'];
    
    % export each trace to the traces folder with one file per molecule
    for i=1:size(traces,1)
        A = [x', traces.Donor(i,x)', traces.Acceptor(i,x)', traces.FRET(i,x)',...
            traces.Donor_hmm(i,x)', traces.Acceptor_hmm(i,x)', traces.FRET_hmm(i,x)']; % create matix of data to save
        
        fileID = fopen([savePath,'trace_', num2str(i), '.dat'],'w'); % create file trace_i.txt
        fprintf(fileID,'%36s   %36s   %36s   %36s   %36s   %36s   %36s\n','X','Donor','Acceptor','FRET','Donor HMM','Acceptor HMM','FRET HMM'); % add header
        fprintf(fileID,'%+30.30e   %+30.30e   %+30.30e   %+30.30e   %+30.30e   %+30.30e   %+30.30e\r\n',A'); % add data
        fclose(fileID); % close
    end
end

function exportTraceImages(hObject,handles)
    preCalculateAllTraces(hObject, handles);
    
    % get relevent data
    currentTrace = getappdata(handles.f,'trace_currentTrace');
    traces = getappdata(handles.f,'traces');
    startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
    x = (startT:endT);
    savePath = getappdata(handles.f,'savePath');
    
    % Set save path to be in a folder "traces".
    % Add this folder to the save directory.
    % If this folder alread exist remove it then add it.
    mkdir(savePath,'trace_images');
    rmdir([savePath, '/trace_images/'], 's');
    mkdir(savePath,'trace_images');
    savePath = [savePath, '/trace_images/'];
    
    % export each trace to the traces folder with one file per molecule
    hWaitBar = waitbar(0,'Exporting trace images ...', 'WindowStyle', 'modal');
    for i=1:size(traces,1)
        waitbar(i/size(traces,1));
        
        setTrace(hObject,handles,i);
        updateDisplay(hObject,handles);
        
        tempFig = figure(2);
        tempFig.Visible = "off";
        set(tempFig, 'WindowStyle', 'normal');
        tempFig.Units = 'inches';
        tempFig.Position = [0 0 8.5 5.5];
        hplot1 = copyobj(handles.tra.DAAxes,tempFig);
        hplot2 = copyobj(handles.tra.FRETAxes,tempFig);
        hplot1.set('Units','inches');
        hplot2.set('Units','inches');
        hplot1.set('Position',[.5 3. 7.5 2.]);
        hplot2.set('Position',[.5 .5 7.5 2.]);
        saveas(tempFig,[savePath,'trace_', num2str(i), '.png'])
        close(tempFig);
    end
    
    % switch back to showing current trace
    setTrace(hObject,handles,currentTrace);
    updateDisplay(hObject,handles);
    
    delete(hWaitBar);
end

function showDwellTime(hObject, handles)
    preCalculateAllTraces(hObject, handles);
    
    % get relevent data
    traces = getappdata(handles.f,'traces');
    startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
    x = (startT:endT);
    
    % set up a serperate figure
    if isfield(handles,'f2')
        delete(handles.f2);
    end
    handles.f2 = figure(2);
    ax = axes(handles.f2);
    
    % plot the 3 dwell times
    binSize = 200;
    ax1 = subplot(1, 3, 1, ax); % left
    title(ax1, "Donor");
    donorData = traces.Donor(:,x);
    histogram(ax1, donorData(:), binSize);
    
    ax2 = subplot(1, 3, 2); % middle
    title(ax2, "Acceptor");
    acceptorData = traces.Acceptor(:,x);
    histogram(ax2, acceptorData(:), binSize);
    
    ax3 = subplot(1, 3, 3); % right
    title(ax3, "FRET");
    fretData = traces.FRET(:,x);
    histogram(ax3, fretData(:), binSize);
    
    % save the handle
    guidata(hObject,handles);
end

function exportTransCounts(hObject, handles)
    preCalculateAllTraces(hObject, handles);
    
    % get relevent data
    traces = getappdata(handles.f,'traces');
    startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
    x = (startT:endT);
    savePath = getappdata(handles.f,'savePath');
    
    fileID = fopen([savePath,'/transition_counts.dat'],'w'); % create file
    fprintf(fileID,'%12s   %12s   %12s   %12s\n','Molecule','Donor','Acceptor','FRET'); % add header
    
    % write counts to file with one line per molecule
    for i=1:size(traces,1)
        % count the number of transitions excluding "half transitions"
        donorCount = floor( sum(diff(traces.Donor_hmm(i,x))~=0) / 2 );
        acceptorCount = floor( sum(diff(traces.Acceptor_hmm(i,x))~=0) / 2 );
        fretCount = floor( sum(diff(traces.FRET_hmm(i,x))~=0) / 2 );
        
        fprintf(fileID,'%12u   %12u   %12u   %12u\r\n', i, donorCount, acceptorCount, fretCount); % add data
    end
    
    fclose(fileID); % close
end

function showTDP(hObject, handles)
    %% Setups
    preCalculateAllTraces(hObject, handles);

    % get all the trace data
    traces = getappdata(handles.f,'traces');
    startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
    T = (startT:endT);
    
    % setup the histogram grid
    gridSpacing = 1000;
    [X, Y] = meshgrid(1:gridSpacing);
    X = X/gridSpacing;
    Y = Y/gridSpacing;
    
    % setup the 2d-gaussian
    sig = 0.005;
    gauss2d = @(x0,y0) exp( -((X-x0).^2 + (Y-y0).^2) / (2*sig^2) );
        
    %% Calculation
    fret = traces.FRET_hmm(:,T); % grab all the FRET traces in one matrix
    diffrences = diff(fret,1,2); % calculate transition locations
    
    % only keep traces with atleast 1 transition
    goodLocs  = find(any(diffrences,2));
    goodDiffs = diffrences(goodLocs,:); 
    fret      = fret(goodLocs,:);

    TDPArray = zeros(size(goodDiffs,1),gridSpacing,gridSpacing); % pre-aloc
    parfor i=1:size(goodDiffs,1)
        loc = find(goodDiffs(i,:));
        start = fret(i,loc);
        stop  = fret(i,loc+1);
        
        TDP = zeros(gridSpacing); % pre-aloc
        for j=1:size(start,2)
             TDP = TDP + gauss2d(start(j),stop(j));
        end
        TDPArray(i,:,:) = TDP;
    end
    
    TDP = shiftdim(sum(TDPArray,1));
    
    handles.f2 = figure(2);
    surf(X,Y,TDP);
    xlabel('FRET Before Transision');
    ylabel('FRET After Transision');
    shading interp;
end

function showPSH(hObject, handles)
    %% Setups
    preCalculateAllTraces(hObject, handles);

    % get all the trace data
    traces = getappdata(handles.f,'traces');
    startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
    T = (startT:endT);
    
    %% Calculation
    fret  = traces.FRET_hmm(:,T); % grab all the FRET traces in one matrix
    times = repmat(1:length(T),size(fret,1),1);
    [N, X, Y] = histcounts2(times(:),fret(:),1:3:length(T), 0:.05:1);
    X = movmean(X,2,'Endpoints','discard'); % convert endpoints to centers
    Y = movmean(Y,2,'Endpoints','discard'); % convert endpoints to centers
    X = repmat(X, size(Y,2), 1); % convert to meshgrid
    Y = repmat(Y', 1, size(X,2)); % convert to meshgrid
    
    %% Display
    handles.f2 = figure(2);
    surf(X,Y,N');
    xlabel('Time');
    ylabel('FRET');
    shading interp;
end