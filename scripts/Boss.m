% Description of Boss Script

% Begining
clear all;
close all;
clc;

% Admin Messages
% disp('** KbCheck Commented ! **');
% Modif : Feature Extract --> electAlpha / electBeta / 9-11 Hz. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%   === Configuration of Output Devices ===     %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% EV3 Robot, Bluetooth
bolRobot = false;

% Android App, Bluetooth
bolTablet = true;

% Bluetooth configuration for Smartphone or Table running the Android App
btDevice = 'MuSAE N7';
btChannel = 3;
% If you do not know the bluetooth channel number, uncomment the next line:
%btChannel = 0
% Matlab will search for the correct channel, however the connection will 
% take longer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%   === Players information ===                 %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Name of Players
player1Name = 'Ana';
player2Name = 'Wil';
player1Port = 33001;
player2Port = 33002;

% Verify names
if isempty(player1Name) || isempty(player2Name)
    if isempty(player1Name)
        player1Name = 'PC1';
    end
    if isempty(player1Name)
        player2Name = 'PC2';
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% === Configuration of Game Mechanics ===       %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Game Mechanics
trainDuration  = 15;  %Duration of each training section
windowDuration = 2;  %Duration of the test window to extract features
testOverlap    = 1;    %Overlap for the windows

% General Variables
command = 'x';
bolPlayer1 = true;
bolPlayer2 = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%            === Connections Init ===           %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Adds the parent directory to the Matlab Path
folder = [pwd '\'];
cd('..\');
addpath(genpath(pwd));
cd(folder);

% Matlab execccutable path
matlabExePath = ' "C:\Program Files\MATLAB\R2013a\bin\matlab.exe" ';
disp('###### Neural Drift #######')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%              Connection with EV3              %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if bolRobot
    disp('Waiting for EV3 client on port 33000...')
    ev3Server=tcpip('0.0.0.0', 33000, 'NetworkRole', 'server');
    ev3Server.InputBufferSize = 500000;
    ev3Server.Timeout = 60; %in seconds
    %Run EV3 client script in another matlab instance
    system( [ matlabExePath ' -nosplash -nodesktop -r "run(''' folder '\demo7\demo7_ev3_client.m''); exit();"']);
    %Open a connection with the EV3 client
    fopen(ev3Server);
    disp('Successful connection with EV3 client')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%            Connection with Tablet             %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if bolTablet
    disp('Waiting for connection with Tablet...');
    if btChannel <= 0
        btInfo = instrhwinfo('Bluetooth',btDevice);
        btDevice = btInfo.RemoteName;
        btChannel = str2num(btInfo.Channels{1});
    end
    disp(sprintf('Connecting with: %s, in channel: %d',btDevice, btChannel));
    %Opening connection with Tablet
    tabletServer = Bluetooth(btDevice,btChannel);
    fopen(tabletServer);
    disp('Bluetooth connection opened sucessfully!');
    disp('Touch the tablet screen to start');
    input('Press Enter to Continue')
    %delay_ms(200);
    %Receiving a string from the Tablet, the string is ended ('\r')
    index=1;
    while true
        if tabletServer.BytesAvailable ~= 0
            dataRx(index) = fread(tabletServer, 1);
            if dataRx(index) < 20 %See ASCII table ENTER is below 20
                break
            else
                index = index +1 ;
            end
        end
        pause(0.01);
        %tabletServer.BytesAvailable
    end
    
    %Welcoming string from the Table, this string is used to check that
    %the bluettoth connection is working properly
    disp(char(dataRx));
end


%Start sound
filename = 'deep_bass.wav';
[y, Fs] = audioread(filename);
sound(y,Fs/1.1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%           Connection with Player1             %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if bolPlayer1
    disp('Waiting for Player1 client on port 33001...')
    %Open the communication with EEGacq program
    player1Server = tcpip('0.0.0.0', 33001, 'NetworkRole', 'server');
    player1Server.InputBufferSize = 5000000;
    player1Server.Timeout = 20; %in seconds
    
    %Calling PlayerFunct to player1
    playerNameAux = ['''''' player1Name  ''''''];
    system( [ matlabExePath ' -nosplash -nodesktop -r "run(''' [folder ...
        'PlayerFunct(33001,30001,' playerNameAux ',' num2str(trainDuration) ',' ...
        num2str(windowDuration) ',' num2str(testOverlap)]  ')''); exit();"']);
    
    %Check for device number and start the acquisition with that
    %system( [folder '\EEG_Acquisition1\eegacq.exe &']);
    
    %fopen waits for the client connection.
    fopen(player1Server);
    disp('Connected to Player 1 !')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%           Connection with Player2             %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if bolPlayer2
    disp('Waiting for Player2 client on port 33002...')
    %Open the communication with EEGacq program
    player2Server = tcpip('0.0.0.0', 33002, 'NetworkRole', 'server');
    player2Server.InputBufferSize = 5000000;
    player2Server.Timeout = 20; %in seconds
    
    %Calling PlayerFunct to player1
    playerNameAux = ['''''' player2Name  ''''''];
    system( [ matlabExePath ' -nosplash -nodesktop -r "run(''' [folder ...
        'PlayerFunct(33002,30002,' playerNameAux ',' num2str(trainDuration) ',' ...
        num2str(windowDuration) ',' num2str(testOverlap)]  ')''); exit();"']);
    
    %Check for device number and start the acquisition with that
    %system( [folder '\EEG_Acquisition2\eegacq.exe &']);
    
    %fopen waits for the client connection.
    fopen(player2Server);
    disp('Connected to Player2 !')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%        === Handshake / Calibration ===        %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% filename = 'initiating.mp3';
% [y, Fs] = audioread(filename);
% sound(y,Fs/1.1);

nRun = 1;
while true %MegaLoop While
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%                    Phase 1                    %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if bolPlayer1 && player1Server.BytesAvailable > 0
        fread(player1Server, player1Server.BytesAvailable);
    end
    if bolPlayer2 && player2Server.BytesAvailable > 0
        fread(player2Server, player2Server.BytesAvailable);
    end
    
    disp('Handshake Phase 1...')
    % filename = 'phase1.mp3';
    % [y, Fs] = audioread(filename);
    % sound(y,Fs/1.1);
    if bolTablet
        fwrite(tabletServer, 204, 'uint8'); %CC in hex
    end
    if bolPlayer1
        fwrite(player1Server, 'A');
    end
    if bolPlayer2
        fwrite(player2Server, 'A');
    end
    
    %This sound indicates that the Phase 1 is initiated
    filename = 'initiating.mp3';
    [y, Fs] = audioread(filename);
    sound(y,Fs/1.1);
    
    % Waiting for 2 Players to finish the Handshake.
    serversState = zeros(2,1);
    while min(serversState) == 0
        delay_ms(100);
        if bolPlayer1
            if player1Server.BytesAvailable > 0
                player1Data = fread(player1Server, player1Server.BytesAvailable);
                serversState(1) = 1; % Player 1 has finished Handshake Phase 1
            end
        else
            serversState(1) = 1; % Player 1 has finished Handshake Phase 1 (No Player 1)
        end
        if bolPlayer2
            if player2Server.BytesAvailable > 0
                player2Data = fread(player2Server, player2Server.BytesAvailable);
                serversState(2) = 1; % Player 2 has finished Handshake Phase 1
            end
        else
            serversState(2) = 1; % Player 2 has finished Handshake Phase 1 (No Player 2)
        end
        % TODO : Validate playerData, not just any data.
    end
    disp('Handshake Phase 1 Done !')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%                    Phase 2                    %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp('Handshake Phase 2...')
    filename = 'phase2.mp3';
    [y, Fs] = audioread(filename);
    sound(y,Fs/1.1);
    if bolTablet
        fwrite(tabletServer, 221, 'uint8'); %DD in hex
    end
    if bolPlayer1
        fwrite(player1Server, 'B');
    end
    if bolPlayer2
        fwrite(player2Server, 'B');
    end
    
    % Waiting for 2 Players to finish the Handshake.
    serversState = zeros(2,1);
    while min(serversState) == 0
        delay_ms(100);
        
        if bolPlayer1
            if player1Server.BytesAvailable > 0
                player1Data = fread(player1Server, player1Server.BytesAvailable);
                serversState(1) = 1; % Player 1 has finished Handshake Phase 2
            end
        else
            serversState(1) = 1; % Player 1 has finished Handshake Phase 2 (No Player 1)
        end
        if bolPlayer2
            if player2Server.BytesAvailable > 0
                player2Data = fread(player2Server, player2Server.BytesAvailable);
                serversState(2) = 1; % Player 2 has finished Handshake Phase 2
            end
        else
            serversState(2) = 1; % Player 2 has finished Handshake Phase 2 (No Player 2)
        end
        % TODO : Validate playerData, not just any data.
    end
    
    %Calibration Done !
    disp('Handshake Phase 2 Done !')
    
    filename = 'completed.mp3';
    [y, Fs] = audioread(filename);
    sound(y,Fs/1.1);
    delay_ms(1000);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%                   Training                    %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp('Handshake Training...')
    if bolTablet
        fwrite(tabletServer, 238, 'uint8'); %EE in hex
    end
    if bolPlayer1
        fwrite(player1Server, 'C');
    end
    if bolPlayer2
        fwrite(player2Server, 'C');
    end
    
    % Waiting for 2 Players to finish the Handshake Training.
    serversState = zeros(2,1);
    while min(serversState) == 0
        delay_ms(100);
        if bolPlayer1
            if player1Server.BytesAvailable > 0
                player1Data = fread(player1Server, player1Server.BytesAvailable);
                serversState(1) = 1; % Player 1 has  Handshake Phase 1
            end
        else
            serversState(1) = 1; % Player 1 has  Handshake Phase 1 (No Player 1)
        end
        if bolPlayer2
            if player2Server.BytesAvailable > 0
                player2Data = fread(player2Server, player2Server.BytesAvailable);
                serversState(2) = 1; % Player 1 has finished Handshake Phase 2
            end
        else
            serversState(2) = 1; % Player 1 has finished Handshake Phase 2
        end
        % TODO : Validate playerData, not just any data.
    end
    
    disp('Handshake Done !')
    filename = 'strong_and_holding.mp3';
    [y, Fs] = audioread(filename);
    sound(y,Fs/1.1);
    delay_ms(1000);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%            === Real Time Game ===             %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp('Starting the Game...')
    tone(500,1000); % Sound : Ready to Roll.
    if bolTablet
        fwrite(tabletServer, 255, 'uint8'); %FF in hex
    end
    if bolPlayer1
        fwrite(player1Server, 'D');
    end
    if bolPlayer2
        fwrite(player2Server, 'D');
    end
    
    % Waiting for 1 of the 2 Players to quit the game.
    serversState = zeros(2,1);
    powerP1 = 20;
    powerP1LastStep = 0;
    powerP1LastClass = 0;
    powerP2 = 20;
    powerP2LastStep = 0;
    powerP2LastClass = 0;
    toggleStop = false;
    newDecision1 = 1;
    newDecision2 = 1;
    powerP1Step = 0;
    powerP2Step = 0;   
    player1Data = 0;
    player2Data = 0;
    
    while max(serversState) == 0 %While for game
        
        incStep = 50;
        motorFactor = 0.25;            
        %Game Mechanic. The magic happens HERE !
        if bolPlayer1 && player1Server.BytesAvailable > 0
            player1Data = fread(player1Server, player1Server.BytesAvailable);
            newDecision1 = 1;
            switch player1Data
                case 1,
                    %                 powerP1 = 50;
                    if powerP1LastClass == 1
                        powerP1Step = powerP1Step + incStep;
                    else
                        powerP1Step = incStep;
                    end
                    powerP1 = powerP1 + powerP1Step;
                case 2,
                    %                powerP1 = 0;
                    if powerP1LastClass == 2
                        powerP1Step = powerP1Step - incStep;
                    else
                        powerP1Step = -incStep;
                    end
                    powerP1 = powerP1 + powerP1Step;
                case 9, %PlayerFunct wants to finish
                    serversState(1) = 1;
            end
            powerP1LastClass = player1Data;
                     
            if powerP1 > 99
                powerP1 = 100;
            elseif powerP1 < 1
                powerP1 = 0;
            end       
        end
        
        if bolPlayer2 && player2Server.BytesAvailable > 0
            player2Data = fread(player2Server, player2Server.BytesAvailable);
            newDecision2 = 1;
            switch player2Data
                case 1,
                    %                 powerP2 = 50;
                    if powerP2LastClass == 1
                        powerP2Step = powerP2Step + incStep;
                    else
                        powerP2Step = incStep;
                    end
                    powerP2 = powerP2 + powerP2Step;
                case 2,
                    %                powerP2 = 0;
                    if powerP2LastClass == 2
                        powerP2Step = powerP2Step - incStep;
                    else
                        powerP2Step = - incStep;
                    end
                    powerP2 = powerP2 + powerP2Step;
                case 9, %PlayerFunct wants to finish
                    serversState(2) = 1;
            end
            powerP2LastClass = player2Data;
            
            if powerP2 > 99
                powerP2 = 100;
            elseif powerP2 < 1
                powerP2 = 0;
            end
        end
        
        if newDecision1 == 1 || newDecision2 == 1
            newDecision1 = 0;
            newDecision2 = 0;
            %If a decision was read from any player, update Robot and Tablet
            barP1 = uint8(round(powerP1*(10/100)));
            barP2 = uint8(round(powerP2*(10/100)));
            bar1Array = dec2bin(barP1,4);
            bar2Array = dec2bin(barP2,4);
            %Build byte to send to the Tablet
            %High 4 bits encode power from 0 to 10 for P1
            %Low  4 bits encode power from 0 to 10 for P2
            byteBars = [bar1Array,bar2Array];
            bytePowers = uint8(bin2dec(byteBars));
            if bolTablet
                fwrite(tabletServer, bytePowers, 'uint8' );
                delay_ms(500);
            end
            
            if bolRobot
                if toggleStop
                    fwrite(ev3Server, uint8([0,0]), 'uint8' );
                else
                    fwrite(ev3Server, uint8([motorFactor * powerP1, motorFactor * powerP2]), 'uint8' );
                end
            end
            
            fprintf('%d %d (%d) | %d %d (%d)\n', player1Data, powerP1, powerP1Step, player2Data, powerP2, powerP2Step) 
        end
        
        %Check for space key to stop the robot (send zeros ONLY to Robot)        
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck([]);
        if sum(keyCode) > 1
            disp('Press only one key at the same time');
        elseif sum(keyCode) == 0
            command = 'x';
        else
            command = KbName(find(keyCode));
            disp(command);
        end
        
        switch command
            case 'space',
                disp(toggleStop);
                toggleStop = ~toggleStop;
                delay_ms(50);
            case 'esc',
                break; %breaks While for game
            case 'r',
                break; %breaks While for game
            case 'n'
                fprintf('Class for P1 = %d\r',player1Data);
                fprintf('Class for P2 = %d\r',player2Data);
                fprintf('P1 power = %d\r',powerP1);
                fprintf('P2 power = %d\r',powerP2);
                fprintf('Byte sent to Tablet = %x\r',bytePowers);
                fprintf('Toggle Status %i\r', toggleStop);
        end
        %delay_ms(10);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%           === Out of the Playing part ===     %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    switch command
        case 'esc'
            break; %Breaks the MegaLoop
        case 'r'
            if bolTablet
                fwrite(tabletServer, 187, 'uint8'); %FF in hex
            end
            if bolRobot
                fwrite(ev3Server, uint8([0,0]), 'uint8' );
            end
            nRun = nRun +1;
            if bolPlayer1
                fwrite(player1Server, 'R');
            end
            if bolPlayer2
                fwrite(player2Server, 'R');
            end
            tone(600,300);
            tone(600,300);
            delay_ms(2000);
            input('Press ENTER to continue');
    end
    
end %MegaLoop While

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%         === Closing the Whole Thing ! ===     %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tone(600,1500); % Sound : END

% Close EV3
if bolRobot
    fwrite(ev3Server, uint8([0,0]), 'uint8' );
    delay_ms(200);
    fwrite(ev3Server, uint8([101,101]), 'uint8' );
    delay_ms(200);
    fclose(ev3Server);
end

% Close Tablet
if bolTablet
    fwrite(tabletServer, 187, 'uint8'); %BB in hex
    delay_ms(500);
    fclose(tabletServer);
end

% Close Player 1
if bolPlayer1
    fwrite(player1Server,'Q');
    delay_ms(500);
    fclose(player1Server);
end

% Close Player 2
if bolPlayer2
    fwrite(player2Server,'Q');
    delay_ms(500);
    fclose(player2Server);
end

disp('Bye !')