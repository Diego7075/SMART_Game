# SMART Experiment (Psychtoolbox)

SMART is a MATLAB/Psychtoolbox experiment for studying audiovisual
statistical learning using visual target responses. The experiment
supports both a visualization-only mode for development and a full
hardware mode using the VPixx ecosystem (VIEWPixx + DATAPixx +
RESPONSEPixx).

## Features

-   MATLAB + Psychtoolbox implementation
-   Visualization mode for debugging
-   Full VPixx hardware support
-   Automatic ISI balancing
-   Automatic response-mapping balancing
-   Pixel Mode trigger generation
-   Trial-by-trial behavioral and event logging

## Requirements

### Software

-   MATLAB
-   Psychtoolbox
-   VPixx Datapixx Toolbox (hardware mode)

### Asset folders

    flac_practice
    flac_task
    flac_generalization

Run the experiment with:

``` matlab
SMART
```

## Execution Modes

### Visualization

-   Screen 1
-   Keyboard D/F/J/K
-   No DATAPixx
-   Pixel squares drawn visually
-   Events logged

### Full Hardware

-   Screen 3
-   DATAPixx Pixel Mode enabled
-   RESPONSEPixx buttons and LEDs
-   Requires \~120 Hz VIEWPixx

## Participant Balancing

The script creates `data/ISI_Assignments.csv` and automatically balances
both ISI conditions and response mappings across participants.

### ISI conditions

- 0 ms
- 250 ms
- 500 ms
- 1100 ms

### Response mappings

- `AXBY`
- `BYAX`
- `YBXA`
- `XAYB`

## Trigger Scheme

  Phase            RGB
  ---------------- -------------
  Practice         \[16 0 0\]
  Task             \[32 0 0\]
  Violation        \[64 0 0\]
  Generalization   \[128 0 0\]

  Response     RGB
  ------------ -------------
  Yellow (D)   \[0 16 0\]
  Green (F)    \[0 32 0\]
  Blue (J)     \[0 64 0\]
  Red (K)      \[0 128 0\]

Each trigger is displayed for three frames.

## Output

-   .mat results
-   Trial CSV
-   Event CSV
-   Summary CSV

## Notes

-   Response-screen trigger repeats the phase marker.
-   ISI applies only to Practice, Task, and Violation.
-   Generalization presents 48 trials twice to create 96 trials.
-   Practice repeats until all responses are correct and under 1.5 s.
-   Verify RESPONSEPixx button mapping before data collection.
-   All audio files must share one sampling rate.

## Validation

Before collecting experimental data, it is recommended to:

1. Run the validation script.
2. Test Visualization mode.
3. Test Full Hardware mode.
4. Verify Pixel Mode triggers.

### Reducing the number of trials during development

For debugging purposes, both `SMART_Task.m` and `SMART_Generalization.m` contain the following temporary code block:

```matlab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Temporary: keep only two trials while testing (comment to nulify)
order = order(1:2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
```

Leaving this code active limits each randomized block to two trials. Comment out (or remove) these lines before running the complete experiment.
