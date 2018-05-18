clear;
clc;
figure(1)

[fPath1 fPath2] = uigetfile('*.tif');
fPath = [fPath2 fPath1];
%% Create DNA
figure(2)

padSize = 2; % width
obj = strel('line',20,0); % length
obj = obj.Neighborhood;
obj = padarray(obj,padSize);
obj = padarray(obj',padSize)';
obj = imgaussfilt(double(obj),1);
obj = im2uint16(obj);

obj = imrotate(obj, 0);

%
imshow(obj);
%%
I = imread(fPath);
I = I(1:size(I,1),200:size(I,2));

I = adapthisteq(I,'Distribution','rayleigh','ClipLimit',0.005);

c = normxcorr2(obj,I);
c = normalize(c,'range'); % normalize between 0 and 1

c = imhmax(c,mean(c(:)));
regMax = imregionalmax(c);

CC = bwconncomp(regMax);
S = regionprops(CC,'Centroid');

figure(1)
imshow(I)
ax = gca;

corrs = zeros(size(S,1),1);
rects = zeros(size(S,1),4);

for i=1:size(S,1)
    center = S(i,:).Centroid;
    rects(i,:) = [center(1)-size(obj,2), center(2)-size(obj,1), size(obj,2), size(obj,1)];
    
    dnaImage = imcrop(I,rects(i,:));
    
    corrs(i) = max(max(xcorr2(dnaImage,obj)));
end
    
meanCorrs = mean(corrs);
for i=1:size(S,1)
    if corrs(i) > meanCorrs
        rectangle(ax,'Position',rects(i,:),'EdgeColor','r');
    else
        rectangle(ax,'Position',rects(i,:),'EdgeColor','g');
    end
end


%%

    binaryI = imbinarize(I);
    stats = regionprops(binaryI,'Eccentricity','MajorAxisLength','Centroid');
    componets = bwconncomp(binaryI);
    labledI = labelmatrix(componets);
    validIds = find([stats.Eccentricity] >= .25 & [stats.MajorAxisLength] >= 5 & [stats.MajorAxisLength] <= 50); 
    
    
    corrs = zeros(size(S,1),1);
    rects = zeros(size(S,1),4);
    for i=1:size(validIds,2)
        
        center = stats(validIds(i),:).Centroid;
        rects(validIds(i),:) = [center(1)-size(obj,2)/2, center(2)-size(obj,1)/2, size(obj,2), size(obj,1)];
    
        rectangle(ax,'Position',rects(i,:),'EdgeColor','c');
    end 
    
    
    
    