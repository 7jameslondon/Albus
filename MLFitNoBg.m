function [ux, uy] = MLFitNoBg(data,X,Y)
    numT    = size(data(:),1);
    dataT   = sum(data(:));

    ux  = mean(data(:).*X(:))/dataT*numT;
    uy  = mean(data(:).*Y(:))/dataT*numT;
end