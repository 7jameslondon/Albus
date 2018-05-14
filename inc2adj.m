% Function for converting an incidence matrix of a simple graph 
% (no multi-edges and self-loops) to an adjacency matrix.
% mAdj = inc2adj(mInc) - conversion from incidence matrix mInc to
% adjacency matrix mAdj
%
% INPUT:   mInc - incidence matrix; rows = edges, columns = vertices
% OUTPUT:  mAdj - adjacency matrix of a graph; if
%                  -- directed    - elements from {-1,0,1}
%                  -- undirected  - elements from {0,1}
%
% example: Graph:   __(v1)<--
%                  /         \_e2/e4_
%               e1|                  |  
%                  \->(v2)-e3->(v3)<-/
%                
%                 v1  v2 v3  <- vertices 
%                  |  |  |
%          mInc = [1 -1  0   <- e1   |
%                  1  0 -1   <- e2   | edges
%                  0  1 -1   <- e3   |
%                 -1  0  1]; <- e4   |
%
%          mAdj = [0 1 1
%                  0 0 1
%                  1 0 0];
%
% 26 Mar 2011   - created:  Ondrej Sluciak <ondrej.sluciak@nt.tuwien.ac.at>
% 31 Mar 2011   - faster check of the input matrix
% 13 Dec 2012   - major code optimization (Thanks to Andreas Gunnel for inspiration)
% 25 Feb 2016   - checks for correct input added (Thanks to Kaif Agbaje)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mAdj = inc2adj(mInc)

if ~issparse(mInc)
    mInc = sparse(mInc);  
end

if ~all(ismember(mInc(:), [-1, 0, 1]))
    error('inc2adj:wrongMatrixInput', 'Matrix must contain only {-1,0,1}');    
end

if ~all(any(mInc, 2))
    error('inc2adj:wrongMatrixInput', 'Invalid incidence matrix - each edge must be connected to at least one node.');
end

mInc = mInc.';

if any(mInc(:) == -1)   % directed graph

    iN_nodes = size(mInc,1);       % columns must be vertices!!!
    
    [vNodes1, dummy] = find(mInc == 1);    % since MATLAB 2009b 'dummy' can be replaced by '~'
    [vNodes2, dummy] = find(mInc == -1);   % since MATLAB 2009b 'dummy' can be replaced by '~'
    
    mAdj = sparse(vNodes1, vNodes2, 1, iN_nodes, iN_nodes);
            
else    % undirected graph
    
    L    = mInc*mInc.';        % using Laplacian
    mAdj = L - diag(diag(L));
    
end

if any(mAdj(:) > 1)
    warning('inc2adj:wrongMatrixInput', 'Multi-edge detected!');
end

end
