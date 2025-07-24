function [vds, vgs, id, g_m, r_o, capacitances, capacitance_vds, G1, G2, H1, H2, H3] = simulink_variables(Z_i_s_r, Z_o_p_r, Z_o_s_r, r_g_r, max_vds)
[~, ~, ~, ~, I, ~, sol, g_m, r_o, ~, ~, ~, vds, vgs, id] = fet_small_signal(Z_i_s_r, Z_o_p_r, Z_o_s_r, 1, 1, max_vds);
[~, ~, ~, capacitance_vds, capacitances] = fet_capacitances(1);
[~, ~, ~, ~, ~, G1, G2, ~, ~, H1, H2, H3, ~, ~, ~, Z_i_s_r] = control_loop(60, 10, Z_o_p_r, Z_o_s_r, r_g_r, 1, 1, max_vds);

vals = [I(2); sol{1}; sol{2}];

Z_i_s = sym('Z_i_s');
Z_o_s = sym('Z_o_s');
Z_o_p = sym('Z_o_p');

vals = subs(vals, [Z_i_s Z_o_s Z_o_p], [Z_i_s_r Z_o_s_r Z_o_p_r]);
I_s = vals(1);
V_ds_sol = vals(2);
V_gs_sol = vals(3);

function numden_coeffs = numden_coeffs(func)
    s = sym('s');
    
    [num, den] = numden(func);
    num_coeffs = coeffs(num, s);
    den_coeffs = coeffs(den, s);
    numden_coeffs = [num_coeffs den_coeffs];
end

V_gs = sym('V_gs');
V_ds = sym('V_ds');
V_i = sym('V_i');
V_o = sym('V_o');

Y_i = subs(I_s, [V_gs V_ds], [1 0])
Y_o = subs(I_s, [V_gs V_ds], [0 1])
G_v_dsi = subs(V_ds_sol, [V_i V_o], [1 0])
numden_coeffs(G_v_dsi)
G_v_dso = subs(V_ds_sol, [V_i V_o], [1 0])
G_v_gsi = subs(V_gs_sol, [V_i V_o], [1 0])
G_v_gso = subs(V_gs_sol, [V_i V_o], [1 0])
end