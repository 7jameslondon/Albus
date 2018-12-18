    %% Setup/Import
    mpath = fileparts(which(mfilename));
    addpath([mpath '/Registration']);
    addpath([mpath '/Interface']);
    addpath([mpath '/Tracking']);
    addpath([mpath '/Particle_Detection']);
    addpath([mpath '/DNA_Detection']);
    addpath([mpath '/Drift_Correction']);
    addpath([mpath '/Miscellaneous']);

    filePath = ['/Users/jameslondon/Documents/Fishel Lab/JL Nature Data/2016-',...
                '01-12_Ecoli_10nM MutS Alexa 647_20nM MutL Cy3 R95F_1mM ATP_1',...
                '00mM NaCl_DoubleBiotn17KbSMPL_300ms_0.6sec Timelapse/MutS+Mu',...
                'tL 1A_Sytox_400ms_1/MutS+MutL 1A_Sytox_400ms_1_MMStack_Pos0.',...
                'ome.tif'];

    [stack, maxIntensity] = getStackFromFile(filePath);
    I = timeAvgStack(stack);
    I = I(:,1:240);

    %%

    lengths = (13);
    widths  = (2);
    rotations = (0:10);
    dnaMatchingStrength = 80;

    kernals = generateDNAKernals(lengths,widths,rotations);
    kernal = kernals{1};

    f = figure(1);
    subplot(1,2,1);
    imshow(I);
    subplot(1,2,2);
    imshow(kernal);

    % f2 = figure(2);
    % for i=1:length(kernals)
    %     subplot(10,length(kernals)/10,i);
    %     imshow(kernals{i});
    % end

    %% Prepare image
    J = adapthisteq(I,'Distribution','rayleigh','ClipLimit',0.005);

    fullCor = normxcorr2(kernal,J); % between -1 and 1
    fullCor = (fullCor+1)/2; % between 0 and 1
    cor = imcrop(fullCor,[size(kernal,2) size(kernal,1) size(J,2) size(J,1)]);
    regMax = imregionalmax(cor);
    validCors = cor.*regMax;

    if exist('f','var')
        delete(f);
    end
    f = uifigure('Name', 'Plotted Results');
    
    handles = guidata(f);

    handles.g = uigridlayout(f);
    handles.g.RowHeight = {'1x',200,40};
    handles.g.ColumnWidth = {'1x'};

    handles.imageAxes = uiaxes(handles.g);
    imshow(I,'parent',handles.imageAxes);

    handles.matchStrengthAxes = uiaxes(handles.g);
    histogram(validCors(validCors~=0), 100, 'parent', handles.matchStrengthAxes);

    handles.validCors = validCors;
    handles.kernal = kernal;
    
    handles.linesH = cell(0);
    handles.matchStrengthSlider = uislider(handles.g,'Value',90);
    handles.matchStrengthSlider.ValueChangedFcn = @(hObject,~) updateMatchStrength(hObject,guidata(hObject));

    guidata(f,handles);
    
    updateMatchStrength(handles.matchStrengthSlider,handles);

    function updateMatchStrength(matchStrengthSlider,handles)
        wb = waitbar(0,'Please wait...','WindowStyle', 'modal');
            
        selectedCor = handles.validCors >= matchStrengthSlider.Value/100;
        [row,col] = find(selectedCor);

        if isfield(handles,'linesH')
            for i = 1:size(handles.linesH,1)
                delete(handles.linesH{i,1});
            end
        end

        handles.linesH = cell(size(row,1),1);
        hold(handles.imageAxes,'on');
        for i=1:size(row,1)
            handles.linesH{i,1} = line(handles.imageAxes,...
                                        [1 1]*col(i)+[0 1]*size(handles.kernal,2),...
                                        [1 1]*row(i)+size(handles.kernal,1)/2,'LineWidth',1);
        end
        hold(handles.imageAxes,'off');
        
        guidata(matchStrengthSlider,handles);
        
        delete(wb);
    end
