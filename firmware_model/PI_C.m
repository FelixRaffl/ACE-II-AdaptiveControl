function u = PI_C(d0, d1, e_curr, e_prev, u_prev)
% Incremental PI controller: u(k) = u(k-1) + d1*e(k) + d0*e(k-1)
% Verbatim from the reference model.
% ESP32 note: saturate u to [-255, 255] afterwards; the saturated u is
% u_prev for the next step, consistent with anti-windup in the plant path.
    u = u_prev + (d1 * e_curr) + (d0 * e_prev);
end
