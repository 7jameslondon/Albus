function parWaitbar(startOrDone, msg, total)
    
    if nargin == 0 
        %% Call from inside a parfor
        
        % check for the text file
        if ~exist('parWaitbar.txt', 'file')
            error('parWaitbar.txt not found');
        end

        % add a new line to the text file
        f = fopen('parWaitbar.txt', 'a');
        fprintf(f, '1\n');
        fclose(f);
        
    else
        %% set up waitbar or delete waitbar
        
        if strcmp(startOrDone, 'start')
            %% Create a text file with the total number of interations at the top
            f = fopen('parWaitbar.txt', 'w');
            if f<0
                error('Do you have write permissions for %s?', pwd);
            end
            fprintf(f, '%d\n', total); % save total at the top
            fclose(f);

            %% Setup a waitbar and timer
            msg = [msg ' (in parallel)'];
            hWaitbar = waitbar(0,msg);
            hWaitbar.UserData = msg;

            startClock = clock;
            hTimer = timer( 'ExecutionMode', 'fixedSpacing',...
                            'StartDelay', 1,...
                            'Period', 1,...
                            'UserData', true,...
                            'TimerFcn', @(hTimer, ~) updateParWaitbar(hTimer,hWaitbar,startClock) );
            start(hTimer);

        else 
            %% delete waitbar
            delete('parWaitbar.txt');
        end
    end
end


function updateParWaitbar(hTimer,hWaitbar,startClock)
    f = fopen('parWaitbar.txt', 'r');
    
    if f < 0 % file has been deleted and thus the progress is complete
        delete(hWaitbar);
        stop(hTimer);
        delete(hTimer);
    else
        txt = fscanf(f, '%d');
        p = (length(txt)-1)/txt(1);
        waitbar(p,hWaitbar);
        fclose(f);
                
        % Slow down the timer after a while then give a time estamate
        if hTimer.UserData % currently a fast timer
            if hTimer.Period == 1 && hTimer.TasksExecuted >= 60 % its been a minute
                stop(hTimer);
                hTimer.Period = 10; % slow down to checking every 10 seconds
                hTimer.UserData = false;
                start(hTimer);
            end
        else
            secondsPast = etime(clock, startClock);
            waitbar(p, hWaitbar, {hWaitbar.UserData,...
                ['About ', num2str(((1/p)-1)*secondsPast/60, '%.1f'), ' mins remaining']});
        end
    end    
end