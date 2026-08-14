%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SMART
%
% This script coordinates the complete experimental workflow. It selects
% the execution mode and audio output, loads the participant assignment,
% initializes the visual and auditory hardware, executes the three phases
% (practice, learning task, and generalization), saves participant data,
% and performs a controlled shutdown after successful completion or error
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sca;
clear;
clc;

% Locate directory and make all functions (within the functions folder) available
projectRoot = fileparts(mfilename('fullpath'));
functionsFolder = fullfile(projectRoot,'functions');

if exist(functionsFolder,'dir')
    addpath(functionsFolder);
end

% Load the experiment configuration
cfg = SMART_Config(projectRoot);

% Ask whether to use laptop visualization or the complete hardware chain
% and to run the quick test or complete experiment
mode = SMART_Initialize('SelectExecutionMode');

try

    % Select and initialize the audio output before participant setup
    [audioCfg,pahandle] = initialize_audio_output;

    % Request a valid participant identifier and prevent unsafe filenames
    participantID = SMART_Participant('RequestParticipantID',cfg);

    % Assign the participant to the least represented ISI x mapping condition
    % and generate the participant-specific randomization seed
    assignment = SMART_Participant('AssignParticipantConditions',cfg,participantID);
    cfg.currentISI_ms = assignment.isiMs;
    rng(assignment.randomSeed,'twister');

    % Load all trial definitions (practice, task, generalization) from Excel spreadsheets
    trials = SMART_Participant('LoadSMARTTrials',cfg,assignment);

    % Preload the audio stimuli into memory
    audio = SMART_Initialize('LoadSMARTAudio',trials);

    % Initialize PTB and the selected hardware pipeline
    state = SMART_Initialize('InitializeSMART', ...
        cfg,mode,audio.sampleRate,audioCfg,pahandle);

    % Generate the graphical textures
    textures = SMART_Initialize('CreateSMARTTextures',cfg,state);

    % Create the structures that will store trial and event-level data
    results = SMART_Participant('InitializeResults',cfg,mode,participantID,assignment,state);

    % Display the practice instructions and run the practice phase
    SMART_Display('ShowExperimentInstructions',cfg,state,textures,mode);
    [practiceResults,practiceEvents] = SMART_Practice('RunPracticeBlock',cfg,state,textures,audio,trials.practice,mode);
    results.trials = [results.trials; practiceResults];
    results.events = [results.events; practiceEvents];
    SMART_Participant('SaveSMARTResults',cfg,results,participantID,false);

    % Display the task instructions and run each task block
    SMART_Display('ShowTaskInstructions',cfg,state,textures,mode);

    for blockNumber = 1:cfg.nTaskBlocks

        % Run one learning block at a time and append its trial and event data
        [blockResults,blockEvents] = SMART_Task('RunTaskBlock',cfg,state,textures, ...
            audio,trials.task,trials.violation,blockNumber,mode);
        results.trials = [results.trials; blockResults];
        results.events = [results.events; blockEvents];
        SMART_Participant('SaveSMARTResults',cfg,results,participantID,false);

        if blockNumber < cfg.nTaskBlocks
            SMART_Display('ShowBlockBreak',cfg,state,textures,mode,blockNumber);
        end

    end

    % Display the generalization instructions and run the generalization phase
    SMART_Display('ShowGeneralizationInstructions',cfg,state,textures,mode);
    [generalizationResults,generalizationEvents] = SMART_Generalization('RunGeneralizationBlock', ...
        cfg,state,textures,audio,trials.generalization,mode);
    results.trials = [results.trials; generalizationResults];
    results.events = [results.events; generalizationEvents];
    results.completed = true;
    results.completedAt = datetime('now');

    % Save the completed dataset and mark the participant as finished
    SMART_Participant('SaveSMARTResults',cfg,results,participantID,true);
    SMART_Participant('UpdateParticipantCompletion',cfg,participantID,true);

    % Finalize the experiment by displaying the end screen and shutting down
    SMART_Display('ShowEndScreen',cfg,state,textures,mode);
    SMART_Initialize('ShutdownSMART',state,textures);

% In case of failure or interruption...
catch ME

    % Preserve partial data and restore the system before rethrowing the error
    try
        SMART_Participant('SaveSMARTResults',cfg,results,participantID,false);
    catch
    end

    try
        SMART_Participant('UpdateParticipantCompletion',cfg,participantID,false);
    catch
    end

    try
        SMART_Initialize('ShutdownSMART',state,textures);
    catch
        sca;
    end

    % If initialization failed before state was created, close the audio
    % device that was opened during startup
    if ~exist('state','var') && exist('pahandle','var')
        try
            PsychPortAudio('Close',pahandle);
        catch
        end
    end

    rethrow(ME);

end
