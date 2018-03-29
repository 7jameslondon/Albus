% handles = guidata(gcf);

kyms = getappdata(handles.f,'kyms');
seperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');

if exist('fig')
    try
        close(fig);
    end
end
figPos = [900 500 800 1000];
fig = figure('Name','TEST','Position',figPos);
pnl = uipanel('Parent',fig);
ax = axes(pnl);

frameNumber = 1;
particleMaxRadius = 3;
userErrorFactor = 1;

effectiveMaxRadius = userErrorFactor*particleMaxRadius;
I = seperatedStacks{2}(:,:,frameNumber);
pos = round(kyms.Position(2,:));
I = I(min(pos([2,4]))-effectiveMaxRadius : min(pos([2,4]))+effectiveMaxRadius , min(pos([1,3]))-effectiveMaxRadius : max(pos([1,3]))+effectiveMaxRadius);

hImage = imshow(I,'Parent',ax);
AxesScrollPanel = imscrollpanel(pnl,hImage);
AxesAPI = iptgetapi(AxesScrollPanel);
AxesAPI.setMagnification(20);
fig.set('Position',figPos);
plts = cell(0);

%% One Image

filterSize = 1;
particleMinInt = 0.7 * 2^16;
particleMaxInt = 1.0 * 2^16;

if filterSize > 0.1
    I = imgaussfilt(I, filterSize);
end
I = imadjust(I);
AxesAPI.replaceImage(I,'PreserveView',true);

particles = findParticles(I, particleMinInt, particleMaxInt);
centers = particles{1};

for i=1:size(plts,2)
    delete(plts{i});
end
plts = cell(0);

% display particles found
hold('on',ax);
for p=1:size(centers,1)
    plts{end+1} = plot( ax, centers(p,1), centers(p,2), '+r');
end
hold('off',ax);


%% Stack

filterSize = 1;
particleMinInt = 0.7 * 2^16;
particleMaxInt = 1.0 * 2^16;
maxParticleMovment = 3;

stack = seperatedStacks{2}(min(pos([2,4]))-effectiveMaxRadius : min(pos([2,4]))+effectiveMaxRadius , min(pos([1,3]))-effectiveMaxRadius : max(pos([1,3]))+effectiveMaxRadius, 300:600);
    
%%
particles = findParticles(stack, particleMinInt, particleMaxInt, filterSize);

movieFrames = struct('cdata',[],'colormap',[]);
for f=1:size(stack,3)
    for i=1:size(plts,2)
        delete(plts{i});
    end
    plts = cell(0);

    I = stack(:,:,f);
    if filterSize > 0.1
        I = imgaussfilt(I, filterSize);
    end
    I = imadjust(I);
    AxesAPI.replaceImage(I,'PreserveView',true);
    hold('on',ax);
    for p=1:size(particles{f},1)
        plts{end+1} = plot(ax,particles{f}(p,1), particles{f}(p,2), '.r');
    end
    hold('off',ax);
    drawnow;
    movieFrames(f) = getframe(ax);
end
implay(movieFrames)


%%

particleTracksByStack = nearestNeighborTracking(particles, maxParticleMovment);  

% lifetimes
largestID = 0;
largestSize = 0;
for i=1:size(particleTracksByStack,2)
    if size(particleTracksByStack(i).positions.rows,1) > largestSize
        largestID = i;
        largestSize = size(particleTracksByStack(i).positions.rows,1);
    end
end
largestID
largestSize
%%

movieFrames = struct('cdata',[],'colormap',[]);
for f=1:size(stack,3)
    for i=1:size(plts,2)
        delete(plts{i});
    end
    plts = cell(0);

    I = stack(:,:,f);
    if filterSize > 0.1
        I = imgaussfilt(I, filterSize);
    end
    I = imadjust(I);
    AxesAPI.replaceImage(I,'PreserveView',true);
    
    if sum(particleTracksByStack(largestID).positions.frames == f)
        id = find(particleTracksByStack(largestID).positions.frames == f);
        hold('on',ax);
        plts{end+1} = plot(ax, particleTracksByStack(largestID).positions.centers(1:id,1), particleTracksByStack(largestID).positions.centers(1:id,2), 'r');
        hold('off',ax);
    end
    drawnow;
    movieFrames(f) = getframe(ax);
end
implay(movieFrames)