function sys_fit = derive_ina826_gain(~)
% DERIVE_INA826_GAIN Generate INA826 instrumentation amplifier gain transfer function model
%
% This function provides a fitted transfer function model for the INA826 instrumentation
% amplifier based on measured frequency response data from the datasheet. The model
% captures the amplifier's gain characteristics across frequency for use in control
% loop analysis.
%
% USAGE:
%   sys_fit = derive_ina826_gain()           % Return fitted transfer function with plotting
%   sys_fit = derive_ina826_gain(0)          % Return fitted transfer function only
%
% OUTPUTS:
%   sys_fit - Symbolic transfer function model of INA826 gain characteristics
%
% TRANSFER FUNCTION MODEL:
%   The fitted model represents the INA826 gain with appropriate poles and zeros
%   to match the measured frequency response characteristics from the datasheet
%   specifications.
%
% DATA SOURCE:
%   Frequency response data is based on INA826 datasheet specifications
%   covering the amplifier's gain characteristics across frequency. Only
%   magnitude data is available; phase data is not fitted.
%
% VISUALIZATION:
%   When called with no arguments (~nargin), the function displays:
%   - Single figure with Bode plot comparing fitted model vs. measured magnitude data
%
% EXAMPLE:
%   % Get INA826 gain model with visualization
%   H_ina = derive_ina826_gain();
%
%   % Get model without plotting
%   H_ina = derive_ina826_gain(0);
%
% NOTES:
%   - Model is based on datasheet frequency response data
%   - Fitted to match gain rolloff characteristics (no phase data available)
%   - Used in control loop analysis for G5 transfer function
%   - INA826 is referenced but not directly used in the main control loop
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
    % Frequency points for INA826 gain measurement (Hz)
    frequency = [
    10
    12.5892541179417
    15.8489319246111
    19.9526231496888
    25.1188643150958
    31.6227766016838
    39.8107170553497
    50.1187233627273
    63.0957344480193
    79.4328234724281
    100
    125.892541179417
    158.489319246111
    199.526231496888
    251.188643150958
    316.227766016838
    398.107170553497
    501.187233627272
    630.957344480193
    794.328234724281
    1000
    1258.92541179417
    1584.89319246111
    1995.26231496888
    2511.88643150958
    3162.27766016838
    3981.07170553497
    5011.87233627272
    6309.57344480193
    7943.28234724281
    10000
    12589.2541179417
    15848.9319246111
    19952.6231496888
    25118.8643150958
    31622.7766016838
    39810.7170553498
    50118.7233627273
    63095.7344480193
    79432.8234724282
    1e5
    1.25892541179417e5
    1.58489319246111e5
    1.99526231496888e5
    2.51188643150958e5
    3.16227766016838e5
    3.98107170553498e5
    5.01187233627273e5
    6.30957344480194e5
    7.94328234724282e5
    1e6
    1.25892541179417e6
    1.58489319246111e6
    1.99526231496888e6
    2.51188643150958e6
    3.16227766016838e6
    ]';  % Frequency points for INA826 gain measurement (Hz)
    
    w = 2*pi*frequency;
    
    % INA826 gain data from datasheet (dB)
    gain_db = [
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    0
    -.2
    -.5
    -1.2
    -2.3
    -4
    -7
    -11
    -17
    -28
    ]';   % INA826 gain magnitude data (dB)
    
    syms s
    % Fitted transfer function model for INA826 gain characteristics
    sys_fit = 1*(s/(2*pi*0.95e6)+1)^2*(s/(2*pi*1.45e6)+1)^2/(s/(2*pi*1.65e6)+1)^2/(s/(2*pi*1.75e6)+1)^4/(s/(2*pi*2.1e6)+1)^3/(s/(2*pi*2.2e6)+1)/(s/(2*pi*2.4e6)+1);

    if ~nargin
        % Visualization mode: create Bode plot comparing fitted model to datasheet data
        % Compute magnitude and phase of fitted transfer function
        [mag_fit, phase_fit] = bode(tf_from_sym(sys_fit), w);
        mag_fit = squeeze(mag_fit);
        phase_fit = squeeze(phase_fit);
        
        % Convert magnitude to dB for comparison with datasheet data
        mag_fit_db = 20*log10(mag_fit);
        
        % Create figure for Bode plot visualization
        figure;
        
        % Configure axes properties
        ax = axes;
        hold on;
        
        ax.YDir = 'normal';  % Normal y-axis direction
        ax.XScale = 'log';   % Logarithmic frequency scale
        
        % Plot magnitude comparison (left y-axis)
        yyaxis left
        semilogx(frequency, mag_fit_db, 'r-', 'LineWidth', 1.5); hold on;
        semilogx(frequency(1:length(gain_db)), gain_db, 'b.', 'MarkerSize', 10);
        ylabel('Magnitude (dB)');
        ylim([min(mag_fit_db) - 5, max(mag_fit_db) + 5]);    % Auto-scale y-axis with margin
        
        % Plot phase response (right y-axis) - fitted model only (no datasheet phase data)
        yyaxis right
        semilogx(frequency, phase_fit, 'g--', 'LineWidth', 1.5);
        ylabel('Phase (degrees)');
        ylim([min(phase_fit) - 10, max(phase_fit) + 10]);    % Auto-scale y-axis with margin
        
        % Configure plot appearance
        xlabel('Frequency (Hz)');
        xlim([min(frequency), max(frequency)]);
        
        legend('Fitted Mag', 'Data Mag', 'Fitted Phase', 'Location', 'Best');
        grid on;
        
    end
end