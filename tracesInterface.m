function varargout = tracesInterface(varargin)
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
    handles.tra.hmmStatesSlider.JavaPeer.set('MouseReleasedCallback', @(~,~) setHMMStates_Slider(handles.tra.hmmStatesSlider));
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
                                                'String', 'Export Transision Counts',...
                                                'Callback', @(hObject,~) exportTransCounts(hObject,guidata(hObject)));
                                                 
    %% 
    handles.tra.leftPanel.set('Heights',[25 150 80 75 150]);
    
    
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
    handles.tra.vidCurrentFrame.JavaPeer.set('MouseReleasedCallback',...
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
    handles.tra.graphGrid           = uix.GridFlex('Parent', handles.tra.graphPanel, 'Spacing', 5);
    
    [~, handles.tra.DAScale] = javacomponent('javax.swing.JSlider');
    handles.tra.DAScale.set('Parent', handles.tra.graphGrid);
    handles.tra.DAScale.JavaPeer.set('Maximum', 10e6);
    handles.tra.DAScale.JavaPeer.set('Minimum', 0);
    handles.tra.DAScale.JavaPeer.set('Value', 0);
    handles.tra.DAScale.JavaPeer.set('MouseReleasedCallback', @(~,~) setScale(handles.tra.DAScale, handles.tra.DAScale.JavaPeer.get('Value')/handles.tra.DAScale.JavaPeer.get('Maximum')*10));
    handles.tra.DAScale.JavaPeer.set('Orientation',handles.tra.DAScale.JavaPeer.VERTICAL);
    
    uix.Empty('Parent', handles.tra.graphGrid);
    handles.tra.DAAxes              = axes(handles.tra.graphGrid);
    handles.tra.FRETAxes            = axes(handles.tra.graphGrid);
    handles.tra.DAHistVBox          = uix.VBox('Parent', handles.tra.graphGrid);
    handles.tra.DonorHistAxes       = axes(handles.tra.DAHistVBox);
    handles.tra.AcceptorHistAxes    = axes(handles.tra.DAHistVBox);
    handles.tra.FRETHistAxes        = axes(handles.tra.graphGrid);
    handles.tra.graphGrid.set('Widths',[30 -4 -1],'Heights',[-1 -1]);
    
    % plots
    handles.tra.DonorPlot           = plot(handles.tra.DAAxes, 1, '-','color', [0 0.5 0]);
    hold(handles.tra.DAAxes,'on');
    handles.tra.AcceptorPlot        = plot(handles.tra.DAAxes, 1, '-','color', [1 0 0]);
    handles.tra.DonorStatePlot      = plot(handles.tra.DAAxes, 1, '-', 'color', [1 1 1]);
    handles.tra.AcceptorStatePlot 	= plot(handles.tra.DAAxes, 1, '-', 'color', [1 1 1]);
    hold(handles.tra.DAAxes,'off');
    % fret
    handles.tra.FRETPlot        = plot(handles.tra.FRETAxes, 1, '-','color', [42 167 201]/512);
    hold(handles.tra.FRETAxes,'on');
    handles.tra.FRETStatePlot   = plot(handles.tra.FRETAxes, 1, '-','color', [0 0 0]/256);
    hold(handles.tra.FRETAxes,'off');
    
    % current frame arrows on traces
    handles.tra.curFrameArrowDA   = text(handles.tra.DAAxes,   1,0,char(8593),'HorizontalAlignment','center','VerticalAlignment','top');
    handles.tra.curFrameArrowFRET = text(handles.tra.FRETAxes, 1,0,char(8593),'HorizontalAlignment','center','VerticalAlignment','top');
end

%% Load from session
function handles = loadFromSession(hObject,handles,session)
	setappdata(handles.f,'trace_traces', session.tra_traces);
    
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
    
    set(handles.tra.DAScale.JavaPeer, 'Value', session.tra_DAScale);
end

%% Updates
function onDisplay(hObject,handles)
    setappdata(handles.f,'mode','Traces');
    
    % set sliders
    seperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');
    vidMax = size(seperatedStacks{1},3);
    set(handles.tra.vidCurrentFrame.JavaPeer,'Maximum', vidMax);
    set(handles.tra.vidCurrentFrame.JavaPeer,'Value', getappdata(handles.f,'home_currentFrame'));
    handles.tra.cutSlider.JavaPeer.set('Maximum', vidMax);
    handles.tra.cutSlider.JavaPeer.set('HighValue', vidMax);
    handles.tra.highCutTextBox.String = num2str(vidMax);
    set(handles.tra.vidHBox,'Visible','on');
    
    % updates
    getRawTraceData(hObject, handles);
    updateMaxTraces(hObject,handles);
    setTrace(hObject,handles,1);
    setVidCurrentFrame(hObject, getappdata(handles.f,'home_currentFrame'));
    scale = handles.tra.DAScale.JavaPeer.get('Value') / handles.tra.DAScale.JavaPeer.get('Maximum')*10;
    scale = 10^-scale;
    axis(handles.tra.DAAxes, [1, vidMax, -scale*0.1, scale*1.1]);
    
    % key presses, these get turned off by onRelease
    set(handles.f,'KeyPressFcn',@keyPressCallback);
    
    handles.rightPanel.Selection = 3;
    handles.rightPanel.Visible = 'on';
end

function onRelease(hObject,handles)
    handles.rightPanel.Selection = 1;
    
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    % key presses, these get turned on by onDisplay
    set(handles.f,'KeyPressFcn','');
    
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
            movMeanWidth = handles.tra.meanSlider.JavaPeer.get('Value');
            minStates = handles.tra.hmmStatesSlider.JavaPeer.get('LowValue');
            maxStates = handles.tra.hmmStatesSlider.JavaPeer.get('HighValue');
            scale = handles.tra.DAScale.JavaPeer.get('Value')/handles.tra.DAScale.JavaPeer.get('Maximum')*10;
            scale = 10^-scale;
            traces(c,:) = calculateTraceData(traces(c,:), movMeanWidth, x, scale, minStates, maxStates);
            setappdata(handles.f,'traces',traces); % save
        end
        
        % Donor Trace
        handles.tra.DonorPlot.XData         = x;
        handles.tra.DonorPlot.YData         = traces.Donor(c,x);
        handles.tra.DonorStatePlot.XData    = x;
        handles.tra.DonorStatePlot.YData    = zeros(size(x,2),1);%traces.Donor_hmm(c,x);
        
        % Acceptor Trace
        handles.tra.AcceptorPlot.XData      = x;
        handles.tra.AcceptorPlot.YData      = traces.Acceptor(c,x);
        handles.tra.AcceptorStatePlot.XData = x;
        handles.tra.AcceptorStatePlot.YData = zeros(size(x,2),1);%traces.Acceptor_hmm(c,x);

        % FRET Trace
        handles.tra.FRETPlot.XData          = x;
        handles.tra.FRETPlot.YData          = traces.FRET(c,x);
        handles.tra.FRETStatePlot.XData     = x;
        handles.tra.FRETStatePlot.YData     = traces.FRET_hmm(c,x);
        axis(handles.tra.FRETAxes, [startT, endT, -0.05, 1.05]);

        % Histograms
        histogram(handles.tra.DonorHistAxes,traces.Donor(c,x), 50, 'Orientation', 'horizontal');

        histogram(handles.tra.AcceptorHistAxes,traces.Acceptor(c,x), 50, 'Orientation', 'horizontal');
        
        histogram(handles.tra.FRETHistAxes,traces.FRET(c,x), 50, 'Orientation', 'horizontal');

        
        % Video peak circle
        if isappdata(handles.f,'data_trace_plt')
            delete(getappdata(handles.f,'data_trace_plt'));
        end
        hold(handles.tra.vidAxes,'on');
        plt = viscircles(handles.tra.vidAxes, [traces.Center(c,:);traces.Center(c,:)], [traces.HalfWidth(c),traces.HalfWidth(c)*3], 'Color', 'white', 'LineWidth', .1);
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
function getRawTraceData(hObject, handles)
    hWaitBar = waitbar(0,'Generating traces ...', 'WindowStyle', 'modal');
    
    %% Grab relevent data
    seperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');
    I = selectFRETInterface('getCurrentImage',hObject,handles);
    filterSize = handles.fret.particleFilter.JavaPeer.get('Value') / handles.fret.particleFilter.JavaPeer.get('Maximum') * 5;
    particleMinInt = handles.fret.particleIntensity.JavaPeer.get('LowValue');
    particleMaxInt = handles.fret.particleIntensity.JavaPeer.get('HighValue');
    particleMaxEccentricity = handles.fret.eccentricitySlider.JavaPeer.get('Value')...
        / handles.fret.eccentricitySlider.JavaPeer.get('Maximum');
    particleMinDistance = handles.fret.minDistanceSlider.JavaPeer.get('Value')...
        / handles.fret.minDistanceSlider.JavaPeer.get('Maximum') * 20;
    combinedROIMask = getappdata(handles.f,'combinedROIMask');
    edgeDistance = handles.fret.edgeDistanceSlider.JavaPeer.get('Value')...
        / handles.fret.edgeDistanceSlider.JavaPeer.get('Maximum') * 20;
    startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
    
    %% Find particles
    particles = findParticles(I, particleMinInt, particleMaxInt, filterSize,...
                                'Method','GaussianFit',...
                                'EdgeDistance', edgeDistance,...
                                'Mask', combinedROIMask,...
                                'MaxEccentricity', particleMaxEccentricity,...
                                'MinDistance', particleMinDistance);
    traces = particles{1};    
    
    %% Calculate the donor and acceptor raw traces
    numTraces = size(traces,1);
    dur = size(seperatedStacks{1},3);
    Donor_raw = zeros(numTraces,dur); % pre-aloc;
    Acceptor_raw = zeros(numTraces,dur); % pre-aloc;
    for f=1:dur % no parfor becuase seperatedStacks is too big :(
        waitbar(f/dur);
        
        I_donor    = im2double(seperatedStacks{1}(:,:,f));
        I_acceptor = im2double(seperatedStacks{2}(:,:,f));
        
        %% interperolate at maskpoints
        F_donor    = griddedInterpolant(I_donor);
        F_acceptor = griddedInterpolant(I_acceptor);
        
        % create 7 by 7 area mask
        F_del = ( repmat((-1:1/3:1),numTraces,1) .* repmat(traces.HalfWidth*3, 1, 7) );
        F_x = reshape( repmat( repmat(traces.Center(:,2), 1, 7) + F_del , 1, 7) ,[],1);
        F_y = reshape( imresize( repmat(traces.Center(:,1), 1, 7) + F_del, [numTraces 49], 'nearest') ,[],1);
        
        W = (1:49);
        W = (mod(W,7)-1-3).^2 + (floor(W/7)-3).^2;
        W = repmat(W,numTraces,1);
        W = W ./ repmat( 2*(traces.HalfWidth.^2) ,1,49);
		W = exp(-W);
                
        Donor_raw(:,f)      = mean((reshape( F_donor(F_x,F_y), [], 49 ) ) .* W ,2);
        Acceptor_raw(:,f)  	= mean((reshape( F_acceptor(F_x,F_y), [], 49 ) ) .* W ,2);

    end
    traces.Donor_raw = Donor_raw;
    traces.Acceptor_raw = Acceptor_raw;
    
    % pre-aloc traces
    preAloc = zeros(numTraces, dur);
    traces.Donor        = preAloc;
    traces.Donor_hmm    = preAloc;
    traces.Acceptor     = preAloc;
    traces.Acceptor_hmm = preAloc;
    traces.FRET         = preAloc;
    traces.FRET_hmm     = preAloc;
    traces.Donor_bg     = zeros(numTraces,1);
    traces.Acceptor_bg  = zeros(numTraces,1);
    traces.Calculated  = zeros(numTraces,1,'logical');
    
    setappdata(handles.f,'traces',traces);
    
    delete(hWaitBar);
end

function preCalculateAllTraces(hObject, handles)
    hWaitBar = waitbar(0,'Updating traces ...', 'WindowStyle', 'modal');

    % Get data
    handles.tra.preCalButton.Enable = 'off';
    traces = getappdata(handles.f,'traces');
    movMeanWidth = handles.tra.meanSlider.JavaPeer.get('Value');
    startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
    x = (startT:endT);
    scale = handles.tra.DAScale.JavaPeer.get('Value')/handles.tra.DAScale.JavaPeer.get('Maximum')*10;
    scale = 10^-scale;
    numTraces = size(traces,1);
    minStates = handles.tra.hmmStatesSlider.get('LowValue');
    maxStates = handles.tra.hmmStatesSlider.get('HighValue');
        
    for c=1:numTraces
        waitbar(c/numTraces);
        if ~traces.Calculated(c)
            traces(c,:) = calculateTraceData(traces(c,:), movMeanWidth, x, scale, minStates, maxStates);
        end
    end
    
    % save
    setappdata(handles.f,'traces',traces);
    delete(hWaitBar);
end

function trace = calculateTraceData(trace, movMeanWidth, x, scale, minStates, maxStates)
    % Get original traces
    Donor       = movmean(trace.Donor_raw(1,x), movMeanWidth) / scale;
    Acceptor    = movmean(trace.Acceptor_raw(1,x), movMeanWidth) / scale;
    % Hmm
    trace.Donor_hmm(1,x)       = vbFRETWrapper(Donor, minStates, maxStates);
    trace.Acceptor_hmm(1,x)    = vbFRETWrapper(Acceptor, minStates, maxStates);
    % Background
    trace.Donor_bg(1)          = min(trace.Donor_hmm(1,x));
    trace.Acceptor_bg(1)       = min(trace.Acceptor_hmm(1,x));
    trace.Donor_hmm(1,x)       = trace.Donor_hmm(1,x) - trace.Donor_bg(1);
    trace.Acceptor_hmm(1,x)    = trace.Acceptor_hmm(1,x) - trace.Acceptor_bg(1);
    trace.Donor(1,x)           = Donor - trace.Donor_bg(1);
    trace.Acceptor(1,x)        = Acceptor - trace.Acceptor_bg(1);
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
    handles.tra.preCalButton.Enable = 'on';
    traces = getappdata(handles.f,'traces');
    startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
    scale = 10^-value;
    
    axis(handles.tra.DAAxes, [startT, endT, -0.05, 1.05]);
    
    traces.Calculated  = zeros(size(traces,1),1,'logical');
    
    setappdata(handles.f,'traces',traces); % save first
    updateDisplay(hObject,handles);
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
    % get relevent data
    traces = getappdata(handles.f,'traces');
    startT = handles.tra.cutSlider.JavaPeer.get('LowValue');
    endT = handles.tra.cutSlider.JavaPeer.get('HighValue');
    x = (startT:endT);
    savePath = getappdata(handles.f,'savePath');
    
    % Set save path to be in a folder "traces".
    % Add this folder to the save directory.
    % If this folder alread exist remove it then add it.
    flag = mkdir(savePath,'traces');
    if flag == 0
        rmdir([savePath, '/traces/'], 's');
        mkdir(savePath,'traces');
    end
    savePath = [savePath, '/traces/'];
    
    % export each trace to the traces folder with one file per molecule
    for i=1:size(traces,1)
        A = [x', traces.Donor(i,x)', traces.Acceptor(i,x)', traces.FRET(i,x)',...
            traces.Donor_hmm(i,x)', traces.Acceptor_hmm(i,x)', traces.FRET_hmm(i,x)']; % create matix of data to save
        
        fileID = fopen([savePath,'trace_', num2str(i), '.dat'],'w'); % create file trace_i.txt
        fprintf(fileID,'%30s %30s\n','X','Donor','Acceptor','FRET','Donor HMM','Acceptor HMM','FRET HMM'); % add header
        fprintf(fileID,'%30.25d %30.25d %30.25d %30.25d %30.25d %30.25d %30.25d\r\n',A); % add data
        fclose(fileID); % close
    end
end

    
