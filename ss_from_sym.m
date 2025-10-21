function H_ss = ss_from_sym(H_sym)
% SS_FROM_SYM Convert symbolic transfer function to state-space representation
%
% This function converts a symbolic transfer function expression to a MATLAB
% state-space representation. It extracts the numerator and denominator
% coefficients and creates a state-space model structure for control system
% analysis.
%
% USAGE:
%   H_ss = ss_from_sym(H_sym)
%
% INPUTS:
%   H_sym - Symbolic transfer function expression
%
% OUTPUTS:
%   H_ss - State-space model structure with fields:
%          A - State matrix
%          B - Input matrix  
%          C - Output matrix
%          D - Feedthrough matrix
%
% PROCESS:
%   1. Extracts numerator and denominator from symbolic expression
%   2. Converts symbolic polynomials to coefficient vectors
%   3. Converts transfer function to state-space representation
%   4. Returns state-space matrices in structure format
%
% EXAMPLE:
%   syms s;
%   H_sym = (s + 1) / (s^2 + 2*s + 1);
%   H_ss = ss_from_sym(H_sym);
%
% NOTES:
%   - Converts transfer function to controllable canonical form
%   - Useful for state-space analysis and controller design
%   - State-space representation provides insight into system dynamics
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
    s = sym('s');
    [num_sym, den_sym] = numden(H_sym);
    num_coeffs = coeffs(num_sym, s, 'All');
    den_coeffs = coeffs(den_sym, s, 'All');
    [A, B, C, D] = tf2ss(num_coeffs, den_coeffs);
    H_ss = struct( ...
        'A', A, ...
        'B', B, ...
        'C', C,...
        'D', D...
    );
end
