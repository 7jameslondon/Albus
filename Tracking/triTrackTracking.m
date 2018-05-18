function tracks = triTrackTracking( particlesByFrame, maxMovment )

    %% Check the inputs are valid
    if size(particlesByFrame,1) < 3
        error('Needs three frames')
    end
    
    hWaitBar = waitbar(0,'Tracking Particles...', 'WindowStyle', 'modal');
    
    %% Setup the required varibles
    numFrames = size(particlesByFrame,1);
    
    % Pre-allocate a matix to temporarly store the indexes of particle
    % tracks. It has one row for each track and one column for each frame.
    % blanks have the value 0.
    tracksIdx = zeros(0,numFrames);
    
    %% Find track indexs
    for f = 2:numFrames-1
        waitbar(f/numFrames);
        
        prevParticles = particlesByFrame{f-1};
        currParticles = particlesByFrame{f};
        nextParticles = particlesByFrame{f+1};
        
        idx = minCostMaxFlow(prevParticles,currParticles,nextParticles, maxMovment);
    
        %% Connect Triplets
        for i = 1:size(idx,1)
            % is the triplet completely new
            j = idx(i,1) == tracksIdx(:,f-1) & idx(i,2) == tracksIdx(:,f);
            if ~any(j) % new triplet
                tracksIdx(end+1,f-1:f+1) = idx(i,1:3);
            else % old triplet
                tracksIdx(j,f+1) = idx(i,3);
            end
        end
    end

    %% Get the positions of tracks
    % list of zeros
    z = zeros(size(tracksIdx,1),1);
    tracks = table(z,z,mat2cell(z,z+1,1),'VariableNames',{'Length','StartFrame','Positions'});
    for i = 1:size(tracksIdx,1)
        tracks.Length(i) = sum(tracksIdx(i,:)>0);
        frames = find(tracksIdx(i,:)~=0);
        idx = tracksIdx(i,frames);
        tracks.StartFrame(i) = frames(1);
        
        pos = zeros(size(idx,2),2);
        for j = 1:size(idx,2)
            pos(j,1:2) = particlesByFrame{frames(j)}(idx(j),1:2);
        end
        tracks.Positions(i) = {pos};
    end
    
    delete(hWaitBar);
end

