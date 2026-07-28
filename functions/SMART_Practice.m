%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SMART_Practice
%
% RunPracticeBlock    Run the practice block until the participant passes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = SMART_Practice(action,varargin)
    switch action
    
        case 'RunPracticeBlock'
            [varargout{1:nargout}] = RunPracticeBlock(varargin{:});
    
        otherwise
            error('Unknown SMART_Practice function: %s',action);
    end
end

function [results,events] = RunPracticeBlock(cfg,state,textures,audio,practiceTrials,mode)

    % Create the structures used to store the practice results
    results = SMART_Participant('EmptyTrialResults');
    events = SMART_Participant('EmptyEventResults');
    attempt = 0;
    passed = false;

    % Show the empty display before the first practice attempt
    SMART_Display('DrawTextureBaseline',cfg,state,textures.empty);
    Screen('Flip',state.window);
    WaitSecs(1);
    
    % Repeat the practice block until the participant passes
    while ~passed
        attempt = attempt + 1;
        order = randperm(height(practiceTrials));
        attemptResults = SMART_Participant('EmptyTrialResults');
        attemptEvents = SMART_Participant('EmptyEventResults');
    
        % Run every practice trial in a random order
        for trialNumber = 1:numel(order)
            trial = practiceTrials(order(trialNumber),:);
    
            [trialResult,trialEvents] = SMART_Task('RunVisualTargetTrial',cfg,state,textures,audio,trial,mode,'practice',attempt,trialNumber);
    
            attemptResults = [attemptResults; trialResult];
            attemptEvents = [attemptEvents; trialEvents];
        end
    
        % Check whether this practice attempt meets the passing criteria
        accurate = all(attemptResults.Correct);
    
        if cfg.practiceRequiresTimelyResponses
            timely = all(~attemptResults.Slow);
        else
            timely = true;
        end
    
        passed = accurate && timely;
        results = [results; attemptResults];
        events = [events; attemptEvents];
    
        % Repeat the practice if the participant did not pass
        if ~passed
            SMART_Display('ShowTextureAndWait',cfg,state,textures.practiceRepeat,mode);
        end
    end
end
