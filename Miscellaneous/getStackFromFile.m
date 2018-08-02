function [stack, maxIntensity] = getStackFromFile( filePath, hWaitbar, imageFlag )
    % Sets 'stack' to 0 if an error is encountered and displayes the error
    % message in a pop-up.
    
    try
        videoInfo = imfinfo(filePath);
        
        if length(videoInfo) < 2 && (~exist('imageFlag','var') || ~imageFlag)
            error('This is a single image not a video');
        end
        
        switch videoInfo(1).BitDepth
            case 8
                intType = 'uint8';
            case 16
                intType = 'uint16';
            case 32
                intType = 'uint32';
            case 64
                intType = 'uint64';
        end
        maxIntensity = 2^videoInfo(1).BitDepth;
        
        stack = zeros(videoInfo(1).Height, videoInfo(1).Width, length(videoInfo), intType); % pre-aloc
        warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning');
        tiffLink = Tiff(filePath, 'r');
        
        % read in video frame by frame
        % will use a progress bar if it exists
        if exist('hWaitbar') ~= 0
            for iFrame = 1:length(videoInfo)
               tiffLink.setDirectory(iFrame);
               stack(:,:,iFrame) = tiffLink.read();
               waitbar(iFrame/length(videoInfo),hWaitbar);
            end
        else
            for iFrame = 1:length(videoInfo)
               tiffLink.setDirectory(iFrame);
               stack(:,:,iFrame) = tiffLink.read();
            end
        end

        tiffLink.close();
        warning('on','MATLAB:imagesci:tiffmexutils:libtiffWarning');
    catch ME
        msgbox(ME.message);
        stack=0;
        maxIntensity=0;
    end
end

