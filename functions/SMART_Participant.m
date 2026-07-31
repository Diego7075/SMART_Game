%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SMART_Participant
%
% LoadSMARTTrials             Load and organize the SMART trial tables
% AssignParticipantConditions Assign the participant to one experimental condition
% InitializeResults           Create the structures used to store the experiment results
% SaveSMARTResults            Save the experiment results
% UpdateParticipantCompletion Mark a participant as completed or aborted
% RequestParticipantID        Request a valid participant ID
%
% BuildTrialTable             Build the practice and task trial tables
% BuildGeneralizationTable    Build the generalization trial table
% MapCategoryToResponse       Convert a category into its expected response
% MakeTrialResult             Store one trial as a behavioral table row
% AddEvent                    Store one Pixel Mode event
%
% EmptyTrialResults           Create an empty behavioral results table
% EmptyEventResults           Create an empty event table
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = SMART_Participant(action,varargin)
    switch action
    
        case 'LoadSMARTTrials'
            [varargout{1:nargout}] = LoadSMARTTrials(varargin{:});
    
        case 'AssignParticipantConditions'
            [varargout{1:nargout}] = AssignParticipantConditions(varargin{:});
    
        case 'InitializeResults'
            [varargout{1:nargout}] = InitializeResults(varargin{:});
    
        case 'SaveSMARTResults'
            [varargout{1:nargout}] = SaveSMARTResults(varargin{:});
    
        case 'UpdateParticipantCompletion'
            [varargout{1:nargout}] = UpdateParticipantCompletion(varargin{:});
    
        case 'RequestParticipantID'
            [varargout{1:nargout}] = RequestParticipantID(varargin{:});
    
        case 'BuildTrialTable'
            [varargout{1:nargout}] = BuildTrialTable(varargin{:});
    
        case 'BuildGeneralizationTable'
            [varargout{1:nargout}] = BuildGeneralizationTable(varargin{:});
    
        case 'MapCategoryToResponse'
            [varargout{1:nargout}] = MapCategoryToResponse(varargin{:});
    
        case 'MakeTrialResult'
            [varargout{1:nargout}] = MakeTrialResult(varargin{:});
    
        case 'AddEvent'
            [varargout{1:nargout}] = AddEvent(varargin{:});
    
        case 'EmptyTrialResults'
            [varargout{1:nargout}] = EmptyTrialResults(varargin{:});
    
        case 'EmptyEventResults'
            [varargout{1:nargout}] = EmptyEventResults(varargin{:});
    
        otherwise
            error('Unknown SMART_Participant function: %s',action);
    end
end

function trials = LoadSMARTTrials(cfg,assignment)
    
    % Load the excel spreadsheets
    practiceRaw = readtable(cfg.practiceSpreadsheet, 'Sheet','task','TextType','string','VariableNamingRule','preserve');
    taskRaw = readtable(cfg.taskSpreadsheet, 'Sheet','task','TextType','string','VariableNamingRule','preserve');
    generalizationRaw = readtable(cfg.generalizationSpreadsheet, 'Sheet','task','TextType','string','VariableNamingRule','preserve');
    
    % Keep only the rows used by the experiment
    practiceRows = strcmpi(practiceRaw.display,'practice');
    taskRows = strcmpi(taskRaw.display,'trials');
    generalizationRows = strcmpi(generalizationRaw.display,'trial');
    
    % Build the trial tables for each experimental phase
    allTask = SMART_Participant('BuildTrialTable',taskRaw(taskRows,:),cfg.taskSoundFolder,'task',assignment.mapping);
    trials.practice = SMART_Participant('BuildTrialTable',practiceRaw(practiceRows,:),cfg.practiceSoundFolder,'practice',assignment.mapping);
    trials.task = allTask(allTask.Block ~= cfg.violationBlock,:);   
    trials.violation = allTask(allTask.Block == cfg.violationBlock,:);
    trials.generalization = SMART_Participant('BuildGeneralizationTable',generalizationRaw(generalizationRows,:), ...
        cfg.generalizationSoundFolder,assignment.mapping);
    
    % Check that every phase contains the expected number of trials
    if height(trials.practice) ~= cfg.practiceTrials
        error('Expected %d practice trials, but found %d',cfg.practiceTrials,height(trials.practice));
    end
    
    for block = 1:cfg.nTaskBlocks
        if block == cfg.violationBlock
            nTrials = sum(trials.violation.Block == block);
        else
            nTrials = sum(trials.task.Block == block);
        end
    
        if nTrials ~= cfg.taskTrialsPerBlock
            error('Task block %d contains %d trials instead of %d',block,nTrials,cfg.taskTrialsPerBlock);
        end
    end
    
    if height(trials.generalization) * cfg.generalizationRepetitions ~= cfg.generalizationTrials
        error('Generalization rows and repetitions do not produce %d trials',cfg.generalizationTrials);
    end
end

function assignment = AssignParticipantConditions(cfg,participantID)

    % Load the participant assignment table
    if ~exist(cfg.dataFolder,'dir')
        mkdir(cfg.dataFolder);
    end

    if exist(cfg.assignmentFile,'file')
        assignments = readtable(cfg.assignmentFile,'TextType','string');
    else
        assignments = table(strings(0,1),zeros(0,1),strings(0,1),strings(0,1), NaT(0,1),strings(0,1),'VariableNames', ...
            {'ParticipantID','ISI_ms','Mapping','Status','AssignedAt','RandomSeed'});
    end

    % Reuse the previous assignment if this participant already exists
    existing = find(strcmp(strtrim(string(assignments.ParticipantID)),strtrim(string(participantID))),1);

    if ~isempty(existing)
        assignment.isiMs = assignments.ISI_ms(existing);
        assignment.mapping = assignments.Mapping(existing);
        assignment.randomSeed = assignments.RandomSeed(existing);
        return
    end

    % Count how many participants have been assigned to each condition
    mappingOptions = ["AXBY","BYAX","YBXA","XAYB"];
    cellCounts = zeros(numel(cfg.isiConditionsMs),numel(mappingOptions));

    for isi = 1:numel(cfg.isiConditionsMs)
        for map = 1:numel(mappingOptions)
            cellCounts(isi,map) = sum(assignments.ISI_ms == cfg.isiConditionsMs(isi) & strcmp(assignments.Mapping, ...
                mappingOptions(map)) & assignments.Status ~= "aborted");
        end
    end

    % Randomly choose one of the least represented conditions
    minimumCount = min(cellCounts(:));
    [row,col] = find(cellCounts == minimumCount);
    selected = randi(numel(row));

    assignment.isiMs = cfg.isiConditionsMs(row(selected));
    assignment.mapping = mappingOptions(col(selected));
    assignment.randomSeed = randi([1 intmax('uint32')]);

    % Save the new assignment
    newRow = table(string(participantID),assignment.isiMs,assignment.mapping,"pending",datetime('now'),string(assignment.randomSeed), ...
        'VariableNames',assignments.Properties.VariableNames);
    assignments = [assignments; newRow];

    writetable(assignments,cfg.assignmentFile);

    fprintf('Assigned ISI: %d ms\n',assignment.isiMs);
    fprintf('Assigned mapping: %s\n',assignment.mapping);
end

function results = InitializeResults(cfg,mode,participantID,assignment,state)
    
    % Store the participant information
    results.participantID = string(participantID);
    results.mode = string(mode.name);
    results.isiMs = assignment.isiMs;
    results.mapping = assignment.mapping;
    results.randomSeed = assignment.randomSeed;
    results.startedAt = datetime('now');
    results.completedAt = NaT;
    results.completed = false;
    
    % Store the hardware configuration
    results.hardware.screenNumber = state.screenNumber;
    results.hardware.refreshRate = state.refreshRate;
    results.hardware.ifi = state.ifi;
    results.hardware.audioSampleRate = [];
    results.hardware.datapixx = mode.useHardware;
    
    % Create the structures that will store the experiment results
    results.configuration = cfg;
    results.trials = SMART_Participant('EmptyTrialResults');
    results.events = SMART_Participant('EmptyEventResults');
end

function SaveSMARTResults(cfg,results,participantID,completed)
    
    % Create the participant folder if needed
    participantFolder = fullfile(cfg.dataFolder,participantID);
    
    if ~exist(participantFolder,'dir')
        mkdir(participantFolder);
    end
    
    % Save the trial and event data
    baseName = sprintf('SMART_%s',participantID);
    matPath = fullfile(participantFolder,[baseName '.mat']);
    trialPath = fullfile(participantFolder,[baseName '_trials.csv']);
    eventPath = fullfile(participantFolder,[baseName '_events.csv']);
    summaryPath = fullfile(participantFolder,[baseName '_summary.csv']);
    save(matPath,'results','-v7.3');
    writetable(results.trials,trialPath);
    writetable(results.events,eventPath);
    
    % Save a short summary of the session
    summary = table(string(participantID),results.isiMs,results.mapping,string(results.mode),results.startedAt,datetime('now'), ...
        completed,'VariableNames',{'ParticipantID','ISI_ms','Mapping','Mode','StartedAt','LastSavedAt','Completed'});
    writetable(summary,summaryPath);
end

function UpdateParticipantCompletion(cfg,participantID,completed)
    
    if ~exist(cfg.assignmentFile,'file')
        return
    end
    
    % Find this participant in the assignment table
    assignments = readtable(cfg.assignmentFile,'TextType','string');
    row = find(strcmp(strtrim(string(assignments.ParticipantID)),strtrim(string(participantID))),1);
    
    if isempty(row)
        return
    end
    
    if completed
        assignments.Status(row) = "completed";
    else
        assignments.Status(row) = "aborted";
    end
    
    writetable(assignments,cfg.assignmentFile);
end

function participantID = RequestParticipantID(cfg)
    
    participantID = strtrim(input('Participant ID: ','s'));
    
    while isempty(participantID) || isempty(regexp(participantID,'^[A-Za-z0-9_-]+$','once'))
        fprintf('Use only letters, numbers, hyphens, and underscores.\n');
        participantID = strtrim(input('Participant ID: ','s'));
    end
    
    % Warn if this participant already has a data folder
    participantFolder = fullfile(cfg.dataFolder,participantID);
    
    if exist(participantFolder,'dir')
        answer = lower(strtrim(input('This participant folder exists. Resume or overwrite protection remains active. Continue? [y/n]: ','s')));
        if ~strcmp(answer,'y')
            error('Experiment cancelled before initialization');
        end
    end
end

function output = BuildTrialTable(raw,soundFolder,phase,mapping)
    n = height(raw);
    output = table;
    
    % Create the trial table
    output.Phase = repmat(string(phase),n,1);
    output.Block = str2double(raw.block);
    output.SoundFile = raw.sound;
    output.SoundPath = strings(n,1);
    output.Category = lower(raw.category);
    output.CategoryType = lower(raw.category_type);
    output.MappingLabel = lower(raw.mapping);
    output.OriginalCorrectAnswer = str2double(raw.CorrectAnswer);
    output.ExpectedResponse = zeros(n,1);
    
    % Build the information needed for each trial
    for row = 1:n
        output.SoundPath(row) = string(fullfile(soundFolder,char(output.SoundFile(row))));
        if strcmpi(output.Category(row),'rand')
            output.ExpectedResponse(row) = output.OriginalCorrectAnswer(row);
        else
            output.ExpectedResponse(row) = SMART_Participant('MapCategoryToResponse',output.Category(row),mapping);
        end
    end
end

function output = BuildGeneralizationTable(raw,soundFolder,mapping)
    n = height(raw);
    output = table;
    
    % Create the generalization trial table
    output.Phase = repmat("generalization",n,1);
    output.Block = repmat(1,n,1);
    output.SoundFile = raw.GeneralizationSoundFile;
    output.SoundPath = strings(n,1);
    output.Category = lower(raw.Category);
    output.CategoryType = repmat("generalization",n,1);
    output.MappingLabel = repmat("generalization",n,1);
    output.OriginalCorrectAnswer = str2double(raw.CorrectAnswer);
    output.ExpectedResponse = zeros(n,1);
    
    % Build the information needed for each trial
    for row = 1:n
        output.SoundPath(row) = string(fullfile(soundFolder,char(output.SoundFile(row))));
        output.ExpectedResponse(row) = SMART_Participant('MapCategoryToResponse',output.Category(row),mapping);
    end
end

function response = MapCategoryToResponse(category,mapping)
    category = lower(char(category));
    
    switch upper(string(mapping))
    
        case "AXBY"
            categories = {'a','x','b','y'};
    
        case "BYAX"
            categories = {'b','y','a','x'};
    
        case "YBXA"
            categories = {'y','b','x','a'};
    
        case "XAYB"
            categories = {'x','a','y','b'};
    
        otherwise
            error('Unknown mapping: %s',mapping);
    
    end
    
    response = find(strcmp(categories,category),1);
    
    if isempty(response)
        error('Unknown SMART category: %s',category);
    end
end

function result = MakeTrialResult(cfg,trial,phase,blockNumber,trialNumber,expectedResponse,pressedResponse, ...
    correct,reactionTime,slow,earlyPressDetected,soundOnset,soundOffset,responseOnset,pressTime)
    
    result = SMART_Participant('EmptyTrialResults');
    result(1,:) = { ...
        string(phase),blockNumber,trialNumber,NaN, ...
        trial.SoundFile,trial.SoundPath,trial.Category, ...
        expectedResponse,string(cfg.responseNames{expectedResponse}), ...
        pressedResponse,string(cfg.responseNames{pressedResponse}), ...
        correct,reactionTime,slow,earlyPressDetected, ...
        soundOnset,soundOffset,responseOnset,pressTime,trial.MappingLabel};
end

function events = AddEvent(events,timestamp,phase,blockNumber,trialNumber,eventName,trigger,mode)
    
    if mode.useHardware
        source = "PixelMode";
    else
        source = "simulated";
    end
    
    row = table(timestamp,string(phase),blockNumber,trialNumber,string(eventName),double(trigger(1)),double(trigger(2)), ...
        double(trigger(3)),source,'VariableNames',events.Properties.VariableNames);
    events = [events; row];
end

function tableOut = EmptyTrialResults
    
    tableOut = table( ...
        strings(0,1),zeros(0,1),zeros(0,1),zeros(0,1), ...
        strings(0,1),strings(0,1),strings(0,1), ...
        zeros(0,1),strings(0,1),zeros(0,1),strings(0,1), ...
        false(0,1),zeros(0,1),false(0,1),false(0,1), ...
        zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1), ...
        strings(0,1), ...
        'VariableNames',{ ...
        'Phase','Block','TrialInBlock','GlobalTrial', ...
        'SoundFile','SoundPath','Category', ...
        'ExpectedResponse','ExpectedColor','PressedResponse', ...
        'PressedColor','Correct','ReactionTime_s','Slow', ...
        'EarlyPressDetected','SoundOnset_s','SoundOffset_s', ...
        'ResponseOnset_s','ResponsePress_s','MappingLabel'});
end

function tableOut = EmptyEventResults
    
    tableOut = table( ...
        zeros(0,1),strings(0,1),zeros(0,1),zeros(0,1), ...
        strings(0,1),zeros(0,1),zeros(0,1),zeros(0,1), ...
        strings(0,1), ...
        'VariableNames',{ ...
        'Timestamp_s','Phase','Block','TrialInBlock', ...
        'Event','Red','Green','Blue','Source'});
end
