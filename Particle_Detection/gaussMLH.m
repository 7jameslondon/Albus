function [xCenter, yCenter, amplitude, width]=gauss2dcirc(x, y, z, noiselevel)
% maximum liklyhood gaussian fitting

z = z + eps; % so that all are atleast non-zero

% calculate weights using noise
noise = log(max(z+noiselevel,1e-10)) - log(max(z-noiselevel,1e-20)); 
weights = 1./noise;
weights(z<=0) = 0; % floor at zero

n = [x y log(z) ones(size(x))].*(weights*ones(1,4)); 
d = -(x.^2 + y.^2).*weights;
a = n \ d;

xCenter     = -0.5*a(1);
yCenter     = -0.5*a(2);
width       = sqrt(a(3)/2); 
amplitude   = exp((a(4)-xCenter^2-yCenter^2)/(-2*width^2));
