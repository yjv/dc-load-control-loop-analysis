function [H, H_transient, H_loop_gain, Y_i, Y_o, G1, G2, G3, G4, G5, H1, H2, H3, vds, vgs, id] = control_loop(vds_dc, vgs_dc, Z_o_p_r, Z_o_s_r, r_g, c_g, vds_divisor, vgs_divisor, max_vds)
% Control_loop Calculate transfer functions for specific control loop analysis
%
% This function calculates the transfer functions for the control loop consisting 
% of OPA210 + INA296 + MAX5719GSD+ + MSC017SMA120B4N + 0.0047Ω current sense resistor. 
% It returns transfer functions for the control loop input, output transient response, and loop gain for stability analysis.
%
% USAGE:
%   [H, H_transient, H_loop_gain, ...] = control_loop(vds_dc, vgs_dc, ...)
%
% INPUTS:
%   vds_dc      - MSC017SMA120B4N drain-source DC voltage (V)
%   vgs_dc      - MSC017SMA120B4N gate-source DC voltage (V)
%   Z_o_p_r     - Parallel source impedance at FET output (Ω)
%   Z_o_s_r     - Series source impedance at FET output (Ω)
%   r_g         - Additional gate resistance (external to FET) (Ω)
%   c_g         - Additional gate capacitance (external to FET) (F)
%   vds_divisor - Vds resolution divisor (balances precision vs calculation speed)
%   vgs_divisor - Vgs resolution divisor (balances precision vs calculation speed)
%   max_vds     - Maximum Vds for analysis (V)
%
% OUTPUTS:
%   H           - Control loop transfer function (set-point gain)
%   H_transient - Transient response transfer function (DUT source changes)
%   H_loop_gain - Loop gain transfer function (G2*G3*H1*H2*H3)
%   Y_i         - Callable function that returns MOSFET input transconductance transfer function for given DC operating points
%   Y_o         - Callable function that returns MOSFET output transconductance transfer function for given DC operating points
%   G1          - Control voltage source output impedance + OPA210 input impedance
%   G2          - OPA210 gain stage transfer function
%   G3          - MOSFET current gain block (OPA210 output impedance + FET input admittance)
%   G4          - Current gain block (MOSFET output transconductance + source impedances)
%   G5          - INA826 gain transfer function (returned for external use)
%   H1          - Current sense resistor (0.0047Ω current to voltage gain)
%   H2          - INA296 current sense amplifier gain
%   H3          - INA296 output impedance + OPA210 input impedance
%   vds         - Vds operating points used in analysis
%   vgs         - Vgs operating points used in analysis
%   id          - Drain current characteristics
%
% DEPENDENCIES:
%   - derive_opa210_zo.m - OPA210 output impedance model
%   - derive_ina296_zo.m - INA296 output impedance model
%   - derive_opa210_zi.m - OPA210 input impedance model
%   - derive_opa210_gain.m - OPA210 gain model
%   - derive_ina826_gain.m - INA826 gain model (referenced but not found)
%   - derive_ina296_gain.m - INA296 gain model
%   - fet_small_signal.m - MSC017SMA120B4N MOSFET small-signal model
%   - normalize_tf_from_sym.m - Transfer function normalization
%   - normalize_tf.m - Transfer function normalization
%
% EXAMPLE:
%   % Analyze control loop at specific operating point
%   [H, H_transient, H_loop_gain] = control_loop(60, 10, 1e9, 5, 0, 0, 1, 1, 800);
%
% NOTES:
%   - All transfer functions are normalized to prevent Inf and NaN due to number overflow
%   - MOSFET characteristics are interpolated from characterization data
%   - Component models are based on datasheet information
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
    % Component model initialization
    opa210_zo = derive_opa210_zo(0);      % OPA210 output impedance model
    ina296_zo = derive_ina296_zo(0);      % INA296 output impedance model
    dac_zo = 2e3;                         % Control voltage source output impedance (Ω)
    r_sense = 4.7e-3;                     % Current sense resistor (0.0047Ω)
    Z_i_s_r = opa210_zo;                  % OPA210 output impedance
    
    % Calculate component transfer functions
    [G1, H3] = derive_opa210_zi(dac_zo, ina296_zo);  % G1: Control source + OPA210 input impedance, H3: INA296 output + OPA210 input impedance
    G2 = derive_opa210_gain(0);                       % OPA210 gain stage
    G5 = derive_ina826_gain(0);                       % INA826 gain (returned for external use)
    
    % Calculate MOSFET small-signal characteristics
    [Y_i, Y_o, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, vds, vgs, id] = fet_small_signal(Z_i_s_r, Z_o_p_r, Z_o_s_r, r_g, c_g, vds_divisor, vgs_divisor, max_vds);
    
    % Extract transfer functions at specific operating point
    Y_i_tf = Y_i(vds_dc, vgs_dc);         % MOSFET input admittance + OPA210 output impedance
    Y_o_tf = Y_o(vds_dc, vgs_dc);         % MOSFET output transconductance + source impedances at FET output

    % Additional transfer functions
    H1 = r_sense;                         % Current sense resistor (0.0047Ω)
    H2 = derive_ina296_gain(0);           % INA296 current sense amplifier gain

    % Normalize transfer functions for numerical stability
    G1 = normalize_tf_from_sym(G1);
    G2 = normalize_tf_from_sym(G2);
    G3 = Y_i_tf;
    G4 = Y_o_tf;
    H1 = tf(H1, 1);
    H2 = normalize_tf_from_sym(H2);
    H3 = normalize_tf_from_sym(H3);

    % Calculate final transfer functions
    H_loop_gain = normalize_tf(H1*H2*H3*G2*G3);           % Loop gain transfer function
    H = normalize_tf(G1*G2*G3)/(1+H_loop_gain);           % Control loop transfer function
    H_transient = G4/(1+H_loop_gain);                     % Transient response transfer function
end