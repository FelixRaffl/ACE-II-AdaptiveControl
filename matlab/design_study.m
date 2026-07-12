% design_study.m -- design decisions for the ESP32 implementation
%
% Script-based simulation of the first-order adaptive loop (no Simulink
% needed) under realistic ESP32 conditions: u saturated to [-255, 255],
% saturated u fed back as u_prev (anti-windup, as in firmware_model/PI_C.m).
% A flywheel swap (J x24, as in the S->L demo) happens mid-run.
%
% Experiments:
%   A: alpha = 1.00, gain freeze 50 samples          (reference design)
%   B: alpha = 0.98, gain freeze 50 samples          (proposed forgetting)
%   C: as B + adaptive reference prefilter F(z)      (overshoot fix)
%   D: alpha = 0.98, NO gain freeze                  (startup comparison)
%
% Usage:
%   cd matlab
%   matlab -batch "design_study"

scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
outDir = getenv('ACE_OUT_DIR');
if isempty(outDir), outDir = fullfile(repoRoot, 'img'); end
if ~exist(outDir, 'dir'), mkdir(outDir); end
rng(23341);

% Normalized plant model.
p.T = 0.08; p.Km = 1; p.b = 1; p.J1 = 1; p.J2 = 24;
p.q0 = 0.06; p.q1 = -0.5;
p.Tend = 64; p.refAmp = 50; p.refPeriod = 16; p.tSwap = 32;
p.noiseStd = sqrt(1e-3 / p.T);
p.uMax = 255;
N = round(p.Tend / p.T);
p.noise = p.noiseStd * randn(N + 1, 1);   % same noise for all runs

A = runLoop(p, 1.00, 50, false);
B = runLoop(p, 0.98, 50, false);
C = runLoop(p, 0.98, 50, true);
D = runLoop(p, 0.98,  0, false);

b0True1 = p.Km/p.b * (1 - exp(-p.b*p.T/p.J1));
b0True2 = p.Km/p.b * (1 - exp(-p.b*p.T/p.J2));

%% ---------- Figure 1: forgetting factor vs flywheel swap ----------
fig = figure('Visible','off','Position',[0 0 1100 950]);
tl = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact');
title(tl, {'Flywheel swap J \times 24 at t = 32 s  (u saturated to \pm255)', ...
           '\alpha = 1.00 vs. \alpha = 0.98,  gain freeze 50 samples'});

nexttile; hold on; grid on;
stairs(A.t, A.r, 'k--', 'LineWidth', 1);
plot(A.t, A.y, 'LineWidth', 1.1);
xline(p.tSwap, ':r', 'swap', 'LineWidth', 1.2);
ylabel('y'); legend('reference', '\alpha = 1.00', 'Location', 'best');
title('\alpha = 1.00 (reference design): estimator asleep after convergence');

nexttile; hold on; grid on;
stairs(B.t, B.r, 'k--', 'LineWidth', 1);
plot(B.t, B.y, 'LineWidth', 1.1);
xline(p.tSwap, ':r', 'swap', 'LineWidth', 1.2);
ylabel('y'); legend('reference', '\alpha = 0.98', 'Location', 'best');
title('\alpha = 0.98: re-adapts after the swap');

nexttile; hold on; grid on;
plot(A.t, A.b0e, 'LineWidth', 1.1);
plot(B.t, B.b0e, 'LineWidth', 1.1);
stairs([0 p.tSwap p.Tend], [b0True1 b0True2 b0True2], '--k', 'LineWidth', 1);
xline(p.tSwap, ':r', 'LineWidth', 1.2);
ylim([-0.01 0.12]);
xlabel('t [s]'); ylabel('b_0 estimate');
legend('\alpha = 1.00', '\alpha = 0.98', 'true b_0', 'Location', 'best');
title('RLS b_0 estimate: only \alpha < 1 tracks the parameter change');

exportgraphics(fig, fullfile(outDir, 'design_study_forgetting.png'), 'Resolution', 150);
close(fig);

%% ---------- Figure 2: startup freeze + prefilter ----------
fig = figure('Visible','off','Position',[0 0 1100 950]);
tl = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact');
title(tl, 'Start-up gain freeze and adaptive reference prefilter');

iS = A.t <= 8;
nexttile; hold on; grid on;
stairs(B.t(iS), B.r(iS), 'k--', 'LineWidth', 1);
plot(D.t(iS), D.y(iS), 'LineWidth', 1.1);
plot(B.t(iS), B.y(iS), 'LineWidth', 1.1);
ylabel('y'); legend('reference', 'no freeze', 'freeze 50 samples', 'Location', 'best');
title('Start-up (first 8 s)');

nexttile; hold on; grid on;
stairs(D.t(iS), D.u(iS), 'LineWidth', 1.1);
stairs(B.t(iS), B.u(iS), 'LineWidth', 1.1);
yline(p.uMax, '--k'); yline(-p.uMax, '--k');
ylabel('u'); legend('no freeze', 'freeze 50 samples', 'Location', 'best');
title('Control signal at start-up');

iZ = A.t >= 15.5 & A.t <= 21;
nexttile; hold on; grid on;
stairs(B.t(iZ), B.r(iZ), 'k--', 'LineWidth', 1);
plot(B.t(iZ), B.y(iZ), 'LineWidth', 1.1);
plot(C.t(iZ), C.y(iZ), 'LineWidth', 1.1);
xlabel('t [s]'); ylabel('y');
legend('reference', 'without prefilter', 'with prefilter F(z)', 'Location', 'best');
title('Converged step response: prefilter removes the overshoot');

exportgraphics(fig, fullfile(outDir, 'design_study_startup_prefilter.png'), 'Resolution', 150);
close(fig);

%% ---------- Figure 3: reverse swap L -> S (the safety-critical case) ----------
% Adapted to the large flywheel (b0 small -> aggressive gains d1 ~ 450),
% then swap to the small one: loop gain suddenly x23 too high.
pR = p; pR.J1 = p.J2; pR.J2 = p.J1;
E1 = runLoop(pR, 1.00, 50, false);
E2 = runLoop(pR, 0.98, 50, false);

fig = figure('Visible','off','Position',[0 0 1100 950]);
tl = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact');
title(tl, {'Reverse swap L \rightarrow S at t = 32 s (loop gain suddenly \times23)', ...
           'the safety-critical direction'});

nexttile; hold on; grid on;
stairs(E1.t, E1.r, 'k--', 'LineWidth', 1);
plot(E1.t, E1.y, 'LineWidth', 1.1);
xline(pR.tSwap, ':r', 'swap', 'LineWidth', 1.2);
ylabel('y'); legend('reference', '\alpha = 1.00', 'Location', 'best');
title('\alpha = 1.00');

nexttile; hold on; grid on;
stairs(E2.t, E2.r, 'k--', 'LineWidth', 1);
plot(E2.t, E2.y, 'LineWidth', 1.1);
xline(pR.tSwap, ':r', 'swap', 'LineWidth', 1.2);
ylabel('y'); legend('reference', '\alpha = 0.98', 'Location', 'best');
title('\alpha = 0.98');

iP = E1.t >= 31 & E1.t <= 40;
nexttile; hold on; grid on;
stairs(E1.t(iP), E1.u(iP), 'LineWidth', 1.0);
stairs(E2.t(iP), E2.u(iP), 'LineWidth', 1.0);
yline(p.uMax, '--k'); yline(-p.uMax, '--k');
xlabel('t [s]'); ylabel('u');
legend('\alpha = 1.00', '\alpha = 0.98', 'Location', 'best');
title('Control signal around the swap (chattering = mechanical stress)');

exportgraphics(fig, fullfile(outDir, 'design_study_reverse_swap.png'), 'Resolution', 150);
close(fig);

%% ---------- metrics ----------
fprintf('--- pre-swap converged steps (16..32 s), 2%% band ---\n');
stepMetrics('B (no prefilter)', B, 16, 32, p);
stepMetrics('C (prefilter)   ', C, 16, 32, p);
fprintf('--- post-swap steps (32..64 s) ---\n');
stepMetrics('A (alpha=1.00)  ', A, 32, 64, p);
stepMetrics('B (alpha=0.98)  ', B, 32, 64, p);
fprintf('--- b0 re-convergence after swap (|err| < 10%% of true) ---\n');
reconv('A (alpha=1.00)', A, p, b0True2);
reconv('B (alpha=0.98)', B, p, b0True2);
fprintf('--- reverse swap L->S: post-swap (32..64 s) ---\n');
stepMetrics('E1 (alpha=1.00) ', E1, 32, 64, p);
stepMetrics('E2 (alpha=0.98) ', E2, 32, 64, p);
iPost = E1.t >= 32;
fprintf('E1 (alpha=1.00): max|y| post-swap = %7.1f, u sign changes/s = %.1f\n', ...
    max(abs(E1.y(iPost))), nnz(diff(sign(E1.u(iPost))))/(64-32));
fprintf('E2 (alpha=0.98): max|y| post-swap = %7.1f, u sign changes/s = %.1f\n', ...
    max(abs(E2.y(iPost))), nnz(diff(sign(E2.u(iPost))))/(64-32));
fprintf('--- start-up (0..8 s) ---\n');
fprintf('D (no freeze): max|y| = %7.1f, max|u| = %5.0f\n', ...
    max(abs(D.y(iS))), max(abs(D.u(iS))));
fprintf('B (freeze 50): max|y| = %7.1f, max|u| = %5.0f\n', ...
    max(abs(B.y(iS))), max(abs(B.u(iS))));
disp('EXPORT_OK');

%% ---------- local functions ----------
function out = runLoop(p, alpha, freezeN, usePF)
    N = round(p.Tend / p.T);
    t = (0:N-1)' * p.T;
    % true plant parameters over time (exact ZOH, J changes at the swap)
    J = p.J1 * ones(N,1); J(t >= p.tSwap) = p.J2;
    a0t = -exp(-p.b*p.T ./ J);
    b0t = p.Km/p.b * (1 - exp(-p.b*p.T ./ J));

    r = p.refAmp * (mod(t, p.refPeriod) < p.refPeriod/2);

    xe = [-0.5; 1.0]; P = 100*eye(2);
    d0f = (p.q0 + xe(1)) / xe(2);          % frozen start-up gains from the
    d1f = (p.q1 + 1 - xe(1)) / xe(2);      % initial parameter guess
    d0 = d0f; d1 = d1f;

    x = 0; yPrev = 0; uPrev = 0; ePrev = 0; rPrev = 0; rfPrev = 0;
    y = zeros(N,1); u = zeros(N,1); a0e = zeros(N,1); b0e = zeros(N,1);

    for k = 1:N
        yk = x + p.noise(k);

        % RLS (identical to firmware_model/rls_estimator.m, plus alpha)
        C = [-yPrev, uPrev];
        L = (P*C') / (C*P*C' + alpha);
        xe = xe + L * (yk - C*xe);
        P = (eye(2) - L*C) * P / alpha;

        % pole placement with b0 guard (hold gains near singularity)
        if k > freezeN && abs(xe(2)) > 1e-3
            d0 = (p.q0 + xe(1)) / xe(2);
            d1 = (p.q1 + 1 - xe(1)) / xe(2);
        elseif k <= freezeN
            d0 = d0f; d1 = d1f;
        end

        % adaptive reference prefilter F(z) = (1-z0)/(z-z0), z0 = -d0/d1
        if usePF
            z0 = min(max(-d0/d1, 0), 0.95);
            rf = z0*rfPrev + (1 - z0)*rPrev;
        else
            rf = r(k);
        end

        % incremental PI with saturation, saturated u fed back
        e = rf - yk;
        uk = uPrev + d1*e + d0*ePrev;
        uk = min(max(uk, -p.uMax), p.uMax);

        y(k) = yk; u(k) = uk; a0e(k) = xe(1); b0e(k) = xe(2);

        x = -a0t(k)*x + b0t(k)*uk;          % true plant step
        yPrev = yk; uPrev = uk; ePrev = e; rPrev = r(k); rfPrev = rf;
    end
    out = struct('t',t,'r',r,'y',y,'u',u,'a0e',a0e,'b0e',b0e);
end

function stepMetrics(name, run, t0win, t1win, p)
    edges = find(abs(diff(run.r)) > 1e-6) + 1;
    for k = 1:numel(edges)
        i0 = edges(k);
        t0 = run.t(i0);
        if t0 < t0win || t0 >= t1win, continue; end
        if k < numel(edges), t1 = run.t(edges(k+1)); else, t1 = run.t(end) + 1; end
        target = run.r(i0); y0 = run.r(i0-1); h = target - y0;
        win = run.t >= t0 & run.t < t1;
        yw = run.y(win); tw = run.t(win);
        ovs = max(0, max((yw - target)*sign(h)) / abs(h) * 100);
        tol = 0.02 * abs(h);
        li = find(abs(yw - target) > tol, 1, 'last');
        if isempty(li),        ts = 'immediate';
        elseif li == numel(yw), ts = 'NOT settled';
        else,                   ts = sprintf('%.2f s', tw(li+1) - t0);
        end
        fprintf('%s step @ t=%5.1f s: overshoot = %6.2f %%, settling = %s\n', ...
            name, t0, ovs, ts);
    end
end

function reconv(name, run, p, b0True2)
    idx = find(run.t >= p.tSwap & abs(run.b0e - b0True2) < 0.1*b0True2, 1);
    if isempty(idx)
        fprintf('%s: b0 never within 10%% of new true value\n', name);
    else
        fprintf('%s: b0 within 10%% after %.1f s\n', name, run.t(idx) - p.tSwap);
    end
end
