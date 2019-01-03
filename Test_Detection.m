%% Setup/Import
mpath = ['/Users/jameslondon/Documents/Fishel Lab/Albus'];
addpath([mpath '/Registration']);
addpath([mpath '/Interface']);
addpath([mpath '/Tracking']);
addpath([mpath '/Particle_Detection']);
addpath([mpath '/DNA_Detection']);
addpath([mpath '/Drift_Correction']);
addpath([mpath '/Miscellaneous']);

filePath = ['/Users/jameslondon/Documents/Fishel Lab/JL Nature Data/2016-',...
            '01-12_Ecoli_10nM MutS Alexa 647_20nM MutL Cy3 R95F_1mM ATP_1',...
            '00mM NaCl_DoubleBiotn17KbSMPL_300ms_0.6sec Timelapse/MutS+Mut',...
            'L 1_300ms_1/MutS+MutL 1_300ms_1_MMStack_Pos0.',...
            'ome.tif'];

[stack, maxIntensity] = getStackFromFile(filePath);
I = stack(:,1:240,1);

%%
sizeP = 5;
minI = 2000;

particles = MLDetector(I,minI,sizeP,'MLE Full')
J = imgaussfilt(I, sizeP/5);

rgb = [particles.L]';
rgb = rgb - min(rgb);
rgb = rgb / max(rgb);
rgb = ind2rgb(uint8(round(rgb*256)),parula(256));
rgb = permute(double(rgb),[1 3 2]);

f = figure(1);
imshow(imadjust(imcomplement(I)));

hold on;
if ~isempty(particles)
    for i = 1:size(particles,2)
        viscircles([particles(i).ux particles(i).uy], particles(i).s,'Color',rgb(i,:));
        %viscircles([particles(i).ux particles(i).uy], 5);
    end
end

hold off;

%%
subplot(2,1,2);
histogram(J(:));

%%
clc;

[X,Y] = meshgrid((1:50),(1:60));
cf = @(x,y,ux,uy,s,A,B)  A * exp(((x-ux).^2 + (y-uy).^2) / (-2*s)) / (2*pi*s) + B ;

act_ux = 30;
act_uy = 20;
act_s  = 5;
act_A  = 20000;
act_B  = 10;

%data = cf(X, Y, act_ux, act_uy, act_s, act_A, act_B) + .002*2*rand(size(X)) - .002;
data = cf(X, Y, 30, 20, act_s, act_A, act_B) ...
     + cf(X, Y, 30, 25, act_s, act_A, act_B) ...
     + rand(size(X));
 
 data = round(data);
 
f = figure(1);
ax = axes('parent',f);
imagesc(data);

sizeP = 10;
minI = 200;
particles = MLDetector(data,minI,sizeP,false,false);

viscircles(ax, [[particles.ux]' [particles.uy]'], [particles.s]');
