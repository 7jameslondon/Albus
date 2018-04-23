function rgbI = rgbCombineSeperatedImages( seperatedImages, colors)
    % seperatedImages = cellfun(@(x) imadjust(x), seperatedImages, 'UniformOutput', false); % autobrightness each image
    colorImageFun = @(i) cat(3, seperatedImages{i}*colors(i,1), seperatedImages{i}*colors(i,2), seperatedImages{i}*colors(i,3));
    seperatedRGBImages = arrayfun(colorImageFun, (1:length(seperatedImages)), 'UniformOutput', false); % color each image
    rgbI = cast(sum(cat(4,seperatedRGBImages{:}),4), class(seperatedImages{1}(1,1,1))); % combine into one rgb image
end

