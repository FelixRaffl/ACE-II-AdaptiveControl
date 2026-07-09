function u = PI_C(d0, d1, e_curr, e_prev, u_prev)
% Inkrementeller PI-Regler:  u(k) = u(k-1) + d1*e(k) + d0*e(k-1)
% VERBATIM aus dem Referenzmodell.
% Hinweis ESP32: u danach auf [-255, 255] saturieren; das saturierte u
% ist u_prev fuer den naechsten Schritt (Anti-Windup-konsistent mit der Strecke).
    u = u_prev + (d1 * e_curr) + (d0 * e_prev);
end
