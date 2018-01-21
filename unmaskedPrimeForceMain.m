function [experimentRecord timeStamps] = unmaskedPrimeForceMain(experimentParameters, splashParameters, trialParameters)
% function [experimentRecord timeStamps] = unmaskedPrimeForceMain(experimentParameters, splashParameters, trialParameters)
% Handles all the setting up for an unmasked prime force production study. 
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
    error('Usage: [experimentRecord timeStamps] = unmaskedPrimeForceMain(experimentParameters, trialParameters) (unmaskedPrimeForceMain.m)');
end

%****************SET UP****************
subID = experimentParameters.subID; %Keep this to keep everything that uses subID short and tidy
nTrialsPerBlock = length(trialParameters.trialName);
nTrials = nTrialsPerBlock * experimentParameters.nBlocks;

KbName('UnifyKeyNames'); %Set to consistent standard (OSX format)
escKeyID = KbName('ESCAPE');
blockKeyID = KbName('b');
spaceKeyID = KbName('space');

black = BlackIndex(0);
white = WhiteIndex(0);

defaultLineWidths = 6;

%Defines how long the person has after the target presentation to respond
responseTime = experimentParameters.ResponseDuration; %eg 3s

%Set up a matrix to record what happened in the experiment. This should get built on the fly to record the order in which things happened
recordTitle = {'Trial Number' '# in Block' 'Block #' 'Trial Type Number' 'Trial Name' 'Trial Type', 'Correct Response'};
experimentRecord = cell(nTrials, length(recordTitle));

timeStamps=[];

dataTitle = {'Time' 'Force Data'};
timeColumn = ismember(dataTitle, 'Time');
dataColumn = ismember(dataTitle, 'Force Data');
forceData = cell(nTrials, length(dataTitle));
%****************END SET UP****************

try
    %PTB things to get ready
    [wPtr rect] = Screen('OpenWindow', 0);
    ListenChar(2); %Supress keyboard output from going to the command window
    HideCursor;
    Priority(1);

    %Makes the stimuli for one full block, ie one of everything required. The matrices returned in the struct 'stimuli' are coordinates 
    %and sourceRect information for use with Screen('DrawLines'), and are indexed according to trialParameters.trialInBlock
    maskSize = [150 90];  % A placeholder
    stimuli = makeStimuli (maskSize, trialParameters);
    
    %Open serial port (set to COM4 here, change as necessary/parameterise in text file?)
    %These parameters suitable for SY034 amplifier
    [handle, errmsg] = IOPort('OpenSerialPort', 'COM4', 'BaudRate=57600 Terminator=CR');
    %Error handling
    if ~isempty(errmsg)
        disp(errmsg);
        IOPort('CloseAll');
        error('unmaskedPrimeForceMain.m quit with above error when trying to open the serial port (unmaskedPrimeForceMain.m)');
    end
    %Set to filter 1 (100Hz); probably not required but no harm done
    IOPort('Write', handle, 'F1');
    WaitSecs(.05);
    IOPort('Read', handle);  %Reads out the return value 'CR' to clear the buffer
    
    %Tares (zeros) reading then reads off the 'CR' response to clean out the queue.
    IOPort('Write', handle, 'T');
    WaitSecs(.05);
    IOPort('Read', handle); %Reads out the return value 'CR' to clear the buffer
          
    %Initial blank screen + instructions
    splashScreen(wPtr, splashParameters, trialParameters, stimuli);
    WaitSecs(.2); 
    [secs keyCode] = KbWait; %Pauses until a key press is detected
    while ~keyCode(spaceKeyID)
        [secs keyCode] = KbWait;
        %Tests to see if the escape key has been pressed to end the session (no save data as this is pre-experiment only)
        if keyCode(escKeyID)
            cleanup;
            return; %Ends this run of unmaskedPrimeForceMain.m
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
            %Initial blank screen + instructions
            instructions = 'Relax your finger, then press the space bar to begin the trial';
            [instructionsX instructionsY] = centreText(wPtr, instructions, 32);
            Screen('DrawText', wPtr, instructions, instructionsX, instructionsY, black); Screen('Flip', wPtr);
            WaitSecs(.2); 
            [secs keyCode] = KbWait; %Pauses until a key press is detected
            while ~keyCode(spaceKeyID)
                [secs keyCode] = KbWait;
                %Tests to see if the escape key has been pressed to end the session (no save data as this is pre-experiment only)
                if keyCode(escKeyID)
                    cleanup;
                    return; %Ends this run of unmaskedPrimeForceMain.m
                end
            end            
            
            %Fixation dot plus pauses on either side
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
            [blank2FlipStart, blank2StimOnset] = Screen('Flip', wPtr, targetFlipStart + (targetDuration-.01));
            %**************END DISPLAY**************
            
            %**************BEGIN RESPONSE HANDLING**************
            %Records force time series
            trialTimeStamps=[]; 
            trialData = [];
            
            start = GetSecs;
            stop =  start + responseTime;
            while GetSecs < stop                   
                    %Response
                    IOPort('Write', handle, 'M'); %Sends the M command, which queues up data for reading
                    [data, whenRead, errmsgRead] = IOPort('Read', handle, 1,8); %Reads 8 bytes of data
                    
                    trialTimeStamps = [trialTimeStamps; whenRead-start];
                    trialData       = [trialData; str2num(char(data))];  %converts the result of IOPort('Read') into the string 
                                                                         %of the number, the the number
%                 end
            end
            
            forceData{trial, timeColumn} = trialTimeStamps;
            forceData{trial, dataColumn} = trialData;
            %**************END RESPONSE HANDLING**************
            timeStamps = [timeStamps; primeStimOnset 0 blankStimOnset targetStimOnset blank2StimOnset];
            
            %Fill in experimentRecord for this trial. Column indices relate to recordTitle
            experimentRecord{trial, 1} = trial;
            experimentRecord{trial, 2} = trialInBlock;
            experimentRecord{trial, 3} = block;
            experimentRecord{trial, 4} = trialParameters.uniqueTrialNumbers(trialOrder(trialInBlock));
            experimentRecord{trial, 5} = trialParameters.trialName{trialOrder(trialInBlock)};
            experimentRecord{trial, 6} = trialParameters.trialType{trialOrder(trialInBlock)};
            experimentRecord{trial, 7} = trialParameters.correctResponse{trialOrder(trialInBlock)};
                       
            %Clear the stimuli offscreen windows for use again
            Screen('Close', [wPtrPrime wPtrTarget]); 
        end
        %Break between blocks
        while ~isequal(block, experimentParameters.nBlocks) %Skip last block          
            splashScreen(wPtr, splashParameters, trialParameters, stimuli);
            WaitSecs(.5); [secs keyCode] = KbWait;

            %Tests to see if the escape key has been pressed to end the session
            if keyCode(escKeyID)
                save QUITDATA experimentRecord timeStamps experimentParameters trialParameters;
                cleanup;
                return; %Ends this run of unmaskedPrimeForceMain.m
            elseif keyCode(blockKeyID) %Pressing 'b' briefly shows which block you are in
                blockIDText = ['You just completed Block ', int2str(block)];
                Screen('DrawText', wPtr, blockIDText, 0, 0, black); Screen('Flip', wPtr);
                WaitSecs(1);
            elseif keyCode(spaceKeyID)
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
        fileName = [subID, '_unmaskedPrimingForceData.xls'];
        if ~exist(fileName, 'file')
            xlswrite(fileName, experimentRecord, 1);
            eval(['save ', subID, '_unmaskedPrimeForceData experimentRecord timeStamps experimentParameters trialParameters forceData']);
        else
            %Note this check is only done once - rename kghrhtgkrehk.xls immediately or it will be overwritten
            xlswrite('kghrhtgkrehk', experimentRecord);
            save kghrhtgkrehk__unmaskedPrimeForceData experimentRecord timeStamps experimentParameters trialParameters forceData;
            disp(['Warning! ', fileName, ' already existed (unmaskedPrimeForceMain.m).']);
            disp('Your data has been saved to files prefixed kghrhtgkrehk. Rename them with the correct subID');
        end        
    end    
    cleanup;
catch 
    maskPrimeError = lasterror;
    message        = maskPrimeError(1).message
    identifier     = maskPrimeError(1).identifier
    stack          = maskPrimeError(1).stack
    file           = stack.file
    line           = stack.line
    
    disp(['INFORMATION: participant completed ', int2str(trialInBlock), ' trials from Block ',...
        int2str(block), '.']);
    
    cleanup;  
    eval(['save ', subID, '_unmaskedPrimeForceData experimentRecord timeStamps forceData']);
end

function cleanup
%Performs everything needed to shut this down properly
IOPort('CloseAll'); %Close serial port
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