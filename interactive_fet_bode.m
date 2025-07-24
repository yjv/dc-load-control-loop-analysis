function interactive_fet_bode()
    % Initial values
    vds_dc = 60;
    vgs_dc = 10;
    Z_i_s_r = 5;    % Ohms
    Z_o_p_r = 1e9;    % Ohms
    Z_o_s_r = 5;     % Ohms
    f = logspace(-1, 9, 110);
    w = 2 * pi * f;

    % UI figure
    f_ui = uifigure('Name', 'FET Bode Plots', 'Position', [100 100 1000 750]);

    % Axes for Bode plot
    % Axes for Y_i
    ax1 = uiaxes(f_ui, 'Position', [50 430 900 250]);
    title(ax1, 'Y_i Bode Plot');

    % Axes for Y_o
    ax2 = uiaxes(f_ui, 'Position', [50 130 900 250]);
    title(ax2, 'Y_o Bode Plot');

    % Vds slider (on top of Vgs)
    uilabel(f_ui, 'Text', 'Vds (DC)', ...
        'Position', [100 80 60 22]);
    vds_slider = uislider(f_ui, ...
        'Position', [170 90 600 3], ...
        'Limits', [0.1 800.0], ...
        'Value', vds_dc, ...
        'ValueChangedFcn', @(src, event) updatePlot());
    
    % Vgs slider (just below Vds)
    uilabel(f_ui, 'Text', 'Vgs (DC)', ...
        'Position', [100 40 60 22]);
    vgs_slider = uislider(f_ui, ...
        'Position', [170 50 600 3], ...
        'Limits', [2.0 22.0], ...
        'Value', vgs_dc, ...
        'ValueChangedFcn', @(src, event) updatePlot());

    % Initial plot
    updatePlot();

    function updatePlot()
        vds_dc = vds_slider.Value;
        vgs_dc = vgs_slider.Value;

        [Y_i, Y_o] = fet_small_signal(vds_dc, vgs_dc, Z_i_s_r, Z_o_p_r, Z_o_s_r);

        H_i = tf_from_sym(Y_i);
        H_o = tf_from_sym(Y_o);

        % Evaluate freq response
        [mag_i, phase_i] = bode(H_i, w);
        [mag_o, phase_o] = bode(H_o, w);

        mag_i = 20*log10(squeeze(mag_i));
        phase_i = squeeze(phase_i);
        mag_o = 20*log10(squeeze(mag_o));
        phase_o = squeeze(phase_o);

        % Extract poles and zeros for Y_i
        poles_i = pole(H_i);
        zeros_i = zero(H_i);
        poles_str_i = sprintf('%.2e ', poles_i);
        zeros_str_i = sprintf('%.2e ', zeros_i);
        
        % Extract poles and zeros for Y_o
        poles_o = pole(H_o);
        zeros_o = zero(H_o);
        poles_str_o = sprintf('%.2e ', poles_o);
        zeros_str_o = sprintf('%.2e ', zeros_o);

        % Plot Y_i
        cla(ax1); yyaxis(ax1, 'left');
        semilogx(ax1, f, mag_i, 'b', 'LineWidth', 1.5); ylabel(ax1, '|Y_i| (dB)');
        yyaxis(ax1, 'right');
        semilogx(ax1, f, phase_i, 'r--', 'LineWidth', 1.5); ylabel(ax1, '∠Y_i (deg)');
        xlabel(ax1, 'Frequency (Hz)'); grid(ax1, 'on');
        title(ax1, sprintf('Y_i: Vds=%.2f V, Vgs=%.2f V\nPoles: [%s]\nZeros: [%s]', ...
            vds_dc, vgs_dc, poles_str_i, zeros_str_i));

        % Plot Y_o
        cla(ax2); yyaxis(ax2, 'left');
        semilogx(ax2, f, mag_o, 'b', 'LineWidth', 1.5); ylabel(ax2, '|Y_o| (dB)');
        yyaxis(ax2, 'right');
        semilogx(ax2, f, phase_o, 'r--', 'LineWidth', 1.5); ylabel(ax2, '∠Y_o (deg)');
        xlabel(ax2, 'Frequency (Hz)'); grid(ax2, 'on');
        title(ax2, sprintf('Y_o: Vds=%.2f V, Vgs=%.2f V\nPoles: [%s]\nZeros: [%s]', ...
            vds_dc, vgs_dc, poles_str_o, zeros_str_o));

    end
end
