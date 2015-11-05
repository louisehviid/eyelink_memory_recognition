function dataFilePointer = getOutputFilePointer(outputFilename)
    % check for existing result file to prevent accidentally overwriting
    % files from a previous subject/session (except for subject numbers > 99):
    file = outputFilename;
    if fopen(file, 'rt')~=-1
        fclose('all');
        error('Result data file already exists! Choose a different subject number.');
    else
        disp(file)
        dataFilePointer = fopen(file,'wt'); % open ASCII file for writing
    end
end