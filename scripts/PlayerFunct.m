function PlayerFunct(port2boss, port2acq, playerName, trainDuration, windowDuration, testOverlap)
% Description of Boss Script

% Adds the parent directory to the Matlab Path
folder = [pwd '\'];
cd('..\');
addpath(genpath(pwd));
cd(folder);

%Begining

% Find the player number
if port2boss == 33001
    playerNb = 1;
elseif port2boss == 33002
    playerNb = 2;
else
    disp('Player number could not be identified.');
    playerNb = 0;
end

disp(['Player ',num2str(playerNb)]);
disp(playerName);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%              Connection with Boss             %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Trying to connect to Boss...')
playerClient = tcpip('0.0.0.0', port2boss, 'NetworkRole', 'client');
playerClient.Timeout = 10; %in seconds
fopen(playerClient);
disp('Connected to Boss !')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%              Connection with MuLES            %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Trying to connect to MuLES...')
mulesClient = tcpip('0.0.0.0', port2acq, 'NetworkRole', 'client');
mulesClient.InputBufferSize = 5000000;
mulesClient.Timeout = 10; %in seconds

% Wait for the connection with MuLES 
waitingMules = true;
while waitingMules
    waitingMules = false;
    try
        fopen(mulesClient);
    catch
        waitingMules = true;
    end
end

disp('Connected to MuLES !')

% Audio cue, Player has correctly started
audiofilename = 'beep.mp3';
[y, sampF] = audioread(audiofilename);
sound(y,sampF);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%              Obtain EEG device info           %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[device, fs, tags, nCh] = headerMules();
chLabels = chNamesMules();

disp(strcat('Using : ', device));

% Selection of Electrodes to compute Alpha power
switch device
    case 'MUSE'
        electArray = [1:4];
        electNames = {'TP7', 'Fp1', 'Fp2', 'TP8'};
    case 'EMOTIV'
        electArray = [9:12];
    case 'ENOBIO'
        electArray = [1:4];
    case 'NEUROSKY'
        electArray = [1];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%              Title                            %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

quitFlag = false;
evalFirst = true;

nSamplesTrain = trainDuration * fs;
nSamplesWindow = windowDuration * fs;
nSamplesOverlap = testOverlap * fs;

nColumns = numel(tags);

evalData = NaN(nSamplesWindow*2,nColumns);
nRun = 1;

while true % Player Loop
    commandBoss = fread(playerClient, 1);
    switch commandBoss % Command Switch
        case 'A', %Training data Class 0
            disp('Handshake Phase 1...');
            flushMules();
            pause(trainDuration*1.1);
            eegData = getDataMules();
            train0 = eegData(1:nSamplesTrain,:);
            sound(y,sampF); %beep
            fwrite(playerClient, 1); % Notify Boss
        case 'B', %Training data Class 1
            disp('Handshake Phase 2...');
            flushMules();
            pause(trainDuration*1.1);
            eegData = getDataMules();
            train1 = eegData(1:nSamplesTrain,:);
            sound(y,sampF); %beep
            fwrite(playerClient, 1); % Notify Boss
        case 'C', %Training classifier
            % Select electrodes
            % Train0 and Train1 are divided in windows
            % Features are computed window-wise
            % Feature vectors and labels are used fro training the classifier
            % Save configuration
            sound(y,sampF); %beep
            pause(0.2);
            sound(y,sampF); %beep
            fwrite(playerClient, 1); % Notify Boss
        case 'D', %Evaluate
            while true %Classification Loop
                % Get data and classify it
                limit = testOverlap; % How often EEG data will be requested
                if evalFirst % To obtain the First window, without overlap
                    tic
                    limit = windowDuration;
                    evalFirst = false;
                end
                
                if toc > limit*1.1
                    tic
                    eegData = getDataMules();
                    evalData = [eegData; evalData];
                    evalData = evalData(1:2*nSamplesWindow,:);
                    yHat = 1;
                    % Classify the example
                    fwrite(playerClient, yHat);
                end
                           
                % Check if the Boss requested to Stop
                if playerClient.BytesAvailable > 0 % If available bytes
                    commandBoss = fread(playerClient, 1);
                    if(commandBoss == 'Q') %If Q command
                        quitFlag = true;
                        evalFirst = true;
                        break; % Breaks Classification Loop
                    elseif(commandBoss == 'R')                      
                        nRun = nRun+1;
                        break; % Breaks Classification Loop
                    end %If Q command
                end % If available bytes    
            end % Classification Loop          
    end % Command Switch  
    if quitFlag
        break;
    end
end %Player Loop

sound(y,sampF); %beep
fclose(mulesClient);
delay_ms(500);
fclose(playerClient);
disp(['Done with Player ',num2str(playerNb)]);

%   Read command (or wait for it)
%       switch with command
%           Calib0
%               Flushes MuLES 
%               Wait training Secs and read data
%               Send exit to boss
%           Calib1
%               Flushes MuLES 
%               Wait training Secs and read data
%               Send exit to boss
%           Training
%               Feature comp
%               Train
%               Flushes MuLES 
%               Send exit to boss
%           Evaluation
%               While true
%                   if bytes.ava > 0 
%                       read if == Q or R break, quitFlag
%                   else
%                       Wait 100ms
%                       Get data
%                       Fill buffer
%                       If lleno, 
%                       Feature comp
%                       Eval
%           if quitFlag
%               Brake this while
%               Send exit to boss           
%












% %Buffer definition, it will depend of FS and #CHANNELS
% bufferSeconds = trainDuration;
% nSamples = bufferSeconds*fs;
% nColumns = numel(tags);
% trainEEG = NaN(nSamples,nColumns);
% timeVector = (0:nSamples-1)/fs;
% 
% %Window length were power is computed (in samples)
% windowLength = fs*windowDuration;
% overlapLength = testOverlap; %seconds
% overlapSampleLength = floor(overlapLength*fs);
% 
% %Test buffer
% testEEG = NaN(windowLength,nColumns);

% 
% yHatHist = [40];
% Xtest = [];



% State machine label
% state = 'NA';






% delay_ms(1000);
% 
% if(mulesClient.BytesAvailable > 0)
%     fread(mulesClient, mulesClient.BytesAvailable);
% end

% FullTestSave = ones(length(electArray),1)';
% FullYEval = 1;
% FullYHat = 1;

% needWaitHandshake = 1;
% nRun = 1;
% while true %Main loop, it is controlled by the TCP/IP packages rate
%     if needWaitHandshake == 1
%         playerData = fread(playerClient, 1);
%         if(playerData == 'A')
%             disp('Handshake Phase 1...');
%             state = 'acqTrain0';
%             % Empty Buffer.
%             if(mulesClient.BytesAvailable > 0)
%                 fread(mulesClient, mulesClient.BytesAvailable);
%             end
%             needWaitHandshake = 0;
%         end
%         if(playerData == 'B')
%             disp('Handshake Phase 2...');
%             state = 'acqTrain1';
%             % Empty Buffer.
%             if(mulesClient.BytesAvailable > 0)
%                 fread(mulesClient, mulesClient.BytesAvailable);
%             end
%             needWaitHandshake = 0;
%         end
%         if(playerData == 'C')
%             disp('Start Training...');
%             state = 'trainClassifier';
%             % Empty Buffer.
%             if(mulesClient.BytesAvailable > 0)
%                 fread(mulesClient, mulesClient.BytesAvailable);
%             end
%             needWaitHandshake = 0;
%         end
%         if(playerData == 'D')
%             disp('Start Real Time Game...');
%             state = 'startClassification';
%             % Empty Buffer.
%             if(mulesClient.BytesAvailable > 0)
%                 fread(mulesClient, mulesClient.BytesAvailable);
%             end
%             needWaitHandshake = 0;
%         end
%         %This is not reach unless you send Q before the testing part
%         if(playerData == 'Q')
%             disp('Exit...');
%             break;
%         end
%     end
%     
%     %After Training the data is flushed
%     if strcmp(state,'startClassification')
%         if(mulesClient.BytesAvailable > 0)
%             fread(mulesClient, mulesClient.BytesAvailable);
%         end
%         state = 'classification';
%     end
%     %Catch error in communication with the EEG acq client
%     try
%         nBytes_4B = fread(mulesClient, 4);
%     catch err;
%         break %break if there is an error in communication
%     end
%     %Break the while loop if the first byte is -1
%     nBytes = double(swapbytes(typecast(uint8(nBytes_4B),'int32')));
%     if nBytes == -1 %If -1 is recived, close TCP communication
%         break;
%     end
%     %Catch error in communication with the EEG acq client
%     try
%         data = fread(mulesClient,nBytes);
%     catch err;
%         break
%     end
%     %Give order to the incoming data, and removing DC component
%     eegData = mesDataFormat(data,tags);%normalize_col(mesDataFormat(data,tags));
%     [newRows, ~ ] = size(eegData);
%     
%     trainEEG =  [trainEEG(1+newRows:end, :); eegData];
%     testEEG = [testEEG(1+newRows:end, :); eegData];
%     
%     if ~isnan(trainEEG(1,1))
%         switch state
%             case 'acqTrain0',
%                 disp('Handshake Phase 1 Done !');
%                 fwrite(playerClient, 1);
%                 needWaitHandshake = 1;
%                 train0 = trainEEG;
%                 trainEEG(:) = NaN;
%                 %state = 'acqTrain1';
%                 sound(y,sampF); %beep
%                 
%                 size(train0)
%                 
%             case 'acqTrain1',
%                 disp('Handshake Phase 2 Done !');
%                 %Don't tell Boss now, wait after Training. (since not long)
%                 fwrite(playerClient, 1);
%                 needWaitHandshake = 1;
%                 train1 = trainEEG;
%                 trainEEG(:) = NaN;
%                 %state = 'trainClassifier';
%                 sound(y,sampF); %beep
%                 
%         end %switch for training examples
%     end %if first row is NaN
%     
%     switch state
%         case 'trainClassifier',
%             
%             disp('Training classifier');
%             
%             %Extract features for class 0
%             electUsed = double(train0(:,electArray));
%             
%             L = length(electUsed);
%             nbWin = floor(L/(windowLength - overlapSampleLength))-2;
% 
%             for i = 0:nbWin-1
%                 % Get the window
%                 start = (windowLength - overlapSampleLength)*i + 1;
%                 finish = start + windowLength - 1;
%                 dataWin = electUsed(start:finish,:);
%                 
%                 if i == 0
%                     nFeatures = length(dataWin);
%                     featArray0 = zeros(nbWin,nFeatures);
%                 end
% 
%                 [featArray0(i+1,:), ~] = featureExtract(dataWin, fs, 0);
%             end
% 
%             % Extract features for class 1
%             electUsed = double(train1(:,electArray));
%             
%             L = length(electUsed);
%             nbWin = floor(L/(windowLength - overlapSampleLength))-2;
%             for i = 0:nbWin-1
%                 % Get the window
%                 start = (windowLength - overlapSampleLength)*i + 1;
%                 finish = start + windowLength - 1;
%                 dataWin = electUsed(start:finish,:);
%                 
%                 if i == 0
%                     nFeatures = length(dataWin);
%                     featArray1 = zeros(nbWin,nFeatures);
%                 end
% 
%                 [featArray1(i+1,:), featNames] = featureExtract(dataWin, fs, 1);
%             end
%             
%             % Remove start and end of featArray
%             featArray0 = featArray0(2:end-2,:);
%             featArray1 = featArray1(2:end-2,:);
%             
%             % Z-score normalize the features
%             featArrayAll = [featArray0; featArray1];
%             mu_col = nanmean(featArrayAll);
%             sigma_col = nanstd(featArrayAll);
%             featArray0 = (featArray0-repmat(mu_col,nbWin,1))./repmat(sigma_col,nbWin,1);
%             featArray1 = (featArray1-repmat(mu_col,nbWin,1))./repmat(sigma_col,nbWin,1);
%             
%             % Select the best features
%             nSelectedFeat = 5;
%             selectedFeatInd = featureSelect(featArrayAll(:,1:end-1), featArrayAll(:,end), nSelectedFeat);
%             disp('Selected features: ')
%             disp(featNames(selectedFeatInd))
%             
%             % Remove outliers from selected features
%             [outInd0] = findOutliers(featArray0(:,selectedFeatInd));
%             [outInd1] = findOutliers(featArray1(:,selectedFeatInd));
%             featArray0(outInd0,:) = [];
%             featArray1(outInd1,:) = [];
%                         
%             % Train the classifier
%             classifierName = 'SVM';
%             [modelParams, trainingAcc] = trainClassifier(featArray0(:,selectedFeatInd), featArray1(:,selectedFeatInd), classifierName);
%             
%             % Save the raw data, the features, the normalized features, the
%             % feature list, the selected features list, the classifier
%             % parameters, and the training accuracy
%             saveName = ['calibration_player_', playerName, num2str(playerNb),'_',num2str(now), '_', num2str(nRun), '.mat'];
%             calibData.port2boss = port2boss;
%             calibData.port2acq = port2acq;
%             calibData.playerNb = playerNb;
%             calibData.raw = electUsed;
%             calibData.Fs = fs;
%             calibData.device = device;
%             calibData.chLabels = chLabels;
%             calibData.featArray = featArrayAll;
%             calibData.featArrayNorm = [featArray0; featArray1];
%             calibData.featNames = featNames;
%             calibData.selectedFeatInd = selectedFeatInd;
%             calibData.selectedFeat = featNames(selectedFeatInd);
%             calibData.modelParams = modelParams;
%             calibData.trainingAcc = trainingAcc;
%             calibData.train0 = train0;
%             calibData.train1 = train1;
%             try
%                 save(saveName, 'calibData');
%                 disp(['Calibration data saved in ',saveName,'.'])
%             catch
%                 disp('Could not save the calibration data.')
%             end
%             
%             % Plot the main results
% %             scrsz = get(groot,'ScreenSize');
% %             figure('Position',[scrsz(3)/8 scrsz(4)/4 6*scrsz(3)/8 2*scrsz(4)/4])
% %             
%             figure('units','normalized','outerposition',[0 0 1 1])        
%             subplot(3,1,1);
%                 plot([train0, train1]')
%                 xlabel('Time points')
%                 ylabel('Raw EEG amplitude')
%                 legend(electNames);
%                 title(strcat('Calibration session for Player', num2str(playerNb)));
%                 
%             subplot(3,1,2);
%                 plot([featArray0(:,selectedFeatInd); featArray1(:,selectedFeatInd)])
%                 xlabel('Time points')
%                 ylabel('Normalized feature amplitude')
%                 legend(featNames{selectedFeatInd});
%                 title([num2str(nSelectedFeat),' best features over time'])
%                 
%             subplot(3,1,3);
%                 boxplot([featArray0, featArray1], 'labels', [featNames, featNames],...
%                         'labelorientation','inline');
%                 ylabel('Normalized feature amplitude')
%                 title('Distribution of features for the two classes')
%                 
%             drawnow
%             pause(1);
%             
%             testEEG(:) = NaN;
%             %state = 'startClassification';
%             sound(y,sampF); sound(y,sampF); %beep
%             
%             disp('Training Done !');
%             %Don't tell Boss now, wait after Training. (since not long)
%             fwrite(playerClient, 1);
%             needWaitHandshake = 1;
%             
%         case 'classification'
%             if ~isnan(testEEG(1,1))
%                 electUsed = double(testEEG(:,electArray));
%                 FullTestSave = [FullTestSave; electUsed];
%                 example = featureExtract(electUsed, fs);
%                 example = (example-mu_col)./sigma_col;
%                 
%                 yEval = modelPredict(modelParams, example(selectedFeatInd), classifierName);
%                 yHat = yEval;
%                 
%                 %[~,yHat] = max(yEval,[],2);
%                 yHatHist = [yHatHist; yHat];
%                 fwrite(playerClient, yHat);
%          
%                 testEEG(1:windowLength-overlapSampleLength,:) = NaN;
%                 %Only the shift is cleaned.
%                 %note that if overlap = 0, then all the matrix is set to
%                 %NaN
%                 
%                 if playerClient.BytesAvailable > 0
%                     playerData = fread(playerClient, 1);
%                     if(playerData == 'Q')
%                         break;
%                     elseif(playerData == 'R')
%                         needWaitHandshake = 1;
%                         trainEEG(:) = NaN;
%                         testEEG(:) = NaN;
%                         nRun = nRun+1;
%                         
%                     end
%                 end
%             end
%     end
%     
%     delay_ms(200);
% end %while true
% 
% saveName = ['test_player_', playerName, num2str(playerNb),'_',num2str(now), '_', num2str(nRun), '.mat'];
% testData.port2boss = port2boss;
% testData.port2acq = port2acq;
% testData.playerNb = playerNb;
% testData.raw = electUsed;
% testData.Fs = fs;
% testData.device = device;
% testData.chLabels = chLabels;
% testData.data = FullTestSave;
% % testData.Threshold = scoreThreshold;
% % testData.YHats = FullYHat;
% % testData.YEvals = FullYEval;
% 
% save(saveName, 'testData');
% disp(['Test data saved in ',saveName,'.'])
% 
% subplot(2,1,1);
% plot(FullTestSave);
% subplot(2,1,2);
% plot([FullYEval FullYHat]);
% bPress = 0;
% % while bPress == 0
% %     bPress = waitforbuttonpress;
% % end


    function flushMules()
        commandMules = 'F';
        fwrite(mulesClient, commandMules);
    end

    function [dev_name, dev_hardware, fs, data_format, nCh] = headerMules()
        commandMules = 'H';
        fwrite(mulesClient, commandMules);
        nBytes_4B = fread(mulesClient, 4);  %How large is the package (# bytes)
        nBytes = double(swapbytes(typecast(uint8(nBytes_4B),'int32')));
        package = fread(mulesClient,nBytes);
        header_str = char(package)';
        [dev_name, dev_hardware, fs, data_format, nCh] = mules_parse_header(header_str);
    end

    function  ch_labels = chNamesMules()
        commandMules = 'N';
        fwrite(mulesClient, commandMules);
        nBytes_4B = fread(mulesClient, 4);  %How large is the package (# bytes)
        nBytes = double(swapbytes(typecast(uint8(nBytes_4B),'int32')));
        package = fread(mulesClient,nBytes);
        ch_names_str = char(package)';
        tmp = textscan(ch_names_str,'%s','delimiter',',');
        ch_labels = tmp{1};
    end

    function eeg_data = getDataMules()
        commandMules = 'R';
        fwrite(mulesClient, commandMules);
        nBytes_4B = fread(mulesClient, 4);  %How large is the package (# bytes)
        nBytes = double(swapbytes(typecast(uint8(nBytes_4B),'int32')));
        eeg_package = fread(mulesClient,nBytes);
        eeg_data = mules_parse_data(eeg_package,tags);
    end

end
