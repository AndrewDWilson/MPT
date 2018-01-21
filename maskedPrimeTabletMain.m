function [experimentRecord timeStamps] = maskedPrimeTabletMain (experimentParameters, maskParameters, splashParameters, trialParameters)
% function [experimentRecord timeStamps] = maskedPrimeTabletMain (experimentParameters, maskParameters, splashParameters, trialParameters)
%
% Handles all the setting up for a masked prime study with the tablet.
% 
% ARGUMENTS - all structs containing various bits of information
% experimentParameters: various experiment parameters (eg subID, nBlocks)
% maskParameters:       mask information for all trials
% splashParameters:     parameters for the splashScreen
% trialParameters:      one blocks's worth of trial parameters. Used
%                       as per stimuli
%
% OUTPUT - optional, if you want it sent to the command window
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
if nargin ~=4
    error(['Not enough arguments. Usage: [experimentRecord timeStamps] = maskedPrimeTabletMain ', ...
        '(experimentParameters, maskParameters, trialParameters). (maskedPrimeTabletMain.m)']);
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

defaultLineWidths = 4;
dotSize = 5; %Fixation dot size

%***Tablet parameters***
%These parameters are all tablet specific and so won't go into the experiment parameter set up. However, these
%can get set by a local setup file (include this info in it)
deltaT        = 1/100; %100Hz is the sampling rate for the Wacom A3 Inuos2. Computable by diffing the time stamp it outputs.
recordingTime = experimentParameters.ResponseDuration; %Record 1.5s of kinematics

%Starting location for each trial
startLocation = experimentParameters.TabletStartLocation;
startBoxSize = 500;    %.5cm^2 (tablet resolution = 1000 pixels/cm
%The possible values the pen can be at if inside the box
xRange = startLocation(1) - startBoxSize : 1 : startLocation(1) + startBoxSize;
yRange = startLocation(2) - startBoxSize : 1 : startLocation(2) + startBoxSize;
%***/Tablet Parameters***

%Set up a matrix to record what happened in the experiment.
recordTitle = {'Trial Number' '# in Block' 'Block #' 'Trial Type Number' 'Trial Name' 'Trial Type' 'Correct Response'};
experimentRecord = cell(nTrials, length(recordTitle));
timeStamps=[];

%Data matrices + the header for the raw data in each cell of earlyKinematics and lateKinematics
dataHeader = {'xPostion', 'yPosition', 'zPosition', 'ButtonState', 'PacketCount', 'TimeStamp', 'Status', 'StateChanged'};
earlyKinematics=[]; lateKinematics = [];
%****************/SET UP****************

try
    %PTB things to get ready
    [wPtr rect] = Screen('OpenWindow', 0);
    ListenChar(2); %Supress keyboard output from going to the command window
    HideCursor;
    Priority(1);
    
    %Make all the masks for the experiment. The matrices returned are again for use with Screen('DrawLines')
    nMasks = length(trialParameters.trialType) * experimentParameters.nBlocks; %trialParameters.trialType has everything for 1 full block
    masks  = makeMask(nMasks, trialParameters.maskLocation, maskParameters);
    
    %Makes the stimuli for one full block, ie one of everything required. The matrices returned in the struct 'stimuli' are coordinates 
    %and sourceRect information for use with Screen('DrawLines'), and are indexed according to trialParameters.trialInBlock
    maskSize = [max(masks.sourceRects(:,3)) max(masks.sourceRects(:,4))];
    stimuli = makeStimuli (maskSize, trialParameters);
    
    %Coordinates for the fixation dot
    dotRect = [(rect(3)/2)-(dotSize/2) (rect(4)/2)-(dotSize/2) (rect(3)/2)+(dotSize/2) (rect(4)/2)+(dotSize/2)];
        
    %Initialise tablet
    WinTabMex(0, wPtr); %Initialise driver, attach to window wPtr
             
    %Initial blank screen + instructions
    splashScreen(wPtr, splashParameters, trialParameters, stimuli);
    WaitSecs(.2); 
    [secs keyCode] = KbWait; %Pauses until a key press is detected
    while ~keyCode(spaceKeyID)
        [secs keyCode] = KbWait;
        %Tests to see if the escape key has been pressed to end the session (no save data as this is pre-experiment only)
        if keyCode(escKeyID)
            cleanup;
            return; %Ends this run of maskedPrimeTabletMain.m
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
            
            [wPtrMask]      = Screen('OpenOffScreenWindow', wPtr);
            maskSourceRect  = masks.sourceRects(trialOrder(trialInBlock),:);
            maskDestRect    = masks.destRects(trialOrder(trialInBlock),:);
            maskOrientation = 0;
            maskDuration    = trialParameters.maskDuration(trialOrder(trialInBlock))/1000;
            
            blankDuration   = trialParameters.blankDuration(trialOrder(trialInBlock))/1000;
            
            [wPtrTarget]      = Screen('OpenOffScreenWindow', wPtr); 
            targetLocation    = stimuli.targetCoordinates{trialOrder(trialInBlock)};
            targetSourceRect  = stimuli.targetSourceRect(trialOrder(trialInBlock),:);
            targetDestRect    = stimuli.targetDestRect(trialOrder(trialInBlock),:);
            targetOrientation = trialParameters.targetOrientation(trialOrder(trialInBlock));
            targetDuration    = trialParameters.targetDuration(trialOrder(trialInBlock))/1000;

            %**************BEGIN TRIAL**************           
            Screen('FillOval', wPtr, black, dotRect); Screen('Flip', wPtr);  %Draw fixation dot
            
            %Waits until pen enters tablet
            WinTabMex(2); %Empties the queue so that pkt remains empty until the stylus is placed
            pkt=WinTabMex(5);
            while 1
                %while loop runs until there is data and the (x,y) coordinates are at the starting location.
                %You can escape out prior to this being true, ie while the fixation dot is showing
                while isempty(pkt)|| (~ismember(pkt(1), xRange) || ~ismember(pkt(2), yRange))
                    pkt = WinTabMex(5);

                    %Checks for the escape key
                    [keyIsDown, secs, keyCode] = KbCheck;
                    if keyCode(escKeyID)
                        cleanup;
                        return;
                    end
                    WaitSecs(deltaT); %No point sampling faster than the tablet's sampling rate
                end
                
                %Checks after .5s to make sure you are still inside the starting box. If not, the 'while 1' will run again 
                %This ensures the participant is in the start box and steady.
                WinTabMex(2);
                WaitSecs(.5);
                pkt = WinTabMex(5);
                if (ismember(pkt(1), xRange) && ismember(pkt(2), yRange))
                    break; %Breaks from 'while 1' loop & begins the trial
                end
            end
            nPktRows = size(pkt, 1); %Figure this out now, when you are sure to have a packet to check, in case WinTabMex gets further updates
            Screen('FillRect', wPtr, white); Screen('Flip', wPtr);
            WaitSecs(.5);

            WinTabMex(2); %Reset the tablet queue to be empty. This will start to fill up and will contain ~30 values by the
                          %time the fast queue dump is executed (33+100+50+100 = 283ms of stimulus presentation + some variation)
            %**************BEGIN DISPLAY**************
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
            
            if isequal(experimentParameters.MaskTargetISI, {'yes'})
                %Mask - 100ms (6 frames @ 60Hz)            
                switch maskParameters.maskType{:}
                    case {'lines', 'randomLines'}
                        Screen('DrawLines', wPtrMask, maskLocation, masks.penWidths{trial}, 0);
                    case 'squares'
                        Screen('FrameRect', wPtrMask, black, maskLocation, masks.penWidths{trial});
                end
                Screen('DrawTexture', wPtr, wPtrMask, maskSourceRect, maskDestRect);
                [maskFlipStart, maskStimOnset] = Screen('Flip', wPtr, primeFlipStart+(primeDuration-.01));
                
                %Blank screen - 50ms, 3 frames @ 60Hz
                Screen('FillRect', wPtr, white); 
                [blankFlipStart, blankStimOnset] = Screen('Flip', wPtr, maskFlipStart+(maskDuration-.01));
                
                %Target - 100ms (6 frames @ 60Hz)
                if ~isempty(targetLocation)
                    Screen('DrawLines', wPtrTarget, targetLocation, defaultLineWidths, black);
                    Screen('DrawTexture', wPtr, wPtrTarget, targetSourceRect, targetDestRect, targetOrientation);
                else  %Allows you to display no-target trials with everything else intact
                    Screen('FillRect', wPtr, white);
                end
                [targetFlipStart, targetStimOnset] = Screen('Flip', wPtr, blankFlipStart+(blankDuration-.01));
               
            elseif isequal(experimentParameters.MaskTargetISI, {'no'})
                if ~isempty(targetLocation)
                    switch maskParameters.maskType{:}
                        case {'lines', 'randomLines'}
                            Screen('DrawLines', wPtrMask, maskLocation, masks.penWidths{trial}, 0);
                        case 'squares'
                            Screen('FrameRect', wPtrMask, black, maskLocation, masks.penWidths{trial});
                    end
                    Screen('DrawLines', wPtrTarget, targetLocation, defaultLineWidths, black);
                                        
                    Screen('DrawTextures', wPtr, [wPtrMask; wPtrTarget], [maskSourceRect; targetSourceRect]',...
                        [maskDestRect; targetDestRect]', [maskOrientation; targetOrientation]');                    
                end
                [targetFlipStart, targetStimOnset] = Screen('Flip', wPtr, primeFlipStart+(primeDuration-.01));
                blankFlipStart = targetFlipStart;   blankStimOnset = targetStimOnset;
                maskFlipStart  = targetFlipStart;   maskStimOnset  = targetStimOnset;
            end
            
            %Final response screen
            Screen('FillRect', wPtr, white);
            [blank2FlipStart, blank2StimOnset] = Screen('Flip', wPtr, targetFlipStart + (targetDuration-.01));
            %**************END DISPLAY**************
            
            %**************BEGIN RESPONSE HANDLING**************
            %Records response
            tempData1=[]; tempData2=[];
            %Fast loop to drain the queue - contains the kinematics recorded during stimulus presentation
            while 1
                pkt = WinTabMex(5)';
                if isempty(pkt) %ie queue empty
                    break;
                else
                    tempData1 = [tempData1; pkt];
                end
            end
            
            %Slow loop that runs for 'recordingTime' and records the kinematics post-targetOffset.
            loop=0; 
            recordStart = WaitSecs(.01);  stop = recordStart + recordingTime;
            while GetSecs < stop
                loop = loop + 1;
                loopEnd = recordStart+(loop*deltaT);
                
                pkt = WinTabMex(5);
                %If the queue is empty, polls it until a value is reported or it runs out of time
                while isempty(pkt) && GetSecs<(loopEnd-.01)
                    pkt = WinTabMex(5);
                end
                if isempty(pkt)
                    pkt = zeros(nPktRows,1); %Default to index a miss. Gets corrected later
                end
                tempData2 = [tempData2; pkt'];
                
                WaitSecs('UntilTime', loopEnd);
            end
            
            earlyKinematics  = [earlyKinematics; {tempData1}];
            lateKinematics   = [lateKinematics; {tempData2}];
            timeStamps = [timeStamps; primeStimOnset maskStimOnset blankStimOnset targetStimOnset blank2StimOnset,...
                recordStart tempData1(1,6) tempData2(1,6)];
            %**************END RESPONSE HANDLING**************
            %Fill in experimentRecord for this trial
            experimentRecord{trial, 1} = trial;
            experimentRecord{trial, 2} = trialInBlock;
            experimentRecord{trial, 3} = block;
            experimentRecord{trial, 4} = trialParameters.uniqueTrialNumbers(trialOrder(trialInBlock));
            experimentRecord{trial, 5} = trialParameters.trialName{trialOrder(trialInBlock)};
            experimentRecord{trial, 6} = trialParameters.trialType{trialOrder(trialInBlock)};
            experimentRecord{trial, 7} = trialParameters.correctResponse{trialOrder(trialInBlock)};
            
            %Clear the stimuli offscreen windows for use again
            Screen('Close', [wPtrPrime wPtrMask wPtrTarget]);
        end
        %Break between blocks
        while ~isequal(block, experimentParameters.nBlocks) %Skip last block          
            splashScreen(wPtr, splashParameters, trialParameters, stimuli);
            WaitSecs(.5); [secs keyCode] = KbWait;

            %Tests to see if the escape key has been pressed to end the session
            if keyCode(escKeyID)
                save QUITDATA experimentRecord timeStamps earlyKinematics lateKinematics experimentParameters trialParameters;
                cleanup;
                return; %Ends this run of maskedPrimeTabletMain.m
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
    WaitSecs(1); %Turns itself off after a second
    
    %Save data out to Excel and Matlab format files
    experimentRecord = [recordTitle; experimentRecord];
    if ~isequal(subID, 'practice')
        fileName = [subID, '_maskedPrimeTabletData.mat'];
        if ~exist(fileName, 'file')
            eval(['save ', fileName,...
                ' experimentRecord timeStamps dataHeader earlyKinematics lateKinematics experimentParameters trialParameters']);
            analyseActionData(subID, 'masked');
        else
            %Note this check is only done once - rename kghrhtgkrehk.xls immediately or it will be overwritten
            save kghrhtgkrehk_maskedPrimeTabletData experimentRecord timeStamps earlyKinematics lateKinematics experimentParameters trialParameters;
            analyseActionData('kghrhtgkrehk', 'masked');
            disp(['Warning! ', fileName, ' already existed (maskedPrimeTabletMain.m).']);
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
    eval(['save ', experimentParameters.subID,...
        '_maskedPrimeTabletData experimentRecord timeStamps earlyKinematics lateKinematics experimentParameters trialParameters']);
end
return

function cleanup
%Performs everything needed to shut this down properly

Priority(0);
WinTabMex(3);       WinTabMex(1);  %Stop data acquisition and shutdown the driver
ListenChar(1);  Screen('CloseAll');     ShowCursor; 
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