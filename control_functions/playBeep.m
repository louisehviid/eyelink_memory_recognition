function playBeep()
    f = 329.6;
    d = 0.6;
    sr = 44100;
    beep = MakeBeep(f,d,sr);
    pahandle = PsychPortAudio('open', [],[],[],sr,1);
    PsychPortAudio('FillBuffer', pahandle, beep);
    PsychPortAudio('start', pahandle);
    %PsychPortAudio('stop', pahandle,d);
end

