function subId = promptForSubjectId()
    fail1='Program aborted. Participant number not entered'; % error message which is printed to command window
    prompt = {'Enter participant number:'};
    dlg_title = 'New Participant';
    num_lines = 1;
    def = {'0'};
    answer = inputdlg(prompt,dlg_title,num_lines,def); %presents box to enter data into
    switch isempty(answer)
    case 1 %deals with both cancel and X presses
        error(fail1)
    case 0
        subId=(answer{1});        
    end
end