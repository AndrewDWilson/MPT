function masks = makeMask (nMasks, maskLocations, maskParameters)
%function masks = makeMask (nMasks, maskLocations, maskParameters)
% 
% Creates nMask masks by drawing randomised elements to a grid. The
% grid size is specified by the variables xExtentPixels and
% yExtentPixels,  which should be computed to produce a mask of
% approximately 1.5 x 1 degree of visual angle. This will depend on
% your screen's physical size and resolution and the size of the prime
% you want to mask.
%
% Mask specifications:
%     'lines':      creates a mask similar to ERTS, with 1/6 of the
%                   lines vertical, 1/6 horizontal and the remaining
%                   2/3s with random orientation
%     'randomLines: all line orientations randomly generated
%     'squares':    each mask element is a randomly sized square with
%                   random line width. This was made to try and mask
%                   squares and is otherwise not a lot of use, but
%                   I've kept the functionality
%
% ARGUMENTS:
% maskLocations  = array of mask locations specified as trial
%                  parameters
% nMasks         = a 1x2 vector [nTrialsPerBlock nBlocks]
% maskParameters = struct containing parameters from
%                  ExperimentParameters.txt
% 
% RETURN VALUES:
% masks = a struct, containing fields
%     maskCoordinates = a 2xnMask*2 matrix containing the coordinates
%                       of all the lines, set to draw from (0,0) on
%                       the monitor. Compute sourceRect as 
%                       [0 0 max(maskCoordinates{trial}(1,:) max(maskCoordinates{trial}(2,:)]
%                       Use these coordinates as arguments to a
%                       Screen('DrawLines') call.
%     penWidths       = nMasks x nLines matrix with randomly generated
%                       pen widths. Again for use with a call to
%                       Screen('DrawLines')
%     sourceRects     = nTrial x 4 matrix with the coordinates of the
%                       sourceRect for each trial's mask. Use this to
%                       figure out size, etc for positioning
% 
% Andrew D Wilson (2009)

if nargin ~= 3
    error('Wrong number of arguments. Usage: makeMasks = makeMask (nMasks, maskLocations, maskParameters) (makeMasks.m)');
end

rect = Screen('Rect', 0);

nTrials = nMasks(1) * nMasks(2);
maskCoordinates = cell(nTrials, 1);
penWidths       = cell(nTrials, 1);
maskSourceRect  = zeros(nTrials, 4);
maskDestRect    = zeros(nTrials, 4);

%RANDOM MASK GENERATOR
%The mask is generated using a similar procedure to the ERTS code, but without pre-specifying the line
%elements. The mask is given a size in pixels; that rectangular area is subdivided into boxes of a set size 
%(and therefore number). The algorithm starts at the top left box, and moves to a random location within each 
%box. Using this as the starting location, it generates a random length and angle (ie it specifies a line in
%polar coordinates). It converts the result into the Cartesian coordinates of the end of the line, for use 
%as arguments to Screen('DrawLines').
for block = 1:nMasks(2)
    for trialInBlock = 1:nMasks(1)  
        
        trial = (block-1)*nMasks(1) + trialInBlock; %Indexes where in the experiment you are
        
        %Used for 'randomLines'
        xCoordinates = [];
        yCoordinates = [];
        
        %Used for 'squares'; overwritten if randomLines used
        coordinates=[];
        
        %Used for 'lines'; creates a random vector of orientations, 1/3 vertical/horizontal, 2/3s random
        if isequal(maskParameters.maskType{:}, 'lines')
            box = 0;  %Initialise the box counter used in 'lines'
            
            %Generates line orientations in the correct proportion and randomises the order in which they'll get used
            totalBoxes = maskParameters.nBoxes(1) * maskParameters.nBoxes(2);
            vertical = ones(ceil (totalBoxes/6), 1) * ((90/360)*2*pi);
            horizontal = zeros(floor(totalBoxes/6), 1);
            random = ones(totalBoxes-length(vertical)-length(horizontal), 1) .* (2*pi*rand(totalBoxes-length(vertical)-length(horizontal), 1));
            orientations = sortrows([rand(totalBoxes, 1) [vertical;horizontal;random]]);
        end
               
        %Used for all maskTypes
        widths = [];

        %Build matrix of coordinates for mask elements
        for y = 1:maskParameters.nBoxes(2)
            for x = 1:maskParameters.nBoxes(1)                
                switch maskParameters.maskType{:}
                    case {'lines', 'randomLines'}
                        %Select a random location within the current box
                        originX = ceil(maskParameters.boxSize * rand) + (x * maskParameters.boxSize);
                        originY = ceil(maskParameters.boxSize * rand) + (y * maskParameters.boxSize);

                        %Polar coordinate specification of the line to be drawn
                        if isequal(maskParameters.maskType{:}, 'lines')
                            box = box+1;
                            angle = orientations(box,2);
                        elseif isequal(maskParameters.maskType{:}, 'randomLines')
                            angle  = 2*pi*rand;  %Random number between 0 and 2pi
                        end
                        lineLength = maskParameters.meanLineLength + (randn*maskParameters.lineLengthSD);

                        %Convert polar specification to Cartesian coordinates, rounding up to a whole pixel value
                        endX = originX + ceil(lineLength * cos(angle));
                        endY = originY + ceil(lineLength * sin(angle));
                        
                        %Build 2x2*nBoxes matrix of start and end coordinates to send Screen('DrawLines') (plural) + a vector of widths
                        xCoordinates = [xCoordinates originX endX];
                        yCoordinates = [yCoordinates originY endY];
                        widths       = [widths ceil(maskParameters.meanPenWidth + randn*maskParameters.penWidthSD)];
                        
                    case 'squares'
                        %Select a random location within the current box
                        originX = ceil(maskParameters.boxSize * rand) + (x * maskParameters.boxSize);
                        originY = ceil(maskParameters.boxSize * rand) + (y * maskParameters.boxSize);
                        
                        lineLength = ceil(maskParameters.meanLineLength + (randn*maskParameters.lineLengthSD));
                        
                        endX = originX + abs(lineLength);
                        endY = originY + abs(lineLength);
                        
                        %Build 4xnBoxes matrix of rect coordinates to send Screen('FrameRect') + a vector of widths
                        coordinates = [coordinates [originX; originY; endX; endY]];
                        widths      = [widths ceil(maskParameters.meanPenWidth + randn*maskParameters.penWidthSD)];
                end                
            end
        end
               
        switch maskParameters.maskType{:}
            case {'lines', 'randomLines'}
                coordinates = [xCoordinates; yCoordinates];  %Overwrites the empty one set up in case needed by another mask
                maskSize = [max(xCoordinates) max(yCoordinates)];
            case 'squares'
                %Shifts the whole mask over to the left and up a bit. Given that squares are drawn from the top left to bottom right 
                %corners, left alone the mask tends to appear offset down and to the right. This corrects for that by subtracting
                %out min(x) and min(y), then adding in the max(width) so that all lines get drawn properly.
                %Rows 1 and 3 are x coordinates
                coordinates(1,:) = (coordinates(1,:) - min(coordinates(1,:)) + max(widths));
                coordinates(3,:) = (coordinates(3,:) - min(coordinates(1,:)) + max(widths));

                coordinates(2,:) = (coordinates(2,:) - min(coordinates(2,:)) + max(widths));
                coordinates(4,:) = (coordinates(4,:) - min(coordinates(2,:)) + max(widths));
                
                maskSize = [max(coordinates(3,:)) max(coordinates(4,:))] + max(widths);  %The +max(widths) allows for random widths
        end
            
        maskCoordinates{trial} = coordinates; %Cell array, each cell has a mask for one trial
        penWidths{trial} = widths;
        maskSourceRect(trial,:) = [0 0 maskSize];
        
        %Compute the (x,y) location on which the mask should be centred
        switch maskLocations{trialInBlock}
            case 'centre'
                mLocation = [rect(3)/2 rect(4)/2];
            case 'left'
                mLocation = [(rect(3)/2)-maskSize(1) rect(4)/2];
            case 'right'
                mLocation = [(rect(3)/2)+maskSize(1) rect(4)/2];
            case 'up'
                mLocation = [rect(3)/2 (rect(4)/2)-maskSize(2)];
            case 'down'
                mLocation = [rect(3)/2 (rect(4)/2)+maskSize(2)];
            otherwise
                try
                    eval(['mLocation = ', maskLocations{mask}, ';']);
                catch
                    error('Mask location was not read correctly. Check your parameter file (makeMask.m)');
                end
        end
        %Compute where the targets are to go, given the window rect
        newOrigin = mLocation - (maskSize/2);
        maskDestRect(trial, :) = [newOrigin newOrigin(1)+maskSourceRect(trial,3) newOrigin(2)+maskSourceRect(trial,4)];
    end
end

%Assembles everything into a struct for passing around - unpack later
masks = struct;
masks.maskCoordinates = maskCoordinates;
masks.penWidths       = penWidths;
masks.sourceRects     = maskSourceRect;
masks.destRects       = maskDestRect;