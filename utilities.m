function utilities(subFunction)
% function utilities(subFunction)
% 
% Contains a set of minor functions that are of use in setting up and
% configuring the Masked Priming Toolbox. 
% 
% ARGUMENT:
% subfunction: a string specifying which utility function you wish to
% call. Currently implemented:
%   'keyName':    returns the name of the key you press via KbName;
%                 use this to finmd the right value for the parameter
%                 CorrectResponse
%   'screenSize': returns the size, in pixels, of the primary monitor
% 
% Andrew D Wilson 2009

switch subFunction
    case 'keyName'
        KbName('UnifyKeyNames'); %Set to consistent standard (OSX format)
        ListenChar(2); %Supress keyboard output from going to the command window
        
        disp('Wait 1s, then press the key you wish to identify:');
        kbNameResult = KbName;
        if iscell(kbNameResult)  %Catches the times when, for eg, hitting shift returns {'Shift', 'LeftShift'}
            kbNameResult = kbNameResult{2};
        end
        
        disp(['That key is called ', kbNameResult, ': enter this into your parameter file.']);
        ListenChar(1); %Reenables keyboard output
        
    case 'screenSize'
        rect=Screen('Rect', 0);
        disp(['Your screen size (in x,y coordinates) is (', int2str(rect(3:4)), ').']);        
end