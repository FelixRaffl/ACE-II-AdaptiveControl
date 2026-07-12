function [d0, d1] = pole_placement_controller(a0_est, b0_est, q0, q1, b0Min)
% Pole placement: desired closed-loop polynomial q(z) = z^2 + q1*z + q0
% Standard: q0 = 0.06, q1 = -0.5 (settling around 250 ms at T = 0.08 s).
% Delta from the reference model, validated in matlab/design_study.m:
%   - b0 guard: while |b0_est| <= b0Min (recommended 1e-3), hold the last
%     valid gains to avoid division blow-up before the estimator converges.
%     This replaces the script's start-up gain freeze, which proved
%     counterproductive in the design study.
    persistent d0Hold d1Hold
    if isempty(d0Hold)
        d0Hold = -0.44;
        d1Hold = 1.0;
    end
    if abs(b0_est) > b0Min
        d0Hold = (q0 + a0_est) / b0_est;
        d1Hold = (q1 + 1.0 - a0_est) / b0_est;
    end
    d0 = d0Hold;
    d1 = d1Hold;
end
