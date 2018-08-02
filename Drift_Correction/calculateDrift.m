function drift = calculateDrift(stack, minMeanPeakIntensity, maxMeanPeakIntensity, gaussFilterSigma, maxDistance)
    particlesByFrame = findParticles(stack,minMeanPeakIntensity,maxMeanPeakIntensity,gaussFilterSigma);
    
    tracks = triTrackTracking( particlesByFrame, maxDistance );
        
    %% Calculate drift vector    
    dur = size(stack,3);
    numChanges = zeros(dur,1);
    totChanges = zeros(dur,2);
    
    for i=1:size(tracks,1)        
        start = tracks.StartFrame(i);
        stop  = start + tracks.Length(i) - 1;
        
        numChanges(start:stop)    = numChanges(start:stop)    + ones(tracks.Length(i),1);
        totChanges(start:stop, :) = totChanges(start:stop, :) + [0,0; diff(tracks.Positions{i})];
    end

    avgChanges = totChanges ./ numChanges;
    avgChanges(isnan(avgChanges)) = 0;

    drift = cumsum(avgChanges,1);
end

