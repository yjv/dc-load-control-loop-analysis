function sys_fit = derive_ina826_zo(~)
        % Your frequency data (Hz)
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
    ]';  % paste your frequency vector here
    
    w = 2*pi*frequency;
    
    % Your gain data (dB)
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

    ]';   % paste your gain vector here
    

    syms s
    sys_fit = 60000/(s/(2*pi*.7)+1)*(s/(2*pi*2.6e2)+1)*(s/(2*pi*1e5)+1)/(s/(2*pi*2.5e5)+1)*(s/(2*pi*4.7e6)+1);
    
    if ~nargin
        % Compute magnitude and phase of fitted system
        [zo_fit, phase_fit] = bode(tf_from_sym(sys_fit), w);
        zo_fit = squeeze(zo_fit);
        phase_fit = squeeze(phase_fit);
        
        % Create figure and axes
        figure;
        
        % Set up axes for background image
        ax = axes;
        hold on;
        
        % Set limits to match your data range
        ax.YDir = 'normal';  % flip y-axis so it's not upside down
        ax.XScale = 'log';   % semilog scale
        ax.YScale = 'log';   % semilog scale
        
        % Overlay plot on top of image
        yyaxis left
        
        semilogx(frequency, zo_fit, 'r-', 'LineWidth', 1.5); hold on;
        semilogx(frequency(1:length(zo)), zo, 'b.', 'MarkerSize', 10);
        ylabel('Z_o (\Omega)');
        ylim([100, 100e3]);    % adjust based on your dB + phase range
        
        yyaxis right
        semilogx(frequency, phase_fit, 'g--', 'LineWidth', 1.5);
        ylabel('Phase (degrees)');
        ylim([min(phase_fit) - 10, max(phase_fit) + 10]);    % adjust based on your dB + phase range
        
        xlabel('Frequency (Hz)');
        xlim([min(frequency), max(frequency)]);
        
        legend('Fitted Mag', 'Data Mag', 'Fitted Phase', 'Location', 'Best');
        grid on;
    end
end