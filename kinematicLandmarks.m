function [onsetTimeB offsetTimeB timeToPeakSpeed peakSpeed movementTime decelerationTime] =...
    kinematicLandmarks(data, tolerancePercent)
% function [onsetTimeB offsetTimeB timeToPeakSpeed peakSpeed movementTime decelerationTime] =...
%     kinematicLandmarks(data, tolerancePercent)
% 
% Computes the vector indices in a position time series that the
% various key landmarks occur. It's up to the user to use these vector
% indices to figure out what the actual time is - this code is
% indifferent to sampling rate. This works happily on single peak
% speed data from a discrete movement (although in theory you could
% chain together a series of calls to this code, chopping a single 
% time series from a series of discrete movements according to the
% computed movement on- and offsets).
% 
% Implements Algorithms A & B from
% Teasdale N, Bard C, Fleury M, Young DE, Proteau L. (1993)
%   Determining movement onsets from temporal series. Journal of Motor
%   Behavior, 25(2):97-106
% to estimate movement onset and offset
% 
% ARGUMENTS
% data: a 1-dimensional vector of speed time series data (ie the
%       result of filtering and differentiating position data) This
%       function is currently best suited to discrete movements with a
%       single peak speed. If you have noisy (multiple speed peaks)
%       data you should plot the output to double check what comes out
% tolerancePercent: (optional) percentage (eg .01 for 1%) parameter
%       for the Teasdale et al algorithm. It defaults to 5% - this
%       effectively means that any signal <5% of the peak speed gets
%       filtered, which is ok. When first running an experiment it's
%       probably a good idea to tweak the tolerancePercent to see what
%       gets cut out, though.
% 
% OUPUT
% onsetTimeB:       Data point in vector that satisfies the criteria
%                       for movement onset, as per Teasdale et al
%                       (Algorithm B)
% offsetTimeB:      Computed the same way as onsetB except starting
%                       from the end and working backwards
% peakSpeed:        max(abs(data)) so it doesn't worry about direction
%                       data (ie the sign). Use the indices to look up
%                       the data yourself
% timeToPeakSpeed:  Data point at which PS occurs
% movementTime:     offsetTimeB - onsetTimeB
% decelerationTime: movementTime - timeToPeakSpeed
% 
% Andrew D Wilson 2008

%Error handling
if min(size(data)) ~= 1
    error('Data must be a one dimensional row or column vector (kinematicLandmarks.m)');
end
%Catches empty trials, ie where no data was recorded, and sets the return values to 0 before returning. This will index a bad trial
if sum(data)==0
    onsetTimeB       = 0;
    offsetTimeB      = 0;
    timeToPeakSpeed  = 0;
    peakSpeed        = 0;
    movementTime     = 0;
    decelerationTime = 0;
    
    return
end
%Sets optional argument to default if not specified
if nargin<2
    tolerancePercent = .05; %5%
end

%PEAK SPEED: finds it then scans the data and returns the index at which PS occurs
peakSpeed = max(abs(data)); %Assumes a single meaningful peak
timeToPeakSpeed = 1;
while ~isequal(abs(data(timeToPeakSpeed)), peakSpeed)
    timeToPeakSpeed = timeToPeakSpeed + 1;
end

%*****************************************************Algorithm A*****************************************************
tolerance = tolerancePercent*peakSpeed;

%************ONSET************
timeOn = 1;
while isequal(data(timeOn), data(timeOn+1))
    timeOn = timeOn+1;
end

%First time that the speed is different from what it is at t=1 or t=end
%ONSET
firstMoveTimeOn = timeOn + 1;
firstSpeedOn    = data(firstMoveTimeOn);
timeOn          = firstMoveTimeOn;
while abs(data(timeOn) - firstSpeedOn) < tolerance && timeOn <= length(data)
    timeOn = timeOn+1;
end
secondSpeedOn = data(timeOn);  %First speed after the first change detected that is higher than the tolerance

toleranceOn = tolerancePercent*secondSpeedOn;
timeOn = timeOn - 1;

while abs(data(timeOn)-secondSpeedOn) < toleranceOn && timeOn >= firstMoveTimeOn
    timeOn = timeOn-1;
end
%onsetAmpA  = data(timeOn);
onsetTimeA = timeOn;
%************ONSET************


%************OFFSET************
timeOff = length(data);
while isequal(data(timeOff), data(timeOff-1))
    timeOff = timeOff-1;
end

firstMoveTimeOff = timeOff - 1;
firstSpeedOff    = data(firstMoveTimeOff);
timeOff          = firstMoveTimeOff;
while abs(data(timeOff) - firstSpeedOff) < tolerance
    timeOff = timeOff-1;
end
secondSpeedOff = data(timeOff);  %First speed after the last change detected that is higher than the tolerance

toleranceOff = tolerancePercent*secondSpeedOff;
timeOff = timeOff-1;

while abs(data(timeOff)-secondSpeedOn) < toleranceOff && timeOff >= firstMoveTimeOn
    timeOff = timeOff-1;
end
%offsetAmpA  = data(timeOff);
offsetTimeA = timeOff;
%************OFFSET************

%*****************************************************Algorithm B*****************************************************
%************ONSET************
meanAmplitudeOn = mean(data(firstMoveTimeOn:onsetTimeA)); %Mean amplitude within range of first change and computed onset
stdDevOn        = std (data(firstMoveTimeOn:onsetTimeA));

timeOn = onsetTimeA;
while data(timeOn) >= (meanAmplitudeOn+stdDevOn) && timeOn >= firstMoveTimeOn
    timeOn = timeOn - 1;
end

onsetAmpB = min(data(timeOn:onsetTimeA));
tempTime=onsetTimeA;
while data(tempTime-1) < data(tempTime) && tempTime >= timeOn
    tempTime=tempTime-1;
    
    if tempTime==1
%         figure; plot(data)
        break
    end
end
onsetTimeB = tempTime;
%************ONSET************

%************OFFSET************
meanAmplitudeOff = mean(data(offsetTimeA:firstMoveTimeOff)); %Mean amplitude within range of first change and computed onset
stdDevOff        = std (data(offsetTimeA:firstMoveTimeOff));

timeOff = offsetTimeA;
while data(timeOff) >= (meanAmplitudeOff+stdDevOff) && timeOff >= firstMoveTimeOff
    timeOff = timeOff + 1;
end

offsetAmpB = min(data(offsetTimeA:timeOff));
tempTime=offsetTimeA;
while data(tempTime+1) < data(tempTime) && tempTime <= timeOff
    tempTime=tempTime+1;
end
offsetTimeB = tempTime;
%************OFFSET************

movementTime     = offsetTimeB - onsetTimeB;
decelerationTime = offsetTimeB - timeToPeakSpeed;
