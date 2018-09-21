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
    handles.tra.cutSlider.JavaPeer.set('MouseReleasedCallback', @(~,~) setCut(handles.tra.cutSlider));
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
    handles.tra.meanSlider.JavaPeer.set('MouseReleasedCallback', @(~,~) setMean_Slider(handles.tra.meanSlider));
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
                                        
    % hide hidden groups
    handles.tra.skipHiddenGroups = uicontrol(  'Parent', handles.tra.selectionBox,...
                                               'Style' , 'Checkbox', ...
                                               'Value', 0,...
                                               'String', 'Skip hidden groups',...
                                               'Callback', @(hObject,~) updateDisplay(hObject,guidata(hObject)));
                                    
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
    handles.tra.hmmStatesSlider.JavaPeer.set('MouseReleasedCallback', @(~,~) setHMMStates_Slider(handles.tra.hmmStatesSlider));
    handles.tra.hmmStatesHighTextBox = uicontrol(   'Parent', handles.tra.hmmStatesBox,...
                                                    'String', '2',...
                                                    'Style', 'edit',...
                                                    'Callback', @(hObject,~) setHMMStates_HighTextBox(hObject));
    handles.tra.hmmStatesBox.set('Widths',[30, -1, 30]);
    
    %% Grouping
    handles.tra.group = struct();
    handles.tra.group.panel = uix.BoxPanel(  'Parent', handles.tra.leftPanel,...
                                            'Title','Groups',...
                                            'Padding',5);
    handles.tra.group.box = uix.VBox('Parent', handles.tra.group.panel);
    
    % group names
    handles.tra.group.groupNameBox = uix.VBox('Parent', handles.tra.group.box);
    handles.tra.group.grid = uix.Grid('Parent', handles.tra.group.groupNameBox);
    
    % group headers
    uicontrol( 'Parent', handles.tra.group.grid,...
               'String', 'Show Group',...
               'Style', 'text');
    uicontrol( 'Parent', handles.tra.group.grid,...
               'String', 'Name',...
               'Style', 'text');
    uicontrol( 'Parent', handles.tra.group.grid,...
                'String', 'Size',...
                'Style', 'text');
    uicontrol( 'Parent', handles.tra.group.grid,...
                'String', 'Selected',...
                'Style', 'text');
    uicontrol( 'Parent', handles.tra.group.grid,...
                'String', 'Set Rule',...
                'Style', 'text');
    uicontrol( 'Parent', handles.tra.group.grid,...
                'String', 'Remove',...
                'Style', 'text');
            
    setappdata(handles.f,'trace_groupHandles',cell(0,6));
            
    handles.tra.group.grid.set('Heights',25);
    handles.tra.group.grid.set('Widths',[-1 -1 -1 -1 -1 -1]);
    
    uicontrol( 'Parent', handles.tra.group.box,...
               'String', 'Add group',...
               'Callback', @(hObject,~) addGroup(hObject,guidata(hObject)));
           
    handles.tra.group.box.set('heights', [150, 25]);
    
    %% Exports
    handles.tra.export = struct;
    handles.tra.export.panel = uix.BoxPanel(  'Parent', handles.tra.leftPanel,...
                                              'Title','Export',...
                                              'Padding',5);
    handles.tra.export.box = uix.VBox('Parent', handles.tra.export.panel);
                                       
    % drop menu                   
    handles.tra.export.menu = uicontrol('Parent', handles.tra.export.box,...
                                        'Style', 'popupmenu',...
                                        'String', { 'Export Traces',...
                                                    'Export Images of Traces',...
                                                    'Histograms',...
                                                    'HMM Histograms',...
                                                    'Transition Density',...
                                                    'Transition Count',...
                                                    'Post-sync'});
    % exclude zero data                                            
    handles.tra.export.excludeZeros = uicontrol('Parent', handles.tra.export.box,...
                                                'String', 'Exclude zero data',...
                                                'Style', 'checkbox');
                                                
    % button box
    handles.tra.export.buttonBox = uix.HButtonBox( 'Parent', handles.tra.export.box,...
                                                   'ButtonSize', [60 30],...
                                                   'Spacing', 30);
    % display button
    handles.tra.export.dispaly = uicontrol( 'Parent', handles.tra.export.buttonBox,...
                                            'String', 'Display',...
                                            'Callback', @(hObject,~) displayAnalysis(hObject,guidata(hObject)));
    % export button
    handles.tra.export.export = uicontrol(  'Parent', handles.tra.export.buttonBox,...
                                            'String', 'Export',...
                                            'Callback', @(hObject,~) exportAnalysis(hObject,guidata(hObject)));
                           
    %% 
    handles.tra.leftPanel.set('Heights',[25 200 110 75 203 100]);
    
    
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
                                   
                                   
    % play speed
    handles.tra.playSpeed = uicontrol(  'Parent', handles.tra.vidHBox, ...
                                        'Style','edit',...
                                        'String','1',...
                                        'Callback', @(hObject,~) setPlaySpeed(hObject,guidata(hObject),str2double(hObject.String)));
    % slider
    [~, handles.tra.vidCurrentFrame] = javacomponent('javax.swing.JSlider');
    handles.tra.vidCurrentFrame.set('Parent', handles.tra.vidHBox);
    handles.tra.vidCurrentFrame.JavaPeer.set('Maximum', 2);
    handles.tra.vidCurrentFrame.JavaPeer.set('Minimum', 1);
    handles.tra.vidCurrentFrame.JavaPeer.set('Value', 1);
    handles.tra.vidCurrentFrame.JavaPeer.set('StateChangedCallback',...
        @(~,~) setVidCurrentFrame(handles.tra.vidCurrentFrame, get(handles.tra.vidCurrentFrame.JavaPeer,'Value')));
    % frame number
    handles.tra.currentFrameTextbox = uicontrol('Parent', handles.tra.vidHBox, ...
                                                'Style','edit',...
                                                'String','1',...
                                                'Callback', @(hObject,~) setVidCurrentFrame(hObject,str2double(hObject.String)));
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
    handles.tra.vidHBox.set('Widths',[50, 30, -1, 50]);
    handles.tra.vidVBox.set('Heights',[25 -1]);
    vidMagBoxPos = get(handles.tra.vidMagBox,'Position');
    set(handles.tra.vidMagBox,'Position',[0 0 vidMagBoxPos(3) vidMagBoxPos(4)]);
    
    %% Graphs
    % grid
    handles.tra.graphGrid = uix.GridFlex('Parent', handles.tra.graphPanel, 'Spacing', 5);
    
    handles.tra.DAScaleBox = uix.VBox('Parent', handles.tra.graphGrid);
    
    uicontrol('Parent', handles.tra.DAScaleBox,...
              'String', 'Auto',...
              'Style', 'text');
    
    handles.tra.DAScaleAuto = uicontrol('Parent', handles.tra.DAScaleBox,...
                                        'String', '',...
                                        'Style', 'Checkbox');
    
    [~, handles.tra.DAScale] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.tra.DAScale.set('Parent', handles.tra.DAScaleBox);
    handles.tra.DAScale.JavaPeer.set('Maximum', 11e6);
    handles.tra.DAScale.JavaPeer.set('Minimum', 0);
    handles.tra.DAScale.JavaPeer.set('LowValue', 0);
    handles.tra.DAScale.JavaPeer.set('HighValue', 11e6);
    handles.tra.DAScale.JavaPeer.set('StateChangedCallback', @(~,~) setScale(handles.tra.DAScale,...
        handles.tra.DAScale.JavaPeer.get('LowValue')/handles.tra.DAScale.JavaPeer.get('Maximum')*11,...
        handles.tra.DAScale.JavaPeer.get('HighValue')/handles.tra.DAScale.JavaPeer.get('Maximum')*11));
    handles.tra.DAScale.JavaPeer.set('Orientation',handles.tra.DAScale.JavaPeer.VERTICAL);
    
    handles.tra.DAScaleBox.set('Heights',[15 15 -1]);
    
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
    handles.tra.DonorStatePlot.LineWidth    = 2;
    handles.tra.AcceptorStatePlot.LineWidth = 2;
    
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
    handles.tra.skipHiddenGroups.Value = 0; % initally set to 0, session value set last
    
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
    
    handles.tra.DAScaleAuto.Value = session.tra_DAScaleAuto;
    set(handles.tra.DAScale.JavaPeer, 'LowValue', session.tra_DAScale(1));
    set(handles.tra.DAScale.JavaPeer, 'HighValue', session.tra_DAScale(2));
    
    handles.tra.playSpeed.String = num2str(session.playSpeed);
    
    %% groups
    % remove old groups
    delete(handles.tra.group.grid.Children(7:size(handles.tra.group.grid.Children,1)));
    setappdata(handles.f,'trace_groupHandles',cell(0,6));
    
    % add groups from session
    for i = 1:size(session.tra_groups,1)
        addGroup(hObject,handles,1);
        
        groupHandles = getappdata(handles.f,'trace_groupHandles');
        
        groupHandles{i,1}.set('Value', session.tra_groups{i,1});
        groupHandles{i,2}.set('String', session.tra_groups{i,2});
        groupHandles{i,3}.set('String', session.tra_groups{i,3});
        
        setappdata(handles.f,'trace_groupHandles',groupHandles);
    end
    
    handles.tra.skipHiddenGroups.Value = session.tra_skipHiddenGroups;
    
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
    setScale(hObject, ...
        handles.tra.DAScale.JavaPeer.get('LowValue') / ...
        handles.tra.DAScale.JavaPeer.get('Maximum')*11, ...
        handles.tra.DAScale.JavaPeer.get('HighValue') / ...
        handles.tra.DAScale.JavaPeer.get('Maximum')*11)
    ax = axis(handles.tra.DAAxes);
    axis(handles.tra.DAAxes, [1, vidMax, ax(3), ax(4)]);
    
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
        %% Get required data
        c = getappdata(handles.f,'trace_currentTrace');
        traces = getappdata(handles.f,'traces');
        startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
        endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
        x = (startT:endT);
        
        %% check everything is loaded
        if isempty(traces)
            return;
        end
        
        %% Group Selection
        % skip if this group is hidden
        if handles.tra.skipHiddenGroups.Value
            shownTraceIdx = getShownTraces(hObject, handles);
            
            if ~shownTraceIdx(c) % Is this traces hidden?
                % Then goto next trace shown trace                
                
                if ~any(shownTraceIdx) % Are all the traces currently hidden?
                    handles.tra.skipHiddenGroups.Value = 0;
                    uiwait(msgbox('All traces hidden'));
                else
                    % Find the next traces that is next in order
                    shownTraces = find(shownTraceIdx);
                    if any(shownTraces>c)
                        shownTraces = shownTraces(shownTraces>c);
                        nextTrace = shownTraces(1);
                    else
                        nextTrace = shownTraces(1);
                    end
                    setTrace(hObject,handles,nextTrace);
                    updateDisplay(hObject,handles);
                end
                return;
            end
        end
        
        % Diplay selected groups
        groupHandles = getappdata(handles.f,'trace_groupHandles');
        numGroups = size(groupHandles,1);
        for i = 1:numGroups
            groupHandles{i,4}.set('Value',traces.Groups(c,i));
        end
        setappdata(handles.f,'trace_groupHandles',groupHandles);
        
        %% Calculate fret, background and HMM
        if ~traces.Calculated(c)
            hWaitBar = waitbar(0,'loading...', 'WindowStyle', 'modal');
            
            movMeanWidth    = handles.tra.meanSlider.JavaPeer.get('Value');
            minStates       = handles.tra.hmmStatesSlider.JavaPeer.get('LowValue');
            maxStates       = handles.tra.hmmStatesSlider.JavaPeer.get('HighValue');
            
            donorLimits     = getappdata(handles.f,'donorLimits');
            acceptorLimits  = getappdata(handles.f,'acceptorLimits');
            
            if isempty(donorLimits)
                return;
            end
            
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
                
        %% Auto scale axes if applicable
        if handles.tra.DAScaleAuto.Value
            lowDAV = min([traces.Donor(c,x), traces.Acceptor(c,x)])  * 0.9;
            highDAV = max([traces.Donor(c,x), traces.Acceptor(c,x)]) * 1.1;
            
            highscalefix = 11-log10(1.1); % ensures max highvalue gives a scale of 1.1
            highDA = log10(highDAV)+highscalefix;
            lowDA  = (lowDAV*10/highDAV)+1;
            
            handles.tra.DAScale.JavaPeer.set('LowValue',lowDA * handles.tra.DAScale.JavaPeer.get('Maximum')/11);
            handles.tra.DAScale.JavaPeer.set('HighValue',highDA * handles.tra.DAScale.JavaPeer.get('Maximum')/11);
            handles.tra.DAScale.JavaPeer.set('LowValue',lowDA * handles.tra.DAScale.JavaPeer.get('Maximum')/11); % do it twise incase high is initaly lower
            
            setScale(hObject,lowDA,highDA);
        end
    end
end

%% Groups
function saveTraceGroups(hObject,handles)
    traces = getappdata(handles.f,'traces');
    c = getappdata(handles.f,'trace_currentTrace');
    groupHandles = getappdata(handles.f,'trace_groupHandles');
    
    numGroups = size(groupHandles,1);
    
    for i = 1:numGroups
        traces.Groups(c,i) = groupHandles{i,4}.get('Value');
    end
    
    % update the group counts
    for i = 1:numGroups
        groupHandles{i,3}.set('String', num2str(sum(traces.Groups(:,i))));
    end
    
    setappdata(handles.f,'traces',traces);
    setappdata(handles.f,'trace_groupHandles',groupHandles);
    updateDisplay(hObject,handles);
end

function addGroup(hObject,handles,loadingFlag)
    groupHandles = getappdata(handles.f,'trace_groupHandles');
    
    numRows = size(groupHandles,1) + 1;
    
    if numRows > 5
        uiwait(msgbox('Only 5 groups allowed.'));
        return;
    end
    
    % show
    groupHandles{numRows, 1} = uicontrol(   'Parent', handles.tra.group.grid,...
                                            'Style', 'Checkbox',...
                                            'Value', 1,...
                                            'Callback', @(hObject,~) updateDisplay(hObject,guidata(hObject)));
    
    % names
    groupHandles{numRows, 2} = uicontrol(   'Parent', handles.tra.group.grid,...
                                            'Style', 'edit',...
                                            'String', ['Group ' num2str(numRows)]);
                                        
    % size
    groupHandles{numRows, 3} = uicontrol(   'Parent', handles.tra.group.grid,...
                                            'Style', 'text',...
                                            'String', '0');
    % selected
    groupHandles{numRows, 4} = uicontrol(   'Parent', handles.tra.group.grid,...
                                            'Style', 'Checkbox',...
                                            'Value', 0,...
                                            'Callback', @(hObject,~) saveTraceGroups(hObject,guidata(hObject)));
                                        
    % rule
    groupHandles{numRows, 5} = uicontrol(   'Parent', handles.tra.group.grid,...
                                            'Callback', @(hObject,~) setGroupRule(hObject,numRows),...
                                            'String', 'Set');
                                        
    % delete
    groupHandles{numRows, 6} = uicontrol(   'Parent', handles.tra.group.grid,...
                                            'Callback', @(hObject,~) deleteGroup(hObject,numRows),...
                                            'String', 'X');
    
    handles.tra.group.grid.set('Widths',[-1 -1 -1 -1 -1 -1]);
    handles.tra.group.grid.set('Heights',ones(1,numRows+1)*25);
    
    numOrderedObj = size(handles.tra.group.grid.Contents,1)-6;
    groupSeq = [reshape(1:numOrderedObj,numOrderedObj/6,6); numOrderedObj+1:numOrderedObj+6];
    handles.tra.group.grid.Contents = handles.tra.group.grid.Contents(groupSeq(:));
    
    setappdata(handles.f,'trace_groupHandles',groupHandles);
    
    if ~exist('loadingFlag','var') || ~loadingFlag
        traces = getappdata(handles.f,'traces');
        traces.Groups = [traces.Groups, zeros(size(traces,1),1,'logical')];
        setappdata(handles.f,'traces',traces);
    end
end

function setGroupRule(hObject,rowNum)
    handles = guidata(hObject);
    
    % check if all traces have been calculated
    traces = getappdata(handles.f,'traces');
    if any(~traces.Calculated)
        uiwait(msgbox('Pre-calculate traces first.'));
        return;
    end

    % promp user
    groupHandles = getappdata(handles.f,'trace_groupHandles');
    prompt = ['Set group rule for ' groupHandles{rowNum,1}.get('String')];
    ansArray = inputdlg(    prompt,... % prompt
                            '',... % title
                            [3 50]); % dims
    if isempty(ansArray) % user selects cancel
        return;
    end
    rule = ansArray{1};
    
    
    % evluate prompt
    traces = getappdata(handles.f,'traces');
    results = eval(rule);
    traces.Groups(:,rowNum) = results;
    setappdata(handles.f,'traces',traces);
    c = getappdata(handles.f,'trace_currentTrace');
    groupHandles{rowNum,4}.set('Value',results(c));
    saveTraceGroups(hObject,handles);
    updateDisplay(hObject,handles);
end

function deleteGroup(hObject,rowNum)
    handles = guidata(hObject);
    groupHandles = getappdata(handles.f,'trace_groupHandles');
    
    numRows = size(groupHandles,1) - 1;
        
    delete(groupHandles{rowNum, 1});
    delete(groupHandles{rowNum, 2});
    delete(groupHandles{rowNum, 3});
    delete(groupHandles{rowNum, 4});
    delete(groupHandles{rowNum, 5});
    delete(groupHandles{rowNum, 6});
    groupHandles(rowNum, :) = [];
    
    for i = rowNum:numRows
        groupHandles{i, 6}.set('Callback',@(gObject,~) deleteGroup(gObject,i));
    end
    
    handles.tra.group.grid.set('Widths',[-1 -1 -1 -1 -1 -1]);
    handles.tra.group.grid.set('Heights',ones(1,numRows+1)*25);
    setappdata(handles.f,'trace_groupHandles',groupHandles);
    
    
    traces = getappdata(handles.f,'traces');
    traces.Groups(:,rowNum) = [];
    setappdata(handles.f,'traces',traces);
    saveTraceGroups(hObject,handles);
end

function shownTraceIdx = getShownTraces(hObject, handles)
    traces = getappdata(handles.f,'traces');
    if handles.tra.skipHiddenGroups.Value
        groupHandles = getappdata(handles.f,'trace_groupHandles');
        numGroups = size(groupHandles,1);

        shownGroups = zeros(numGroups,1,'logical'); % pre-aloc
        for i = 1:numGroups
            shownGroups(i) = logical(groupHandles{i,1}.get('Value'));
        end

        shownTraceIdx = any(traces.Groups(:,shownGroups),2);
    else
        shownTraceIdx = ones(1,size(traces,1),'logical');
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
    
    % if skiping hidden groups check for prev group
    if handles.tra.skipHiddenGroups.Value
        shownTraceIdx = getShownTraces(hObject, handles);

        if ~shownTraceIdx(c) % Is this traces hidden?
            % Then goto next trace shown trace                

            if ~any(shownTraceIdx) % Are all the traces currently hidden?
                handles.tra.skipHiddenGroups.Value = 0;
                uiwait(msgbox('All traces hidden'));
            else
                % Find the prev traces that is prev in order
                allShownTraces = find(shownTraceIdx);
                if any(allShownTraces<c)
                    shownTrace = allShownTraces(allShownTraces<c);
                    nextTrace = shownTrace(end);
                else
                    nextTrace = allShownTraces(end);
                end
                setTrace(hObject,handles,nextTrace);
                updateDisplay(hObject,handles);
            end
            return;
        end
    end
    
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
    handles.tra.currentFrameTextbox.set('String', num2str(value));
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
        playSpeed = getappdata(handles.f,'playSpeed');
        if currentFrame+playSpeed <= handles.tra.vidCurrentFrame.JavaPeer.get('Maximum')
            currentFrame = currentFrame+playSpeed;
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

function setPlaySpeed(hObject, handles, value)
    value = min(value,100);
    value = max(value,1);
    
    setappdata(handles.f, 'playSpeed', value);
    handles.tra.playSpeed.String = num2str(value);
    handles.axesControl.playSpeed.String = num2str(value);
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

%% DAScale
function setScale(hObject,lowvalue,highvalue)
    handles = guidata(hObject);
    ax = axis(handles.tra.DAAxes); 
    
    highscalefix = 11-log10(1.1); % ensures max highvalue gives a scale of 1.1
    highscale = 10^-(highscalefix-highvalue);
    lowscale = ((lowvalue-1)*highscale/10);
    
    axis(handles.tra.DAAxes,[ax(1), ax(2), lowscale, highscale]);
end

%% Settings
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
    
    if isempty(donorLimits) 
        return; 
    end
    
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
% Button Callbacks
function displayAnalysis(hObject,handles)
    % check if all traces have been calculated
    traces = getappdata(handles.f,'traces');
    if any(~traces.Calculated)
        uiwait(msgbox('Pre-calculate traces first.'));
        return;
    end
    
    exportFlag = false;
    
    switch handles.tra.export.menu.String{handles.tra.export.menu.Value}
        case 'Export Traces'
            uiwait(msgbox('Only for export.'));
        case 'Export Images of Traces'
            uiwait(msgbox('Only for export.'));
        case 'Histograms'
            analysisHistograms(hObject, handles, exportFlag, false);
        case 'HMM Histograms'
            analysisHistograms(hObject, handles, exportFlag, true);
        case 'Trasition Density'
            displayTDP(hObject, handles);
        case 'Transition Count'
            uiwait(msgbox('Only for export.'));
        case 'Post-sync'
            displayPSH(hObject, handles);
    end
end

function exportAnalysis(hObject,handles)
    % check if all traces have been calculated
    traces = getappdata(handles.f,'traces');
    if any(~traces.Calculated)
        uiwait(msgbox('Pre-calculate traces first.'));
        return;
    end
    
    exportFlag = true;
    
    switch handles.tra.export.menu.String{handles.tra.export.menu.Value}
        case 'Export Traces'
            exportTraces(hObject,handles);
        case 'Export Images of Traces'
            exportTraceImages(hObject,handles);
        case 'Histograms'
            analysisHistograms(hObject, handles, exportFlag, false);
        case 'HMM Histograms'
            analysisHistograms(hObject, handles, exportFlag, true);
        case 'Trasition Density'
            uiwait(msgbox('Only for display.'));
        case 'Transition Count'
            exportTransCounts(hObject, handles);
        case 'Post-sync'
            uiwait(msgbox('Only for display.'));
    end
end

%% Export Analysis
% Trace
function exportTraces(hObject,handles)
    % ask user where to save
    savePath = getappdata(handles.f,'savePath');
    savePath = uigetdir(savePath);
    
    % get relevent data
    traces = getappdata(handles.f,'traces');
    shownTraceIdx = find(getShownTraces(hObject, handles)');
    startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
    x = (startT:endT);
    
    % export each trace to the traces folder with one file per molecule
    for i = shownTraceIdx
        A = [x', traces.Donor(i,x)', traces.Acceptor(i,x)', traces.FRET(i,x)',...
            traces.Donor_hmm(i,x)', traces.Acceptor_hmm(i,x)', traces.FRET_hmm(i,x)']; % create matix of data to save
        
        fileID = fopen([savePath,'/trace_', num2str(i), '.dat'],'w'); % create file trace_i.txt
        fprintf(fileID, '%36s   %36s   %36s   %36s   %36s   %36s   %36s\n',...
                        'X','Donor','Acceptor','FRET','Donor HMM','Acceptor HMM','FRET HMM'); % add header
        fprintf(fileID,'%+30.30e   %+30.30e   %+30.30e   %+30.30e   %+30.30e   %+30.30e   %+30.30e\r\n',A'); % add data
        fclose(fileID); % close
    end
end

% Trace Images
function exportTraceImages(hObject,handles)    
    % ask user where to save
    savePath = getappdata(handles.f,'savePath');
    savePath = uigetdir(savePath);
    
    % get relevent data
    traces = getappdata(handles.f,'traces');
    shownTraceIdx = find(getShownTraces(hObject, handles)');
    currentTrace = getappdata(handles.f,'trace_currentTrace');
    
    % export each trace to the traces folder with one file per molecule
    hWaitBar = waitbar(0,'Exporting trace images ...', 'WindowStyle', 'modal');
    for i = shownTraceIdx
        waitbar(i/size(traces,1));
        
        setTrace(hObject,handles,i);
        updateDisplay(hObject,handles);
        
        tempFig = figure;
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
        saveas(tempFig,[savePath,'/trace_', num2str(i), '.png'])
        close(tempFig);
    end
    
    % switch back to showing current trace
    setTrace(hObject,handles,currentTrace);
    updateDisplay(hObject,handles);
    
    delete(hWaitBar);
end

% Histograms
function analysisHistograms(hObject, handles, exportFlag, hmmFlag)    
    % get relevent data
    traces = getappdata(handles.f,'traces');
    shownTraceIdx = getShownTraces(hObject, handles);
    traces = traces(shownTraceIdx,:);
    startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
    x = (startT:endT);
    
    % select the data
    if hmmFlag
        donorData = traces.Donor_hmm(:,x);
        acceptorData = traces.Acceptor_hmm(:,x);
        fretData = traces.FRET_hmm(:,x);
    else
        donorData = traces.Donor(:,x);
        acceptorData = traces.Acceptor(:,x);
        fretData = traces.FRET(:,x);
    end
    
    if handles.tra.export.excludeZeros.Value
        donorExclude = traces.Donor_hmm(:,x) > 0.0;
        acceptorExclude = traces.Acceptor_hmm(:,x) > 0.0;
        fretExclude = traces.FRET_hmm(:,x) > .05;
        
        donorData = donorData(donorExclude);
        acceptorData = acceptorData(acceptorExclude);
        fretData = fretData(fretExclude);
    end
    
    if exportFlag
        % ask user where to save
        savePath = getappdata(handles.f,'savePath');
        savePath = uigetdir(savePath);
        
        % donor
        fileID = fopen([savePath,'/Donor_for_histogram.dat'],'w'); % create file
        fprintf(fileID,'%30e30\n',donorData(:)); 
        fclose(fileID);
        % acceptor
        fileID = fopen([savePath,'/Acceptor_for_histogram.dat'],'w'); % create file
        fprintf(fileID,'%30e30\n',acceptorData(:)); 
        fclose(fileID);
        % fret
        fileID = fopen([savePath,'/FRET_for_histogram.dat'],'w'); % create file
        fprintf(fileID,'%30e30\n',fretData(:)); 
        fclose(fileID);
    else
        % plot the 3 dwell times
        f = figure;
        ax = axes(f);
        
        nBins = 200;
        
        ax1 = subplot(1, 3, 1, ax); % left
        title(ax1, "Donor");
        histogram(ax1, donorData(:), nBins);

        ax2 = subplot(1, 3, 2); % middle
        title(ax2, "Acceptor");
        histogram(ax2, acceptorData(:), nBins);

        ax3 = subplot(1, 3, 3); % right
        title(ax3, "FRET");
        histogram(ax3, fretData(:), nBins, 'BinLimits', [-.1 1.1]);
    end
end

% Transition counts
function exportTransCounts(hObject, handles)
    % ask user where to save
    savePath = getappdata(handles.f,'savePath');
    savePath = uigetdir(savePath);
    
    % get relevent data
    traces = getappdata(handles.f,'traces');
    shownTraceIdx = find(getShownTraces(hObject, handles)');
    startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
    x = (startT:endT);
    
    fileID = fopen([savePath,'/transition_counts.dat'],'w'); % create file
    fprintf(fileID,'%12s   %12s   %12s   %12s\n','Molecule','Donor','Acceptor','FRET'); % add header
    
    % write counts to file with one line per molecule
    for i = shownTraceIdx
        % count the number of transitions excluding "half transitions"
        donorCount = floor( sum(diff(traces.Donor_hmm(i,x))~=0) / 2 );
        acceptorCount = floor( sum(diff(traces.Acceptor_hmm(i,x))~=0) / 2 );
        fretCount = floor( sum(diff(traces.FRET_hmm(i,x))~=0) / 2 );
        
        fprintf(fileID,'%12u   %12u   %12u   %12u\r\n', i, donorCount, acceptorCount, fretCount); % add data
    end
    
    fclose(fileID); % close
end

% Transition density
function displayTDP(hObject, handles)
    %% Setups
    % get all the trace data
    traces = getappdata(handles.f,'traces');
    shownTraceIdx = getShownTraces(hObject, handles);
    traces = traces(shownTraceIdx,:);
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
    
    figure;
    surf(X,Y,TDP);
    xlabel('FRET Before Transision');
    ylabel('FRET After Transision');
    shading interp;
end

% Post sync
function displayPSH(hObject, handles)
    %% Setups
    % get all the trace data
    traces = getappdata(handles.f,'traces');
    shownTraceIdx = getShownTraces(hObject, handles);
    traces = traces(shownTraceIdx,:);
    startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
    T = (startT:endT);
    
    %% Calculation
    fret  = traces.FRET_hmm(:,T); % grab all the FRET traces in one matrix
    fret = fret(:);
    if handles.tra.export.excludeZeros.Value
        fret = fret(fret~=0);
    end
    
    times = repmat(1:length(T),size(fret,1),1);
    [N, X, Y] = histcounts2(times(:),fret(:),1:3:length(T), 0:.05:1);
    X = movmean(X,2,'Endpoints','discard'); % convert endpoints to centers
    Y = movmean(Y,2,'Endpoints','discard'); % convert endpoints to centers
    X = repmat(X, size(Y,2), 1); % convert to meshgrid
    Y = repmat(Y', 1, size(X,2)); % convert to meshgrid
    
    %% Display
    figure;
    surf(X,Y,N');
    xlabel('Time');
    ylabel('FRET');
    shading interp;
    view(0,90); % birds-eye
end
