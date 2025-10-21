function [G_p, G_m, sys_fit, sys_fit_sym, V_diff] = derive_opa210_zi(Z_sp_r, Z_sm_r)
% DERIVE_OPA210_ZI Generate OPA210 operational amplifier input impedance transfer functions
%
% This function calculates the input impedance characteristics of the OPA210 operational
% amplifier by solving the differential amplifier circuit equations. It returns transfer
% functions for the positive and negative input paths, which are used in control loop
% analysis for G1 and H3 transfer functions.
%
% USAGE:
%   [G_p, G_m, sys_fit, sys_fit_sym, V_diff] = derive_opa210_zi(Z_sp_r, Z_sm_r)
%
% INPUTS:
%   Z_sp_r - Source impedance at positive input terminal (Ω)
%   Z_sm_r - Source impedance at negative input terminal (Ω)
%
% OUTPUTS:
%   G_p        - Transfer function for positive input path (V_p/V_sp)
%   G_m        - Transfer function for negative input path (V_m/V_sm)
%   sys_fit    - Complete differential transfer function with source impedances
%   sys_fit_sym- Symbolic differential transfer function with source impdances still as symbols
%   V_diff     - Differential voltage (V_p - V_m) transfer function
%
% CIRCUIT ANALYSIS:
%   The function solves Kirchhoff's Current Law (KCL) equations for the differential amplifier:
%   (V_sp - V_p)/Z_sp = (V_p - V_m)/Z_diff + V_p/Z_cm
%   (V_sm - V_m)/Z_sm = (V_m - V_p)/Z_diff + V_m/Z_cm
%
%   Current into non-inverting input = current through differential impedance + current through common-mode impedance
%   Current into inverting input = current through differential impedance + current through common-mode impedance
%
%   Where:
%   - Z_diff = 1/(1/400e3 + s*9e-12) - differential input impedance
%   - Z_cm = 1/(1/1e9 + s*0.5e-12) - common-mode input impedance
%
% EXAMPLE:
%   % Calculate input impedance with 2kΩ DAC output impedance on both terminals
%   dac_zo = 2e3;
%   [G_p, G_m, sys_fit] = derive_opa210_zi(dac_zo, dac_zo);
%
% NOTES:
%   - Based on OPA210 datasheet input impedance specifications
%   - Used in control loop analysis for G1 and H3 transfer functions
%   - Accounts for both differential and common-mode input impedances
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
    % Define symbolic variables for circuit analysis
    % V_sp, V_sm - Source voltages at non-inverting and inverting inputs
    % V_p, V_m   - Voltages at op-amp input terminals (after input impedance voltage divider effect)
    % Z_sp, Z_sm - Source impedances at non-inverting and inverting inputs
    % Z_diff     - Op-amp differential input impedance
    % Z_cm       - Op-amp common-mode input impedance
    % s          - Complex frequency
    syms V_sp V_sm V_p V_m Z_sp Z_sm Z_diff Z_cm s
    
    % Set up opamp non-inverting and inverting input circuit equations
    eq1 = (V_sp - V_p)/Z_sp == (V_p - V_m)/Z_diff + V_p/Z_cm;
    eq2 = (V_sm - V_m)/Z_sm == (V_m - V_p)/Z_diff + V_m/Z_cm;
    
    % Solve for V_p and V_m in terms of V_sp, V_sm, Z_sp, Z_sm, Z_diff, Z_cm
    [V_p_sol, V_m_sol] = solve([eq1 eq2], [V_p V_m]);
    
    % Collect terms for cleaner expressions
    V_p_solved = collect(V_p_sol, [V_sm, V_sp]);
    V_m_solved = collect(V_m_sol, [V_sm, V_sp]);
    V_diff = simplify(V_p_solved - V_m_solved);

    % Substitute OPA210 input impedance values and expand
    % Z_diff = 1/(1/400e3 + s*9e-12) - differential input impedance
    % Z_cm = 1/(1/1e9 + s*0.5e-12) - common-mode input impedance
    sys_fit_sym = collect(expand(subs(V_diff, [Z_diff Z_cm], [1/(1/400e3 + s*9e-12) 1/(1/1e9 + s*0.5e-12)])), [V_sm, V_sp]);
    
    % Substitute actual source impedance values
    sys_fit = subs(sys_fit_sym, [Z_sp Z_sm], [Z_sp_r Z_sm_r]);

    % Extract transfer functions for positive and negative input paths
    G_p = subs(sys_fit, [V_sp V_sm], [1 0]);
    G_m = subs(sys_fit, [V_sp V_sm], [0 -1]);
end