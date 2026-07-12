% Extract the shared time vector
t = step.time;

% Extract the two signals from the columns of the matrix
% (:, 1) means "all rows, first column"
y_ref  = step.signals.values(:, 1); 
y_meas = step.signals.values(:, 2); 

% Create a new figure with a white background
figure('Color', 'w');

% Plot the reference signal (dashed line is standard for references)
plot(t, y_ref, '-', 'LineWidth', 1.5); % Gray dashed
hold on; 

% Plot the actual measured tracking response
plot(t, y_meas, '-', 'LineWidth', 1.5); % Blue solid
hold off;

% Add formatting, grid, and labels
grid on;
xlabel('time/s');
ylabel('Amplitude/(rad/s)');

% Add a legend so it's clear which line is which
legend('Reference Step', 'Actual Response');