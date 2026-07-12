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

## Wiring

| Signal | ESP32 connection | Notes |
|---|---:|---|
| PWM / ENA | GPIO 14 | Remove the ENA jumper on the L298N |
| IN1 | GPIO 26 | Direction input |
| IN2 | GPIO 27 | Direction input |
| Encoder A | GPIO 32 | Quadrature channel A |
| Encoder B | GPIO 33 | Quadrature channel B |
| Encoder VCC | 3.3 V | Do not power the encoder from 5 V |

Use a common ground between ESP32, L298N, motor supply, and encoder. See [img/wiring.png](img/wiring.png) and [hardware_diagram.md](hardware_diagram.md) for the full wiring diagram.

## Software prerequisites

| Software | Required version or package |
|---|---|
| MATLAB / Simulink | R2025b |
| Code generation | Simulink Coder and Embedded Coder |
| ESP32 target support | Simulink Support Package for Arduino/ESP32 Hardware |

## Build the models

The build scripts write models to `ACE_OUT_DIR`. If `ACE_OUT_DIR` is not set, they use the current MATLAB working directory. Set it when you want generated `.slx` files and logs to land in a separate staging directory.

From MATLAB:

```matlab
setenv("ACE_OUT_DIR", "C:\path\to\ace_build")
cd("C:\path\to\ACE-II-AdaptiveControl\matlab")

build_stage_models
% expected: BUILD_OK

validate_stage_models
% expected: VALIDATION_OK

build_second_order_model
% expected: BUILD_OK

validate_second_order
% expected: VALIDATION_OK
```

From a shell, run the same sequence headlessly from the `matlab/` directory:

```bash
cd matlab
matlab -batch "build_stage_models"       # expected: BUILD_OK
matlab -batch "validate_stage_models"    # expected: VALIDATION_OK
matlab -batch "build_second_order_model" # expected: BUILD_OK
matlab -batch "validate_second_order"    # expected: VALIDATION_OK
```

## Bring-up in stages

### Stage 1: `pwm_test.slx`

Run the open-loop PWM model first. This stage does not use encoder feedback or a controller; it only drives the L298N from the ESP32.

What must work: changing the PWM command must make the motor rotate, and changing the sign or direction command must reverse the direction. If the motor does not move, fix power, ground, ENA, IN1, IN2, and GPIO 14 before continuing.

### Stage 2: `encoder_test.slx`

Run `encoder_test.slx` in External Mode with Monitor and Tune. Set the PWM constant to `0` before starting this stage, then check that the encoder count changes when the shaft is turned by hand.

Calibrate the encoder before using any speed values: rotate the motor shaft exactly one revolution by hand, read the counter difference, and use that value as counts per revolution. Enter it in `stageParams()` as `p.CPR`, rebuild the stage models, and deploy again.

What must work: with PWM at zero, the count must change monotonically when the shaft is turned and must return the measured counts-per-revolution value for one exact revolution. Without this calibration, every speed value is wrong by an unknown scale factor.

### Stage 3: `adaptive_dcmotor.slx`

Run `adaptive_dcmotor.slx` in External Mode after the PWM and encoder stages are correct. This closes the loop around the real motor with RLS estimation and pole-placement control.

What must work: the measured speed must follow the reference, the estimates `a0` and `b0` must converge instead of drifting, and `trace(P)` must fall from its initial value. If the controller saturates continuously or the estimates diverge, return to Stage 2 and verify encoder scaling and sign conventions.

## Simulation only

| Model | Purpose |
|---|---|
| `adaptive_dcmotor_sim.slx` | First-order adaptive controller with inertia change S -> L -> S |
| `adaptive_dcmotor_2nd_sim.slx` | Second-order model with electrical dynamics, `T = 2 ms` |

These models are for simulation and validation without the ESP32 hardware.

## Known limitations

The encoder CPR has not been calibrated on the final hardware, so all reported speeds remain subject to an unknown scale factor until the one-revolution test is done.

The controller cannot actively brake the motor. When the command is reduced, the motor coasts down instead of being driven with regenerative or dynamic braking.

The flywheels are designed but not mounted for the submission. The inertia-change scenario is therefore demonstrated in simulation rather than on the physical test bench.
