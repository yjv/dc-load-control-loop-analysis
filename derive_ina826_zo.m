function sys_fit = derive_ina826_zo(~)
% DERIVE_INA826_ZO Generate INA826 instrumentation amplifier output impedance transfer function model
%
% This function provides a fitted transfer function model for the INA826 instrumentation
% amplifier output impedance based on measured frequency response data from the datasheet.
% The model captures the amplifier's output impedance characteristics across frequency
% for use in control loop analysis.
%
% USAGE:
%   sys_fit = derive_ina826_zo()           % Return fitted transfer function with plotting
%   sys_fit = derive_ina826_zo(0)          % Return fitted transfer function only
%
% OUTPUTS:
%   sys_fit - Symbolic transfer function model of INA826 output impedance characteristics
%
% TRANSFER FUNCTION MODEL:
%   The fitted model represents the INA826 output impedance with appropriate
%   poles and zeros to match the measured frequency response characteristics
%   from the datasheet specifications.
%
% DATA SOURCE:
%   Frequency response data is based on INA826 datasheet specifications
%   covering the amplifier's output impedance behavior across frequency.
%   Only magnitude data is available; phase data is not fitted.
%
% VISUALIZATION:
%   When called with no arguments (~nargin), the function displays:
%   - Single figure with output impedance vs. frequency plot comparing fitted model vs. measured magnitude data
%
% EXAMPLE:
%   % Get INA826 output impedance model with visualization
%   Z_ina = derive_ina826_zo();
%
%   % Get model without plotting
%   Z_ina = derive_ina826_zo(0);
%
% NOTES:
%   - Model is based on datasheet frequency response data
%   - Fitted to match impedance magnitude characteristics (no phase data available)
%   - INA826 is referenced but not directly used in the main control loop
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
        % Frequency points for INA826 output impedance measurement (Hz)
    frequency = [
    1
    1.25892541179417
    1.58489319246111
    1.99526231496888
    2.51188643150958
    3.16227766016838
    3.98107170553497
    5.01187233627272
    6.30957344480193
    7.94328234724282
    10
    12.5892541179417
    15.8489319246111
    19.9526231496888
    25.1188643150958
    31.6227766016838
    39.8107170553497
    50.1187233627272
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
    9999.99999999999
    12589.2541179417
    15848.9319246111
    19952.6231496888
    25118.8643150958
    31622.7766016838
    39810.7170553498
    50118.7233627273
    63095.7344480194
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
    3.98107170553498e6
    5.01187233627272e6
    6.30957344480194e6
    7.94328234724282e6
    1e7
    ]';  % Frequency points for INA826 output impedance measurement (Hz)
    
    w = 2*pi*frequency;
    
    % INA826 output impedance data from datasheet (Ω)
    zo = [
    4e4
    3.5e4
    2.6e4
    2.2e4
    1.65e4
    1.4e4
    1.05e4
    8.5e3
    6.6e3
    5.5e3
    4.1e3
    3.4e3
    2.6e3
    2.1e3
    1.7e3
    1.4e3
    1.05e3
    900
    680
    550
    450
    370
    300
    270
    230
    210
    190
    182
    173
    168
    166
    164
    163
    162
    162
    162
    161
    161
    161
    161
    161
    162
    162
    162
    164
    168
    172
    180
    189
    200
    215
    235
    260
    280
    310
    330
    350
    360
    380
    390
    400
    410
    420
    428
    440
    480
    520
    600
    690
    800
    950

    ]';   % INA826 output impedance magnitude data (Ω)
    

    syms s
    % Fitted transfer function model for INA826 output impedance characteristics
    sys_fit = 60000/(s/(2*pi*.7)+1)*(s/(2*pi*2.6e2)+1)*(s/(2*pi*1e5)+1)/(s/(2*pi*2.5e5)+1)*(s/(2*pi*4.7e6)+1);
    
    if ~nargin
        % Visualization mode: create output impedance plot comparing fitted model to datasheet data
        % Compute magnitude and phase of fitted transfer function
        [zo_fit, phase_fit] = bode(tf_from_sym(sys_fit), w);
        zo_fit = squeeze(zo_fit);
        phase_fit = squeeze(phase_fit);
        
        % Create figure for output impedance plot visualization
        figure;
        
        % Configure axes properties
        ax = axes;
        hold on;
        
        ax.YDir = 'normal';  % Normal y-axis direction
        ax.XScale = 'log';   % Logarithmic frequency scale
        ax.YScale = 'log';   % Logarithmic y-axis scale for impedance
        
        % Plot impedance comparison (left y-axis)
        yyaxis left
        semilogx(frequency, zo_fit, 'r-', 'LineWidth', 1.5); hold on;
        semilogx(frequency(1:length(zo)), zo, 'b.', 'MarkerSize', 10);
        ylabel('Z_o (\Omega)');
        ylim([100, 100e3]);    % Auto-scale y-axis with margin
        
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