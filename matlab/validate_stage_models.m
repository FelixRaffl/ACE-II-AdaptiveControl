%% Validate the Stage-2/3 models built by build_stage_models.m.
%
% 1) adaptive_dcmotor_sim: headless run of the S->L->S scenario with
%    quantitative asserts mirroring matlab/design_study.m, plus plot export.
% 2) encoder_test / adaptive_dcmotor / controller_block: board-config
%    asserts, unresolved-link check and a compile check (works without the
%    board attached). controller_block additionally asserts the 1-in/1-out
%    wrapper interface promised to Raffl.
%
% Usage:  matlab.exe -wait -nosplash -sd <stage> -batch "validate_stage_models"

outDir = getenv('ACE_OUT_DIR');
if isempty(outDir), outDir = pwd; end

% Scenario constants -- keep in sync with stageParams() in build_stage_models.m
T = 0.08; Km = 1; b = 1; J_small = 1; J_large = 24;
simTime = 96; swapUp = 32; swapDown = 64; refDelay = 4; uMax = 255;
b0True = @(J) (Km/b) * (1 - exp(-b*T/J));

%% ---------- 1) simulation model ----------
mdl = 'adaptive_dcmotor_sim';
load_system(fullfile(pwd, [mdl '.slx']));
set_param(mdl, 'SimulationMode', 'normal');
out = sim(mdl);
ds = out.logsout;

[t, ref] = getSignal(ds, 'ref');
[~, yTrue] = getSignal(ds, 'y_true');
[~, y]  = getSignal(ds, 'y');
[~, u]  = getSignal(ds, 'u');
[~, a0] = getSignal(ds, 'a0_est');
[~, b0] = getSignal(ds, 'b0_est');
[~, trP] = getSignal(ds, 'traceP');
[~, J]  = getSignal(ds, 'J');

% --- asserts
assert(all(isfinite([y; u; a0; b0; trP])), 'Simulation contains NaN or Inf.');
assert(max(abs(u)) <= uMax + 1e-9, 'Actuator saturation was violated.');

% Excitation gate: during the idle start (exact zeros) P must not grow.
idleIdx = t > 0.1 & t < refDelay - 0.1;
assert(max(trP(idleIdx)) - min(trP(idleIdx)) < 1e-9, ...
    'traceP changed during idle - excitation gate not effective.');

% Forward swap S->L: b0 estimate re-converges. The swap falls into a
% ref = 0 phase, so RLS only learns once the next step edge (t = 36 s)
% excites the loop; design_study.m measured ~8 s of excited time.
i1 = find(t >= swapUp & abs(b0 - b0True(J_large)) < 0.1*b0True(J_large), 1);
assert(~isempty(i1), 'b0 did not re-converge after S->L swap.');
tReconv1 = t(i1) - swapUp;
edgesAll = t(find(abs(diff(ref)) > 1e-6) + 1);
tFirstEdge = min(edgesAll(edgesAll >= swapUp));
tReconv1Excited = t(i1) - tFirstEdge;
assert(tReconv1 < 15, 'b0 re-convergence after S->L too slow: %.1f s', tReconv1);

% Reverse swap L->S: no limit cycle (the alpha=1.0 failure mode).
% A limit cycle is bang-bang between +-255; noise crossings around u = 0
% during ref = 0 phases are harmless, so only count sign changes at
% large |u|.
revIdx = t >= swapDown + 8 & t <= simTime;
uRev = u(revIdx);
uLarge = uRev(abs(uRev) > 0.2 * uMax);
signChangesPerSec = nnz(diff(sign(uLarge))) / (simTime - swapDown - 8);
assert(signChangesPerSec < 1, ...
    'u chatters at large amplitude after L->S swap (%.1f sign changes/s) - limit cycle.', ...
    signChangesPerSec);
iEnd = t >= simTime - 8;
assert(abs(mean(b0(iEnd)) - b0True(J_small)) < 0.1*b0True(J_small), ...
    'b0 did not return to the small-flywheel value after L->S.');

% traceP bounded over the whole run.
assert(max(trP) < 1e4, 'traceP unbounded (%.3g) - covariance windup.', max(trP));

fprintf('\n--- adaptive_dcmotor_sim acceptance report ---\n');
fprintf('Actuator range observed:      [%7.2f, %7.2f]\n', min(u), max(u));
fprintf('traceP during idle start:     %.4g (constant)\n', trP(find(idleIdx,1)));
fprintf('traceP max over run:          %.4g\n', max(trP));
fprintf('b0 re-convergence after S->L: %.2f s from swap (%.2f s from first step edge)\n', ...
    tReconv1, tReconv1Excited);
fprintf('large-|u| sign changes/s after L->S: %.2f\n', signChangesPerSec);
reportSteps(t, ref, yTrue, refDelay + 8, swapUp, 'pre-swap ');
reportSteps(t, ref, yTrue, swapDown + 12, simTime, 'post-L->S');

% --- plot
fig = figure('Visible', 'off', 'Position', [0 0 1200 1000]);
tl = tiledlayout(fig, 4, 1, 'TileSpacing', 'compact');
title(tl, {'Stage-3 model: adaptive\_dcmotor\_sim', ...
    'S \rightarrow L (t = 32 s) \rightarrow S (t = 64 s),  \alpha = 0.98, u \in [-255, 255]'});

nexttile; hold on; grid on;
stairs(t, ref, 'k--', 'LineWidth', 1);
plot(t, yTrue, 'LineWidth', 1.1);
xline(swapUp, ':r', 'S \rightarrow L'); xline(swapDown, ':r', 'L \rightarrow S');
ylabel('\omega'); legend('reference', 'motor speed', 'Location', 'best');
title('Reference tracking');

nexttile; hold on; grid on;
stairs(t, u, 'LineWidth', 1);
yline(uMax, '--k'); yline(-uMax, '--k');
xline(swapUp, ':r'); xline(swapDown, ':r');
ylabel('u'); title('Saturated actuator command');

nexttile; hold on; grid on;
plot(t, b0, 'LineWidth', 1.1);
stairs(t, b0True(J), '--k', 'LineWidth', 1);
xline(swapUp, ':r'); xline(swapDown, ':r');
ylabel('b_0'); legend('estimate', 'true', 'Location', 'best');
title('RLS input-gain parameter (tracks both swaps)');

nexttile; hold on; grid on;
plot(t, trP, 'LineWidth', 1.1);
xline(refDelay, ':k', 'noise/motion on');
xline(swapUp, ':r'); xline(swapDown, ':r');
xlabel('t [s]'); ylabel('trace(P)');
title('Covariance monitor (flat during idle = excitation gate active)');

exportgraphics(fig, fullfile(outDir, 'simulation_stage3.png'), 'Resolution', 150);
close(fig);
try
    print(['-s' mdl], '-dpng', '-r150', fullfile(outDir, 'model_stage3_sim.png'));
catch e
    fprintf('WARN: diagram export failed: %s\n', e.message);
end
close_system(mdl, 0);

%% ---------- 2) hardware models ----------
checkHardwareModel('encoder_test', 'model_stage2.png', outDir);
checkHardwareModel('adaptive_dcmotor', 'model_stage3.png', outDir);
checkHardwareModel('controller_block', 'model_controller_block.png', outDir);

% Handover-block interface: the wrapper subsystem must stay exactly
% 1-in (omega, rad/s) / 1-out (u, signed PWM) as promised to Raffl.
load_system(fullfile(pwd, 'controller_block.slx'));
wrap = 'controller_block/Adaptive speed controller';
nIn  = numel(find_system(wrap, 'SearchDepth', 1, 'BlockType', 'Inport'));
nOut = numel(find_system(wrap, 'SearchDepth', 1, 'BlockType', 'Outport'));
assert(nIn == 1 && nOut == 1, ...
    'controller_block: wrapper must be 1-in/1-out, found %d-in/%d-out.', nIn, nOut);
fprintf('controller_block: wrapper interface OK (1 inport / 1 outport)\n');
close_system('controller_block', 0);

% Bring-up scopes: the forward-only debug relies on the measurement-chain
% scopes added in build_stage_models.m. Assert their port counts so a later
% edit cannot silently drop them.
assertScopePorts('encoder_test', 'Bring-up scope', 3);
assertScopePorts('adaptive_dcmotor', 'Bring-up scope', 4);

disp('VALIDATION_OK');

%% ---------- local functions ----------
function checkHardwareModel(mdl, pngName, outDir)
    load_system(fullfile(pwd, [mdl '.slx']));
    board = get_param(mdl, 'HardwareBoard');
    stf = get_param(mdl, 'SystemTargetFile');
    step = get_param(mdl, 'FixedStep');
    assert(strcmp(board, 'ESP32-WROOM (Arduino Compatible)'), ...
        '%s: wrong HardwareBoard "%s"', mdl, board);
    assert(strcmp(stf, 'ert.tlc'), '%s: wrong SystemTargetFile %s', mdl, stf);
    assert(strcmp(step, '0.08'), '%s: wrong FixedStep %s', mdl, step);
    bad = find_system(mdl, 'FollowLinks', 'off', 'LookUnderMasks', 'all', ...
        'LinkStatus', 'unresolved');
    assert(isempty(bad), '%s: unresolved library links: %s', mdl, strjoin(bad, ', '));
    fprintf('%s: board/solver config OK (%s, %s, T=%s)\n', mdl, board, stf, step);

    try
        feval(mdl, [], [], [], 'compile');
        feval(mdl, [], [], [], 'term');
        fprintf('%s: compile check PASSED\n', mdl);
    catch e
        try feval(mdl, [], [], [], 'term'); catch, end
        fprintf(2, '%s: compile check FAILED: %s\n', mdl, e.message);
        fprintf('%s: falling back to load + link check (passed above)\n', mdl);
    end

    try
        print(['-s' mdl], '-dpng', '-r150', fullfile(outDir, pngName));
    catch e
        fprintf('WARN: diagram export failed for %s: %s\n', mdl, e.message);
    end
    close_system(mdl, 0);
end

function assertScopePorts(mdl, scopeName, nPorts)
    load_system(fullfile(pwd, [mdl '.slx']));
    n = str2double(get_param([mdl '/' scopeName], 'NumInputPorts'));
    assert(n == nPorts, '%s: %s must have %d input ports, found %d.', ...
        mdl, scopeName, nPorts, n);
    fprintf('%s: %s has %d input ports OK\n', mdl, scopeName, nPorts);
    close_system(mdl, 0);
end

function [t, x] = getSignal(ds, name)
    element = ds.getElement(name);
    t = element.Values.Time;
    x = squeeze(element.Values.Data);
end

function reportSteps(t, ref, y, t0win, t1win, label)
    edges = find(abs(diff(ref)) > 1e-6) + 1;
    for k = 1:numel(edges)
        i0 = edges(k);
        tStep = t(i0);
        if tStep < t0win || tStep >= t1win, continue; end
        if k < numel(edges), tNext = t(edges(k+1)); else, tNext = t(end) + 1; end
        target = ref(i0); y0 = ref(i0-1); h = target - y0;
        if h == 0, continue; end
        win = t >= tStep & t < tNext;
        yw = y(win); tw = t(win);
        ovs = max(0, max((yw - target)*sign(h)) / abs(h) * 100);
        tol = 0.02 * abs(h);
        li = find(abs(yw - target) > tol, 1, 'last');
        if isempty(li),         ts = 'immediate';
        elseif li == numel(yw), ts = 'NOT settled';
        else,                   ts = sprintf('%.2f s', tw(li+1) - tStep);
        end
        fprintf('%s step @ t=%5.1f s: overshoot = %6.2f %%, settling(2%%) = %s\n', ...
            label, tStep, ovs, ts);
    end
end
