function varargout = mappingInterface(varargin)
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
    setappdata(handles.f,'mapping_mode','Select Video');
    
    handles.map = struct();
    handles.map.leftPanel = uix.VBox( 'Parent', handles.leftPanel);
    
    %% back
    handles.map.backButtonPanel = uix.Panel('Parent', handles.map.leftPanel);
    handles.map.backButton = uicontrol(     'Parent', handles.map.backButtonPanel,...
                                          	'String', 'Back',...
                                          	'Callback', @(hObject,~) onRelease(hObject,guidata(hObject)));
    
    %% video or displacmentFields                
    handles.map.seletVideoPanel = uix.BoxPanel('Parent', handles.map.leftPanel,...
                                                'Title', 'Select the mapping video',...
                                                'Padding', 5);
    handles.map.seletVideoBox = uix.VBox('Parent', handles.map.seletVideoPanel);
    
    handles.map.loadPreviousMappingBox = uix.VButtonBox('Parent', handles.map.seletVideoBox,...
                                                        'ButtonSize', [140 25]);
                                        
    handles.map.loadPreviousMappingButton = uicontrol(  'Parent', handles.map.loadPreviousMappingBox,...
                                                'String', 'Use previous mapping',...
                                                'Callback', @(hObject,~) loadPreviousMapping(hObject));
                                            
    uicontrol(  'Parent', handles.map.seletVideoBox,...
                'Style', 'text',...
                'String', 'or');
            
    handles.map.selectVideoButtonBox = uix.VButtonBox('Parent', handles.map.seletVideoBox,...
                                                        'ButtonSize', [140 25]);
                                            
    handles.map.selectVideoButton = uicontrol(  'Parent', handles.map.selectVideoButtonBox,...
                                                'String', 'Import new mapping video',...
                                                'Callback', @(hObject,~) selectVideoFileButtonCallback(hObject));
    
    uix.Empty('Parent', handles.map.seletVideoBox); % spacer
    
    handles.map.selectVideoTextBox = uicontrol( 'Parent', handles.map.seletVideoBox,...
                                                'Style' , 'edit', ...
                                                'String', 'No mapping video selected',...
                                                'Callback', @(hObject,~) selectVideoFileTextBoxCallback(hObject,hObject.String));
    
    handles.map.seletVideoBox.set('Heights',[25 15 25 2 25]);
    
                                   
    %% pre-precessing
    handles.map.preProcPanel = uix.BoxPanel('Parent', handles.map.leftPanel,...
                                            'Title', 'Pre-processing',...
                                            'Visible', 'off');
    handles.map.preProcVBox = uix.VButtonBox('Parent', handles.map.preProcPanel, ...
                                             'ButtonSize', [280 25]);
                                            
    % brightness
    uicontrol( 'Parent', handles.map.preProcVBox,...
               'Style' , 'text', ...
               'String', 'Brightness');
    [~, handles.map.brightness] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.map.brightness.set('Parent', handles.map.preProcVBox);
    handles.map.brightness.JavaPeer.set('Maximum', 1e6);
    handles.map.brightness.JavaPeer.set('Minimum', 0);
    handles.map.brightness.JavaPeer.set('LowValue', 0);
    handles.map.brightness.JavaPeer.set('HighValue', 1e6);
    handles.map.brightness.JavaPeer.set('PaintTicks',true);
    handles.map.brightness.JavaPeer.set('MajorTickSpacing',1e5);
    handles.map.brightness.JavaPeer.set('MouseReleasedCallback', @(~,~) setBrightness(handles.map.brightness));
    
    % box for auto, invert and time average
    handles.map.autoAndInvertHBox = uix.HBox('Parent', handles.map.preProcVBox);
    
    % invert
    handles.map.invertCheckbox = uicontrol(     'Parent', handles.map.autoAndInvertHBox,...
                                                'Style', 'checkbox',...
                                                'String', 'Invert',...
                                                'Callback', @(hObject,~) setInvertVideo(hObject, guidata(hObject),hObject.Value));
    
    % auto brightness
    handles.map.autoBrightnessButton = uicontrol(  'Parent', handles.map.autoAndInvertHBox,...
                                                'String', 'Auto Brightness',...
                                                'Callback', @(hObject,~) autoBrightness(hObject, guidata(hObject)));
                                            
    % time average
    handles.map.timeAvgCheckbox = uicontrol(     'Parent', handles.map.autoAndInvertHBox,...
                                                'Style', 'checkbox',...
                                                'String', 'Time Average',...
                                                'Callback', @(hObject,~) setTimeAverageVideo(hObject, guidata(hObject),hObject.Value));
    
    %% ROI
    setappdata(handles.f,'selectingROI', false);
    handles.map.roiPanel = uix.BoxPanel('Parent', handles.map.leftPanel,...
                                        'Title', 'Select Chanels',...
                                        'Visible', 'off');
    handles.map.roiVBox = uix.VButtonBox('Parent', handles.map.roiPanel, ...
                                             'ButtonSize', [280 25]);
    % number of roi
    handles.map.numberROIPanel = uix.HBox('Parent', handles.map.roiVBox);
    uicontrol(  'Parent', handles.map.numberROIPanel,...
                'Style' , 'text', ...
                'String', 'Number of channels: ');
    handles.map.numberROITextBox = uicontrol(   'Parent', handles.map.numberROIPanel,...
                                                'Style' , 'popupmenu', ...
                                                'String', {'2','3','4'},...
                                                'Callback', @(hObject,~) updateSelectROI(hObject,guidata(hObject)));
    
    % select roi
    handles.map.selectROIPanel = uix.HBox('Parent', handles.map.roiVBox);
    handles.map.selectROIButton = uicontrol('Parent', handles.map.selectROIPanel,...
                                         	'String', 'Select Channels',...
                                            'Callback', @(hObject,~) selectROI(hObject, guidata(hObject)));
    handles.map.doneROIButton = uicontrol(  'Parent', handles.map.selectROIPanel,...
                                         	'String', 'Done',...
                                           	'Callback', @(hObject,~) roiSelected(hObject, guidata(hObject)));
                                        
    %% Re-change ROI
    handles.map.changeROIPanel = uix.BoxPanel('Parent', handles.map.leftPanel,...
                                              'Title', 'Edit Channels',...
                                              'Visible', 'off');
                                          
    handles.map.changeROIBox = uix.HButtonBox( 'Parent', handles.map.changeROIPanel,...
                                                'ButtonSize', [100, 25]);
    
    handles.map.changeROIButton = uicontrol(  'Parent', handles.map.changeROIBox,...
                                              'String', 'Edit Channels',...
                                           	  'Callback', @(hObject,~) reselectROI(hObject, guidata(hObject)));
                                        
    %% Particle detection
    handles.map.particlePanel = uix.BoxPanel('Parent', handles.map.leftPanel,...
                                             'Title', 'Particle Detection',...
                                             'Visible', 'off',...
                                             'Padding', 5);
    handles.map.particleVBox = uix.VBox('Parent', handles.map.particlePanel);
                                          
    % channel selector
    handles.map.particleChannel = uicontrol('Parent', handles.map.particleVBox,...
                                            'Style' , 'popupmenu', ...
                                            'String' , {'ERROR'}, ...
                                            'Callback', @(hObject,~) particleDetectionChangeChannel(hObject,guidata(hObject)));
    % filter
    uicontrol( 'Parent', handles.map.particleVBox,...
               'Style' , 'text', ...
               'String', 'Gaussina Filter Size');
    [~, handles.map.particleFilter] = javacomponent('javax.swing.JSlider');
    handles.map.particleFilter.set('Parent', handles.map.particleVBox);
    handles.map.particleFilter.JavaPeer.set('Maximum', 5e5);
    handles.map.particleFilter.JavaPeer.set('Minimum', 0);
    handles.map.particleFilter.JavaPeer.set('Value', 0);
    handles.map.particleFilter.JavaPeer.set('MouseReleasedCallback', @(~,~) updateParticleDetection(handles.map.particleFilter));
    % add filter lables
    parFilLabels = java.util.Hashtable();
    parFilLabels.put( int32( 0 ), javax.swing.JLabel('0') );
    parFilLabels.put( int32( 1e5 ), javax.swing.JLabel('1') );
    parFilLabels.put( int32( 2e5 ), javax.swing.JLabel('2') );
    parFilLabels.put( int32( 3e5 ), javax.swing.JLabel('3') );
    parFilLabels.put( int32( 4e5 ), javax.swing.JLabel('4') );
    parFilLabels.put( int32( 5e5 ), javax.swing.JLabel('5') );
    handles.map.particleFilter.JavaPeer.setLabelTable( parFilLabels );
    handles.map.particleFilter.JavaPeer.setPaintLabels(true);
    
    % intensity
    uicontrol( 'Parent', handles.map.particleVBox,...
               'Style' , 'text', ...
               'String', 'Selected Intensities');
    [~, handles.map.particleIntensity] = javacomponent('com.jidesoft.swing.RangeSlider');
    handles.map.particleIntensity.set('Parent', handles.map.particleVBox);
    handles.map.particleIntensity.JavaPeer.set('Maximum', 1e6);
    handles.map.particleIntensity.JavaPeer.set('Minimum', 0);
    handles.map.particleIntensity.JavaPeer.set('LowValue', 0);
    handles.map.particleIntensity.JavaPeer.set('HighValue', 1e6);
    handles.map.particleIntensity.JavaPeer.set('MouseReleasedCallback', @(~,~) updateParticleDetection(handles.map.particleIntensity));
    
    handles.map.regChannelsButton = uicontrol(  'Parent', handles.map.particleVBox,...
                                                'String', 'Register Channels',...
                                                'Callback', @(hObject,~) registerMapping(hObject,guidata(hObject)));
    uicontrol( 'Parent', handles.map.particleVBox,...
               'Style','text',...
               'String', [  'Register Channels: This may take a several minutes. This will attempt to overlap the two channels using the some ' ...
                            'of the particles that were detected. This uses only one frame of the video.']);
    
    handles.map.particleVBox.set('Heights',[25 15 50 15 50 25 75]);
    
    %% Save
    handles.map.saveMappingPanel = uix.Panel('Parent', handles.map.leftPanel,...
                                             'Visible', 'off',...
                                             'Padding', 5);
    handles.map.saveMappingDone = uicontrol(  'Parent', handles.map.saveMappingPanel,...
                                              'String', 'Done',...
                                           	  'Callback', @(hObject,~) onRelease(hObject, guidata(hObject)));
    %%
    handles.map.leftPanel.set('Heights',[25, 125, 100, 80, 50, 250 35]);
    
    setappdata(handles.f,'mapping_currentFrame',1)
end

%% Select File Callback
function selectVideoFileButtonCallback(hObject)
    [fileName, fileDir, ~] = uigetfile({'*.tif';'*.tiff';'*.TIF';'*.TIFF'}, 'Select the mapping video file'); % prompt user for file
    if fileName ~= 0 % if user does not presses cancel
        selectVideoFileTextBoxCallback(hObject, [fileDir fileName]);
    end
end

function selectVideoFileTextBoxCallback(hObject, filePath)
    handles = guidata(hObject);
    handles = setVideoFile(hObject, handles, filePath);
    handles = setControlsForNewVideo(hObject, handles);
    updateDisplay(hObject, handles);
end

function handles = setControlsForNewVideo(hObject, handles)
    % requires a video to have been saved
    stack = getappdata(handles.f,'data_mapping_originalStack');
    maxIntensity = getappdata(handles.f,'mapping_maxIntensity');
    
    % frame controls
    % set max before values
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    handles.map.particleIntensity.JavaPeer.set('Maximum',maxIntensity);
    
    % frame
    handles.axesControl.currentFrameTextbox.String = '1';
    set(handles.axesControl.currentFrame.JavaPeer,'Value',1);
    setappdata(handles.f,'mapping_currentFrame',1)
    
    % brightness controls
    autoImAdjust = stretchlim(stack(:,:,1)); % get the auto brightness values    
    autoImAdjust = round(autoImAdjust * get(handles.map.brightness.JavaPeer,'Maximum'));
    set(handles.map.brightness.JavaPeer,'LowValue',autoImAdjust(1));
    set(handles.map.brightness.JavaPeer,'HighValue',autoImAdjust(2));
    
    % invert
    handles.map.invertCheckbox.Value   = 0;
    
    % time avg
    handles.map.timeAvgCheckbox.Value   = 0;
    
    % ROI
    handles.map.numberROITextBox.Value = 1;
    
    % particle settings
    handles.map.particleChannel.Value = 1;
    
    % show controls
    switchMode(hObject, handles, 'ROI');
end

function handles = loadFromSession(hObject,handles,session)
    if strcmp(session.map_mode, 'Loaded Map')
        handles = setupMultiAxes(hObject,handles,size(session.ROI,1));
        guidata(hObject,handles);
        switchMode(hObject, guidata(hObject), session.map_mode);
        return;
    end

    % particleSettings
    setappdata(handles.f,'mapping_particleSettings',session.map_particleSettings);
        
    % get the stack
    handles = setVideoFile(hObject, handles, session.map_videoFilePath);
    stack = getappdata(handles.f,'data_mapping_originalStack');
    maxIntensity = getappdata(handles.f,'mapping_maxIntensity');
    if stack==0 % the file could not be located
        uiwait(msgbox('The original mapping video file could not be found. Please locate the new location of the mapping video and select it.'));
        
        [fileName, fileDir, ~] = uigetfile({'*.tif';'*.tiff';'*.TIF';'*.TIFF'}, 'Select the mapping video file'); % prompt user for file
        if fileName ~= 0 % if user does not presses cancel
            handles = setVideoFile(hObject, handles, [fileDir fileName]);
        else
            handles.map.selectVideoTextBox.String = session.map_videoFilePath;
            delete(handles.f);
        end
        stack = getappdata(handles.f,'data_mapping_originalStack');
        maxIntensity = getappdata(handles.f,'mapping_maxIntensity');
    end
    
    
    % frame controls
    % set max before values
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    handles.map.particleIntensity.JavaPeer.set('Maximum',maxIntensity);
    
    % frame
    handles.axesControl.currentFrameTextbox.String = num2str(session.map_currentFrame);
    set(handles.axesControl.currentFrame.JavaPeer, 'Value', session.map_currentFrame);
    setappdata(handles.f,'mapping_currentFrame',session.map_currentFrame)
    
    % brightness controls
    set(handles.map.brightness.JavaPeer, 'LowValue', session.map_lowBrightness);
    set(handles.map.brightness.JavaPeer, 'HighValue', session.map_highBrightness);
    
    % invert
    handles.map.invertCheckbox.Value = session.map_invertVideo;
    
    % time avg
    handles.map.timeAvgCheckbox.Value   = session.map_timeAvg;
    
    % ROI
    handles.map.numberROITextBox.Value = session.map_numberROI;
    roiSelected(hObject, handles);
    
    % particle settings
    handles.map.particleChannel.Value = session.map_particleChannel;
    
    % overlay
    if strcmp(session.map_mode,'Overlay')
        collocalizeMapping(hObject, guidata(hObject));
        switchMode(hObject, handles, 'Overlay');
    else
        switchMode(hObject, guidata(hObject), session.map_mode);
    end
end
    
function handles = setVideoFile(hObject, handles, filePath)
    hWaitBar = waitbar(0,'Loading in mapping video...', 'WindowStyle', 'modal');
    [stack, maxIntensity] = getStackFromFile(filePath, hWaitBar);
    if stack == 0 % an error was encountored
        filePath = 'No mapping video selected';
    end
    
    % save
    handles.map.selectVideoTextBox.String = filePath;
    setappdata(handles.f,'data_mapping_originalStack',stack);
    setappdata(handles.f,'mapping_maxIntensity',maxIntensity);
    
    close(hWaitBar);
end

function loadPreviousMapping(hObject)
    [fileName, fileDir, ~] = uigetfile({'*.mat'}, 'Select a mapped session file'); % prompt user for file
    if fileName == 0 % the user canceled
        return;
    end
    
    hWaitBar = waitbar(0,'Loading in mapping...', 'WindowStyle', 'modal');
    session = load([fileDir fileName]);
    session = session.session;
    
    if ~session.isMapped % contains no mapping
        msgbox('This file does not contain a mapping!');
        delete(hWaitBar);
        return;
    end
    
    % import mapping
    handles = guidata(hObject);
    setappdata(handles.f,'isMapped',session.isMapped);
    setappdata(handles.f,'displacmentFields',session.displacmentFields);
    setappdata(handles.f,'combinedROIMask',session.combinedROIMask);
    setappdata(handles.f,'ROI',session.ROI);
    
    % apply mapping
    if ~strcmp(handles.vid.selectVideoTextBox.String, 'No video selected')
        collocalizeVideo(hObject,handles);
    end
    if handles.dna.sourcePopUpMenu.Value ~= 1
        collocalizeDNAImport(hObject,handles);
    end
    if handles.fret.sourcePopUpMenu.Value ~=1
        collocalizeFRETImport(hObject,handles);
    end
    
    % setup display
    handles = setupMultiAxes(hObject,handles,size(session.ROI,1));
    guidata(hObject,handles);
    switchMode(hObject, handles, 'Loaded Map');
    msgbox('Mapping Loaded!');
    
    delete(hWaitBar);
end

%% ROI Controls
function selectROI(hObject, handles)
    setappdata(handles.f,'selectingROI', true);
    updateDisplay(hObject,handles);
end

function drawROI(hObject, handles)
    numROI = handles.map.numberROITextBox.Value+1;
    
    ROI = getappdata(handles.f,'ROI');
    if isempty(ROI)
        ROI = [(1:numROI)'*20, (1:numROI)'*20, zeros(numROI,2)+50];
    else
        if numROI < size(ROI,1)
            ROI = ROI(1:numROI,:); % remove extra rows from end
        elseif numROI > size(ROI,1)
            othersROISize = ROI(1,3:4);
            ROI = [ROI; [(size(ROI,1)+1:numROI)'*20, (size(ROI,1)+1:numROI)'*20, ones(numROI-size(ROI,1),1)*othersROISize]]; % add new rows to end
        end
    end
    setappdata(handles.f,'ROI',ROI);
    
    colors = getappdata(handles.f,'colors');

    constrainFunc = makeConstrainToRectFcn('imrect', get(handles.oneAxes.Axes,'XLim')+[1 -1], get(handles.oneAxes.Axes,'YLim')+[1 -1]);
    
    % delete old roiRects
    if isfield(handles, 'roiRect')
        for i=1:size(handles.roiRect,1)
            delete(handles.roiRect{i});
        end
    end
    
    handles.roiRect = cell(numROI,1); % pre-aloc
    api = cell(numROI,1); % pre-aloc
    for i=1:numROI
        handles.roiRect{i} = imrect(handles.oneAxes.Axes, ROI(i,:));
        api{i} = iptgetapi(handles.roiRect{i});
        api{i}.setPositionConstraintFcn(constrainFunc);
        api{i}.addNewPositionCallback(make_roiRectCallback(i,handles.f));
        api{i}.setColor(colors(i,:)); % change colors
    end
    
    guidata(hObject,handles);
    
    function fun = make_roiRectCallback(i,fig)
        fun = @roiRectCallback;
        function roiRectCallback(pos)
            ROI(i,1:2) = [ceil(pos(1)) ceil(pos(2))]; % convert pos cordinates to integers
            ROI(:,3:4) = repmat([floor(pos(3)) floor(pos(4))], size(ROI,1), 1); % convert pos cordinates to integers
            setappdata(fig,'ROI',ROI);
            for j=1:size(ROI,1)
                otherRectPos = api{j}.getPosition();
                api{j}.setConstrainedPosition([otherRectPos(1) otherRectPos(2) ROI(i,3) ROI(i,4)]);
            end
        end
    end
end

function updateSelectROI(hObject, handles)
    if getappdata(handles.f,'selectingROI')
        drawROI(hObject, handles)
    end
end

function reselectROI(hObject, handles)
    switchMode(hObject, handles, 'ROI');
    selectROI(hObject, handles);
end

function roiSelected(hObject, handles)
    hWaitBar = waitbar(0,'Seperating stacks...', 'WindowStyle', 'modal');

    setappdata(handles.f,'selectingROI', false);
    
    numROI = handles.map.numberROITextBox.Value+1;
    maxIntensity = getappdata(handles.f,'mapping_maxIntensity');
    particleSettings = getappdata(handles.f,'mapping_particleSettings');
    
    %% Setup particle detection settings
    channelStr = cell(numROI+1,1);
    channelStr = {'All Channels'};
    for i=1:numROI
        channelStr{i+1} = ['Channel ' num2str(i)];
        particleSettings(i).filterSize = 0;
        particleSettings(i).minIntensity = maxIntensity*0.9;
        particleSettings(i).maxIntensity = maxIntensity;
    end
    setappdata(handles.f,'mapping_particleSettings',particleSettings);
    handles.map.particleChannel.String = channelStr;

    %% Setup seperate chanels axes
    handles = setupMultiAxes(hObject,handles,numROI);

    %% Seperate Stacks
    ROI = getappdata(handles.f,'ROI');
    stack = getappdata(handles.f,'data_mapping_originalStack');
    seperatedStacks = seperateStack(ROI,stack);
    
    %% Remove imrects
    if isfield(handles,'roiRect')
        for i=1:numROI
            delete(handles.roiRect{1});
            handles.roiRect(1)=[];
        end
        handles = rmfield(handles,'roiRect');
    end
    
    %% Save then Display
    setappdata(handles.f,'data_mapping_originalSeperatedStacks',seperatedStacks);
    guidata(hObject,handles);
    particleDetectionChangeChannel(hObject,handles);
    switchMode(hObject, handles, 'Particles');
    updateParticleDetection(hObject);
    handles.multiAxes.AxesAPI{1}.setMagnification(handles.multiAxes.AxesAPI{1}.findFitMag()); % zoom axes
    close(hWaitBar);
end

function handles = setupMultiAxes(hObject,handles,numROI)
% delete old multiAxes if they exist
    if isfield(handles,'multiAxes')
        delete(handles.multiAxes.Grid);
    end
    
    colors = getappdata(handles.f,'colors');
    names  = getappdata(handles.f,'ROINames');
    
    handles.multiAxes = struct();
    handles.multiAxes.plt = cell(numROI,1);
    handles.multiAxes.Grid = uix.Grid(  'Parent', handles.axesPanel,...
                                        'Padding', 0,...
                                        'Spacing', 0);

    handles.multiAxes.Axes = cell(numROI,1);
    for i=1:numROI
        % box containing title and edit button
        handles.multiAxes.titleBox{i} = uix.HBox(   'Parent', handles.multiAxes.Grid,...
                                                    'Padding', 0,...
                                                    'Spacing', 0);
        % title
        handles.multiAxes.titleText{i} = uicontrol( 'Parent', handles.multiAxes.titleBox{i},...
                                                    'Style', 'text',...
                                                    'String', names{i},...
                                                    'FontSize', 14,...
                                                    'FontWeight', 'bold');
        % edit button
        handles.multiAxes.editBox{i} = uix.HButtonBox('Parent', handles.multiAxes.titleBox{i}, 'ButtonSize', [60, 25]);
        handles.multiAxes.editButton{i} = uicontrol('Parent', handles.multiAxes.editBox{i},...
                                                    'Style', 'pushbutton',...
                                                    'String', 'edit',...
                                                    'BackgroundColor', colors(i,:),...
                                                    'Callback', @(hObject,~) editMultiAxesCallback(hObject, guidata(hObject), i));
        % panel
        handles.multiAxes.Panel{i} = uipanel('Parent', handles.multiAxes.Grid,...
                                             'BorderType', 'none');
        % axes
        handles.multiAxes.Axes{i} = axes(handles.multiAxes.Panel{i});
        % scroll panel
        hImage = imshow(rand(1000),'Parent',handles.multiAxes.Axes{i});
        handles.multiAxes.AxesScrollPanel{i} = imscrollpanel(handles.multiAxes.Panel{i},hImage);
        handles.multiAxes.AxesAPI{i} = iptgetapi(handles.multiAxes.AxesScrollPanel{i});
        % magnification box (first only)
        if i==1
            handles.multiAxes.magPanel = uipanel('Parent', handles.multiAxes.Grid,...
                                                 'BorderType', 'none');
            handles.multiAxes.magBox = immagbox(handles.multiAxes.magPanel, hImage);
            handles.multiAxes.AxesAPI{1}.addNewMagnificationCallback(@(mag) mappingInterface('updateMagnifcation',handles.multiAxes.magBox,mag));
        end
    end
    
    % setup grid spacing
    % the last 20 is for the mag box
    % the first and middle 20s are for the titles
    % the -1s are for the axes
    switch i
        case 2
            widths = [-1 -1];
            heights = [20 -1 20];
        case 3
            widths = [-1 -1];
            heights = [20 -1 20 -1 20];
        case 4
            widths = [-1 -1];
            heights = [20 -1 20 -1 20];
    end
    handles.multiAxes.Grid.set('Widths',widths,'Heights',heights);
    
    % magnification box
    magBoxPos = get(handles.multiAxes.magBox,'Position');
    set(handles.multiAxes.magBox,'Position',[0 0 magBoxPos(3) magBoxPos(4)]);
end

function editMultiAxesCallback(hObject, handles, id)
    colors = getappdata(handles.f,'colors');
    names  = getappdata(handles.f,'ROINames');

    % Window
    dialogWindow = dialog('Position',[300 300 250 100],'Name','Editing Channel', 'DeleteFcn', @(~,~) onClose);
    dialogBox    = uix.VBox('Parent', dialogWindow, 'Padding', 10, 'Spacing', 10);
    
    % Names Box
    nameBox = uix.HBox('Parent', dialogBox);
    % Name Text
    uicontrol('Parent',nameBox,...
           'Style','text',...
           'String','Channel Name: ');
    % Name Input
    nameInput = uicontrol('Parent',nameBox,...
           'Style','edit',...
           'String', names{id});
       
    % Color Button
    colorBox = uix.HButtonBox('Parent', dialogBox, 'ButtonSize', [100, 25]);
    colorButton = uicontrol('Parent',colorBox,...
                            'Position',[89 20 70 25],...
                            'String','Change Color',...
                            'BackgroundColor', colors(id,:),...
                            'Callback',@(~,~) colorCallback);
       
    % Close
    uicontrol(  'Parent',dialogBox,...
                'String','Close',...
                'Callback', @(~,~) delete(dialogWindow));
       
    dialogBox.set('Heights', [20, 25, 25]);
              
    % Wait for d to close before running to completion
    uiwait(dialogWindow); 
    
    
   function colorCallback()
      color = uisetcolor(colors(id,:));
      colors(id,:) = color;
      colorButton.BackgroundColor = color;
      setappdata(handles.f,'colors',colors);
   end    

    function onClose()
        % save text (color is already saved)
        names{id} = nameInput.String;
        setappdata(handles.f,'ROINames',names);
        
        % update display
        handles.multiAxes.titleText{id}.String = nameInput.String;
        handles.multiAxes.editButton{id}.BackgroundColor = colors(id,:);
        updateParticleDetection(hObject);
    end
end

%% Brightness Callbacks
function setBrightness(hObject)
    handles = guidata(hObject);
    lowBrightness = get(handles.map.brightness.JavaPeer,'LowValue');
    highBrightness = get(handles.map.brightness.JavaPeer,'HighValue');
    if lowBrightness==highBrightness
        if lowBrightness==0
            set(handles.map.brightness.JavaPeer,'HighValue',highBrightness+1)
        else
            set(handles.map.brightness.JavaPeer,'LowValue',lowBrightness-1)
        end
    end
    
    updateDisplay(hObject,handles);
end

function autoBrightness(hObject, handles)    
    stack       = getappdata(handles.f,'data_mapping_originalStack');
    curretFrame = get(handles.axesControl.currentFrame.JavaPeer,'Value');
    timeAvg     = handles.map.timeAvgCheckbox.Value;

    % get frame
    if timeAvg
        I = timeAvgStack(stack);
    else
        I = stack(:,:,curretFrame);
    end

    % invert
    if handles.map.invertCheckbox.Value
        I = imcomplement(I);
    end

    % auto brightness
    autoImAdjust = stretchlim(I);
    autoImAdjust = round(autoImAdjust * get(handles.map.brightness.JavaPeer,'Maximum'));

    % set slider values
    set(handles.map.brightness.JavaPeer,'LowValue',autoImAdjust(1));
    set(handles.map.brightness.JavaPeer,'HighValue',autoImAdjust(2));
    
    % display autoed image
    updateDisplay(hObject,handles);
end

function setInvertVideo(hObject, handles, value)
    handles.map.invertCheckbox.Value = value;
    autoBrightness(hObject,handles); % this will also update the display
end

%% Frames
function setCurrentFrame(hObject, value)
    handles = guidata(hObject);
    set(handles.axesControl.currentFrame.JavaPeer,'Value',value);
    handles.axesControl.currentFrameTextbox.String = num2str(value);
    setappdata(handles.f,'mapping_currentFrame', value);
    updateDisplay(hObject,handles);
end

function setTimeAverageVideo(hObject, handles, value)

    handles.map.timeAvgCheckbox.Value = value;
    if value
        handles.axesControl.currentFramePanel.Visible = 'off';
    else
        handles.axesControl.currentFramePanel.Visible = 'on';
    end
    
    % this will call updateDisplay
    autoBrightness(hObject, handles);
end

%% Update Display
function updateDisplay(hObject,handles,particleFlag) 
    if ~exist('handles','var')
        handles = guidata(hObject);
    end
    
    % get values
    curretFrame     = get(handles.axesControl.currentFrame.JavaPeer,'Value');
    lowBrightness   = get(handles.map.brightness.JavaPeer,'LowValue')/get(handles.map.brightness.JavaPeer,'Maximum');
    highBrightness  = get(handles.map.brightness.JavaPeer,'HighValue')/get(handles.map.brightness.JavaPeer,'Maximum');
    invertImage     = handles.map.invertCheckbox.Value;
    timeAvg         = handles.map.timeAvgCheckbox.Value;
    colors          = getappdata(handles.f,'colors');
    combinedROIMask = getappdata(handles.f,'combinedROIMask');

    if strcmp(getappdata(handles.f,'mapping_mode'),'Overlay')
        % Display overalped stacks
        collocalisedSeperatedStacks = getappdata(handles.f,'data_mapping_collocalisedSeperatedStacks');
        combinedImage = rgbCombineSeperatedImages(cellfun(@(S) S(:,:,curretFrame), collocalisedSeperatedStacks, 'UniformOutput', false), colors);
        combinedImage = combinedImage .* cast( cat(3, combinedROIMask,combinedROIMask,combinedROIMask), class(combinedImage));
        handles.oneAxes.AxesAPI.replaceImage(combinedImage,'PreserveView',true);

        for i=1:size(collocalisedSeperatedStacks,1)
            % remove particle plots
            for p = 1:size(handles.multiAxes.plt{i},1)
                delete(handles.multiAxes.plt{i}{1})
                handles.multiAxes.plt{i}(1) = [];
            end
            
            % get and display
            I = cast(combinedROIMask, class(combinedImage)) .* collocalisedSeperatedStacks{i}(:,:,curretFrame);
            handles.multiAxes.AxesAPI{i}.replaceImage(I,'PreserveView',true);
        end
        guidata(hObject,handles);
    elseif  handles.axesPanel.Selection == 1
        stack = getappdata(handles.f,'data_mapping_originalStack');
        
        % current frame
        if timeAvg
            I = timeAvgStack(stack);
        else
            I = stack(:,:,curretFrame);
        end
        
        % invert
        if invertImage
            I = imcomplement(I);
        end
        
        % brightness
        I = imadjust(I, [lowBrightness highBrightness]);
        
        % display
        handles.oneAxes.AxesAPI.replaceImage(I,'PreserveView',true);
    elseif handles.axesPanel.Selection == 2
        seperatedStacks = getappdata(handles.f,'data_mapping_originalSeperatedStacks');
        particleSettings = getappdata(handles.f,'mapping_particleSettings');
        
        for i=1:length(seperatedStacks)
            % current frame
            if timeAvg
                I = timeAvgStack(seperatedStacks{i});
            else
                I = seperatedStacks{i}(:,:,curretFrame);
            end
            
            % invert
            if invertImage
                I = imcomplement(I);
            end
            I = imadjust(I);
            
            % remove particle plots
            for p = 1:size(handles.multiAxes.plt{i},2)
                delete(handles.multiAxes.plt{i}{1})
                handles.multiAxes.plt{i}(1) = [];
            end
            hold(handles.multiAxes.Axes{i},'on');
            
            if ~exist('particleFlag','var')
                handles.multiAxes.AxesAPI{i}.replaceImage(I,'PreserveView',true);
            else
                filterSize = particleSettings(i).filterSize;
                particleMinInt = particleSettings(i).minIntensity;
                particleMaxInt = particleSettings(i).maxIntensity;
                
                if filterSize > 0.1
                    I = imgaussfilt(I, filterSize);
                end
                I = imadjust(I);
                handles.multiAxes.AxesAPI{i}.replaceImage(I,'PreserveView',true);
                
                
                particles = findParticles(I, particleMinInt, particleMaxInt);
                centers = particles{1};
                
                
                % display particles found
                handles.multiAxes.plt{i} = cell(size(centers,1));
                for p=1:size(centers,1)
                    handles.multiAxes.plt{i}{p} = plot( handles.multiAxes.Axes{i}, centers(p,1), centers(p,2), '+');
                    handles.multiAxes.plt{i}{p}.set('Color',colors(i,:));
                end
            end
            hold(handles.multiAxes.Axes{i},'off');
            guidata(hObject,handles);
        end
    end
    
    updateSelectROI(hObject, handles);
end

function updateParticleDetection(hObject)
    hWaitBar = waitbar(0,'loading ...', 'WindowStyle', 'modal');
    
    handles = guidata(hObject);
    particleSettings = getappdata(handles.f,'mapping_particleSettings');
    numChannels = size(particleSettings,2);
        
    if handles.map.particleChannel.Value == 1
        for c=1:numChannels
            particleSettings(c).filterSize = handles.map.particleFilter.JavaPeer.get('Value') / handles.map.particleFilter.JavaPeer.get('Maximum') * 5;
            particleSettings(c).minIntensity = handles.map.particleIntensity.JavaPeer.get('LowValue');
            particleSettings(c).maxIntensity = handles.map.particleIntensity.JavaPeer.get('HighValue');
        end
    else
        channel = handles.map.particleChannel.Value-1;
        particleSettings(channel).filterSize = handles.map.particleFilter.JavaPeer.get('Value') / handles.map.particleFilter.JavaPeer.get('Maximum') * 5;
        particleSettings(channel).minIntensity = handles.map.particleIntensity.JavaPeer.get('LowValue');
        particleSettings(channel).maxIntensity = handles.map.particleIntensity.JavaPeer.get('HighValue');
    end
    setappdata(handles.f,'mapping_particleSettings',particleSettings); % save
    
    updateDisplay(hObject,handles,1); % parameter '1' added to add particles
    
    delete(hWaitBar);
end

function particleDetectionChangeChannel(hObject,handles)
    particleSettings = getappdata(handles.f,'mapping_particleSettings');
    numChannels = size(particleSettings,2);
    
    if handles.map.particleChannel.Value == 1
        for c=1:numChannels
            handles.map.particleFilter.JavaPeer.set('Value', round(particleSettings(c).filterSize * handles.map.particleFilter.JavaPeer.get('Maximum') / 5));
            handles.map.particleIntensity.JavaPeer.set('LowValue', particleSettings(c).minIntensity);
            handles.map.particleIntensity.JavaPeer.set('HighValue', particleSettings(c).maxIntensity);
        end
    else
        channel = handles.map.particleChannel.Value-1;
        handles.map.particleFilter.JavaPeer.set('Value', round(particleSettings(channel).filterSize * handles.map.particleFilter.JavaPeer.get('Maximum') / 5));
        handles.map.particleIntensity.JavaPeer.set('LowValue', particleSettings(channel).minIntensity);
        handles.map.particleIntensity.JavaPeer.set('HighValue', particleSettings(channel).maxIntensity);
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
    
    if ~strcmp(getappdata(handles.f,'mapping_mode'),'Loaded Map')
        updateDisplay(hObject,handles);
    end
end

function switchMode(hObject, handles, value)
    setappdata(handles.f,'mapping_mode',value);

    handles.rightPanel.Visible = 'off';
    handles.map.particlePanel.Visible = 'off';
    handles.map.changeROIPanel.Visible = 'off';
    handles.map.preProcPanel.Visible = 'off';
    handles.map.roiPanel.Visible = 'off';
    handles.axesControl.currentFramePanel.Visible = 'off';
    handles.axesControl.seperateButtonGroup.Visible =  'off';
    handles.map.saveMappingPanel.Visible = 'off';
    
    switch value
        case 'Select Video'
            handles.axesControl.currentFramePanel.Visible = 'on';
        case 'ROI'
            handles.rightPanel.Visible = 'on';
            handles.map.preProcPanel.Visible = 'on';
            handles.map.roiPanel.Visible = 'on';
            switchDisplayAxes(hObject, 1);
            updateDisplay(hObject,handles);
            handles.oneAxes.AxesAPI.setMagnification(handles.oneAxes.AxesAPI.findFitMag()); % zoom axes
                
            if handles.map.timeAvgCheckbox.Value
                handles.axesControl.currentFramePanel.Visible = 'off';
            else
                handles.axesControl.currentFramePanel.Visible = 'on';
            end
        case 'Particles'
            handles.rightPanel.Visible = 'on';
            handles.map.changeROIPanel.Visible = 'on';
            handles.map.particlePanel.Visible = 'on';
            switchDisplayAxes(hObject, 2);
            updateDisplay(hObject,handles,1);
        case 'Overlay'
            handles.rightPanel.Visible = 'on';
            handles.axesControl.seperateButtonGroup.Visible =  'on';
            handles.map.changeROIPanel.Visible = 'on';
            handles.map.saveMappingPanel.Visible = 'on';
            handles.axesControl.currentFramePanel.Visible = 'on';
            switchDisplayAxes(hObject, 1);
        case 'Loaded Map'
            handles.map.selectVideoTextBox.String = 'Mapping loaded from a session.';
            switchDisplayAxes(hObject, 1);
    end
end

function onDisplay(hObject,handles)
    % current frame
    stack = getappdata(handles.f,'data_mapping_originalStack');
    set(handles.axesControl.currentFrame.JavaPeer,'Maximum',size(stack,3));
    set(handles.axesControl.currentFrame.JavaPeer,'Value', getappdata(handles.f,'mapping_currentFrame'));
    set(handles.axesControl.currentFrameTextbox,'String', num2str(getappdata(handles.f,'mapping_currentFrame')));
    handles.axesControl.currentFrame.JavaPeer.set('MouseReleasedCallback', @(~,~) setCurrentFrame(handles.axesControl.currentFrame, get(handles.axesControl.currentFrame.JavaPeer,'Value')));
    handles.axesControl.currentFrameTextbox.set('Callback', @(hObject,~) setCurrentFrame( hObject, str2num(hObject.String)));
    % play button
    handles.axesControl.playButton.set('Callback', @(hObject,~) playVideo( hObject, guidata(hObject)));
    % axes control
    handles.axesControl.seperateButtonGroup.set('SelectionChangedFcn', @(hObject,event) switchDisplayAxes(hObject,str2num(event.NewValue.Tag))); 
    
    switchMode(hObject, handles, getappdata(handles.f,'mapping_mode'));
end

function onRelease(hObject,handles)
    setappdata(handles.f,'selectingROI', false);
    setappdata(handles.f,'mapping_currentFrame', get(handles.axesControl.currentFrame.JavaPeer,'Value'));
    
    %
    if isappdata(handles.f,'displacmentFields')
        if ~strcmp(handles.vid.selectVideoTextBox.String, 'No video selected')
            collocalizeVideo(hObject,handles);
        end
        if handles.dna.sourcePopUpMenu.Value ~= 1
            collocalizeDNAImport(hObject,handles);
        end
        if handles.fret.sourcePopUpMenu.Value ~=1
            collocalizeFRETImport(hObject,handles);
        end
        
        if isfield(handles,'multiAxes')
            % remove particle plots
            for i=1:size(handles.multiAxes.plt,1)
                % remove particle plots
                for p = 1:size(handles.multiAxes.plt{i},1)
                    delete(handles.multiAxes.plt{i}{1})
                    handles.multiAxes.plt{i}(1) = [];
                end
            end
            guidata(hObject,handles);
        end
    end
    
    homeInterface('openHome',hObject);
end

function updateMagnifcation(hObject,mag)    
    handles = guidata(hObject);
    
    for i=2:size(handles.multiAxes.AxesAPI,2)
        handles.multiAxes.AxesAPI{i}.setMagnification(mag);
    end
end

%% Registration
function registerMapping(hObject,handles)
    setappdata(handles.f,'isMapped',1);
    generateRegistration(hObject,handles);
    collocalizeMapping(hObject,handles);
    switchMode(hObject, handles, 'Overlay');
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
