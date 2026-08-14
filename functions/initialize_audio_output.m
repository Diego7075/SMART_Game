function [cfg,pahandle] = initialize_audio_output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BABYFACE / REALTEK AUDIO INITIALIZATION
%
% This function initializes the PsychPortAudio output used by auditory
% experiments and validation scripts. It provides a common audio-loading
% procedure so that the Realtek and RME Babyface playback pathways use the
% same validated PsychPortAudio configuration across experiments
%
% At startup, the function enumerates the available PsychPortAudio output
% devices and prompts the user to select one of two supported pathways:
%
%     1 - Computer speakers (development/troubleshooting)
%     2 - Desktop headphone jack (Realtek -> StimTrak)
%     3 - RME Babyface Analog 3/4
%
% The requested device is located automatically using its device name,
% Windows WASAPI backend, and number of output channels. The function then
% opens the selected device using the standard audio configuration:
%
%     Sample rate       = 48000 Hz
%     Output channels   = 2
%     audioLatencyClass = 1
%     Audio volume      = 1.0
%
% OUTPUTS:
%
%     cfg       Structure containing the selected audio pathway and its
%               PsychPortAudio configuration.
%
%     pahandle  PsychPortAudio handle for the opened playback device
%
% The returned cfg structure contains:
%
%     cfg.audioPath
%     cfg.audioDeviceName
%     cfg.audioDeviceHostAPIName
%     cfg.audioDeviceIndex
%     cfg.audioChannels
%     cfg.sampleRate
%     cfg.audioLatencyClass
%     cfg.audioVolume
%
% IMPORTANT:
% This function initializes the audio device only. Experiment-specific
% timing parameters, including LatencyBias, audio-pathway compensation,
% stimulus leading-silence compensation, and event scheduling times must
% be defined within the experiment or validation script
%
% For the RME Babyface pathway, the Babyface must be connected to the
% computer through USB before this function is called. The validated RME
% configuration uses a 512-sample buffer and a 48000-Hz sample rate in
% Fireface USB Settings. DO NOT CHANGE THEM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize PsychPortAudio and close any previously open audio streams
InitializePsychSound(1);
PsychPortAudio('Close');

% Detect all available PsychPortAudio devices
devices = PsychPortAudio('GetDevices');

fprintf('\n');
fprintf('Available audio output devices\n');
fprintf('------------------------------\n');

% Display playback devices and their properties
for k = 1:length(devices)

    if devices(k).NrOutputChannels > 0

        fprintf('%2d  %-40s API=%-20s Out=%d\n', ...
            devices(k).DeviceIndex, ...
            devices(k).DeviceName, ...
            devices(k).HostAudioAPIName, ...
            devices(k).NrOutputChannels);

    end

end

fprintf('\n');
fprintf('Select the audio output:\n');
fprintf('  1 - Computer speakers\n');
fprintf('  2 - Desktop headphone jack -> StimTrak\n');
fprintf('  3 - Babyface Analog 3/4\n\n');

choice = input('Selection (1, 2, or 3): ');

% Define the requested playback device
switch choice

    case 1

        % Built-in computer speakers.
        % This is a flexible troubleshooting/development pathway rather than
        % a validated experimental audio pathway. The exact speaker name may
        % differ between computers, so identify it dynamically.
        cfg.audioDeviceHostAPIName = 'Windows WASAPI';
        cfg.audioChannels = 2;
        cfg.audioPath = 'speaker';

        speakerMatches = ...
            startsWith({devices.DeviceName}, 'Speakers', 'IgnoreCase', true) & ...
            strcmp({devices.HostAudioAPIName}, cfg.audioDeviceHostAPIName) & ...
            [devices.NrOutputChannels] >= cfg.audioChannels;

        if ~any(speakerMatches)

            error('No suitable Windows WASAPI speaker output was found.');

        elseif sum(speakerMatches) > 1

            fprintf('\nMultiple Windows WASAPI speaker outputs were found:\n');

            idx = find(speakerMatches);

            for k = 1:length(idx)
                fprintf('  %d  %s\n', ...
                    devices(idx(k)).DeviceIndex, ...
                    devices(idx(k)).DeviceName);
            end

            error(['Multiple speaker outputs matched. ' ...
                   'Speaker selection cannot be determined automatically.']);

        end

        audioDevice = devices(speakerMatches);
        cfg.audioDeviceName = audioDevice.DeviceName;

    case 2

        % Desktop Realtek headphone output -> StimTrak
        cfg.audioDeviceName = 'Headphones (Realtek(R) Audio)';
        cfg.audioDeviceHostAPIName = 'Windows WASAPI';
        cfg.audioChannels = 2;
        cfg.audioPath = 'realtek';

    case 3

        % RME Babyface Analog 3/4
        cfg.audioDeviceName = 'Analog (3+4) (RME Babyface Pro)';
        cfg.audioDeviceHostAPIName = 'Windows WASAPI';
        cfg.audioChannels = 2;
        cfg.audioPath = 'babyface';

    otherwise

        error('Invalid selection. Choose 1, 2, or 3.');

end

% Locate the requested playback device
matches = strcmp({devices.DeviceName}, cfg.audioDeviceName) & ...
          strcmp({devices.HostAudioAPIName}, cfg.audioDeviceHostAPIName) & ...
          [devices.NrOutputChannels] >= cfg.audioChannels;

if ~any(matches)

    error('Audio device "%s" using "%s" was not found.', ...
        cfg.audioDeviceName, cfg.audioDeviceHostAPIName);

end

if sum(matches) > 1

    error('Multiple audio output devices matched "%s" using "%s".', ...
        cfg.audioDeviceName, cfg.audioDeviceHostAPIName);

end

audioDevice = devices(matches);
cfg.audioDeviceIndex = audioDevice.DeviceIndex;

% Configure the selected audio output
cfg.sampleRate = 48000;

% PsychPortAudio audioLatencyClass controls how aggressively PTB optimizes
% audio timing:
% 0 = normal latency, maximum compatibility
% 1 = low-latency mode with conservative timing optimization
% 2 = aggressive low-latency mode for accurate stimulus timing
% 3 = same as 2, but requires exclusive access to the audio device
% 4 = most aggressive mode, with additional restrictions for maximum
%     timing precision
cfg.audioLatencyClass = 1;
cfg.audioVolume = 1.0;

% Open the selected audio output
pahandle = PsychPortAudio( ...
    'Open', ...
    cfg.audioDeviceIndex, ...
    1, ...
    cfg.audioLatencyClass, ...
    cfg.sampleRate, ...
    cfg.audioChannels);

PsychPortAudio('Volume',pahandle,cfg.audioVolume);

% Display the selected playback device
fprintf('\n');
fprintf('Selected audio output\n');
fprintf('---------------------\n');
fprintf('Device      : %s\n',cfg.audioDeviceName);
fprintf('Index       : %d\n',cfg.audioDeviceIndex);
fprintf('API         : %s\n',cfg.audioDeviceHostAPIName);
fprintf('Sample rate : %d Hz\n',cfg.sampleRate);
fprintf('Channels    : %d\n',cfg.audioChannels);
fprintf('\n');

end