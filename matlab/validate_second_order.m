%% Validate the second-order adaptive DC-motor simulation model.
%
% Runs adaptive_dcmotor_2nd_sim headless and checks numerical health,
% saturation, covariance boundedness, 4-parameter convergence and steady
% tracking bias in settled second-phase step windows.
%
% Usage:
%   cd matlab
%   matlab -batch "validate_second_order"

scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
modelDir = getenv('ACE_OUT_DIR');
if isempty(modelDir), modelDir = fullfile(repoRoot, 'simulink'); end

p = second_order_params();
mdl = 'adaptive_dcmotor_2nd_sim';
modelFile = fullfile(modelDir, [mdl '.slx']);

load_system(modelFile);
set_param(mdl, 'SimulationMode', 'normal');
out = sim(mdl);
ds = out.logsout;

[t, ref] = getSignal(ds, 'ref');
[~, y] = getSignal(ds, 'y');
[~, u] = getSignal(ds, 'u');
[~, a1] = getSignal(ds, 'a1_est');
[~, a0] = getSignal(ds, 'a0_est');
[~, b1] = getSignal(ds, 'b1_est');
[~, b0] = getSignal(ds, 'b0_est');
[~, trP] = getSignal(ds, 'traceP');

allSignals = [ref; y; u; a1; a0; b1; b0; trP];

idxTheta = t >= 3.0 & t <= 4.0;
thetaTrue = [p.a1; p.a0; p.b1; p.b0];
thetaHatSeries = [a1(idxTheta), a0(idxTheta), b1(idxTheta), b0(idxTheta)];
thetaHat = mean(thetaHatSeries, 1).';
thetaErr = abs(thetaHat - thetaTrue);
thetaTol = 0.05 * max(abs(thetaTrue), 0.05);
closedLoopDcGain = closedLoopT1(p.a1, p.a0, p.b1, p.b0, p.q0, p.q1, p.q2, p.q3);

trackingWindows = [5.0 5.5; 6.5 7.0; 7.5 8.0];
nTrackingWindows = size(trackingWindows, 1);
trackingBias = zeros(nTrackingWindows, 1);
trackingBiasPct = zeros(nTrackingWindows, 1);
trackingRms = zeros(nTrackingWindows, 1);
trackingRmsPct = zeros(nTrackingWindows, 1);
trackingSetpoint = zeros(nTrackingWindows, 1);
for k = 1:nTrackingWindows
    idxTrack = t >= trackingWindows(k, 1) & t < trackingWindows(k, 2);
    trackingSetpoint(k) = median(ref(idxTrack));
    refScale = max(abs(trackingSetpoint(k)), 1e-9);
    trackingErr = y(idxTrack) - ref(idxTrack);
    trackingBias(k) = abs(mean(trackingErr));
    trackingBiasPct(k) = 100 * trackingBias(k) / refScale;
    trackingRms(k) = sqrt(mean(trackingErr.^2));
    trackingRmsPct(k) = 100 * trackingRms(k) / refScale;
end

stepTime = 5.5;
stepTarget = 130;
stepAmplitude = 40;
idxStep = t >= stepTime & t < 7.0;
stepPeak = max(y(idxStep));
stepOvershoot = max(0, stepPeak - stepTarget);
stepOvershootPct = 100 * stepOvershoot / stepAmplitude;
stepSettlingTime = settlingTime2Pct(t(idxStep), y(idxStep), stepTime, stepTarget);

fprintf('\n--- adaptive_dcmotor_2nd_sim acceptance report ---\n');
fprintf('Actuator range observed: [%8.4f, %8.4f] V\n', min(u), max(u));
fprintf('trace(P) max over run:   %.6g\n', max(trP));
fprintf('Max normalized parameter error, t=3..4 s: %.6g\n', max(thetaErr ./ thetaTol));
fprintf('Closed-loop steady-state gain T(1): %.10g\n', closedLoopDcGain);
for k = 1:nTrackingWindows
    fprintf(['Tracking window %.1f..%.1f s, setpoint %.1f rad/s: ' ...
        'bias %.4f rad/s (%.3f %%), RMS %.4f rad/s (%.3f %%)\n'], ...
        trackingWindows(k, 1), trackingWindows(k, 2), trackingSetpoint(k), ...
        trackingBias(k), trackingBiasPct(k), trackingRms(k), trackingRmsPct(k));
end
fprintf('Step 5.5 s overshoot: %.4f rad/s (%.3f %% of step)\n', ...
    stepOvershoot, stepOvershootPct);
fprintf('Step 5.5 s 2%% settling time: %.4f s\n', stepSettlingTime);
fprintf('\nParameter | estimated (t=3..4 s) | true | abs error\n');
names = {'a1'; 'a0'; 'b1'; 'b0'};
for k = 1:numel(names)
    fprintf('%-9s | %20.6f | %10.6f | %10.3e\n', ...
        names{k}, thetaHat(k), thetaTrue(k), thetaErr(k));
end

assert(all(isfinite(allSignals)), 'Simulation contains NaN or Inf.');
assert(max(abs(u)) <= p.uMax + 1e-9, 'Actuator saturation was violated.');
assert(max(trP) < 500, 'trace(P) unbounded (%.3g) - covariance windup.', max(trP));
assert(all(thetaErr < thetaTol), ...
    'Parameter convergence failed: max normalized error %.3g.', max(thetaErr ./ thetaTol));
assert(all(trackingBias <= 0.02 * abs(trackingSetpoint)), ...
    'Settled phase-2 tracking bias too large: max %.3f %% of setpoint.', max(trackingBiasPct));

close_system(mdl, 0);
disp('VALIDATION_OK');

%% ---------- local functions ----------
function gain = closedLoopT1(a1, a0, b1, b0, q0, q1, q2, q3)
    M = [1.0,     b1, 0.0, 0.0;
         a1-1.0,  b0, b1,  0.0;
         a0-a1,  0.0, b0,  b1;
        -a0,     0.0, 0.0, b0];
    rhs = [q3 - a1 + 1.0; q2 - a0 + a1; q1 + a0; q0];
    if rcond(M) < 1e-8
        gain = NaN;
        return;
    end
    sol = M \ rhs;
    d2 = sol(2);
    d1 = sol(3);
    d0 = sol(4);
    gain = (b1 + b0) * (d2 + d1 + d0) / (1.0 + q3 + q2 + q1 + q0);
end

function [t, x] = getSignal(ds, name)
    element = ds.getElement(name);
    t = element.Values.Time(:);
    x = squeeze(element.Values.Data);
    x = x(:);
end

function settlingTime = settlingTime2Pct(t, y, stepTime, target)
    tol = 0.02 * abs(target);
    settled = abs(y - target) <= tol;
    settlingTime = NaN;
    for k = 1:numel(t)
        if all(settled(k:end))
            settlingTime = t(k) - stepTime;
            return;
        end
    end
end
