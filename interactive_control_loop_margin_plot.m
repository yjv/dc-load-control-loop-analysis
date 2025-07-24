function interactive_control_loop_margin_plot

    Z_o_p_r = 1e9;
    Z_o_s_r = 5;
    r_g = 0;
    c_g = 0;
    max_I_s = log10(6);

    vds_divisor = 100;
    vgs_divisor = 30;
    max_vds = 60;

    % Create figure
    fig = uifigure('Name', 'Gain & Phase Margin Map', 'Position', [100 100 1000 700]);

    % Axes for gain and phase margin
    ax_gain = uiaxes(fig, 'Position', [50 350 400 300]);
    ax_phase = uiaxes(fig, 'Position', [550 350 400 300]);
    title(ax_gain, 'Gain Margin (dB)'); xlabel(ax_gain, 'V_{GS} (V)'); ylabel(ax_gain, 'V_{DS} (V)');
    title(ax_phase, 'Phase Margin (°)'); xlabel(ax_phase, 'V_{GS} (V)'); ylabel(ax_phase, 'V_{DS} (V)');
    colormap(ax_phase, flipud(colormap(ax_phase)));

    % r_g slider (on top of Vds)
    uilabel(fig, 'Text', 'Z_o_s (H(s))', ...
        'Position', [30 290 70 22]);
    Z_o_s_r_text_box = uieditfield(fig, ...
        'Position', [110 290 390 20], ...
        'Value', '5', ...
        'ValueChangedFcn', @(src, event) updatePlots());

    % r_g slider (on top of Vds)
    uilabel(fig, 'Text', 'Z_o_p (H(s))', ...
        'Position', [30 250 70 22]);
    Z_o_p_r_text_box = uieditfield(fig, ...
        'Position', [110 250 390 20], ...
        'Value', '1e9', ...
        'ValueChangedFcn', @(src, event) updatePlots());

    % c_g slider (on top of R_g)
    uilabel(fig, 'Text', 'C_g', ...
        'Position', [30 210 60 22]);
    cg_slider = uislider(fig, ...
        'Position', [100 220 400 3], ...
        'Limits', [0 10], ...
        'Value', c_g, ...
        'MajorTicks', 0:1:10, ...
        'MajorTickLabels', {'pF', '10', '100', 'nF', '10', '100', 'uF', '10', '100', 'mF'}, ...
        'ValueChangedFcn', @(src, event) updatePlots());

    % r_g slider (on top of Vds)
    uilabel(fig, 'Text', 'R_g', ...
        'Position', [30 170 60 22]);
    rg_slider = uislider(fig, ...
        'Position', [100 180 400 3], ...
        'Limits', [0 6], ...
        'Value', r_g, ...
        'MajorTicks', 0:1:6, ...
        'MajorTickLabels', {'1', '10', '100', '1k', '10k', '100k', '1M'}, ...
        'ValueChangedFcn', @(src, event) updatePlots());
    
    % max_I_s slider (on top of Vds)
    uilabel(fig, 'Text', 'R_g', ...
        'Position', [30 130 60 22]);
    max_I_s_slider = uislider(fig, ...
        'Position', [100 140 400 3], ...
        'Limits', [-3 log10(30)], ...
        'Value', max_I_s, ...
        'MajorTicks', [-3:1:log10(30) log10(30)], ...
        'MajorTickLabels', {'mA', '10', '100', 'A', '10', '30'}, ...
        'ValueChangedFcn', @(src, event) updatePlots());

    % Initial plot
    updatePlots(); 

    function [gain_margin, phase_margin, vds, vgs, id] = compute_margins(r_g, c_g)
        persistent w;
        persistent f;

        if isempty(w)
            f = logspace(1.06, 7, 11000);
            w = 2 * pi * f;
        end

        [~, ~, ~, Y_i, ~, ~, G2, ~, ~, H1, H2, H3, vds, vgs, id] = control_loop(60, 10, Z_o_p_r, Z_o_s_r, r_g, c_g, vds_divisor, vgs_divisor, max_vds);

        Y_i_tf = Y_i();

        G3 = Y_i_tf(:, 1:length(vds));

        H_loop_gain = -H1*H2*H3*G2*G3;

        gain_margin = zeros(size(H_loop_gain));
        phase_margin = zeros(size(H_loop_gain));

        for i = 1:size(H_loop_gain, 1)
            for j = 1:size(H_loop_gain, 2)
                [gain, phase] = bode(H_loop_gain(i, j), w);
                gain_db = 20*log10(squeeze(gain));
                phase = squeeze(phase);
                [gain_margin(i, j), phase_margin(i, j)] = margins_from_loop_gain(gain_db, phase, f);
            end
        end
    end

    % Callback to update plots when R_g changes
    function updatePlots()
                
        r_g = rg_slider.Value;
        c_g = cg_slider.Value;
        max_I_s = 10^max_I_s_slider.Value;
        Z_o_p_r = str2sym(Z_o_p_r_text_box.Value);
        Z_o_s_r = str2sym(Z_o_s_r_text_box.Value);

        if r_g > 0
            r_g = 10^r_g;
        end

        if c_g > 0
            c_g = 10^(c_g - 12);
        end

        % Show progress dialog
        d = uiprogressdlg(fig, ...
        'Title', 'Please Wait', ...
        'Message', 'Computing margins...', ...
        'Indeterminate', 'on');

        drawnow;  % Force UI to update and show dialog

        [gm, pm, vds, vgs, id] = compute_margins(r_g, c_g);

        % Interpolate gm data
        [vds_fine, vgs_fine] = meshgrid(linspace(min(vds), max(vds), vds_divisor/2*length(vds)), ...
                                        linspace(min(vgs), max(vgs), vgs_divisor/2*length(vgs)));
        gm_fine = interp2(vds, vgs, gm, vds_fine, vgs_fine, 'spline');
        pm_fine = interp2(vds, vgs, pm, vds_fine, vgs_fine, 'spline');
        id_fine = interp2(vds, vgs, id, vds_fine, vgs_fine, 'spline');

        % Find points where Z is in the specified range
        max_I_s_indices = (id_fine >= max_I_s - .1) & (id_fine <= max_I_s + .1);

        % Plot gain margin
        surf(ax_gain, vgs_fine(:, 1), vds_fine(1, :), gm_fine');
        view(ax_gain, 2); shading(ax_gain, 'interp'); colorbar(ax_gain);
        title(ax_gain, sprintf('Gain Margin (R_g = %.0f Ω, C_g = %.0fpF)', r_g, c_g * 1e12));

        hold(ax_gain, 'on');
        % Gain margin = 0 dB
        [~, h_gm0] = contour3(ax_gain, vgs_fine(:, 1), vds_fine(1, :), gm_fine', [0, 0], 'r-', 'LineWidth', 2);
        % Gain margin = -6 dB
        [~, h_gm6] = contour3(ax_gain, vgs_fine(:, 1), vds_fine(1, :), gm_fine', [-6, -6], 'r--', 'LineWidth', 2);
        % Max I_s
        h_mad_I_s = plot3(ax_gain, vgs_fine(max_I_s_indices), vds_fine(max_I_s_indices), id_fine(max_I_s_indices)' + 2000, 'm--', 'MarkerSize', 40);
        legend(ax_gain, [h_gm0, h_gm6 h_mad_I_s], {'Gain Margin = 0 dB (Marginally Stable)', 'Gain Margin = -6 dB (Stable)', sprintf('Max I_s = %.2fA', max_I_s)}, 'Location', 'southoutside');
        hold(ax_gain, 'off');

        % Plot phase margin
        surf(ax_phase, vgs_fine(:, 1), vds_fine(1, :), pm_fine');
        view(ax_phase, 2); shading(ax_phase, 'interp'); colorbar(ax_phase);
        title(ax_phase, sprintf('Phase Margin (R_g = %.0f Ω, C_g = %.0fpF)', r_g, c_g * 1e12));

        hold(ax_phase, 'on');
        % Phase margin = 0 deg
        [~, h_pm0] = contour3(ax_phase, vgs_fine(:, 1), vds_fine(1, :), pm_fine', [0 0], 'r-', 'LineWidth', 2);
        % Phase margin = 40 deg
        [~, h_pm40] = contour3(ax_phase, vgs_fine(:, 1), vds_fine(1, :), pm_fine', [40 40], 'r--', 'LineWidth', 2);
        % % Max I_s
        h_mad_I_s = plot3(ax_phase, vgs_fine(max_I_s_indices), vds_fine(max_I_s_indices), id_fine(max_I_s_indices)' + 2000, 'm--', 'MarkerSize', 40);
        % [~, h_mad_I_s] = contour3(ax_phase, vgs_fine(:, 1), vds_fine(1, :), id_fine', [max_I_s - .1, 1e9], 'w--', 'LineWidth', 2);
        legend(ax_phase, [h_pm0, h_pm40, h_mad_I_s], {'Phase Margin = 0° (Marginally Stable)', 'Phase Margin = 40° (Stable)', sprintf('Max I_s = %.2fA', max_I_s)}, 'Location', 'southoutside');
        hold(ax_phase, 'off');

        % Close progress dialog
        close(d);
    end
end
