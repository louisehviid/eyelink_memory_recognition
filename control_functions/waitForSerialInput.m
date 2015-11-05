function ret = waitForSerialInput(s, button)
    %Read serial port for button press
    %Wait for researcher to press their button
    input = '';
    
    % clear/read anything in the serial buffer
    % to avoid getting false starts... ie button presses
    % that happened before we started listening for input.
    if (get(s, 'BytesAvailable') > 0 )
        fscanf(s);
    end
    
    while (~strcmp(input, button))
        if (get(s, 'BytesAvailable') > 0 )
            input = strtrim(fscanf(s));
        end
        
        WaitSecs(0.001); % don't kill the cpu
    end
end
