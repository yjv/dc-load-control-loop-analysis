function interactive_control_loop()
    % Initial values
    vds_dc = 60;
    vgs_dc = 10;
    Z_o_p_r = 1e9;    % Ohms
    Z_o_s_r = 5;     % Ohms
    r_g = 0;
    c_g = 0;
    f = logspace(1.06, 7, 11000);
    w = 2 * pi * f;

    % UI figure
    f_ui = uifigure('Name', 'Control Loop Bode Plots', 'Position', [100 100 1040 630]);
    f_pz = figure;
    title('H_lim Pole Zero');
    f_rl = figure;
    title('H_lim Root Locus');
    f_step_response = figure;
    title('H Step Response');

    % Axes for Bode plot
    % Axes for H
    ax1 = uiaxes(f_ui, 'Position', [50 350 460 250]);
    title(ax1, 'H Bode Plot');

    % Axes for H_transient
    ax2 = uiaxes(f_ui, 'Position', [530 350 460 250]);
    title(ax2, 'H_{transient} Bode Plot');

    % Axes for H_loop_gain
    ax3 = uiaxes(f_ui, 'Position', [530 40 460 280]);
    title(ax3, 'H_{loop gain} Bode Plot');

    % r_g slider (on top of Vds)
    uilabel(f_ui, 'Text', 'Z_o_s (H(s))', ...
        'Position', [30 290 70 22]);
    Z_o_s_r_text_box = uieditfield(f_ui, ...
        'Position', [110 290 390 20], ...
        'Value', '5', ...
        'ValueChangedFcn', @(src, event) updatePlot());

    % r_g slider (on top of Vds)
    uilabel(f_ui, 'Text', 'Z_o_p (H(s))', ...
        'Position', [30 250 70 22]);
    Z_o_p_r_text_box = uieditfield(f_ui, ...
        'Position', [110 250 390 20], ...
        'Value', '1e9', ...
        'ValueChangedFcn', @(src, event) updatePlot());

    % c_g slider (on top of R_g)
    uilabel(f_ui, 'Text', 'C_g', ...
        'Position', [30 210 60 22]);
    cg_slider = uislider(f_ui, ...
        'Position', [100 220 400 3], ...
        'Limits', [0 10], ...
        'Value', c_g, ...
        'MajorTicks', 0:1:10, ...
        'MajorTickLabels', {'pF', '10', '100', 'nF', '10', '100', 'uF', '10', '100', 'mF'}, ...
        'ValueChangedFcn', @(src, event) updatePlot());

    % r_g slider (on top of Vds)
    uilabel(f_ui, 'Text', 'R_g', ...
        'Position', [30 170 60 22]);
    rg_slider = uislider(f_ui, ...
        'Position', [100 180 400 3], ...
        'Limits', [0 7], ...
        'Value', r_g, ...
        'MajorTicks', 0:1:7, ...
        'MajorTickLabels', {'1', '10', '100', '1k', '10k', '100k', '1M', '10M'}, ...
        'ValueChangedFcn', @(src, event) updatePlot());

    % Vds slider (on top of Vgs)
    uilabel(f_ui, 'Text', 'Vds (DC)', ...
        'Position', [30 130 60 22]);
    vds_slider = uislider(f_ui, ...
        'Position', [100 140 400 3], ...
        'Limits', [0.1 60.0], ...
        'Value', vds_dc, ...
        'ValueChangedFcn', @(src, event) updatePlot());
    
    % Vgs slider (just below Vds)
    uilabel(f_ui, 'Text', 'Vgs (DC)', ...
        'Position', [30 90 60 22]);
    vgs_slider = uislider(f_ui, ...
        'Position', [100 100 400 3], ...
        'Limits', [2.0 22.0], ...
        'Value', vgs_dc, ...
        'ValueChangedFcn', @(src, event) updatePlot());

    % Initial plot
    updatePlot();

    function updatePlot()
        vds_dc = vds_slider.Value;
        vgs_dc = vgs_slider.Value;
        r_g = rg_slider.Value;
        c_g = cg_slider.Value;
        Z_o_p_r = str2sym(Z_o_p_r_text_box.Value);
        Z_o_s_r = str2sym(Z_o_s_r_text_box.Value);

        if r_g > 0
            r_g = 10^r_g;
        end

        if c_g > 0
            c_g = 10^(c_g - 12); %Pf
        end

        [H, H_transient, H_loop_gain, ~, ~, ~, ~, ~, ~, ~, ~, ~, vds, vgs, id] = control_loop(vds_dc, vgs_dc, Z_o_p_r, Z_o_s_r, r_g, c_g, 1, 1, 800);

        pzmap(H);

        % Evaluate freq response
        [mag_H, phase_H] = bode(H, w);
        [mag_H_transient, phase_H_transient] = bode(H_transient, w);
        [mag_H_loop_gain, phase_H_loop_gain] = bode(H_loop_gain, w);

        mag_H = 20*log10(squeeze(mag_H));
        phase_H = squeeze(phase_H);
        mag_H_transient = 20*log10(squeeze(mag_H_transient));
        phase_H_transient = squeeze(phase_H_transient);
        mag_H_loop_gain = 20*log10(squeeze(mag_H_loop_gain));
        phase_H_loop_gain = squeeze(phase_H_loop_gain);

        [gain_margin, phase_margin, f_gain0, f_phase_neg180, f_gain20, f_gainn20] = margins_from_loop_gain(mag_H_loop_gain, phase_H_loop_gain, f);

        H_lim = limit_tf_to_frequencies(H, f_gain20, f_gainn20)

        if phase_margin < 0 || gain_margin > 0
            stability = 'unstable';
        elseif phase_margin < 40 || gain_margin > -6
            stability = 'marginally stable';
        else
            stability = 'stable';
        end

        id_dc = interp2(vds, vgs, id, vds_dc, vgs_dc);

        % Plot H
        cla(ax1); yyaxis(ax1, 'left');
        semilogx(ax1, f, mag_H, 'b', 'LineWidth', 1.5); ylabel(ax1, '|H| (dB)');
        yyaxis(ax1, 'right');
        semilogx(ax1, f, phase_H, 'r--', 'LineWidth', 1.5); ylabel(ax1, '∠H (°)');
        xlabel(ax1, 'Frequency (Hz)'); grid(ax1, 'on');
        title(ax1, sprintf('H: Vds=%.2fV, Vgs=%.2fV, I_s=%.2fA, R_g=%.2f\\Omega, C_g=%.2fpF', ...
            vds_dc, vgs_dc, id_dc, r_g, c_g*1e12));

        % Plot H_transient
        cla(ax2); yyaxis(ax2, 'left');
        semilogx(ax2, f, mag_H_transient, 'b', 'LineWidth', 1.5); ylabel(ax2, '|H_{transient}| (dB)');
        yyaxis(ax2, 'right');
        semilogx(ax2, f, phase_H_transient, 'r--', 'LineWidth', 1.5); ylabel(ax2, '∠H_{transient} (°)');
        xlabel(ax2, 'Frequency (Hz)'); grid(ax2, 'on');
        title(ax2, sprintf('H_{transient}: Vds=%.2fV, Vgs=%.2fV, I_s=%.2fA, R_g=%.2f\\Omega, C_g=%.2fpF', ...
            vds_dc, vgs_dc, id_dc, r_g, c_g*1e12));

        % Plot H_loop_gain
        cla(ax3); yyaxis(ax3, 'left');
        semilogx(ax3, f, mag_H_loop_gain, 'b', 'LineWidth', 1.5); ylabel(ax3, '|H_{loop gain}| (dB)');

        % Add vertical line for 0 dB crossing
        xline(ax3, f_gain0, '--k', '0 dB', 'LabelHorizontalAlignment', 'left');
        
        yyaxis(ax3, 'right');
        semilogx(ax3, f, phase_H_loop_gain, 'r--', 'LineWidth', 1.5); ylabel(ax3, '∠H_{loop gain} (°)');

        % Add vertical lines for ±180° phase
        xline(ax3, f_phase_neg180, '--r', '-180°', 'LabelHorizontalAlignment', 'left');

        xlabel(ax3, 'Frequency (Hz)'); grid(ax3, 'on');
        title(ax3, sprintf('H_{loop gain}: Vds=%.2fV, Vgs=%.2fV, R_g=%.2f\\Omega\nMargins: %.2fdB %.2f° (%s)\n0 dB %.2f Hz, -180° %.2f Hz', ...
            vds_dc, vgs_dc, r_g, gain_margin, phase_margin, stability, f_gain0, f_phase_neg180));

        figure(f_rl);
        rlocus(H_lim);
        figure(f_pz);
        pzmap(H_lim);
        figure(f_step_response);
        sp = stepplot(H_lim);
        sp.Characteristics.PeakResponse.Visible = 'on';
        sp.Characteristics.RiseTime.Visible = 'on';
        sp.Characteristics.SettlingTime.Visible = 'on';
        sp.Characteristics.SteadyState.Visible = 'on';
    end
end
