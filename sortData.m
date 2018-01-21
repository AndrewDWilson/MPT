function data = sortData(experimentRecord)
% function data = sortData(experimentRecord)
% 
% Takes an experimentRecord file (output from an experiment) with RTs
% in it and computes the median RT for the correct trials, sorted
% by trialType. It also counts the errors and misses and outputs them
% as a proportion of the number of trials in that condition.
% 
% Designed primarily at this point to handle button press data;
% requires testing to handle scored tablet data
% 
% Andrew D Wilson 2009

%Assumes the only reason a file may have an empty cell is because the escape key was pressed. This truncates the file to just the trials
%that occurred before the escape
for row = 1:size(experimentRecord, 1)
    if isempty(experimentRecord(row, 1))
        experimentData = experimentData(1:row, :);
        disp(['WARNING: experimentRecord has been truncated at trial ', int2str(row), '. (sortData.m)']);
    end
end

%Pulls out the trialType information and creates a vector containing a single instance of each trialType
trialTypeColumn = ismember(experimentRecord(1,:), 'Trial Type');
trialTypes = unique(experimentRecord(2:end,trialTypeColumn));  %Removes the first row of labels from consideration
%Identifies the columns containing data to be sorted
scoreColumn = ismember(experimentRecord(1,:), 'Score');
rtColumn    = ismember(experimentRecord(1,:), 'Reaction Time');

%Set up the cell matrix that will get written to an Excel sheet
labels = [{'Trial Types'} {'Median Correct RTs'} {'Error Rate'} {'Miss Rate'}];  %Column labels
data = cell(length(trialTypes), length(labels)); 

%This loop iterates through the trialTypes, computes the median RT for the correct trials and counts errors and misses
for trial = 1:length(trialTypes)
    %Pulls out the data for the current trial type
    currentDataRows = ismember(experimentRecord(:, trialTypeColumn), trialTypes(trial));
    nTrials = sum(currentDataRows);
    
    %Set up places to put data for the trialType(trial)
    tempExperimentRecord = experimentRecord(currentDataRows, :);
    tempRT  = [];
    nErrors = 0;
    nMisses = 0;
    
    %Iterates through the data for trialType(trial)
    for subtrial = 1:size(tempExperimentRecord, 1)
        if tempExperimentRecord{subtrial, scoreColumn} == 1              %Compiles RTs for correct scores
            tempRT = [tempRT; tempExperimentRecord{subtrial, rtColumn}];
        elseif tempExperimentRecord{subtrial, scoreColumn} == 0          %Counts errors
            nErrors = nErrors + 1;  
        elseif isequal(tempExperimentRecord{subtrial, rtColumn}, 'miss') %Counts misses
            nMisses = nMisses + 1;            
        end
    end
    
    %Compiles data
    data(trial, 1) = trialTypes(trial);
    data{trial, 2} = median(tempRT).*1000;
    data{trial, 3} = nErrors/nTrials;
    data{trial, 4} = nMisses/nTrials;
end
data = [labels; data];  %Creates full cell matrix with headers for output to Excel