function c = flowCost(rkm1,rk,rkp1)

% weights
l1 = 0.5;
l2 = 0.5;

% direction coherance
d = dot(rk-rkm1,rkp1-rk)/(norm(rk-rkm1)*norm(rkp1-rk));
if isnan(d)
    d = 1;
end

% speed coherance
s = 2*sqrt(norm(rk-rkm1)*norm(rkp1-rk))/(norm(rk-rkm1)+norm(rkp1-rk));
if isnan(s)
    s = 1;
end

% cost
c = l1*(1-d) + l2*(1-s) ;

% normalize the value such that it is between 0 and -1
c = -1/(c+1);

end

