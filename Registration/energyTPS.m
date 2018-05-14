function U = energyTPS(r)
% energyTPS - calculates the "bending" energy of a displacments r.
% There is a disconsinuity at r=0 which is 
% set to 0 or otherwise NaN would be returned.
    U = r.^2 .* log(r.^2+double(r==0)); 
end