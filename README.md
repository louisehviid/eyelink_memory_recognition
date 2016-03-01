### Readme

#### Procedure for verififying eyelink operation
- Open the eyelink "demo.m" and make sure it's in your matlab path.
- Run it.
- If it fails, run again (not sure why, but eyelink fails to initialize on first attempt after starting matlab.)
- Remeber "CTRL-C" will release control of the keyboard back to user.
- Make sure demo script is working, and can calibrate.
- If demo does not run and calibrate, restart eye tracker machine, start over.
- Open "run_study.m", and add it and all sub files/directories to matlab path.
- Run it.

#### Loading EDF files in matlab
`edfmex('./results/edf/OcularMotorExperiment_9_1_1.edf')`

Markdown cheatsheet
https://guides.github.com/features/mastering-markdown/