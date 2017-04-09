function Data = doTrialMonocConsc(Params, Trial)
% This function handles the running of a single bCFS trial. It recieves
% parameters in two structs - Params for parameters that are constant
% across experiments, Trial for parameters that vary with each trial.

%% Prep
% Determine end frame from trial
maxFrame = time2flips(Params, Params.endTrial);

% Determine location for stimulus
frameLocation = CenterRectCalib(Params,angle2pix(Params.Display, ...
    [0 0 Params.frame.width Params.frame.height]), Trial.Eye);   % Frame to draw in
stimLocation = angle2pix(Params.Display,...
    [0 0 Params.stimulus.size Params.stimulus.size]); % Rect the size of the stimulus

if Trial.Location == 9
    % If stimulus is top
    frameLocation(4) = (frameLocation(4)-frameLocation(2)) / 2 + ...
        frameLocation(2);
elseif Trial.Location == 10
    % If stimulus is bottom
    frameLocation(2) = frameLocation(4) - ...
        (frameLocation(4)-frameLocation(2)) / 2;
end

stimLocation = CenterRect(stimLocation, frameLocation);

% Missing values
Data.RT=NaN;
Data.Response=NaN;

%% Animation loop
stimAlpha = 0;  % Initial stimulus alpha
mondrian = createMondrian(1 - Trial.Eye);   % Create mask for first frame
terminate = 0;  % Assisting variable
thisFrame = 1;  % Frame counter
startTime = GetSecs();  % Time of trial start
while thisFrame <= maxFrame && ~terminate
    
    % Select masked-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', Params.w, 1 - Trial.Eye);
    
    % Draw mask:
    Screen('FillRect',Params.w, mondrian.colors', mondrian.rect');
    
    % Draw mask-side frame:
    drawFrame(Params, 1 - Trial.Eye);    % See below
    
    % Draw fixation
    drawFixation(1 - Trial.Eye);    % See below
    
    % Select stim-eye image buffer for drawing:
    Screen('SelectStereoDrawBuffer', Params.w, Trial.Eye);
    
    % Draw Stimulus:
    Screen('DrawTexture', Params.w, Trial.stimHandle,...
        [],stimLocation,[],[],Params.stimulus.monocStimAlpha);
    
    % Draw stimulus-side frame
    drawFrame(Params, Trial.Eye);    % See below
    
    % Draw fixation
    drawFixation(Trial.Eye);    % See below
    
    % Tell PTB drawing is finished for this frame:
    Screen('DrawingFinished', Params.w);
    
    % Now all non-drawing tasks:
    
    % Compute mask for next frame:
    if ~mod(thisFrame, time2flips(Params, 1 / Params.mondrian.Hz))
        mondrian = createMondrian(1 - Trial.Eye);
    end
    
    % Compute mask alpha for next frame:
    if maxFrame < inf
        % If there is a time cut off to the trial
        maskAlpha = 1 - min((maxFrame - (thisFrame + 1)) / ...
            time2flips(Params, Params.mondrian.fadeOutTime),1);
        mondrian.colors(end,4) = maskAlpha;
    end
    
    % Get response:
    [keyDown,~,keyCode,~] = KbCheck();
    
    if keyDown
        if keyCode(Params.keyEsc)
            % Close screen and break loop if esc is pressed
            sca;
            break
        elseif any(keyCode([Params.keyRight,Params.keyLeft]))
            Data.RT = GetSecs() - startTime;
            Data.Response = Params.respMap(keyCode == 1);
            Data.Acc = Params.respMap(keyCode == 1)+8 == Trial.Location;
            terminate = 1;
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

    function mondrian = createMondrian(side)
        % Rectangle sizes
        dx = angle2pix(Params.Display,Params.mondrian.width);
        dy = angle2pix(Params.Display,Params.mondrian.height);
        
        % Where to draw the rects
        frame = CenterRectCalib(Params,angle2pix(Params.Display,...
            [0 0 Params.frame.width Params.frame.height]), side);
        
        locRect = frame - [dx, dy, 0, 0];
        
        % Possible colours
        colorOpts = [eye(3); 1-eye(3)];
        
        % Preallocate
        mondrian.rect = zeros(Params.mondrian.rectNum + 1,4);
        mondrian.colors = zeros(Params.mondrian.rectNum + 1,4);
        
        % Randomly draw rects
        for ii = 1:Params.mondrian.rectNum
            mondrian.rect(ii,1) = max(randi(locRect(3) - locRect(1)) + locRect(1),...
                frame(1));
            mondrian.rect(ii,2) = max(randi(locRect(4) - locRect(2)) + locRect(2),...
                frame(2));
            mondrian.rect(ii,3) = min(mondrian.rect(ii,1) + randi(dx) + dx, ...
                frame(3));
            mondrian.rect(ii,4) = min(mondrian.rect(ii,2) + randi(dy) + dy,...
                frame(4));
            
            mondrian.colors(ii,1:3) = colorOpts(randi(6),:);
            mondrian.colors(ii,4) = 1;  % Alpha channel
        end
        
        % Use a large big grey rect for fading out
        mondrian.rect(end,:) = frame;
        mondrian.colors(end,1:3) = 0.5;
        mondrian.colors(end,4) = 0;
    end
end