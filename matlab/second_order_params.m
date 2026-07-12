%% Shared second-order model parameters.
%
% Single source of the second-order model parameters shared by the builder,
% the validator and the plot export.

function p = second_order_params()
    p.Km = 0.05;
    p.J  = 0.001;
    p.b  = 0.0005;
    p.La = 0.002;
    p.Ra = 2.0;

    p.T       = 0.002;  % 2 ms - resolves the electrical pole
    p.alpha   = 1.0;    % no forgetting; alpha < 1 without PE causes P windup/bursting
    p.P0      = 100;    % P = P0 * eye(4)
    p.uMax    = 12;     % armature voltage limit [V]
    p.kFreeze = 50;     % apply pole placement only after 50 samples
    p.tEnd    = 8;      % simulation horizon [s]
    p.tPhase1 = 4;      % dither excitation horizon [s]

    p.ditherAmp  = 1.5; % PRBS actuator dither amplitude [V]
    p.prbsHold   = 5;   % bit duration in samples, 5*T = 10 ms
    p.tracePLimit = 9000;

    p.pFast = 0.1357;   % electrical plant pole at T = 2 ms
    r = exp(-p.T / 0.05);
    % Design rule: modes much faster than the desired bandwidth are not
    % moved; otherwise the controller must invert the fast dynamics and can
    % become unstable, which necessarily diverges behind saturation.
    q = poly([0 p.pFast r r]);
    p.q3 = q(2);
    p.q2 = q(3);
    p.q1 = q(4);
    p.q0 = q(5);

    Gd = c2d(tf(p.Km, [p.La*p.J, p.La*p.b + p.Ra*p.J, p.Ra*p.b + p.Km^2]), ...
        p.T, 'zoh');
    [numd, dend] = tfdata(Gd, 'v');
    numd = numd / dend(1);
    dend = dend / dend(1);
    p.a1 = dend(end-1);
    p.a0 = dend(end);
    p.b1 = numd(end-1);
    p.b0 = numd(end);
end
