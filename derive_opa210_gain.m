function sys_fit = derive_opa210_gain(~)
    % Your frequency data (Hz)
    frequency = [
    0.125892541179417
    0.158489319246111
    0.199526231496888
    0.251188643150958
    0.316227766016838
    0.398107170553497
    0.501187233627272
    0.630957344480193
    0.794328234724282
    1
    1.25892541179417
    1.58489319246111
    1.99526231496888
    2.51188643150958
    3.16227766016838
    3.98107170553497
    5.01187233627272
    6.30957344480193
    7.94328234724281
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
    5011.87233627273
    6309.57344480193
    7943.28234724282
    10000
    12589.2541179417
    15848.9319246111
    19952.6231496888
    25118.8643150958
    31622.7766016838
    39810.7170553497
    50118.7233627273
    63095.7344480193
    79432.8234724282
    1e5
    1.25892541179417e5
    1.58489319246111e5
    1.99526231496888e5
    2.51188643150958e5
    3.16227766016838e5
    3.98107170553497e5
    5.01187233627273e5
    6.30957344480193e5
    7.94328234724282e5
    1e6
    1.25892541179417e6
    1.58489319246111e6
    1.99526231496888e6
    2.51188643150958e6
    3.16227766016838e6
    3.98107170553497e6
    5.01187233627272e6
    6.30957344480193e6
    7.94328234724282e6
    1e7
    1.25892541179417e7
    1.58489319246111e7
    1.99526231496888e7
    2.51188643150958e7
    3.16227766016838e7
    3.98107170553497e7
    
    ]';  % paste your frequency vector here
    
    w = 2*pi*frequency;
    
    % Your gain data (dB)
    gain_db = [
    130
    130
    130
    130
    130
    130
    130
    130
    130
    129.8
    129.7
    129.5
    129.3
    129
    128.7
    128.0
    127.2
    126.2
    125
    123.5
    121.8
    120
    118.2
    116.4
    114.5
    112.6
    110.6
    108.6
    106.6
    104.6
    102.6
    100.6
    98.5
    96.5
    94.5
    92.5
    90.5
    88.5
    86.5
    84.5
    82.5
    80.5
    78.5
    76.5
    74.5
    72.5
    70.5
    68.5
    66.5
    64.5
    62.5
    60.5
    58.5
    56.5
    54.5
    52.5
    50.5
    48.5
    46.5
    44.5
    42.5
    40.5
    38.5
    36.5
    34.5
    32.5
    30.5
    28.5
    26.5
    24.5
    22.5
    20.4
    18.4
    16.3
    14.2
    12.1
    10
    8
    6.1
    4.2
    2.55
    0.8
    -0.7
    -1.8
    -2.8
    -3.6
    ]';   % paste your gain vector here
    
    % Your phase (degrees)
    phase = [
    138.5
    138.2
    137.7
    137.2
    136.5
    135.6
    134.7
    133.4
    131.7
    129.4
    126.7
    123.5
    119.8
    115.2
    110
    104
    97.5
    91
    84.5
    79
    73
    68.8
    65.2
    62
    59.5
    57.5
    56
    54.6
    53.6
    52.9
    52.3
    51.75
    51.3
    51
    50.8
    50.7
    50.5
    50.4
    50.35
    50.3
    50.25
    50.2
    50.15
    50.1
    50.1
    50.05
    50
    50
    50
    50
    50
    50
    50
    50
    50
    49.95
    49.8
    49.7
    49.65
    49.65
    49.6
    49.55
    49.5
    49.4
    49.3
    49.15
    49
    48.6
    48.4
    48.2
    47.9
    47.5
    47
    46.7
    46.6
    46.6
    46.6
    46.6
    46.4
    45.4
    44
    43
    40
    38
    29
    20
    ]';   % paste your phase vector here
    
    phase = phase + 40;

    % Convert gain in dB to magnitude
    mag = 10.^(gain_db / 20);
    
    % Convert phase in degrees to radians
    phase_rad = deg2rad(phase);  % your measured phase
    
    % Create complex frequency response
    H = mag .* exp(1j * phase_rad);
    
    syms s
    sys_fit = 10^(130/20)/(s/(2*pi*5.25)+1)*(s/(2*pi*34e6)+1)/(s/(2*pi*55e6)+1)^2;
    
    if ~nargin
        sys_fit_tf = tf_from_sym(sys_fit);
        % Compute magnitude and phase of fitted system
        [mag_fit, phase_fit] = bode(sys_fit_tf, w);
        mag_fit = squeeze(mag_fit);
        phase_fit = squeeze(phase_fit);
        
        mag_fit_db = 20*log10(mag_fit);
        
        % Create figure and axes
        figure;
        
        % Set up axes for background image
        ax = axes;
        hold on;
        
        % Set limits to match your data range
        ax.YDir = 'normal';  % flip y-axis so it's not upside down
        ax.XScale = 'log';   % semilog scale
        
        % Overlay plot on top of image
        yyaxis left
        semilogx(frequency, mag_fit_db, 'r-', 'LineWidth', 1.5); hold on;
        semilogx(frequency(1:length(gain_db)), gain_db, 'b.', 'MarkerSize', 10);
        ylabel('Magnitude (dB)');
        ylim([min(min(mag_fit_db), min(gain_db)) - 5, max(max(mag_fit_db), max(gain_db)) + 5]);    % adjust based on your dB + phase range
        
        yyaxis right
        semilogx(frequency, phase_fit, 'g--', 'LineWidth', 1.5);
        semilogx(frequency(1:length(phase)), phase, 'm.', 'MarkerSize', 10);
        ylabel('Phase (degrees)');
        ylim([min(min(phase_fit), min(phase)) - 10, max(max(phase_fit), max(phase)) + 10]);    % adjust based on your dB + phase range
        
        xlabel('Frequency (Hz)');
        xlim([min(frequency), max(frequency)]);
        
        legend('Fitted Mag', 'Data Mag', 'Fitted Phase', 'Data Phase', 'Location', 'Best');
        grid on;
        figure;
        pzmap(sys_fit_tf)
    end
end