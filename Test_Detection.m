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
I = stack(1:200,270:500,1);

f = figure(1);
imshow(imadjust(imcomplement(I)));
%%

minJ        = 14000;
logWidth    = 0.35;
boundRadius  = 4;

particles = MLDetector(I,minJ,logWidth,boundRadius,'MLE Center Only');
J = imfilter(I, fspecial('log',8,logWidth), 'symmetric');

f = figure(1);
imshow([imadjust(imcomplement(I)),imadjust(imcomplement(J))]);

% rgb = [particles.L]';
% rgb = rgb - min(rgb);
% rgb = rgb / max(rgb);
% rgb = ind2rgb(uint8(round(rgb*256)),parula(256));
% rgb = permute(double(rgb),[1 3 2]);

hold on;
if ~isempty(particles)
    for i = 1:size(particles,2)
        %viscircles([particles(i).x, particles(i).y], particles(i).s+1, ...
        %    'Color','g', 'EnhanceVisibility', false, 'LineWidth', .1);
        %text(particles(i).x, particles(i).y,num2str(i),'Color','g');
        viscircles([particles(i).x particles(i).y], .5, 'Color','r', 'EnhanceVisibility', false, 'LineWidth', 1);
    end
end
hold off;
