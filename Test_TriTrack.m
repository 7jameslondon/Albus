clc;
clear;
addpath('/Users/jameslondon/Documents/Fishel Lab/Albus/Albus 4/Tracking');

%% GENERATE POSITIONS
durration = 1200;
positions = cell(durration,1);
positions{1} = [repmat(1:5,1,5)',imresize(1:5,[1 25],'nearest')'];
for f=2:durration
    positions{f} = positions{f-1} + [[randn(1,23)/50 -.02 0]', [randn(1,23)/50 -.002 -.01]'] ;
end

%% PLOT REAL TRACKS
figure(1)
cla;
axis([0 6 0 6]);
hold on;
for i=1:size(positions{1},1)
    track = zeros(durration,2);
    for f=1:size(positions,1)
        track(f,:) = positions{f}(i,:);
    end
    plot(track(:,1),track(:,2),'o-');
end
hold off;



%% GRAPH THEORY
maxDist = .7;

tracks = triTrackTracking( positions, maxDist );

%% PLOT the FOUND TRACKS
figure(4)
cla;
axis([0 6 0 6]);
hold on;
for i=1:size(tracks,1)
    pos = cell2mat(tracks.Positions(i));
    plot(pos(:,1),pos(:,2),'o-');
end
hold off;

