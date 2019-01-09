minJ        = 14000;
logWidth    = 0.35;
boundRadius = 4;

tracker = trackerGNN(   'MaxNumTracks', 100,...
                        'AssignmentThreshold', 3,...
                        'FilterInitializationFcn', 'initcvabf',...
                        'TrackLogic', 'Score',...
                        'DeletionThreshold', inf,...
                        'DetectionProbability', 0.9,...
                        'FalseAlarmRate', 0.01);

positions = cell(size(S,3),1);
for f = 1:size(S,3)
    particles = MLDetector(S(:,:,f), minJ,logWidth,boundRadius,'MLE Center Only');
    
    detections = cell(size(particles,2),1);
    
    if ~isempty(particles)
        positions{f} = [[particles.x]', [particles.y]'];
        for i = 1:size(particles,2)
            detections{i} = objectDetection(f,[particles(i).x, particles(i).y]);
        end
    end
    tracker(detections,f);
end
            
