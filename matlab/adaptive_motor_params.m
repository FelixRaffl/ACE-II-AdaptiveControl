%% Parameters for adaptive_motor_sim.slx
% Normalized first-order motor used to validate the adaptive controller.
% The inertia ratio 1:24 matches the two flywheels; absolute motor
% parameters will be identified online on the real setup.

T = 0.08;                 % controller sample time [s]
simTime = 64;             % simulation horizon [s]
swapTime = 32;            % flywheel change [s]

Km = 1;                   % normalized motor gain
b = 1;                    % normalized viscous friction
J_small = 1;
J_large = 24;

refAmplitude = 50;
refPeriod = 16;

q0 = 0.06;                % q(z) = z^2 + q1*z + q0
q1 = -0.5;
alpha = 0.98;             % forgetting factor required for re-adaptation
b0Min = 1e-3;             % pole-placement division guard

uMin = -255;
uMax = 255;

noiseVariance = 1e-3 / T;
noiseSeed = 23341;
