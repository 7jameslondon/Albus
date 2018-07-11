kyms = getappdata(handles.f,'kyms');
seperatedStacks = getappdata(handles.f,'data_video_seperatedStacks');
kymImages = getappdata(handles.f,'data_kym_images');

if exist('fig')
    try
        close(fig);
    end
end
figPos = [900 500 800 1000];
fig = figure('Name','TEST','Position',figPos);
pnl = uipanel('Parent',fig);
ax = axes(pnl);

I = kymImages{1}(:,:,2);
J = medfilt2(I,[2 2]);

binaryJ = imbinarize(J,0.3);
stats = regionprops(binaryJ,I,'Area','PixelList');
componets = bwconncomp(binaryJ);
labledI = labelmatrix(componets);
validIds = find([stats.Area] > 5); 

imshow(I);
for i=1:length(validIds)
    % get all pixles of each valid serpated object
    cords = stats(validIds(i)).PixelList;
    x = [];
    y = [];
    for i=min(cords(:,1)):max(cords(:,1))
        x(end+1) = i;
        y(end+1) = mean(cords(cords(:,1)==i,2));
    end    

    line(x,y,'Color','red');
end 
