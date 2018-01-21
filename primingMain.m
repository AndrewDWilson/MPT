function primingMain(parameterFileName, subID)
% function primingMain(parameterFileName, subID)
%
% The primary interface between an experimenter and an experiment.
% Handles reading in the parameters from the text file
% 'parameterFileName' and calls the correct code to run the specified
% experiment.
% 
% ARGUMENTS
% parameterFileName: a string specifying the full (i.e including the
%                    .txt suffix) file name of the tab-delimited
%                    parameter file. 
% subID:             a string specifying the subject ID code (eg
%                    'sub01') that will be used to save data out, etc
% 
% Andrew D Wilson 2008

%Error handling
if nargin ~= 2
    error('Usage: primingMain(parameterFileName, subID). (primingMain.m)');
end
%Screen('Preference', 'SkipSyncTests', 1);

%Read in parameters and assign the fields of the various structs
[experimentParameters maskParameters splashParameters trialParameters] = readExperimentParameters(parameterFileName);
experimentParameters.subID = subID;
%Check here to see if subID is an ok code
if ~isequal(subID, 'practice')
    if exist([subID, '.xls'], 'file')
        error('Warning: data for specified subID already exists. Move/delete that file or rename current participant. (primingMain.m)')
    end
end

%All force experiments need to know the Maximum Voluntary Contraction
if isequal(experimentParameters.ResponseDevice, {'force'})
    %Initialise the force transducer
    [handle, errmsg] = IOPort('OpenSerialPort', 'COM4', 'BaudRate=57600 Terminator=CR');
    %Error handling
    if ~isempty(errmsg)
        disp(errmsg);
        IOPort('CloseAll');
        error('primingMain.m quit with the above error when trying to open the force transducer (primingMain.m)');
    end

    %Set to filter 1 (100Hz) then waits and reads out the 'CR' response to clear the queue
    IOPort('Write', handle, 'F1'); 
    WaitSecs(.05);
    IOPort('Read', handle);

    %Tares (zeros) reading then reads off the 'CR' response to clean out the queue. The wait is to allow the queue to fill
    disp('Remove all weights from the transducer then press the space bar to zero it...');
    pause

    IOPort('Write', handle, 'T');
    WaitSecs(.05);
    IOPort('Read', handle);

    disp('Transducer zeroed successfully.');
%     IOPort('CloseAll');
%     experimentParameters.MVC = 45909;

    %Maximum voluntary contraction setup
    maxVC=zeros(1,3);
        
    repeat = 'n';
    while isequal(repeat, 'n')
        disp('We will now record you pressing as hard as you can three times.');
        disp('Get set to press as hard as you can when told, then press the space bar and do so'); 
        pause

        for maxTrial = 1:3
            maxVCData=[]; %Empty this - it's only a temporary recording of force data
            disp(['Recording Trial ', int2str(maxTrial), '...']);

            %Collect data for 3s that will include the pulse produced by the person to their maximum
            stop=GetSecs+3;
            while GetSecs<stop
                IOPort('Write', handle, 'M');
                [data] = IOPort('Read', handle, 1, 8);

                maxVCData = [maxVCData; str2num(char(data))];
            end
            maxVC(maxTrial) = max(maxVCData);

            disp(['Trial ', int2str(maxTrial), ' complete.']);
            if maxTrial<3 %Run up to three trials
                disp('Get ready for the next trial, and press the space bar to continue');
                pause
            else  %Present the recorded estimates of MVC and asks if they are useful
                disp('maxTrial estimates:');
                disp(maxVC');
                disp(['Should I use the average, ', int2str(mean(maxVC)), '?']);
                repeat = input('Enter (y)es, (n)o, or (q)uit: ', 's');
                
                if isequal(repeat, 'q')  %Quits all the way back to the command window
                    IOPort('CloseAll');
                    return
                end
            end
        end
    end
    IOPort('CloseAll');
    experimentParameters.MVC = mean(maxVC);
end

%Calls the correct experiment file and sends it the required parameters
%%%MASKED%%%
if ~isequal(experimentParameters.Masking, {'unmasked'})
    
    if isequal(experimentParameters.ResponseDevice, {'button'})
        maskedPrimeMain(experimentParameters, maskParameters, splashParameters, trialParameters);
    elseif isequal(experimentParameters.ResponseDevice, {'tablet'})
        maskedPrimeTabletMain(experimentParameters, maskParameters, splashParameters, trialParameters);
    elseif isequal(experimentParameters.ResponseDevice, {'force'})
        maskedPrimeForceMain(experimentParameters, maskParameters, splashParameters, trialParameters);
    else
        error('ResponseDevice can be ''button'', ''tablet'' or ''force'' - check your parameter file (primingMain.m)');
    end
    
%%%UNMASKED%%%
elseif isequal(experimentParameters.Masking, {'unmasked'})
    
    if isequal(experimentParameters.ResponseDevice, {'button'})
        unmaskedPrimeMain(experimentParameters, splashParameters, trialParameters);
    elseif isequal(experimentParameters.ResponseDevice, {'tablet'})
        unmaskedPrimeTabletMain(experimentParameters, splashParameters, trialParameters);
    elseif isequal(experimentParameters.ResponseDevice, {'force'})
        unmaskedPrimeForceMain(experimentParameters, splashParameters, trialParameters);
    else
        error('ResponseDevice can be ''button'', ''tablet'' or ''force'' - check your parameter file (primingMain.m)');
    end
else
    error('Masking can be ''masked'' or ''unmasked'' - check your parameter file (primingMain.m)');
end


