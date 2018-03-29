function best_x_hat = vbFRETWrapper(fret, kmin, K)
    % kmin - set minimum number of states to try fitting
    % K - set maximum number of states to try fitting

    % analyze data in 1D
    D = 1;
    % set maximum number of restarts 
    I = 10;
    
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

    bestOut=cell(1,K);
    outF=-inf*ones(1,K);
    best_idx=zeros(1,K);
    best_LPs=zeros(1,K);

    %%%%%%%%%%%%%%%%%%%%%%%%
    %run the VBEM algorithm
    %%%%%%%%%%%%%%%%%%%%%%%%
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
                bestOut{1,k} = out;
                outF(1,k)=out.F(end);
                best_idx(1,k) = i;
            end
            i=i+1;
        end
    end
        
    % grab the best fit
    [~, best_k] = max(outF);

    % Get idealized data fits
    [best_z_hat, best_x_hat] = chmmViterbi(bestOut{1,best_k},fret);
end