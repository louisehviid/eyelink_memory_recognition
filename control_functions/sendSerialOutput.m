function ret = sendSerialOutput(s, output)    
    % trigger timeout prompt light, researcher should ask something like
    % "Are you ready to proceed?"
    fprintf(s,output);
end