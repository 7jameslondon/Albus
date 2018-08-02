function handles = createInterface(varargin)
    if nargin>=1
        if nargin && ischar(varargin{1})
            if nargout
                [varargout{1:nargout}] = feval(str2func(varargin{1}), varargin{2:end});
            else
                feval(str2func(varargin{1}), varargin{2:end});
            end
        end
    end

    %% Setup Main Figure
    handles = struct();
    handles.f = figure( 'Name','Albus 0.44', ...
                        'NumberTitle','off', ...
                        'ToolBar','figure', ...
                        'MenuBar','none', ...
                        'Units', 'characters', ...
                        'Position', [20 10 150 50], ...
                        'Visible', 'off',...
                        'DeleteFcn', @(hObject,~) closeProgram(hObject,guidata(hObject)));
   

    %% setup the toolbar
    try % 
        set(groot,'ShowHiddenHandles','on');
        mainTB = findobj(handles.f.Children,'Type','uitoolbar');

        tbFileOpen      = findobj(mainTB.Children,'Tag','Standard.FileOpen');
        tbSaveFigure    = findobj(mainTB.Children,'Tag','Standard.SaveFigure');
        tbDataCursor    = findobj(mainTB.Children,'Tag','Exploration.DataCursor');
        ttZoomIn        = findobj(mainTB.Children,'Tag','Exploration.ZoomIn');
        ttZoomOut       = findobj(mainTB.Children,'Tag','Exploration.ZoomOut');

        delete(setdiff(mainTB.Children,[tbFileOpen tbSaveFigure tbDataCursor ttZoomIn ttZoomOut]))

        tbSaveFigure.set('ClickedCallback',@(~,~) saveSession(handles.f));
        tbFileOpen.set('ClickedCallback',@(~,~) loadSession(handles.f));

        tbSaveFigure.set('TooltipString','Save Session');
        tbFileOpen.set('TooltipString','Load Session');
    catch
        delete(handles.f);
        handles.f = figure( 'Name','Albus 0.4', ...
                        'NumberTitle','off', ...
                        'ToolBar','none', ...
                        'MenuBar','none', ...
                        'Units', 'characters', ...
                        'Position', [20 10 150 50], ...
                        'Visible', 'off',...
                        'DeleteFcn', @(hObject,~) closeProgram(hObject,guidata(hObject)));
    end

    %% main framework
    handles.HBox = uix.HBox('Parent', handles.f);
    
    handles.leftPanelContainer = uix.Panel('Parent', handles.HBox);
    handles.rightPanelContainer = uix.Panel('Parent', handles.HBox);
    handles.HBox.set('Widths', [300, -1]);
    
    handles.leftPanel = uix.CardPanel('Parent', handles.leftPanelContainer);
    handles.rightPanel = uix.CardPanel('Parent', handles.rightPanelContainer,...
                                       'Visible', 'off');
    handles.rightPanelAxes = uix.VBox('Parent', handles.rightPanel,...
                                      'Visible', 'off');
                              

    %% control panel
    handles.axesControl = struct();
    handles.axesControl.Panel = uix.Panel('Parent', handles.rightPanelAxes);
    handles.axesPanelContainer = uix.Panel('Parent', handles.rightPanelAxes);
    handles.axesPanel = uix.CardPanel('Parent', handles.axesPanelContainer);
    handles.axesPanel.set('Padding',5);
    handles.rightPanelAxes.set('Heights', [100, -1]);

    handles.axesControl.VBox = uix.VBox('Parent', handles.axesControl.Panel);
    handles.axesControl.seperateButtonGroup = uibuttongroup('Parent', handles.axesControl.VBox,...
                                                            'Visible','off',...
                                                            'BorderType', 'none');
    handles.axesControl.overlapAxesButton = uicontrol(  'Parent', handles.axesControl.seperateButtonGroup, ...
                                                        'Style','radiobutton',...
                                                        'Position',[0 0 100 30],...
                                                        'String','Overlap Axes',...
                                                        'Tag', '1');
    handles.axesControl.seperateAxesButton = uicontrol( 'Parent', handles.axesControl.seperateButtonGroup, ...
                                                        'Style','radiobutton',...
                                                        'Position',[100 0 100 30],...
                                                        'String','Seperate Axes',...
                                                        'Tag', '2');
    
    
    % current frame slider
    setappdata(handles.f,'Playing_Video',0);
    handles.axesControl.currentFramePanel = uix.VBox(   'Parent', handles.axesControl.VBox,...
                                                        'Padding', 5);
                                                    
    handles.axesControl.playContolsBox = uix.HButtonBox('Parent', handles.axesControl.currentFramePanel,...
                                                        'ButtonSize',[80,25]);
                                                    
    handles.axesControl.playButton = uicontrol( 'Parent', handles.axesControl.playContolsBox, ...
                                                'String','Play');
                                            
    uicontrol(  'Parent', handles.axesControl.playContolsBox, ...
                'Style','text',...
                'String','Play Speed:');
                                            
    handles.axesControl.playSpeedBox = uix.HButtonBox('Parent', handles.axesControl.playContolsBox,...
                                                      'ButtonSize',[30,25]);
            
    handles.axesControl.playSpeed = uicontrol(  'Parent', handles.axesControl.playSpeedBox, ...
                                                'Style','edit',...
                                                'String','1',...
                                                'Callback', @(hObject,~) setPlaySpeed(hObject,guidata(hObject),str2double(hObject.String)));
                                                        
    handles.axesControl.currentFrameBox = uix.HBox('Parent', handles.axesControl.currentFramePanel);

    uicontrol(  'Parent', handles.axesControl.currentFrameBox, ...
                'Style','text',...
                'String','Frame');
    
    [~, handles.axesControl.currentFrame] = javacomponent('javax.swing.JSlider');
    handles.axesControl.currentFrame.set('Parent', handles.axesControl.currentFrameBox);
    handles.axesControl.currentFrame.JavaPeer.set('Maximum', 2);
    handles.axesControl.currentFrame.JavaPeer.set('Minimum', 1);
    handles.axesControl.currentFrame.JavaPeer.set('Value', 1);
    
    handles.axesControl.currentFrameTextbox = uicontrol('Parent', handles.axesControl.currentFrameBox, ...
                                                       	'Style','edit',...
                                                        'String','1');
    
    handles.axesControl.currentFrameBox.set('Widths',[35 -1 37]);
    
    handles.axesControl.currentFramePanel.set('Heights',[35 35]);
    
    handles.axesControl.VBox.set('Heights', [30, 70]);

    %% one axes
    handles.oneAxes = struct();
    handles.oneAxes.Panel = uipanel('Parent', handles.axesPanel,...
                                       'BorderType', 'none');
    handles.oneAxes.Axes = axes(handles.oneAxes.Panel);
    hImage = imshow(rand(1000),'Parent',handles.oneAxes.Axes);
    handles.oneAxes.AxesScrollPanel = imscrollpanel(handles.oneAxes.Panel,hImage);
    handles.oneAxes.AxesAPI = iptgetapi(handles.oneAxes.AxesScrollPanel);
    handles.oneAxes.AxesAPI.setMagnification(1001);
    % magnification box
    handles.oneAxes.magBox = immagbox(handles.oneAxes.AxesScrollPanel, hImage);
    magBoxPos = get(handles.oneAxes.magBox,'Position');
    set(handles.oneAxes.magBox,'Position',[0 0 magBoxPos(3) magBoxPos(4)]);
    
    %% kympgraph right panel
    handles.kym = struct();
    handles.rightPanelKym   = uix.Panel('Parent', handles.rightPanel, 'BorderType', 'none');
    
    %% traces right panel
    handles.tra = struct();
    handles.rightPanelTra   = uix.Panel('Parent', handles.rightPanel, 'BorderType', 'none');
        
    %% create sub-interfaces
    handles = homeInterface(                    'createInterface',handles);
    handles = videoSettingInterface(            'createInterface',handles);
    handles = mappingInterface(                 'createInterface',handles);
    handles = generateKymographInterface(       'createInterface',handles);
    handles = analyzeKymographInterface(        'createInterface',handles);
    handles = generateFRETInterface(            'createInterface',handles);
    handles = analyzeFRETInterface(             'createInterface',handles);
    handles = driftInterface(                   'createInterface',handles);
    handles = generateFlowStrechingInterface(	'createInterface',handles);
    handles = analyzeFlowStrechingInterface(	'createInterface',handles);

    %% save and display
    handles.rightPanel.Selection = 1;% start with the default right panel
    handles.leftPanel.Selection = 1; % start with the home left panel
    guidata(handles.f,handles);
end

function setPlaySpeed(hObject, handles, value)
    value = min(value,100);
    value = max(value,1);
    
    setappdata(handles.f, 'playSpeed', value);
    handles.kym.playSpeed.String = num2str(value);
    handles.axesControl.playSpeed.String = num2str(value);
end
