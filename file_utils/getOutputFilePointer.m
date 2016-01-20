function dataFilePointer = getOutputFilePointer(outputFilename)
    % check for existing result file to prevent accidentally overwriting
    % files from a previous subject/session (except for subject numbers > 99):
    file = outputFilename;
    if fopen(file, 'rt')~=-1
        fclose('all');
        error('Result data file already exists! Choose a different subject number.');
    else
        disp(file)
        [dataFilePointer, message] = fopen(file,'wt'); % open ASCII file for writing
        if dataFilePointer == -1 
            error(message)
        end
    end
end