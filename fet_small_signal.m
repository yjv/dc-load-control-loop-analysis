function [Y_i, Y_o, Y_i_sym, Y_o_sym, I, I_sol, V_sol, g_m_r, r_o_r, C_iss_r, C_oss_r, C_rss_r, vds, vgs, id] = fet_small_signal(Z_i_s_r, Z_o_p_r, Z_o_s_r, r_g, c_g, vds_divisor, vgs_divisor, max_vds)
    C_ds = sym('C_ds');
    C_gd = sym('C_gd');
    C_gs = sym('C_gs');
    g_m = sym('g_m');
    r_o = sym('r_o');
    C_iss = sym('C_iss');
    C_oss = sym('C_oss');
    C_rss = sym('C_rss');
    V_gs = sym('V_gs');
    V_ds = sym('V_ds');
    s = sym('s');
    V_o = sym('V_o');
    V_i = sym('V_i');
    Z_o_s = sym('Z_o_s');
    Z_i_s = sym('Z_i_s');

    if isempty(vds_divisor)
        vds_divisor = 1;
    end

    if isempty(vgs_divisor)
        vgs_divisor = 1;
    end

    if isempty(max_vds)
        max_vds = 800;
    end

    I_C_gs=V_gs*s*C_gs;
    I_C_gd=(V_gs-V_ds)*s*C_gd;
    I_r_o=V_ds/r_o;
    I_C_ds=V_ds*s*C_ds;

    % currents in terms of small signal capacitances and small signal gm
    % and r_o
    I=collect([ ...
        g_m*V_gs+I_r_o+I_C_ds-I_C_gd %I_d
        I_C_gs+g_m*V_gs+I_r_o+I_C_ds %I_s
        I_C_gd+I_C_gs                %I_g
    ], [V_gs, V_ds]);

    % replace small signal capacitances with datasheet capacitances
    I = subs(I, [C_ds, C_gs, C_gd], [C_oss-C_rss (C_iss-C_rss + c_g) C_rss]);

    V_ds_eq = V_ds == V_o - Z_o_s * I(1);
    V_gs_eq = V_gs == V_i - Z_i_s * I(3);

    % solve for V_ds and V_gs in terms of voltages on the sources coming
    % into the drain and gate
    [V_ds_sol, V_gs_sol] = solve([V_ds_eq V_gs_eq], [V_ds V_gs]);
    V_sol = struct('V_ds', collect(V_ds_sol, [V_i, V_o]), 'V_gs', collect(V_gs_sol, [V_i, V_o]));

    I_sol = collect(simplify(subs(I, [V_ds V_gs], [V_sol.V_ds V_sol.V_gs])), [V_i, V_o]);

    I = struct( ...
        'I_d', I(1),...
        'I_s', I(2),...
        'I_g', I(3)...
    );

    I_sol = struct( ...
        'I_d', I_sol(1),...
        'I_s', I_sol(2),...
        'I_g', I_sol(3)...
    );

    Y_i_sym = subs(I_sol.I_s, [V_o V_i], [0 1]);
    Y_o_sym = subs(I_sol.I_s, [V_o V_i], [1 0]);

    [g_m_r, r_o_r, vds, vgs, id] = drain_curves(vds_divisor, vgs_divisor, max_vds);

    [C_iss_r, C_oss_r, C_rss_r] = fet_capacitances(vds);

    C_iss_r = repmat(C_iss_r, length(vgs), 1);
    C_oss_r = repmat(C_oss_r, length(vgs), 1);
    C_rss_r = repmat(C_rss_r, length(vgs), 1);

    function coeff_funs = generate_coeff_funs(coeffs)
        coeff_funs = cell(length(coeffs));
       
        persistent count;

        if isempty(count)
            count = 0;
        end

        for i = 1:length(coeffs)
            count = count + 1;
            coeff = coeffs(i);
            coeff_fun = matlabFunction(coeff, 'Vars', [g_m r_o C_iss C_oss C_rss]);
            coeff_fun  = @() coeff_fun(g_m_r, r_o_r, C_iss_r, C_oss_r, C_rss_r);
            coeff_funs{i} = coeff_fun;

        end
    end

    function coeffs = generate_coeffs(num_coeff_funs, den_coeff_funs, vds_dc, vgs_dc)

        zero_fill = zeros(size(r_o_r));
        
        for i = 1:length(num_coeff_funs)
            num_coeff_fun = num_coeff_funs{i};
            num_coeff = num_coeff_fun();
            den_coeff_fun = den_coeff_funs{i};
            den_coeff = den_coeff_fun();

            if num_coeff == 0
                num_coeff = zero_fill;
            end

            if den_coeff == 0
                den_coeff = zero_fill;
            end

            if nargin == 4
                num_coeff = interp2(vds, vgs, num_coeff, vds_dc, vgs_dc);
                den_coeff = interp2(vds, vgs, den_coeff, vds_dc, vgs_dc);
            end

            if i == 1
                coeffs = cellfun(@(num, den) [num; den], num2cell(num_coeff), num2cell(den_coeff), 'UniformOutput', false);
            elseif i == length(num_coeff_funs)
                coeffs = cellfun(@(l, num, den) normalize_tf_from_numden([l(1, :) num], [l(2, :) den]), coeffs, num2cell(num_coeff), num2cell(den_coeff), 'UniformOutput', false);
            else
                coeffs = cellfun(@(l, num, den) [l(1, :) num; l(2, :) den], coeffs, num2cell(num_coeff), num2cell(den_coeff), 'UniformOutput', false);
            end
        end

        coeffs = cell2mat(coeffs);
    end

    Y_i_sub = subs(Y_i_sym, [Z_i_s r_o Z_o_s], [(Z_i_s_r + r_g) 1/(1/Z_o_p_r + 1/r_o) Z_o_s_r]);
    Y_o_sub = subs(Y_o_sym, [Z_i_s r_o Z_o_s], [(Z_i_s_r + r_g) 1/(1/Z_o_p_r + 1/r_o) Z_o_s_r]);

    [Y_i_num, Y_i_den] = numden(Y_i_sub);
    Y_i_num_coeffs = coeffs(Y_i_num, s, 'All');
    Y_i_den_coeffs = coeffs(Y_i_den, s, 'All');
    max_coeffs = max([length(Y_i_num_coeffs) length(Y_i_den_coeffs)]);

    Y_i_num_coeffs = [zeros(1, max_coeffs - length(Y_i_num_coeffs)) Y_i_num_coeffs];
    Y_i_den_coeffs = [zeros(1, max_coeffs - length(Y_i_den_coeffs)) Y_i_den_coeffs];
    Y_i_num_coeff_funs = generate_coeff_funs(Y_i_num_coeffs);
    Y_i_den_coeff_funs = generate_coeff_funs(Y_i_den_coeffs);
    Y_i = @(varargin) generate_coeffs(Y_i_num_coeff_funs, Y_i_den_coeff_funs, varargin{:});
    [Y_o_num, Y_o_den] = numden(Y_o_sub);
    Y_o_num_coeff_funs = generate_coeff_funs(coeffs(Y_o_num, s, 'All'));
    Y_o_den_coeff_funs = generate_coeff_funs(coeffs(Y_o_den, s, 'All'));
    Y_o = @(varargin) generate_coeffs(Y_o_num_coeff_funs, Y_o_den_coeff_funs, varargin{:});
end