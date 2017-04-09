function Data = doTrialJustStim(Params, Trial)
% This function handles the running of a single hard conscious trial. In a
% hard conscius trial the mask is presented to both eye, with the stimulus
% presented at full contrast at a random time after mask onset. Time range
% is determined in Params. The function recieves parameters in two structs
% - Params for parameters that are constant  across experiments, Trial for 
% parameters that vary with each trial.

%% Prep
% Determine frame to present stimulus
Data.stimTime = round2flips(Params,rand() * range(Params.hardCon.stimOnsetRange) + ...
    Params.hardCon.stimOnsetRange(1));
stimFrame = time2flips(Params, Data.stimTime);

% Determine end frame
maxFrame = time2flips(Params, Params.endTrial) + stimFrame;

% Determine location for stimulus
frameLocation = [CenterRectCalib(Params,angle2pix(Params.Display, ...
    [0 0 Params.frame.width Params.frame.height]), 0);...
    CenterRectCalib(Params,angle2pix(Params.Display, ...
    [0 0 Params.frame.width Params.frame.height]), 1)]; % Frames to draw in

if Trial.Location == 9
    % If stimulus is top
    frameLocation(:,4) = (frameLocation(:,4)-frameLocation(:,2)) ./ 2 + ...
        frameLocation(:,2);
elseif Trial.Location == 10
    % If stimulus is bottom
    frameLocation(:,2) = frameLocation(:,4) - ...
        (frameLocation(:,4)-frameLocation(:,2)) ./ 2;
end

stimRect = angle2pix(Params.Display,...
    [0 0 Params.stimulus.size Params.stimulus.size]); % Rect the size of the stimulus

stimLocation = [CenterRect(stimRect, frameLocation(1,:));...
    CenterRect(stimRect, frameLocation(2,:))];

% Missing values
Data.RT=NaN;
Data.Response=NaN;

%% Animation loop
terminate = 0;  % Assisting variable
thisFrame = 1;  % Frame counter
startTime = GetSecs();  % Time of trial start
while thisFrame <= maxFrame && ~terminate
    
    for side = [0, 1]
        
        % Select masked-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', Params.w, side);
                
        % Draw mask-side frame:
        drawFrame(Params, side);    % See below
        
        % Draw fixation
        drawFixation(side);    % See below
        
        % Draw Stimulus:
        if thisFrame >= stimFrame
            Screen('DrawTexture', Params.w, Trial.stimHandle,...
                [],stimLocation(side+1,:),[],[],Params.stimulus.maxAlpha);
        end
    end
    
    % Tell PTB drawing is finished for this frame:
    Screen('DrawingFinished', Params.w);
        
    % Now all non-drawing tasks:
         
    % Get response:
    if thisFrame >= stimFrame
        [keyDown,~,keyCode,~] = KbCheck();
        
        if keyDown
            if keyCode(Params.keyEsc)
                % Close screen and break loop if esc is pressed
                sca;
                break
            elseif any(keyCode([Params.keyRight,Params.keyLeft]))
                Data.RT = GetSecs() - (startTime + Data.stimTime);
                Data.Response = Params.respMap(keyCode == 1);
                Data.Acc = Params.respMap(keyCode == 1)+8 == Trial.Location;
                terminate = 1;
            end
        end
    end
    
    % Flip screen - currently implemented without specifying when
    Screen('Flip',Params.w);
    thisFrame = thisFrame + 1;
end

if ~Params.saltShaker
    KbReleaseWait();
end

% Clear presentation
Screen('Flip', Params.w);

% Anxillary functions
    function drawFixation(side)
        fixSize = angle2pix(Params.Display, Params.fixationSize);
        verFix = CenterRectCalib(Params,[0 0 fixSize/4 fixSize], ...
            side);
        horFix = CenterRectCalib(Params,[0 0 fixSize fixSize/4], ...
            side);
        
        Screen('FillRect', Params.w, [0 0 0], [verFix; horFix]');
    end
end