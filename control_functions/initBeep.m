function pahandle = initBeep()
    InitializePsychSound;
    f = 330;
    d = 0.6;
    sr = 44100;
    beep = MakeBeep(f,d,sr);
    pahandle = PsychPortAudio('open', [],[],[],sr,1);
    PsychPortAudio('FillBuffer', pahandle, beep);
end