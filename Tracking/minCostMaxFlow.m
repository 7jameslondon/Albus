function idx = minCostMaxFlow(prevPositions,currPositions,nextPositions,maxMovment,plotGraph)

    % The variable 'p' is each position in the current frame.
    % And  'pp1' is p plus  1(pp1) so it is a position in the next frame.
    % Then 'pm1' is p minus 1(pm1) so it is a postion in the prevous frame.

    %% Create a directed graph
    maxSize = round(sqrt(size(prevPositions,1)*size(currPositions,1)*size(nextPositions,1)));
    triplets = zeros(maxSize,3); % pre-aloc
    costs = zeros(maxSize,1); % pre-aloc
    num_triplets = 0;
    
    for pm1=1:size(prevPositions,1) % positions in the previous frame
        for p=1:size(currPositions,1) % positions in the frame current
            for pp1=1:size(nextPositions,1) % positions in the next frame
                
                % are the distances between the points within the max
                % distance
                if norm(prevPositions(pm1,:)-currPositions(p,:)) <= maxMovment && ...
                        norm(currPositions(p,:)-nextPositions(pp1,:)) <= maxMovment 
                    
                    num_triplets = num_triplets + 1;
                    
                    % save each valid triplet
                    triplets(num_triplets,1:3) = [pm1, p, pp1];

                    % connect triplet to source with capacity given by cost
                    costs(num_triplets,1) = flowCost(prevPositions(pm1,:), currPositions(p,:), nextPositions(pp1,:));
                end
            end
        end
    end
    
    triplets = triplets(1:num_triplets,:);
    costs = costs(1:num_triplets,1);
    
    %% Create incidence matrix 'I' from 'triplets'
        
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
    
    idx = reshape(triplets(repmat(x(1:num_triplets)==3,1,3)),[],3);
    
    %% PLOT
    if exist('plotGraph','var') && plotGraph
        G = digraph(inc2adj(-I));
        H = plot(G,'Layout','layered','EdgeLabel',G.Edges.Weight);
        highlight(H,'Edges',find(x>0),'EdgeColor','r','linewidth',1);
        highlight(H,'Edges',find(x==3),'EdgeColor','g','linewidth',1);
    end
    
end

