function N = normalize_tf_from_sym(H)
% NORMALIZE_TF_FROM_SYM Normalize symbolic transfer function
%
% This function converts a symbolic transfer function to a normalized MATLAB
% transfer function object. It extracts the numerator and denominator 
% coefficients from the symbolic expression and applies normalization to prevent
% numerical overflow. While the ratio of numerator to denominator coefficients 
% may be reasonable, the absolute magnitude of individual coefficients can be 
% very large, leading to Inf and NaN values in computations.
%
% USAGE:
%   N = normalize_tf_from_sym(H)
%
% INPUTS:
%   H - Symbolic transfer function expression
%
% OUTPUTS:
%   N - Normalized transfer function object (tf)
%
% PROCESS:
%   1. Extracts numerator and denominator from symbolic expression
%   2. Converts symbolic coefficients to polynomial coefficients
%   3. Applies normalization using median-based scaling to prevent numerical overflow
%   4. Creates MATLAB transfer function object with normalized coefficients
%
% EXAMPLE:
%   syms s;
%   H_sym = (s + 1) / (s^2 + 2*s + 1);
%   N = normalize_tf_from_sym(H_sym);
%
% DEPENDENCIES:
%   - normalize_tf_from_numden.m - Core normalization function
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
        % Extract numerator and denominator from symbolic expression
        [num, den] = numden(H);
        
        % Convert symbolic coefficients to polynomial coefficients
        num_coeffs = sym2poly(num);
        den_coeffs = sym2poly(den);
        
        % Apply normalization and create transfer function
        N = normalize_tf_from_numden(num_coeffs, den_coeffs);
    end