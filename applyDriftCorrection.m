function stack = applyDriftCorrection(stack,drift)
    
    if isempty(drift)
        return;
    end
    
    outputview = imref2d(size(stack(:,:,1)));

    for i=1:size(stack,3)
        I = stack(:,:,i);
        tForm = affine2d([1 0 -drift(i,1); 0 1 -drift(i,2); 0 0 1]');
        stack(:,:,i) = imwarp(I, tForm, 'OutputView', outputview,'Interp','Cubic');
    end
    
end

