function seperatedStacks = seperateStack(ROI,stack)
    seperatedStacks = cell(size(ROI,1),1); % pre-aloc
    for s=1:size(ROI,1)
        for i=1:size(stack,3)
            I = stack(:,:,i);
            
            % crop into sperated stacks
            I = imcrop(I , ROI(s,:) );
            
            seperatedStacks{s}(:,:,i) = I;
        end
    end
end