function stimuli = makeStimuli (maskSize, trialParameters)
% function stimuli = makeStimuli (maskSize, trialParameters)
% 
% Creates two nTrialsx1 cell vectors of coordinates for drawing fully
% parameterised stimuli. There is a vector for primes and for targets. 
% 
% Each cell in the vector contains a 2x2*nLines matrix of coordinates
% suitable for use with Screen('DrawLines'). The matrix is arranged:
%     [ originX   endX1 ... originX   endXn
%       originY   endY1 ... originX   endYn]
% for n lines in the stimulus.
% 
% ARGUMENTS
% maskSize:        the size of the largest random mask for this
%                  experiment - in the form [maxX maxY] 
% trialParameters: a struct array created when
%                  ExperimentParameters.txt is read in via
%                  readExperimentParameters.m
% 
% RETURN VALUES:
% stimuli = a struct, containing fields
%     primeCoordinates:  an nTrialx1 cell vector of coordinates for
%                        the prime for that trial
%     primeSourceRect:   an nTrialx4 matrix with the coordinates that
%                        specify the rect that the primes for that
%                        trial are drawn in
%     primeDestRect:     an nTrialx4 matrix with the coordinates that
%                        specify the rect that the primes for that
%                        trial are drawn in
%     targetCoordinates: an nTrialx1 cell vector of coordinates for
%                        the target for that trial
%     targetSourceRect:  an nTrialx4 matrix with the coordinates that
%                        specify the rect that the targets for that
%                        trial are drawn in
%     targetDestRect:    an nTrialx4 matrix with the coordinates that
%                        specify the rect that the targets for that
%                        trial are drawn in
%
% SUBFUNCTIONS
% makeTripleLines
% makeSingleArrow
% makeDoubleArrow
% makeBrackets
% makeCross
% makeExCross
% makeExSquare
% makeRectangle
% 
% Andrew D Wilson (2009)

rect = Screen('Rect', 0);

nTrials = length(trialParameters.trialType);

primeCoordinates  = cell(nTrials, 1);
primeSourceRect   = zeros(nTrials, 4);
primeDestRect     = zeros(nTrials, 4);

targetCoordinates = cell(nTrials, 1);
targetSourceRect  = zeros(nTrials, 4);
targetDestRect    = zeros(nTrials, 4);

for trial = 1:nTrials
    %Primes
    primeGain = trialParameters.primeSize(trial);
    
    %Compute line coordinates for the desired prime shape
    switch trialParameters.prime{trial}
        case 'doubleArrow'
            [arrowCoordinates sourceRect] = makeDoubleArrow(primeGain);
            primeCoordinates{trial}  = arrowCoordinates;
            primeSourceRect(trial,:) = sourceRect;
            
        case 'brackets'
            [bracketCoordinates sourceRect] = makeBrackets(primeGain);
            primeCoordinates{trial}  = bracketCoordinates;
            primeSourceRect(trial,:) = sourceRect;
            
        case 'tripleLines'
            [lineCoordinates sourceRect] = makeTripleLines(primeGain);
            primeCoordinates{trial}  = lineCoordinates;
            primeSourceRect(trial,:) = sourceRect;
            
        case 'exSquare'
            [exSquareCoordinates sourceRect] = makeExSquare(primeGain);
            primeCoordinates{trial}  = exSquareCoordinates;
            primeSourceRect(trial,:) = sourceRect;
            
        case 'rectangle'
            [rectangleCoordinates sourceRect] = makeRectangle(primeGain);
            primeCoordinates{trial}  = rectangleCoordinates;
            primeSourceRect(trial,:) = sourceRect;
            
        case 'cross'
            [crossCoordinates sourceRect] = makeCross(primeGain);
            primeCoordinates{trial}  = crossCoordinates;
            primeSourceRect(trial,:) = sourceRect;
            
        case 'exCross'  %exploded cross
            [exCrossCoordinates sourceRect] = makeExCross(primeGain);
            primeCoordinates{trial}  = exCrossCoordinates;
            primeSourceRect(trial,:) = sourceRect;
            
        case 'none'
            sourceRect = [0 0 0 0];
            primeCoordinates{trial} = [];
            primeSourceRect(trial,:) = sourceRect;
            
        otherwise
            if isequal(trialParameters.prime{trial}(1:5), 'cross')
                [crossCoordinates sourceRect] = makeCrossedLines(primeGain, trialParameters.prime{trial});
                primeCoordinates{trial}  = crossCoordinates;
                primeSourceRect(trial,:) = sourceRect;
            else
                error('Invalid prime - check your parameter file for typos, etc (makeStimuli.m)');
            end
    end
    
    %Compute the (x,y) location on which the prime should be centred.
    %Locations are relative to the centre of the screen
    switch trialParameters.primeLocation{trial}
        case 'centre'
            pLocation = [rect(3)/2 rect(4)/2];
        case 'left'
            pLocation = [(rect(3)/2 - maskSize(1)/2 - primeSourceRect(trial, 3)/2) rect(4)/2];
        case 'right'
            pLocation = [(rect(3)/2 + maskSize(1)/2 + primeSourceRect(trial, 3)/2) rect(4)/2];
        case 'up'
            pLocation = [rect(3)/2 (rect(4)/2 - maskSize(2)/2 - primeSourceRect(trial,3)/2)];
        case 'down'
            pLocation = [rect(3)/2 (rect(4)/2 + maskSize(2)/2 + primeSourceRect(trial,3)/2)];
        otherwise
            try
                eval(['pLocation = ', trialParameters.primeLocation{trial}, ';']);
            catch
                error('Prime location was not read correctly. Check your parameter file (makeStimuli.m)');
            end
    end    
    %Corrects the centred coordinates to compute the destRect 
    sizeStim  = [(primeSourceRect(trial, 3)-primeSourceRect(trial, 1))/2 (primeSourceRect(trial, 4)-primeSourceRect(trial, 2))/2];
    newOrigin = pLocation - sizeStim;
    primeDestRect(trial, :) = [newOrigin newOrigin(1)+sourceRect(3) newOrigin(2)+sourceRect(4)];
  
    %*******************************************
    %Targets
    targetGain = trialParameters.targetSize(trial);
    
    %Compute line coordinates for the desired target shape    
    switch trialParameters.target{trial}
        case 'doubleArrow'
            [arrowCoordinates sourceRect] = makeDoubleArrow(targetGain);
            targetCoordinates{trial}  = arrowCoordinates;
            targetSourceRect(trial,:) = sourceRect;
            
        case 'exSquare'
            [exSquareCoordinates sourceRect] = makeExSquare(targetGain);
            targetCoordinates{trial}  = exSquareCoordinates;
            targetSourceRect(trial,:) = sourceRect;
             
        case 'rectangle'
            [rectangleCoordinates sourceRect] = makeRectangle(primeGain);
            targetCoordinates{trial}  = rectangleCoordinates;
            targetSourceRect(trial,:) = sourceRect;
            
        case 'cross'
            [crossCoordinates sourceRect] = makeCross(targetGain);
            targetCoordinates{trial}  = crossCoordinates;
            targetSourceRect(trial,:) = sourceRect;
            
        case 'exCross'  %Exploded cross
            [exCrossCoordinates sourceRect] = makeExCross(targetGain);
            targetCoordinates{trial}  = exCrossCoordinates;
            targetSourceRect(trial,:) = sourceRect;
            
        case 'none'
            targetCoordinates{trial} = [];
            
        otherwise           
            if isequal(trialParameters.target{trial}(1:5), 'cross')
                [crossCoordinates sourceRect] = makeCrossedLines(targetGain, trialParameters.target{trial});
                targetCoordinates{trial}  = crossCoordinates;
                targetSourceRect(trial,:) = sourceRect;
            else
                error('Invalid target - check your parameter file for typos, etc (makeStimuli.m)');
            end
    end
    
    %Compute the (x,y) location on which the prime should be centred.
    %Locations are relative to the centre of the screen
    switch trialParameters.targetLocation{trial}
        case 'centre'
            pLocation = [rect(3)/2 rect(4)/2];
        case 'left'
            pLocation = [(rect(3)/2 - maskSize(1)/2 - targetSourceRect(trial, 3)/2) rect(4)/2];
        case 'right'
            pLocation = [(rect(3)/2 + maskSize(1)/2 + targetSourceRect(trial, 3)/2) rect(4)/2];
        case 'up'
            pLocation = [rect(3)/2 (rect(4)/2 - maskSize(2)/2 - targetSourceRect(trial,3)/2)];
        case 'down'
            pLocation = [rect(3)/2 (rect(4)/2 + maskSize(2)/2 + targetSourceRect(trial,3)/2)];
        otherwise
            try
                eval(['pLocation = ', trialParameters.targetLocation{trial}, ';']);
            catch
                error('Target location was not read correctly. Check your parameter file (makeStimuli.m)');
            end
    end    
    %Corrects the centred coordinates to compute the destRect 
    sizeStim  = [(targetSourceRect(trial, 3)-targetSourceRect(trial, 1))/2 (targetSourceRect(trial, 4)-targetSourceRect(trial, 2))/2];
    newOrigin = pLocation - sizeStim;
    targetDestRect(trial, :) = [newOrigin newOrigin(1)+sourceRect(3) newOrigin(2)+sourceRect(4)];
end

%Assembles everything into a struct to get passed around. Unpack later for use.
stimuli = struct;

stimuli.primeCoordinates = primeCoordinates;
stimuli.primeSourceRect  = primeSourceRect;
stimuli.primeDestRect    = primeDestRect;

stimuli.targetCoordinates = targetCoordinates;
stimuli.targetSourceRect  = targetSourceRect;
stimuli.targetDestRect    = targetDestRect;

return

function [lineCoordinates sourceRect] = makeTripleLines(gain)
% function [lineCoordinates sourceRect] = makeTripleLines(gain)
% 
% Creates a single matrix of line coordinates suitable for use with Screen('Drawlines') for a triple set of horizontal lines
% 
% The coordinates are such that the lines are being drawn to the very top left corner of the screen in a box that ranges from 
% (0,0) to (endX3R, endYR) in size. This 'sourceRect' should get used to compute an appropriate 'destRect'
%
% INPUTS
% gain - the parameter from the trialParameters struct that alters the stimulus size
% 
% OUTPUTS
% lineCoordinates - a 2 x 2*nLines matrix of coordinates suitable for use with Screen('DrawLines')
% sourceRect      - a rect vector specifying the size of the brackets for positioning purposes
% 
% Andrew D. Wilson (2009)

%Width and offset make this 65x40 pixels high, same size as a double arrow with a gain of 1
defaultWidth  = 65;
defaultOffset = 20;
defaultLineWidth = 4;  %This must match what's set in the main.m files

width  = defaultWidth * gain;
offset = defaultOffset * gain;
correction = defaultLineWidth/2;  %The point [startX startY] is halfway between the top and bottom of a line with any extent >1
                                  % ie it's here, midway up the bracket ->[LINE OF SOME WIDTH]

originX = 0;
originY = 0;

%Line 1
startX1 = originX;
endX1   = originX + width;
startY1 = originY + correction;
endY1   = originY + correction;
xCoordinates = [startX1 endX1];
yCoordinates = [startY1 endY1];

%Line 2
startX2 = originX;
endX2   = originX + width;
startY2 = originY + offset;
endY2   = originY + offset;
xCoordinates = [xCoordinates startX2 endX2];
yCoordinates = [yCoordinates startY2 endY2];

%Line 3
startX3 = originX;
endX3   = originX + width;
startY3 = (originY + (2*offset)) - correction;
endY3   = (originY + (2*offset)) - correction;
xCoordinates = [xCoordinates startX3 endX3];
yCoordinates = [yCoordinates startY3 endY3];

lineCoordinates = [xCoordinates; yCoordinates];
sourceRect = [originX originY max(xCoordinates) max(yCoordinates)+correction];

function [arrowCoordinates sourceRect] = makeSingleArrow(gain)

function [arrowCoordinates sourceRect] = makeDoubleArrow(gain)
% function [arrowCoordinates sourceRect] = makeDoubleArrow(gain)
% 
% Creates a single matrix of line coordinates suitable for use with Screen('Drawlines') for a double arrow (i.e >>)
% 
% The coordinates are such that the arrow is being drawn to the very top left corner of the screen in a box that ranges from 
% (0,0) to (endX4, endY4) in size. This 'sourcerect' should get computed prior to drawing and used to compute an appropriate 'destRect'
%
% INPUTS
% gain - the parameter from the trialParameters struct that alters the stimulus size
% 
% OUTPUTS
% arrowCoordinates - a 2 x 2*nLines matrix of coordinates suitable for use with Screen('DrawLines')
% sourceRect       - a rect vector specifying the size of the arrow for positioning purposes
% 
% Andrew D. Wilson (2008)

defaultAngle  = 60;
defaultLength = 40;
defaultOffset = 30;

%Sets up the various size related parameters. The gain is taken from ExperimentParameters.txt and multiplied on the defaults
angleRads = (defaultAngle/360)*(2*pi);
length    = gain * defaultLength;
offset    = gain * defaultOffset;

originX = 0;
originY = abs(sin(angleRads/2)*length);  %Halfway down, ie where the tip of the arrow is

%Computes the end coordinates of each line from the origin, angle & length, ie converts from polar to cartesian
%Arrow 1
startX1 = originX;
endX1   = originX + cos(-angleRads/2)* length;
startY1 = originY;
endY1   = originY + sin(-angleRads/2)* length;
xCoordinates = [startX1 endX1]; 
yCoordinates = [startY1 endY1];

startX2 = originX;
endX2   = originX + cos(angleRads/2)* length;
startY2 = originY;
endY2   = originY + sin(angleRads/2)* length;
xCoordinates = [xCoordinates startX2 endX2]; 
yCoordinates = [yCoordinates startY2 endY2];

%Arrow 2
startX3 = originX + offset;
endX3   = (originX + offset) + cos(-angleRads/2)* length;
startY3 = originY;
endY3   = originY + sin(-angleRads/2)* length;
xCoordinates = [xCoordinates startX3 endX3]; 
yCoordinates = [yCoordinates startY3 endY3];

startX4 = originX +offset;
endX4 = (originX + offset) + cos(angleRads/2)* length;
startY4 = originY;
endY4 = originY + sin(angleRads/2)* length;
xCoordinates = [xCoordinates startX4 endX4]; 
yCoordinates = [yCoordinates startY4 endY4];

arrowCoordinates = [xCoordinates; yCoordinates];
sourceRect = [originX 0 max(xCoordinates) max(yCoordinates)];
return;

function [bracketCoordinates sourceRect] = makeBrackets(gain)
% function [bracketCoordinates sourceRect] = makeBrackets(gain)
% 
% Creates a single matrix of line coordinates suitable for use with Screen('Drawlines') for a set of brackets (e.g. [ ])
% 
% The coordinates are such that the brackets are being drawn to the very top left corner of the screen in a box that ranges from 
% (0,0) to (endX3R, endYR) in size. This 'sourceRect' should get used to compute an appropriate 'destRect'
%
% INPUTS
% gain - the parameter from the trialParameters struct that alters the stimulus size
% 
% OUTPUTS
% bracketCoordinates - a 2 x 2*nLines matrix of coordinates suitable for use with Screen('DrawLines')
% sourceRect       - a rect vector specifying the size of the brackets for positioning purposes
% 
% Andrew D. Wilson (2008)

%Height, width and offset make this 65x40 pixels, same size as a double arrow with a gain of 1
defaultHeight = 40;
defaultWidth  = 20;
defaultOffset = 15;
defaultLineWidth = 4;

height = defaultHeight * gain;
width  = defaultWidth * gain;
offset = defaultOffset;
correction = defaultLineWidth/2; %The point [startX startY] is halfway between the top and bottom of a line with any extent >1
                                  % ie it's here, midway up the bracket ->[LINE OF SOME WIDTH]

originX = 0;
originY = 0;

%%%Left bracket%%%
%Vertical Line
startX1Left = originX;
endX1Left   = originX;
startY1Left = originY;
endY1Left   = originY + height;
xCoordinates = [startX1Left endX1Left];
yCoordinates = [startY1Left endY1Left];

%Top horizontal line
startX2Left = originX - correction;
endX2Left   = originX + width;
startY2Left = originY + correction;
endY2Left   = originY + correction;
xCoordinates = [xCoordinates startX2Left endX2Left];
yCoordinates = [yCoordinates startY2Left endY2Left];

%Bottom horizontal line
startX3Left = originX - correction;
endX3Left   = originX + width;
startY3Left = originY + height - correction;
endY3Left   = originY + height - correction;
xCoordinates = [xCoordinates startX3Left endX3Left];
yCoordinates = [yCoordinates startY3Left endY3Left];

%%%Right Bracket%%%
%Vertical Line
startX1Right = originX + (2*width) + offset;
endX1Right   = originX + (2*width) + offset;
startY1Right = originY;
endY1Right   = originY + height;
xCoordinates = [xCoordinates startX1Right endX1Right];
yCoordinates = [yCoordinates startY1Right endY1Right];

%Top horizontal line
startX2Right = originX + (2*width) + offset + correction;
endX2Right   = originX + width + offset;
startY2Right = originY + correction;
endY2Right   = originY + correction;
xCoordinates = [xCoordinates startX2Right endX2Right];
yCoordinates = [yCoordinates startY2Right endY2Right];

%Bottom horizontal line
startX3Right = originX + (2*width) + offset + correction;
endX3Right   = originX + width + offset;
startY3Right = originY + height - correction;
endY3Right   = originY + height - correction;
xCoordinates = [xCoordinates startX3Right endX3Right];
yCoordinates = [yCoordinates startY3Right endY3Right];

bracketCoordinates = [xCoordinates; yCoordinates];
sourceRect = [originX-correction originY max(xCoordinates) max(yCoordinates)];

function [crossCoordinates sourceRect] = makeCross(gain)
% function [crossCoordinates sourceRect] = makeCross(gain)
% 
% Creates a single matrix of line coordinates suitable for use with Screen('Drawlines') for a cross (oriented like a t)
% 
% The coordinates are such that the lines are being drawn to the very top left corner of the screen in a box that ranges from 
% (0,0) to (maxX, maxY) in size. This 'sourceRect' should get used to compute an appropriate 'destRect'
%
% INPUTS
% gain - the parameter from the trialParameters struct that alters the stimulus size
% 
% OUTPUTS
% lineCoordinates - a 2 x 2*nLines matrix of coordinates suitable for use with Screen('DrawLines')
% sourceRect      - a rect vector specifying the size of the brackets for positioning purposes
% 
% Andrew D. Wilson (2009)

%Width and offset make this 60x60 (rather than the 65x40 pixels high, same size as a double arrow with a gain of 1)
defaultWidth  = 60;
defaultHeight = 60;

width  = defaultWidth * gain;
height = defaultHeight * gain;

originX = 0;
originY = 0;

%Horizontal line
startX1 = originX;
endX1   = originX + width;
startY1 = originY + (height/2);
endY1   = originY + (height/2);
xCoordinates = [startX1 endX1];
yCoordinates = [startY1 endY1];

%Vertical Line
startX2 = originX + (width/2);
endX2   = originX + (width/2);
startY2 = originY;
endY2   = originY + height;
xCoordinates = [xCoordinates startX2 endX2];
yCoordinates = [yCoordinates startY2 endY2];

crossCoordinates = [xCoordinates; yCoordinates];
sourceRect = [originX originY max(xCoordinates) max(yCoordinates)];

function [exCrossCoordinates sourceRect] = makeExCross(gain)
% function [exCrossCoordinates sourceRect] = makeExCross(gain)
% 
% Creates a single matrix of line coordinates suitable for use with Screen('Drawlines') for an exploded cross (ie the lines
% aren't joined up). For a regular cross, call 'makeCross'
% 
% The coordinates are such that the lines are being drawn to the very top left corner of the screen in a box that ranges from 
% (0,0) to (endX3R, endYR) in size. This 'sourceRect' should get used to compute an appropriate 'destRect'
%
% INPUTS
% gain - the parameter from the trialParameters struct that alters the stimulus size
% 
% OUTPUTS
% lineCoordinates - a 2 x 2*nLines matrix of coordinates suitable for use with Screen('DrawLines')
% sourceRect      - a rect vector specifying the size of the brackets for positioning purposes
% 
% Andrew D. Wilson (2009)

%Width and offset make this 65x40 pixels high, same size as a double arrow with a gain of 1
defaultLength    = 20;
defaultLineWidth = 4;  %This must match what's set in the main.m files
defaultGap = 15;  %Tweak this

length  = defaultLength * gain;
gap     = defaultGap * gain;

correction = defaultLineWidth/2;  %The point [startX startY] is halfway between the top and bottom of a line with any extent >1
                                  % ie it's here, midway up the bracket ->[LINE OF SOME WIDTH]
originX = (2*length + 2*gap)/2;
originY = (2*length + 2*gap)/2;  %Places the origin at the centre

%Top Vertical Line
startX1 = originX;
endX1   = originX;
startY1 = 0;
endY1   = length;
xCoordinates = [startX1 endX1];
yCoordinates = [startY1 endY1];

%Bottom Vertical Line
startX2 = originX;
endX2   = originX;
startY2 = originY + gap;
endY2   = originY + gap + length;
xCoordinates = [xCoordinates startX2 endX2];
yCoordinates = [yCoordinates startY2 endY2];

%Left Horizontal Line
startX3 = 0;
endX3   = length;
startY3 = originY;
endY3   = originY;
xCoordinates = [xCoordinates startX3 endX3];
yCoordinates = [yCoordinates startY3 endY3];

%Right Horizontal Line
startX4 = originX + gap;
endX4   = originX + gap + length;
startY4 = originY;
endY4   = originY;
xCoordinates = [xCoordinates startX4 endX4];
yCoordinates = [yCoordinates startY4 endY4];

exCrossCoordinates = [xCoordinates; yCoordinates];
sourceRect = [0 0 max(xCoordinates)+correction max(yCoordinates)+correction];

function [exSquareCoordinates sourceRect] = makeExSquare(gain)
% function [exSquareCoordinates sourceRect] = makeExSquare(gain)
% 
% Creates a single matrix of line coordinates suitable for use with Screen('Drawlines') for an exploded square (ie the edges
% aren't joined up). For a regular square, requires a new function that allows the use of 'FrameRect'
% 
% The coordinates are such that the lines are being drawn to the very top left corner of the screen in a box that ranges from 
% (0,0) to (endX3R, endYR) in size. This 'sourceRect' should get used to compute an appropriate 'destRect'
%
% INPUTS
% gain - the parameter from the trialParameters struct that alters the stimulus size
% 
% OUTPUTS
% lineCoordinates - a 2 x 2*nLines matrix of coordinates suitable for use with Screen('DrawLines')
% sourceRect      - a rect vector specifying the size of the brackets for positioning purposes
% 
% Andrew D. Wilson (2009)

%Width and offset make this 65x40 pixels high, same size as a double arrow with a gain of 1
defaultLength    = 20;
defaultLineWidth = 4;  %This must match what's set in the main.m files
defaultGap = 15;  %Tweak this

width  = defaultLength * gain;
height = defaultLength * gain;
gap    = defaultGap * gain;

correction = defaultLineWidth/2;  %The point [startX startY] is halfway between the top and bottom of a line with any extent >1
                                  % ie it's here, midway up the bracket ->[LINE OF SOME WIDTH]
originX = 0;
originY = 0;

%Top Line
startX1 = originX + gap;
endX1   = originX + gap + width;
startY1 = originY + correction;
endY1   = originY + correction;
xCoordinates = [startX1 endX1];
yCoordinates = [startY1 endY1];

%Bottom Line
startX2 = originX + gap;
endX2   = originX + gap+ width;
startY2 = originY + height + 2*gap;
endY2   = originY + height + 2*gap;
xCoordinates = [xCoordinates startX2 endX2];
yCoordinates = [yCoordinates startY2 endY2];

%Left Line
startX3 = originX + correction;
endX3   = originX + correction;
startY3 = originY + gap;
endY3   = originY + gap + height;
xCoordinates = [xCoordinates startX3 endX3];
yCoordinates = [yCoordinates startY3 endY3];

%Right Line
startX4 = originX + width + 2*gap - correction;
endX4   = originX + width + 2*gap - correction;
startY4 = originY + gap;
endY4   = originY + gap + height;
xCoordinates = [xCoordinates startX4 endX4];
yCoordinates = [yCoordinates startY4 endY4];

exSquareCoordinates = [xCoordinates; yCoordinates];
sourceRect = [originX originY max(xCoordinates)+correction max(yCoordinates)+correction];

function [rectangleCoordinates sourceRect] = makeRectangle(gain)
% function [rectangleCoordinates sourceRect] = makeRectangle(gain)
% 
% Creates a single matrix of line coordinates suitable for use with Screen('Drawlines') for a rectangle
% 
% The coordinates are such that the lines are being drawn to the very top left corner of the screen in a box that ranges from 
% (0,0) to (endX3R, endYR) in size. This 'sourceRect' should get used to compute an appropriate 'destRect'
%
% INPUTS
% gain - the parameter from the trialParameters struct that alters the stimulus size
% 
% OUTPUTS
% lineCoordinates - a 2 x 2*nLines matrix of coordinates suitable for use with Screen('DrawLines')
% sourceRect      - a rect vector specifying the size of the brackets for positioning purposes
% 
% Andrew D. Wilson (2009)

%Width and offset make this 65x40 pixels high, same size as a double arrow with a gain of 1
defaultWidth  = 65;
defaultHeight = 40;
defaultLineWidth = 4;  %This must match what's set in the main.m files

width  = defaultWidth * gain;
height = defaultHeight * gain;

correction = defaultLineWidth/2;  %The point [startX startY] is halfway between the top and bottom of a line with any extent >1
                                  % ie it's here, midway up the bracket ->[LINE OF SOME WIDTH]
originX = 0;
originY = 0;

%Top Line
startX1 = originX;
endX1   = originX + width;
startY1 = originY + correction;
endY1   = originY + correction;
xCoordinates = [startX1 endX1];
yCoordinates = [startY1 endY1];

%Bottom Line
startX2 = originX;
endX2   = originX + width;
startY2 = originY + height;
endY2   = originY + height;
xCoordinates = [xCoordinates startX2 endX2];
yCoordinates = [yCoordinates startY2 endY2];

%Left Line
startX3 = originX + correction;
endX3   = originX + correction;
startY3 = originY;
endY3   = originY + height;
xCoordinates = [xCoordinates startX3 endX3];
yCoordinates = [yCoordinates startY3 endY3];

%Right Line
startX4 = originX + width - correction;
endX4   = originX + width - correction;
startY4 = originY;
endY4   = originY + height;
xCoordinates = [xCoordinates startX4 endX4];
yCoordinates = [yCoordinates startY4 endY4];

rectangleCoordinates = [xCoordinates; yCoordinates];
sourceRect = [originX originY max(xCoordinates)+correction max(yCoordinates)+correction];

return;

function [crossCoordinates sourceRect] = makeCrossedLines(gain, crossName)
% function [crossCoordinates sourceRect] = makeCrossedLines(targetGain, trialParameters.target{trial})
% 
% Creates a single matrix of line coordinates suitable for use with Screen('Drawlines') for two crossed lines, one vertical of
% a set length, one horizontal of a set length placed some proportion of the way up the vertical line. This can be used to make 
% stimuli that prime along a continuous dimension without being hard to tell apart.
% 
% The coordinates are such that the lines are being drawn to the very top left corner of the screen in a box that ranges from 
% (0,0) to (endX3R, endYR) in size. This 'sourceRect' should get used to compute an appropriate 'destRect'
%
% INPUTS
% gain      - the parameter from the trialParameters struct that alters the stimulus size
% crossName - a string from the parameter file, eg 'cross20' or 'cross40'; the last two numbers specify the percentage of the way
% up the vertical line that you want the horizontal line
% 
% OUTPUTS
% crossCoordinates - a 2 x 2*nLines matrix of coordinates suitable for use with Screen('DrawLines')
% sourceRect       - a rect vector specifying the size of the brackets for positioning purposes
% 
% Andrew D. Wilson (2009)

%Width and offset make this 40x65 pixels, same kind of dimensions as a double arrow with a gain of 1
defaultWidth  = 40;
defaultHeight = 100;

width  = defaultWidth * gain;
height = defaultHeight * gain;

proportion = str2double(crossName(end-1:end)) / 100; %Converts the 2-digit string at the end of the name (eg '20' in 'cross20')
                                                  %to a number and then a proportion
originX = 0;
originY = 0;

%Vertical Line
startX2 = originX + (width/2);
endX2   = originX + (width/2);
startY2 = originY;
endY2   = originY + height;
xCoordinates = [startX2 endX2];
yCoordinates = [startY2 endY2];

%Horizontal line
startX1 = originX;
endX1   = originX + width;
startY1 = originY + (height-(height*proportion));
endY1   = originY + (height-(height*proportion));
xCoordinates = [xCoordinates startX1 endX1];
yCoordinates = [yCoordinates startY1 endY1];

crossCoordinates = [xCoordinates; yCoordinates];
sourceRect = [originX originY max(xCoordinates) max(yCoordinates)];

return;











