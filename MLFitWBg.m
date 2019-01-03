function [ux, uy, s, A, B, R] = MLFitWBg(data,X,Y)
    
    numT    = numel(data);
    dataT   = sum(data(:));
    
    % Calculate center which not effected by backgound
    ux  = mean(data(:).*X(:))/dataT*numT;
    uy  = mean(data(:).*Y(:))/dataT*numT;
    
    % Pre-calculate the sigma nuemerator that will not change
    sXY = (X - ux).^2 + (Y - uy).^2;
        
    % Find the background level that minimses the residual
    B = fminbnd_striped(@(B) risidual(B), 0, dataT/numT);
    
    % calculate the final residual
    R = risidual(B);
        
    function R = risidual(B)
        
        A   = dataT - B*numT;
        s   = sum( sXY .* (data - B) / (A*2) , 'all');
    
        fitData = A * exp(sXY/(-2*s)) / (2*pi*s) + B;

        R = sum(abs(data - fitData),[1 2]);
        
    end
    
end