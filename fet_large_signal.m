function [V_sol, I_sol, I_full_sol, V_full_sol, vds, vgs, id, capacitance_vds, capacitances, Y_iss_g, Y_oss_g, Y_rss_g, Y_iss_d, Y_oss_d, Y_rss_d, G_g, G_d, G_s] = fet_large_signal(Z_i_s_r, Z_o_p_r, Z_o_s_r, r_g, c_g, vds_divisor, vgs_divisor, max_vds)
    C_ds = sym('C_ds');
    C_gd = sym('C_gd');
    C_gs = sym('C_gs');
    C_iss = sym('C_iss');
    C_oss = sym('C_oss');
    C_rss = sym('C_rss');
    V_gs = sym('V_gs');
    V_ds = sym('V_ds');
    I_dd = sym('I_dd');
    s = sym('s');
    V_o = sym('V_o');
    V_i = sym('V_i');
    Z_o_s = sym('Z_o_s');
    Z_o_p = sym('Z_o_p');
    Z_i_s = sym('Z_i_s');

    I_C_gs=V_gs*s*C_gs;
    I_C_gd=(V_gs-V_ds)*s*C_gd;
    I_C_ds=V_ds*s*C_ds;
    I_Z_o_p=V_ds/Z_o_p;

    I_sol = struct( ...
        'I_d', I_dd+I_Z_o_p+I_C_ds-I_C_gd, ...
        'I_s', I_C_gs+I_dd+I_Z_o_p+I_C_ds, ...
        'I_g', I_C_gd+I_C_gs ...
    );

    % replace small signal capacitances with datasheet capacitances
    I_sol = subs(I_sol, [C_ds, C_gs, C_gd], [C_oss-C_rss (C_iss-C_rss + c_g) C_rss]);
    I_sol=structfun(@(field) collect(field, [V_gs, V_ds, I_dd]), I_sol, 'UniformOutput', false);

    V_ds_eq = V_ds == V_o - Z_o_s * I_sol.I_d;
    V_gs_eq = V_gs == V_i - Z_i_s * I_sol.I_g;

    % solve for V_ds and V_gs in terms of voltages on the sources coming
    % into the drain and gate
    V_sol = solve([V_ds_eq V_gs_eq], [V_ds V_gs]);
    V_sol = structfun(@(field) collect(field, [V_i, V_o, I_dd]), V_sol, 'UniformOutput', false);

    I_full_sol = subs(I_sol, [Z_i_s Z_o_p Z_o_s], [(Z_i_s_r + r_g) Z_o_p_r Z_o_s_r]);
    V_full_sol = subs(V_sol, [Z_i_s Z_o_p Z_o_s], [(Z_i_s_r + r_g) Z_o_p_r Z_o_s_r]);

    [~, ~, vds, vgs, id] = drain_curves(vds_divisor, vgs_divisor, max_vds);
    [~, ~, ~, capacitance_vds, capacitances] = fet_capacitances(vds);

    Y_iss_g = subs(V_full_sol.V_gs, [V_i V_o I_dd], [1 0 0]);
    Y_oss_g = subs(V_full_sol.V_gs, [V_i V_o I_dd], [0 1 0]);
    Y_rss_g = subs(V_full_sol.V_gs, [V_i V_o I_dd], [0 0 1]);
    Y_iss_d = subs(V_full_sol.V_ds, [V_i V_o I_dd], [1 0 0]);
    Y_oss_d = subs(V_full_sol.V_ds, [V_i V_o I_dd], [0 1 0]);
    Y_rss_d = subs(V_full_sol.V_ds, [V_i V_o I_dd], [0 0 1]);
    G_g = subs(I_full_sol.I_s, [V_gs V_ds I_dd], [1 0 0]);
    G_d = subs(I_full_sol.I_s, [V_gs V_ds I_dd], [0 1 0]);
    G_s = subs(I_full_sol.I_s, [V_gs V_ds I_dd], [0 0 1]);
end