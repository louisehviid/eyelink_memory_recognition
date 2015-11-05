function [response, responseTime] = waitForParticipantInputOrTimeout(s, input1, input2, timeout)
    %temp variables for reading input and 
    input = '';
    timeoutReached = 0;
    responseTime = GetSecs;
    startTime = GetSecs;
    
    % clear/read anything in the serial buffer
    % to avoid getting false starts... ie button presses
    % that happened before we started listening for input.
    if (get(s, 'BytesAvailable') > 0 )
        fscanf(s);
    end
    
    % While the participant has not responded and the timeout has not
    % been reached, we will
    while (~(strcmp(input,input1) || strcmp(input,input2) || timeoutReached))
        if (get(s, 'BytesAvailable') > 0 )
            responseTime = GetSecs;
            input = strtrim(fscanf(s));
        end

        if ((GetSecs - startTime) > timeout)
           input = '';
           timeoutReached = 1;
        end

        WaitSecs(0.0001); % don't kill the cpu
    end
    
    response = input;
end