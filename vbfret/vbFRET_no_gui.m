%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This is a command line version of vbFRET
% the data must be FRET transformed already and stored in a cell array
% called 'FRET'
%
% Posterior parameters are stored in an NxK array called 'bestOut'
%
% Idealized trajectories are stored in an NxK array called 'x_hat'
%
% Idealized hidden state trajectories are stored in an NxK array called 
% 'z_hat' 
%
% Please direct any questions to Jonathan Bronson (jeb2126@columbia.edu)
%
% March 2010
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load data 
load ./example_files/multi_trace_data_example

% make file name to save data to
fil_name = 'file_name'; % name of output file (must be string)
d_t = clock;
save_name=sprintf('%s_d%02d%02d%02d_t%02d%02d',fil_name,d_t(2),d_t(3),d_t(1)-2000,d_t(4),d_t(5));

%%%%%%%%%%%%%%%%%%%%%
% parameter settings
%%%%%%%%%%%%%%%%%%%%%

% analyze data in 1D
D = 1;
% set minimum number of states to try fitting
kmin = 3;
% set maximum number of states to try fitting
K = 5;
% set maximum number of restarts 
I = 10;

N = length(FRET);

% analyzeFRET program settings
PriorPar.upi = 1;
PriorPar.mu = .5*ones(D,1);
PriorPar.beta = 0.25;
PriorPar.W = 50*eye(D);
PriorPar.v = 5.0;
PriorPar.ua = 1.0;
PriorPar.uad = 0;
%PriorPar.Wa_init = true;


% set the vb_opts for VBEM
% stop after vb_opts iterations if program has not yet converged
vb_opts.maxIter = 100;
% question: should this be a function of the size of the data set??
vb_opts.threshold = 1e-5;
% display graphical analysis
vb_opts.displayFig = 0;
% display nrg after each iteration of forward-back
vb_opts.displayNrg = 0;
% display iteration number after each round of forward-back
vb_opts.displayIter = 0;
% display number of steped needed for convergance
vb_opts.DisplayItersToConverge = 0;


% bestMix = cell(N,K);
bestOut=cell(N,K);
outF=-inf*ones(N,K);
best_idx=zeros(N,K);

%%%%%%%%%%%%%%%%%%%%%%%%
%run the VBEM algorithm
%%%%%%%%%%%%%%%%%%%%%%%%

for n=1:N
    fret = FRET{n}(:)'; %make sure the data is a row vector
    for k=kmin:K
        ncentres = k;
        init_mu = (1:ncentres)'/(ncentres+1);
        i=1;
        maxLP = -Inf;
        while i<I+1
            if k==1 && i > 3
                break
            end
            if i > 1
                init_mu = rand(ncentres,1);
            end
            clear mix out;
            disp(sprintf('Working on inference for restart %d, k%d of trace %d...',i,k,n))
            % Initialize gaussians
            % Note: x and mix can be saved at this point andused for future
            % experiments or for troubleshooting. try-catch needed because
            % sometimes the K-means algorithm doesn't initialze and the program
            % crashes otherwise when this happens.
           try
                [mix] = get_mix(fret',init_mu);
                [out] = vbFRET_VBEM(fret, mix, PriorPar, vb_opts);
            catch
                disp('There was an error, repeating restart.');
                runError=lasterror;
                disp(runError.message)
                continue
           end
            
            % Only save the iterations with the best out.F
            if out.F(end) > maxLP
                maxLP = out.F(end);
%                 bestMix{n,k} = mix;
                bestOut{n,k} = out;
                outF(n,k)=out.F(end);
                best_idx(n,k) = i;
            end
            i=i+1;
        end
    end
   % save results
   save(save_name);           

end

%%%%%%%%%%%%%%%%%%%%%%%% VBHMM postprocessing %%%%%%%%%%%%%%%%%%%%%%%%%%%

% analyze accuracy and save analysis
disp('Analyzing results...')

save(save_name);          

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get idealized data fits
%%%%%%%%%%%%%%%%%%%%%%%%%%
z_hat=cell(N,K);
x_hat=cell(N,K);
for n=1:N
    for k=kmin:K
        [z_hat{n,k} x_hat{n,k}] = chmmViterbi(bestOut{n,k},FRET{n}(:)');
    end
end

disp('...done w/ analysis') 

save(save_name);           



