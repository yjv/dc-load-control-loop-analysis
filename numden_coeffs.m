function [num, den] = numden_coeffs(H_sym)
    s = sym('s');
    [num, den] = numden(H_sym);
    num = coeffs(num, s, 'All');
    den = coeffs(den, s, 'All');
end