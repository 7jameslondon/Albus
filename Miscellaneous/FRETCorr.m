function avgCor = FRETCorr(donor, acceptor)
    numTraces = size(donor,1);
    lenTrace  = size(donor,2);
    totalCor  = zeros(1,lenTrace);
    
    for i = 1:numTraces
        m_donor       = mean(donor(i,:));
        m_acceptor    = mean(acceptor(i,:));

        if m_donor + m_acceptor == 0
            cor = zeros(1,lenTrace);
        else
            corUnNormFull = conv( fliplr(donor(i,:)) - m_donor , acceptor(i,:) - m_acceptor);
            corUnNormHalf = corUnNormFull(lenTrace:end);
            cor           = corUnNormHalf / (m_donor + m_acceptor); %./ (lenTrace:-1:1); (not sure if this normalization should be included)
        end
        
        totalCor = totalCor + cor;
    end
    
    avgCor = totalCor/numTraces;
end