%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SMART_Generalization
%
% RunGeneralizationBlock     Run the complete generalization phase
% RunGeneralizationTrial     Run one generalization trial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = SMART_Generalization(action,varargin)
    switch action
    
        case 'RunGeneralizationBlock'
            [varargout{1:nargout}] = RunGeneralizationBlock(varargin{:});
    
        case 'RunGeneralizationTrial'
            [varargout{1:nargout}] = RunGeneralizationTrial(varargin{:});
    
        otherwise
            error('Unknown SMART_Generalization function: %s',action);
    end
end

function [results,events] = RunGeneralizationBlock(cfg,state,textures,audio,generalizationTrials,mode)
    
    % Initialize the structures that will store trial and event-level data
    results = SMART_Participant('EmptyTrialResults');
    events = SMART_Participant('EmptyEventResults');
    globalTrial = 0;
    
    % Create generalization-specific textures that include the progress bar
    windowWidth = RectWidth(state.windowRect);
    windowHeight = RectHeight(state.windowRect);
    textures.empty = SMART_Initialize('CreateBoxesTexture',state.window,cfg,windowWidth,windowHeight,textures.layout,0,false,true,0,cfg.generalizationTrials);
    textures.generalizationEmpty = SMART_Initialize('CreateBoxesTexture',state.window,cfg,windowWidth,windowHeight,textures.layout,-1,false,true,0,cfg.generalizationTrials);
    
    % Display the initial progress screen before the first trial
    SMART_Display('DrawTextureBaseline',cfg,state,textures.empty);
    Screen('Flip',state.window);
    WaitSecs(1);
    
    for repetition = 1:cfg.generalizationRepetitions
    
        % Randomly select the sound sequences presented in this pass
        order = randperm(height(generalizationTrials));

        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % % Temporary: keep only two trials while testing (comment to nulify)
        % order = order(1:2);
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        for index = 1:numel(order)
    
            globalTrial = globalTrial + 1;
            trial = generalizationTrials(order(index),:);
    
            % Run one randomized generalization trial
            [trialResult,trialEvents] = SMART_Generalization('RunGeneralizationTrial',cfg,state,textures,audio,trial,mode,repetition,index,globalTrial);
    
            results = [results; trialResult];
            events = [events; trialEvents];
    
            % Update the progress bar for the next trial
            Screen('Close',textures.empty);
            Screen('Close',textures.generalizationEmpty);
    
            textures.empty = SMART_Initialize('CreateBoxesTexture',state.window,cfg,windowWidth,windowHeight,textures.layout,0,false,true,globalTrial,cfg.generalizationTrials);
            textures.generalizationEmpty = SMART_Initialize('CreateBoxesTexture',state.window,cfg,windowWidth,windowHeight,textures.layout,-1,false,true,globalTrial,cfg.generalizationTrials);
    
        end
    end
    
    % Release the temporary progress-bar textures
    Screen('Close',textures.empty);
    Screen('Close',textures.generalizationEmpty);

end

function [result,events] = RunGeneralizationTrial(cfg,state,textures,audio,trial,mode,repetition,trialInPass,globalTrial)
    
    % Initialize the trial-specific variables
    events = SMART_Participant('EmptyEventResults');
    phase = 'generalization';
    blockNumber = repetition;
    soundPath = char(trial.SoundPath);
    audioIndex = audio.index(soundPath);
    
    % Prepare the trial and schedule audio playback
    WaitSecs(cfg.intertrialInterval);
    SMART_Task('ClearResponseBuffer',state,mode);
    
    PsychPortAudio('FillBuffer',state.pahandle,audio.waveforms{audioIndex});
    startTime = GetSecs + cfg.startLeadTime;
    PsychPortAudio('Start',state.pahandle,1,startTime,0);
    
    % Present the auditory sequence together with the trial-onset trigger
    [soundOnset,triggerEvents] = SMART_Display('PresentTriggeredTexture',cfg,state,textures.empty,cfg.trigger.generalization,phase,blockNumber,globalTrial,'trial_onset',startTime,mode);
    events = [events; triggerEvents];
    
    earlyPressDetected = false;
    audioStatus = PsychPortAudio('GetStatus',state.pahandle);

    % Monitor for early responses while the sound is playing
    while audioStatus.Active
        earlyPressDetected = earlyPressDetected || SMART_Task('CheckEarlyResponse',state,mode);
        SMART_Task('CheckEscape',state);
        WaitSecs('YieldSecs',0.001);
        audioStatus = PsychPortAudio('GetStatus',state.pahandle);
    end
    
    soundOffset = GetSecs;
    isiFrames = round((cfg.currentISI_ms / 1000) / state.ifi);
    
    % Maintain the blank display during the participant-specific ISI
    for frame = 1:isiFrames
            SMART_Display('DrawTextureBaseline',cfg,state,textures.empty);
        Screen('Flip',state.window);
        earlyPressDetected = earlyPressDetected || SMART_Task('CheckEarlyResponse',state,mode);
    end
    
    % Enable the response buttons and present the response prompt
    SMART_Task('ClearResponseBuffer',state,mode);
    SMART_Task('SetAllResponseLEDs',cfg,state,mode,true);
    
    responseStart = GetSecs + cfg.startLeadTime;
    [responseOnset,responseEvents] = SMART_Display('PresentTriggeredTexture',cfg,state,textures.generalizationEmpty,cfg.trigger.generalization,phase,blockNumber,globalTrial,'response_onset', responseStart,mode);
    events = [events; responseEvents];
    
    % Wait for the participant's button press
    [pressedResponse,pressTime] = SMART_Task('WaitForTrialResponse',cfg,state,mode,responseOnset);
    
    SMART_Task('SetAllResponseLEDs',cfg,state,mode,false);
    
    % Send the response trigger using the selected button
    responseTrigger = cfg.trigger.response(pressedResponse,:);
    [~,pressEvents] = SMART_Display('PresentTriggeredTexture',cfg,state,textures.empty,responseTrigger,phase,blockNumber,globalTrial,'response_press',pressTime,mode);
    events = [events; pressEvents];
    
    % Wait until the participant releases the button
    SMART_Task('WaitForResponseRelease',cfg,state,mode);

    % Compute the behavioral results and store them
    reactionTime = pressTime - responseOnset;
    expectedResponse = trial.ExpectedResponse;
    correct = pressedResponse == expectedResponse;
    slow = false;
    
    result = SMART_Participant('MakeTrialResult',cfg,trial,phase,repetition,globalTrial,expectedResponse,pressedResponse,correct,reactionTime,slow,earlyPressDetected,soundOnset,soundOffset,responseOnset,pressTime);
end
