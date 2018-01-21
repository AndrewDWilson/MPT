function splashScreen(wPtr, splashParameters, trialParameters, stimuli)
% function splashScreen(wPtr, splashParameters, trialParameters, stimuli)
% 
% Draws a splash screen for use at the start of an experiment and in
% between blocks. It uses the parameters from the text file to find
% the information required to draw the right stimuli, places the
% specified correct response under the right stimulus, and puts
% everything where you tell it in 'Location'. It also draws the text
% 'Press the space bar to continue' centred and at y = 20% of the
% screen height up from the bottom)
%
% NB: Location currently requires you to specify the specific
% coordinates where you want things to go. I will eventually implement
% some defaults (left, right, top, down, centre) all defined relative
% to the centre, as well as any other requests for commonly used
% locations. This is low priority, though. Use the function
% utilities('screenSize') to find the size of your monitor in pixels,
% and use this to tweak where you want things. Remember: (0,0) is the
% top left corner, x increases going right and y increases going down.
% 
% ARGUMENTS
% wPtr:             the window pointer for where the stimuli are to be
%                   drawn. This will generally be the main wPtr for an
%                   experiment
% splashParameters: a struct containing the parameters read in from
%                   the text parameter file for the splash screen. See
%                   'help readExperimentParameters' for more information
% trialParameters:  a struct containing the parameters read in from
%                   the text parameter file for all trials. See 'help
%                   readExperimentParameters for more information
% stimuli:          a struct containing prime and target coordinates.
%                   See 'help makeStimuli' for more information
%
% Andrew D Wilson (2009)

%****************SET UP****************
black = BlackIndex(0);

defaultLineWidths = 4;

%Identifies the unique types of targets that are going to be drawn
sourceRects = [];
coordinates = cell(size(splashParameters.responses, 1), 1);
%****************END SET UP****************

%SORT OUT WHAT STIMULI TO DRAW
%splashParameters.responses contains the names of the responses to be demonstrated. This loop scrolls through this list one at a time, and then
%scrolls through trialParameters.correctResponses looking for a trial specification that matches that response. This then provides all the
%details about stimuli, etc, because there must always only be one response per imperative stimulus.
%
%This all needs to happen this way because making stimuli requires parameters that this code does not have access to, so it can't make stimuli
%itself via makeStimuli.m. Future versions may alter this, although frankly this works fine.
for response = 1:size(splashParameters.responses, 1)
    for trial = 1:length(trialParameters.correctResponse)     %This subloop identifies a trial specifying one of the possible responses
        if isequal(splashParameters.imperativeStimulus, 'prime')
            if isequal(trialParameters.correctResponse{trial}, splashParameters.responses{response}{:}) &&...
                    isequal(trialParameters.primeOrientation(trial), splashParameters.orientations{response})
                sourceRects           = [sourceRects; stimuli.primeSourceRect(trial,:)];
                coordinates{response} = stimuli.primeCoordinates{trial};
                break
            end
        else
            if isequal(trialParameters.correctResponse{trial}, splashParameters.responses{response}{:}) &&...
                    isequal(trialParameters.targetOrientation(trial), splashParameters.orientations{response})
                sourceRects           = [sourceRects; stimuli.targetSourceRect(trial,:)];
                coordinates{response} = stimuli.targetCoordinates{trial};
                break;
            end
        end        
    end
end

%DRAW THE SPLASH SCREEN
%Takes the coordinates of the stimuli to be drawn and sends them to the specified locations on the screen.
try
    %Default screen locations - DO LATER. Set up left, right, centre, up, down
    rect=Screen('Rect', wPtr);  %Gets the size of the screen    
    
    %Loops through the stimuli to be drawn (via DrawLines) and sends them one at a time to the screen at wPtr via an offscreen window called
    %wPtrStimuli. This set up clears the intermediate screen in between, because otherwise a second stimulus is drawn on top of the first and you
    %end up with overlayed stimuli.
    %The response string 'splashParameters.responses{item}{:}' is also drawn, centred on and 20 pixels below the corresponding stimulus. 
    %All these elements (stimuli, responses) are then sent to the Screen at wPtr. Once everything is drawn, the Screen is flipped and sits there
    %until the space bar is pressed.
    for item = 1:size(splashParameters.responses, 1)       
        %Sort out where the stimuli are going to go
        eval(['location = ', splashParameters.locations{item}{:}, ';']);  %Converts from string to a double, stores in variable 'location'
        destRect = sourceRects(item,:) + [location location];             %Moves sourceRect to required screen location, preserving sizes, etc
        
        %DRAW STIMULI as texture to wPtrStimuli, then sends to wPtr using orientation parameters
        wPtrStimuli = Screen('OpenOffScreenWindow', wPtr);  
        Screen('DrawLines', wPtrStimuli, coordinates{item}, defaultLineWidths, black);
        Screen('DrawTextures', wPtr, wPtrStimuli, sourceRects(item,:), destRect, splashParameters.orientations{item});
        Screen('Close', wPtrStimuli); %Clears this for reuse so that things don't get drawn on top of each other
        
        %DRAW RESPONSES - Computes where to put the text specifying the required response so its centred under the relevant stimuli.
        Screen('TextSize', wPtr, 32);  %Set text size to 32
        [normBoundsRect]= Screen('TextBounds', wPtr, splashParameters.responses{item}{:});        
        textCentreX     = normBoundsRect(3)/2;
        stimulusCentreX = destRect(3)-.5*(destRect(3)-destRect(1));

        textX = stimulusCentreX - textCentreX;  %Top left x of text box
        textY = destRect(4) + 20;               %Top left y of text box
        Screen('DrawText', wPtr, splashParameters.responses{item}{:}, textX, textY, black);        
    end
    %Location is 20% of the screen height from the bottom
    DrawFormattedText(wPtr, 'Press the space bar to continue', 'center', rect(4)-(rect(4)/5), black);
    
    %Flip the completed splash screen; handle space bar pressing, etc in the various maskedPrimeMain.m files
    Screen('Flip', wPtr);  
catch
    splashError = lasterror;
    message     = splashError(1).message
    identifier  = splashError(1).identifier
    stack       = splashError(1).stack
    file        = stack.file
    line        = stack.line
    Screen('CloseAll');
end
        
 
    