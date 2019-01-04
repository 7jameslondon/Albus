function [ux, uy] = MLFitNoBg(data,X,Y)
    numT    = numel(data);
    dataT   = sum(data(:));

    ux  = mean(data(:).*X(:))/dataT*numT;
    uy  = mean(data(:).*Y(:))/dataT*numT;
end