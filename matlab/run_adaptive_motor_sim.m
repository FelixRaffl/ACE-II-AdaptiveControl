%% Run and validate adaptive_motor_sim.slx
scriptDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(scriptDir);
run(fullfile(scriptDir, 'adaptive_motor_params.m'));

mdl = 'adaptive_motor_sim';
mdlFile = fullfile(scriptDir, [mdl '.slx']);
if ~isfile(mdlFile)
    run(fullfile(scriptDir, 'build_adaptive_motor_sim.m'));
end

load_system(mdlFile);
set_param(mdl, 'SimulationMode', 'normal');
out = sim(mdl);
ds = out.logsout;

[t, ref] = getSignal(ds, 'ref');
[~, yTrue] = getSignal(ds, 'y_true');
[~, y] = getSignal(ds, 'y');
[~, u] = getSignal(ds, 'u');
[~, a0] = getSignal(ds, 'a0_est');
[~, b0] = getSignal(ds, 'b0_est');
[~, J] = getSignal(ds, 'J');

a0True = -exp(-b*T ./ J);
b0True = (Km/b) .* (1 - exp(-b*T ./ J));

pre = t >= swapTime - 4 & t < swapTime;
% Exclude the final sample because the periodic reference changes exactly
% at t = simTime and would otherwise dominate the settled-window RMSE.
post = t >= simTime - 4 & t < simTime - T/2;
preErr = [mean(abs(a0(pre) - a0True(pre))), ...
          mean(abs(b0(pre) - b0True(pre)))];
postErr = [mean(abs(a0(post) - a0True(post))), ...
           mean(abs(b0(post) - b0True(post)))];
trackingRmsePost = sqrt(mean((yTrue(post) - ref(post)).^2));

assert(all(isfinite([y; u; a0; b0])), 'Simulation contains NaN or Inf.');
assert(max(abs(u)) <= uMax + 1e-9, 'Actuator saturation was violated.');
assert(postErr(1) < preErr(1) + 0.1, 'a0 estimate did not remain plausible.');
assert(postErr(2) < 0.02, 'b0 estimate did not re-converge after flywheel swap.');

fprintf('\n--- adaptive_motor_sim acceptance report ---\n');
fprintf('Fixed step:                 %.3f s\n', T);
fprintf('Actuator range observed:    [%7.2f, %7.2f]\n', min(u), max(u));
fprintf('Before swap mean |a0 err|:  %.5f\n', preErr(1));
fprintf('Before swap mean |b0 err|:  %.5f\n', preErr(2));
fprintf('After swap mean |a0 err|:   %.5f\n', postErr(1));
fprintf('After swap mean |b0 err|:   %.5f\n', postErr(2));
fprintf('Final-window tracking RMSE: %.3f\n', trackingRmsePost);
fprintf('VALIDATION_OK\n');

fig = figure('Visible', 'off', 'Position', [0 0 1200 1000]);
tl = tiledlayout(fig, 4, 1, 'TileSpacing', 'compact');
title(tl, {'Clean adaptive DC-motor simulation', ...
    sprintf('RLS + pole placement + incremental PI, T = %.2f s', T)});

nexttile; hold on; grid on;
stairs(t, ref, 'k--', 'LineWidth', 1.1);
plot(t, yTrue, 'LineWidth', 1.2);
xline(swapTime, ':r', 'J: 1 -> 24');
ylabel('\omega');
legend('reference', 'motor speed', 'Location', 'best');
title('Reference tracking');

nexttile; hold on; grid on;
stairs(t, u, 'LineWidth', 1.0);
yline(uMax, '--k'); yline(uMin, '--k');
xline(swapTime, ':r');
ylabel('u');
title('Saturated actuator command');

nexttile; hold on; grid on;
plot(t, a0, 'LineWidth', 1.1);
plot(t, a0True, '--k', 'LineWidth', 1.0);
xline(swapTime, ':r');
ylabel('a_0');
legend('estimate', 'true', 'Location', 'best');
title('RLS denominator parameter');

nexttile; hold on; grid on;
plot(t, b0, 'LineWidth', 1.1);
plot(t, b0True, '--k', 'LineWidth', 1.0);
xline(swapTime, ':r');
xlabel('t [s]'); ylabel('b_0');
legend('estimate', 'true', 'Location', 'best');
title('RLS input-gain parameter');

plotFile = fullfile(projectDir, 'img', 'adaptive_motor_clean_sim.png');
exportgraphics(fig, plotFile, 'Resolution', 150);
close(fig);

try
    print(['-s' mdl], '-dpng', '-r150', ...
        fullfile(projectDir, 'img', 'adaptive_motor_sim_model.png'));
catch diagramError
    fprintf('WARN: model diagram export failed: %s\n', diagramError.message);
end

close_system(mdl, 0);

function [t, x] = getSignal(ds, name)
    element = ds.getElement(name);
    t = element.Values.Time;
    x = squeeze(element.Values.Data);
end
