function [experimentRecord timeStamps] = unmaskedPrimeMain(experimentParameters, splashParameters, trialParameters)
% function [experimentRecord timeStamps] = unmaskedPrimeMain(experimentParameters, splashParameters, trialParameters)
% Handles all the setting up for an unmasked prime button press study. 
% 
% ARGUMENTS - all structs containing various bits of information
% experimentParameters: various experiment parameters (eg subID,
%                       nBlocks)
% splashParameters:     parameters for the splashScreen
% trialParameters:      one blocks's worth of trial parameters. Used
%                       as per stimuli
%
% RETURN VALUES - optional, if you want it sent to the command window
% experimentRecord: cell array detailing the order in which the trials
%                   were presented + responses, scores and RTs
% timeStamps:       [primeStimOnset maskStimOnset blankStimOnset
%                     targetStimOnset blank2StimOnset]
%
% Contains two subfunctions:
%   cleanup
%   centreText
% Andrew D Wilson 2008

%Error handling
if nargin ~= 3
    error('Usage: [experimentRecord timeStamps] = unmaskedPrimeMain(experimentParameters, trialParameters) (unmaskedPrimeMain.m)');
end

%****************SET UP****************
subID = experimentParameters.subID;
nTrialsPerBlock = length(trialParameters.trialName);
nTrials = nTrialsPerBlock * experimentParameters.nBlocks;

KbName('UnifyKeyNames'); %Set to consistent standard (OSX format)
escKeyID = KbName('ESCAPE');
blockKeyID = KbName('b');
spaceKeyID = KbName('space');

black = BlackIndex(0);
white = WhiteIndex(0);

defaultLineWidths = 4;
dotSize = 5; %Fixation dot size

%Defines how long the person has after the target presentation to respond
responseTime = experimentParameters.ResponseDuration; %1300ms

%Set up a matrix to record what happened in the experiment. This should get built on the fly to record the order in which things happened
recordTitle = {'Trial Number' '# in Block' 'Block #' 'Trial Type Number' 'Trial Name' 'Trial Type' 'Correct Response',...
    'Response', 'Score', 'Reaction Time'};
responseColumn = ismember(recordTitle, 'Response');
scoreColumn = ismember(recordTitle, 'Score');
RTColumn = ismember(recordTitle, 'Reaction Time');

experimentRecord = cell(nTrials, length(recordTitle));
timeStamps=[];
%****************END SET UP****************

try
    %PTB things to get ready
    [wPtr rect] = Screen('OpenWindow', 0);
    ListenChar(2); %Supress keyboard output from going to the command window
    HideCursor;
    Priority(1);
    
    %Makes the stimuli for one full block, ie one of everything required. The matrices returned in the struct 'stimuli' are coordinates 
    %and sourceRect information for use with Screen('DrawLines'), and are indexed according to trialParameters.trialInBlock
    %They are made here, rather than primingMain.m, because I need 'rect'
    maskSize = [150 90];  % A placeholder 
    stimuli = makeStimuli (maskSize, trialParameters);
    
    %Coordinates for the fixation dot
    dotRect = [(rect(3)/2)-(dotSize/2) (rect(4)/2)-(dotSize/2) (rect(3)/2)+(dotSize/2) (rect(4)/2)+(dotSize/2)];
             
    %Initial blank screen + instructions
    splashScreen(wPtr, splashParameters, trialParameters, stimuli);
    WaitSecs(.2); 
    [secs keyCode] = KbWait; %Pauses until a key press is detected
    while ~keyCode(spaceKeyID)
        [secs keyCode] = KbWait;
        %Tests to see if the escape key has been pressed to end the session (no save data as this is pre-experiment only)
        if keyCode(escKeyID)
            cleanup;
            return; %Ends this run of maskedPrimeMain.m
        end
    end
    
    %RUN EXPERIMENT
    for block = 1:experimentParameters.nBlocks
        %Produces a random order to sample stimuli from for this block. This updates every block and allows randomisation to be within block
        if isequal(experimentParameters.Randomisation{1}, 'yes')
            trialOrder = [rand(1, nTrialsPerBlock); 1:nTrialsPerBlock]';
            trialOrder = sortrows(trialOrder); %nTrialsPerBlockx2 matrix - randomised trialInBlock numbers in column 2
            trialOrder = trialOrder(:,2); %Makes a 1 column vector
        elseif isequal(experimentParameters.Randomisation{1}, 'no')
            trialOrder = [1:nTrialsPerBlock]';
        end            
        
        for trialInBlock = 1:nTrialsPerBlock
            trial = (block-1)*nTrialsPerBlock + trialInBlock; %Indexes where in the experiment you are
            
            [wPtrPrime]      = Screen('OpenOffScreenWindow', wPtr);            
            primeLocation    = stimuli.primeCoordinates{trialOrder(trialInBlock)};
            primeSourceRect  = stimuli.primeSourceRect(trialOrder(trialInBlock),:);
            primeDestRect    = stimuli.primeDestRect(trialOrder(trialInBlock),:);
            primeOrientation = trialParameters.primeOrientation(trialOrder(trialInBlock));
            primeDuration    = trialParameters.primeDuration(trialOrder(trialInBlock))/1000;
                       
            blankDuration   = trialParameters.blankDuration(trialOrder(trialInBlock))/1000;
            
            [wPtrTarget]      = Screen('OpenOffScreenWindow', wPtr); 
            targetLocation    = stimuli.targetCoordinates{trialOrder(trialInBlock)};
            targetSourceRect  = stimuli.targetSourceRect(trialOrder(trialInBlock),:);
            targetDestRect    = stimuli.targetDestRect(trialOrder(trialInBlock),:);
            targetOrientation = trialParameters.targetOrientation(trialOrder(trialInBlock));
            targetDuration    = trialParameters.targetDuration(trialOrder(trialInBlock))/1000;
            %**************BEGIN DISPLAY**************
            Screen('FillRect', wPtr, white); Screen('Flip', wPtr);
            WaitSecs(.5);
            Screen('FillOval', wPtr, black, dotRect); Screen('Flip', wPtr);  %Draw fixation dot
            WaitSecs(0.5);
            Screen('FillRect', wPtr, white); Screen('Flip', wPtr);
            WaitSecs(0.5);

            %Prime - 33ms (2 frame @ 60Hz)
            if ~isempty(primeLocation)
                Screen('DrawLines', wPtrPrime, primeLocation, defaultLineWidths, black);
                Screen('DrawTexture', wPtr, wPtrPrime, primeSourceRect, primeDestRect, primeOrientation);
            else  %Allows you to display unprimed trials with everything else intact
                Screen('FillRect', wPtr, white);
            end
            [primeFlipStart, primeStimOnset] = Screen('Flip', wPtr);

            %Blank screen - 50ms, 3 frames @ 60Hz
            Screen('FillRect', wPtr, white); 
            [blankFlipStart, blankStimOnset] = Screen('Flip', wPtr, primeFlipStart+(primeDuration-.01));

            %Target - 100ms (6 frames @ 60Hz)
            if ~isempty(targetLocation)
                Screen('DrawLines', wPtrTarget, targetLocation, defaultLineWidths, black);
                Screen('DrawTexture', wPtr, wPtrTarget, targetSourceRect, targetDestRect, targetOrientation);
            else  %Allows you to display no-target trials with everything else intact
                Screen('FillRect', wPtr, white);
            end
            [targetFlipStart, targetStimOnset] = Screen('Flip', wPtr, blankFlipStart+(blankDuration-.01));

            %Final response screen
            Screen('FillRect', wPtr, white);
            [blank2FlipStart, blank2StimOnset] = Screen('Flip', wPtr, targetFlipStart + (targetDuration -.01));
            %**************END DISPLAY**************
            
            %**************BEGIN RESPONSE HANDLING**************
            %Records response, score and RT, and copes with missed trials
            stop  = GetSecs + responseTime;
            [keyIsDown] = KbCheck;
            while ~keyIsDown
                [keyIsDown, secs, keyCode] = KbCheck;

                if keyIsDown
                    %Checks for escape key - this allows you to quit out any time, saves out data thus far
                    if keyCode(escKeyID)
                        save QUITDATA experimentRecord timeStamps experimentParameters trialParameters;
                        cleanup;
                        return
                    end

                    %Response
                    experimentRecord{trial, responseColumn} = KbName(keyCode);
                    %Reaction Time
                    experimentRecord(trial, RTColumn) = {secs - targetStimOnset};
                    break; %Stops waiting once a response is recorded - this will need to change for bimanual responses
                end
                
                if isequal(experimentParameters.TrialLength, 'fixed') && GetSecs > stop
                    break;
                end
            end            
            if ~keyIsDown %ie the trial was missed
                experimentRecord(trial, responseColumn) = {'miss'};
                experimentRecord(trial, scoreColumn)    = {'miss'};
                experimentRecord(trial, RTColumn)       = {'miss'}; %Indexes the miss
            end
            %**************END RESPONSE HANDLING**************
            timeStamps = [timeStamps; primeStimOnset 0 blankStimOnset targetStimOnset blank2StimOnset];
            
            %Fill in experimentRecord for this trial
            experimentRecord{trial, 1} = trial;
            experimentRecord{trial, 2} = trialInBlock;
            experimentRecord{trial, 3} = block;
            experimentRecord{trial, 4} = trialParameters.uniqueTrialNumbers(trialOrder(trialInBlock));
            experimentRecord{trial, 5} = trialParameters.trialName{trialOrder(trialInBlock)};
            experimentRecord{trial, 6} = trialParameters.trialType{trialOrder(trialInBlock)};
            experimentRecord{trial, 7} = trialParameters.correctResponse{trialOrder(trialInBlock)};

            %Score; the '+0' converts to a num
            if ~isequal(experimentRecord(trial, responseColumn), {'miss'})
                experimentRecord{trial, scoreColumn} = (isequal(experimentRecord{trial, responseColumn}, experimentRecord{trial, 7}) + 0);
            end
            
            %Feedback
            if trialParameters.feedback(trialOrder(trialInBlock)) == 1
                WaitSecs(.1);
                if experimentRecord{trial, scoreColumn} == 1 %Correct
                    feedbackText = 'Correct!';
                else
                    feedbackText = 'Incorrect!';
                end
                [fbX fbY] = centreText (wPtr, feedbackText, 32);
                Screen('DrawText', wPtr, feedbackText, fbX, fbY, black); Screen('Flip', wPtr);
                WaitSecs(.5);
            end
            
            %Clear the stimuli offscreen windows for use again
            Screen('Close', [wPtrPrime wPtrTarget]);
            
            %Maintains a constant trial length. This should always be the last thing done in a trial, or commented out for variable trial length
            WaitSecs(stop - GetSecs); 
        end
        %Break between blocks
        while ~isequal(block, experimentParameters.nBlocks) %Skip last block          
            splashScreen(wPtr, splashParameters, trialParameters, stimuli);
            WaitSecs(.5); [secs keyCode] = KbWait;

            %Tests to see if the escape key has been pressed to end the session
            if keyCode(escKeyID)
                save QUITDATA experimentRecord timeStamps experimentParameters trialParameters;
                cleanup;
                return; %Ends this run of maskedPrimeMain.m
            elseif keyCode(blockKeyID) %Pressing 'b' briefly shows which block you are in
                blockIDText = ['You just completed Block ', int2str(block)];
                Screen('DrawText', wPtr, blockIDText, 0, 0, black); Screen('Flip', wPtr);
                WaitSecs(1);
            elseif keyCode(spaceKeyID)
                Screen('FillRect', wPtr, white); Screen('Flip', wPtr);
                WaitSecs(.5);
                break
            end
        end
    end
    endText = 'Thank you for your participation!';
    [endTextX endTextY] = centreText(wPtr, endText, 32);
    Screen('DrawText', wPtr, endText, endTextX, endTextY, black); Screen('Flip', wPtr);
    WaitSecs(.5); %Turns itself off after a second
    
    %Save data out to Excel and Matlab format files
    experimentRecord = [recordTitle; experimentRecord];
    if ~isequal(subID, 'practice')
        medians = sortData(experimentRecord);
        
        fileName = [subID, '_unmaskedPrimingData.xls'];
        if ~exist(fileName, 'file')
            xlswrite(fileName, experimentRecord, 1);
            xlswrite(fileName, medians, 2);
            eval(['save ', subID, '_unmaskedPrimeData experimentRecord timeStamps experimentParameters trialParameters medians']);
        else
            %Note this check is only done once - rename kghrhtgkrehk.xls immediately or it will be overwritten
            xlswrite('kghrhtgkrehk', experimentRecord);
            save kghrhtgkrehk_unmaskedPrimeData experimentRecord timeStamps experimentParameters trialParameters;
            disp(['Warning! ', fileName, ' already existed (unmaskedPrimeMain.m).']);
            disp('Your data has been saved to files prefixed kghrhtgkrehk. Rename them with the correct subID');
        end        
    end    
    cleanup;
catch 
    unmaskPrimeError = lasterror;
    message          = unmaskPrimeError(1).message
    identifier       = unmaskPrimeError(1).identifier
    stack            = unmaskPrimeError(1).stack
    file             = stack.file
    line             = stack.line
    
    disp(['INFORMATION: participant completed ', int2str(trialInBlock), ' trials from Block ',...
        int2str(block), '.']);
    
    cleanup;  
    eval(['save ', subID, '_unmaskedPrimeData experimentRecord timeStamps']);
end

function cleanup
%Performs everything needed to shut this down properly

Priority(0);    ListenChar(1);  Screen('CloseAll');     ShowCursor;
return

function [x y] = centreText(wPtr, text, preferredFontSize)
%function [x y] = centreText(wPtr, text, preferredFontSize)
%
%For use with the Psychtoolbox. 
%Takes a window pointer & a string and returns the x,y coordinates that will centre the text if fed to Screen('DrawText')
%
%ARGUMENTS:
%wPtr = the window pointer returned by a call to Screen('OpenWindow')
%text = a string to be sent to the screen
%preferredFontSize = the maximum sized font you would like to have. If the text is too big, centreText will cycle through 
%   text sizes until it works and set it to the biggest that fits
%
%RETURN VALUES:
%[x y] = a vector with the (x,y) coordinates to centre that text.
%
%NB Requires that you have used Screen('OpenWindow')
%
%Andrew D. Wilson (v1.0.3; 11 April 2008)

x=-1; y=-1; %Allows loop to run once

while x<0
    Screen('TextSize', wPtr, preferredFontSize);

    [normBoundsRect, offsetBoundsRect]= Screen('TextBounds', wPtr, text);
    rect = Screen('Rect', wPtr);

    windowCentre = [rect(3)/2 rect(4)/2];
    textCentre = [normBoundsRect(3)/2 normBoundsRect(4)/2];

    x = windowCentre(1) - textCentre(1);
    y = windowCentre(2) - textCentre(2);
    
    if x < 0 || y < 0 %ie if the text ends up being drawn offscreen
        preferredFontSize = preferredFontSize-1;
    end
end

return;