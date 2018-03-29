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

frameNumber = 1;
particleMaxRadius = 3;
userErrorFactor = 1;

effectiveMaxRadius = userErrorFactor*particleMaxRadius;
I = seperatedStacks{2}(:,:,frameNumber);
pos = round(kyms.Position(2,:));
I = I(min(pos([2,4]))-effectiveMaxRadius : min(pos([2,4]))+effectiveMaxRadius , min(pos([1,3]))-effectiveMaxRadius : max(pos([1,3]))+effectiveMaxRadius);

imshow(I,'Parent',ax);

%% One Image
I = kymImages{2}(70:end,:,1);
J = imgaussfilt(I,1);

binaryJ = imbinarize(J,0.5);
stats = regionprops(binaryJ,I,'Area','PixelList');
componets = bwconncomp(binaryJ);
labledI = labelmatrix(componets);
validIds = find([stats.Area] > 5); 

imshow((labledI==-1));
for i=1:length(validIds)
    % get all pixles of each valid serpated object
    cords = stats(validIds(i)).PixelList;
    x = [];
    y = [];
    for i=min(cords(:,1)):max(cords(:,1))
        x(end+1) = i;
        y(end+1) = mean(cords(find(cords(:,1)==i),2));
    end    

    line(x,y)
end 
