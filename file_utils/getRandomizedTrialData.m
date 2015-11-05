function  [ trialFilenames, trialTypes, trialClasses ] = getRandomizedTrialData(filename)

    %load the trials
    disp(filename);
    [  trialFilenames, trialTypes, trialClasses ] = textread(filename,'%s %d %d');
    
    % Randomize order of list
    numTrials=length(trialFilenames);          % get number of trials
    randomOrder=randperm(numTrials);           % randperm() is a matlab function
    trialFilenames=trialFilenames(randomOrder);% need to randomize each list!
    trialTypes=trialTypes(randomOrder);        %
    trialClasses=trialClasses(randomOrder);    
end