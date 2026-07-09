# Clean adaptive-control simulation

This folder contains the reproducible simulation that bridges the supplied
reference model and the later ESP32 implementation.

## Files

- `adaptive_motor_params.m` — all tunable simulation parameters
- `build_adaptive_motor_sim.m` — generates `adaptive_motor_sim.slx`
- `adaptive_motor_sim.slx` — generated, ready-to-open Simulink model
- `run_adaptive_motor_sim.m` — runs acceptance checks and exports plots

Run from MATLAB:

```matlab
cd('<project>/matlab')
build_adaptive_motor_sim    % only required after changing the builder
run_adaptive_motor_sim
```

The expected terminal result is `VALIDATION_OK`.

## Model boundary

The top level has three deliberately separate parts:

1. **Adaptive controller** — RLS, guarded pole placement, incremental PI,
   saturation and all required unit delays.
2. **Variable inertia plant** — exact ZOH first-order motor model with a
   continuous state across the `J = 1 -> 24` flywheel change.
3. **Measurement and monitoring** — speed noise, tracking scope and an
   Adaptation scope with separate axes for u / a0 and b0 / traceP / J in the
   simulation model.

The simulated `J = 1 -> 24` change represents the flywheel swap that is not run
on the physical test bench; the bench uses the bare motor, so the simulation is
the authoritative inertia-change demonstration.

The controller runs fully discrete at `T = 0.08 s`. The saturated actuator
value is fed back as `u(k-1)`, so the simulation and firmware use the same
anti-windup-consistent recurrence.

## What is validated

- `u` never leaves `[-255, 255]`.
- RLS converges to the exact discrete parameters before the inertia change.
- With `alpha = 0.98`, RLS re-converges after the 24x inertia change.
- The pole-placement update is held whenever `abs(b0_est) <= b0Min`.
- No algebraic loop is used; all previous-sample signals are explicit delays.

## Important physical limitation

The plant parameters are normalized (`Km = b = J_small = 1`). The model is
therefore an algorithm and architecture test, not yet a calibrated prediction
of the real motor's rise time. With `J = 24` and `u = +/-255`, the normalized
plant is torque-limited and ramps for several seconds. It would be misleading
to claim a 250 ms physical settling time from this model alone.

Before judging the hardware settling time, record open-loop PWM steps with
both flywheels (for example duty 64, 128 and 192) and log encoder counts every
80 ms. Those measurements provide realistic `a0`/`b0` ranges and reveal
encoder quantization and motor deadband.

## Transfer to ESP32

Keep the **Adaptive controller** subsystem unchanged and replace only:

```text
Variable inertia plant + measurement noise
```

with:

```text
Encoder A/B -> count difference -> 2*pi/(T*CPR) -> measured speed
u_sat -> abs -> PWM GPIO14
u_sat -> sign -> GPIO26/GPIO27
```

The large-inertia simulation also shows substantial PWM movement when speed
noise is present. Do not hide that by setting the noise to zero: first measure
the encoder signal, then decide whether count averaging, a speed filter or a
small command deadband is needed.
