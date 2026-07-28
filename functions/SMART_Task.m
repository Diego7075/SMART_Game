%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SMART_Task
%
% RunTaskBlock          Run one randomized task block
% RunVisualTargetTrial  Run one visual target trial
%
% SetAllResponseLEDs    Turn all RESPONSEPixx LEDs on or off
% SetResponseLED        Illuminate one RESPONSEPixx button
%
% WaitForAnyResponse    Wait for any valid response
% WaitForTrialResponse  Wait for the participant's response
% WaitForResponseRelease Wait until the response is released
%
% CheckEarlyResponse    Detect responses before the response period
% ClearResponseBuffer   Remove pending responses
% CheckEscape           End the experiment when Escape is pressed
%
% GetTrialTrigger       Return the trigger assigned to one trial phase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = SMART_Task(action,varargin)
    switch action
    
        case 'RunTaskBlock'
            [varargout{1:nargout}] = RunTaskBlock(varargin{:});
    
        case 'RunVisualTargetTrial'
            [varargout{1:nargout}] = RunVisualTargetTrial(varargin{:});
    
        case 'SetAllResponseLEDs'
            [varargout{1:nargout}] = SetAllResponseLEDs(varargin{:});
    
        case 'SetResponseLED'
            [varargout{1:nargout}] = SetResponseLED(varargin{:});
    
        case 'WaitForAnyResponse'
            [varargout{1:nargout}] = WaitForAnyResponse(varargin{:});
    
        case 'WaitForTrialResponse'
            [varargout{1:nargout}] = WaitForTrialResponse(varargin{:});
    
        case 'WaitForResponseRelease'
            [varargout{1:nargout}] = WaitForResponseRelease(varargin{:});
    
        case 'CheckEarlyResponse'
            [varargout{1:nargout}] = CheckEarlyResponse(varargin{:});
    
        case 'ClearResponseBuffer'
            [varargout{1:nargout}] = ClearResponseBuffer(varargin{:});
    
        case 'CheckEscape'
            [varargout{1:nargout}] = CheckEscape(varargin{:});
    
        case 'GetTrialTrigger'
            [varargout{1:nargout}] = GetTrialTrigger(varargin{:});
    
        otherwise
            error('Unknown SMART_Task function: %s',action);
    end
end

function [results,events] = RunTaskBlock(cfg,state,textures,audio,taskTrials,violationTrials,blockNumber,mode)
    
    % Select the trials that belong to this block
    if blockNumber == cfg.violationBlock
        blockTrials = violationTrials(violationTrials.Block == blockNumber,:);
        phase = 'violation';
    else
        blockTrials = taskTrials(taskTrials.Block == blockNumber,:);
        phase = 'task';
    end
    
    % Randomize the trial order within this block
    order = randperm(height(blockTrials));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Temporary: keep only two trials while testing
    order = order(1:2);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Create the structures used to store this block
    results = SMART_Participant('EmptyTrialResults');
    events = SMART_Participant('EmptyEventResults');
    
    % Show the empty display before the first trial
    SMART_Display('DrawTextureBaseline',cfg,state,textures.empty);
    Screen('Flip',state.window);
    WaitSecs(1);
    
    % Run every trial in the randomized order
    for trialNumber = 1:numel(order)
        trial = blockTrials(order(trialNumber),:);
    
        [trialResult,trialEvents] = SMART_Task('RunVisualTargetTrial',cfg,state,textures,audio,trial,mode,phase,blockNumber,trialNumber);
    
        results = [results; trialResult];
        events = [events; trialEvents];
    end
end

function [result,events] = RunVisualTargetTrial(cfg,state,textures,audio,trial,mode,phase,blockNumber,trialNumber)
    
    % Prepare the trial
    events = SMART_Participant('EmptyEventResults');
    expectedResponse = trial.ExpectedResponse;
    soundPath = char(trial.SoundPath);
    audioIndex = audio.index(soundPath);
    
    % Wait for the intertrial interval and prepare the next sound
    WaitSecs(cfg.intertrialInterval);
    SMART_Task('ClearResponseBuffer',state,mode);
    PsychPortAudio('FillBuffer',state.pahandle,audio.waveforms{audioIndex});
    startTime = GetSecs + cfg.startLeadTime;
    PsychPortAudio('Start',state.pahandle,1,startTime,0);
    
    % Present the sound together with the trial-onset trigger
    trialTrigger = SMART_Task('GetTrialTrigger',cfg,phase);
    [soundOnset,triggerEvents] = SMART_Display('PresentTriggeredTexture',cfg,state,textures.empty,trialTrigger,phase,blockNumber,trialNumber,'trial_onset',startTime,mode);
    events = [events; triggerEvents];

    % Monitor for responses while the sound is playing
    earlyPressDetected = false;
    
    audioStatus = PsychPortAudio('GetStatus',state.pahandle);
    while audioStatus.Active
        earlyPressDetected = earlyPressDetected || SMART_Task('CheckEarlyResponse',state,mode);
        SMART_Task('CheckEscape',state);
        WaitSecs('YieldSecs',0.001);
        audioStatus = PsychPortAudio('GetStatus',state.pahandle);
    end
    
    % Wait through the participant-specific ISI
    soundOffset = GetSecs;
    isiFrames = round((cfg.currentISI_ms / 1000) / state.ifi);
    
    for frame = 1:isiFrames
        SMART_Display('DrawTextureBaseline',cfg,state,textures.empty);
        Screen('Flip',state.window);
        earlyPressDetected = earlyPressDetected || SMART_Task('CheckEarlyResponse',state,mode);
    end
    
    % Enable the expected response and present the visual target
    SMART_Task('ClearResponseBuffer',state,mode);
    SMART_Task('SetResponseLED',cfg,state,mode,expectedResponse);
    
    responseStart = GetSecs + cfg.startLeadTime;
    [responseOnset,responseEvents] = SMART_Display('PresentTriggeredTexture',cfg,state,textures.target(expectedResponse),trialTrigger,phase, ...
        blockNumber,trialNumber,'response_onset',responseStart,mode);
    events = [events; responseEvents];
    
    % Wait for the participant's response
    [pressedResponse,pressTime] = SMART_Task('WaitForTrialResponse',cfg,state,mode,responseOnset);
    SMART_Task('SetResponseLED',cfg,state,mode,0);
    
    % Send the response trigger
    responseTrigger = cfg.trigger.response(pressedResponse,:);
    [~,pressEvents] = SMART_Display('PresentTriggeredTexture',cfg,state,textures.target(expectedResponse),responseTrigger,phase, ...
        blockNumber,trialNumber,'response_press',pressTime,mode);
    events = [events; pressEvents];
    
    % Wait until the response button is released
    SMART_Task('WaitForResponseRelease',cfg,state,mode);
    
    % Compute the trial outcome
    reactionTime = pressTime - responseOnset;
    correct = pressedResponse == expectedResponse;
    slow = reactionTime > cfg.slowThreshold;
    
    % Warn the participant after slow responses
    if slow
        SMART_Display('DrawTextureBaseline',cfg,state,textures.slow);
        Screen('Flip',state.window);
        WaitSecs(cfg.slowWarningDuration);
    end
    
    % Store the trial results
    result = SMART_Participant('MakeTrialResult',cfg,trial,phase,blockNumber,trialNumber,expectedResponse,pressedResponse,correct,reactionTime,slow, ...
        earlyPressDetected,soundOnset,soundOffset,responseOnset,pressTime);
    
    % Restore the empty display
    SMART_Display('DrawTextureBaseline',cfg,state,textures.empty);
    Screen('Flip',state.window);
end

function SetAllResponseLEDs(cfg,state,mode,enabled)
    
    % Turn all RESPONSEPixx LEDs on or off
    if ~mode.useHardware
        return
    end
    
    if enabled
        output = sum(cfg.ledOutputs);
    else
        output = 0;
    end
    
    Datapixx('SetDinDataOut',output);
    Datapixx('RegWrRd');
end

function SetResponseLED(cfg,state,mode,response)
    
    % Illuminate one RESPONSEPixx button
    if ~mode.useHardware
        return
    end
    
    if response == 0
        output = 0;
    else
        output = cfg.ledOutputs(response);
    end
    
    Datapixx('SetDinDataOut',output);
    Datapixx('RegWrRd');
end

function WaitForAnyResponse(cfg,state,mode)
    
    % Wait for any response and then for its release
    if mode.useHardware
        SMART_Task('ClearResponseBuffer',state,mode);
    
        pressed = false;
        while ~pressed
            Datapixx('RegWrRd');
            status = Datapixx('GetDinStatus');
    
            if status.newLogFrames > 0
                data = Datapixx('ReadDinLog');
                pressed = any(ismember(data,cfg.buttonInputs));
                Datapixx('SetDinLog');
                Datapixx('RegWrRd');
            end
    
            SMART_Task('CheckEscape',state);
            WaitSecs('YieldSecs',0.001);
        end
    
        released = false;
        while ~released
            Datapixx('RegWrRd');
            status = Datapixx('GetDinStatus');
    
            if status.newLogFrames > 0
                data = Datapixx('ReadDinLog');
                released = any(data == hex2dec('FFFF'));
                Datapixx('SetDinLog');
                Datapixx('RegWrRd');
            end
    
            SMART_Task('CheckEscape',state);
            WaitSecs('YieldSecs',0.001);
        end
    else
        KbReleaseWait;
    
        while true
            [keyDown,~,keyCode] = KbCheck;
    
            if keyDown && keyCode(state.escapeKey)
                error('Experiment terminated by the user');
            elseif keyDown && any(keyCode(state.keyboardKeys))
                break
            end
    
            WaitSecs('YieldSecs',0.001);
        end
    
        KbReleaseWait;
    end
end

function [response,pressTime] = WaitForTrialResponse(cfg,state,mode,responseOnset)
    
    % Wait for the participant's response
    response = [];
    pressTime = NaN;
    
    if mode.useHardware
        Datapixx('SetDinLog');
        Datapixx('RegWrRd');
    
        while isempty(response)
            Datapixx('RegWrRd');
            status = Datapixx('GetDinStatus');
    
            if status.newLogFrames > 0
                [data,timetags] = Datapixx('ReadDinLog');
    
                for event = 1:numel(data)
                    candidate = find(cfg.buttonInputs == data(event),1);
    
                    if ~isempty(candidate)
                        response = candidate;
                        pressTime = timetags(event) + state.datapixxToGetSecsOffset;
                        break
                    end
                end
    
                Datapixx('SetDinLog');
                Datapixx('RegWrRd');
            end
    
            SMART_Task('CheckEscape',state);
            WaitSecs('YieldSecs',0.001);
        end
    else
        KbReleaseWait;
    
        while isempty(response)
            [keyDown,time,keyCode] = KbCheck;
    
            if keyDown
                candidate = find(keyCode(state.keyboardKeys),1);
    
                if ~isempty(candidate)
                    response = candidate;
                    pressTime = time;
                elseif keyCode(state.escapeKey)
                    error('Experiment terminated by the user');
                end
            end
    
            WaitSecs('YieldSecs',0.001);
        end
    end
    
    if pressTime < responseOnset
        error('A response was timestamped before response onset');
    end
end

function releaseTime = WaitForResponseRelease(cfg,state,mode)
    
    % Wait until the selected response is released
    releaseTime = NaN;
    
    if mode.useHardware
        Datapixx('SetDinLog');
        Datapixx('RegWrRd');
    
        while isnan(releaseTime)
            Datapixx('RegWrRd');
            status = Datapixx('GetDinStatus');
    
            if status.newLogFrames > 0
                [data,timetags] = Datapixx('ReadDinLog');
                released = find(data == hex2dec('FFFF'),1);
    
                if ~isempty(released)
                    releaseTime = timetags(released) + state.datapixxToGetSecsOffset;
                end
    
                Datapixx('SetDinLog');
                Datapixx('RegWrRd');
            end
    
            SMART_Task('CheckEscape',state);
            WaitSecs('YieldSecs',0.001);
        end
    else
        while true
            [keyDown,~,keyCode] = KbCheck;
    
            if keyDown && keyCode(state.escapeKey)
                error('Experiment terminated by the user');
            elseif ~keyDown
                break
            end
    
            WaitSecs('YieldSecs',0.001);
        end
    
        releaseTime = GetSecs;
    end
end

function detected = CheckEarlyResponse(state,mode)
    
    % Detect responses before the response period
    detected = false;
    
    if mode.useHardware
        Datapixx('RegWrRd');
        status = Datapixx('GetDinStatus');
    
        if status.newLogFrames > 0
            data = Datapixx('ReadDinLog');
            detected = any(data ~= hex2dec('FFFF'));
            Datapixx('SetDinLog');
            Datapixx('RegWrRd');
        end
    else
        [keyDown,~,keyCode] = KbCheck;
        detected = keyDown && any(keyCode(state.keyboardKeys));
    end
end

function ClearResponseBuffer(state,mode)
    
    % Clear responses from the previous trial
    if mode.useHardware
        Datapixx('SetDinLog');
        Datapixx('RegWrRd');
    else
        KbReleaseWait;
    end
end

function CheckEscape(state)
    
    % End the experiment when Escape is pressed
    [keyDown,~,keyCode] = KbCheck;
    
    if keyDown && keyCode(state.escapeKey)
        error('Experiment terminated by the user');
    end
end

function trigger = GetTrialTrigger(cfg,phase)
    
    % Return the trigger assigned to one trial phase
    switch lower(phase)
        case 'practice'
            trigger = cfg.trigger.practice;
        case 'task'
            trigger = cfg.trigger.task;
        case 'violation'
            trigger = cfg.trigger.violation;
        case 'generalization'
            trigger = cfg.trigger.generalization;
        otherwise
            error('Unknown trial phase: %s',phase);
    end
end
