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
    kyms = table([],'VariableNames',{'Position'});
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
    
    % source popupmenu
    handles.kym.widthBox = uix.HBox('Parent', handles.kym.settingsBox);
    uicontrol(  'Parent', handles.kym.widthBox,...
                'style', 'text',...
                'String', 'Width');
    handles.kym.widthTextbox = uicontrol(   'Parent', handles.kym.widthBox,...
                                        'style', 'edit',...
                                        'String', '1');
                                    
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
                                    
                                                 
    %% 
    handles.kym.leftPanel.set('Heights',[25 50 100 60 60]);
    
    
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
    
    kyms_images = cell(numDNA,1);
    for i=1:numDNA % no parfor as seperatedStacks will be broadcast
        kyms_images{i} = generateKymograph(kyms.Position(i,:), width , seperatedStacks, colors);
        waitbar(i/numDNA);
    end
    
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

%% DNA Selection
function tableCallback(hObject,eventdata,handles)
    if size(eventdata.Indices,1) == 0
        return;
    end
    
    row = eventdata.Indices(1);
    selectDNA(hObject,handles,row)
end

function selectDNA(hObject, handles, row)
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
    
    % kymograph
    handles.kym.kymAxesAPI.replaceImage(kymImages{row},'PreserveView',true);
    
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

