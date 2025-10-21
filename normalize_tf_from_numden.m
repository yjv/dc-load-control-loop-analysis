function N = normalize_tf_from_numden(num_coeffs, den_coeffs)
% NORMALIZE_TF_FROM_NUMDEN Normalize transfer function from numerator and denominator coefficients
%
% This function normalizes a transfer function by scaling the numerator and 
% denominator coefficients to prevent numerical overflow. While the ratio of numerator 
% to denominator coefficients may be reasonable (e.g., 123456789/23456789 ≈ 5.26), 
% the absolute magnitude of individual coefficients can be very large, leading to Inf 
% and NaN values in computations. This scaling preserves the transfer function's 
% frequency response while maintaining numerical stability.
%
% USAGE:
%   N = normalize_tf_from_numden(num_coeffs, den_coeffs)
%
% INPUTS:
%   num_coeffs - Numerator coefficients (vector)
%   den_coeffs - Denominator coefficients (vector)
%
% OUTPUTS:
%   N - Normalized transfer function object (tf)
%
% METHOD:
%   The normalization process:
%   1. Calculates the median of log10(abs(den_coeffs)) for non-zero coefficients
%   2. Uses this as a scaling factor (10^median)
%   3. Scales both numerator and denominator by this factor
%   4. Creates a new transfer function with scaled coefficients
%
% EXAMPLE:
%   % Normalize transfer function coefficients
%   num = [1 2 3];
%   den = [1 10 100 1000];
%   N = normalize_tf_from_numden(num, den);
%
% NOTES:
%   - Only positive denominator coefficients are used for scaling calculation
%   - The scaling preserves the transfer function's frequency response
%   - Prevents Inf/NaN values caused by large absolute coefficient magnitudes
%   - Addresses cases where both numerator and denominator have large absolute values
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
    
    % Calculate normalization factor from median of denominator coefficients
    den_leading = 10^(median(log10(abs(den_coeffs(den_coeffs > 0)))));
    
    % Scale numerator and denominator coefficients
    num_norm = num_coeffs / den_leading;
    den_norm = den_coeffs / den_leading;
    
    % Create normalized transfer function
    N = tf(num_norm, den_norm);
end