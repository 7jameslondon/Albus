clc;

%mpath = fileparts(which(mfilename));
%addpath([mpath '/Registration']);

A = 512*rand(50,2);

theta = 2;
delta_x = 5;
delta_y = 5;

tform = affine2d([  cosd(theta),  sind(theta), 0; ...
                    -sind(theta), cosd(theta), 0; ...
                    delta_x,      delta_y,     1  ]);
B = transformPointsForward(tform,A);

B = B(randperm(size(B,1)),:);
B = B + randn(50,2)/5;

%%
figure(1)

[B_affine, flag] = findAffine(A, B, 50, 1e4, 20);
[A_idx,B_idx] = matchPoints(A, B_affine, 2);

A_matching = A(A_idx,:);
B_matching = B(B_idx,:);

TPS_weights = calculateTPS(A_matching, B_matching, 200);
B_tps = evaluateTPS(B, TPS_weights, A_matching);

plot(A(:,1),A(:,2),'ro');
hold on;
plot(B(:,1),B(:,2),'bo');
plot(B_affine(:,1),B_affine(:,2),'gx');
plot(B_tps(:,1),B_tps(:,2),'r+');
hold off;

%%
figure(2)
[X,Y] = meshgrid(1:10:512,1:10:512);
Z = zeros(size(X));

XY_tps = evaluateTPS([X(:),Y(:)], TPS_weights, A_matching);
X_tps = reshape(XY_tps(:,1),size(X,1),size(X,2));
Y_tps = reshape(XY_tps(:,2),size(Y,1),size(Y,2));
Z_tps = sqrt( (X_tps-X).^2 + (Y_tps-Y).^2 );

surf(X_tps,Y_tps,Z_tps)


