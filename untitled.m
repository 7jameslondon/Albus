s = ones(10,35,'uint16');
for i=1:10
    [N,edges] = histcounts(Book1(:,i),-200:20:500);
    s(i,:) = imadjust(uint16(N/sum(N)*2^16));
end
figure(1)
imshow((imresize(imcomplement(s([1:2:10,2:2:10],:)),50,'nearest')))