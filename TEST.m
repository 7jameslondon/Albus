

G = digraph;
G = addedge(G,'S','1',1);
G = addedge(G,'S','2',2);
G = addedge(G,'1','T',3);
G = addedge(G,'2','T',1);
G = addedge(G,'1','2',2);
G = addedge(G,'T','S', inf);


figure(2)
H1 = plot(G,'Layout','force');
layout(H1,'layered','Sources','S');
title('Linear Programing')

figure(3)
H2 = plot(G,'Layout','force');
layout(H2,'layered','Sources','S');
title('Matlab Max Flow')

capacites = G.Edges.Weight;


numNodes = numnodes(G);
numIntNodes = numNodes-2; % number of intermediat nodes
numEdges = numedges(G);
f   = [-1; -1; 0; 0; 0; 0;];%-double(capacites==1 & costs==0);%costs;%[zeros(numEdges-1,1); -1];
A   = sparse(diag(ones(numEdges,1)));
ub   = capacites;
beq = zeros(numIntNodes,1);
lb  = zeros(numEdges,1);
I   = incidence(G);
Aeq = I(2:end-1,:);
options = optimoptions('linprog','Algorithm','interior-point','MaxIterations',1e10,'OptimalityTolerance',1e-12,'ConstraintTolerance',1e-8);

[x,fval,exitflag,output] = linprog(f, [], [], Aeq, beq, lb, ub, options);
exitflag
maxFlow = -x'*f
highlight(H1,'Edges',find(round(x)>0),'EdgeColor','r','LineWidth',1);

%%
[mf, GF] = maxflow(G,'S','T');
highlight(H2,GF,'EdgeColor','r','LineWidth',1);



%%
% 
% f=[-1; -1; 0; 0; 0];
% A = diag([1 1 1 1 1]);
% b=[1; 2; 2; 3; 1];
% Aeq=[1 0 -1 -1 0; 0 1 1 0 -1];
% beq=[0;0];
% lb=zeros(5,1);
% x=linprog(f,A,b,Aeq,beq,lb);