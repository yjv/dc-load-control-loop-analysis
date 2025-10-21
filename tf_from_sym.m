function H_tf = tf_from_sym(H_sym)
% TF_FROM_SYM Convert symbolic transfer function to MATLAB transfer function object
%
% This function converts a symbolic transfer function expression to a MATLAB
% transfer function object (tf). It extracts the numerator and denominator
% coefficients and creates a tf object for use in control system analysis.
%
% USAGE:
%   H_tf = tf_from_sym(H_sym)
%
% INPUTS:
%   H_sym - Symbolic transfer function expression
%
% OUTPUTS:
%   H_tf - MATLAB transfer function object (tf)
%
% PROCESS:
%   1. Extracts numerator and denominator from symbolic expression
%   2. Converts symbolic coefficients to polynomial coefficients
%   3. Creates MATLAB transfer function object
%
% EXAMPLE:
%   syms s;
%   H_sym = (s + 1) / (s^2 + 2*s + 1);
%   H_tf = tf_from_sym(H_sym);
%
% NOTES:
%   - No normalization is applied (use normalize_tf_from_sym.m for normalization)
%   - Useful for direct conversion from symbolic expressions to tf objects
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
    % Extract numerator and denominator from symbolic expression
    [num_sym, den_sym] = numden(H_sym);
    
    % Convert symbolic coefficients to polynomial coefficients
    num_coeffs = sym2poly(num_sym);
    den_coeffs = sym2poly(den_sym);
    
    % Create MATLAB transfer function object
    H_tf = tf(num_coeffs, den_coeffs);
end
