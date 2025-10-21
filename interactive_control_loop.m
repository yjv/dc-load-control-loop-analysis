function interactive_control_loop(vds_dc, vgs_dc, Z_o_p_r, Z_o_s_r, r_g, c_g)
% Interactive_control_loop Interactive Bode plot analysis for specific control loop
%
% This function provides an interactive user interface for analyzing the 
% stability and frequency response of the specific control loop consisting of:
% - OPA210 operational amplifier
% - INA296 current sense amplifier  
% - MAX5719GSD+ DAC
% - MSC017SMA120B4N MOSFET
% - 0.0047Ω current sense resistor
% It allows real-time adjustment of key parameters and visualizes the effects 
% on system stability margins.
%
% USAGE:
%   interactive_control_loop()                    % Use default parameters
%   interactive_control_loop(vds_dc, vgs_dc, ...) % Specify initial parameters
%
% INPUTS:
%   vds_dc   - MSC017SMA120B4N drain-source DC voltage (V) [default: 60V]
%   vgs_dc   - MSC017SMA120B4N gate-source DC voltage (V) [default: 10V] 
%   Z_o_p_r  - Parallel source impedance at FET output (Ω) [default: 1e9Ω]
%   Z_o_s_r  - Series source impedance at FET output (Ω) [default: 5Ω]
%   r_g      - Additional gate resistance (external to FET) (Ω) [default: 0Ω]
%   c_g      - Additional gate capacitance (external to FET) (F) [default: 0F]
%
% FEATURES:
%   - Interactive sliders for real-time parameter adjustment
%   - Bode plots for set-point gain, transient response, and loop gain transfer functions
%   - Stability margin analysis with gain and phase margin calculations
%   - Root locus and pole-zero plots for detailed stability analysis
%   - Step response characteristics (peak, rise time, settling time)
%
% OUTPUTS:
%   The function creates multiple figure windows:
%   - Main UI with Bode plots and interactive controls
%   - Root locus plot for H_lim transfer function
%   - Pole-zero map for H_lim transfer function  
%   - Step response plot with performance metrics
%
% DEPENDENCIES:
%   - control_loop.m - Main control loop analysis function (OPA210+INA296+MAX5719GSD++MSC017SMA120B4N+0.0047Ω current sense resistor)
%   - margins_from_loop_gain.m - Stability margin calculations
%   - Component models: derive_opa210_*, derive_ina296_*, fet_small_signal.m
%
% EXAMPLE:
%   % Start with default parameters
%   interactive_control_loop();
%
%   % Start with specific operating point
%   interactive_control_loop(50, 12, 1e6, 10, 100, 100e-12);
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0

    % Default parameter initialization
    if ~nargin
        % Initial values - typical operating point for MOSFET control loop
        vds_dc = 60;        % Drain-source voltage (V)
        vgs_dc = 10;        % Gate-source voltage (V)
        Z_o_p_r = 1e9;      % Parallel source impedance at FET output (Ω)
        Z_o_s_r = 5;        % Series source impedance at FET output (Ω)
        r_g = 0;            % Gate resistance (Ω) - no external gate resistance
        c_g = 0;            % Gate capacitance (F) - no external gate capacitance
    end
    
    % Frequency range for analysis (10 Hz to 10 MHz with 11000 points)
    f = logspace(1.06, 7, 11000);
    w = 2 * pi * f;

    % Create main UI figure and analysis windows
    f_ui = uifigure('Name', 'Control Loop Bode Plots', 'Position', [100 100 1040 630]);
    
    % Create separate figures for detailed analysis
    f_pz = figure;
    title('H_lim Pole Zero');
    f_rl = figure;
    title('H_lim Root Locus');
    f_step_response = figure;
    title('H Step Response');

    % Create UI axes for Bode plots
    % Set-point gain transfer function (response to control voltage changes)
    ax1 = uiaxes(f_ui, 'Position', [50 350 460 250]);
    title(ax1, 'H Bode Plot');

    % Transient response transfer function (response to DUT source changes)
    ax2 = uiaxes(f_ui, 'Position', [530 350 460 250]);
    title(ax2, 'H_{transient} Bode Plot');

    % Loop gain transfer function (G2*G3*H1*H2*H3 for stability analysis)
    ax3 = uiaxes(f_ui, 'Position', [530 40 460 280]);
    title(ax3, 'H_{loop gain} Bode Plot');

    % UI Controls for parameter adjustment
    % Series source impedance at FET output
    uilabel(f_ui, 'Text', 'Z_o_s (H(s))', ...
        'Position', [30 290 70 22]);
    Z_o_s_r_text_box = uieditfield(f_ui, ...
        'Position', [110 290 390 20], ...
        'Value', '5', ...
        'ValueChangedFcn', @(src, event) updatePlot());

    % Parallel source impedance at FET output
    uilabel(f_ui, 'Text', 'Z_o_p (H(s))', ...
        'Position', [30 250 70 22]);
    Z_o_p_r_text_box = uieditfield(f_ui, ...
        'Position', [110 250 390 20], ...
        'Value', '1e9', ...
        'ValueChangedFcn', @(src, event) updatePlot());

    % Gate capacitance C_g slider (external gate capacitance)
    uilabel(f_ui, 'Text', 'C_g', ...
        'Position', [30 210 60 22]);
    cg_value_label = uilabel(f_ui, 'Position', [55 210 55 22], 'Text', sprintf("= %s", c_g));
    cg_slider = uislider(f_ui, ...
        'Position', [140 220 360 3], ...
        'Limits', [0 10], ...
        'Value', c_g, ...
        'MajorTicks', 0:1:10, ...
        'MajorTickLabels', {'pF', '10', '100', 'nF', '10', '100', 'uF', '10', '100', 'mF'}, ...
        'ValueChangedFcn', @(src, event) updatePlot(), ...
        'ValueChangingFcn', @(src, event) updateSliderValue(exponentiate(event.Value, -12), 'F', cg_value_label));
    updateSliderValue(exponentiate(cg_slider.Value, -12), 'F', cg_value_label);

    % Gate resistance R_g slider (external gate resistance)
    uilabel(f_ui, 'Text', 'R_g', ...
        'Position', [30 170 60 22]);
    rg_value_label = uilabel(f_ui, 'Position', [55 170 55 22], 'Text', sprintf("= %s", r_g));
    rg_slider = uislider(f_ui, ...
        'Position', [140 180 360 3], ...
        'Limits', [0 7], ...
        'Value', r_g, ...
        'MajorTicks', 0:1:7, ...
        'MajorTickLabels', {'1', '10', '100', '1k', '10k', '100k', '1M', '10M'}, ...
        'ValueChangedFcn', @(src, event) updatePlot(), ...
        'ValueChangingFcn', @(src, event) updateSliderValue(exponentiate(event.Value, 0), 'Ω', rg_value_label));
    updateSliderValue(exponentiate(rg_slider.Value, 0), 'Ω', rg_value_label);

    % Drain-source voltage Vds slider (MOSFET operating point)
    uilabel(f_ui, 'Text', 'Vds (DC)', ...
        'Position', [30 130 60 22]);
    vds_value_label = uilabel(f_ui, 'Position', [80 130 40 22], 'Text', sprintf("= %s", vds_dc));
    vds_slider = uislider(f_ui, ...
        'Position', [140 140 360 3], ...
        'Limits', [0.1 60.0], ...
        'Value', vds_dc, ...
        'ValueChangedFcn', @(src, event) updatePlot(), ...
        'ValueChangingFcn', @(src, event) updateSliderValue(event.Value, 'V', vds_value_label));
    updateSliderValue(vds_slider.Value, 'V', vds_value_label);

    % Gate-source voltage Vgs slider (MOSFET operating point)
    uilabel(f_ui, 'Text', 'Vgs (DC)', ...
        'Position', [30 90 60 22]);
    vgs_value_label = uilabel(f_ui, 'Position', [80 95 40 22], 'Text', sprintf("= %s", vgs_dc));
    vgs_slider = uislider(f_ui, ...
        'Position', [140 100 360 3], ...
        'Limits', [2.0 22.0], ...
        'Value', vgs_dc, ...
        'ValueChangedFcn', @(src, event) updatePlot(), ...
        'ValueChangingFcn', @(src, event) updateSliderValue(event.Value, 'V', vgs_value_label));
    updateSliderValue(vgs_slider.Value, 'V', vgs_value_label)

    % Helper function to update slider value labels with SI metric prefixes (p, n, u, m, k, M, G, T) and scale accordingly
    function updateSliderValue(value, unit, label)
        label.Text = sprintf('= %s', metricScale(value, unit));
    end

    % Helper function to convert slider position to actual value with exponent shift
    % Note: 0 gives the value 0 instead of 1 (special case for zero slider position)
    function [num] = exponentiate(exponent, shift)
        if exponent > 0
            num = 10^(exponent + shift);
        else
            num = 0;
        end
    end

    % Generate initial plots
    updatePlot();

    % Main plot update function - called whenever parameters change
    function updatePlot()
        % Get current parameter values from UI controls
        vds_dc = vds_slider.Value;
        vgs_dc = vgs_slider.Value;
        r_g = exponentiate(rg_slider.Value, 0);
        c_g = exponentiate(cg_slider.Value, -12);
        Z_o_p_r = str2sym(Z_o_p_r_text_box.Value);
        Z_o_s_r = str2sym(Z_o_s_r_text_box.Value);

        % Calculate control loop transfer functions
        [H, H_transient, H_loop_gain, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, vds, vgs, id] = control_loop(vds_dc, vgs_dc, Z_o_p_r, Z_o_s_r, r_g, c_g, 1, 1, 800);

        % Evaluate frequency response of all transfer functions
        [mag_H, phase_H] = bode(H, w);
        [mag_H_transient, phase_H_transient] = bode(H_transient, w);
        [mag_H_loop_gain, phase_H_loop_gain] = bode(H_loop_gain, w);

        % Convert magnitude to dB 
        mag_H = 20*log10(squeeze(mag_H));
        phase_H = squeeze(phase_H);
        mag_H_transient = 20*log10(squeeze(mag_H_transient));
        phase_H_transient = squeeze(phase_H_transient);
        mag_H_loop_gain = 20*log10(squeeze(mag_H_loop_gain));
        phase_H_loop_gain = squeeze(phase_H_loop_gain);

        % Calculate stability margins from loop gain
        [gain_margin, phase_margin, f_gain0, f_phase_neg180, f_gain20, f_gainn20] = margins_from_loop_gain(mag_H_loop_gain, phase_H_loop_gain, f);

        % Create limited transfer function for root locus and pole-zero analysis
        H_lim = limit_tf_to_frequencies(H, f_gain20, f_gainn20);

        % Determine stability classification based on margins
        if phase_margin < 0 || gain_margin > 0
            stability = 'unstable';
        elseif phase_margin < 40 || gain_margin > -6
            stability = 'marginally stable';
        else
            stability = 'stable';
        end

        % Interpolate DC drain current for display
        id_dc = interp2(vds, vgs, id, vds_dc, vgs_dc);

        % Plot set-point gain transfer function (response to control voltage changes)
        cla(ax1); yyaxis(ax1, 'left');
        semilogx(ax1, f, mag_H, 'b', 'LineWidth', 1.5); ylabel(ax1, '|H| (dB)');
        yyaxis(ax1, 'right');
        semilogx(ax1, f, phase_H, 'r--', 'LineWidth', 1.5); ylabel(ax1, '∠H (°)');
        xlabel(ax1, 'Frequency (Hz)'); grid(ax1, 'on');
        title(ax1, sprintf('H: Vds=%.2fV, Vgs=%.2fV, I_s=%.2fA, R_g=%.2f\\Omega, C_g=%.2fpF', ...
            vds_dc, vgs_dc, id_dc, r_g, c_g*1e12));

        % Plot transient response transfer function (response to DUT source changes)
        cla(ax2); yyaxis(ax2, 'left');
        semilogx(ax2, f, mag_H_transient, 'b', 'LineWidth', 1.5); ylabel(ax2, '|H_{transient}| (dB)');
        yyaxis(ax2, 'right');
        semilogx(ax2, f, phase_H_transient, 'r--', 'LineWidth', 1.5); ylabel(ax2, '∠H_{transient} (°)');
        xlabel(ax2, 'Frequency (Hz)'); grid(ax2, 'on');
        title(ax2, sprintf('H_{transient}: Vds=%.2fV, Vgs=%.2fV, I_s=%.2fA, R_g=%.2f\\Omega, C_g=%.2fpF', ...
            vds_dc, vgs_dc, id_dc, r_g, c_g*1e12));

        % Plot loop gain transfer function (G2*G3*H1*H2*H3 for stability analysis)
        cla(ax3); yyaxis(ax3, 'left');
        semilogx(ax3, f, mag_H_loop_gain, 'b', 'LineWidth', 1.5); ylabel(ax3, '|H_{loop gain}| (dB)');

        % Add vertical line for 0 dB crossing (unity gain frequency or gain crossover frequency)
        xline(ax3, f_gain0, '--k', '0 dB', 'LabelHorizontalAlignment', 'left');
        
        yyaxis(ax3, 'right');
        semilogx(ax3, f, phase_H_loop_gain, 'r--', 'LineWidth', 1.5); ylabel(ax3, '∠H_{loop gain} (°)');

        % Add vertical lines for -180° phase crossing (phase crossover frequency)
        xline(ax3, f_phase_neg180, '--r', '-180°', 'LabelHorizontalAlignment', 'left');

        xlabel(ax3, 'Frequency (Hz)'); grid(ax3, 'on');
        title(ax3, sprintf('H_{loop gain}: Vds=%.2fV, Vgs=%.2fV, R_g=%.2f\\Omega\nMargins: %.2fdB %.2f° (%s)\n0 dB %.2f Hz, -180° %.2f Hz', ...
            vds_dc, vgs_dc, r_g, gain_margin, phase_margin, stability, f_gain0, f_phase_neg180));

        % Generate root locus plot for stability analysis
        figure(f_rl);
        rlocus(H_lim);
        
        % Generate pole-zero map 
        figure(f_pz);
        pzmap(H_lim);
        
        % Generate step response with performance metrics
        figure(f_step_response);
        sp = stepplot(H_lim);
        sp.Characteristics.PeakResponse.Visible = 'on';
        sp.Characteristics.RiseTime.Visible = 'on';
        sp.Characteristics.SettlingTime.Visible = 'on';
        sp.Characteristics.SteadyState.Visible = 'on';

    end

    % Helper function to format numbers with SI metric prefixes (p, n, u, m, k, M, G, T)
    function out = metricScale(num, unit)
        % Define SI metric prefixes and their exponents (every 3 powers of 10)
        prefixes = {'p','n','u','m','','k','M','G','T'};
        exponents = -12:3:12; % powers of 10 (pico, nano, micro, milli, base, kilo, mega, giga, tera)
        
        % Handle zero case
        if num == 0
            out = ['0 ', unit];
            return;
        end
        
        % Find nearest exponent of 10^3 matching the number
        exp10 = floor(log10(abs(num))/3)*3;
        % Clamp to supported exponents
        exp10 = max(min(exp10, 12), -12);
        idx = find(exponents==exp10,1);
        % Calculate scaled number
        scaled = num / 10^exp10;
        % Format rounded to 1 decimal place, avoid '.0' for integers
        if abs(scaled-round(scaled))<1e-9
            fmt = '%d %s%s';
        else
            fmt = '%.1f %s%s';
        end
        out = sprintf(fmt, scaled, prefixes{idx}, unit);
    end
end
