function varargout = kymographInterface(varargin)
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
    kyms = table(zeros(0,4), cell(0,1), zeros(0,1), zeros(0,1,'logical'), 'VariableNames', {'Position', 'Traces', 'Mark', 'ImageGenerated'});
    setappdata(handles.f,'kyms',kyms);
    setappdata(handles.f,'data_kym_images',cell(0));
    setappdata(handles.f,'data_currentDNA',1);
    setappdata(handles.f,'kmy_dnaImline',0);
    setappdata(handles.f,'kmy_vidImline',0);
    
    
    handles.kym.leftPanel = uix.VBox( 'Parent', handles.leftPanel);
    
    %% back
    handles.kym.backButtonPanel = uix.Panel('Parent', handles.kym.leftPanel);
    handles.kym.backButton = uicontrol(     'Parent', handles.kym.backButtonPanel,...
                                          	'String', 'Back',...
                                          	'Callback', @(hObject,~) onRelease(hObject,guidata(hObject)));
    
    %% settings
    handles.kym.settingsPanel = uix.BoxPanel('Parent', handles.kym.leftPanel,...
                                           'Title','Settings',...
                                           'Padding',5);
    handles.kym.settingsBox = uix.VBox('Parent', handles.kym.settingsPanel);
    
    % Width
    handles.kym.widthBox = uix.HBox('Parent', handles.kym.settingsBox);
    uix.Empty('Parent', handles.kym.widthBox);
    uicontrol(  'Parent', handles.kym.widthBox,...
                'style', 'text',...
                'String', 'Width:');
    handles.kym.widthTextbox = uicontrol(   'Parent', handles.kym.widthBox,...
                                        'style', 'edit',...
                                        'String', '1');
    uix.Empty('Parent', handles.kym.widthBox);
    handles.kym.widthBox.set('Widths',[-1 50 50 -1]);
    
    % Brightness
    uicontrol( 'Parent', handles.kym.settingsBox,...
               'Style' , 'text', ...
               'String', 'Brightness');
    [~, handles.kym.brightness] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.kym.brightness.set('Parent', handles.kym.settingsBox);
    handles.kym.brightness.JavaPeer.set('Maximum', 1e6);
    handles.kym.brightness.JavaPeer.set('Minimum', 0);
    handles.kym.brightness.JavaPeer.set('LowValue', 0);
    handles.kym.brightness.JavaPeer.set('HighValue', 1e6);
    handles.kym.brightness.JavaPeer.set('MouseReleasedCallback', @(~,~) setBrightness(handles.kym.brightness));
    % auto brightness and invert box
    handles.kym.autoAndInvertHBox = uix.HBox('Parent', handles.kym.settingsBox);
    % invert
    handles.kym.invertCheckbox = uicontrol(     'Parent', handles.kym.autoAndInvertHBox,...
                                                'Style', 'checkbox',...
                                                'String', 'Invert',...
                                                'Callback', @(hObject,~) setInvert(hObject, guidata(hObject), hObject.Value));
    % auto brightness
    handles.kym.autoBrightnessButton = uicontrol('Parent', handles.kym.autoAndInvertHBox,...
                                                 'String', 'Auto Brightness',...
                                                 'Callback', @(hObject,~) autoBrightness(hObject, guidata(hObject)));
                                    
    %% selection
    handles.kym.selectionPanel = uix.BoxPanel(  'Parent', handles.kym.leftPanel,...
                                                'Title','Selection',...
                                                'Padding',5);
    handles.kym.selectionBox = uix.VBox('Parent', handles.kym.selectionPanel);
    
    % arrows
    handles.kym.arrowsBox = uix.HBox('Parent', handles.kym.selectionBox);
    handles.kym.backArrow = uicontrol(  'Parent', handles.kym.arrowsBox,...
                                        'String', '<--',...
                                        'Callback', @(hObject,~) prevDNA(hObject,guidata(hObject)));
    handles.kym.nextArrow = uicontrol(  'Parent', handles.kym.arrowsBox,...
                                        'String', '-->',...
                                        'Callback', @(hObject,~) nextDNA(hObject,guidata(hObject)));
    %
    handles.kym.currentDNABox = uix.HBox('Parent', handles.kym.selectionBox);
    uicontrol(  'Parent', handles.kym.currentDNABox,...
                'style', 'text',...
                'String', 'Current');
    handles.kym.currentDNATextBox = uicontrol(  'Parent', handles.kym.currentDNABox,...
                                                'String', '1',...
                                                'Style', 'edit',...
                                                'Callback', @(hObject,~) currentDNATextBoxCallback(hObject,guidata(hObject),str2num(hObject.String)));
    handles.kym.maxDNAText = uicontrol( 'Parent', handles.kym.currentDNABox,...
                                        'String', '/1',...
                                        'Style', 'text',...
                                        'HorizontalAlignment', 'left');
                                    
    %% Delete
    handles.kym.deletePanel = uix.BoxPanel(  'Parent', handles.kym.leftPanel,...
                                                'Title','Delete',...
                                                'Padding',5);
    handles.kym.deleteBox = uix.VButtonBox('Parent', handles.kym.deletePanel,...
                                           'ButtonSize', [100 30]);
    
    handles.kym.deleteKym = uicontrol(  'Parent', handles.kym.deleteBox,...
                                        'String', 'DELETE',...
                                        'Callback', @(hObject,~) deleteDNA(hObject,guidata(hObject)));
                                    
    %% Exports
    handles.kym.exportPanel = uix.BoxPanel(  'Parent', handles.kym.leftPanel,...
                                             'Title','Export',...
                                             'Padding',5);
    handles.kym.exportBox = uix.VButtonBox('Parent', handles.kym.exportPanel,...
                                           'ButtonSize', [140 30]);
    
    handles.kym.exportAllKyms = uicontrol(  'Parent', handles.kym.exportBox,...
                                            'String', 'Export all kymographs',...
                                            'Callback', @(hObject,~) exportAllKymographs(hObject,guidata(hObject)));
                                    
    %% Tracing
    handles.kym.tracePanel = uix.BoxPanel(  'Parent', handles.kym.leftPanel,...
                                            'Title','Traces',...
                                            'Padding',5);
    handles.kym.traceBox = uix.VBox('Parent', handles.kym.tracePanel);
                                      
    handles.kym.addTraceBox = uix.VButtonBox('Parent', handles.kym.traceBox,...
                                          'ButtonSize', [140 30]);
    
    handles.kym.addTrace = uicontrol(  'Parent', handles.kym.addTraceBox,...
                                       'String', 'Add trace',...
                                       'Callback', @(hObject,~) addTrace(hObject,guidata(hObject)));
                                   
    handles.kym.traceTable = uitable(handles.kym.traceBox);
    
    handles.kym.traceBox.set('Heights', [30 300]);
                                                 
    %% 
    handles.kym.leftPanel.set('Heights',[25 120 80 60 60 400]);
    
    
    %% Right panel
    handles.kym.MainVBox    = uix.VBoxFlex('Parent', handles.rightPanelKym, 'Spacing', 5);
    handles.kym.kymPanel    = uix.CardPanel('Parent', handles.kym.MainVBox);
    handles.kym.HBox        = uix.HBoxFlex('Parent', handles.kym.MainVBox, 'Spacing', 5);
    handles.kym.tablePanel  = uix.Panel('Parent', handles.kym.HBox);
    handles.kym.SubVBox     = uix.VBoxFlex('Parent', handles.kym.HBox, 'Spacing', 5);
    handles.kym.vidPanel    = uix.Panel('Parent', handles.kym.SubVBox);
    handles.kym.dnaPanel    = uix.Panel('Parent', handles.kym.SubVBox);
    
    handles.kym.MainVBox.set('Heights',[200 -1]);
    handles.kym.HBox.set('Widths',[180 -1]);
    
    %% Video
    % framework
    handles.kym.vidVBox    = uix.VBox('Parent', handles.kym.vidPanel);
    handles.kym.vidHBox    = uix.HBox('Parent', handles.kym.vidVBox);
    % play button
    handles.kym.playButton = uicontrol('Parent', handles.kym.vidHBox,...
                                       'String', 'Play',...
                                       'Callback', @(hObject,~) playVideo(hObject,guidata(hObject)));
    % slider
    [~, handles.kym.vidCurrentFrame] = javacomponent('javax.swing.JSlider');
    handles.kym.vidCurrentFrame.set('Parent', handles.kym.vidHBox);
    handles.kym.vidCurrentFrame.JavaPeer.set('Maximum', 2);
    handles.kym.vidCurrentFrame.JavaPeer.set('Minimum', 1);
    handles.kym.vidCurrentFrame.JavaPeer.set('Value', 1);
    handles.kym.vidCurrentFrame.JavaPeer.set('MouseReleasedCallback',...
        @(~,~) setVidCurrentFrame(handles.kym.vidCurrentFrame, get(handles.kym.vidCurrentFrame.JavaPeer,'Value')));
    % scroll-able axes
    handles.kym.vidAxesPanel = uipanel('Parent', handles.kym.vidVBox,...
                                       'BorderType', 'none');
    handles.kym.vidAxes = axes(handles.kym.vidAxesPanel);
    hVidImage = imshow(rand(1000),'Parent',handles.kym.vidAxes);
    handles.kym.vidAxesScrollPanel = imscrollpanel(handles.kym.vidAxesPanel,hVidImage);
    handles.kym.vidAxesAPI = iptgetapi(handles.kym.vidAxesScrollPanel);
    % magnification box
    handles.kym.vidMagBox = immagbox(handles.kym.vidAxesPanel, hVidImage);
    % imline
    handles.kym.vidImline = imline(handles.kym.vidAxes, [.1 .1; .9 .9]);
    handles.kym.vidImline.addNewPositionCallback(@(pos) moveAImline(handles.f,pos));
    handles.kym.vidImline.setColor('red');
    % framework size
    handles.kym.vidHBox.set('Widths',[50, -1]);
    handles.kym.vidVBox.set('Heights',[25 -1]);
    vidMagBoxPos = get(handles.kym.vidMagBox,'Position');
    set(handles.kym.vidMagBox,'Position',[0 0 vidMagBoxPos(3) vidMagBoxPos(4)]);
    
    %% DNA
    handles.kym.dnaBox    = uix.VBox('Parent', handles.kym.dnaPanel);
    % slider
    [~, handles.kym.dnaCurrentFrame] = javacomponent('javax.swing.JSlider');
    handles.kym.dnaCurrentFrame.set('Parent', handles.kym.dnaBox);
    handles.kym.dnaCurrentFrame.JavaPeer.set('Maximum', 2);
    handles.kym.dnaCurrentFrame.JavaPeer.set('Minimum', 1);
    handles.kym.dnaCurrentFrame.JavaPeer.set('Value', 1);
    handles.kym.dnaCurrentFrame.JavaPeer.set('MouseReleasedCallback',...
        @(~,~) setDnaCurrentFrame(handles.kym.dnaCurrentFrame, get(handles.kym.dnaCurrentFrame.JavaPeer,'Value')));
    % scroll-able axes
    handles.kym.dnaAxesPanel = uipanel('Parent', handles.kym.dnaBox,...
                                       'BorderType', 'none');
    handles.kym.dnaAxes = axes(handles.kym.dnaAxesPanel);
    hDnaImage = imshow(rand(1000),'Parent',handles.kym.dnaAxes);
    handles.kym.dnaAxesScrollPanel = imscrollpanel(handles.kym.dnaAxesPanel,hDnaImage);
    handles.kym.dnaAxesAPI = iptgetapi(handles.kym.dnaAxesScrollPanel);
    % magnification box
    handles.kym.dnaMagBox = immagbox(handles.kym.dnaAxesPanel, hDnaImage);
    % imline
    handles.kym.dnaImline = imline(handles.kym.dnaAxes, [.1 .1; .9 .9]);
    handles.kym.dnaImline.addNewPositionCallback(@(pos) moveAImline(handles.f,pos));
    handles.kym.dnaImline.setColor('red');
    % framework size
    handles.kym.dnaBox.set('Heights',[25 -1]);
    dnaMagBoxPos = get(handles.kym.dnaMagBox,'Position');
    set(handles.kym.dnaMagBox,'Position',[0 0 dnaMagBoxPos(3) dnaMagBoxPos(4)]);
    
    %% kymograph
    % panel
    handles.kym.kymAxesPanel = uipanel('Parent', handles.kym.kymPanel);
    % scroll-able axes
    handles.kym.kymAxes = axes(handles.kym.kymAxesPanel);
    hKymImage = imshow(rand(1000),'Parent',handles.kym.kymAxes);
    handles.kym.kymAxesScrollPanel = imscrollpanel(handles.kym.kymAxesPanel,hKymImage);
    handles.kym.kymAxesAPI = iptgetapi(handles.kym.kymAxesScrollPanel);
    % ticks
    %axis(handles.kym.kymAxes,'on');
    %yticks(handles.kym.kymAxes,[]);
    % magnification box
    handles.kym.kymMagBox = immagbox(handles.kym.kymAxesPanel, hKymImage);
    % framework size
    kymMagBoxPos = get(handles.kym.kymMagBox,'Position');
    set(handles.kym.kymMagBox,'Position',[0 0 kymMagBoxPos(3) kymMagBoxPos(4)]);
    % refresh button
    handles.kym.kymRefreshBox = uix.VButtonBox( 'Parent', handles.kym.kymPanel,...
                                                'ButtonSize', [80,25]);
    handles.kym.kymAxesRefresh = uicontrol('Parent', handles.kym.kymRefreshBox,...
                                           'String', 'Refresh',...
                                           'Callback', @(hObject,~) refreshKymAxes(hObject,guidata(hObject)));
    handles.kym.kymPanel.Selection = 1;
    
    % table
    handles.kym.table = uitable(handles.kym.tablePanel,...
                                'CellSelectionCallback', @(hObject,eventdata) tableCallback(hObject,eventdata,guidata(hObject)));
end

%% Updates
function handles = loadFromSession(hObject,handles,session)
    handles.kym.invertCheckbox.Value = session.kym_invertImage;
    set(handles.kym.brightness.JavaPeer, 'LowValue', session.kym_lowBrightness);
    set(handles.kym.brightness.JavaPeer, 'HighValue', session.kym_highBrightness);
end
            
function getDataFromSelectedDNA(hObject, handles)
    hWaitBar = waitbar(0,'Generating kymographs...', 'WindowStyle', 'modal');
    
    kyms = getappdata(handles.f,'kyms');
    
    %% generate all the kymograph images
    if getappdata(handles.f,'isMapped')
        seperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');
        colors = getappdata(handles.f,'colors');
    else
        seperatedStacks = {getappdata(handles.f,'data_video_stack')};
        colors = [1 1 1];
    end
    width = str2num(handles.kym.widthTextbox.String);
    numDNA = size(kyms,1);
    
    kyms_images = generateAllKymographs(kyms.Position, width , seperatedStacks, colors);
    
    setappdata(handles.f,'data_kym_images',kyms_images);
    
    %% fill table
    updateTable(hObject,handles);
    
    delete(hWaitBar);
end

function onDisplay(hObject,handles)
    setappdata(handles.f,'mode','Kymographs');
    
    % set sliders
    if handles.dna.sourceTimeAvgCheckBox.Value
        set(handles.kym.dnaCurrentFrame,'Visible','off');
    else
        dnaStack = selectDNAInterface('getSourceStack',hObject,handles);
        dnaMax = size(dnaStack,3);
        set(handles.kym.dnaCurrentFrame.JavaPeer,'Maximum',dnaMax);
        set(handles.kym.dnaCurrentFrame.JavaPeer,'Value', getappdata(handles.f,'dna_currentFrame'));
        set(handles.kym.dnaCurrentFrame,'Visible','on');
    end
    vidStack = getappdata(handles.f,'data_video_stack');
    vidMax = size(vidStack,3);
    set(handles.kym.vidCurrentFrame.JavaPeer,'Maximum',vidMax);
    set(handles.kym.vidCurrentFrame.JavaPeer,'Value', getappdata(handles.f,'home_currentFrame'));
    set(handles.kym.vidCurrentFrame,'Visible','on');
    
    % updates
    getDataFromSelectedDNA(hObject, handles);
    updateMaxDNA(hObject,handles);
    selectDNA(hObject,handles,1);
    
    % key presses, these get turned off by onRelease
    set(handles.f,'KeyPressFcn',@keyPressCallback);
    
    handles.rightPanel.Selection = 2;
    handles.rightPanel.Visible = 'on';
end

function onRelease(hObject,handles)
    handles.rightPanel.Selection = 1;
    
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    % update any changes that result from Imline moves
    refreshKymAxes(hObject,handles);
    
    % key presses, these get turned on by onDisplay
    set(handles.f,'KeyPressFcn','');
    
    homeInterface('openSelectDNA',hObject);
end

function setVidCurrentFrame(hObject,value)
    handles = guidata(hObject);
    setappdata(handles.f,'home_currentFrame',value);
    selectDNA(hObject, handles, getappdata(handles.f,'data_currentDNA'));
end

function setDnaCurrentFrame(hObject,value)
    handles = guidata(hObject);
    setappdata(handles.f,'dna_currentFrame',value);
    selectDNA(hObject, handles, getappdata(handles.f,'data_currentDNA'));
end

function updateTable(hObject,handles)
    kyms = getappdata(handles.f,'kyms');
    handles.kym.table.Data = xy2rdiff(kyms.Position(:,[1 3]), kyms.Position(:,[2 4]));
end

%% Brightness Callbacks
function setBrightness(hObject)
    handles = guidata(hObject);
    lowBrightness = get(handles.kym.brightness.JavaPeer,'LowValue');
    highBrightness = get(handles.kym.brightness.JavaPeer,'HighValue');
    if lowBrightness==highBrightness
        if lowBrightness==0
            set(handles.kym.brightness.JavaPeer,'HighValue',highBrightness+1)
        else
            set(handles.kym.brightness.JavaPeer,'LowValue',lowBrightness-1)
        end
    end
    
    selectDNA(hObject, handles, getappdata(handles.f,'data_currentDNA'));
end

function autoBrightness(hObject, handles)
    % get the current kymograph
    row = getappdata(handles.f,'data_currentDNA');
    kymImages = getappdata(handles.f,'data_kym_images');
    I = kymImages{row};
    
    % invert the image as requested
    if handles.kym.invertCheckbox.Value
        I = imcomplement(I);
    end

    % calculate auto brightness
    autoImAdjust = stretchlim(I);

    % set the brightness sliders
    autoImAdjust = round(autoImAdjust * get(handles.kym.brightness.JavaPeer,'Maximum'));
    set(handles.kym.brightness.JavaPeer,'LowValue',autoImAdjust(1));
    set(handles.kym.brightness.JavaPeer,'HighValue',autoImAdjust(2));

    % update the displayed image
    selectDNA(hObject, handles, getappdata(handles.f,'data_currentDNA'));
end

function setInvert(hObject, handles, value)
    handles.kym.invertCheckbox.Value = value;
    autoBrightness(hObject,handles); % this will also update the display
end

%% DNA Selection
function tableCallback(hObject,eventdata,handles)
    if size(eventdata.Indices,1) == 0
        return;
    end
    
    row = eventdata.Indices(1);
    selectDNA(hObject,handles,row)
end

function selectDNA(hObject, handles, row)
    % save positions of current Traces
    saveImpolysToTraces(hObject,handles);
    
    if getappdata(handles.f,'Playing_Video')
        pauseVideo(hObject,handles);
    end
    
    if handles.kym.kymPanel.Selection == 2
        refreshKymAxes(hObject,handles); % recalls selectDNA
        return; 
    end

    setappdata(handles.f,'data_currentDNA',row);
    handles.kym.currentDNATextBox.String  = num2str(row);
    
    kyms = getappdata(handles.f,'kyms');
    kymImages = getappdata(handles.f,'data_kym_images');
    lowBrightness = get(handles.kym.brightness.JavaPeer,'LowValue')/get(handles.kym.brightness.JavaPeer,'Maximum');
    highBrightness = get(handles.kym.brightness.JavaPeer,'HighValue')/get(handles.kym.brightness.JavaPeer,'Maximum');
    kymI = kymImages{row};
    if handles.kym.invertCheckbox.Value
        kymI = imcomplement(kymI);
    end
    kymI = imadjust(kymI, [lowBrightness highBrightness]);
    
    % kymograph
    handles.kym.kymAxesAPI.replaceImage(kymI,'PreserveView',true);
    
    % dna
    handles.kym.dnaAxesAPI.replaceImage(selectDNAInterface('getCurrentImage',hObject,handles),'PreserveView',true);
    
    % video
    handles.kym.vidAxesAPI.replaceImage(homeInterface('getCurrentOneAxesImage',hObject,handles),'PreserveView',true);
    
    % imlines
    pos = reshape(kyms.Position(row,:),2,[])';
    handles.kym.dnaImline.setPosition(pos);
    dnaMag = handles.kym.dnaAxesAPI.getMagnification();
    vidMag = handles.kym.vidAxesAPI.getMagnification();
    handles.kym.dnaAxesAPI.setMagnificationAndCenter(dnaMag,mean(pos(:,1)),mean(pos(:,2)));
    handles.kym.vidAxesAPI.setMagnificationAndCenter(vidMag,mean(pos(:,1)),mean(pos(:,2)));
    handles.kym.kymPanel.Selection = 1;
    
    % traces
    resetTraceGraphics(hObject,handles);
end

function prevDNA(hObject,handles)
    c = getappdata(handles.f,'data_currentDNA');
    if c>1
        c=c-1;
    else
        c=1;
    end
    selectDNA(hObject,handles,c);
end

function nextDNA(hObject,handles)
    max_c = size(getappdata(handles.f,'kyms'),1);
    c = getappdata(handles.f,'data_currentDNA');
    if c<max_c
        c=c+1;
    end
    selectDNA(hObject,handles,c);
end

function keyPressCallback(hObject,eventdata)
    switch eventdata.Key
        case {'n','rightarrow','downarrow','s','d'}
            handles = guidata(hObject);
            nextDNA(hObject,handles);
        case {'p','leftarrow','uparrow','w','a'}
            handles = guidata(hObject);
            prevDNA(hObject,handles);
    end
end

function currentDNATextBoxCallback(hObject,handles,value)
    max_c = size(getappdata(handles.f,'kyms'),1);
    value = round(value);
    if value>max_c && value<1
        value = getappdata(handles.f,'data_currentDNA');
    end
    selectDNA(hObject,handles,value);
end

function updateMaxDNA(hObject,handles)
    max_kyms = size(getappdata(handles.f,'kyms'),1);
    handles.kym.maxDNAText.String = ['/' num2str(max_kyms)];
end

%% Delete DNA
function deleteDNA(hObject,handles)
    c = getappdata(handles.f,'data_currentDNA');
    
    % remove image   
    kymImages = getappdata(handles.f,'data_kym_images');
    kymImages(c) = [];
    setappdata(handles.f,'data_kym_images',kymImages);
    
    % remove position data
    kyms = getappdata(handles.f,'kyms');
    kyms(c,:) = [];
    setappdata(handles.f,'kyms',kyms);
    
    % update table
    updateTable(hObject,handles);
    
    % update total DNA count
    updateMaxDNA(hObject,handles);
    
    % change current DNA to nextDNA
    if c>size(kyms,1)
        c=c-1;
    end
    selectDNA(hObject, handles, c);
end

%% DNA Imline change
function moveAImline(hObject,pos)
    handles = guidata(hObject);
    
    handles.kym.dnaImline.setPosition(pos);
    handles.kym.vidImline.setPosition(pos);
    
    handles.kym.kymPanel.Selection = 2;
end

function refreshKymAxes(hObject,handles)
    % get inputs
    i = getappdata(handles.f,'data_currentDNA');
    kyms = getappdata(handles.f,'kyms');
    kymImages = getappdata(handles.f,'data_kym_images');
    width = str2num(handles.kym.widthTextbox.String);
    if getappdata(handles.f,'isMapped')
        seperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');
        colors = getappdata(handles.f,'colors');
    else
        seperatedStacks = {getappdata(handles.f,'data_video_stack')};
        colors = [1 1 1];
    end
    
    % change values
    kyms.Position(i,1:4) = reshape(getPosition(handles.kym.vidImline)',1,[]);
    kymImages{i} = generateKymograph(kyms.Position(i,1:4), width , seperatedStacks, colors);
    
    % save values
    setappdata(handles.f,'kyms',kyms);
    setappdata(handles.f,'data_kym_images',kymImages);
    
    % switch to kymograph axes  and display
    handles.kym.kymPanel.Selection = 1; % must come first
    selectDNA(hObject, handles, getappdata(handles.f,'data_currentDNA'));
    
    % updateTable
    updateTable(hObject,handles);
    
    % traces
    resetTraceGraphics(hObject,handles);
end

%% Play/pause
function playVideo(hObject,handles)
    % switch play button to pause button
    handles.kym.playButton.String = 'Pause';
    handles.kym.playButton.Callback = @(hObject,~) pauseVideo(hObject,guidata(hObject));

    % play loop
    setappdata(handles.f,'Playing_Video',1);
    
    currentFrame = getappdata(handles.f,'home_currentFrame');
    while getappdata(handles.f,'Playing_Video')
        if currentFrame < handles.kym.vidCurrentFrame.JavaPeer.get('Maximum')
            currentFrame = currentFrame+1;
        else
            currentFrame = 1;
        end
        setappdata(handles.f,'home_currentFrame',currentFrame);
        handles.kym.vidCurrentFrame.JavaPeer.set('Value',currentFrame);
        handles.kym.vidAxesAPI.replaceImage(homeInterface('getCurrentOneAxesImage',hObject,handles),'PreserveView',true);
        drawnow;
    end
end

function pauseVideo(hObject,handles)
    % switch pause button to play button
    handles.kym.playButton.String = 'Play';
    handles.kym.playButton.Callback = @(hObject,~) playVideo(hObject,guidata(hObject));
    
    % flag to stop play loop
    setappdata(handles.f,'Playing_Video',0);
end

%% Export
function exportAllKymographs(hObject,handles)
    % make sure the kyms data is uptodate
    refreshKymAxes(hObject,handles);

    % get data
    kyms        = getappdata(handles.f,'kyms');
    kymImages   = getappdata(handles.f,'data_kym_images');
    colors      = getappdata(handles.f,'colors');
    width = str2num(handles.kym.widthTextbox.String);
    if getappdata(handles.f,'isMapped')
        seperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');
        colors = getappdata(handles.f,'colors');
    else
        seperatedStacks = {getappdata(handles.f,'data_video_stack')};
        colors = [1 1 1];
    end
    
    % ask user for location and make a kymographs directory inside
    savePath = uigetdir();
    if savePath==0 % if user presses cancle
        return
    end
    mkdir([savePath '/kymographs/']);
    
    % set up waitbar
    hWaitBar = waitbar(0,'Exporting kymographs...', 'WindowStyle', 'modal');
    
    % save kymographs to directory
    for i=1:size(kyms,1)
        I = generateKymograph(kyms.Position(i,1:4), width , seperatedStacks, colors);
        imwrite(I, [savePath '/kymographs/' num2str(i) '.tif'],'tif');
        waitbar(i/size(kyms,1));
    end
    
    % close waitbar
    delete(hWaitBar);
end

%% Traces
function addTrace(hObject, handles, initPos)
    traceImpolys = getappdata(handles.f,'kym_kymImpoly');
    
    row = size(traceImpolys,2) + 1;
    if exist('initPos')
        traceImpolys{row} = impoly(handles.kym.kymAxes, initPos, 'Closed',false); % poly drawn from initPos
    else 
        traceImpolys{row} = impoly(handles.kym.kymAxes, 'Closed',false); % user draws poly
    end
    
    api = iptgetapi(traceImpolys{row});
    api.setColor('red');
    api.set('UserData',row);
    
    % callbacks
    api.set('Deletefcn',@deleteTrace); % delete callback
    
    % save line handle in cell array
    setappdata(handles.f,'kym_kymImpoly',traceImpolys);
end

function deleteTrace(hObject, ~)
    handles = guidata(hObject);
    
    traceImpolys = getappdata(handles.f,'kym_kymImpoly');

    row = get(hObject,'UserData');
    traceImpolys(row) = []; 
    
    % The kym_kymImpoly UserData must now be updated as the rows for  
    % have shifted after the deletion
    for i=row:length(traceImpolys)
        set(traceImpolys{i},'UserData',i);
    end
    
    % save cell array of handles
    setappdata(handles.f,'kym_kymImpoly',traceImpolys);
end

function resetTraceGraphics(hObject,handles)
    % delete the old ones first
    removeAllTraces(hObject,handles);
    
    row = getappdata(handles.f,'data_currentDNA');
    kyms = getappdata(handles.f,'kyms');
    traces = kyms.Traces{row};
    
    if isempty(traces) % if traces is empty then end
        % clear the trace table
        handles.kym.traceTable.Data = [];
    else
        tracePositions = traces.Positions;

        % add a imploy for each row in traces
        for i = 1:size(tracePositions,1)
            addTrace(hObject, handles, tracePositions{i});
        end

        % update the trace table with lifetimes
        handles.kym.traceTable.Data = kyms.Traces{row}.Lifetimes;
    end
end

function removeAllTraces(hObject,handles)
    traceImpolys = getappdata(handles.f,'kym_kymImpoly');

    % delete each imline graphic object
    for i=1:length(traceImpolys)
        delete(traceImpolys{i});
    end
    
    setappdata(handles.f,'kym_kymImpoly',cell(0));
end

function saveImpolysToTraces(hObject,handles)
    % Find the position of each trace impoly and save the position rather
    % then the whole graphics object.
    row = getappdata(handles.f,'data_currentDNA');
    kyms = getappdata(handles.f,'kyms');
    traces = kyms.Traces{row};
    traceImpolys = getappdata(handles.f,'kym_kymImpoly');
    
    % if traces is empty it will need the table structure
    if isempty(traces)
        traces = table(cell(0,1), zeros(0,1), 'VariableNames', {'Positions', 'Lifetimes'});
    end
    
    removeInd = (1:size(traces,1))'; % a list of all the impoly that no longer exist
    for i=1:size(traceImpolys,2)
        % grab the corrisponding traces row number from imploy UserData
        r = get(traceImpolys{i},'UserData');
        % grab postions from imploy
        pos = getPosition(traceImpolys{i});
        % set position
        traces.Positions(r) = {pos};
        % calculate and set lifetime
        traces.Lifetimes(r) = diff(pos([1 size(pos,1)],1));
        % since it must still exist remove it from the remove list
        removeInd(removeInd==r) = [];
    end
    
    % remove all kyms that with no corresponding Imline
    traces(removeInd,:) = [];
    
    % save traces to kyms appdata
    kyms.Traces(row) = {traces};
    setappdata(handles.f,'kyms',kyms);
end