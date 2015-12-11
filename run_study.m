% Cleanup before we start just in case serial port or sychtoolbox have
% crashed during development
addpath(genpath('./'));
delete(instrfindall);
sca;

% note on stimulus preparation
% psychtoolbox and matlab do not play well with indexed images
% rgb pngs give the most consistent results
% all .gif files were processed using the following 
% imagemagick command:
% `convert input.gif -define png:color-type=2 output.png`

%CONSTANTS... timeouts in seconds
INSTRUCTION_TIMEOUT      = 2;
FIXATION_TIMEOUT         = 2;
ILLUSION_TIMEOUT         = 5;
ILLUSION_GREY_TIMEOUT    = 5;
PICTURE_TIMEOUT          = 3; 
PARTICIPANT_TIMEOUT      = 10;
PARTICIPANT_LEFT_BUTTON  = 'Button1';
PARTICIPANT_RIGHT_BUTTON = 'Button2';
RESEARCHER_BUTTON        = 'Button3';
SIGNAL_TIMEOUT           = 't';
SERIAL_DEVICE            = '/dev/tty.usbserial-AL01CBT6';
SERIAL_BAUDRATE          = 115200;

%Colors
BLACK = [1,1,1];

% Clear Matlab/Octave window:
clc;

%Display prompt to enter subjectID
subId = str2num(promptForSubjectId());

% check for Opengl compatibility, abort otherwise:
AssertOpenGL;

try
screens=Screen('Screens');
screenNumber=max(screens);
Screen('Preference', 'SkipSyncTests', 1);

%small test screen
[w, rect] = Screen('OpenWindow', 0, [],[0 0 640 480]);

%full screen
%[w, rect] = Screen('OpenWindow', screenNumber, []);

%turn on psychtoolbox sound
pahandle = initBeep();

% Hide the mouse cursor:
%HideCursor;

% Returns as default the mean gray value of screen:
gray=GrayIndex(screenNumber);
Screen('TextSize', w, 14);

% Do dummy calls to GetSecs, WaitSecs, KbCheck to make sure
% they are loaded and ready when we need them - without delays
% in the wrong moment:
KbCheck;
WaitSecs(0.1);
GetSecs;

% Set priority for script execution to realtime priority:
priorityLevel=MaxPriority(w);
Priority(priorityLevel);

%randomize which hand is which
% 1 = old, or non-animal
% 2 = new, or animal
leftHand = round(rand(1)); % flip a coin, 0 or 1.
rightHand = 1 - leftHand; % right hand gets the other side.
leftHand = leftHand + 1; %increment by one for 1 indexes
rightHand = rightHand + 1; %increment by one for 1 indexes

types = { 'non-animal', 'animal'};
classes = { 'old', 'new' };
handMeaning = {'yes', 'no'};

% Setup file paths relative to './' which is whatever directory Matlab
% environment is in... vs 'pwd' which would be relative to the ocularmotor2
% folder.
practiceFolder   = ['./phases/practice/'];
studyFolder      = ['./phases/study/'];
testAFolder       = ['./phases/testA/'];
testBFolder       = ['./phases/testB/'];
illusionsFolder   = ['./phases/testIllusions/'];
resultsFolder    = ['./results/'];
edfFolder        = [resultsFolder '/edf/'];
resultFilePrefix = 'OcularMotorExperiment';
% define where to store our participant's results
outputFilename   = [resultsFolder resultFilePrefix sprintf('_%i.%s', subId, 'dat') ];
% each phase has a trials file that defines
% which image to use, and what that image means (class, type)
trialListFilename= 'trials.txt';

% Define the order of the phases, and assign what the hands mean.
% TestA and TestB order needs to be randomized. We flip a coin, and swap
% the order.
testAFirst = round(rand(1)); % flip a coin, 0 or 1.

if testAFirst == 1 
   phaseFolders     = { practiceFolder, studyFolder, testAFolder, testBFolder, illusionsFolder}; 
else 
   phaseFolders     = { practiceFolder, studyFolder, testBFolder, testAFolder, illusionsFolder};
end

phaseLeftHand = {handMeaning{leftHand}, handMeaning{leftHand}, handMeaning{leftHand}, handMeaning{leftHand}};
phaseRightHand = {handMeaning{rightHand}, handMeaning{rightHand}, handMeaning{rightHand}, handMeaning{rightHand}};
phaseInstructions= { 
    sprintf('Please indicate if you see an animal or not\nPress "yes" if you see an animal or "no" for everything else\n Left Hand = %s , Right Hand = %s', ...
        phaseLeftHand{1}, phaseRightHand{1}), ...
    sprintf('Please try to remember the pictures as best you can and still press "yes" if you see an animal or "no" for everything else\n Left Hand = %s , Right Hand = %s', ...
        phaseLeftHand{2}, phaseRightHand{2}), ...
    sprintf('Please indicate if you have seen a picture before\nPress "yes" if you have seen it before or "no" if you have not\n Left Hand = %s , Right Hand = %s', ...
        phaseLeftHand{3}, phaseRightHand{3}) ...
    sprintf('Please indicate if you have seen a picture before\nPress "yes" if you have seen it before or "no" if you have not\n Left Hand = %s , Right Hand = %s', ...
        phaseLeftHand{4}, phaseRightHand{4}) ...
    'Please watch the follow series of pictures\nThere is no response needed.'
};


%open the output result file for this subject
outputFilePointer = getOutputFilePointer(outputFilename);
%write labels
fprintf(outputFilePointer, '%s %s %s %s %s %s %s %s %s %s %s\n', ...
    'subId', ...
    'phaseNum', ...
    'trialNum', ...
    'phaseFolder', ...
    'trialFilename', ...
    'trialType', ...
    'trialClass', ...
    'leftHand',...
    'rightHand',...
    'response', ...
    'responseTime' ...
);

%Initialize and open the serial port
s = serial(SERIAL_DEVICE,'baudrate',SERIAL_BAUDRATE);
set(s, 'Terminator', 'CR/LF'); 
set(s, 'ReadAsyncMode', 'continuous');
fopen(s);

%---------- EYELINK ------------
% Provide Eyelink with details about the graphics environment
% and perform some initializations. The information is returned
% in a structure that also contains useful defaults
% and control codes (e.g. tracker state bit and Eyelink key values).
el=EyelinkInitDefaults(w);
% Disable key output to Matlab window:
ListenChar(2);

% ----------------
% EYELINK DUMMY MODE
% you can init(ialize) in dummy mode when eyelink is not available
%EyelinkInit(1,1)
%-----------------

%-------------------
% EYELINK FOR REAL MODE

if ~EyelinkInit(0, 1)
    fprintf('Eyelink Init aborted.\n');
    error('eyelink initialization failed.')
end

%-------------------

[v, vs]=Eyelink('GetTrackerVersion');
fprintf('Running experiment on a ''%s'' tracker.\n', vs );

% make sure that we get gaze data from the Eyelink
Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');

% STEP 4
% Calibrate the eye tracker
disp('about to do tracker setup')
EyelinkDoTrackerSetup(el);

% do a final check of calibration using driftcorrection
disp('do drift correction')
EyelinkDoDriftCorrection(el);

% This makes white background of images blend
% good explanation here: http://www.machwerx.com/2009/02/11/glblendfunc/
Screen('BlendFunction', w, GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);

%START PHASES
for phaseNum=1:length(phaseFolders)
    
    %if the folder is a "test" folder, we do recalibartion flow
    if (strfind(phaseFolders{phaseNum}, 'test') > 1) == 1
        disp('about to do tracker setup')
        EyelinkDoTrackerSetup(el);
        
        disp('do drift correction')
        EyelinkDoDriftCorrection(el);
    end
    
    isIllusions = strfind(phaseFolders{phaseNum}, 'Illusions' > 1);
    
    %load the trials (stims) for the phase
    thisPhaseFilename = [phaseFolders{phaseNum} trialListFilename];
    [trialFilenames, trialTypes, trialClasses] = getRandomizedTrialData(thisPhaseFilename);
    
    %Display Instructions to participant
    disp('Instructions');
    disp(phaseInstructions{phaseNum});
    Screen('FillRect', w, gray);
    DrawFormattedText(w, phaseInstructions{phaseNum}, 'center', 'center', BLACK);
    
    % Update the display to show the instruction text:
    Screen('Flip', w);
    WaitSecs(INSTRUCTION_TIMEOUT);
    
    %Prompt Researcher
    sendSerialOutput(s, SIGNAL_TIMEOUT);
    
    %Wait for Researcher to press button
    disp('waiting for researcher...');
    waitForSerialInput(s, RESEARCHER_BUTTON);
    
    Screen('FillRect', w, gray)
    Screen('Flip', w)
    
    % START TRIALS
    % For development we loop over 2 trails,
    % for full study, replace "2" with "length(trialFilenames)"
    for trialNum=1:length(trialFilenames)
        
        %Hold The Grey Screen before showing fixation
        WaitSecs(2.0);
        
        % -------------------
        % START EDF recording
        % -------------------
        
        % open file to record data to
        disp('opening demo file')
        edfFile='lh_temp.edf';
        Eyelink('Openfile', edfFile);
        % start recording eye position
        disp('start recording')
        Eyelink('StartRecording');
        
        % record a few samples before we actually start displaying
        WaitSecs(0.1);
        
        %Display the Fixation point
        disp('Fixation Point');
        [X,Y] = RectCenter(rect);
        FixCross = [X-1,Y-40,X+1,Y+40;X-40,Y-1,X+40,Y+1];
        Screen('FillRect', w, gray)
        Screen('FillRect', w, BLACK, FixCross');
        
        %wake up the participant before displaying fixation
        if (isIllusions == 0)
            playBeep(pahandle);
        end
        
        %%%%
        Screen('Flip', w);
        % mark zero-plot time in data file
        Eyelink('Message', 'FIXATION_POINT');
        %%%%
        
        WaitSecs(FIXATION_TIMEOUT);
        
        %Display the picture
        disp('Show Picture for 3 seconds');
        
        %read the image file
        imdata =imread(char([phaseFolders{phaseNum} trialFilenames{trialNum}]));
        
        % make texture image out of image matrix 'imdata'
        tex=Screen('MakeTexture', w, imdata);

        % Draw texture image to backbuffer. It will be automatically
        % centered in the middle of the display if you don't specify a
        % different destination:
        Screen('FillRect', w, gray);
        Screen('DrawTexture', w, tex);
        
        % Show stimulus on screen at next possible display refresh cycle,
        % and record stimulus onset time in 'startTime':
        [VBLTimestamp, startTime]=Screen('Flip', w);
        Eyelink('Message', 'STIM_ONSET');
        %disp(startTime);
        
        if (isIllusions == 0)
            %record participant input, either: Button1, Button2, ''
            disp('showing image, waiting for participant, or 3 seconds');
            [response, responseTime] = waitForParticipantInputOrTimeout(s, PARTICIPANT_LEFT_BUTTON, PARTICIPANT_RIGHT_BUTTON, PICTURE_TIMEOUT);
            disp(responseTime);
        else
            %display illusion for fixed time
            disp('showing illusion for fixed time');
            WaitSecs(ILLUSION_TIMEOUT);
        end
            
        %Display the grey screen
        disp('Show Grey Screen');
        Screen('FillRect', w, gray); % fill the screen with gray
        Screen('Flip', w); % present to the screen
        
        if (isIllusions == 0)
            % if they did not repond while image was on screen
            % record participant input, either: Button1, Button2, ''
            if (strcmp(response, ''))
                disp('waiting for participant again. 10 seconds.');
                [response, responseTime] = waitForParticipantInputOrTimeout(s, PARTICIPANT_LEFT_BUTTON, PARTICIPANT_RIGHT_BUTTON, PARTICIPANT_TIMEOUT);
            end

            if (strcmp(response, PARTICIPANT_LEFT_BUTTON))
                codedResponse = phaseLeftHand{phaseNum};
            elseif (strcmp(response, PARTICIPANT_RIGHT_BUTTON))
                codedResponse = phaseRightHand{phaseNum};
            else
                codedResponse = 'none';
                %if the response timed out, prompt the researcher
                sendSerialOutput(s, SIGNAL_TIMEOUT);
            end
        else
            %display the the grey screen for fixed time
            disp('displaying the grey screen for a fixed time between illusions');
            WaitSecs(ILLUSION_GREY_TIMEOUT);
        end
        
        %write participant response to file
        fprintf(outputFilePointer, '%i %i %i %s %s %s %s %s %s %s %d\n', ...
            subId, ...
            phaseNum, ...
            trialNum, ...
            char(phaseFolders(phaseNum)), ...
            char(trialFilenames(trialNum)), ...
            char(types(trialTypes(trialNum))), ...
            char(classes(trialClasses(trialNum))), ...
            char(phaseLeftHand(phaseNum)), ...
            char(phaseRightHand(phaseNum)), ...
            codedResponse, ...
            (responseTime - startTime) ...
        );
        
        % -------------------
        % STOP EDF recording
        % -------------------
        Eyelink('StopRecording');
        Eyelink('CloseFile');

        fprintf('Receiving data file ''%s''\n', edfFile );
        status=Eyelink('ReceiveFile');
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2==exist(edfFile, 'file')
            moveFileTo = [edfFolder resultFilePrefix sprintf('_%i_%i_%i.%s', subId, phaseNum, trialNum, 'edf') ];
            [status, message] = movefile(edfFile, moveFileTo);
            if 1==status
                error(message);
            else
                fprintf('Data file ''%s'' can be found in ''%s''\n', moveFileTo, pwd );
            end
        end
    end
end


% CLEANUP
Eyelink('Shutdown');
ListenChar(0);
Screen('CloseAll');
ShowCursor;
fclose('all');

fclose(s);
delete(s);
Priority(0);

catch err
    Eyelink('Shutdown');
    ListenChar(0);
    Screen('CloseAll');
    ShowCursor;
    fclose('all');
    Priority(0);
    
    % Output the error message that describes the error:
    throw(err);
    %psychrethrow(err);
end
%this is the end of the study