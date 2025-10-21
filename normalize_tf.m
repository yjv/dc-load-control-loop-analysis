function N = normalize_tf(H)
% NORMALIZE_TF Normalize transfer function for numerical stability
%
% This function normalizes a transfer function by scaling the numerator and 
% denominator coefficients to prevent numerical overflow. While the ratio of 
% numerator to denominator coefficients may be reasonable, the absolute magnitude 
% of individual coefficients can be very large, leading to Inf and NaN values 
% in computations.
%
% USAGE:
%   N = normalize_tf(H)
%
% INPUTS:
%   H - Transfer function object (tf)
%
% OUTPUTS:
%   N - Normalized transfer function object (tf)
%
% METHOD:
%   The function uses the median of the logarithm of denominator coefficients
%   as a scaling factor to normalize the transfer function while preserving
%   its frequency response characteristics and preventing numerical overflow.
%
% EXAMPLE:
%   % Normalize a transfer function
%   H = tf([1 2 3], [1 10 100]);
%   N = normalize_tf(H);
%
% DEPENDENCIES:
%   - normalize_tf_from_numden.m - Core normalization function
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
    N = normalize_tf_from_numden(H.Numerator{1}, H.Denominator{1});
end