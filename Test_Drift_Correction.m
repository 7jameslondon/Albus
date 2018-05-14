%%
handles = guidata(gcf);
stack = getappdata(handles.f,'data_video_stack');

%% find particles in a frame
minMeanPeakIntensity = 0.8*2^16;
maxMeanPeakIntensity = 2^16;
gaussFilterSigma     = 0.3;
I = stack(:,:,1);
figure(2)
imshow(imadjust(I));
particlesByFrame = findParticles(I,minMeanPeakIntensity,maxMeanPeakIntensity,gaussFilterSigma,'DisplayAxes',gca);

%% find particles in every frame
particlesByFrame = findParticles(stack,minMeanPeakIntensity,maxMeanPeakIntensity,gaussFilterSigma);

%% track all particles
maxDist = 3;
tic;
tracks = triTrackTracking( particlesByFrame(1:5), maxDist );
toc

%% Calculate drift vector
dur = size(stack,3);
numChanges = zeros(dur,1);
totChanges = zeros(dur,2);
for i=1:size(tracks,1)
    start = tracks.StartFrame(i);
    stop  = start + tracks.Length(i) - 1;
    numChanges(start:stop) = numChanges(start:stop) + ones(tracks.Length(i),1);
    totChanges(start:stop, :) = totChanges(start:stop, :) + [0,0; [diff(tracks.Positions{i}(:,1)), diff(tracks.Positions{i}(:,2))]];
end

avgChanges = totChanges ./ numChanges;
avgChanges(isnan(avgChanges)) = 0;

drift = cumsum(avgChanges,1);

%% Correct for drift
originalSize = size(stack(:,:,1));

tempStack = cell(dur,1); % pre-aloc
for i=1:dur
    I = stack(:,:,i);
    tForm = affine2d([1 0 -drift(i,1); 0 1 -drift(i,2); 0 0 1]);
    J = imwarp(I, tForm, 'OutputView', OutputView);
    tempStack{i} = J;
    imshowpair(I,J,'montage');
end


%% PLOT ALL TRACKS
figure(4)
hold on;
for i=1:size(tracks,1)
    plot(tracks.Positions{i}(:,1),tracks.Positions{i}(:,2));
end
hold off;
