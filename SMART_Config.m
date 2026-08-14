%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SMART_Config    Define the configuration parameters used throughout SMART
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function cfg = SMART_Config(projectRoot)
    
    % Project folders
    cfg.projectRoot = projectRoot;
    cfg.designFolder = fullfile(projectRoot,'design');
    cfg.dataFolder = fullfile(projectRoot,'data');
    
    % Excel spreadsheets used to build the trial tables
    cfg.practiceSpreadsheet = fullfile(cfg.designFolder,'spreadsheet_practice.xlsx');
    cfg.taskSpreadsheet = fullfile(cfg.designFolder,'spreadsheet_task.xlsx');
    cfg.generalizationSpreadsheet = fullfile(cfg.designFolder,'spreadsheet_generalization.xlsx');
    
    % Folders containing the audio stimuli for each phase
    cfg.practiceSoundFolder = fullfile(projectRoot,'flac_practice');
    cfg.taskSoundFolder = fullfile(projectRoot,'flac_task');
    cfg.generalizationSoundFolder = fullfile(projectRoot,'flac_generalization');
    
    % File used to balance participants across experimental conditions
    cfg.assignmentFile = fullfile(cfg.dataFolder,'ISI_Assignments.csv');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Display configuration
    cfg.displayEnvironment = 'laptop';   % 'laptop' or 'laboratory'
    
    % Screen numbers used by PTB
    cfg.laptopScreenNumber = 0;          % Laptop built-in display
    cfg.laboratoryScreenNumber = 2;      % VIEWPixx stimulus display
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % RGB colors used throughout the experiment
    cfg.backgroundColor = uint8([128 128 128]);
    cfg.textColor = uint8([0 0 0]);
    cfg.redXColor = uint8([255 0 0]);
    cfg.boxBorderColor = uint8([0 0 0]);
    
    % Responses are ordered from left to right. Keyboard responses follow the same left to right order
    cfg.responseNames = {'Yellow','Green','Blue','Red'};
    cfg.responseKeys = {'d','f','j','k'};

    % Colors associated to each keyboard response, from left to right
    cfg.responseColors = uint8([ ...
        200 200   0; ...
          0 200   0; ...
          0   0 200; ...
        200   0   0]);
    
    % RESPONSEPixx values are assumed to match the first four buttons of the
    % five-button controller. Verify them with the four-button controller.
    cfg.buttonInputs = [ ...
        hex2dec('000D'), ... % Yellow
        hex2dec('000B'), ... % Green
        hex2dec('0007'), ... % Blue
        hex2dec('000E')];    % Red
    
    % Digital output values used to illuminate each RESPONSEPixx button
    cfg.ledOutputs = [ ...
        hex2dec('00020000'), ... % Yellow
        hex2dec('00040000'), ... % Green
        hex2dec('00080000'), ... % Blue
        hex2dec('00010000')];    % Red

    cfg.buttonReleaseState = hex2dec('000F');
    cfg.buttonMask = hex2dec('000F');
    
    % Pixel Mode trial triggers (red channel)
    cfg.trigger.practice = uint8([16 0 0]);
    cfg.trigger.task = uint8([32 0 0]);
    cfg.trigger.violation = uint8([64 0 0]);
    cfg.trigger.generalization = uint8([128 0 0]);
    
    % Pixel Mode response triggers (green channel)
    cfg.trigger.response = uint8([ ...
          0  16 0; ...
          0  32 0; ...
          0  64 0; ...
          0 128 0]);
    
    % Pixel Mode pixel presentation settings
    cfg.triggerBaseline = uint8([0 0 0]); % Idle value (black)
    cfg.triggerSquare = [0 0 5 5]; % 6x6 pixel size (square)
    cfg.triggerFrames = 3; % Amount of frames the pixel is held on screen
    
    % Experiment structure
    cfg.nTaskBlocks = 9; % Number of blocks durint task, increased to 9
    cfg.violationBlock = 7; % Block containing random-sequence violations
    cfg.practiceTrials = 8; % Number of practice trials
    cfg.taskTrialsPerBlock = 48; % Trials per task block
    cfg.generalizationTrials = 96; % Total number of generalization trials
    cfg.generalizationRepetitions = 2; % Number of randomized passes through the generalization design
    
    % Timing parameters
    cfg.isiConditionsMs = [0 250 500 1100]; % Possible sound-to-target ISIs (ms)
    cfg.intertrialInterval = 1.0; % Delay before each trial (s)
    cfg.slowThreshold = 1.5; % Delays above this are flagged (s)
    cfg.slowWarningDuration = 1.5; % Duration of the "Too slow" message (s)
    
    % Display layout (expressed as fractions of the screen size)
    cfg.boxWidthRatio = 0.14; % Width of each vertical rectangle
    cfg.boxHeightRatio = 0.36; % Height of each response box
    cfg.boxGapRatio = 0.016; % Horizontal spacing between boxes
    cfg.boxCenterYRatio = 0.44; % Vertical position of the boxes
    cfg.boxBorderWidth = 8; % Border thickness (pixels)
    cfg.responseCircleDiameterRatio = 0.035; % Diameter of the colored button circles
    cfg.responseCircleGapRatio = 0.055; % Distance between boxes and buttons
    cfg.xFontRatio = 0.095; % Size of the red X
    cfg.instructionFontRatio = 0.036; % Main instruction font
    cfg.smallFontRatio = 0.036; % Secondary instruction font
    
    % Generalization progress bar
    cfg.progressBarWidthRatio = 0.70;
    cfg.progressBarHeightRatio = 0.025;
    cfg.progressBarYRatio = 0.90;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Audio initialization and timing    
    % Babyface and Realtek values were validated using
    % viewpixx_audio_latency_test.m. Revalidate these values if the audio
    % hardware or its configuration changes.
    cfg.babyfaceLagCompensation = 0.005;       % Babyface WASAPI @ 512 samples
    cfg.realtekLagCompensation = -0.028;       % Realtek WASAPI
    
    % SMART audio files contain 50 ms of silence before audible sound onset
    cfg.leadingSilenceCompensation = 0.050;    % 50 ms FileStart -> FirstAudio
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % PTB settings
    cfg.skipSyncTestsVisualization = 1; % Skip timing tests while developing (specific for the laptop)
    cfg.skipSyncTestsFullPipeline = 0; % Run timing tests during experiments (specific for the ViewPixx)
    cfg.visualDebugLevel = 0; % Disable PTB startup splash screens
    
    % Timing precision
    cfg.startLeadTime = 0.200; % Schedule flips and audio 200 ms in advance
    
    % Practice passing criteria
    cfg.practiceRequiresPerfectAccuracy = true;
    cfg.practiceRequiresTimelyResponses = true;
    
    % Miscellaneous settings
    cfg.maxInstructionWidth = 80;
    cfg.saveEveryTrial = true;
end
