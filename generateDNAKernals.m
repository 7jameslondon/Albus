function kernals = generateDNAKernals(lengths,widths,rotations)
    % pre-alloc cell array of kernals
    numKernals = length(lengths)*length(widths)*length(rotations);
    kernals = cell(numKernals,1);
    
    % create an array with combos of lengths, widths, rotations for parfor
    [A,B] = meshgrid(lengths,widths);
    combos = [repmat(reshape(cat(2,A',B'),[],2),length(rotations),1),...
              imresize(rotations',[length(lengths)*length(widths)...
              *length(rotations), 1],'nearest')];
    
    % interate through all posibilities
    parfor k = 1:numKernals
        kernals{k,1} = generateDNAKernal(combos(k,1),combos(k,2),combos(k,3));
    end
end

function kernal = generateDNAKernal(length,width,rotation)
    SE          = strel('line',length,0); % length
    element     = SE.Neighborhood;
    padTB       = padarray(element,width); % width
    padded      = padarray(padTB',width)'; % width
    filtered    = imgaussfilt(double(padded), width^(1/2)); % width
    rotated     = imrotate(filtered,rotation,'bicubic');
    kernal      = im2uint16(rotated);    
    kernal      = imadjust(kernal);
end
