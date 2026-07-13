%% Study encoder-limited identifiability of the second-order motor model.
%
% Runs open-loop second-order identification with a full-order PRBS voltage
% input and compares exact speed sensing with encoder-quantised speed
% sensing. This removes closed-loop bias and poor excitation from the
% explanation: the remaining difference is the speed sensor.
%
% Usage:
%   cd matlab
%   matlab -batch "identifiability_study"

scriptDir = fileparts(mfilename('fullpath'));
addpath(scriptDir);

p = second_order_params();
rng(0);

tEnd = 60.0;
fixedT = 0.080;
realCPR = 44;          % Measured rig encoder: 11 PPR with x4 quadrature.
rigFullDutySpeed = 780;
rigModerateSpeed = 90;
cprSweep = [44 176 704 2816];
timeSweep = [0.080 0.020 0.005 0.002];

fprintf('\n--- encoder-limited second-order identifiability study ---\n');
fprintf('Open-loop PRBS amplitude: %.6g V, run length: %.1f s\n', p.uMax, tEnd);
fprintf('RLS: alpha = 1, P0 = 100*eye(4), theta = [a1; a0; b1; b0]\n');

fprintf('\nModel sensitivity from exact ZOH discretisation:\n');
for k = 1:numel(timeSweep)
    thetaTrue = trueCoefficients(p, timeSweep(k));
    fprintf(['T = %6.1f ms: a1 = %+13.6e, a0 = %+13.6e, ' ...
        'b1 = %+13.6e, b0 = %+13.6e, b0/b1 = %8.3f %%\n'], ...
        1000 * timeSweep(k), thetaTrue(1), thetaTrue(2), ...
        thetaTrue(3), thetaTrue(4), 100 * thetaTrue(4) / thetaTrue(3));
end

data80 = simulateOpenLoop(p, fixedT, tEnd);

fprintf('\nSweep 1 - fixed T = %.1f ms, varying encoder resolution\n', 1000 * fixedT);
printEncoderSweepHeader();
sweep1 = repmat(emptyResult(), numel(cprSweep) + 1, 1);
for k = 1:numel(cprSweep)
    sweep1(k) = identifyFromData(data80, cprSweep(k));
    printEncoderSweepRow(sprintf('%d', cprSweep(k)), sweep1(k));
end
sweep1(end) = identifyFromData(data80, Inf);
printEncoderSweepRow('exact', sweep1(end));

fprintf('\nSweep 2 - fixed CPR = %d, varying sampling time\n', realCPR);
printTimeSweepHeader();
sweep2 = repmat(emptyResult(), numel(timeSweep), 1);
for k = 1:numel(timeSweep)
    if abs(timeSweep(k) - fixedT) < eps
        data = data80;
    else
        data = simulateOpenLoop(p, timeSweep(k), tEnd);
    end
    sweep2(k) = identifyFromData(data, realCPR);
    printTimeSweepRow(timeSweep(k), sweep2(k));
end

% This block uses only measured rig constants and no model, so it holds
% regardless of the motor parameters. At T = 2 ms the moderate-speed row is
% about 1.3 counts per sample, so the speed signal degenerates to a one-bit
% signal.
fprintf(['\nEncoder resolution on the rig (measured: CPR = %d, ' ...
    'full-duty speed %.0f rad/s)\n'], realCPR, rigFullDutySpeed);
printRigEncoderHeader();
for k = 1:numel(timeSweep)
    printRigEncoderRow(timeSweep(k), realCPR, rigFullDutySpeed, rigModerateSpeed);
end
rigCounts2ms90 = encoderCountsPerSample(0.002, realCPR, rigModerateSpeed);

exact80 = sweep1(end);
real80 = sweep1(1);
real2ms = sweep2(end);

assert(abs(exact80.b0RelErrPct) < 5, ...
    'Exact speed at T = 80 ms did not recover b0: relative error %.3f %%.', ...
    exact80.b0RelErrPct);
% The true a0 at T = 80 ms is near zero, so a relative a0 error is
% meaningless; the absolute estimate must be small instead.
assert(abs(exact80.thetaEst(2)) < 1e-2, ...
    'Exact speed at T = 80 ms did not keep a0 near zero: a0_est %.6g.', ...
    exact80.thetaEst(2));
assert(abs(exact80.a1RelErrPct) < 5, ...
    'Exact speed at T = 80 ms did not recover a1: relative error %.3f %%.', ...
    exact80.a1RelErrPct);
assert(abs(exact80.b1RelErrPct) < 5, ...
    'Exact speed at T = 80 ms did not recover b1: relative error %.3f %%.', ...
    exact80.b1RelErrPct);
assert(abs(real80.b0RelErrPct) > 100, ...
    'Real encoder at T = 80 ms did not lose b0: relative error %.3f %%.', ...
    real80.b0RelErrPct);
assert(abs(real2ms.b0RelErrPct) > 50, ...
    'Real encoder at T = 2 ms did not fail b0 identification: relative error %.3f %%.', ...
    real2ms.b0RelErrPct);
assert(rigCounts2ms90 < 2, ...
    'Measured rig encoder at T = 2 ms and 90 rad/s gave %.3f counts per sample.', ...
    rigCounts2ms90);
assert(abs(real80.b1RelErrPct) < 5, ...
    'Real encoder at T = 80 ms did not recover b1: relative error %.3f %%.', ...
    real80.b1RelErrPct);

fprintf('\nSummary:\n');
fprintf(['Long T gives fine speed resolution, but the electrical mode has decayed ' ...
    '(sensitivity approximately exp(p_e*T)).\n']);
fprintf(['Short T restores the sensitivity, but the quantisation variance grows as ' ...
    '1/T^2; with CPR = 44 no sampling time satisfies both.\n']);

disp('STUDY_OK');

%% ---------- local functions ----------
function data = simulateOpenLoop(p, T, tEnd)
    thetaTrue = trueCoefficients(p, T);
    n = floor(tEnd / T) + 1;
    u = p.uMax * (2 * (rand(n, 1) >= 0.5) - 1);
    yTrue = zeros(n, 1);

    a1 = thetaTrue(1);
    a0 = thetaTrue(2);
    b1 = thetaTrue(3);
    b0 = thetaTrue(4);

    for k = 3:n
        yTrue(k) = -a1 * yTrue(k-1) - a0 * yTrue(k-2) ...
            + b1 * u(k-1) + b0 * u(k-2);
    end

    data.T = T;
    data.u = u;
    data.yTrue = yTrue;
    data.thetaTrue = thetaTrue;
end

function result = identifyFromData(data, CPR)
    u = data.u;
    if isfinite(CPR)
        step = 2 * pi / (data.T * CPR);
        y = round(data.yTrue / step) * step;
        sigmaQ = step / sqrt(12);
    else
        step = 0;
        sigmaQ = 0;
        y = data.yTrue;
    end

    alpha = 1;
    P = 100 * eye(4);
    xe = zeros(4, 1);
    thetaHist = zeros(numel(y), 4);

    for k = 3:numel(y)
        C  = [-y(k-1), -y(k-2), u(k-1), u(k-2)];
        L  = P*C'/(C*P*C' + alpha);
        xe = xe + L*(y(k) - C*xe);
        P  = (eye(4) - L*C)*P/alpha;   P = 0.5*(P+P');
        thetaHist(k, :) = xe.';
    end

    idxAvg = ceil(0.75 * numel(y)):numel(y);
    thetaEst = mean(thetaHist(idxAvg, :), 1).';
    thetaErr = thetaEst - data.thetaTrue;

    result = emptyResult();
    result.step = step;
    result.sigmaQ = sigmaQ;
    result.qOverYMaxPct = 100 * step / max(abs(data.yTrue));
    result.thetaTrue = data.thetaTrue;
    result.thetaEst = thetaEst;
    result.a1RelErrPct = 100 * thetaErr(1) / data.thetaTrue(1);
    result.a0AbsErr = abs(thetaErr(2));
    result.b1RelErrPct = 100 * thetaErr(3) / data.thetaTrue(3);
    result.b0RelErrPct = 100 * thetaErr(4) / data.thetaTrue(4);
    result.yTrue = data.yTrue;
end

function thetaTrue = trueCoefficients(p, T)
    Gd = c2d(tf(p.Km, [p.La*p.J, p.La*p.b + p.Ra*p.J, ...
        p.Ra*p.b + p.Km^2]), T, 'zoh');
    [numd, dend] = tfdata(Gd, 'v');
    numd = numd / dend(1);
    dend = dend / dend(1);
    thetaTrue = [dend(end-1); dend(end); numd(end-1); numd(end)];
end

function result = emptyResult()
    result = struct( ...
        'step', NaN, ...
        'sigmaQ', NaN, ...
        'qOverYMaxPct', NaN, ...
        'thetaTrue', NaN(4, 1), ...
        'thetaEst', NaN(4, 1), ...
        'a1RelErrPct', NaN, ...
        'a0AbsErr', NaN, ...
        'b1RelErrPct', NaN, ...
        'b0RelErrPct', NaN, ...
        'yTrue', NaN);
end

function printEncoderSweepHeader()
    fprintf('%-8s %13s %13s %15s %12s %12s %14s %12s\n', ...
        'CPR', 'step', 'sigma_q', 'q/|y|max [%]', 'a1 err', 'b1 err', '|a0 err|', 'b0 err');
    fprintf('%-8s %13s %13s %15s %12s %12s %14s %12s\n', ...
        '', '[rad/s]', '[rad/s]', '', '[%]', '[%]', '', '[%]');
    fprintf('%s\n', repmat('-', 1, 108));
end

function printEncoderSweepRow(label, result)
    fprintf('%-8s %13.6f %13.6f %15.3f %12.3f %12.3f %14.6e %12.3f\n', ...
        label, result.step, result.sigmaQ, result.qOverYMaxPct, result.a1RelErrPct, ...
        result.b1RelErrPct, result.a0AbsErr, result.b0RelErrPct);
end

function printTimeSweepHeader()
    fprintf('%-8s %13s %13s %15s %12s %12s %14s %12s\n', ...
        'T', 'step', 'sigma_q', 'q/|y|max [%]', 'a1 err', 'b1 err', '|a0 err|', 'b0 err');
    fprintf('%-8s %13s %13s %15s %12s %12s %14s %12s\n', ...
        '[ms]', '[rad/s]', '[rad/s]', '', '[%]', '[%]', '', '[%]');
    fprintf('%s\n', repmat('-', 1, 108));
end

function printTimeSweepRow(T, result)
    fprintf('%-8.1f %13.6f %13.6f %15.3f %12.3f %12.3f %14.6e %12.3f\n', ...
        1000 * T, result.step, result.sigmaQ, result.qOverYMaxPct, result.a1RelErrPct, ...
        result.b1RelErrPct, result.a0AbsErr, result.b0RelErrPct);
end

function printRigEncoderHeader()
    fprintf('%-8s %18s %20s %20s\n', ...
        'T', 'speed resolution', 'counts at 780', 'counts at 90');
    fprintf('%-8s %18s %20s %20s\n', ...
        '[ms]', '[rad/s]', '[counts]', '[counts]');
    fprintf('%s\n', repmat('-', 1, 72));
end

function printRigEncoderRow(T, CPR, fullDutySpeed, moderateSpeed)
    fprintf('%-8.1f %18.6f %20.3f %20.3f\n', ...
        1000 * T, encoderSpeedResolution(T, CPR), ...
        encoderCountsPerSample(T, CPR, fullDutySpeed), ...
        encoderCountsPerSample(T, CPR, moderateSpeed));
end

function speedResolution = encoderSpeedResolution(T, CPR)
    speedResolution = 2 * pi / (T * CPR);
end

function counts = encoderCountsPerSample(T, CPR, speed)
    counts = speed * T * CPR / (2 * pi);
end
