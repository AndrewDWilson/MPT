function [experimentParameters maskParameters splashParameters trialParameters] = readExperimentParameters(fileName)
% function [experimentParameters maskParameters trialParameters] =
%       readExperimentParameters(fileName)
% 
% Reads in 'fileName', a tab delimited version of
% ExperimentParameters.xls which has been edited for the current
% experiment. The file format must not be changed - this code requires
% that everything is where the template puts it.
% 
% ARGUMENTS 
% fileName: a string specifying the full, exact name of the parameter
%           file (eg 'ExperimentParameters.txt')
% 
% RETURN VALUES 
% Three separate structs, with fields named for the headings in the
% .xls file: 
% experimentParameters - 
%     subjectID                   = empty, to be filled by
%                                   primingMain.m. 
%     fileName                    = stores the file name of the
%                                   parameter file that generated this
%                                   experiment
%     ResponseDevice              = a string specifying 'button' or
%                                   'tablet' 
%     Masking                     = a string specifying 'masked' or
%                                   'unmasked' 
%     MaskTargetISI               = a string specifying 'yes' or 'no'
%                                   about the mask/target ISI 
%     Randomisation               = a string specifying 'yes' or 'no'
%                                   about whether to randomise trial
%                                   presentation 
%     TabletStartLocation         = a location code for the
%                                   'home'location in tablet
%                                   experiments 
%     nBlocks                     = a number specifying the number of
%                                   blocks
%     nRepetitionsPerTrialType    = a number specifying how many of
%                                   each unique trial type each block
%                                   should have. 
%     nTrials eventually equals nBlocks * nRepetitionsPerTrialType *
%                       nUniqueTrials
%
% maskParameters (see the help for 'makeMask.m for more details)
%     maskType       = a string specifying the type of mask ('lines',
%                      'squares') 
%     xExtentPixels  = a number specifying the size of the mask, in
%                      pixels, along the x axis 
%     yExtentPixels	 = a number specifying the size of the mask, in
%                      pixels, along the x axis
%     boxSize        = a number specifying how big each sub-box should
%                      be within the mask. 
%     meanPenWidth	 = the average width of the lines 
%     penWidthSD     = the SD of the width of the lines
%     meanLineLength = the average line length 
%     lineLengthSD   = the line length SD
% 
% splashParameters - details for the splash screen that displays
% between blocks
%     imperativeStimulus = a string specifying 'prime' or 'target';
%                          switches which gets demoed 
%     stimulusTypes      = a string specifying all the different
%                          imperative stimuli to be displayed
%     orientations       = a number specifying the orientation of that
%                          stimuli
%     responses          = a string specifying the response to be
%                          displayed with that stimuli 
%     locations          = a string specifying where to draw that
%                          example (currently requires exact
%                          coordinates, ie [x,y])
% 
% trialParameters - note that the .txt file should contain one row for
% each unique trial type. The resulting struct from here reads that in
% nRepetitionsPerTrialType times
%     UniqueTrialNumbers = a number identifying from which trial in
%                          fileName a given trial was created 
%     TrialName          = a column of strings for the trials 
%     TrialType          = a column of strings specifying the
%                          prime/target compatibility 
%     Feedback           = a column of 0s or 1s to switch feedback on
%                          or off 
%     Prime              = a string specifying 'arrow', 'doubleArrow',
%                          'brackets' (ie prime type) 
%     PrimeDuration      = a number specifying the number of frames
%                          the prime should be presented 
%     PrimeLocation      = a string specifying 'up', 'down', 'left',
%                          'right' or 'centre' (position relative to
%                          the mask)
%     PrimeSize          = a gain on size. makeStimuli.m multiplies
%                          the default sizes by this to alter the size
%     PrimeOrientation   = a number, in degrees, specifying the
%                          orientation. 0 = default way up, increasing
%                          clockwise
%     MaskDuration       = a number specifying the number of frames,
%                          the mask (if used) should be presented 
%     MaskLocation       = a string specifying 'up', 'down', 'left',
%                          'right' or 'centre' (position relative to
%                          the screen centre)
%     BlankDuration      = a number specifying the number of frames
%                          for which the blank after the mask should
%                          be presented 
%     Target, TargetDuration, TargetLocation, TargetSize, TargetOrientation
%                        = matching parameters for the target
%     CorrectResponse    = a string specifying 'left', 'right' - used
%                          to score the trial
% 
% Andrew D. Wilson, 2009

try
    %Format strings
    formatStringExpt   = ['%s' '%s' '%s' '%s' '%q' '%n' '%n' '%s' '%n'];
    formatStringMask   = ['%n' '%n' '%n' '%n' '%n' '%n' '%n'];
    formatStringSplash = ['%s' '%s' '%n' '%s' '%q'];
    formatStringTrial  = ['%n' '%s' '%s' '%n' '%s' '%n' '%q' '%n' '%n' '%n' '%q' '%n' '%s' '%n' '%q' '%n' '%n' '%s'];

    %Read in file contents as three separate cell arrays of cell arrays
    fid = fopen(fileName, 'r');
    experimentStuff = textscan(fid, formatStringExpt, 1, 'headerlines', 2);
    maskStuff = textscan(fid, formatStringMask, 1, 'headerlines', 3);
    
    tempSplashStuff = textscan(fid, formatStringSplash, 1, 'headerlines', 3);
    splashStuff = [];
    while 1
        if ~isequal(tempSplashStuff{1}, {'EndSplashScreen'})
            splashStuff = [splashStuff; tempSplashStuff];
            tempSplashStuff = textscan(fid, formatStringSplash, 1);
        else
            break
        end
    end
    trialStuff = textscan(fid, formatStringTrial, 'headerlines', 3);
    %End reading in parameters
    fclose(fid);
    
    %Error checking on the reading
    for i = 1:length(experimentStuff)
        if isempty(experimentStuff{i})
            experimentStuff
            error('Experiment parameters did not read in correctly (readExperimentParameters.m)')
        end
    end
    for i = 1:length(maskStuff)
        if isempty(maskStuff{i})
            maskStuff
            error('Mask parameters did not read in correctly (readExperimentParameters.m)')
        end
    end
    for i = 1:length(splashStuff)
        if isempty(splashStuff{i})
            splashStuff
            error('Splash screen parameters did not read in correctly (readExperimentParameters.m)')
        end
    end    
    for i = 1:length(trialStuff)
        if isempty(trialStuff{i})
            trialStuff{i-1}
            error('Trial parameters did not read in correctly (readExperimentParameters.m)')
        end
    end
catch
    readError=lasterror;
    %Send the error information to the command window
    message = readError(1).message
    identifier = readError(1).identifier
    stack = readError(1).stack
    
    file = stack.file
    name = stack.name
    line = stack.line

    disp('Something is wrong with the format of your experiment parameter file. Please carefully check the rules');
    disp(' in the manual and make sure everything is in the right place (readExperimentParameters.m).');
    return;
end


%****************Experiment Parameters*****************
experimentParameters = struct('subID', []);  %Sets this field to exist and be listed first in the struct. Gets filled in primingMain.m

%Reference all these string fields using cell notation as they are stored in the struct as cells
experimentParameters.fileName       = fileName;  %Useful to have a record of what file generated this data
experimentParameters.ResponseDevice = experimentStuff{1};
experimentParameters.Masking        = experimentStuff{2};
experimentParameters.MaskTargetISI  = experimentStuff{3};
experimentParameters.Randomisation  = experimentStuff{4};

tablet = [45719 30379]; %A0 Wacom Intuos2 tablet is 45719 x 30379 pixels in size. Set this up locally with SetUp.m
boxSize = 500;  %Half size of the start box, in tablet pixels.
switch experimentStuff{5}{1}
    case {'centre'}
        experimentParameters.TabletStartLocation = floor(tablet/2);
    case {'left'}
        experimentParameters.TabletStartLocation = floor([0+boxSize tablet(2)/2]);
    case {'right'}
        experimentParameters.TabletStartLocation = floor([tablet(1)-boxSize tablet(2)/2]);
    case {'topCentre'}
        experimentParameters.TabletStartLocation = floor([tablet/2 0]);
    case {'bottomCentre'}
        experimentParameters.TabletStartLocation = floor([tablet(1)/2 tablet(2)]);
    case {'topLeft'}
        experimentParameters.TabletStartLocation = floor([0+boxSize 0]);
    case {'bottomLeft'}
        experimentParameters.TabletStartLocation = floor([0+boxSize tablet(2)]);
    case {'topRight'}
        experimentParameters.TabletStartLocation = floor([tablet(1)-boxSize 0]);
    case {'bottomRight'}
        experimentParameters.TabletStartLocation = floor([tablet(1)-boxSize tablet(2)]);
    otherwise
        try
            eval(['experimentParameters.TabletStartLocation = ', experimentStuff{5}{1}, ';']); %Allows you to specify a weird place directly
        catch
            error('Tablet start location is not a number; check the parameter file and the manual for rules (readExperimentParameters.m)');
        end
end

experimentParameters.nBlocks                  = experimentStuff{6};
experimentParameters.nRepetitionsPerTrialType = experimentStuff{7};
experimentParameters.TrialLength              = experimentStuff{8};
experimentParameters.ResponseDuration         = experimentStuff{9} / 1000;
%****************/Experiment Parameters*****************

%****************Mask Parameters*****************
maskParameters = struct; 

maskParameters.maskType = experimentStuff{2};

maskParameters.xExtentPixels = maskStuff{1};
maskParameters.yExtentPixels = maskStuff{2};

%Vary these to change mask density - set using a function that computes the values given screen resolution?
maskParameters.boxSize = maskStuff{3}; %10x10 pixels
%NB nBoxes ends up with integers in it (rounded up) 
maskParameters.nBoxes  = ceil([maskParameters.xExtentPixels/maskParameters.boxSize maskParameters.yExtentPixels/maskParameters.boxSize]);

maskParameters.meanPenWidth   = maskStuff{4};    maskParameters.penWidthSD   = maskStuff{5};
maskParameters.meanLineLength = maskStuff{6};    maskParameters.lineLengthSD = maskStuff{7};       %Units = pixels
%*************/Mask Parameters*****************

%*************Splash Screen Parameters*****************
splashParameters = struct;

%NB the rather unusual (:,x) format is because of the way this data gets read in to handle variable length - do not change 
splashParameters.imperativeStimulus = splashStuff(:,1);
splashParameters.stimulusTypes      = splashStuff(:,2);
splashParameters.orientations       = splashStuff(:,3);
splashParameters.responses          = splashStuff(:,4);
splashParameters.locations          = splashStuff(:,5);
%*************/Splash Screen Parameters*****************

% %****************Trial Parameters*****************
%This reads the trial parameters into the struct so that the final result stores the parameters for one full block. Sample this struct
%without replacement experimentParameters.nBlock times in order to make a full experiment
hz = Screen('NominalFrameRate', 0); %Reports the nominal frame rate as reported by the graphics card; should be a rounded integer
frameLength = (1/hz)*1000; %Used to convert nFrames into a primeDuration

trialParameters = struct('uniqueTrialNumbers', [], 'trialName', [], 'trialType', [], 'feedback', [],...
    'prime', [], 'primeDuration', [], 'primeLocation', [], 'primeSize', [], 'primeOrientation', [],...
    'maskDuration', [], 'maskLocation', [],...
    'blankDuration', [],...
    'target', [], 'targetDuration', [], 'targetLocation', [], 'targetSize', [], 'targetOrientation', [],...
    'correctResponse', [],...
    'trialInBlock', []);

nTrialsPerBlock = experimentParameters.nRepetitionsPerTrialType * length(trialStuff{1});
trialParameters.trialInBlock = [trialParameters.trialInBlock; [1:nTrialsPerBlock]'];

%Final size in each field is [nRepetitionsPerTrialType * nUniqueTrials, 1]
for i = 1:experimentParameters.nRepetitionsPerTrialType
    trialParameters.uniqueTrialNumbers = [trialParameters.uniqueTrialNumbers; trialStuff{1}];
    trialParameters.trialName          = [trialParameters.trialName; trialStuff{2}];
    trialParameters.trialType          = [trialParameters.trialType; trialStuff{3}];
    trialParameters.feedback           = [trialParameters.feedback; trialStuff{4}];

    trialParameters.prime            = [trialParameters.prime; trialStuff{5}];
    trialParameters.primeDuration    = [trialParameters.primeDuration; trialStuff{6}*frameLength];
    trialParameters.primeLocation    = [trialParameters.primeLocation; trialStuff{7}];
    trialParameters.primeSize        = [trialParameters.primeSize; trialStuff{8}];
    trialParameters.primeOrientation = [trialParameters.primeOrientation; trialStuff{9}];

    trialParameters.maskDuration  = [trialParameters.maskDuration; trialStuff{10}*frameLength];
    trialParameters.maskLocation  = [trialParameters.maskLocation; trialStuff{11}];
    
    trialParameters.blankDuration = [trialParameters.blankDuration; trialStuff{12}*frameLength];

    trialParameters.target            = [trialParameters.target; trialStuff{13}];
    trialParameters.targetDuration    = [trialParameters.targetDuration; trialStuff{14}*frameLength];
    trialParameters.targetLocation    = [trialParameters.targetLocation; trialStuff{15}];
    trialParameters.targetSize        = [trialParameters.targetSize; trialStuff{16}];
    trialParameters.targetOrientation = [trialParameters.targetOrientation; trialStuff{17}];

    trialParameters.correctResponse = [trialParameters.correctResponse; trialStuff{18}];
end
% %****************/Trial Parameters*****************
