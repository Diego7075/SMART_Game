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
    % Screen numbers used by PTB
    cfg.laptopScreenNumber = 0; % Primary monitor used during development (laptop)
    % cfg.laptopScreenNumber = 1; % Primary monitor used during development (desktop)
    cfg.laboratoryScreenNumber = 3; % VIEWPixx stimulus displays
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
        hex2dec('FFFB'), ...
        hex2dec('FFFD'), ...
        hex2dec('FFFE'), ...
        hex2dec('FFF7')];
    
    % Digital output values used to illuminate each RESPONSEPixx button
    cfg.ledOutputs = [ ...
        hex2dec('00040000'), ...
        hex2dec('00020000'), ...
        hex2dec('00010000'), ...
        hex2dec('00080000')];
    
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
    
    % PsychPortAudio settings
    cfg.audioLatencyClass = 2; % PTB latency mode (higher = lower latency)
    cfg.audioChannels = 2; % Stereo playback
    cfg.audioVolume = 1.0;  % Full playback volume

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PsychPortAudio output
    % cfg.audioDeviceIndex = 1; % PTB chooses the system 48 KHz audio device (headphone jack - desktop)
    cfg.audioDeviceIndex = 2; % PTB chooses the system 48 KHz audio device (speakers - laptop)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % PTB settings
    cfg.skipSyncTestsVisualization = 1; % Skip timing tests while developing (specific for the laptop)
    cfg.skipSyncTestsFullPipeline = 0; % Run timing tests during experiments (specific for the ViewPixx)
    cfg.visualDebugLevel = 0; % Disable PTB startup splash screens
    cfg.conserveVRAM = 16384; % Compatibility flag for some graphics cards
    
    % Timing precision
    cfg.startLeadTime = 0.100; % Schedule flips and audio 100 ms in advance
    cfg.minimumFrameTolerance = 0.001; % Allowed timing error (s)
    
    % Practice passing criteria
    cfg.practiceRequiresPerfectAccuracy = true;
    cfg.practiceRequiresTimelyResponses = true;
    
    % Miscellaneous settings
    cfg.maxInstructionWidth = 80;
    cfg.saveEveryTrial = true;
end
