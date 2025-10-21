function sys_fit = derive_ina296_gain(~)
% DERIVE_INA296_GAIN Generate INA296 current sense amplifier gain transfer function model
%
% This function provides a fitted transfer function model for the INA296 current sense
% amplifier based on measured frequency response data from the datasheet. The model
% captures the amplifier's gain characteristics across frequency for use in control
% loop analysis.
%
% USAGE:
%   sys_fit = derive_ina296_gain()           % Return fitted transfer function with plotting
%   sys_fit = derive_ina296_gain(0)          % Return fitted transfer function only
%
% OUTPUTS:
%   sys_fit - Symbolic transfer function model of INA296 gain characteristics
%
% TRANSFER FUNCTION MODEL:
%   The fitted model represents the INA296 gain with appropriate poles and zeros
%   to match the measured frequency response characteristics from the datasheet.
%
% DATA SOURCE:
%   Frequency response data is based on INA296 datasheet specifications
%   covering the range from 11 Hz to 12.6 MHz. Only magnitude data is
%   available; phase data is not fitted.
%
% VISUALIZATION:
%   When called with no arguments (~nargin), the function displays:
%   - Single figure with Bode plot comparing fitted model vs. measured magnitude data
%
% EXAMPLE:
%   % Get INA296 gain model with visualization
%   H_ina = derive_ina296_gain();
%
%   % Get model without plotting
%   H_ina = derive_ina296_gain(0);
%
% NOTES:
%   - Model is based on datasheet frequency response data
%   - Fitted to match gain rolloff characteristics (no phase data available)
%   - Used in control loop analysis for H2 transfer function
%   - INA296 provides 50x gain at DC, varying with frequency
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0

    % Frequency points for INA296 gain measurement (Hz)
    frequency = [
    11.2589254117942
    11.5848931924611
    11.9952623149689
    12.5118864315096
    13.1622776601684
    13.981071705535
    15.0118723362727
    16.3095734448019
    17.9432823472428
    20
    22.5892541179417
    25.8489319246111
    29.9526231496888
    35.1188643150958
    41.6227766016838
    49.8107170553497
    60.1187233627272
    73.0957344480193
    89.4328234724281
    110
    135.892541179417
    168.489319246111
    209.526231496888
    261.188643150958
    326.227766016838
    408.107170553497
    511.187233627272
    640.957344480193
    804.328234724281
    1010
    1268.92541179417
    1594.89319246111
    2005.26231496888
    2521.88643150958
    3172.27766016838
    3991.07170553497
    5021.87233627273
    6319.57344480193
    7953.28234724281
    10010
    12599.2541179417
    15858.9319246111
    19962.6231496888
    25128.8643150958
    31632.7766016838
    39820.7170553497
    50128.7233627273
    63105.7344480193
    79442.8234724282
    1.0001E+05
    1.25902541179417E+05
    1.58499319246111E+05
    1.99536231496888E+05
    2.51198643150958E+05
    3.16237766016838E+05
    3.98117170553497E+05
    5.01197233627273E+05
    6.30967344480193E+05
    7.94338234724282E+05
    1.00001E+06
    1.25893541179417E+06
    1.58490319246111E+06
    1.99527231496888E+06
    2.51189643150958E+06
    3.16228766016838E+06
    3.98108170553497E+06
    5.01188233627272E+06
    6.30958344480193E+06
    7.94329234724282E+06
    1.000001E+07 
    1.25893541179417E+07
    ]';  % Frequency points for INA296 gain measurement (Hz)
    
    w = 2*pi*frequency;
    
    gain_db = [
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.9794000867204
    33.8039216005703
    33.7148347720453
    33.5338721924973
    33.2551566336315
    32.8690535297238
    32.2556771343947
    31.4806253545544
    30.2376672195775
    28.4649174787362
    26.0205999132796
    22.9225607135648
    20
    17.501225267834
    13.6248247475117
    8.94316062684439
    3.52182518111363
    ]';   % INA296 gain magnitude data (dB)
    
    syms s
    % Fitted transfer function model for INA296 gain characteristics
    sys_fit = 50/(s/(2*pi*1.1e6)+1)^3*(s/(2*pi*8e5)+1)/(s/(2*pi*2.8e6)+1)/(s/(2*pi*1.1e7)+1)*(s/(2*pi*1.05e6)+1);

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