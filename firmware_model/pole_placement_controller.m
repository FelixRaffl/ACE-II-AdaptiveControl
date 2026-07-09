function [d0, d1] = pole_placement_controller(a0_est, b0_est, q0, q1, b0Min)
% Pol-Platzierung: gewuenschtes CL-Polynom q(z) = z^2 + q1*z + q0
% Standard: q0 = 0.06, q1 = -0.5  (Settling ~250 ms bei T = 0.08 s).
% Delta zur Referenz (validiert in matlab/design_study.m):
%   - b0-Guard: solange |b0_est| <= b0Min (Empfehlung 1e-3) werden die letzten
%     gueltigen Gains gehalten -> kein Divisions-Blow-up, bevor der Schaetzer
%     konvergiert ist. Ersetzt den Startup-Gain-Freeze aus dem Skript (Bsp. 7.5),
%     der sich in der Studie als kontraproduktiv erwies.
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
