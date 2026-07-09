%% Build the Stage-2/3 Simulink models for the ESP32 handover.
%
% Builds three models into ACE_OUT_DIR (default: pwd):
%   encoder_test.slx         Stage 2 - encoder -> omega + PWM spin-up path
%   adaptive_dcmotor_sim.slx Stage 3 - full loop with simulated plant,
%                            S->L->S flywheel-swap scenario (validation)
%   adaptive_dcmotor.slx     Stage 3 - same controller, ESP32 I/O
%
% Controller design as validated in matlab/design_study.m (see README,
% section "Design study"): alpha = 0.98, b0 guard, saturation +-255 with
% the saturated u fed back, RLS excitation gate against covariance windup.
% All block parameters are numeric literals so the .slx files are fully
% self-contained (and literals stay tunable in External Mode).
%
% The ESP32 board / XCP External-Mode configuration is copied from a staged
% READ-ONLY copy of the colleague's pwm_test.slx (never saved).
%
% Usage (staging dir contains pwm_test.slx and this script):
%   matlab.exe -wait -nosplash -sd <stage> -batch "build_stage_models"

outDir = getenv('ACE_OUT_DIR');
if isempty(outDir), outDir = pwd; end

p = stageParams();

load_system('arduinolib');
load_system('arduinosensorlib');
load_system('pwm_test');                      % read-only config donor

buildEncoderTest(p, outDir);
buildSimModel(p, outDir);
buildHardwareModel(p, outDir);

close_system('pwm_test', 0);                  % never save the donor
disp('BUILD_OK');

%% ---------------------------------------------------------------- params
function p = stageParams()
    p.T      = 0.08;   % sample time [s]
    p.alpha  = 0.98;   % RLS forgetting factor (design_study.m)
    p.q0     = 0.06;   % q(z) = z^2 + q1*z + q0
    p.q1     = -0.5;
    p.b0Min  = 1e-3;   % pole-placement guard threshold
    p.uMax   = 255;    % PWM saturation

    % ESP32 pin map (Raffl code_gen_ac2.slx @ 2ffe5be - am Board getestet 2026-07-06)
    p.pinPWM = 14; p.pinIN1 = 26; p.pinIN2 = 27;
    p.pinEncA = 32; p.pinEncB = 33;
    p.CPR    = 44;     % 11 PPR x4 quadrature - calibrate in Stage 2

    % Simulation scenario (normalized plant as in the reference model)
    p.Km = 1; p.b = 1; p.J_small = 1; p.J_large = 24;
    p.simTime = 96;
    p.swapUp = 32;     % S -> L
    p.swapDown = 64;   % L -> S (safety-critical direction)
    p.refAmplitude = 50; p.refPeriod = 16;
    p.refDelay = 4;    % idle start: exercises the RLS excitation gate
    p.noiseVariance = 1e-3 / p.T;
    p.noiseSeed = 23341;
end

function s = num(v)
    s = sprintf('%.10g', v);
end

%% ------------------------------------------- shared controller subsystem
function buildControllerSubsystem(ctrl, p)
    T = num(p.T);
    add_block('simulink/Ports & Subsystems/In1', [ctrl '/reference'], ...
        'Port', '1', 'Position', [20 50 50 70]);
    add_block('simulink/Ports & Subsystems/In1', [ctrl '/speed'], ...
        'Port', '2', 'Position', [20 145 50 165]);
    add_block('simulink/Ports & Subsystems/Out1', [ctrl '/u_sat'], ...
        'Port', '1', 'Position', [735 55 765 75]);
    add_block('simulink/Ports & Subsystems/Out1', [ctrl '/a0_est'], ...
        'Port', '2', 'Position', [735 235 765 255]);
    add_block('simulink/Ports & Subsystems/Out1', [ctrl '/b0_est'], ...
        'Port', '3', 'Position', [735 275 765 295]);
    add_block('simulink/Ports & Subsystems/Out1', [ctrl '/error'], ...
        'Port', '4', 'Position', [735 115 765 135]);
    add_block('simulink/Ports & Subsystems/Out1', [ctrl '/traceP'], ...
        'Port', '5', 'Position', [735 315 765 335]);

    add_block('simulink/Math Operations/Sum', [ctrl '/Tracking error'], ...
        'Inputs', '+-', 'Position', [90 45 125 85]);
    add_block('simulink/Discrete/Unit Delay', [ctrl '/e_prev'], ...
        'InitialCondition', '0', 'SampleTime', T, ...
        'Position', [175 100 225 140]);
    add_block('simulink/Discrete/Unit Delay', [ctrl '/y_prev'], ...
        'InitialCondition', '0', 'SampleTime', T, ...
        'Position', [175 185 225 225]);
    add_block('simulink/Discrete/Unit Delay', [ctrl '/u_prev'], ...
        'InitialCondition', '0', 'SampleTime', T, ...
        'Position', [620 145 670 185]);

    add_block('simulink/Sources/Constant', [ctrl '/alpha'], ...
        'Value', num(p.alpha), 'Position', [175 315 225 345]);
    add_block('simulink/Sources/Constant', [ctrl '/q0'], ...
        'Value', num(p.q0), 'Position', [370 330 420 360]);
    add_block('simulink/Sources/Constant', [ctrl '/q1'], ...
        'Value', num(p.q1), 'Position', [370 395 420 425]);
    add_block('simulink/Sources/Constant', [ctrl '/b0 guard'], ...
        'Value', num(p.b0Min), 'Position', [370 460 420 490]);

    add_block('simulink/User-Defined Functions/MATLAB Function', ...
        [ctrl '/RLS Estimator'], 'Position', [270 195 390 305]);
    setFunctionScript([ctrl '/RLS Estimator'], [ ...
        "function [a0_est,b0_est,traceP] = rls_estimator(y_curr,y_prev,u_prev,alpha)" newline ...
        "%#codegen" newline ...
        "% RLS for G(z) = b0/(z + a0). Excitation gate: skip the update when" newline ...
        "% the regressor is ~zero (motor idle) so P = P/alpha cannot wind up." newline ...
        "persistent P xe" newline ...
        "if isempty(P)" newline ...
        "    P = 100.0 * eye(2);" newline ...
        "    xe = [-0.5; 1.0];" newline ...
        "end" newline ...
        "C = [-y_prev, u_prev];" newline ...
        "if (C * C') > 1e-6" newline ...
        "    den = C * P * C' + alpha;" newline ...
        "    L = (P * C') / den;" newline ...
        "    xe = xe + L * (y_curr - C * xe);" newline ...
        "    P = (eye(2) - L * C) * P / alpha;" newline ...
        "    P = 0.5 * (P + P');" newline ...
        "end" newline ...
        "a0_est = xe(1);" newline ...
        "b0_est = xe(2);" newline ...
        "traceP = P(1,1) + P(2,2);" newline ...
        "end"]);

    add_block('simulink/User-Defined Functions/MATLAB Function', ...
        [ctrl '/Pole placement'], 'Position', [475 205 590 315]);
    setFunctionScript([ctrl '/Pole placement'], [ ...
        "function [d0,d1] = pole_placement(a0,b0,q0,q1,b0Min)" newline ...
        "%#codegen" newline ...
        "% Hold the previous gains while |b0| is too small (guard against" newline ...
        "% division blow-up before the estimator has converged)." newline ...
        "persistent d0Hold d1Hold" newline ...
        "if isempty(d0Hold)" newline ...
        "    d0Hold = -0.44;" newline ...
        "    d1Hold = 1.0;" newline ...
        "end" newline ...
        "if abs(b0) > b0Min" newline ...
        "    d0Hold = (q0 + a0) / b0;" newline ...
        "    d1Hold = (q1 + 1.0 - a0) / b0;" newline ...
        "end" newline ...
        "d0 = d0Hold;" newline ...
        "d1 = d1Hold;" newline ...
        "end"]);

    add_block('simulink/User-Defined Functions/MATLAB Function', ...
        [ctrl '/Incremental PI'], 'Position', [420 35 555 145]);
    setFunctionScript([ctrl '/Incremental PI'], [ ...
        "function u = incremental_pi(d0,d1,e,ePrev,uPrev)" newline ...
        "%#codegen" newline ...
        "u = uPrev + d1 * e + d0 * ePrev;" newline ...
        "end"]);

    add_block('simulink/Discontinuities/Saturation', [ctrl '/PWM saturation'], ...
        'UpperLimit', num(p.uMax), 'LowerLimit', num(-p.uMax), ...
        'Position', [610 45 675 85]);

    add_line(ctrl, 'reference/1', 'Tracking error/1', 'autorouting', 'on');
    add_line(ctrl, 'speed/1', 'Tracking error/2', 'autorouting', 'on');
    add_line(ctrl, 'Tracking error/1', 'e_prev/1', 'autorouting', 'on');
    add_line(ctrl, 'Tracking error/1', 'Incremental PI/3', 'autorouting', 'on');
    add_line(ctrl, 'Tracking error/1', 'error/1', 'autorouting', 'on');
    add_line(ctrl, 'speed/1', 'y_prev/1', 'autorouting', 'on');
    add_line(ctrl, 'speed/1', 'RLS Estimator/1', 'autorouting', 'on');
    add_line(ctrl, 'y_prev/1', 'RLS Estimator/2', 'autorouting', 'on');
    add_line(ctrl, 'u_prev/1', 'RLS Estimator/3', 'autorouting', 'on');
    add_line(ctrl, 'alpha/1', 'RLS Estimator/4', 'autorouting', 'on');
    add_line(ctrl, 'RLS Estimator/1', 'Pole placement/1', 'autorouting', 'on');
    add_line(ctrl, 'RLS Estimator/1', 'a0_est/1', 'autorouting', 'on');
    add_line(ctrl, 'RLS Estimator/2', 'Pole placement/2', 'autorouting', 'on');
    add_line(ctrl, 'RLS Estimator/2', 'b0_est/1', 'autorouting', 'on');
    add_line(ctrl, 'RLS Estimator/3', 'traceP/1', 'autorouting', 'on');
    add_line(ctrl, 'q0/1', 'Pole placement/3', 'autorouting', 'on');
    add_line(ctrl, 'q1/1', 'Pole placement/4', 'autorouting', 'on');
    add_line(ctrl, 'b0 guard/1', 'Pole placement/5', 'autorouting', 'on');
    add_line(ctrl, 'Pole placement/1', 'Incremental PI/1', 'autorouting', 'on');
    add_line(ctrl, 'Pole placement/2', 'Incremental PI/2', 'autorouting', 'on');
    add_line(ctrl, 'e_prev/1', 'Incremental PI/4', 'autorouting', 'on');
    add_line(ctrl, 'u_prev/1', 'Incremental PI/5', 'autorouting', 'on');
    add_line(ctrl, 'Incremental PI/1', 'PWM saturation/1', 'autorouting', 'on');
    add_line(ctrl, 'PWM saturation/1', 'u_prev/1', 'autorouting', 'on');
    add_line(ctrl, 'PWM saturation/1', 'u_sat/1', 'autorouting', 'on');
end

%% -------------------------------------------- exact ZOH first-order plant
function buildPlant(plant, p)
    % omega(k+1) = A*omega(k) + B*u(k),  A = exp(-b*T/J), B = (Km/b)*(1-A)
    T = num(p.T);
    add_block('simulink/Ports & Subsystems/In1', [plant '/u'], ...
        'Port', '1', 'Position', [25 55 55 75]);
    add_block('simulink/Ports & Subsystems/In1', [plant '/J'], ...
        'Port', '2', 'Position', [25 155 55 175]);
    add_block('simulink/Ports & Subsystems/Out1', [plant '/omega'], ...
        'Position', [545 55 575 75]);
    add_block('simulink/Discrete/Unit Delay', [plant '/omega state'], ...
        'InitialCondition', '0', 'SampleTime', T, ...
        'Position', [440 45 490 85]);
    add_block('simulink/Sources/Constant', [plant '/minus bT'], ...
        'Value', num(-p.b * p.T), 'Position', [80 215 135 245]);
    add_block('simulink/Math Operations/Product', [plant '/divide by J'], ...
        'Inputs', '*/', 'Position', [175 165 220 210]);
    add_block('simulink/Math Operations/Math Function', [plant '/exp'], ...
        'Operator', 'exp', 'Position', [255 170 305 205]);
    add_block('simulink/Sources/Constant', [plant '/one'], ...
        'Value', '1', 'Position', [250 250 290 280]);
    add_block('simulink/Math Operations/Sum', [plant '/one minus A'], ...
        'Inputs', '+-', 'Position', [335 215 370 265]);
    add_block('simulink/Math Operations/Gain', [plant '/Km over b'], ...
        'Gain', num(p.Km / p.b), 'Position', [400 220 445 260]);
    add_block('simulink/Math Operations/Product', [plant '/A times omega'], ...
        'Position', [335 70 375 110]);
    add_block('simulink/Math Operations/Product', [plant '/B times u'], ...
        'Position', [335 135 375 175]);
    add_block('simulink/Math Operations/Sum', [plant '/state update'], ...
        'Inputs', '++', 'Position', [405 110 435 170]);

    add_line(plant, 'J/1', 'divide by J/2', 'autorouting', 'on');
    add_line(plant, 'minus bT/1', 'divide by J/1', 'autorouting', 'on');
    add_line(plant, 'divide by J/1', 'exp/1', 'autorouting', 'on');
    add_line(plant, 'exp/1', 'one minus A/2', 'autorouting', 'on');
    add_line(plant, 'one/1', 'one minus A/1', 'autorouting', 'on');
    add_line(plant, 'one minus A/1', 'Km over b/1', 'autorouting', 'on');
    add_line(plant, 'exp/1', 'A times omega/1', 'autorouting', 'on');
    add_line(plant, 'omega state/1', 'A times omega/2', 'autorouting', 'on');
    add_line(plant, 'Km over b/1', 'B times u/1', 'autorouting', 'on');
    add_line(plant, 'u/1', 'B times u/2', 'autorouting', 'on');
    add_line(plant, 'A times omega/1', 'state update/1', 'autorouting', 'on');
    add_line(plant, 'B times u/1', 'state update/2', 'autorouting', 'on');
    add_line(plant, 'state update/1', 'omega state/1', 'autorouting', 'on');
    add_line(plant, 'omega state/1', 'omega/1', 'autorouting', 'on');
end

%% ------------------------------------- Stage 3: simulation model (S->L->S)
function buildSimModel(p, outDir)
    mdl = 'adaptive_dcmotor_sim';
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    new_system(mdl);
    set_param(mdl, ...
        'SolverType', 'Fixed-step', ...
        'Solver', 'FixedStepDiscrete', ...
        'FixedStep', num(p.T), ...
        'StopTime', num(p.simTime), ...
        'SignalLogging', 'on', ...
        'SignalLoggingName', 'logsout', ...
        'Location', [100 100 1550 760]);

    add_block('simulink/Sources/Pulse Generator', [mdl '/Speed reference'], ...
        'PulseType', 'Time based', 'TimeSource', 'Use simulation time', ...
        'Amplitude', num(p.refAmplitude), 'Period', num(p.refPeriod), ...
        'PulseWidth', '50', 'PhaseDelay', num(p.refDelay), 'SampleTime', num(p.T), ...
        'Position', [45 105 105 155]);

    ctrl = [mdl '/Adaptive controller'];
    add_block('simulink/Ports & Subsystems/Subsystem', ctrl, ...
        'Position', [190 70 410 230]);
    Simulink.SubSystem.deleteContents(ctrl);
    buildControllerSubsystem(ctrl, p);

    % Inertia profile: J_small -> J_large at swapUp -> J_small at swapDown
    dJ = p.J_large - p.J_small;
    add_block('simulink/Sources/Constant', [mdl '/J base'], ...
        'Value', num(p.J_small), 'Position', [430 255 490 285]);
    add_block('simulink/Sources/Step', [mdl '/Swap up'], ...
        'Time', num(p.swapUp), 'Before', '0', 'After', num(dJ), ...
        'SampleTime', num(p.T), 'Position', [430 305 490 335]);
    add_block('simulink/Sources/Step', [mdl '/Swap down'], ...
        'Time', num(p.swapDown), 'Before', '0', 'After', num(-dJ), ...
        'SampleTime', num(p.T), 'Position', [430 355 490 385]);
    add_block('simulink/Math Operations/Sum', [mdl '/Inertia profile'], ...
        'Inputs', '+++', 'Position', [520 300 550 350]);

    plant = [mdl '/Variable inertia plant'];
    add_block('simulink/Ports & Subsystems/Subsystem', plant, ...
        'Position', [570 70 760 210]);
    Simulink.SubSystem.deleteContents(plant);
    buildPlant(plant, p);

    % Measurement noise, active only while the motor can move (t >= refDelay).
    % Models the encoder: at standstill the measured speed is exactly zero.
    add_block('simulink/Sources/Random Number', [mdl '/Measurement noise'], ...
        'Mean', '0', 'Variance', num(p.noiseVariance), 'Seed', num(p.noiseSeed), ...
        'SampleTime', num(p.T), 'Position', [620 335 700 375]);
    add_block('simulink/Sources/Step', [mdl '/Noise enable'], ...
        'Time', num(p.refDelay), 'Before', '0', 'After', '1', ...
        'SampleTime', num(p.T), 'Position', [620 395 700 425]);
    add_block('simulink/Math Operations/Product', [mdl '/Gated noise'], ...
        'Position', [730 350 770 390]);
    add_block('simulink/Math Operations/Sum', [mdl '/Measured speed'], ...
        'Inputs', '++', 'Position', [830 105 865 155]);

    add_block('simulink/Signal Routing/Mux', [mdl '/Tracking mux'], ...
        'Inputs', '3', 'Position', [990 70 995 190]);
    add_block('simulink/Sinks/Scope', [mdl '/Tracking scope'], ...
        'Position', [1060 105 1110 155]);
    configureScope([mdl '/Tracking scope'], 1, true);
    add_block('simulink/Signal Routing/Mux', [mdl '/a0b0 mux'], ...
        'Inputs', '2', 'Position', [930 320 935 370]);
    add_block('simulink/Sinks/Scope', [mdl '/Adaptation scope'], ...
        'Position', [1060 300 1110 420]);
    configureScope([mdl '/Adaptation scope'], 4, true);

    add_line(mdl, 'Speed reference/1', 'Adaptive controller/1', 'autorouting', 'on');
    add_line(mdl, 'Adaptive controller/1', 'Variable inertia plant/1', 'autorouting', 'on');
    add_line(mdl, 'J base/1', 'Inertia profile/1', 'autorouting', 'on');
    add_line(mdl, 'Swap up/1', 'Inertia profile/2', 'autorouting', 'on');
    add_line(mdl, 'Swap down/1', 'Inertia profile/3', 'autorouting', 'on');
    add_line(mdl, 'Inertia profile/1', 'Variable inertia plant/2', 'autorouting', 'on');
    add_line(mdl, 'Variable inertia plant/1', 'Measured speed/1', 'autorouting', 'on');
    add_line(mdl, 'Measurement noise/1', 'Gated noise/1', 'autorouting', 'on');
    add_line(mdl, 'Noise enable/1', 'Gated noise/2', 'autorouting', 'on');
    add_line(mdl, 'Gated noise/1', 'Measured speed/2', 'autorouting', 'on');
    add_line(mdl, 'Measured speed/1', 'Adaptive controller/2', 'autorouting', 'on');

    % Feed lines to the tracking mux are left unnamed: naming these branched
    % signals only clutters the block diagram with overlapping labels.
    add_line(mdl, 'Speed reference/1', 'Tracking mux/1', 'autorouting', 'on');
    add_line(mdl, 'Variable inertia plant/1', 'Tracking mux/2', 'autorouting', 'on');
    add_line(mdl, 'Measured speed/1', 'Tracking mux/3', 'autorouting', 'on');
    add_line(mdl, 'Tracking mux/1', 'Tracking scope/1', 'autorouting', 'on');

    add_line(mdl, 'Adaptive controller/2', 'a0b0 mux/1', 'autorouting', 'on');
    add_line(mdl, 'Adaptive controller/3', 'a0b0 mux/2', 'autorouting', 'on');
    add_line(mdl, 'Adaptive controller/1', 'Adaptation scope/1', 'autorouting', 'on');
    add_line(mdl, 'a0b0 mux/1', 'Adaptation scope/2', 'autorouting', 'on');
    add_line(mdl, 'Adaptive controller/5', 'Adaptation scope/3', 'autorouting', 'on');
    add_line(mdl, 'Inertia profile/1', 'Adaptation scope/4', 'autorouting', 'on');

    logSignal([mdl '/Speed reference'], 1, 'ref');
    logSignal([mdl '/Variable inertia plant'], 1, 'y_true');
    logSignal([mdl '/Measured speed'], 1, 'y');
    logSignal([mdl '/Adaptive controller'], 1, 'u');
    logSignal([mdl '/Adaptive controller'], 2, 'a0_est');
    logSignal([mdl '/Adaptive controller'], 3, 'b0_est');
    logSignal([mdl '/Adaptive controller'], 5, 'traceP');
    logSignal([mdl '/Inertia profile'], 1, 'J');

    addNote(mdl, ['Stage 3 - adaptive DC-motor speed control (simulation).' newline ...
        'RLS parameter estimation + pole placement + incremental PI, T = 80 ms.'], [45 20]);
    addNote(mdl, ['Scenario: 0->50 rad/s speed reference (square, period 16 s), ' ...
        'first 4 s idle to exercise the RLS excitation gate.' newline ...
        'Inertia swap S->L at t=32 s, L->S at t=64 s. StopTime 96 s = 6 reference periods.' newline ...
        'NOTE: the inertia swap is demonstrated in simulation only - the test bench runs ' ...
        'the bare motor (no flywheel mounted for submission).'], [45 560]);
    save_system(mdl, fullfile(outDir, [mdl '.slx']));
    close_system(mdl, 0);
    fprintf('Built %s\n', fullfile(outDir, [mdl '.slx']));
end

%% ------------------------------------ Stage 3: ESP32 hardware model
function buildHardwareModel(p, outDir)
    mdl = 'adaptive_dcmotor';
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    new_system(mdl);
    applyEsp32Config(mdl, p);

    add_block('simulink/Sources/Constant', [mdl '/omega_ref'], ...
        'Value', '0', 'SampleTime', num(p.T), 'Position', [40 98 110 132]);

    ctrl = [mdl '/Adaptive controller'];
    add_block('simulink/Ports & Subsystems/Subsystem', ctrl, ...
        'Position', [430 70 650 230]);
    Simulink.SubSystem.deleteContents(ctrl);
    buildControllerSubsystem(ctrl, p);

    % --- actuator path: u_sat -> |u| / direction -> PWM + IN1/IN2
    add_block('simulink/User-Defined Functions/MATLAB Function', ...
        [mdl '/H-bridge map'], 'Position', [720 85 830 175]);
    setFunctionScript([mdl '/H-bridge map'], [ ...
        "function [pwm,in1,in2] = hbridge_map(u)" newline ...
        "%#codegen" newline ...
        "% |u| -> PWM duty (0..255), sign(u) -> L298N direction pins" newline ...
        "pwm = abs(u);" newline ...
        "if u >= 0" newline ...
        "    in1 = 1; in2 = 0;" newline ...
        "else" newline ...
        "    in1 = 0; in2 = 1;" newline ...
        "end" newline ...
        "end"]);
    addLibBlock('arduinolib/PWM', [mdl '/PWM GPIO14'], [900 75 970 115], ...
        'pinNumber', num(p.pinPWM));
    addLibBlock('arduinolib/Digital Output', [mdl '/IN1 GPIO26'], [900 135 970 175], ...
        'pinNumber', num(p.pinIN1));
    addLibBlock('arduinolib/Digital Output', [mdl '/IN2 GPIO27'], [900 195 970 235], ...
        'pinNumber', num(p.pinIN2));

    % --- sensor path: Encoder -> double -> delta N -> rad/s
    addLibBlock('arduinosensorlib/Encoder', [mdl '/Encoder'], [40 260 120 320], ...
        'InputA', num(p.pinEncA), 'InputB', num(p.pinEncB), 'SampleTime', num(p.T));
    add_block('simulink/Signal Attributes/Data Type Conversion', ...
        [mdl '/Count to double'], 'OutDataTypeStr', 'double', ...
        'Position', [150 275 210 305]);
    add_block('simulink/Discrete/Unit Delay', [mdl '/N_prev'], ...
        'InitialCondition', '0', 'SampleTime', num(p.T), ...
        'Position', [235 330 285 370]);
    add_block('simulink/Math Operations/Sum', [mdl '/Delta N'], ...
        'Inputs', '+-', 'Position', [310 275 345 315]);
    add_block('simulink/Math Operations/Gain', [mdl '/Counts to rad_s'], ...
        'Gain', sprintf('2*pi/(%s*%s)', num(p.T), num(p.CPR)), ...
        'Position', [370 270 430 320]);

    % --- scopes for Monitor & Tune
    add_block('simulink/Signal Routing/Mux', [mdl '/Tracking mux'], ...
        'Inputs', '2', 'Position', [1050 280 1055 360]);
    add_block('simulink/Sinks/Scope', [mdl '/Tracking scope'], ...
        'Position', [1100 295 1150 345]);
    configureScope([mdl '/Tracking scope'], 1, true);
    add_block('simulink/Signal Routing/Mux', [mdl '/a0b0 mux'], ...
        'Inputs', '2', 'Position', [990 450 995 500]);
    add_block('simulink/Sinks/Scope', [mdl '/Adaptation scope'], ...
        'Position', [1100 430 1150 550]);
    configureScope([mdl '/Adaptation scope'], 4, true);

    nameLine(add_line(mdl, 'omega_ref/1', 'Adaptive controller/1', 'autorouting', 'on'), 'omega_ref');
    nameLine(add_line(mdl, 'Encoder/1', 'Count to double/1', 'autorouting', 'on'), 'N');
    add_line(mdl, 'Count to double/1', 'Delta N/1', 'autorouting', 'on');
    add_line(mdl, 'Count to double/1', 'N_prev/1', 'autorouting', 'on');
    add_line(mdl, 'N_prev/1', 'Delta N/2', 'autorouting', 'on');
    add_line(mdl, 'Delta N/1', 'Counts to rad_s/1', 'autorouting', 'on');
    nameLine(add_line(mdl, 'Counts to rad_s/1', 'Adaptive controller/2', 'autorouting', 'on'), 'omega');
    nameLine(add_line(mdl, 'Adaptive controller/1', 'H-bridge map/1', 'autorouting', 'on'), 'u');
    add_line(mdl, 'H-bridge map/1', 'PWM GPIO14/1', 'autorouting', 'on');
    add_line(mdl, 'H-bridge map/2', 'IN1 GPIO26/1', 'autorouting', 'on');
    add_line(mdl, 'H-bridge map/3', 'IN2 GPIO27/1', 'autorouting', 'on');

    add_line(mdl, 'omega_ref/1', 'Tracking mux/1', 'autorouting', 'on');
    add_line(mdl, 'Counts to rad_s/1', 'Tracking mux/2', 'autorouting', 'on');
    add_line(mdl, 'Tracking mux/1', 'Tracking scope/1', 'autorouting', 'on');
    nameLine(add_line(mdl, 'Adaptive controller/2', 'a0b0 mux/1', 'autorouting', 'on'), 'a0_est');
    nameLine(add_line(mdl, 'Adaptive controller/3', 'a0b0 mux/2', 'autorouting', 'on'), 'b0_est');
    add_line(mdl, 'Adaptive controller/1', 'Adaptation scope/1', 'autorouting', 'on');
    add_line(mdl, 'a0b0 mux/1', 'Adaptation scope/2', 'autorouting', 'on');
    nameLine(add_line(mdl, 'Adaptive controller/4', 'Adaptation scope/3', 'autorouting', 'on'), 'e');
    nameLine(add_line(mdl, 'Adaptive controller/5', 'Adaptation scope/4', 'autorouting', 'on'), 'traceP');

    addNote(mdl, ['Stage 3 - adaptive controller on ESP32 (External Mode). Bare motor, ' ...
        'no flywheel.' newline 'Pins: PWM 14, IN1/IN2 26/27, Encoder A/B 32/33. T = 80 ms.'], [40 30]);
    save_system(mdl, fullfile(outDir, [mdl '.slx']));
    close_system(mdl, 0);
    fprintf('Built %s\n', fullfile(outDir, [mdl '.slx']));
end

%% ------------------------------------ Stage 2: encoder test model
function buildEncoderTest(p, outDir)
    mdl = 'encoder_test';
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    new_system(mdl);
    applyEsp32Config(mdl, p);

    % Stage-1 PWM path (spin the motor while checking the encoder)
    add_block('simulink/Sources/Constant', [mdl '/duty'], ...
        'Value', '0', 'SampleTime', num(p.T), 'Position', [60 90 130 124]);
    addLibBlock('arduinolib/PWM', [mdl '/PWM GPIO14'], [220 80 290 120], ...
        'pinNumber', num(p.pinPWM));
    add_block('simulink/Sources/Constant', [mdl '/dir 1'], ...
        'Value', '1', 'Position', [60 150 130 184]);
    addLibBlock('arduinolib/Digital Output', [mdl '/IN1 GPIO26'], [220 145 290 185], ...
        'pinNumber', num(p.pinIN1));
    add_block('simulink/Sources/Constant', [mdl '/dir 0'], ...
        'Value', '0', 'Position', [60 210 130 244]);
    addLibBlock('arduinolib/Digital Output', [mdl '/IN2 GPIO27'], [220 205 290 245], ...
        'pinNumber', num(p.pinIN2));

    % Sensor path
    addLibBlock('arduinosensorlib/Encoder', [mdl '/Encoder'], [60 300 140 360], ...
        'InputA', num(p.pinEncA), 'InputB', num(p.pinEncB), 'SampleTime', num(p.T));
    add_block('simulink/Signal Attributes/Data Type Conversion', ...
        [mdl '/Count to double'], 'OutDataTypeStr', 'double', ...
        'Position', [170 315 230 345]);
    add_block('simulink/Sinks/Display', [mdl '/Raw count N'], ...
        'Position', [300 250 400 290]);
    add_block('simulink/Discrete/Unit Delay', [mdl '/N_prev'], ...
        'InitialCondition', '0', 'SampleTime', num(p.T), ...
        'Position', [255 370 305 410]);
    add_block('simulink/Math Operations/Sum', [mdl '/Delta N'], ...
        'Inputs', '+-', 'Position', [330 315 365 355]);
    add_block('simulink/Math Operations/Gain', [mdl '/Counts to rad_s'], ...
        'Gain', sprintf('2*pi/(%s*%s)', num(p.T), num(p.CPR)), ...
        'Position', [390 310 450 360]);
    add_block('simulink/Sinks/Scope', [mdl '/omega scope'], ...
        'Position', [490 285 540 335]);
    add_block('simulink/Sinks/Display', [mdl '/omega rad_s'], ...
        'Position', [490 360 590 400]);

    add_line(mdl, 'duty/1', 'PWM GPIO14/1', 'autorouting', 'on');
    add_line(mdl, 'dir 1/1', 'IN1 GPIO26/1', 'autorouting', 'on');
    add_line(mdl, 'dir 0/1', 'IN2 GPIO27/1', 'autorouting', 'on');
    nameLine(add_line(mdl, 'Encoder/1', 'Count to double/1', 'autorouting', 'on'), 'N');
    add_line(mdl, 'Count to double/1', 'Raw count N/1', 'autorouting', 'on');
    add_line(mdl, 'Count to double/1', 'Delta N/1', 'autorouting', 'on');
    add_line(mdl, 'Count to double/1', 'N_prev/1', 'autorouting', 'on');
    add_line(mdl, 'N_prev/1', 'Delta N/2', 'autorouting', 'on');
    add_line(mdl, 'Delta N/1', 'Counts to rad_s/1', 'autorouting', 'on');
    nameLine(add_line(mdl, 'Counts to rad_s/1', 'omega scope/1', 'autorouting', 'on'), 'omega');
    add_line(mdl, 'Counts to rad_s/1', 'omega rad_s/1', 'autorouting', 'on');

    addNote(mdl, ['Stage 2 - encoder + PWM check on the bare motor.' newline ...
        'Read raw counts, calibrate CPR with the 1-revolution test (see TESTPLAN).'], [40 20]);
    save_system(mdl, fullfile(outDir, [mdl '.slx']));
    close_system(mdl, 0);
    fprintf('Built %s\n', fullfile(outDir, [mdl '.slx']));
end

%% ---------------------------------------------------------- local helpers
function applyEsp32Config(mdl, p)
    % Copy the ESP32 board + XCP External-Mode config from the donor model,
    % then override only the loop rate. The donor is never saved.
    cs = copy(getActiveConfigSet('pwm_test'));
    cs.Name = 'ESP32Config';
    attachConfigSet(mdl, cs, true);
    setActiveConfigSet(mdl, cs.Name);
    set_param(mdl, 'FixedStep', num(p.T), 'StopTime', 'inf');
    fprintf('%s: HardwareBoard = "%s", SystemTargetFile = %s, FixedStep = %s\n', ...
        mdl, get_param(mdl, 'HardwareBoard'), ...
        get_param(mdl, 'SystemTargetFile'), get_param(mdl, 'FixedStep'));
end

function setFunctionScript(blockPath, code)
    rt = sfroot;
    chart = rt.find('-isa', 'Stateflow.EMChart', 'Path', blockPath);
    if isempty(chart), error('MATLAB Function chart not found: %s', blockPath); end
    chart.Script = char(code);
end

function logSignal(blockPath, portNumber, signalName)
    ports = get_param(blockPath, 'PortHandles');
    set_param(ports.Outport(portNumber), 'DataLogging', 'on', ...
        'DataLoggingNameMode', 'Custom', 'DataLoggingName', signalName);
end

function nameLine(lineHandle, name)
    set_param(lineHandle, 'Name', name);
end

function configureScope(scopePath, nAxes, showLegend)
    % Stack nAxes y-axes in one Scope (one input port per axis) so signals
    % with very different scales (e.g. u ~ 255 vs. a0 ~ 1) stay readable.
    set_param(scopePath, 'NumInputPorts', num2str(nAxes));
    sc = get_param(scopePath, 'ScopeConfiguration');
    sc.LayoutDimensions = [nAxes 1];
    % Do not auto-open scope windows: headless -batch validation must stay
    % reproducible (auto-open spawns GUI windows that stall the batch run).
    sc.OpenAtSimulationStart = false;
    sc.ShowLegend = logical(showLegend);
end

function addNote(mdl, text, pos)
    h = Simulink.Annotation(mdl, text);
    h.position = pos;   % [x y] top-left corner
end

function addLibBlock(src, dst, position, varargin)
    % add_block for support-package library blocks; on a bad parameter
    % name, dump the block's DialogParameters so the log shows the fix.
    add_block(src, dst, 'Position', position);
    for k = 1:2:numel(varargin)
        try
            set_param(dst, varargin{k}, varargin{k+1});
        catch e
            fprintf(2, 'set_param %s on %s failed: %s\nDialogParameters:\n', ...
                varargin{k}, dst, e.message);
            disp(get_param(dst, 'DialogParameters'));
            rethrow(e);
        end
    end
end
