clc;

A = 512*rand(200,2)+256;

theta = 2;
tform = affine2d([cosd(theta) sind(theta) 0; -sind(theta) cosd(theta) 0; 0 0 1]);
[B_x,B_y] = transformPointsForward(tform,A(:,1),A(:,2));

B = [B_x,B_y];
B = B + 0.1*rand(200,2);

W = generateTPS(A,B,0);
C = evaluateTPS(B,W,A);

W = generateTPS(A,B,1);
D = evaluateTPS(B,W,A);

plot(A(:,1),A(:,2),'ro');
hold on;
plot(B(:,1),B(:,2),'bo');
plot(C(:,1),C(:,2),'y+');
plot(D(:,1),D(:,2),'gx');
hold off;

disp(['B: ', num2str(mean(sqrt(sum((A-B).^2,2)),1))])
disp(['C: ', num2str(mean(sqrt(sum((A-C).^2,2)),1))])
disp(['D: ', num2str(mean(sqrt(sum((A-D).^2,2)),1))])