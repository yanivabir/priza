function Data = doTrialHardConsc(Params, Trial)
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
mondrian = createMondrian();   % Create mask for first frame
terminate = 0;  % Assisting variable
thisFrame = 1;  % Frame counter
startTime = GetSecs();  % Time of trial start
while thisFrame <= maxFrame && ~terminate
    
    for side = [0, 1]
        
        % Select masked-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', Params.w, side);
        
        % Draw mask:
        Screen('FillRect',Params.w, mondrian.colors', ...
            mondrian.rect(:,:,side+1)');
        
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
    
    % Compute mask for next frame:
    if strcmp(Trial.Type, 'hard conscious control')
        if ~mod(thisFrame, time2flips(Params, 1 / Params.mondrian.Hz))
            mondrian = createMondrian();
        end
    end
    
    % Compute mask alpha for next frame:
    if maxFrame < inf
        % If there is a time cut off to the trial
        maskAlpha = 1 - min((maxFrame - (thisFrame + 1)) / ...
            time2flips(Params, Params.mondrian.fadeOutTime),1);
        mondrian.colors(end,4) = maskAlpha;
    end
     
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

    function mondrian = createMondrian()
        % Rectangle sizes
        dx = angle2pix(Params.Display,Params.mondrian.width);
        dy = angle2pix(Params.Display,Params.mondrian.height);
        
        % Possible colours
        colorOpts = [eye(3); 1-eye(3)];
        
        % Preallocate
        mondrian.rect = zeros(Params.mondrian.rectNum+1,4,2);
        for l = 0:1
            
            % Where to draw the rects
            frame = CenterRectCalib(Params,angle2pix(Params.Display,...
                [0 0 Params.frame.width Params.frame.height]), l);
            
            locRect = frame - [dx, dy, 0, 0];
            
            % Draw same rects on both sides
            if l == 0
                randRect = [randi(locRect(3) - locRect(1),Params.mondrian.rectNum,1)...
                    randi(locRect(4) - locRect(2),Params.mondrian.rectNum,1)...
                    randi(dx, Params.mondrian.rectNum, 1)...
                    randi(dy, Params.mondrian.rectNum, 1)];
            end
            
            % Randomly draw rects
            for ii = 1:Params.mondrian.rectNum
                mondrian.rect(ii,1,l+1) = max(randRect(ii,1) + locRect(1),...
                    frame(1));
                mondrian.rect(ii,2,l+1) = max(randRect(ii,2) + locRect(2),...
                    frame(2));
                mondrian.rect(ii,3,l+1) = min(mondrian.rect(ii,1,l+1) + randRect(ii,3) + dx, ...
                    frame(3));
                mondrian.rect(ii,4,l+1) = min(mondrian.rect(ii,2,l+1) + randRect(ii,4) + dy,...
                    frame(4));
            end
            
            % Use a large big grey rect for fading out
            mondrian.rect(end,:,l+1) = frame;
            
        end
        
        % Draw colors randomly
        mondrian.colors = zeros(Params.mondrian.rectNum+1,4);
        for ii = 1:Params.mondrian.rectNum
            mondrian.colors(ii,1:3) = colorOpts(randi(6),:);
            mondrian.colors(ii,4) = 1;  % Alpha channel
        end
        
        % Colors and alpha for fade out
        mondrian.colors(end,1:3) = 0.5;
        mondrian.colors(end,4) = 0;
    end
end