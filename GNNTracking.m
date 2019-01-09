function tracks = GNNTracking( positions, maxLRMovment, maxUDMovment )

    maxDist = maxLRMovment^2 + maxUDMovment^2;
    numFrames = size(positions,1);
    maxNum = max(arrayfun( @(i) size(positions{i},1), 1:numFrames));

    %% Particles -> Segments
    segments = zeros(maxNum*numFrames,numFrames); % pre-alloc
    
    s = size(positions{1},1);
    segments(1:s,1) = 1:s;

    for f = 1:numFrames-1
        posF  = positions{f};
        posF1 = positions{f+1};

        numF  = size(posF,1);
        numF1 = size(posF1,1);

        if numF1 == 0
            continue;
        elseif numF ==0
            segments(s+1:s+numF1, f+1) = 1:numF1;
            s = s+numF1;
            continue;
        end

        distXY = repmat(posF,1,1,numF1) - permute(repmat(posF1,1,1,numF),[3 2 1]);
        distXY(distXY(:,1,:) > maxLRMovment) = inf;
        distXY(distXY(:,2,:) > maxUDMovment) = inf;
        cost = permute(sum(distXY .^ 2,2),[1 3 2]);
        
        [assignments,~,unassignedcolumns] = assignauction(cost, maxDist);
        
        % assignments
        for i = 1:size(assignments,1)
            idF  = assignments(i,1);
            idF1 = assignments(i,2);
            
            segments(segments(:,f)==idF, f+1) = idF1;
        end
        
        % unassigned
        segments(s+1:s+size(unassignedcolumns,1),f+1) = unassignedcolumns;
        s = s+size(unassignedcolumns,1);
    end
    
    segments = segments(1:s,:);
    
    %% Segments -> Tracks
    numSegs = size(segments,1);
    tracks = struct;
    
    for s = 1:numSegs
        seg = segments(s,:)';
        segStart = find(seg,1);
        segEnd   = find(seg,1,'last');
        
        tracks(s).positions.frames = segStart:segEnd;
        
        for f = segStart:segEnd
            tracks(s).positions.centers(f-segStart+1,1:2) = positions{f}(seg(f),:);
        end
    end
    
    %% Segments -> Gap Costs
    segStartEnds    = [[0;0;0;0;] segments] - [segments [0;0;0;0;]];
    segStarts       = segments(startEndsSegs(:,1:end-1) == -1);
    segEnds         = segments(startEndsSegs(:,2:end) == 1);
    
    numSegs = size(segments,1);
    costs = zeros(numSegs);
    
    for s = 1:numSegs
        seg = segments(s,:);
                
        
        
        costs
    end

end

