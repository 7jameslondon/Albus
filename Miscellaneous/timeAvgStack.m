function I = timeAvgStack(S)
    % Take a time average of a stack and returns the image cast to the 
    % same type as the orginal stack
    
    I = cast(mean(S,3),class(S));
end

