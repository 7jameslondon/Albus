function dwellTimes = FRETDwellTimes(traces)
    numTraces   = size(traces,1);
    dwellTimes  = cell(1,1);
    
    traces(isnan(traces)) = 0;
    
    for i = 1:numTraces
        trace = traces(i,:);
        states = unique(trace,'sorted');
        
        if length(states) == 1
            continue;
        end
        
        % add new state to dwellTimes if nessasary
        if size(dwellTimes,1) < length(states)
            dwellTimes(end+1:length(states),1) = cell(length(states)-size(dwellTimes,1),1);
        end
        
        % fill in dwell times
        for s = 1:length(states)
            % Equals 1 when in state, .5 at transitions, and 0 otherwise
            locations = movmean(trace == states(s), 2, 'Endpoints', 0);
            locations(end) = locations(end)/2; % nessasary for end-endpoint
            
            % Sets regions at ends to 0 if on
            if locations(1) == 0.5
                rmvInd = find(locations==0.5, 2);
                locations(rmvInd(1):rmvInd(2)) = 0;
            end
            if locations(end) == 0.5
                rmvInd = find(locations==0.5, 2, 'last');
                locations(rmvInd(1):rmvInd(2)) = 0;
            end
            
            allTimes = diff(find(locations==0.5));
            
            if isempty(allTimes)
                continue;
            end
            
            dwellTimes{s,1}(end+1:end+((length(allTimes)+1)/2)) = allTimes(1:2:end);
        end
    end
end