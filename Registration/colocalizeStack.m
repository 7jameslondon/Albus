function stack = colocalizeStack( stack, displacmentField )
    for iFrame = 1:size(stack,3)
        stack(:,:,iFrame) = imwarp( stack(:,:,iFrame), displacmentField);
    end
end

