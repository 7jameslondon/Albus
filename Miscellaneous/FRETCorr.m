function avgCor = FRETCorr(donor, acceptor)
    numTraces = size(donor,1);
    lenTrace  = size(donor,2);
    totalCor  = zeros(1,lenTrace*2-1);
    
    donorM      = donor - mean(donor,2);
    acceptorM   = acceptor - mean(acceptor,2);
    
    for i = 1:numTraces
        totalCor = totalCor + xcorr( donorM(i,:) , acceptorM(i,:) );
    end
    
    avgCor = totalCor / lenTrace / numTraces;
end