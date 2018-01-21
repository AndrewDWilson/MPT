function [experimentRecord onsets dataUsed] = analyseKinematics (experimentRecord, subID, displayTime, rawDataX, rawDataY)
% function [experimentRecord onsets dataUsed] = analyseKinematics...
%              (experimentRecord, subID, displayTime, rawDataX, rawDataY)
%
% Filters (via a dual pass filter with Butterworth 'max flat'
% configuration parameters) and differentiates (via dx.m) kinematic
% data from a masked priming study. It then calls kinematicLandmarks.m
% to establish the various features of the resulting speed profile and
% computes RT. The kinematic landmarks plus RT are appended to
% experimentRecord.
%
% NB RTs < 100ms are scored as 'errors'. Negative RTs index trials in
% which there was enough movement before the trial began to trip the
% onset calculation; these kinematics should be eyeballed
% 
% ARGUMENTS
% experimentRecord: cell array storing all the trial information for
%                       the rawDataX and Y files
% subID:            string specifying the subject ID
% displayTime:      time (in s) between primeOnset and targetOnset
%                       that must be subtracted off the movement onset to get RT
% rawDataX:         matrix of X position data (rows = time, columns =
%                       trials)
% rawDataY:         (optional) matrix of Y position data (rows = time,
%                       columns = trials)
%
% RETURN VALUES
% experimentRecord: updated cell array with RT, MT, TPS, DT and PS
%                       appended
% onsets:           The indices of the vector where movement onset was
%                       identified.
% dataUsed:         The data on which everything was computed (either
%                       X or XY data)
% 
% This code also outputs Matlab files called 'subID_kinematics.mat'
% that contains
%         experimentRecord
%         rawDataX
%         filteredX
%         velocityX
%         onsetTimeX
%         xAverage (this only makes sense if the data passed is sorted
%                       by trial type)
%         xSD      (this only makes sense if the data passed is sorted
%                       by trial type)
%         reactionTimes     
%     + (if the data is 2 dimensional)
%         rawDataY
%         filteredY
%         velocityY 
%         onsetTimeY 
%         yAverage (this only makes sense if the data passed is sorted
%                       by trial type)
%         ySD      (this only makes sense if the data passed is sorted
%                       by trial type)
%         rawTangentialVxy 
%         velocityXY 
%         onsetTimeXY
%
% SUBFUNCTIONS
% dx = dx( x, fs ) - differentiation routine

% %Error handling so as not to accidentally overwrite data
saveFileName = [subID, '_kinematics.mat'];
while exist(saveFileName, 'file')
    disp(['File ', saveFileName, ' exists: ']);
    s = input('  enter a new file name, (o)verwrite or (q)uit?: ', 's');
    if isequal(s, 'o') 
        break;
    elseif isequal(s, 'q')
        return;  %This may cause errors because the outputs aren't assigned
    else
        saveFileName = [s, '_kinematics.mat'];
    end
end

%Append some extra columns to experimentRecord
kinematicLabels = {'Reaction Time' 'Score' 'Movement Time' 'Time to Peak Speed' 'Deceleration Time' 'Peak Speed'};
rtIndex = size(experimentRecord, 2) + 1;
for i = 1:length(kinematicLabels)
    experimentRecord(1, end+1) = kinematicLabels(i);
end

%Rescale tablet data to cm if need be and set up X data variables
if mean(rawDataX) > 1000
    rawDataX = rawDataX ./ 1000;
end
filteredX=[]; velocityX=[];
onsetTimeX=[]; onsetTimeY=[]; onsetTimeXY=[];
reactionTimes=[];

%Increment this whenever variables added to the analysis (eg when doing optional Y components)
saveName = ['save ', saveFileName, ' experimentRecord rawDataX filteredX velocityX onsetTimeX reactionTimes'];

%Handles the case where there is 2D data to process
if ~isempty(rawDataY)
    if ~isequal(size(rawDataX), size(rawDataY))
        error('X and Y data matrices must be the same size (analyseKinematics.m)');
    end
    if mean(rawDataY) > 1000 %rescale Y data, if present and required
        rawDataY = rawDataY ./ 1000;
    end
    filteredY=[];         velocityY=[];
    rawTangentialVxy=[];  velocityXY=[];
    %Increment the save name for the .mat file
    saveName = [saveName, ' rawDataY filteredY velocityY onsetTimeY rawTangentialVxy velocityXY onsetTimeXY']; 
end

%********FILTER*********
%Filter parameters
cutOff = 20;
sampleRate = 100;
Wn = cutOff / (sampleRate/2); %Expresses the cut off frequency as a fraction of the Nyquist frequency

%IIR filter design using butterworth 'max flat' configuration
NB = 10; NA = 2;
[B, A] = maxflat(NB, NA, Wn);
%*******END FILTER*******

%******DIFFERENTIATE AND LANDMARK***********
for trial = 1:size(rawDataX, 2)
    %Filter and differentiate X component data
    filtX = filtfilt(B, A, rawDataX(:,trial));
    diffX = dx(filtX, sampleRate);  
    filteredX = [filteredX filtX];
    velocityX = [velocityX diffX'];

    [onset offset TPS PS MT DT] = kinematicLandmarks(diffX);
    if sum([onset offset TPS PS MT DT])==0
        disp(['WARNING: Trial ', int2str(trial), ' contains no data. All landmarks were set to 0 (analyseKinematics.m)']);
    end
    RT = (onset / sampleRate) - displayTime; %Converts onsetTimeB to seconds (frames / (frames/seconds) = seconds)
    onsetTimeX = [onsetTimeX; onset];
    
    if ~isempty(rawDataY)
        %Filter and differentiate Y component data
        filtY = filtfilt(B, A, rawDataY(:,trial));
        diffY = dx(filtY, sampleRate);
        filteredY = [filteredY filtY];
        velocityY = [velocityY diffY'];
        
        [onY] = kinematicLandmarks(diffY);
        onsetTimeY = [onsetTimeY; onY];
        
        %Resultant data
        %Diff the single component velocity data to get dX and dY
        deltaX = diff(diffX);
        deltaY = diff(diffY);
        
        %Vector addition of the x and y component velocity time series
        tanV = zeros(length(deltaX), 1);
        for row = 1:length(tanV)
            tanV(row) = sqrt((deltaX(row)*deltaX(row)) + (deltaY(row)*deltaY(row)));
        end
        rawTangentialVxy = [rawTangentialVxy tanV];
        
        %Filter the resultant tangential speed profile
        filtXY = filtfilt(B, A, tanV);
        velocityXY = [velocityXY filtXY];
        
        [onset offset TPS PS MT DT] = kinematicLandmarks(filtXY);
        RT = (onset / sampleRate) - displayTime; %Replaces the previous computation (line 95) if called
        onsetTimeXY = [onsetTimeXY; onset];
    end
    reactionTimes = [reactionTimes; RT];
    
    %Score kinematics as correct or incorrect
    start = onset;
    stop  = onset + 10;
    responseColumn = ismember(experimentRecord(1,:), 'Correct Response');
    
    %Computes the intitial direction as the sign of the mean of the first 5 data points (50ms@100Hz) after movement onset
    switch experimentRecord{trial+1, responseColumn}
        case 'left'
            if mean(filtX(start:stop)) < 0  %Going left
                score = 1;
            else
                score = 0;
            end
        case 'right'
            if mean(filtX(start:stop)) > 0
                score = 1;
            else
                score = 0;
            end
        otherwise %Set all to 1 if not coped with here, and handle outside Matlab
            score = 1;
            %Add more options if they become available here
    end
    %Trials with noise at the start that triggers a false onset often end up with negative RTs because of onset time - display time
    if RT < 0.1
        score = 0;
        disp(['Trial ', int2str(trial), ' has an RT < 100ms; eyeball the kinematics. (analyseKinematics.m)']);
    end

    %kinematicLabels = {'Reaction Time' 'Score' 'Movement Time' 'Time to Peak Speed' 'Deceleration Time' 'Peak Speed'};
    %Converts times to ms. Note index is trial+1 to handle the header row
    experimentRecord(trial+1, rtIndex)   = {RT * 1000};
    experimentRecord(trial+1, rtIndex+1) = {score};
    experimentRecord(trial+1, rtIndex+2) = {(MT / sampleRate) * 1000}; %MT is already offset - onset
    experimentRecord(trial+1, rtIndex+3) = {((TPS - onset) / sampleRate) * 1000};  %TPS & onset are indices. Output is 'TPS from onset'
    experimentRecord(trial+1, rtIndex+4) = {(DT / sampleRate) * 1000}; %DT is already MT - TPS
    experimentRecord(trial+1, rtIndex+5) = {PS};        
end
xlswrite([subID, '_experimentRecord'], experimentRecord);
%******END DIFFERENTIATE AND LANDMARK***********

if ~isempty(rawDataY)
    dataUsed = velocityXY;
    onsets = onsetTimeXY;
    yAverage = mean(filteredY, 2); ySD = std(filteredY, 0, 2);
    saveName = [saveName, ' yAverage ySD'];
else
    dataUsed = velocityX;
    onsets = onsetTimeX;
end
xAverage = mean(filteredX, 2); xSD = std(filteredX, 0, 2);
saveName = [saveName, ' xAverage xSD'];

eval(saveName);

function dx = dx( x, fs )

% dx = dx( x, fs )
%
% first derivative of signal x, sampled at frequency fs
%   using a finite differences algoritm
%
% x:   signal in 1-dim. array
% fs:  sampling frequency
% dx:  differentiated signal

% Frank Zaal, April 1997
% reference: Winter, D.A. (1990). Biomechanics and motor control of
%   human movement. New York: Wiley.

signalLength = length( x );

dx = ones( 1, signalLength );
dx ( 2 : signalLength - 1) = ...
			0.5 * ( x ( 3 : signalLength ) - x ( 1 : signalLength - 2 ) ) * fs;
dx ( 1 ) = dx ( 2 );
dx ( signalLength ) = dx ( signalLength - 1 );