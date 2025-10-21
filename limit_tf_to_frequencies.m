function H_lim = limit_tf_to_frequencies(H, f_min, f_max)
% LIMIT_TF_TO_FREQUENCIES Limit transfer function poles and zeros to specified frequency range
%
% This function creates a simplified transfer function by limiting poles and zeros
% to a specified frequency range while maintaining causality. It's useful for
% reducing the complexity of high-order transfer functions for analysis and
% visualization purposes.
%
% USAGE:
%   H_lim = limit_tf_to_frequencies(H, f_min, f_max)
%
% INPUTS:
%   H     - Original transfer function object (tf)
%   f_min - Minimum frequency for pole/zero inclusion (Hz)
%   f_max - Maximum frequency for pole/zero inclusion (Hz)
%
% OUTPUTS:
%   H_lim - Limited transfer function object (tf) with poles/zeros in specified range
%
% METHOD:
%   1. Identifies poles and zeros within the target frequency range
%   2. Ensures minimum number of poles for causality (at least zeros + 1)
%   3. Adds nearest out-of-range poles if needed to maintain causality
%   4. Ensures complex poles have their conjugate pairs
%   5. Preserves DC gain of the original transfer function
%
% EXAMPLE:
%   % Limit transfer function to frequency range of interest
%   H_lim = limit_tf_to_frequencies(H, 1e3, 1e6);
%
% NOTES:
%   - Maintains causality by ensuring adequate number of poles
%   - Preserves DC gain characteristics
%   - Useful for simplifying complex transfer functions for analysis
%   - Used in interactive control loop analysis for root locus and pole-zero plots
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
    % Convert frequency limits to angular frequency (rad/s)
    w_min = 2*pi*f_min;
    w_max = 2*pi*f_max;

    % Extract all zeros and poles from the original transfer function
    zeros_all = zero(H);
    poles_all = pole(H);
    
    % Identify zeros and poles within the target frequency range
    % abs() gives magnitude (angular frequency in rad/s) for complex poles/zeros
    in_range_zero = (abs(zeros_all) >= w_min) & (abs(zeros_all) <= w_max);
    in_range_pole = (abs(poles_all) >= w_min) & (abs(poles_all) <= w_max);
    
    % Extract poles and zeros within the specified frequency range
    zeros_lim = zeros_all(in_range_zero);
    poles_in_range = poles_all(in_range_pole);
    
    % Determine minimum number of poles needed for strictly proper transfer function
    % A strictly proper transfer function must have more poles than zeros (at least 1 extra)
    n_required_poles = max(numel(zeros_lim) + 1, 1);
    
    % Check if we have enough poles within the frequency range
    if numel(poles_in_range) >= n_required_poles
        % Use only poles within the specified frequency range
        poles_lim = poles_in_range;
    else
        % Need to add poles from outside the frequency range to maintain causality
        poles_out_range = poles_all(~in_range_pole);
        % Calculate distance from each out-of-range pole to the frequency boundaries
        dist_to_range = min(abs(abs(poles_out_range) - w_min), abs(abs(poles_out_range) - w_max));
        % Sort poles by distance to frequency range (closest first)
        [~, sort_idx] = sort(dist_to_range);
        % Calculate how many additional poles we need
        n_needed = n_required_poles - numel(poles_in_range);
        % Select the nearest out-of-range poles
        poles_extra = poles_out_range(sort_idx(1:min(n_needed, numel(sort_idx))));
        % Combine in-range and extra poles
        poles_lim = [poles_in_range; poles_extra];
    end
    
    % Ensure conjugate pairs exist for all complex poles
    % Real systems must have complex poles in conjugate pairs
    tol = 1e-8;  % Tolerance for numerical comparisons
    
    for i = 1:numel(poles_lim)
        p = poles_lim(i);
        % Check if this pole has an imaginary part (complex pole)
        if abs(imag(p)) > tol
            conj_p = conj(p);  % Calculate the complex conjugate
            % Check if the conjugate pole is already in our pole list
            if ~any(abs(poles_lim - conj_p) < tol)
                % Add the conjugate pole if it's missing
                poles_lim = [poles_lim; conj_p];
            end
        end
    end
    
    % Sort poles by frequency magnitude for consistent ordering
    [~, sort_idx] = sort(abs(poles_lim));
    poles_lim = poles_lim(sort_idx);

    % Construct the final limited transfer function
    % Preserve the DC gain of the original transfer function
    gain = dcgain(H);  % Extract DC gain from original transfer function
    H_lim = zpk(zeros_lim, poles_lim, gain);  % Create zero-pole-gain form
    
    % Normalize to preserve the exact DC gain (zpk gain ≠ DC gain)
    H_lim = gain/dcgain(H_lim) * H_lim;

end