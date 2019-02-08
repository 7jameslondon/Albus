mpath = ['/Users/jameslondon/Documents/Fishel Lab/Albus'];
addpath([mpath '/Registration']); addpath([mpath '/Interface']);
addpath([mpath '/Tracking']); addpath([mpath '/Particle_Detection']);
addpath([mpath '/DNA_Detection']); addpath([mpath '/Drift_Correction']);
addpath([mpath '/Miscellaneous']);
filePath = ['/Users/jameslondon/Documents/Fishel Lab/JL Nature Data/2016-',...
            '01-12_Ecoli_10nM MutS Alexa 647_20nM MutL Cy3 R95F_1mM ATP_1',...
            '00mM NaCl_DoubleBiotn17KbSMPL_300ms_0.6sec Timelapse/MutS+Mut',...
            'L 1_300ms_1/MutS+MutL 1_300ms_1_MMStack_Pos0.',...
            'ome.tif'];
[stack, maxIntensity] = getStackFromFile(filePath);
S = stack(48:48+13,323:323+21,1:100);
%S = stack(1:200,323:end,1:100);

fig = figure(1);
imshow(imadjust(imcomplement(S(:,:,1))));
%%
tic;
minJ        = 14000;
logWidth    = 0.35;
boundRadius = 3;

positions = cell(size(S,3),1);

parWaitbar('start', 'Detecting', size(S,3));
for f = 1:size(S,3)
    parWaitbar;
    particles = MLDetector(S(:,:,f), minJ,logWidth,boundRadius,'MLE Hill');
    if ~isempty(particles)
        positions{f} = [[particles.x]', [particles.y]'];
    end
%     imshow(imadjust(imcomplement(S(:,:,f))));
%     hold on;
%     plot(positions{f}(:,1),positions{f}(:,2),'.r');
%     hold off;
end
toc
parWaitbar('done');


%%
minJ        = 10000;
logWidth    = 0.35;
boundRadius = 3;

positions = cell(size(S,3),1);
f = 9;
particles = MLDetector(S(:,:,f), minJ, logWidth, boundRadius, 'WLS');
fig = figure(1);
ax = axes;
im = imshow(imadjust(imcomplement(S(:,:,f))));
hold on;
viscircles(ax,[[particles.x]',[particles.y]'],[particles.s]'/2);
hold off;


%% Tri Track
maxDist     = 5;
tracks = triTrackTracking( positions, maxDist );

%% Tri Track Plot
figure(4)
%imshow([imadjust(imcomplement(timeAvgStack(S))), imadjust(imcomplement(timeAvgStack(S)))]);
imshow(imadjust(imcomplement(timeAvgStack(S))));
hold on;
for i=1:size(tracks,1)
    pos = cell2mat(tracks.Positions(i));
    if tracks.Length(i) > 10 && abs(min(pos(:,2)) - max(pos(:,2))) > 0
        
        plot(pos(:,1),pos(:,2),'.-');
    end
end
hold off;

%% Tri Track Movie
f = figure(5)
ax = axes(f);
im = imshow(imadjust(imcomplement(S(:,:,1))),'Parent',ax);

h = imscrollpanel(f, im);
api = iptgetapi(h);
api.setMagnification(api.findFitMag())

for f=1:size(S,3)
    api.replaceImage(imadjust(imcomplement(S(:,:,f))),'PreserveView',true);
    
    hold on;
    for i=1:size(tracks,1)
        if tracks.StartFrame(i) <= f && tracks.StartFrame(i)+tracks.Length(i)-1 >= f
            pos = cell2mat(tracks.Positions(i));
            plot(pos(1:f-tracks.StartFrame(i)+1,1),pos(1:f-tracks.StartFrame(i)+1,2),'.-','Color',rgb(i,:));
        end
    end
    hold off;
    drawnow;
end






%% NN Track
maxLRMovment = 3;
maxUDMovment = 1.5;
tracks = nearestDNANeighborTracking( positions, maxLRMovment, maxUDMovment );

%% GGNN Track
tic;
maxLRMovment = 5;
maxUDMovment = 2;
maxBlink = 2;
tracks = GNNTracking( positions, maxLRMovment, maxUDMovment, maxBlink );
toc

%% NN Plot
imshow(imadjust(imcomplement(timeAvgStack(S))));
hold on;
for i=1:size([tracks.positions],2)
    pos = tracks(i).positions.centers;
    if size(pos,1) > 1 && abs(min(pos(:,2)) - max(pos(:,2))) > 0
        
        plot(pos(:,1),pos(:,2),'.-');
    end
end
hold off;

%% NN Track Movie
fig = figure(5);
ax = axes(fig);
im = imshow(imadjust(imcomplement(S(:,:,1))),'Parent',ax);

rgb=rand(size([tracks.positions],2),3);

h = imscrollpanel(fig, im);
api = iptgetapi(h);
api.setMagnification(api.findFitMag())

for f=1:size(S,3)
    im = imshow(imadjust(imcomplement(S(:,:,f))),'Parent',ax);
    
    hold on;
    
    if ~isempty(positions{f})
        plot(positions{f}(:,1),positions{f}(:,2),'or');
    end
    
    for i=1:size([tracks.positions],2)
        if tracks(i).positions.frames(1) <= f && tracks(i).positions.frames(end) >= f
            pos = tracks(i).positions.centers;
            plot(pos(tracks(i).positions.frames <= f,1), pos(tracks(i).positions.frames <= f,2),'.-','Color',rgb(i,:));
        end
    end
    
    hold off;
    
    pause(.5);
end


