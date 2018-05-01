clc;
clear;
addpath('/Users/jameslondon/Documents/Fishel Lab/Albus/Albus 4/Tracking');

tic;
%% GENERATE POSITIONS
durration = 50;
numOrginalTracks = 30;
positions = cell(durration,1);
positions{1} = rand(numOrginalTracks,2)*100;
curveA = randn(numOrginalTracks,1);
curveB = randn(numOrginalTracks,1);
for f=2:durration
    positions{f} = positions{f-1} + [curveA*cos(f/durration*pi/2)  curveB*sin(f/durration*pi/2)] ;
end

%% PLOT REAL TRACKS
figure(1)
cla;
hold on;
for i=1:size(positions{1},1)
    track = zeros(durration,2);
    for f=1:size(positions,1)
        track(f,:) = positions{f}(i,:);
    end
    plot(track(:,1),track(:,2),'.-');
end
hold off;



%% GRAPH THEORY
maxDist = 5;

tracks = triTrackTracking( positions, maxDist );

%% PLOT the FOUND TRACKS
figure(4)
cla;
hold on;
for i=1:size(tracks,1)
    pos = cell2mat(tracks.Positions(i));
    plot(pos(:,1),pos(:,2),'.-');
end
hold off;

toc
