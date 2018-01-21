function test(fileName)
%function test(fileName)
% Runs through one unrandomised block of the experiment specified in
% fileName with 2s intervals between stimuli. This allows you to check
% that all your stimuli are drawing correctly, and are sized and
% located where you want, plus to make sure your primes are
% displaying, etc. 
% 
% Escape key functionality is enabled whenever something is displayed
% on the screen (prime, mask or target)
% 
% Andrew D Wilson (2009)

[experimentParameters maskParameters splashParameters trialParameters] = readExperimentParameters(fileName);

%****************SET UP****************
nTrialsPerBlock = length(trialParameters.trialName);

KbName('UnifyKeyNames'); %Set to consistent standard (OSX format)
spaceKeyID = KbName('space');
escKeyID   = KbName('ESCAPE');

black = BlackIndex(0);
white = WhiteIndex(0);

defaultLineWidths = 4;
%****************END SET UP****************

try
    [wPtr] = Screen('OpenWindow', 0);
    
    nMasks = [nTrialsPerBlock experimentParameters.nBlocks]; %trialParameters.trialType has everything for 1 full block
    masks  = makeMask(nMasks, trialParameters.maskLocation, maskParameters);
    maskSize = [max(masks.sourceRects(:,3)) max(masks.sourceRects(:,4))];
    stimuli = makeStimuli (maskSize, trialParameters);
    
    for block = 1
        trialOrder = [1:nTrialsPerBlock]'; %Always unrandomised
        
        splashScreen(wPtr, splashParameters, trialParameters, stimuli);
        %2s pause, monitors for escape key
        [keyIsDown, secs, keyCode] = KbCheck;
        while ~keyCode(spaceKeyID)
            [keyIsDown, secs, keyCode] = KbCheck;                
            if keyIsDown
                %Checks for escape key - this allows you to quit out any time, saves out data thus far
                if keyCode(escKeyID)
                    Screen('CloseAll');
                    return
                end
            end
        end
            
        for trialInBlock = 1:nTrialsPerBlock
            trial = (block-1)*nTrialsPerBlock + trialInBlock; %Indexes where in the experiment you are
                       
            [wPtrPrime]      = Screen('OpenOffScreenWindow', wPtr);            
            primeLocation    = stimuli.primeCoordinates{trialOrder(trialInBlock)};
            primeSourceRect  = stimuli.primeSourceRect(trialOrder(trialInBlock),:);
            primeDestRect    = stimuli.primeDestRect(trialOrder(trialInBlock),:);
            primeOrientation = trialParameters.primeOrientation(trialOrder(trialInBlock));
            primeDuration    = trialParameters.primeDuration(trialOrder(trialInBlock))/1000;
            
            [wPtrMask]      = Screen('OpenOffScreenWindow', wPtr); %Needed to stop the Screen('Close') call working
            if ~isequal(experimentParameters.Masking, {'unmasked'})
                maskLocation    = masks.maskCoordinates{trialOrder(trialInBlock)};
                maskSourceRect  = masks.sourceRects(trialOrder(trialInBlock),:);
                maskDestRect    = masks.destRects(trialOrder(trialInBlock),:);
                maskOrientation = 0;
                maskDuration    = trialParameters.maskDuration(trialOrder(trialInBlock))/1000;
            end
            
            blankDuration   = trialParameters.blankDuration(trialOrder(trialInBlock))/1000;
            
            [wPtrTarget]      = Screen('OpenOffScreenWindow', wPtr); 
            targetLocation    = stimuli.targetCoordinates{trialOrder(trialInBlock)};
            targetSourceRect  = stimuli.targetSourceRect(trialOrder(trialInBlock),:);
            targetDestRect    = stimuli.targetDestRect(trialOrder(trialInBlock),:);
            targetOrientation = trialParameters.targetOrientation(trialOrder(trialInBlock));
            targetDuration    = trialParameters.targetDuration(trialOrder(trialInBlock))/1000;
            %**************BEGIN DISPLAY**************
            %Prime - 33ms (2 frame @ 60Hz)
            if ~isempty(primeLocation)
                Screen('DrawLines', wPtrPrime, primeLocation, defaultLineWidths, black);
                Screen('DrawTexture', wPtr, wPtrPrime, primeSourceRect, primeDestRect, primeOrientation);
            else  %Allows you to display unprimed trials with everything else intact
                Screen('FillRect', wPtr, white);
            end
            [primeFlipStart, primeStimOnset] = Screen('Flip', wPtr);
                
            %2s pause, monitors for escape key
            start = GetSecs;
            while GetSecs<start+2
                [keyIsDown, secs, keyCode] = KbCheck;                
                if keyIsDown
                    %Checks for escape key - this allows you to quit out any time, saves out data thus far
                    if keyCode(escKeyID)
                        Screen('CloseAll');
                        return
                    end
                end
            end
            
            if ~isequal(experimentParameters.Masking, {'unmasked'})
                if isequal(experimentParameters.MaskTargetISI, {'yes'})
                    %Mask - 100ms (6 frames @ 60Hz)            
                    switch maskParameters.maskType{:}
                        case {'lines', 'randomLines'}
                            Screen('DrawLines', wPtrMask, maskLocation, masks.penWidths{trial}, 0);
                        case 'squares'
                            Screen('FrameRect', wPtrMask, black, maskLocation, masks.penWidths{trial});
                    end
                    Screen('DrawTexture', wPtr, wPtrMask, maskSourceRect, maskDestRect);
                    Screen('Flip', wPtr);
                    
                    %2s pause, monitors for escape key
                    start = GetSecs;
                    while GetSecs<start+2
                        [keyIsDown, secs, keyCode] = KbCheck;                
                        if keyIsDown
                            %Checks for escape key - this allows you to quit out any time, saves out data thus far
                            if keyCode(escKeyID)
                                Screen('CloseAll');
                                return
                            end
                        end
                    end
                    
                    %Target - 100ms (6 frames @ 60Hz)
                    if ~isempty(targetLocation)
                        Screen('DrawLines', wPtrTarget, targetLocation, defaultLineWidths, black);
                        Screen('DrawTexture', wPtr, wPtrTarget, targetSourceRect, targetDestRect, targetOrientation);
                    else  %Allows you to display no-target trials with everything else intact
                        Screen('FillRect', wPtr, white);
                    end
                    Screen('Flip', wPtr);
                    
                    %2s pause, monitors for escape key
                    start = GetSecs;
                    while GetSecs<start+2
                        [keyIsDown, secs, keyCode] = KbCheck;                
                        if keyIsDown
                            %Checks for escape key - this allows you to quit out any time, saves out data thus far
                            if keyCode(escKeyID)
                                Screen('CloseAll');
                                return
                            end
                        end
                    end                      

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
                    Screen('Flip', wPtr);
                    
                    %2s pause, monitors for escape key
                    start = GetSecs;
                    while GetSecs<start+2
                        [keyIsDown, secs, keyCode] = KbCheck;                
                        if keyIsDown
                            %Checks for escape key - this allows you to quit out any time, saves out data thus far
                            if keyCode(escKeyID)
                                Screen('CloseAll');
                                return
                            end
                        end
                    end 
                end
                
            elseif isequal(experimentParameters.Masking, {'unmasked'})
                %Target - 100ms (6 frames @ 60Hz)
                if ~isempty(targetLocation)
                    Screen('DrawLines', wPtrTarget, targetLocation, defaultLineWidths, black);
                    Screen('DrawTexture', wPtr, wPtrTarget, targetSourceRect, targetDestRect, targetOrientation);
                else  %Allows you to display no-target trials with everything else intact
                    Screen('FillRect', wPtr, white);
                end
                Screen('Flip', wPtr);
                
                %2s pause, monitors for escape key
                start = GetSecs;
                while GetSecs<start+2
                    [keyIsDown, secs, keyCode] = KbCheck;                
                    if keyIsDown
                        %Checks for escape key - this allows you to quit out any time, saves out data thus far
                        if keyCode(escKeyID)
                            Screen('CloseAll');
                            return
                        end
                    end
                end 
            end
            Screen('FillRect', wPtr, white);
            Screen('Flip', wPtr);
            %1s pause, monitors for escape key
            start = GetSecs;
            while GetSecs<start+1
                [keyIsDown, secs, keyCode] = KbCheck;                
                if keyIsDown
                    %Checks for escape key - this allows you to quit out any time, saves out data thus far
                    if keyCode(escKeyID)
                        Screen('CloseAll');
                        return
                    end
                end
            end 
            %**************END DISPLAY**************
            Screen('Close', [wPtrPrime wPtrMask wPtrTarget]);
        end
    end    
    Screen('CloseAll');
catch
    Screen('CloseAll');
    bob = lasterror
    bob.message
    stack = bob.stack;
    stack.file
    stack.line
end