%%

seperatedStacks = getappdata(handles.f,'data_mapping_originalSeperatedStacks');
I = imadjust(seperatedStacks{2}(:,:,1));

figure(2)

ax1 = subaxis(2,3,1);
axis tight;
imshow(I,'Parent',ax1);
title(ax1,'(a)');

J = imadjust(imgaussfilt(I,.6));
ax1 = subaxis(2,3,2);
imshow(J,'Parent',ax1);
title(ax1,'(b)');

% 1.8189e-04
K = imregionalmax(J);
ax1 = subaxis(2,3,3);
imshow(K,'Parent',ax1);
title(ax1,'(c)');

% 0.0070
BW = imregionalmax(J);
stats = regionprops('Table',BW,J,'MeanIntensity','Centroid');
selectedIdx = stats.MeanIntensity > .5*2^16;
selectedIdx = find(selectedIdx);
L = bwlabel(BW);
K = BW.*0;
for i=1:size(selectedIdx,1)
    K = K + (L==selectedIdx(i));
end
ax1 = subaxis(2,3,4);
imshow(K,'Parent',ax1);
title(ax1,'(d)');



ax1 = subaxis(2,3,5);
imshow(I,'Parent',ax1);
title(ax1,'(e)');
hold on;
for i=1:size(selectedIdx,1)
    center = stats(selectedIdx(i),:).Centroid;
    plot(center(1),center(2),'r+');
end
hold off;


% 22.033132/100
centers = findParticles(I,0.5*2^16,1.0*2^16,0.5,'Method','GaussianFit');
centers = centers{1}.Center;
ax1 = subaxis(2,3,6);
imshow(I,'Parent',ax1);
title(ax1,'(f)');
hold on;
for i=1:size(centers,1)
    plot(centers(i,1),centers(i,2),'r+');
end
hold off;



%%
dist1 = 0;
dist2 = 0;

for renner=1:1000
I = zeros(51,'uint16');
Intensities = uint16(rand(10,1) * 0.25*2^16 + 0.5*2^16);
Widths = randn(10,1)/4 + 1;
Widths(Widths<0) = 0;
Posx = rand(10,1)*51;
Posy = rand(10,1)*51;

for i=1:10    
    Zeros = zeros(51,'uint16');
    while max(Zeros(:)) < Intensities(i)
        R = mvnrnd([Posx(i), Posy(i)], [Widths(i),Widths(i)], 1000);
        [N,Xedges,Yedges] = histcounts2(R(:,1),R(:,2),0:51,0:51);
        Zeros = uint16(N) + Zeros;
    end
    I = I + Zeros;
end

Posx = Posx + .5;
Posy = Posy + .5;

I = imnoise(I,'gaussian',.01);
I = imnoise(I,'poisson');
I = imadjust(I);

figure(3)
imshow(I);

hold on;
for i=1:size(Posy,1)
    plot(Posy(i),Posx(i),'g+');
end
hold off;

J = imadjust(imgaussfilt(I,.5));
BW = imregionalmax(J);
stats = regionprops('Table',BW,J,'MeanIntensity','Centroid');
selectedIdx = stats.MeanIntensity > .8*2^16;
selectedIdx = find(selectedIdx);
L = bwlabel(BW);
K = BW.*0;
for i=1:size(selectedIdx,1)
    K = K + (L==selectedIdx(i));
end

hold on;
for i=1:size(selectedIdx,1)
    center = stats(selectedIdx(i),:).Centroid;
    plot(center(1),center(2),'r+');
end
hold off;

centers = stats(selectedIdx(:),:).Centroid;

dist1x = min(abs( repmat(centers(:,2),1,size(Posx,1)) - repmat(Posx,1,size(centers,1))' ));
dist1y = min(abs( repmat(centers(:,1),1,size(Posy,1)) - repmat(Posy,1,size(centers,1))' ));
dist1 = sum(sqrt(dist1x.^2 + dist1y.^2)) + dist1;

centers = findParticles(I,0.8*2^16,1.0*2^16,0.5,'Method','GaussianFit');
centers = centers{1}.Center;
hold on;
for i=1:size(centers,1)
    plot(centers(i,1),centers(i,2),'b+');
end
hold off;


dist2x = min(abs( repmat(centers(:,2),1,size(Posx,1)) - repmat(Posx,1,size(centers,1))' ));
dist2y = min(abs( repmat(centers(:,1),1,size(Posy,1)) - repmat(Posy,1,size(centers,1))' ));
dist2 = sum(sqrt(dist2x.^2 + dist2y.^2)) + dist2;
end

dist1 = dist1/10
dist2 = dist2/10
