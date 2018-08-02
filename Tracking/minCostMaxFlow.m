function idx = minCostMaxFlow(prevPositions,currPositions,nextPositions,maxMovment,plotGraph)

    % The variable 'p' is each position in the current frame.
    % And  'pp1' is p plus  1(pp1) so it is a position in the next frame.
    % Then 'pm1' is p minus 1(pm1) so it is a postion in the prevous frame.

    %% Find the triplet positions and their costs
    % Pre-aloc - this will overallocate space but we will remove it at the
    % end of the for loops
    maxSize = round(sqrt(size(prevPositions,1)*size(currPositions,1)*size(nextPositions,1)));
    triplets = zeros(maxSize,3); % pre-aloc
    costs = zeros(maxSize,1); % pre-aloc
    num_triplets = 0;
    
    % Find the indexs of all neighbors in the previous and next frame from 
    % the current frame with in a radius maxMovment
    prevNeighbors = rangesearch(prevPositions,currPositions,maxMovment);
    nextNeighbors = rangesearch(nextPositions,currPositions,maxMovment);
    
    for c=1:size(currPositions,1)
        for p=1:size(prevNeighbors{c},2)
            for n=1:size(nextNeighbors{c},2)
                num_triplets = num_triplets + 1;
                
                % save each valid triplet
                triplets(num_triplets,1:3) = [prevNeighbors{c}(p), c, nextNeighbors{c}(n)];
                
                % connect triplet to source with capacity given by cost
                costs(num_triplets) = flowCost( ...
                    prevPositions(prevNeighbors{c}(p),:), ...
                    currPositions(c,:), ...
                    nextPositions(nextNeighbors{c}(n),:));
            end
        end
    end

    % remove extra rows
    triplets = triplets(1:num_triplets,:);
    costs = costs(1:num_triplets,1);
    
    %% Remove triplets with no conflicts  
    % This is to ease the burden on the linear programing algorthim.
    % Since triplets with all their elements having no other triplets claim
    % them will always have flow.
    
    % find all the elements that occure once in each column
    ncePrev = find(histcounts(triplets(:,1), 1:(size(prevPositions,1)+1)) == 1);
    nceCurr = find(histcounts(triplets(:,2), 1:(size(currPositions,1)+1)) == 1);
    nceNext = find(histcounts(triplets(:,3), 1:(size(nextPositions,1)+1)) == 1);
    
    % create the binary of the location of those columns
    ncPrev = zeros(size(triplets,1),1,'logical');
    ncCurr = zeros(size(triplets,1),1,'logical');
    ncNext = zeros(size(triplets,1),1,'logical');
    
    for i=1:size(ncePrev,2)
        ncPrev = ncPrev | triplets(:,1)==ncePrev(i);
    end
    
    for i=1:size(nceCurr,2)
        ncCurr = ncCurr | triplets(:,2)==nceCurr(i);
    end
    
    for i=1:size(nceNext,2)
        ncNext = ncNext | triplets(:,3)==nceNext(i);
    end
    
    % and thoughs columns
    noConflictsIdx = ncPrev & ncCurr & ncNext;
    
    % remove thoes columns
    noConflicts = reshape(triplets([noConflictsIdx noConflictsIdx noConflictsIdx]),[],3);
    triplets = reshape(triplets(~[noConflictsIdx noConflictsIdx noConflictsIdx]),[],3);
    costs = costs(~noConflictsIdx);
    
    num_triplets = size(costs,1);
    
    %% Create incidence matrix of graph 'I' from 'triplets'
        
    % find the total number of unique particles over all three frames
    num_particles = 0; % pre-aloc
    num_unique_triplets = zeros(4,1); % pre-aloc
    unique_triplets = zeros(size(triplets)); % pre-aloc
    for i=1:3
        u = unique(triplets(:,i));
        num_unique_triplets(i+1) = size(u,1);
        num_particles = num_particles + size(u,1);
        unique_triplets(1:size(u,1),i) = u;
    end
    
    % pre-allocate the incidence matrix
    num_edges = 1 + num_particles + num_triplets*4;
    num_nodes = 2 + num_particles + num_triplets; % 2 is for the sink and source
    I = zeros(num_edges,num_nodes);
    
    % Fill the incidence matrix
    %   source to triplets
    I(1:num_triplets,1) = -1;
    I(1:num_triplets,1+(1:num_triplets)) = diag(ones(num_triplets,1));
    %   triplets to particles
    for i=1:num_triplets
        for t=1:3
            idx = find(unique_triplets(:,t) == triplets(i,t))...
                + 1 + num_triplets + sum(num_unique_triplets(1:t));
            I(num_triplets+(i-1)*3+t,i+1) = -1;
            I(num_triplets+(i-1)*3+t,idx) = 1;
        end
    end
    %   particles to sink
    idx = (num_triplets+1):(num_triplets+num_particles);
    I(idx+num_triplets*3,idx+1) = diag(-ones(num_particles,1));
    I(idx+num_triplets*3,end) = 1;
    %   sink to source
    I(end,end) = -1;
    I(end,1) = 1;

    %% Linear Program
    costs = [costs; zeros(num_edges-num_triplets-1,1); -1e10];
    
    capacites = ones(num_edges,1);
    capacites(1:num_triplets) = 3;
    capacites(end) = 1e10;
    
    options = optimoptions('linprog','Algorithm','interior-point','Display','off');

    %           f              Aeq beq                 lower bound         uper bound
    x = linprog(costs, [], [], I', zeros(num_nodes,1), zeros(num_edges,1), capacites, options);
    x = round(x);
    
    % resolve cases of identical costs for the same nodes
    while size(x,1) < num_triplets || isempty(x)
        [unique_costs, ~, unique_indexs] = unique(costs(1:num_triplets)); 
        occurances = accumarray(unique_indexs,1);
        [~, max_occurances] = max(occurances);
        frequent_cost = unique_costs(max_occurances);        
        frequent_cost_index = find(costs==frequent_cost);
        costs(frequent_cost_index(1)) = costs(frequent_cost_index(1)) * 0.99;
        
        x = linprog(costs, [], [], I', zeros(num_nodes,1), zeros(num_edges,1), capacites, options);
        x = round(x);
    end
    
    fullFlowIdx = reshape(triplets(repmat(x(1:num_triplets)==3,1,3)),[],3);
    
    %% Combine the no conflict indexes and the linear programing full flow indexs
    idx = [noConflicts; fullFlowIdx];

    %% PLOT
    if exist('plotGraph','var') && plotGraph
        figure(2)
        G = digraph(ItoA(I));
        H = plot(G,'Layout','layered','EdgeLabel', costs);
        highlight(H,'Edges',find(x>0),'EdgeColor','r','linewidth',1);
        highlight(H,'Edges',find(x==3),'EdgeColor','g','linewidth',1);
    end
    
end

function A = ItoA(I)
    I = -I.';
    N = size(I,1);
    [N1, ~] = find(I == 1);
    [N2, ~] = find(I == -1);
    A = sparse(N1, N2, 1, N, N);
end



