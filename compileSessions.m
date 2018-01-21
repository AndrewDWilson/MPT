function compileSessions(subID1, subID2)
% function compileSessions(subID1, subID2)
% 
% Compiles together two parts of data from a single subject; copes with
% the times when the tablet experiments crash out. Data is saved out to
% a file called 'subID1_maskedPrimeTabletDataREMOVETHIS.mat'; good
% practice is to move the original files into a separate folder (ie do
% not throw them away) and to then remove the text that says
% REMOVETHIS. If for any reason it's not tablet data, rename the file
% to match the appropriate convention. 
% 
% ARGUMENTS
% subID1: the subID from the first run, usually subXX
% subID2: the subID from the second run, usually subXXa
% 
% Andrew D Wilson 2009

%%%%%%SUBID 1%%%%%
eval(['load ', subID1, '_maskedPrimeTabletData.mat']);

%Figures out how many blocks there should have been and how many trials
nBlocks         = experimentParameters.nBlocks;
nTrialsPerBlock = length(trialParameters.uniqueTrialNumbers);

%Figures out how many blocks were actually completed. The way the tablet crashes out, this is generally a set of full blocks (ie it crashes on trial 1
%of the next block)
nBlocksCompleted = floor(size(timeStamps,1) / nTrialsPerBlock);

nTrialsCompleted = nTrialsPerBlock*nBlocksCompleted;
nAdditionalBlocks = experimentParameters.nBlocks - nBlocksCompleted;

%Takes the data and puts in in temporary variables
temp_earlyKinematics        = earlyKinematics(1:nTrialsCompleted,:);
temp_lateKinematics         = lateKinematics(1:nTrialsCompleted,:);
temp_timeStamps             = timeStamps(1:nTrialsCompleted,:);
temp_experimentRecord       = experimentRecord(1:nTrialsCompleted,:);
temp_experimentParameters   = experimentParameters;

%%%%%%SUBID 2%%%%%
eval(['load ', subID2, '_maskedPrimeTabletData.mat']);

%Collates data
earlyKinematics         = [temp_earlyKinematics; earlyKinematics];
lateKinematics          = [temp_lateKinematics; lateKinematics];
timeStamps              = [temp_timeStamps; timeStamps];
experimentParameters    = temp_experimentParameters;

experimentRecord = [experimentRecord(1,:); temp_experimentRecord; experimentRecord(2:nAdditionalBlocks*nTrialsPerBlock+1, :)];
for row = 2:size(experimentRecord, 1)
    if experimentRecord{row, 3} > nBlocksCompleted
        experimentRecord{row, 3} = experimentRecord{row, 3} + nBlocksCompleted;
    end
end

%Saves the data out.
eval(['save ', subID1, '_maskedPrimeTabletDataREMOVETHIS ',...
    'dataHeader earlyKinematics experimentParameters experimentRecord lateKinematics timeStamps trialParameters;']);




