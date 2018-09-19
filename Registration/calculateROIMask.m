function calculateROIMask(~,handles)
    % Get data
    displacmentFields = getappdata(handles.f, 'displacmentFields');
    drift             = getappdata(handles.f, 'drift');
    
    % Iterate through each channel
    if getappdata(handles.f,'isMapped')
        ROI = getappdata(handles.f,'ROI');
        numChannels = size(ROI,1);
        
        ROIofOnes = ones([size(displacmentFields{2},1), size(displacmentFields{2},2)]);
        combinedROIMask = ROIofOnes;
        
        for s = 2:numChannels % no parfor as findParticles has parfor
            combinedROIMask = combinedROIMask .* imwarp(ROIofOnes, displacmentFields{s});
        end
    else
        % Start a mask of the overlapping channels
        videoSize  = getappdata(handles.f,'video_size');
        ROIofOnes = ones(videoSize(1:2));

        % Crop out section from video setting croping
        videoImrectPos = round(getappdata(handles.f, 'vid_imrectPos'));
        videoSettingsSelection = ROIofOnes;
        x1 = max(videoImrectPos(2),1);
        y1 = max(videoImrectPos(1),1);
        x2 = min(videoImrectPos(2)+videoImrectPos(4),videoSize(1));
        y2 = min(videoImrectPos(1)+videoImrectPos(3),videoSize(2));
        videoSettingsSelection( x1:x2, y1:y2) = 0;
        ROIofOnes(logical(videoSettingsSelection)) = 0;
        combinedROIMask = ROIofOnes;
    end
    
    % Calculate mask from drift
    if handles.drift.applyCorrection.Value
        % Output view
        outputview = imref2d(size(combinedROIMask));
        
        originalROIMask = combinedROIMask;
        
        dur = handles.vid.cutting.JavaPeer.get('HighValue') - handles.vid.cutting.JavaPeer.get('LowValue') + 1;
    
        for i=1:dur
            tForm = affine2d([1 0 -drift(i,1); 0 1 -drift(i,2); 0 0 1]');
            combinedROIMask = combinedROIMask .* imwarp(originalROIMask, tForm, 'OutputView', outputview, 'Interp', 'Cubic');
        end
    end
        
    % Save
    combinedROIMask = logical(combinedROIMask);
    setappdata(handles.f,'combinedROIMask',combinedROIMask);
end