function stack = colocalizeStack( stack, tForm, OutputView )
    for iFrame = 1:size(stack,3)
        stack(:,:,iFrame) = imwarp( stack(:,:,iFrame), tForm, 'OutputView', OutputView );
    end
end

