function exportColocalizedVideo(hObject)
    % where to save
    [saveName, savePath, ~] = uiputfile({'*.tiff'}, 'Export movie to:', 'movie.tiff'); 

    % get data
    hWaitBar = waitbar(0,'Exporting...', 'WindowStyle', 'modal');
    handles = guidata(hObject);
    
    % get the movie stack
    if getappdata(handles.f,'isMapped')
        colors = getappdata(handles.f,'colors');
        seperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');
        combinedROIMask = getappdata(handles.f,'combinedROIMask');
        
        stack = zeros([size(seperatedStacks{1},1), size(seperatedStacks{1},2), 3, size(seperatedStacks{1},3)], class(seperatedStacks{1}(:,:,1))); % pre-aloc
        seperatedFrames = cell(length(seperatedStacks),1);
        for f=1:size(seperatedStacks{1},3)
            for s=1:length(seperatedStacks)
                I = seperatedStacks{s}(:,:,f);
                
                % overalp mask
                I(~combinedROIMask) = 0;
                % brightness
                I(combinedROIMask) = imadjust(I(combinedROIMask));
            
                seperatedFrames{s} = I;
            end
            
            stack(:,:,:,f) = rgbCombineSeperatedImages(seperatedFrames, colors);
        end
        
        samplesPerPixel = 3;
        photometric = Tiff.Photometric.RGB;
    else
        stack = getappdata(handles.f,'data_video_stack');
        
        samplesPerPixel = 1;
        photometric = Tiff.Photometric.MinIsBlack;
    end
   
    
    % create the tiff data    
    tagstruct.ImageLength = size(stack,1);
    tagstruct.ImageWidth = size(stack,2);
    tagstruct.Photometric = photometric;
    if isa(stack,'uint8')
        tagstruct.BitsPerSample = 8;
    elseif isa(stack,'uint16')
        tagstruct.BitsPerSample = 16;
    else
        tagstruct.BitsPerSample = 8;
    end
    tagstruct.SamplesPerPixel = samplesPerPixel;
    tagstruct.RowsPerStrip = 16;
    tagstruct.Compression = Tiff.Compression.None; 
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software = 'MATLAB';
    
    % save the tiff data
    if getappdata(handles.f,'isMapped')
        t = Tiff([savePath,saveName],'w');
        setTag(t,tagstruct);
        write(t,stack(:, :, :, 1));
        close(t);

        for f=2:size(stack,4)
            waitbar(f/length(stack));
            t = Tiff([savePath,saveName],'a');
            setTag(t,tagstruct);
            write(t,stack(:, :, :, f));
            close(t);
        end
    else
        t = Tiff([savePath,saveName],'w');
        setTag(t,tagstruct);
        write(t,stack(:, :, 1));
        close(t);
        
        for f=2:size(stack,4)
            waitbar(f/length(stack));
            t = Tiff([savePath,saveName],'a');
            setTag(t,tagstruct);
            write(t,stack(:, :, :, f));
            close(t);
        end
    end

    delete(hWaitBar);
end