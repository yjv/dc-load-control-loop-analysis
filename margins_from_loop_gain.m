function [gain_margin, phase_margin, f_gain0, f_phase_neg180, f_gain20, f_gainn20] = margins_from_loop_gain(mag_db, phase, f)
% MARGINS_FROM_LOOP_GAIN Calculate stability margins from loop gain frequency response
%
% This function calculates gain margin, phase margin, and crossover frequencies 
% from the frequency response data of a loop gain transfer function. These 
% parameters are essential for assessing the stability of a control system.
%
% USAGE:
%   [gain_margin, phase_margin, f_gain0, f_phase_neg180, f_gain20, f_gainn20] = margins_from_loop_gain(mag_db, phase, f)
%
% INPUTS:
%   mag_db - Magnitude response in dB (vector)
%   phase  - Phase response in degrees (vector)
%   f      - Frequency vector in Hz (vector)
%
% OUTPUTS:
%   gain_margin     - Gain margin in dB (negative values indicate stability)
%   phase_margin    - Phase margin in degrees (positive values indicate stability)
%   f_gain0         - Unity gain frequency (0 dB crossover) in Hz
%   f_phase_neg180  - Phase crossover frequency (-180° crossing) in Hz
%   f_gain20        - Frequency where gain reaches 20 dB in Hz
%   f_gainn20       - Frequency where gain reaches -20 dB in Hz
%
% STABILITY CRITERIA:
%   - Gain margin < 0 dB: Stable (negative gain margin)
%   - Gain margin > 0 dB: Unstable (positive gain margin)
%   - Phase margin > 0°: Stable (positive phase margin)
%   - Phase margin < 0°: Unstable (negative phase margin)
%   - Marginal stability: f_0dB < f_-180° (unity gain before -180° phase)
%   - Good stability: Gain margin ≤ -6 dB, Phase margin ≥ 40°
%
% EXAMPLE:
%   % Calculate margins from loop gain frequency response
%   [gm, pm, f0, f180, f20, fn20] = margins_from_loop_gain(mag_db, phase, f);
%
% NOTES:
%   - Uses linear interpolation for accurate crossover frequency determination
%   - Returns maximum frequency if crossover not found in data range
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0

    % Helper function to find frequency for specific gain level
    % INPUTS:
    %   mag_db  - Magnitude response in dB (vector)
    %   gain_db - Target gain level in dB (scalar)
    function f_gain = frequency_for_gain_db(mag_db, gain_db)
        % Find first index where magnitude drops below target gain
        idx_gain = find(mag_db < gain_db, 1, 'first');
        if isempty(idx_gain)
            % If no crossover found, return maximum frequency
            f_gain = max(f);
        else
            % Use linear interpolation for accurate crossover frequency
            f_gain = interp1(mag_db(idx_gain-1:idx_gain), ...
                f(idx_gain-1:idx_gain), ...
                gain_db);
        end
    end
    
    % Calculate gain crossover frequencies
    f_gain0 = frequency_for_gain_db(mag_db, 0);      % Unity gain frequency (0 dB)
    f_gain20 = frequency_for_gain_db(mag_db, 20);    % 20 dB gain frequency
    f_gainn20 = frequency_for_gain_db(mag_db, -20);  % -20 dB gain frequency

    % Find phase crossover frequency (-180° crossing)
    idx_phase_cross = find(phase < -180, 1, 'first');
    if isempty(idx_phase_cross)
        % If no -180° crossing found, return maximum frequency
        f_phase_neg180 = max(f);
    else
        % Use linear interpolation for accurate crossover frequency
        f_phase_neg180 = interp1(phase(idx_phase_cross-1:idx_phase_cross), ...
                         f(idx_phase_cross-1:idx_phase_cross), ...
                         -180);
    end
    
    % Calculate phase margin (phase at unity gain frequency + 180°)
    phase_at_0db = interp1(f, phase, f_gain0);
    phase_margin = 180 + phase_at_0db;

    % Calculate gain margin (gain at -180° phase crossover frequency)
    gain_at_m180_dB = interp1(f, mag_db, f_phase_neg180);
    gain_margin = gain_at_m180_dB;
end