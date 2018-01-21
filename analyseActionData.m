function analyseActionData(subID, exptType)
% function analyseActionData(subID, exptType)
% 
% This is the primary hub for the analysis of kinematic data from the
% tablet. It handles all the output to Excel of the data sorted by
% condition, as specified in the cell array experimentData, after
% sending the data to analyseKinematics.m
%  
% ARGUMENTS
% subID:    string specifying the subject ID
% exptType: string specifying 'masked' or 'unmasked' (this matters
%               for computing RT as movementOnset -
%               startOfStimuliPresentation
% 
% OUTPUT
% This code saves out a collection of files, all prefixed 'subID_'
%       subID_sortedData:
%             x_Raw             Raw data
%             y_Raw 
%             x_ZerosFixed      Raw data with 0s (indexing an empty
%                                   pkt) replaced with the data point
%                                   from time(pkt=empty)-1
%             y_ZerosFixed
%             correctionCountX  A count of how often this happened
%             correctionCountY
%             onsets
%             reactionTimes     (NB this gets exported to an Excel
%                                   file called
%                                   'subID_ReactionTimes.xls'
%         + the corrected position time series sorted by trialType
%                 Compatible_Left_X    Compatible_Left_Y
%                 Compatible_Right_X   Compatible_Right_Y
%                 Incompatible_Left_X  Incompatible_Left_Y
%                 Incompatible_Right_X Incompatible_Right_Y
%                 Neutral_Left_X       Neutral_Left_Y
%                 Neutral_Right_X      Neutral_Right_Y
% 
% 
% SUB-FUNCTIONS
% xlsheets(sheetnames,varargin) - used to create custom workbooks,
% code from the Mathworks website

%Error handling
if nargin ~=2
    error('Usage: analyseActionData(subID, exptType) (analyseActionData.m)');
end

%Load correct data file, if it exists
if isequal(exptType, 'masked')
    fileName = [subID, '_maskedPrimeTabletData.mat'];
else
    fileName = [subID, '_unmaskedPrimeTabletData.mat'];
end

if exist(fileName, 'file')
    eval(['load ', fileName]);
else
    error(['File ', fileName, ' not found. (analyseActionData.m)']);
end

disp(['Writing out data for ', subID, ': please wait...']);

%*************SET UP MATRICES, ETC*************
warning off MATLAB:xlswrite:AddSheet;
displayTime = mean(timeStamps(:,4) - timeStamps(:,1)); %Computes the average time taken from prime onset to target offset

%Set this up to contain everything you want saved, and add to it if you make any variable names on the fly
saveName = ['save ', subID, '_sortedData experimentRecord trialTypes x_Raw x_ZerosFixed correctionCountX y_Raw y_ZerosFixed correctionCountY '];

%Separate out header and the data from experimentRecord
header = experimentRecord(1,:);
experimentData = experimentRecord(2:end, :);

%Figure out how how the data is arranged.
blockColumn         = ismember(header, 'Block #');
trialInBlockColumn  = ismember(header, '# in Block');

nBlocks         = experimentData{end, blockColumn};
nTrialsPerBlock = experimentData{end, trialInBlockColumn};
nTrials         = nBlocks * nTrialsPerBlock;

trialTypeColumn = ismember(header, 'Trial Type');
trialTypes = unique(experimentData(:,trialTypeColumn));
%*************END SET UP*************

%*************CHECKING THE KINEMATICS PRIOR TO ANALYSIS*************
%Checks to see how much data is in the kinematics. There should be about 30 and 150 data points, respectively (earlyKinematics will be
%shorter if there is no mask, though)
bufferCheck=[]; dataCheck=[];
for check = 1:nTrials
    bufferCheck = [bufferCheck; check length(earlyKinematics{check})];
    dataCheck   = [dataCheck;   check length(lateKinematics{check})];
end
%Check earlyKinematics
if isequal(exptType, 'masked') && min(bufferCheck(:,2)) < 28 || (isequal(exptType, 'unmasked') && min(bufferCheck(:,2)) < 20)
    bufferCheck
    disp('Warning: at least one buffer has fewer data points than the expected 28 (ignore if the experiment is unmasked)');
% 
%     s = input('Continue with analysis? y/n ', 's');
%     if isequal(s, 'n')
%         return
%     end
end
%Check lateKinematics
if min(dataCheck) ~= 150
    dataCheck
    disp('Warning: at least one trial has fewer data points than the expected 150...');
% 
%     s = input('Continue with analysis? y/n ', 's');
%     if isequal(s, 'n')
%         return
%     end
end
%*************END CHECKING THE KINEMATICS PRIOR TO ANALYSIS*************

%*************CORRECTING FOR MISSING DATA*************
%Some trials contain 0s that index an empty packet was called. This is mostly due to 
% a) the first packet in lateKinematics not being filled in time, or 
% b) to the pen being held still or taken off the tablet surface at the end (which makes the packet queue stop filling). 
%Both of this cases are perfectly OK, and the 0 data at time t is replaced (legitimately) by the non-0 data at time t-1.
x_Raw=[]; y_Raw=[];

%Concatenate early and late kinematics
for trial = 1:nTrials
    concatX = [earlyKinematics{trial}(1:min(bufferCheck(:,2)),1); lateKinematics{trial}(:,1)];
    x_Raw   = [x_Raw concatX];
    
    concatY = [earlyKinematics{trial}(1:min(bufferCheck(:,2)),2); lateKinematics{trial}(:,2)];
    y_Raw   = [y_Raw concatY];
end
x_ZerosToFix = ismember(x_Raw, 0);
y_ZerosToFix = ismember(y_Raw, 0);

%Row of the number of data points replaced per trial
correctionCountX = sum(x_ZerosToFix, 1); 
correctionCountY = sum(y_ZerosToFix, 1);

if max(correctionCountX) > 5 || max(correctionCountY) > 5
    corrections = [1:nTrials; correctionCountX; correctionCountY]'
    disp('At least one trial has more than 5 0''s being replaced...');
    
%     s = input('Continue with analysis? y/n ', 's');
%     if isequal(s, 'n')
%         return
%     end
end

%Fix 0s - replaces missing data with the last valid sample. 
x_ZerosFixed=x_Raw;
y_ZerosFixed=y_Raw;
for column = 1:nTrials
    %Fix x data
    for row = 2:length(x_ZerosFixed(:,1))
        %[row column]
        if x_ZerosToFix(row, column)
            x_ZerosFixed(row, column) = x_ZerosFixed(row-1, column);
        end
    end
    %Fix y data
    for row = 2:length(y_ZerosFixed(:,1))
        %[row column]
        if y_ZerosToFix(row, column)
            y_ZerosFixed(row, column) = y_ZerosFixed(row-1, column);
        end
    end
end

%Computes a matrix of corrected data, with the first data point subtracted, and scales the raw tablet pixels into
%cm by dividing by 1000. This '0s' all the data and allows for variation in the precise starting location (all movement is then 
%relative to that point) as well as making the data better for plotting. 
for column = 1:size(x_ZerosFixed, 2)
    x_ZerosFixed(:,column) = (x_ZerosFixed(:,column) - x_ZerosFixed(1,column))/1000;
    y_ZerosFixed(:,column) = (y_ZerosFixed(:,column) - y_ZerosFixed(1,column))/1000;
end
%*************END CORRECTING FOR MISSING DATA*************

%*************SCORING DATA (CORRECT/INCORRECT)*************
%USE THIS MATRIX - SORT IT AND OUTPUT IT TO EXCEL FILES, USING THE SCORES TO SORT BY CORRECT/INCORRECT, ETC

%scoredExperimentData = scoreTabletData(subID, header, experimentData, displayTime, x_ZerosFixed, y_ZerosFixed);

%*************ADDING KINEMATICS TO EXPERIMENTRECORD*************
analyseKinematics (experimentRecord, subID, displayTime, x_ZerosFixed, y_ZerosFixed);
%*************/ADDING KINEMATICS TO EXPERIMENTRECORD*************

%*************OUTPUTTING SORTED DATA**********************
%Takes the _ZerosFixed data and sorts it by trial type, as specified in experimentData(:, trialTypeColumn). This
%then gets output to Matlab files for later analysis, plotting, etc
for trial = 1:length(trialTypes)
    %Identify which columns of x contain data from trialType(trial) and pulls those columns out into a temp matrix
    tempDataIndex = ismember(experimentData(:,trialTypeColumn), trialTypes(trial));
    tempDataX = x_ZerosFixed(:,tempDataIndex);
    tempDataY = y_ZerosFixed(:,tempDataIndex);

    %Saves out these columns to a separate Matlab variable for later use and increments saveName
    eval([trialTypes{trial}, '_X = x_ZerosFixed(:, tempDataIndex);']); %Generates a variable name on the fly
    eval([trialTypes{trial}, '_Y = y_ZerosFixed(:, tempDataIndex);']);
    saveName = [saveName, trialTypes{trial}, '_X ', trialTypes{trial}, '_Y '];    
end

eval(saveName);

disp(['Data output complete to a bunch of files, all prefixed ', subID, '_']);

function xlsheets(sheetnames,varargin)

%XLSHEETS creates or opens existing Excel file and names sheets
%
% xlsheets(sheetnames,filename)
% xlsheets(sheetnames)
%
% xlsheets  : Creates new excel file (or opens it if file exists)
%               and name the sheets as listed in (sheetnames)
%               and saves the workbook as (filename).
%
%       sheetnames:     List of sheet names (cell array).
%       filename:       Name of excel file.
% 
% NOTE: Follow the following rules when naming your sheets:
%       1- Make sure the name you entered does not exceed 31 characters.
%       2- Make sure the name does not contain any of the following characters:  :  \  /  ?  *  [  or  ]
%       3- Make sure you did not leave the name blank.
%       4- Make sure each sheet name is a character string.
%       5- Make sure you do not have two sheets or more with the same name.
%
% Example:
% 
%      sheetnames = {'Mama','Papa','Son','Daughter','Dog'};
%      filename = 'family.xls';          % can be named without '.xls'
%      xlsheets(sheetnames,filename);
%      xlsheets(sheetnames);            % Will leave file open
%

%   Copyright 2004 Fahad Al Mahmood
%   Version: 1.0 $  $Date: 12-Feb-2004
%   Version: 1.5 $  $Date: 16-Feb-2004  (Open exisiting file feature)
%   Version: 2.0 $  $Date: 26-Feb-2004  (Fixed [Group] problem + Making process invisible)
%   Version: 2.1 $  $Date: 27-Feb-2004  (Fixed replacing existing sheets problem)
%   Version: 2.5 $  $Date: 15-Mar-2004  (Fixed filename problem)
%   Version: 3.0 $  $Date: 04-Apr-2004  (Fixed Naming to an existing sheetnames problem + Fixed Opening Multiple Excel Programs Problem)
%   Version: 3.1 $  $Date: 10-Apr-2004  (Added more help about the rules of naming Excel sheets)
%   Version: 3.2 $  $Date: 10-Apr-2004  (Supporting Full or Partial Path)

    
% Making sure the names of the sheets are according to Excel rules.
for n=1:length(sheetnames)
%  (1) Making sure each sheetname entered does not exceed 31 characters.    
    if length(sheetnames{n})>31
        error(['sheet (' sheetnames{n} ') exceeds 31 characters! (see xlsheets help)'])
    end
%  (2) Making sure each sheetname does not contain any illegal character.
    if any(ismember([':','\','/','?','*'],sheetnames{n})) | ismember('[',sheetnames{n}(1))
        error(['sheet (' sheetnames{n} ') contains an illegal character! (see xlsheets help)'])
    end
%  (3) Making sure each sheetname is not blank.
    if isempty(sheetnames{n})
        error(['sheet ' int2str(n) ' is empty! (see xlsheets help)'])
    end
%  (4) Making sure each sheetname is a character string.
    if ~ischar(sheetnames{n})
        error(['sheet (' int2str(n) ') is NOT a character string! (see xlsheets help)'])
    end
end

%  (5) Making sure two or more sheets do not have the same name.
if length(sheetnames)>length(unique(sheetnames))
    error('Two or more sheets have the same name!')

end

% Opening Excel
target_num_sheets = length(sheetnames);
Excel = actxserver('Excel.Application');
if nargin==2
    filename = varargin{1};
    [fpath,fname,fext] = fileparts(filename);
    if isempty(fpath)
        out_path = pwd;
    elseif fpath(1)=='.'
        out_path = [pwd filesep fpath];
    else
        out_path = fpath;
    end
    filename = [out_path filesep fname fext];
    if ~exist(filename,'file')
        % The following case if file does not exist (Creating New Workbook)
        Workbook = invoke(Excel.Workbooks,'Add');
        % getting the number of sheets in new workbook      
        numsheets = get(Excel,'SheetsInNewWorkbook');    
        new=1;
    else
        % The following case if file does exist (Opening Workbook)
        Workbook = invoke(Excel.Workbooks, 'open', filename);
        % getting the number of sheets in new workbook  
        workSheets = Excel.sheets;
        for i = 1:workSheets.Count
            sheet = get(workSheets,'item',i);
            description{i} = sheet.Name;
            if ~isempty(sheet.UsedRange.value)
                indexes(i) = true;
            else
                indexes(i) = false;
            end
        end
        descr = description(indexes);
        numsheets = length(descr);
        new=0;
    end
    leave_file_open = 0;
else
    % The following case if file does not exist (Creating New Workbook)
    Workbook = invoke(Excel.Workbooks,'Add');
    % getting the number of sheets in new workbook      
    numsheets = get(Excel,'SheetsInNewWorkbook');    
    new=1;
    leave_file_open = 1;
end

% making Excel visible only if workbook name is not specified or new workbook is created. 
if nargin==1
    set(Excel,'Visible', 1);
end

if target_num_sheets > numsheets
    
    % Activating Last sheet of new (filename)
    Sheets = Excel.ActiveWorkBook.Sheets;
    sheet = get(Sheets, 'Item', numsheets);
    invoke(sheet, 'Activate');
    
    % Adding sheets to match the number of (sheetnames) specified.
    for i=1:target_num_sheets-numsheets
        invoke(Excel.Sheets,'Add');
    end
    
elseif target_num_sheets < numsheets
    
    % Deleting sheets to match the number of (sheetnames) specified.
    for i=numsheets-target_num_sheets:-1:1
        sheet = get(Excel.ActiveWorkBook.Sheets, 'Item', i);
        invoke(sheet, 'Delete');
    end
end

% Renaming sheets to temporary names
for i=1:target_num_sheets
    Sheets = Excel.Worksheets;
    sheet = get(Sheets, 'Item', i);
    invoke(sheet, 'Activate');
    Activesheet = Excel.Activesheet;
    temp_name = ['temp_' int2str(i)];
    set(Activesheet,'Name',temp_name);
end

% Renaming sheets to the designated names
for i=1:target_num_sheets
    Sheets = Excel.Worksheets;
    sheet = get(Sheets, 'Item', i);
    invoke(sheet, 'Activate');
    Activesheet = Excel.Activesheet;
    set(Activesheet,'Name',char(sheetnames(i)));
end

if nargin>1
    if new invoke(Workbook, 'SaveAs', filename);
    else invoke(Workbook, 'Save'); end
end

if ~leave_file_open invoke(Excel, 'Quit'); end
delete(Excel);