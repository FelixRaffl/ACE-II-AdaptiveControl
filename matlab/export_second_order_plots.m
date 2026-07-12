%% Export plots for the second-order adaptive DC-motor simulation.
%
% Produces:
%   simulation_2nd_order.png
%
% Usage:
%   cd matlab
%   matlab -batch "export_second_order_plots"

scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
aceOutDir = getenv('ACE_OUT_DIR');
if isempty(aceOutDir)
    modelDir = fullfile(repoRoot, 'simulink');
    imageDir = fullfile(repoRoot, 'img');
else
    modelDir = aceOutDir;
    imageDir = aceOutDir;
end
if ~exist(imageDir, 'dir'), mkdir(imageDir); end

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
close_system(mdl, 0);

thetaTrue = [p.a1; p.a0; p.b1; p.b0];
thetaEst = [a1 a0 b1 b0];
thetaScale = max(abs(thetaTrue.'), eps);
relErr = max(abs(bsxfun(@rdivide, bsxfun(@minus, thetaEst, thetaTrue.'), ...
    thetaScale)), [], 2);
relErrPlot = relErr;
relErrPlot(relErrPlot < 1e-8) = 1e-8;

fig = figure('Visible', 'off', 'Position', [0 0 1300 1150]);
tl = tiledlayout(fig, 4, 1, 'TileSpacing', 'compact');
title(tl, {'Second-order adaptive DC-motor simulation', ...
    '4-parameter RLS + RST pole placement, T = 2 ms'});

nexttile; hold on; grid on;
stairs(t, ref, 'k--', 'LineWidth', 1.0);
plot(t, y, 'k-', 'LineWidth', 1.1);
ylabel('speed [rad/s]');
legend('reference', 'output', 'Location', 'best');
title('Reference tracking');

nexttile; hold on; grid on;
stairs(t, u, 'k-', 'LineWidth', 1.0);
yline(p.uMax, 'k--', '+u_{max}');
yline(-p.uMax, 'k--', '-u_{max}');
ylabel('u [V]');
title('Saturated control signal');

nexttile; hold on; grid on;
plot(t, a1, 'k-', 'LineWidth', 1.0);
plot(t, a0, '-', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.0);
plot(t, b1, '-', 'Color', [0.50 0.50 0.50], 'LineWidth', 1.0);
plot(t, b0, '-', 'Color', [0.70 0.70 0.70], 'LineWidth', 1.0);
yline(thetaTrue(1), '-.', 'Color', [0.00 0.00 0.00], 'LineWidth', 0.9);
yline(thetaTrue(2), '-.', 'Color', [0.25 0.25 0.25], 'LineWidth', 0.9);
yline(thetaTrue(3), '-.', 'Color', [0.50 0.50 0.50], 'LineWidth', 0.9);
yline(thetaTrue(4), '-.', 'Color', [0.70 0.70 0.70], 'LineWidth', 0.9);
xlim([0 1]);
xlabel('time [s]');
ylabel('estimate');
legend('a_1 estimate', 'a_0 estimate', 'b_1 estimate', 'b_0 estimate', ...
    'a_1 true', 'a_0 true', 'b_1 true', 'b_0 true', 'Location', 'eastoutside');
title('Parameter estimates and true values');

errAx = nexttile; hold(errAx, 'on'); grid(errAx, 'on');
semilogy(errAx, t, relErrPlot, 'k-', 'LineWidth', 1.1);
set(errAx, 'YScale', 'log');
ylim(errAx, [1e-8, max(1e-7, max(relErrPlot))]);
xlabel(errAx, 'time [s]');
ylabel(errAx, 'max relative error');
title(errAx, 'Normalized parameter estimation error');

exportgraphics(fig, fullfile(imageDir, 'simulation_2nd_order.png'), 'Resolution', 150);
close(fig);

disp('PLOTS_OK');

%% ---------- local functions ----------
function [t, x] = getSignal(ds, name)
    element = ds.getElement(name);
    t = element.Values.Time(:);
    x = squeeze(element.Values.Data);
    x = x(:);
end
