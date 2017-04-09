function Logger = runBlock(Params, Block)
% This script runs a block of trials, and updates the
% Logger structure.

% try
    % Choose only relevant stimuli
    Images = Params.Images(strcmp(Params.Images.label, Block.stimLabel),:);
    Images.Properties.RowNames = Images.filename;
    
    % Make a trial plan
    Plan = trialPlanner();  % See below
    
    % Preallocate Logger struct
    Logger = struct('Subject',[],'Trial',[],'Type',[],'Stimulus',[],...
        'Eye',[],'Location',[],'Response',[],'RT',[],'Acc',[]);
    Logger(length(Plan)).Trial = NaN;
    
    % Add trial data to general Logger
    for jj = transpose(intersect(fieldnames(Logger),fieldnames(Plan)))
        for trl = 1:NTrials
            Logger = setfield(Logger,{trl},jj{:},...
                getfield(Plan,{trl},jj{:}));
        end
    end
    
    % Up the priority
    Priority(1);
    
    % Trial loop
    ITIStart = GetSecs();   % When did the ITI start
    for trl = 1:length(Plan)
        
        Trial = Plan(trl);
        
        % Make texture
        Trial.stimHandle = Screen('MakeTexture', Params.w, ...
            Images{Trial.Stimulus, 'image'}{:});
        
        % Wait ITI
        WaitSecs(Params.ITI() - (GetSecs() - ITIStart));
        
        % Do Trial
        switch Trial.Type
            case 'bCFS'
                data = doTrial(Params,Trial);
            case {'hard conscious control','static conscious control'}
                data = doTrialHardConsc(Params,Trial);
            case 'just stimulus'
                data = doTrialJustStim(Params,Trial);
            case 'monocular conscious control'
                data = doTrialMonocConsc(Params,Trial);
        end
        ITIStart = GetSecs();
        
        % Add trial data to general Logger
        for jj = transpose(fieldnames(data))
            Logger = setfield(Logger,{trl},jj{:},getfield(data,jj{:}));
        end
        
        % Close stimuli textures to save memory
        Screen('Close', Trial.stimHandle);
        
        % Take a break if needed
        if ~(mod(trl, Params.breakEvery)) && trl~=length(Block)
            doInstructions(Params, Params.breakMessage);
        end
    end
    
% catch
%     Priority(0);
%     return % Make sure partial Logger is returned to global workspace if errors
% end

%% Auxillary functions
    function Plan = trialPlanner()
        % Allow for single trial type
        if ~iscell(Block.trialType);
            Block.trialType = {Block.trialType};
        end;
        
        % Get relevant file names for this block from csv
        stimuli = Images.filename(strcmp(Images.label,Block.stimLabel));
        
        % Random eye and location
        NTrials = length(Block.trialType) * Block.repetitions * length(stimuli);
        
        % Preallocate
        Plan = struct('Subject',[],'Trial',[],'Type',[],'Stimulus',[],...
            'Eye',[],'Location',[]);
        Plan(NTrials).trial ...
            = NaN;
        count = 1;
        for type = 1:length(Block.trialType)
            
            % randomly assign location and eye (if applicable) within
            % condition
            locations = Shuffle([ones(1,ceil(Block.repetitions * length(stimuli)/2)) ...
                zeros(1,floor(Block.repetitions * length(stimuli)/2))] + 9);
            if strcmp(Block.trialType{type}, 'bCFS') || ...
                    strcmp(Block.trialType{type}, 'monocular conscious control')
                eyes = Shuffle(locations)-9;
            else
                eyes = NaN(size(locations));
            end
            
            % Assign values to trials
            for rep = 1:Block.repetitions
                startBlock = count;
                for stim = 1:length(stimuli)
                    Plan(count).Subject = Params.subjectNumber;
                    Plan(count).Stimulus = Images.filename{stim};
                    Plan(count).Type = Block.trialType{type};
                    Plan(count).Eye = eyes(count - startBlock + 1);
                    Plan(count).Location = locations(count - startBlock + 1);
                    
                    count = count+1;
                end
                % Shuffle keeping block order
                Plan(startBlock:count-1) = Shuffle(Plan(startBlock:count-1));
            end
        end
        
        for ii = 1:length(Plan); Plan(ii).Trial = ii; end;
    end

end