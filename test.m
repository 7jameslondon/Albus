re = zeros(size(traces,1),1)
for i = 1:size(traces,1)
    [~, b] = min(FRETCorr(traces.Donor(i,90:660),traces.Acceptor(i,90:660)));
    re(i) = b < 580 && b > 560;
end
sum(re)