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
S = stack(1:100,270:370,:);

f = figure(1);
imshow(imadjust(imcomplement(S(:,:,1))));
%%

minJ        = 14000;
logWidth    = 0.35;
boundRadius  = 4;
maxDist = 5;

positions = cell(size(S,3),1);
for f = 1:size(S,3)
    particles = MLDetector(S(:,:,f), minJ,logWidth,boundRadius,'MLE Center Only');
    positions{f} = [[particles.x]', [particles.y]'];
end

tracks = triTrackTracking( positions, maxDist );

%% PLOT the FOUND TRACKS
figure(4)
%imshow([imadjust(imcomplement(timeAvgStack(S))), imadjust(imcomplement(timeAvgStack(S)))]);
imshow(imadjust(imcomplement(timeAvgStack(S))));
hold on;
for i=1:size(tracks,1)
    pos = cell2mat(tracks.Positions(i));
    if tracks.Length(i) > 1 && abs(min(pos(:,2)) - max(pos(:,2))) > 4
        
        plot(pos(:,1),pos(:,2),'.-');
    end
end
hold off;

%%
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

