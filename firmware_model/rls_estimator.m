function [a0_est, b0_est, traceP] = rls_estimator(y_curr, y_prev, u_prev, alpha)
% RLS estimator for G(z) = b0 / (z + a0) -> parameters [a0; b0]
% Delta from the reference model, validated in matlab/design_study.m:
%   - alpha is an input (recommended 0.98 instead of fixed 1.0), enabling
%     re-adaptation after the flywheel change; alpha = 1.0 ends L->S in a
%     limit cycle.
%   - Excitation gate: update only when C*C' > 1e-6; otherwise hold P and xe
%     to avoid covariance windup while omega_ref = 0.
%   - P symmetrisation against numerical drift.
%   - traceP output for the adaptation scope windup monitor.
% MATLAB-Function-Block, Sample-Time T = 0.08 s.
    persistent P xe
    if isempty(P)
        P = 100.0 * eye(2);
        xe = [-0.5; 1.0];
    end
    C = [-y_prev, u_prev];
    if (C * C') > 1e-6
        den = C * P * C' + alpha;
        L = (P * C') / den;
        xe = xe + L * (y_curr - C * xe);
        P = (eye(2) - L * C) * P / alpha;
        P = 0.5 * (P + P');
    end
    a0_est = xe(1);
    b0_est = xe(2);
    traceP = P(1,1) + P(2,2);
end
