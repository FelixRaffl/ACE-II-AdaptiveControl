# ESP32 Adaptive Control Model Specification

This directory documents the ESP32 version of the adaptive DC motor controller. The simulated plant is replaced by real ESP32 I/O, while the validated controller structure remains unchanged. The hardware models run through Simulink External Mode with Monitor and Tune.

## Controller Blocks

| Block | File | Function |
|---|---|---|
| RLS estimator | [`rls_estimator.m`](rls_estimator.m) | Estimates `[a0; b0]` online |
| Pole placement | [`pole_placement_controller.m`](pole_placement_controller.m) | Computes `d0, d1` from `a0, b0, q0, q1` |
| Incremental PI | [`PI_C.m`](PI_C.m) | Computes `u = u_prev + d1*e + d0*e_prev` |

Parameters: `q0 = 0.06`, `q1 = -0.5`, `alpha = 0.98`, `P0 = 100*I`, `xhat0 = [-0.5; 1.0]`, `b0Min = 1e-3`, and sample time `T = 0.08 s` for the full control loop.

## Signal Flow

```text
                  omega_ref (tunable) --(+)--> e_curr -------------------+
                              omega(k) --(-)--> e_prev = z^-1(e_curr)    |
                                                                           v
   y(k)=omega(k) --+                                                     [PI] --> u
   y_prev=z^-1(y) -+--> [RLS] --> a0,b0 --> [PolePlace q0,q1] --> d0,d1 --+
   u_prev=z^-1(u_sat) ----------------------------------------------------+

   u -> Saturation[-255,255] -> actuator path and u_prev feedback
```

## ESP32 I/O Mapping

### Output: `u` to Motor

- Saturate `u` to `[-255, 255]`.
- Send `abs(u)` directly to PWM on GPIO 14. The confirmed LEDC block range is 0..255.
- Map the sign of `u` to the L298N direction pins:
  - `u >= 0`: IN1 = 1 on GPIO 26, IN2 = 0 on GPIO 27
  - `u < 0`: IN1 = 0, IN2 = 1

### Input: Encoder to `omega`

- Read quadrature counts `N` from the `arduinosensorlib/Encoder` block in Simulink Support Package for Arduino Hardware 25.2.9 on GPIO 32 and GPIO 33.
- The block runs interrupt based with x4 quadrature decoding, returns `int32`, and uses mode `No reset`.
- Compute `DeltaN = N(k) - N(k-1)`.
- Convert speed with `omega(k) = 2*pi*DeltaN/(T*CPR)`, using the measured `CPR = 44` from the one-revolution test.
- Feed `y(k) = omega(k)` to the controller.

`omega_ref` and `omega` use the same unit, rad/s. RLS adapts the real `a0` and `b0` values for the hardware plant, so no manual plant-gain tuning is required.

## External Mode Signals

Monitor and tune `omega`, `omega_ref`, `u`, `e`, `a0_est`, `b0_est`, and `traceP`. The test bench runs with the bare motor for the submission. The complete S->L->S flywheel demonstration is validated in `../simulink/adaptive_dcmotor_sim.slx`; `a0` and `b0` re-adapt and the simulated settling time remains around 0.25-0.4 s.

## Build Sequence

1. PWM open loop: `Constant(duty) -> PWM GPIO14` plus fixed direction. Verify the actuator path before using encoder feedback.
2. Encoder open loop: encoder block -> `DeltaN` -> `omega` -> scope. Verify monotonic counts and `CPR = 44` with one motor-shaft revolution.
3. Closed loop: insert RLS, pole placement, incremental PI, unit delays, saturation, and `omega_ref`. Keep the bench supply current limit active and raise `omega_ref` gradually.

## Operating Constraints

- The static duty-to-speed characteristic determines the practical low-speed deadband and the useful `omega_ref` range.
- The measurement chain is checked before the loop is closed: monotonic `N`, single-signed `DeltaN`, plausible `omega`, and a stable forward direction command.
- The physical test bench uses the bare motor. The flywheel inertia change is demonstrated in simulation.
