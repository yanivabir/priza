% Main experiment file
% This file should be clear and readable, and easily manipulated even by
% users who did not take part in coding this experiment.

%% Prep
% Clear previous screen settings. Optionally for debug - run with
% transperant window
clear Screen
% PsychDebugWindowConfiguration;

PsychDefaultSetup(2);

% Load parameters
B1Params;

% Log start time
Params.experimentStart = datestr(now,'yymmdd_HHMM');

%Set randomization to not start over on every system startup
s = RandStream.create('mt19937ar','seed',sum(100*clock));       
RandStream.setGlobalStream(s);

% Get subject number
Params.subjectNumber=input('subject number?\n');
Params.subjectPrefix = ['S' num2str(Params.subjectNumber, '%02d')];

% Log everything to diary file
diary([Params.dataFolder Params.version '_' Params.subjectPrefix '_Log_'...
    Params.experimentStart '.txt']);

try
    % Force GetSecs and WaitSecs into memory to avoid latency later on:
    GetSecs; WaitSecs(0.1);
    
    % Load image files
    Params.Images = loadImages(Params);    
    
    % Open PTB window
    Params = openWindow(Params);
    
    % Calibrate stereoscopic presentation if needed
    if strcmp(Params.Display.stereoMode,'stereoscope')
        Params = initialCalibration(Params);
    end
    
    %%% Training block
    % Define block
    training = [];
    training.stimLabel = 'training'; % Label in the csv file for stimuli for this block
    training.repetitions = 1;    % How many times to repeat stimuli, factors
    training.trialType = 'bCFS';    % Type of trial, can be a cell if this is a factor
    
    % Instructions
    ins.isPict = 1;
    ins.img = 'Ins3.jpg';
    ins.contKey = KbName('space');
    doInstructions(Params,ins);
    
    % Run block
    Logger = runBlock(Params, training);
    
    % Insturctions
    msg.text = 'אנא קרא לנסיין';
    msg.rtl = 0;
    msg.contKey = KbName('1!');
    doInstructions(Params,msg);
    
    msg.text = 'לחץ על מקש\nהרווח להמשך';
    msg.contKey = KbName('space');
    doInstructions(Params,msg);
    
    %%% Experimental blocks
    % Define block
    exp = [];
    exp.stimLabel = 'exp';
    exp.repetitions = 1;
    exp.trialType = 'bCFS';
    
    % Run block
    Logger = runBlock(Params,exp);
    
    % Save file
    saveFiles(Params,Logger);
    
    % Display message
    msg.text = 'אנא קרא לנסיין';
    msg.contKey = KbName('1!');
    doInstructions(Params,msg);
    
    %%% Finish and close
    sca;        % Close PTB window
    diary off;  % Stop logging events

catch
    Screen('CloseAll');
    psychrethrow(psychlasterror);
    Priority(0);
    ShowCursor;
end