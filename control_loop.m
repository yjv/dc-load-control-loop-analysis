function [H, H_transient, H_loop_gain, Y_i, Y_o, G1, G2, G3, G4, H1, H2, H3, vds, vgs, id] = control_loop(vds_dc, vgs_dc, Z_o_p_r, Z_o_s_r, r_g, c_g, vds_divisor, vgs_divisor, max_vds)
    opa210_zo = derive_opa210_zo(0);
    ina296_zo = derive_ina296_zo(0);
    dac_zo = 2e3;
    r_sense = 4.7e-3;
    Z_i_s_r = opa210_zo;
    [G1, H3] = derive_opa210_zi(dac_zo, ina296_zo);
    G2 = derive_opa210_gain(0);
    [Y_i, Y_o, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, vds, vgs, id] = fet_small_signal(Z_i_s_r, Z_o_p_r, Z_o_s_r, r_g, c_g, vds_divisor, vgs_divisor, max_vds);
    Y_i_tf = Y_i(vds_dc, vgs_dc);
    Y_o_tf = Y_o(vds_dc, vgs_dc);
    H1 = r_sense;
    H2 = derive_ina296_gain(0);

    G1 = normalize_tf_from_sym(G1);
    G2 = normalize_tf_from_sym(G2);
    G3 = Y_i_tf;
    G4 = Y_o_tf;
    H1 = tf(H1, 1);
    H2 = normalize_tf_from_sym(H2);
    H3 = normalize_tf_from_sym(H3);
    
    H_loop_gain = normalize_tf(-H1*H2*H3*G2*G3);
    H = normalize_tf(G1*G2*G3)/(1+H_loop_gain);
    H_transient = G4/(1+H_loop_gain);
end