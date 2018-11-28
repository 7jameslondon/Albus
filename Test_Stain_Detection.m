%% Setup/Import
% mpath = fileparts(which(mfilename));
% addpath([mpath '/Registration']);
% addpath([mpath '/Interface']);
% addpath([mpath '/Tracking']);
% addpath([mpath '/Particle_Detection']);
% addpath([mpath '/DNA_Detection']);
% addpath([mpath '/Drift_Correction']);
% addpath([mpath '/Miscellaneous']);
% 
% filePath = ['/Users/jameslondon/Documents/Fishel Lab/JL Nature Data/2016-',...
%             '01-12_Ecoli_10nM MutS Alexa 647_20nM MutL Cy3 R95F_1mM ATP_1',...
%             '00mM NaCl_DoubleBiotn17KbSMPL_300ms_0.6sec Timelapse/MutS+Mu',...
%             'tL 1A_Sytox_400ms_1/MutS+MutL 1A_Sytox_400ms_1_MMStack_Pos0.',...
%             'ome.tif'];
% 
% [stack, maxIntensity] = getStackFromFile(filePath);
% I = timeAvgStack(stack);
% I = I(:,1:240);

%%

lengths = (13);
widths  = (2);
rotations = (0);
dnaMatchingStrength = 50;

kernals = generateDNAKernals(lengths,widths,rotations);
kernal = kernals{1};

f = figure(1);
subplot(1,2,1);
imshow(I);
subplot(1,2,2);
imshow(kernal);

% f2 = figure(2);
% for i=1:length(kernals)
%     subplot(10,length(kernals)/10,i);
%     imshow(kernals{i});
% end

%% Prepare image
tic;
I = adapthisteq(IOrginial,'Distribution','rayleigh','ClipLimit',0.005);

fullCor = normxcorr2(kernal,I); % between -1 and 1
fullCor = (fullCor+1)/2; % between 0 and 1
cor = imcrop(fullCor,[size(kernal,2) size(kernal,1) size(I,2) size(I,1)]);

regMax = imregionalmax(cor);
imshowpair(imadjust(cor),I,'montage')

selectedCor = cor.*regMax >= dnaMatchingStrength/100;
[row,col] = find(selectedCor);
toc

f = figure(1);
subplot(1,1,1);
imshow(I);
for i=1:size(row,1)
    line([1 1]*col(i)+[0 1]*size(kernal,2),...
         [1 1]*row(i)+size(kernal,1)/2,'LineWidth',1);
end
