function [a0_est, b0_est, traceP] = rls_estimator(y_curr, y_prev, u_prev, alpha)
% RLS-Schaetzer fuer G(z) = b0 / (z + a0)  ->  Parameter [a0; b0]
% Basis: Referenzmodell (ACE-II-AdaptiveControl / First Order Model).
% Delta zur Referenz (validiert in matlab/design_study.m, s. README "Design study"):
%   - alpha ist Eingang (Empfehlung 0.98 statt fest 1.0): noetig fuer Re-Adaption
%     nach Schwungrad-Wechsel; mit alpha = 1.0 endet L->S im Grenzzyklus.
%   - Anregungs-Gate: Update nur wenn C*C' > 1e-6, sonst P und xe halten ->
%     kein Covariance-Windup im Leerlauf (omega_ref = 0).
%   - P-Symmetrisierung gegen numerische Drift.
%   - traceP als Ausgang (Windup-Monitor fuer den Adaptions-Scope).
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
