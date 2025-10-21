function sys_fit = derive_opa210_zo(~)
% DERIVE_OPA210_ZO Generate OPA210 operational amplifier output impedance transfer function model
%
% This function provides a fitted transfer function model for the OPA210 operational
% amplifier output impedance based on measured frequency response data from the datasheet.
% The model captures the amplifier's output impedance characteristics across frequency
% for use in control loop analysis.
%
% USAGE:
%   sys_fit = derive_opa210_zo()           % Return fitted transfer function with plotting
%   sys_fit = derive_opa210_zo(0)          % Return fitted transfer function only
%
% OUTPUTS:
%   sys_fit - Symbolic transfer function model of OPA210 output impedance characteristics
%
% TRANSFER FUNCTION MODEL:
%   The fitted model represents the OPA210 output impedance with appropriate
%   poles and zeros to match the measured frequency response characteristics
%   from the datasheet specifications.
%
% DATA SOURCE:
%   Frequency response data is based on OPA210 datasheet specifications
%   covering the range from 10 Hz to 100 MHz. Only magnitude data is
%   available; phase data is not fitted.
%
% VISUALIZATION:
%   When called with no arguments (~nargin), the function displays:
%   - Single figure with log-log plot comparing fitted model vs. measured magnitude data
%
% EXAMPLE:
%   % Get OPA210 output impedance model with visualization
%   Z_opamp = derive_opa210_zo();
%
%   % Get model without plotting
%   Z_opamp = derive_opa210_zo(0);
%
% NOTES:
%   - Model is based on datasheet frequency response data
%   - Fitted to match impedance magnitude characteristics (no phase data available)
%   - Used in control loop analysis for G3 transfer function
%   - Output impedance affects loop stability and load regulation
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
    % OPA210 frequency response data from datasheet (Hz)
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
    3.98107170553498e6
    5.01187233627272e6
    6.30957344480194e6
    7.94328234724282e6
    1e7
    1.25892541179417e7
    1.58489319246111e7
    1.99526231496888e7
    2.51188643150958e7
    3.16227766016838e7
    3.98107170553498e7
    5.01187233627272e7
    6.30957344480194e7
    7.94328234724282e7
    1e8
    ]';  % OPA210 frequency response data from datasheet (Hz)
    
    w = 2*pi*frequency;
    
    % OPA210 output impedance data from datasheet (Ω)
    zo = [
    490
    390
    310
    245
    195
    155
    123
    98
    76
    60
    48
    38
    30
    24
    19.5
    15.5
    12.5
    10
    8
    6.5
    5.5
    4.6
    4
    3.6
    3.25
    3
    2.9
    2.8
    2.7
    2.675
    2.65
    2.65
    2.65
    2.65
    2.65
    2.65
    2.675
    2.7
    2.75
    2.8
    2.9
    3.05
    3.3
    3.6
    4.05
    4.7
    5.5
    6.6
    8
    10
    12
    14.5
    17.5
    20.3
    23
    26
    28
    30
    31.5
    32.5
    33
    33.5
    34
    34.5
    34.7
    35
    35.6
    37
    38
    40
    42
    ]';   % OPA210 output impedance magnitude data (Ω)
    
    syms s
    % Fitted transfer function model for OPA210 output impedance characteristics
    sys_fit = 4900/(s/(2*pi)+1)*(s/(2*pi*1.85e3)+1)*(s/(2*pi*2.1e5)+1)/(s/(2*pi*2.7e6)+1)*(s/(2*pi*1.35e8)+1)/(s/(2*pi*6.35e8)+1)^2;
    
    if ~nargin
        % Visualization mode: create output impedance plot comparing fitted model to datasheet data
        % Compute magnitude and phase of fitted transfer function
        [zo_fit, phase_fit] = bode(tf_from_sym(sys_fit), w);
        zo_fit = squeeze(zo_fit);
        phase_fit = squeeze(phase_fit);
        
        % Create figure for output impedance plot visualization
        figure;
        
        % Set up axes with logarithmic frequency scale
        ax = axes;
        hold on;
        
        % Configure axes properties
        ax.YDir = 'normal';  % Normal y-axis direction
        ax.XScale = 'log';   % Logarithmic frequency scale
        ax.YScale = 'log';   % Logarithmic y-axis scale for impedance
        
        % Plot impedance comparison (left y-axis)
        yyaxis left
        semilogx(frequency, zo_fit, 'r-', 'LineWidth', 1.5); hold on;
        semilogx(frequency(1:length(zo)), zo, 'b.', 'MarkerSize', 10);
        ylabel('Z_o (\Omega)');
        ylim([1, 1e3]);    % Auto-scale y-axis with margin
        
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