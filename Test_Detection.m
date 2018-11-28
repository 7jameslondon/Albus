%% Setup/Import
mpath = fileparts(which(mfilename));
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

f = figure(1);

J = imgaussfilt(I, 1);
BW = imregionalmax(J);

imshowpair(imadjust(J),BW,'montage')

%%
clc;

[X,Y] = meshgrid((1:50),(1:50));
cf = @(x,y,ux,uy,s,A,B) A * ( (1-B)*(exp(((x-ux).^2 + (y-uy).^2) / (-2*s)) / (2*pi*s)) + B/size(x(:),1) );

act_ux = 30;
act_uy = 20;
act_s  = 10;
act_A  = 1;
act_B  = 0;

data = cf(X, Y, act_ux, act_uy, act_s, act_A, act_B);

f = figure(1);
surf(data)

numT    = size(data(:),1);
dataT   = sum(data(:))

est_ux  = mean(data(:).*X(:))/dataT*numT;
est_uy  = mean(data(:).*Y(:))/dataT*numT;
est_s   = sum( ((X(:) - est_ux).^2 + (Y(:) - est_uy).^2).*data(:) ) / (dataT*2);
est_A  = dataT;

est_B  = mean(data(:));


[est_ux est_uy est_s est_A est_B]

