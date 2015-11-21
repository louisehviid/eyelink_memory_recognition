% dependency on first initializing sound
% put this in your script before calling playBeep()
% [pahandle, beep] = initBeep();

function playBeep(pahandle)
    PsychPortAudio('Start', pahandle);    
end
