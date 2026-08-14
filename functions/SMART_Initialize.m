%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SMART_Initialize
%
% InitializeSMART        Initialize PTB, audio, and optional hardware
% ShutdownSMART          Close hardware and restore the MATLAB environment
% LoadSMARTAudio         Preload all audio stimuli into memory
% SelectExecutionMode    Select laptop or full hardware mode
% CreateSMARTTextures    Create all textures used during the experiment
%
% DefineLayout           Compute the screen layout
% CreateMappingTexture   Create one response-mapping instruction screen
% CreateReadyTexture     Create the ready screen
% CreateTextTexture      Create a formatted instruction screen
% MakeTextureFromCanvas  Create a texture from a blank RGB canvas
% CreateBoxesTexture     Create one stimulus display
%
% DrawProgressBar        Draw the generalization progress bar
% DrawRectangleBorder    Draw a rectangle border on an RGB canvas
% DrawFilledCircle       Draw a filled circle on an RGB canvas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = SMART_Initialize(action,varargin)
    switch action
    
        case 'InitializeSMART'
            [varargout{1:nargout}] = InitializeSMART(varargin{:});
    
        case 'ShutdownSMART'
            [varargout{1:nargout}] = ShutdownSMART(varargin{:});
    
        case 'LoadSMARTAudio'
            [varargout{1:nargout}] = LoadSMARTAudio(varargin{:});
    
        case 'SelectExecutionMode'
            [varargout{1:nargout}] = SelectExecutionMode(varargin{:});
    
        case 'CreateSMARTTextures'
            [varargout{1:nargout}] = CreateSMARTTextures(varargin{:});
    
        case 'DefineLayout'
            [varargout{1:nargout}] = DefineLayout(varargin{:});
    
        case 'CreateMappingTexture'
            [varargout{1:nargout}] = CreateMappingTexture(varargin{:});
    
        case 'CreateReadyTexture'
            [varargout{1:nargout}] = CreateReadyTexture(varargin{:});
    
        case 'CreateTextTexture'
            [varargout{1:nargout}] = CreateTextTexture(varargin{:});
    
        case 'MakeTextureFromCanvas'
            [varargout{1:nargout}] = MakeTextureFromCanvas(varargin{:});
    
        case 'CreateBoxesTexture'
            [varargout{1:nargout}] = CreateBoxesTexture(varargin{:});
    
        case 'DrawProgressBar'
            [varargout{1:nargout}] = DrawProgressBar(varargin{:});
    
        case 'DrawRectangleBorder'
            [varargout{1:nargout}] = DrawRectangleBorder(varargin{:});
    
        case 'DrawFilledCircle'
            [varargout{1:nargout}] = DrawFilledCircle(varargin{:});
    
        otherwise
            error('Unknown SMART_Initialize function: %s',action);
    end
end

function state = InitializeSMART(cfg,mode,sampleRate,audioCfg,pahandle)

    % Prepare PTB and the keyboard mapping
    PsychDefaultSetup(2);
    AssertOpenGL;
    KbName('UnifyKeyNames');
    state.escapeKey = KbName('ESCAPE');
    state.keyboardKeys = [KbName('d'),KbName('f'),KbName('j'),KbName('k')];
        
    % Choose stimulus display independently of hardware mode
    switch lower(cfg.displayEnvironment)
        case 'laptop'
            screenNumber = cfg.laptopScreenNumber;
    
        case 'laboratory'
            screenNumber = cfg.laboratoryScreenNumber;
    
        otherwise
            error('Unknown display environment: %s', cfg.displayEnvironment);
    end
    
    % Sync-test behavior depends on execution mode
    if mode.useHardware
        Screen('Preference','SkipSyncTests',cfg.skipSyncTestsFullPipeline);
    else
        Screen('Preference','SkipSyncTests',cfg.skipSyncTestsVisualization);
    end
    
    Screen('Preference','VisualDebugLevel',cfg.visualDebugLevel);
    
    % Store the experiment settings and prepare the state structure
    state.mode = mode;
    state.screenNumber = screenNumber;
    state.datapixxOpen = false;
    state.pixelModeEnabled = false;
    state.audioOpen = false;
    state.windowOpen = false;
    
    % Connect to the DATAPixx when running the full setup
    if mode.useHardware
        Datapixx('Open');
        state.datapixxOpen = true;
    
        Datapixx('StopAllSchedules');
        Datapixx('EnablePixelMode');
        state.pixelModeEnabled = true;
    
        Datapixx('SetDinDataDirection',hex2dec('0F0000'));
        Datapixx('EnableDinDebounce');
        Datapixx('SetDinLog');
        Datapixx('StartDinLog');
        Datapixx('SetDinDataOut',0);
        Datapixx('RegWrRd');
    
        state.datapixxToGetSecsOffset = GetSecs - Datapixx('GetTime');
    else
        state.datapixxToGetSecsOffset = NaN;
    end
    
    % Store the audio device that was initialized before participant setup
    state.pahandle = pahandle;
    state.audioOpen = true;
    
    % Verify that the selected audio device matches the stimulus sampling rate
    if audioCfg.sampleRate ~= sampleRate
        error(['Audio stimulus sampling rate (%d Hz) does not match the ' ...
               'audio output sampling rate (%d Hz).'], ...
               sampleRate,audioCfg.sampleRate);
    end
    
    % Select the timing compensation for the chosen audio pathway
    if strcmp(audioCfg.audioPath,'realtek')
    
        audioLagCompensation = cfg.realtekLagCompensation;
    
    elseif strcmp(audioCfg.audioPath,'babyface')
    
        audioLagCompensation = cfg.babyfaceLagCompensation;
    
    elseif strcmp(audioCfg.audioPath,'speaker')
    
        % Computer speakers are intended only for development/troubleshooting
        % Their physical audio latency has not been calibrated
        audioLagCompensation = 0;
    
        warning(['Computer speakers selected. No audio-path latency ' ...
                 'compensation has been validated for this output.']);
    
    else
    
        error('Unknown audio pathway: %s',audioCfg.audioPath);
    
    end
    
    % Apply the total audio timing correction
    latencyBias = audioLagCompensation + cfg.leadingSilenceCompensation;
    PsychPortAudio('LatencyBias',state.pahandle,latencyBias);
    
    % Store the audio configuration used for this experiment
    state.audioCfg = audioCfg;
    state.audioLagCompensation = audioLagCompensation;
    state.leadingSilenceCompensation = cfg.leadingSilenceCompensation;
    state.latencyBias = latencyBias;

    % Open the experiment window
    [state.window,state.windowRect] = Screen('OpenWindow',screenNumber,cfg.backgroundColor);
    state.windowOpen = true;
    
    % Measure the monitor timing
    Screen('ColorRange',state.window,255);
    Screen('BlendFunction',state.window,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    state.ifi = Screen('GetFlipInterval',state.window);
    state.refreshRate = 1 / state.ifi;
    
    if mode.useHardware && abs(state.refreshRate - 120) > 1
        error('VIEWPixx refresh rate is %.3f Hz instead of approximately 120 Hz',state.refreshRate);
    end
            
    Priority(MaxPriority(state.window));
    
    % Everything is ready, so hide the cursor and lock keyboard input
    HideCursor;
    ListenChar(2);
end

function ShutdownSMART(state,~)

    % Turn off any active DATAPixx outputs
    try
        if state.datapixxOpen
            Datapixx('SetDinDataOut',0);
            Datapixx('RegWrRd');
        end
    catch
    end
    
    % Turn off Pixel Mode
    try
        if state.pixelModeEnabled
            Datapixx('DisablePixelMode');
            Datapixx('RegWrRd');
        end
    catch
    end
    
    % Close the DATAPixx connection
    try
        if state.datapixxOpen
            Datapixx('Close');
        end
    catch
    end
    
    % Stop and close the audio device
    try
        if state.audioOpen
            PsychPortAudio('Stop',state.pahandle);
            PsychPortAudio('Close',state.pahandle);
        end
    catch
    end
    
    % Restore MATLAB to its normal state
    Priority(0);
    ListenChar(0);
    ShowCursor;
    sca;
end

function audio = LoadSMARTAudio(trials)

    % Gather every sound file used during the experiment
    allPaths = [trials.practice.SoundPath;trials.task.SoundPath;trials.violation.SoundPath;trials.generalization.SoundPath];
    
    % Create the structure that stores all loaded audio
    uniquePaths = unique(allPaths,'stable');
    audio.paths = uniquePaths;
    audio.waveforms = cell(numel(uniquePaths),1);
    audio.durations = zeros(numel(uniquePaths),1);
    audio.index = containers.Map('KeyType','char','ValueType','double');
    audio.sampleRate = [];
    
    fprintf('Preloading %d audio files...\n',numel(uniquePaths));
    
    % Load each sound into memory
    for index = 1:numel(uniquePaths)
        path = char(uniquePaths(index));
    
        if ~exist(path,'file')
            error('Missing audio file: %s',path);
        end
    
        [waveform,sampleRate] = audioread(path);
    
        % Make sure every sound uses the same sampling rate
        if isempty(audio.sampleRate)
            audio.sampleRate = sampleRate;
        elseif sampleRate ~= audio.sampleRate
            error('Audio files do not share one sampling rate: %s',path);
        end
    
        % Convert mono files to stereo when needed
        if size(waveform,2) == 1
            waveform = [waveform waveform];
        elseif size(waveform,2) > 2
            waveform = waveform(:,1:2);
        end
    
        % Store the waveform and its information
        waveform = waveform';
        audio.waveforms{index} = waveform;
        audio.durations(index) = size(waveform,2) / sampleRate;
        audio.index(path) = index;
    end
end

function mode = SelectExecutionMode
    
    fprintf('\nSMART experiment\n');
    fprintf('1 - Visualization only\n');
    fprintf('2 - Full hardware pipeline\n\n');
    
    selection = input('Select execution mode: ','s');
    
    while ~ismember(selection,{'1','2'})
        selection = input('Enter 1 or 2: ','s');
    end
    
    if strcmp(selection,'1')
        mode.name = 'visualization';
        mode.useHardware = false;
    else
        mode.name = 'full_pipeline';
        mode.useHardware = true;
    end
    
    fprintf('\nExperiment length\n');
    fprintf('1 - Quick test (2 trials)\n');
    fprintf('2 - Full experiment (all trials)\n\n');
    
    selection = input('Select experiment length: ','s');
    
    while ~ismember(selection,{'1','2'})
        selection = input('Enter 1 or 2: ','s');
    end
    
    mode.quickTest = strcmp(selection,'1');
end

function textures = CreateSMARTTextures(cfg,state)
    
    window = state.window;
    rect = state.windowRect;
    width = RectWidth(rect);
    height = RectHeight(rect);
    
    % Create the displays used during the task
    textures.blank = SMART_Initialize('MakeTextureFromCanvas',window,cfg.backgroundColor,width,height,@(~) []);
    layout = SMART_Initialize('DefineLayout',cfg,rect);
    textures.layout = layout;
    textures.empty = SMART_Initialize('CreateBoxesTexture',window,cfg,width,height,layout,0,false,false,0,cfg.generalizationTrials);
    
    textures.target = zeros(1,4);
    for response = 1:4
        textures.target(response) = SMART_Initialize('CreateBoxesTexture',window,cfg,width,height,layout,response,false,0,1);
    end
    
    textures.generalizationColored = SMART_Initialize('CreateBoxesTexture',window,cfg,width,height,layout,0,true,0,1);
    textures.generalizationEmpty = SMART_Initialize('CreateBoxesTexture',window,cfg,width,height,layout,-1,false,true,0,cfg.generalizationTrials);
    
    % Create every instruction screen
    textures.instructions = struct;

    % Practice instructions
    textures.instructions.practice = SMART_Initialize('CreateTextTexture',window,cfg,width,height,{ ...
        '**Experiment instructions**', ...
        '', ...
        'Your job is to report the location of an X on the screen', ...
        'using the colored buttons on the button boxes'});
    
    for response = 1:4
        textures.instructions.practiceMapping(response) = SMART_Initialize('CreateMappingTexture',window,cfg,width,height,layout,response);
    end
    
    textures.instructions.practiceReminder = SMART_Initialize('CreateTextTexture',window,cfg,width,height,{ ...
        '**Please note:**', ...
        '', ...
        'You will hear sounds just before the X appears', ...
        'Your task is always to report the visual location of the X', ...
        '', ...
        '**Please be as fast and accurate as possible**', ...
        'It is important that you pay attention on each trial', ...
        'Low effort responses will be rejected'});
    
    textures.instructions.practiceRules = SMART_Initialize('CreateTextTexture',window,cfg,width,height,{ ...
        '**Before we begin, let''s do a few practice trials**', ...
        '', ...
        'You must complete the practice trials with 100% accuracy', ...
        'to continue with the experiment', ...
        '', ...
        'Slow responses will also be discarded, so remember to keep', ...
        'a steady and fast pace'});
    
    % Task instructions
    textures.instructions.taskStart = SMART_Initialize('CreateTextTexture',window,cfg,width,height,{ ...
        'You completed the practice trials successfully!!', ...
        '', ...
        'Now we will start the real task', ...
        '', ...
        '**Press any button to continue**'});
    
    textures.instructions.taskReminder = SMART_Initialize('CreateTextTexture',window,cfg,width,height,{ ...
        '**Remember**', ...
        '', ...
        'You will hear sounds just before the X appears', ...
        'Your task is always to report the visual location of the X', ...
        '', ...
        '**Please be as fast and accurate as possible**', ...
        'It is important that you pay attention on each trial', ...
        'Low effort responses will be rejected'});
    
    % Generalization instructions
    textures.instructions.generalization1 = SMART_Initialize('CreateTextTexture',window,cfg,width,height,{ ...
        '**There is just one more block of trials**', ...
        '', ...
        'Please continue to pay attention'});
    
    textures.instructions.generalization2 = SMART_Initialize('CreateTextTexture',window,cfg,width,height,{ ...
        'This task is very similar to what you have been doing', ...
        '', ...
        'You will hear a sequence of sounds', ...
        'but no X will appear on the screen'});
    
    textures.instructions.generalization3 = SMART_Initialize('CreateTextTexture',window,cfg,width,height,{ ...
        '**Do your best to guess the location**', ...
        '**where you would expect the X to appear**', ...
        '', ...
        'This may be challenging, so go with your intuition', ...
        '', ...
        '**Press any button to continue**'});
    
    textures.instructions.generalization4 = SMART_Initialize('CreateTextTexture',window,cfg,width,height,{ ...
        '**Remember**', ...
        '', ...
        'Listen to the sound sequence and report the location', ...
        'where you expect the X to appear'});
    
    % Feedback and transition screens
    textures.ready = SMART_Initialize('CreateReadyTexture',window,cfg,width,height,layout);
    
    textures.slow = SMART_Initialize('CreateTextTexture',window,cfg,width,height,{ ...
        '**Too slow**', ...
        '', ...
        'Please respond as quickly as possible'});
    
    textures.practiceRepeat = SMART_Initialize('CreateTextTexture',window,cfg,width,height,{ ...
        'The practice block must be completed with 100% accuracy', ...
        '', ...
        'The practice trials will now repeat', ...
        '', ...
        '**Press any button when you are ready**'});
    
    textures.blockBreak = cell(cfg.nTaskBlocks,1);
    
    for block = 1:cfg.nTaskBlocks
    
        textures.blockBreak{block} = SMART_Initialize('CreateTextTexture',window,cfg,width,height,{ ...
            sprintf('**Block %d of %d is complete**',block,cfg.nTaskBlocks), ...
            '', ...
            'Take a brief break', ...
            '', ...
            '**Press any button when you are ready to continue**'});
    
    end
    
    textures.end = SMART_Initialize('CreateTextTexture',window,cfg,width,height,{ ...
        '**The experiment is complete!!**', ...
        '', ...
        'Thank you for your participation'});
    
end
    
function layout = DefineLayout(cfg,rect)
    width = RectWidth(rect);
    height = RectHeight(rect);
    
    % Compute the position of the response boxes (vertical rectangles)
    boxWidth = round(width * cfg.boxWidthRatio);
    boxHeight = round(height * cfg.boxHeightRatio);
    gap = round(width * cfg.boxGapRatio);
    totalWidth = 4 * boxWidth + 3 * gap;
    left = round((width - totalWidth) / 2);
    centerY = round(height * cfg.boxCenterYRatio);
    top = centerY - round(boxHeight / 2);
    
    layout.boxes = zeros(4,4);
    for box = 1:4
        boxLeft = left + (box - 1) * (boxWidth + gap);
        layout.boxes(box,:) = [boxLeft,top,boxLeft + boxWidth,top + boxHeight];
    end
    
    % Compute the position of the colored response buttons
    circleDiameter = round(width * cfg.responseCircleDiameterRatio);
    circleY = top + boxHeight + round(height * cfg.responseCircleGapRatio);
    
    layout.circles = zeros(4,4);
    for box = 1:4
        centerX = mean(layout.boxes(box,[1 3]));
        layout.circles(box,:) = CenterRectOnPointd([0 0 circleDiameter circleDiameter],centerX,circleY);
    end
    
    % Save the box centers used to draw the target Xs
    layout.xCenters = mean(layout.boxes(:,[1 3]),2);
    layout.xCenterY = mean(layout.boxes(1,[2 4]));
end

function texture = CreateMappingTexture(window,cfg,width,height,layout,response)

    % Start from the standard task display
    base = SMART_Initialize('CreateBoxesTexture',window,cfg,width,height,layout,response,false,0,1);
    Screen('DrawTexture',window,base);
    Screen('TextFont',window,'Arial');
    Screen('TextStyle',window,0);
    Screen('TextSize',window,round(height * cfg.smallFontRatio));
    
    % Add the instruction for this response mapping
    message = sprintf( ...
        'If you see the X in this box, press %s as quickly as you can.',lower(cfg.responseNames{response}));
    DrawFormattedText(window,message,'center',round(height * 0.84),cfg.textColor,round(width * 0.80));
    
    % Save the completed display as a texture
    image = Screen('GetImage',window,[],'backBuffer');
    Screen('Close',base);
    texture = Screen('MakeTexture',window,image);
end

function texture = CreateReadyTexture(window,cfg,width,height,layout)
    
    % Start from the standard task display
    base = SMART_Initialize('CreateBoxesTexture',window,cfg,width,height,layout,0,false,0,1);
    Screen('DrawTexture',window,base);
    Screen('TextFont',window,'Arial');
    Screen('TextStyle',window,0);
    Screen('TextSize',window,round(height * cfg.smallFontRatio));
    
    % Add the instruction for this response mapping
    message = sprintf([ ...
        'Be sure to place your fingers on the correct buttons.\n\n' ...
        'Press any button when you are ready to start.']);
    DrawFormattedText(window,message,'center',round(height * 0.78),cfg.textColor,round(width * 0.85),[],[],1.5);
    
    % Save the completed display as a texture
    image = Screen('GetImage',window,[],'backBuffer');
    Screen('Close',base);
    texture = Screen('MakeTexture',window,image);
end

function texture = CreateTextTexture(window,cfg,width,height,lines)

    Screen('FillRect',window,cfg.backgroundColor);
    Screen('TextFont',window,'Arial');
    Screen('TextSize',window,round(height * cfg.instructionFontRatio));
    
    lineSpacing = round(height * cfg.instructionFontRatio * 1.5);
    nLines = numel(lines);
    totalHeight = (nLines-1) * lineSpacing;
    y = round(height/2 - totalHeight/2);
    
    for i = 1:nLines
    
        line = char(lines{i});
    
        % Empty line
        if isempty(line)
            y = y + lineSpacing;
            continue;
        end
    
        % Separate regular and bold text
        tokens = regexp(line,'(\*\*.*?\*\*)','split');
        boldTokens = regexp(line,'\*\*(.*?)\*\*','tokens');
    
        fragments = {};
        styles = [];
    
        for k = 1:length(tokens)
    
            if ~isempty(tokens{k})
                fragments{end+1} = tokens{k};
                styles(end+1) = 0;
            end
    
            if k <= length(boldTokens)
                fragments{end+1} = boldTokens{k}{1};
                styles(end+1) = 1;
            end
        end
    
        % Compute total line width
        totalWidth = 0;
    
        for k = 1:length(fragments)
    
            Screen('TextStyle',window,styles(k));
            bounds = Screen('TextBounds',window,fragments{k});
            totalWidth = totalWidth + RectWidth(bounds);
    
        end
    
        x = round((width-totalWidth)/2);
    
        % Draw the line one fragment at a time
        for k = 1:length(fragments)
    
            Screen('TextStyle',window,styles(k));
            DrawFormattedText(window,fragments{k},x,y,cfg.textColor);
            bounds = Screen('TextBounds',window,fragments{k});
            x = x + RectWidth(bounds);
    
        end
    
        y = y + lineSpacing;
    
    end
    
    image = Screen('GetImage',window,[],'backBuffer');
    texture = Screen('MakeTexture',window,image);
end

function texture = MakeTextureFromCanvas(window,color,width,height,~)
    canvas = repmat(reshape(color,1,1,3),height,width,1);
    texture = Screen('MakeTexture',window,canvas);
end

function texture = CreateBoxesTexture(window,cfg,width,height,layout,target,filled,showProgress,completed,total)
    canvas = repmat(reshape(cfg.backgroundColor,1,1,3),height,width,1);
    
    % Draw the response boxes
    for box = 1:4
        rect = round(layout.boxes(box,:));
    
        if filled
            fillColor = cfg.responseColors(box,:);
        else
            fillColor = cfg.backgroundColor;
        end
    
        canvas(rect(2):rect(4),rect(1):rect(3),:) = repmat(reshape(fillColor,1,1,3), rect(4)-rect(2)+1,rect(3)-rect(1)+1,1);
        canvas = SMART_Initialize('DrawRectangleBorder',canvas,rect, cfg.boxBorderColor,cfg.boxBorderWidth);
    end
    
    % Draw the colored response buttons
    for box = 1:4
        canvas = SMART_Initialize('DrawFilledCircle',canvas,layout.circles(box,:), cfg.responseColors(box,:));
    end
    
    
    texture = Screen('MakeTexture',window,canvas);
    
    % Add the visual X target when needed
    if target > 0
    
        Screen('DrawTexture',window,texture);
        Screen('TextFont',window,'Arial');
        Screen('TextStyle',window,1);
        Screen('TextSize',window,round(height * cfg.xFontRatio));
    
        DrawFormattedText(window,'X','center','center',cfg.redXColor,[],[],[],[],[],layout.boxes(target,:));
    
        image = Screen('GetImage',window,[],'backBuffer');
        Screen('Close',texture);
        texture = Screen('MakeTexture',window,image);
    
    elseif target == -1
    
        Screen('DrawTexture',window,texture);
        Screen('TextFont',window,'Arial');
        Screen('TextStyle',window,1);
        Screen('TextSize',window,round(height * cfg.xFontRatio));
    
        for box = 1:4
            DrawFormattedText(window,'X','center','center',cfg.redXColor,[],[],[],[],[],layout.boxes(box,:));
        end
    
        image = Screen('GetImage',window,[],'backBuffer');
        Screen('Close',texture);
        texture = Screen('MakeTexture',window,image);
    
    end
    
    % Add the progress bar when needed
    if showProgress
        Screen('DrawTexture',window,texture);
    
        SMART_Initialize('DrawProgressBar',window,cfg,width,height,completed,total);
    
        image = Screen('GetImage',window,[],'backBuffer');
        Screen('Close',texture);
        texture = Screen('MakeTexture',window,image);
    
    end
end

function DrawProgressBar(window,cfg,width,height,completed,total) 
    if total <= 1
        return;
    end
    
    fraction = min(max(completed/total,0),1);
    
    barWidth  = round(width*cfg.progressBarWidthRatio);
    barHeight = round(height*cfg.progressBarHeightRatio);
    
    left = round((width-barWidth)/2);
    top  = round(height*cfg.progressBarYRatio);
    
    outline = [left top left+barWidth top+barHeight];
    
    Screen('FrameRect',window,cfg.textColor,outline,2);
    
    if fraction>0
        filled = outline;
        filled(3) = left + round(barWidth*fraction);
        Screen('FillRect',window,cfg.textColor,filled);
    end
end

function canvas = DrawRectangleBorder(canvas,rect,color,borderWidth)
    for offset = 0:borderWidth-1
        x1 = rect(1) + offset;
        y1 = rect(2) + offset;
        x2 = rect(3) - offset;
        y2 = rect(4) - offset;
    
        canvas(y1,x1:x2,:) = repmat(reshape(color,1,1,3),1,x2-x1+1,1);
        canvas(y2,x1:x2,:) = repmat(reshape(color,1,1,3),1,x2-x1+1,1);
        canvas(y1:y2,x1,:) = repmat(reshape(color,1,1,3),y2-y1+1,1,1);
        canvas(y1:y2,x2,:) = repmat(reshape(color,1,1,3),y2-y1+1,1,1);
    end
end

function canvas = DrawFilledCircle(canvas,rect,color)
    rect = round(rect);
    [xGrid,yGrid] = meshgrid(rect(1):rect(3),rect(2):rect(4));
    centerX = mean(rect([1 3]));
    centerY = mean(rect([2 4]));
    radius = min(rect(3)-rect(1),rect(4)-rect(2)) / 2;
    mask = (xGrid-centerX).^2 + (yGrid-centerY).^2 <= radius^2;
    
    for channel = 1:3
        layer = canvas(rect(2):rect(4),rect(1):rect(3),channel);
        layer(mask) = color(channel);
        canvas(rect(2):rect(4),rect(1):rect(3),channel) = layer;
    end
end
