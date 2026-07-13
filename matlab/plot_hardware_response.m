%% Plot the logged hardware response of the second-order adaptive DC-motor run.
%
% Plots the logged closed-loop response of
% simulink/adaptive_dcmotor_2nd_hw.slx from an External Mode run and exports
% img/hw_response.pdf.
%
% Usage:
%   Run simulink/adaptive_dcmotor_2nd_hw.slx in External Mode so that the
%   logged variable step is present in the workspace.
%   cd matlab
%   plot_hardware_response

scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
aceOutDir = getenv('ACE_OUT_DIR');
if isempty(aceOutDir)
    imageDir = fullfile(repoRoot, 'img');
else
    imageDir = aceOutDir;
end
if ~exist(imageDir, 'dir'), mkdir(imageDir); end

if ~exist('step', 'var')
    error('plot_hardware_response:MissingStep', ...
        ['The logged variable ''step'' is required in the workspace. ' ...
        'Run simulink/adaptive_dcmotor_2nd_hw.slx in External Mode first.']);
end

% Extract the shared time vector from the logged two-column signal.
t = step.time;
y_ref  = step.signals.values(:, 1);
y_meas = step.signals.values(:, 2);

figure('Color', 'w');
plot(t, y_ref, '-', 'LineWidth', 1.5);
hold on;
plot(t, y_meas, '-', 'LineWidth', 1.5);
hold off;
grid on;
xlabel('time/s');
ylabel('Amplitude/(rad/s)');
legend('Reference Step', 'Actual Response');

exportgraphics(gcf, fullfile(imageDir, 'hw_response.pdf'), ...
    'ContentType', 'vector');
