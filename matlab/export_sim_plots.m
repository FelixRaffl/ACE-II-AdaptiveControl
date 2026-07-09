% export_sim_plots.m -- headless export of adaptive-control simulation results
%
% Runs the two reference Simulink models (First / Second Order) in normal
% mode, enables signal logging programmatically (the models ship without
% any logging configured), exports result plots as PNG and prints
% step-response metrics to the log. The models are never saved.
%
% Usage (staged copy of the .slx files next to this script):
%   matlab.exe -wait -nosplash -sd <stage-dir> -batch "export_sim_plots"
%
% Requires R2025b (both models were saved with release 25.2).

outDir = getenv('ACE_OUT_DIR');
if isempty(outDir), outDir = pwd; end
errs = {};

%% ---------- Model 1: first order (2-parameter RLS + pole placement + PI) ----------
try
    % Init values from "First Order Model/ACE_II_AC_DCMotor.mlx"
    Km = 1; J = 1; b = 1; T = 0.08; q0 = 0.06; q1 = -0.5;
    mdl = 'ACE_II_AC_1oDCMotor';
    load_system(mdl);
    set_param(mdl, 'SimulationMode', 'normal');
    logPort(mdl, sprintf('Pulse\nGenerator'),  1, 'ref');
    logPort(mdl, sprintf('Zero-Order\nHold1'), 1, 'y');
    logPort(mdl, 'MATLAB Function2',           1, 'u');
    logPort(mdl, 'Subsystem/MATLAB Function',  1, 'a0_est');
    logPort(mdl, 'Subsystem/MATLAB Function',  2, 'b0_est');
    out = sim(mdl);
    ds = out.logsout;
    [tRef, refv] = getSig(ds, 'ref');
    [tY,   yv]   = getSig(ds, 'y');
    [tU,   uv]   = getSig(ds, 'u');
    [tA,   a0v]  = getSig(ds, 'a0_est');
    [~,    b0v]  = getSig(ds, 'b0_est');

    % Exact ZOH discretization of Km/(J*s + b) at T
    a0True = -exp(-b*T/J);
    b0True = Km/b * (1 - exp(-b*T/J));

    fig = figure('Visible','off','Position',[0 0 1100 950]);
    tl = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact');
    title(tl, {'First-order model: RLS + pole placement + PI', ...
               'q(z) = z^2 - 0.5z + 0.06,  T = 0.08 s'});

    nexttile; hold on; grid on;
    stairs(tRef, refv, 'k--', 'LineWidth', 1);
    plot(tY, yv, 'LineWidth', 1.2);
    ylabel('speed y'); legend('reference', 'output', 'Location', 'best');
    title('Reference tracking');

    nexttile; hold on; grid on;
    stairs(tU, uv, 'LineWidth', 1);
    ylabel('u'); title('Control signal');

    nexttile; hold on; grid on;
    plot(tA, a0v, 'LineWidth', 1.2);
    plot(tA, b0v, 'LineWidth', 1.2);
    yline(a0True, '--k', sprintf('a_0 true = %.4f', a0True));
    yline(b0True, '--k', sprintf('b_0 true = %.4f', b0True));
    xlabel('t [s]'); ylabel('estimate');
    legend('a_0 estimate', 'b_0 estimate', 'Location', 'best');
    title('RLS parameter convergence');

    exportgraphics(fig, fullfile(outDir, 'simulation_1st.png'), 'Resolution', 150);
    close(fig);
    try
        print(['-s' mdl], '-dpng', '-r150', fullfile(outDir, 'model_1st.png'));
    catch e2
        fprintf('WARN: model diagram export failed: %s\n', e2.message);
    end

    fprintf('--- 1st-order metrics ---\n');
    reportSteps(tRef, refv, tY, yv, 0.02);
    fprintf('RLS final: a0 = %.4f (true %.4f, |err| %.2e), b0 = %.4f (true %.4f, |err| %.2e)\n', ...
        a0v(end), a0True, abs(a0v(end)-a0True), ...
        b0v(end), b0True, abs(b0v(end)-b0True));
    close_system(mdl, 0);
catch e
    errs{end+1} = sprintf('1st order: %s', e.message);
    fprintf(2, 'ERROR in 1st-order model:\n%s\n', getReport(e));
end

%% ---------- Model 2: second order (4-parameter RLS + RST pole placement) ----------
try
    % Init values from "Second Order Model/ACE_II_AC_DCMotor.mlx"
    Km = 0.05; J = 0.001; b = 0.0005; La = 0.002; Ra = 2.0;
    T = 0.08; q0 = 0.06; q1 = -0.5;
    mdl = 'ACE_II_AC_DCMotor';
    load_system(mdl);
    set_param(mdl, 'SimulationMode', 'normal');
    logPort(mdl, sprintf('Pulse\nGenerator'),  1, 'ref');
    logPort(mdl, sprintf('Zero-Order\nHold1'), 1, 'y');
    logPort(mdl, 'MATLAB Function2',           1, 'u');
    logPort(mdl, 'Subsystem/MATLAB Function',  1, 'a1_est');
    logPort(mdl, 'Subsystem/MATLAB Function',  2, 'a0_est');
    logPort(mdl, 'Subsystem/MATLAB Function',  3, 'b1_est');
    logPort(mdl, 'Subsystem/MATLAB Function',  4, 'b0_est');
    out = sim(mdl);
    ds = out.logsout;
    [tRef, refv] = getSig(ds, 'ref');
    [tY,   yv]   = getSig(ds, 'y');
    [tU,   uv]   = getSig(ds, 'u');
    [tA,   a1v]  = getSig(ds, 'a1_est');
    [~,    a0v]  = getSig(ds, 'a0_est');
    [~,    b1v]  = getSig(ds, 'b1_est');
    [~,    b0v]  = getSig(ds, 'b0_est');

    % ZOH discretization of the true 2nd-order plant (needs Control System Tbx)
    haveTruth = false;
    try
        Gd = c2d(tf(Km, [La*J, La*b + Ra*J, Ra*b + Km^2]), T, 'zoh');
        [numd, dend] = tfdata(Gd, 'v');
        a1True = dend(2); a0True = dend(3);
        b1True = numd(2); b0True = numd(3);
        haveTruth = true;
    catch
        fprintf('WARN: c2d unavailable, skipping truth lines for 2nd order\n');
    end

    fig = figure('Visible','off','Position',[0 0 1100 950]);
    tl = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact');
    title(tl, {'Second-order model: 4-parameter RLS + RST pole placement', ...
               'T = 0.08 s'});

    nexttile; hold on; grid on;
    stairs(tRef, refv, 'k--', 'LineWidth', 1);
    plot(tY, yv, 'LineWidth', 1.2);
    ylabel('speed y'); legend('reference', 'output', 'Location', 'best');
    title('Reference tracking');

    nexttile; hold on; grid on;
    stairs(tU, uv, 'LineWidth', 1);
    ylabel('u'); title('Control signal');

    nexttile; hold on; grid on;
    plot(tA, a1v, 'LineWidth', 1.2);
    plot(tA, a0v, 'LineWidth', 1.2);
    plot(tA, b1v, 'LineWidth', 1.2);
    plot(tA, b0v, 'LineWidth', 1.2);
    if haveTruth
        yline(a1True, '--k'); yline(a0True, '--k');
        yline(b1True, '--k'); yline(b0True, '--k');
    end
    xlabel('t [s]'); ylabel('estimate');
    legend('a_1', 'a_0', 'b_1', 'b_0', 'Location', 'best');
    title('RLS parameter convergence');

    exportgraphics(fig, fullfile(outDir, 'simulation_2nd.png'), 'Resolution', 150);
    close(fig);
    try
        print(['-s' mdl], '-dpng', '-r150', fullfile(outDir, 'model_2nd.png'));
    catch e2
        fprintf('WARN: model diagram export failed: %s\n', e2.message);
    end

    fprintf('--- 2nd-order metrics ---\n');
    reportSteps(tRef, refv, tY, yv, 0.05);
    if haveTruth
        fprintf('RLS final: a1 = %.4f (true %.4f), a0 = %.4f (true %.4f), b1 = %.4f (true %.4f), b0 = %.4f (true %.4f)\n', ...
            a1v(end), a1True, a0v(end), a0True, b1v(end), b1True, b0v(end), b0True);
    else
        fprintf('RLS final: a1 = %.4f, a0 = %.4f, b1 = %.4f, b0 = %.4f\n', ...
            a1v(end), a0v(end), b1v(end), b0v(end));
    end
    close_system(mdl, 0);
catch e
    errs{end+1} = sprintf('2nd order: %s', e.message);
    fprintf(2, 'ERROR in 2nd-order model:\n%s\n', getReport(e));
end

%% ---------- result ----------
if isempty(errs)
    disp('EXPORT_OK');
else
    error('export_sim_plots:failed', 'Export failed:\n%s', strjoin(errs, '\n'));
end

%% ---------- local functions ----------
function logPort(mdl, blk, port, name)
    try
        ph = get_param([mdl '/' blk], 'PortHandles');
    catch e
        fprintf(2, 'Block "%s" not found. Blocks in %s:\n', blk, mdl);
        disp(getfullname(Simulink.findBlocks(mdl)));
        rethrow(e);
    end
    set_param(ph.Outport(port), 'DataLogging', 'on', ...
        'DataLoggingNameMode', 'Custom', 'DataLoggingName', name);
end

function [t, x] = getSig(ds, name)
    el = ds.getElement(name);
    t = el.Values.Time;
    x = squeeze(el.Values.Data);
end

% Per-step overshoot and settling time of y against the reference steps.
% band: settling band as a fraction of the step height (e.g. 0.02 = 2 %).
function reportSteps(tR, refv, tY, yv, band)
    edges = find(abs(diff(refv)) > 1e-6) + 1;
    if refv(1) ~= 0
        edges = [1; edges(:)];
    end
    edges = edges(:);
    for k = 1:numel(edges)
        i0 = edges(k);
        t0 = tR(i0);
        if k < numel(edges), t1 = tR(edges(k+1)); else, t1 = tY(end) + 1; end
        target = refv(i0);
        if i0 > 1, y0 = refv(i0-1); else, y0 = 0; end
        h = target - y0;
        if h == 0, continue; end
        win = tY >= t0 & tY < t1;
        tw = tY(win); yw = yv(win);
        if isempty(tw), continue; end
        ovs = max(0, max((yw - target) * sign(h)) / abs(h) * 100);
        tol = band * abs(h);
        li = find(abs(yw - target) > tol, 1, 'last');
        if isempty(li)
            ts = 'settled immediately';
        elseif li == numel(yw)
            ts = 'NOT settled in window';
        else
            ts = sprintf('%.3f s', tw(li+1) - t0);
        end
        fprintf('step @ t=%6.2f s (%g -> %g): overshoot = %6.2f %%, settling(%g%%) = %s\n', ...
            t0, y0, target, ovs, band*100, ts);
    end
end
