function idx = minCostMaxFlow(prevPositions,currPositions,nextPositions,maxMovment,plotGraph)

    % The variable 'p' is each position in the current frame.
    % And  'pp1' is p plus  1(pp1) so it is a position in the next frame.
    % Then 'pm1' is p minus 1(pm1) so it is a postion in the prevous frame.

    % create a graph
    G = digraph;
    G = addnode(G,'S'); % add a source
    G = addnode(G,'T'); % add a sink/target
    
    for pm1=1:size(prevPositions,1) % positions in the previous frame
        for p=1:size(currPositions,1) % positions in the frame current
            for pp1=1:size(nextPositions,1) % positions in the next frame
                
                % are the distances between the points within the max
                % distance
                if norm(prevPositions(pm1,:)-currPositions(p,:)) > maxMovment ||...
                        norm(currPositions(p,:)-nextPositions(pp1,:)) > maxMovment 
                    continue;
                end
                
                % position node names
                n1 = [num2str(1), '_', num2str(pm1)]; 
                n2 = [num2str(2),   '_', num2str(p)];
                n3 = [num2str(3), '_', num2str(pp1)];
               
                % add the triplet
                tiplet = [n1, ', ',n2, ', ',n3];
                
                % connect triplet to source with capacity given by cost
                c = flowCost(prevPositions(pm1,:), currPositions(p,:), nextPositions(pp1,:));
                G = addedge(G,'S',tiplet,c);
                
                % connect position nodes to triplet with capacity 1
                G = addedge(G,tiplet,n1,1);
                G = addedge(G,tiplet,n2,1);
                G = addedge(G,tiplet,n3,1);
                
                % connect position nodes to sink with capacity 1
                if edgecount(G,n1,'T') == 0
                    G = addedge(G,n1,'T',1);
                end
                if edgecount(G,n2,'T') == 0
                    G = addedge(G,n2,'T',1);
                end
                if edgecount(G,n3,'T') == 0
                    G = addedge(G,n3,'T',1);
                end
            end
        end
    end
    
    % reorder so that 'T' is last'
    order = G.Nodes.Name;
    order(2) = [];
    order{end+1} = 'T';
    G = reordernodes(G,order);

    % add edge from sink to source with infinite capacity
    G = addedge(G,'T','S', inf);
    
    capacites = G.Edges.Weight;
    costs = capacites;
    costs(costs==1) = 0;
    costs(costs==inf) = -1e10;
    capacites(capacites~=1 & capacites~=inf) = 3;
    capacites(capacites==inf) = 1e10;

    numNodes = numnodes(G);
    numIntNodes = numNodes-2; % number of intermediat nodes
    numEdges = numedges(G);
    f   = costs;
    A   = sparse(diag(ones(numEdges,1)));
    ub  = capacites;
    beq = zeros(numIntNodes,1);
    lb  = zeros(numEdges,1);
    I   = incidence(G);
    Aeq = I(2:end-1,:);
    options = optimoptions('linprog','Algorithm','interior-point','Display','off');

    [x,fval,exitflag,output] = linprog(f, [], [], Aeq, beq, lb, ub, options);
    x = round(x);
        
    idxNames = G.Edges.EndNodes(find(x==3),2);
    idxNames = split(idxNames,["_",", "]);
    idx = str2double(idxNames(:,2:2:6));
    
    %% PLOT
    if exist('plotGraph','var') && plotGraph
        H = plot(G,'Layout','layered','EdgeLabel',G.Edges.Weight);
        highlight(H,'Edges',find(x>0),'EdgeColor','r','linewidth',1);
        highlight(H,'Edges',find(x==3),'EdgeColor','g','linewidth',1);
    end
    
end

