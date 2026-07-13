# Adaptive DC-Motor Test Bench

## What this is

This repository contains an adaptive speed-control test bench for a DC motor. The controller combines recursive least squares (RLS) parameter estimation with pole-placement control and runs on an ESP32 from Simulink. The setup implements Example 7.6 from the ACE-II script with a Hyuduo 25GA371 motor and an L298N H-bridge. The theory, derivations, and validation results are documented in [report/report.pdf](report/report.pdf).

## Hardware

| Item | Part | Notes |
|---|---|---|
| Motor | Hyuduo 25GA371, 12 V | Quadrature encoder, gearbox removed |
| Microcontroller | ESP32-WROOM DevKit with power shield | Simulink External Mode target |
| Motor driver | L298N H-bridge | Direction plus PWM drive |
| Power supply | 12 V DC bench supply | Use a current limit during bring-up |

Warning: the L298N drops about 4 V, so with a 12 V supply the motor sees only about 8 V.

`CAD/` contains the Autodesk Inventor parts and assembly for the motor mount and enclosure.

## Wiring

| Signal | ESP32 connection | Notes |
|---|---:|---|
| PWM / ENA | GPIO 14 | Remove the ENA jumper on the L298N |
| IN1 | GPIO 26 | Direction input |
| IN2 | GPIO 27 | Direction input |
| Encoder A | GPIO 32 | Quadrature channel A |
| Encoder B | GPIO 33 | Quadrature channel B |
| Encoder VCC | 3.3 V | Do not power the encoder from 5 V |

Use a common ground between ESP32, L298N, motor supply, and encoder. See [img/wiring.png](img/wiring.png) for the full wiring diagram.

## Software prerequisites

| Software | Required version or package |
|---|---|
| MATLAB / Simulink | R2025b |
| Model discretisation | Control System Toolbox (`c2d`, `tf`, `tfdata`) |
| Code generation | Simulink Coder and Embedded Coder |
| ESP32 target support | Simulink Support Package for Arduino/ESP32 Hardware |

The Control System Toolbox is required by `second_order_params.m` and therefore
by every second-order script. The ESP32 support package is required by
`build_stage_models` and `validate_stage_models` even with no board attached.

## Build the models

By default, the build scripts write generated Simulink models to `simulink/`
and exported figures to `img/`, independent of the current MATLAB working
directory. `ACE_OUT_DIR` is optional; set it only when you want generated
models and figures to land in a separate output directory.

From MATLAB:

```matlab
cd("C:\path\to\ACE-II-AdaptiveControl\matlab")

build_stage_models
% expected: BUILD_OK

validate_stage_models
% expected: VALIDATION_OK

build_second_order_model
% expected: BUILD_OK

validate_second_order
% expected: VALIDATION_OK

export_second_order_plots
% expected: PLOTS_OK, writes img/simulation_2nd_order.png

identifiability_study
% expected: STUDY_OK
```

Optional output override, set before running the scripts:

```matlab
setenv("ACE_OUT_DIR", "C:\path\to\ace_build")
```

From a shell, run the same sequence headlessly from the `matlab/` directory:

```bash
cd matlab
matlab -batch "build_stage_models"       # expected: BUILD_OK
matlab -batch "validate_stage_models"    # expected: VALIDATION_OK
matlab -batch "build_second_order_model" # expected: BUILD_OK
matlab -batch "validate_second_order"    # expected: VALIDATION_OK
matlab -batch "export_second_order_plots" # expected: PLOTS_OK
matlab -batch "identifiability_study"    # expected: STUDY_OK
```

## Safety checklist before power-up

- Bench supply current limit active, start at 0.5 A
- Common ground between ESP32, L298N, motor supply and encoder
- Encoder powered from **3.3 V only**; the ESP32 GPIOs are not 5 V tolerant
- ENA jumper removed from the L298N
- Motor mechanically secured before applying power

## Bring-up in stages

### Stage 1: `simulink/pwm_test.slx`

Run the open-loop PWM model first. This stage does not use encoder feedback or a controller; it only drives the L298N from the ESP32.

What must work: changing the PWM command must make the motor rotate, and changing the sign or direction command must reverse the direction. If the motor does not move, fix power, ground, ENA, IN1, IN2, and GPIO 14 before continuing.

### Stage 2: `encoder_test.slx`

Run `encoder_test.slx` in External Mode with Monitor and Tune. Set the PWM constant to `0` before starting this stage, then check that the encoder count changes when the shaft is turned by hand.

Verify the encoder scaling before using speed values: rotate the motor shaft exactly one revolution by hand. The counter difference must be 44 counts, matching the measured 11 PPR encoder with x4 quadrature decoding.

What must work: with PWM at zero, the count must change monotonically when the shaft is turned and must return 44 counts for one exact revolution.

### Stage 3: `adaptive_dcmotor.slx`

Run `adaptive_dcmotor.slx` in External Mode after the PWM and encoder stages are correct. This closes the loop around the real motor with RLS estimation and pole-placement control.

What must work: the measured speed must follow the reference, the estimates `a0` and `b0` must converge instead of drifting, and `trace(P)` must fall from its initial value. If the controller saturates continuously or the estimates diverge, return to Stage 2 and verify encoder scaling and sign conventions.

## Models and analysis

| Item | Purpose |
|---|---|
| `simulink/adaptive_dcmotor_sim.slx` | Simulation-only first-order adaptive controller with inertia change S -> L -> S |
| `simulink/adaptive_dcmotor_2nd_sim.slx` | Simulation-only second-order model with electrical dynamics, `T = 2 ms` |
| `simulink/adaptive_dcmotor_2nd_hw.slx` | Hardware experiment for the second-order controller at `T = 80 ms`; source of the two measurement figures in the report, not the recommended simulation model |
| `matlab/plot_hardware_response.m` | Exports the logged hardware response from `simulink/adaptive_dcmotor_2nd_hw.slx` to `img/hw_response.pdf` |

`matlab/identifiability_study.m` shows why the second-order model can be identified in simulation but not on the rig, by sweeping the encoder resolution and the sampling time.

## Known limitations

The controller cannot actively brake the motor. When the command is reduced, the motor coasts down instead of being driven with regenerative or dynamic braking.

The 44-count encoder resolves speed to `2*pi/(T*CPR)`, which is 1.78 rad/s at `T = 80 ms`. That is fine for the first-order model, but the second-order model's electrical mode contributes only about 1 % of the output at that sampling time and is lost in the quantisation. Reducing the sampling time does not help, because the resolution degrades as `1/T`. Running `identifiability_study` reproduces this limitation; see [report/report.pdf](report/report.pdf).
