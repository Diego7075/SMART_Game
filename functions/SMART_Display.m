%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SMART_Display
%
% ShowExperimentInstructions     Display the complete practice instructions
% ShowTaskInstructions           Display the complete task instructions
% ShowGeneralizationInstructions Display the generalization instructions
% ShowBlockBreak                 Display the break screen between task blocks
% ShowEndScreen                  Display the final screen before closing the experiment
%
% ShowTextureAndWait             Display one screen (texture) and wait for a response
% PresentTriggeredTexture        Present a stimulus together with a trigger
% DrawTextureBaseline            Draw a texture while maintaining the trigger baseline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = SMART_Display(action,varargin)
    switch action
    
        case 'ShowExperimentInstructions'
            [varargout{1:nargout}] = ShowExperimentInstructions(varargin{:});
    
        case 'ShowTaskInstructions'
            [varargout{1:nargout}] = ShowTaskInstructions(varargin{:});
    
        case 'ShowGeneralizationInstructions'
            [varargout{1:nargout}] = ShowGeneralizationInstructions(varargin{:});
    
        case 'ShowBlockBreak'
            [varargout{1:nargout}] = ShowBlockBreak(varargin{:});
    
        case 'ShowEndScreen'
            [varargout{1:nargout}] = ShowEndScreen(varargin{:});
    
        case 'ShowTextureAndWait'
            [varargout{1:nargout}] = ShowTextureAndWait(varargin{:});
    
        case 'PresentTriggeredTexture'
            [varargout{1:nargout}] = PresentTriggeredTexture(varargin{:});
    
        case 'DrawTextureBaseline'
            [varargout{1:nargout}] = DrawTextureBaseline(varargin{:});
    
        otherwise
            error('Unknown SMART_Display function: %s',action);
    end
end

function ShowExperimentInstructions(cfg,state,textures,mode)
    
    % Display the main practice instructions
    SMART_Display('ShowTextureAndWait',cfg,state,textures.instructions.practice,mode);
    
    % Present each sound-to-button mapping individually
    for response = 1:4
        SMART_Display('ShowTextureAndWait',cfg,state,textures.instructions.practiceMapping(response),mode);
    end
    
    % Reinforce the mapping and explain the practice rules
    SMART_Display('ShowTextureAndWait',cfg,state,textures.instructions.practiceReminder,mode);
    SMART_Display('ShowTextureAndWait',cfg,state,textures.instructions.practiceRules,mode);

    % Wait on the ready screen before starting the practice block
    SMART_Display('ShowTextureAndWait',cfg,state,textures.ready,mode);
end

function ShowTaskInstructions(cfg,state,textures,mode)
    
    % Explain the transition from practice to the main task
    SMART_Display('ShowTextureAndWait',cfg,state,textures.instructions.taskStart,mode);

    % Remind the participant of the task rules
    SMART_Display('ShowTextureAndWait',cfg,state,textures.instructions.taskReminder,mode);

    % Wait on the ready screen before starting the first task block
    SMART_Display('ShowTextureAndWait',cfg,state,textures.ready,mode);
end

function ShowGeneralizationInstructions(cfg,state,textures,mode)
    
    % Display the complete generalization instructions
    SMART_Display('ShowTextureAndWait',cfg,state,textures.instructions.generalization1,mode);
    SMART_Display('ShowTextureAndWait',cfg,state,textures.instructions.generalization2,mode);
    SMART_Display('ShowTextureAndWait',cfg,state,textures.instructions.generalization3,mode);
    SMART_Display('ShowTextureAndWait',cfg,state,textures.instructions.generalization4,mode);

    % Wait on the ready screen before starting generalization
    SMART_Display('ShowTextureAndWait',cfg,state,textures.ready,mode);
end

function ShowBlockBreak(cfg,state,textures,mode,completedBlock)
    
    % Display the break screen between task block
    SMART_Display('DrawTextureBaseline',cfg,state,textures.blockBreak{completedBlock});
    
    % Present the break screen without sending a trigger
    Screen('FillRect',state.window,cfg.triggerBaseline,cfg.triggerSquare);
    
    Screen('Flip',state.window);
    
    % Resume when the participant presses any response button
    SMART_Task('WaitForAnyResponse',cfg,state,mode);

end

function ShowEndScreen(cfg,state,textures,mode)
    
    % Display the final experiment screen
    SMART_Display('DrawTextureBaseline',cfg,state,textures.end);
    Screen('Flip',state.window);

    % Wait until the participant acknowledges the end of the experiment
    SMART_Task('WaitForAnyResponse',cfg,state,mode);
end

% Present one texture and wait until the participant completes a press-release response
function ShowTextureAndWait(cfg,state,texture,mode)
    
    % Draw and display the requested texture
    SMART_Display('DrawTextureBaseline',cfg,state,texture);
    Screen('Flip',state.window);
    
    % Continue only after a complete button press and release
    SMART_Task('WaitForAnyResponse',cfg,state,mode);
end

function [onset,events] = PresentTriggeredTexture(cfg,state,texture,trigger,phase,blockNumber,trialNumber,eventName,requestedOnset,mode)
    
    % Presents one Pixel Mode marker for three frames, then returns to baseline
    % Initialize the event structure returned to the caller
    events = SMART_Participant('EmptyEventResults');
    onset = NaN;
    
    % Present the trigger for the requested number of frames
    for frame = 1:cfg.triggerFrames
        Screen('DrawTexture',state.window,texture);
        Screen('FillRect',state.window,trigger,cfg.triggerSquare);
    
        % Respect the requested onset time on the first frame only
        if frame == 1 && requestedOnset > GetSecs
            flipTime = Screen('Flip',state.window,requestedOnset);
        else
            flipTime = Screen('Flip',state.window);
        end
    
        % Store the timestamp and event information only once
        if frame == 1
            onset = flipTime;
            events = SMART_Participant('AddEvent',events,onset,phase,blockNumber,trialNumber,eventName,trigger,mode);
        end
    end
    
    % Restore the trigger region to baseline after the trigger presentation
    SMART_Display('DrawTextureBaseline',cfg,state,texture);
    Screen('Flip',state.window);
end

function DrawTextureBaseline(cfg,state,texture)

    % Draw the requested texture
    Screen('DrawTexture',state.window,texture);

    % Force the Pixel Mode trigger region back to baseline
    Screen('FillRect',state.window,cfg.triggerBaseline,cfg.triggerSquare);
end
