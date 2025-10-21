function [num, den] = numden_coeffs(H_sym)
% NUMDEN_COEFFS Extract numerator and denominator coefficients from symbolic transfer function
%
% This function extracts the numerator and denominator polynomial coefficients
% from a symbolic transfer function expression. It's a utility function used
% in the process of converting symbolic transfer functions to MATLAB transfer
% function objects.
%
% USAGE:
%   [num, den] = numden_coeffs(H_sym)
%
% INPUTS:
%   H_sym - Symbolic transfer function expression
%
% OUTPUTS:
%   num - Numerator polynomial coefficients (vector)
%   den - Denominator polynomial coefficients (vector)
%
% PROCESS:
%   1. Extracts numerator and denominator from symbolic expression
%   2. Converts symbolic polynomials to coefficient vectors
%   3. Returns coefficients in descending power order
%
% EXAMPLE:
%   syms s;
%   H_sym = (s + 1) / (s^2 + 2*s + 1);
%   [num, den] = numden_coeffs(H_sym);
%
% NOTES:
%   - Utility function used in transfer function conversion processes
%   - Coefficients are returned in MATLAB polynomial format
%   - Used by normalize_tf_from_sym.m and tf_from_sym.m
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
    s = sym('s');
    [num, den] = numden(H_sym);
    num = coeffs(num, s, 'All');
    den = coeffs(den, s, 'All');
end