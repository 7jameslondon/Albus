function tracks = nearestNeighborTracking( particlesByFrame, maxMovment )
    % tracks ->   frames: (centerX centerY frame row)
    tracks(size(particlesByFrame,1)*size(particlesByFrame{1},1)).positions = []; % preallocate with guess for size of particles

    % For each particle in each frame see is there a particle with in
    % maxParticleMovment in the next frame. If so add it to particles.
        
    iParticle = 1;
    for currentFrame = 1:size(particlesByFrame,1)
        for currentParticle = 1:size(particlesByFrame{currentFrame},1)
            % if the particle is not already in particles
            if size(particlesByFrame{currentFrame}(currentParticle,:),2) ~= 4 || particlesByFrame{currentFrame}(currentParticle,4) ~= 1
                tracks(iParticle).positions.centers(1,:) = particlesByFrame{currentFrame}(currentParticle,1:2);
                tracks(iParticle).positions.frames(1,:) = currentFrame;
                tracks(iParticle).positions.rows(1,:) = currentParticle;

                % check future frames for neighbors
                for futureFrame = currentFrame+1:size(particlesByFrame,1)
                    distancesToParticles = sqrt( sum( ( tracks(iParticle).positions.centers(end,:) - particlesByFrame{futureFrame}(:,1:2) ).^2 , 2 ) );
                    [closestDistance, closestParticle] = min(distancesToParticles);
                    if closestDistance <= maxMovment
                        % add closest neighbor to particles and mark as used                        
                        tracks(iParticle).positions.centers(end+1,:) = particlesByFrame{futureFrame}(closestParticle,1:2);
                        tracks(iParticle).positions.frames(end+1,:) = futureFrame;
                        tracks(iParticle).positions.rows(end+1,:) = closestParticle;
                        
                        particlesByFrame{futureFrame}(closestParticle,4) = 1;
                    else
                        break;
                    end
                end
                
                iParticle = iParticle + 1;
            end
        end
    end
    
    % remove any empty rows from particles due to over preallocation
    tracks(iParticle:end) = [];
end