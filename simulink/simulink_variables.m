function [vds, vgs, id, capacitances, capacitance_vds, G1, G2, G3, G4, H1, H2, H3, Y_iss_g, Y_oss_g, Y_rss_g, Y_iss_d, Y_oss_d, Y_rss_d, G_g, G_d, G_s] = simulink_variables(Z_i_s, Z_o_p, Z_o_s, r_g, c_g, vds_divisor, vgs_divisor, max_vds, vds_dc, vgs_dc)
[~, ~, ~, ~, vds, vgs, id, capacitance_vds, capacitances, Y_iss_g, Y_oss_g, Y_rss_g, Y_iss_d, Y_oss_d, Y_rss_d, G_g, G_d, G_s] = fet_large_signal(Z_i_s, Z_o_p, Z_o_s, r_g, c_g, vds_divisor, vgs_divisor, max_vds);
[~, ~, ~, ~, ~, G1, G2, G3, G4, H1, H2, H3, ~, ~, ~] = control_loop(vds_dc, vgs_dc, Z_o_p, Z_o_s, r_g, c_g, 1, 1, max_vds);
end