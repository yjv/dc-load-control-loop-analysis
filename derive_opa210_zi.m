function [G_p, G_m, sys_fit, sys_fit_sym] = derive_opa210_zi(Z_sp_r, Z_sm_r)
    syms V_sp V_sm V_p V_m Z_sp Z_sm Z_diff Z_cm s
    eq1 = (V_sp - V_p)/Z_sp == (V_p - V_m)/Z_diff + V_p/Z_cm;
    eq2 = (V_sm - V_m)/Z_sm == (V_m - V_p)/Z_diff + V_m/Z_cm;
    
    [V_p_sol, V_m_sol] = solve([eq1 eq2], [V_p V_m]);
    
    V_p_solved = collect(V_p_sol, [V_sm, V_sp]);
    V_m_solved = collect(V_m_sol, [V_sm, V_sp]);
    V_diff=simplify(V_p_solved-V_m_solved);

    % sys_fit_sym = collect(expand(subs(V_diff, [Z_diff Z_cm], [1/(1/400e3 + s*9e-12) 1/(1/1e9 + s*0.5e-12)])), [V_sm, V_sp]);
    sys_fit_sym = collect(expand(subs(V_diff, [Z_diff Z_cm], [1/(1/400e3 + s*9e-12) 1/(1/1e9 + s*0.5e-12)])), [V_sm, V_sp]);
    sys_fit = subs(sys_fit_sym, [Z_sp Z_sm], [Z_sp_r Z_sm_r]);

    G_p = subs(sys_fit, [V_sp V_sm], [1 0]);
    G_m = subs(sys_fit, [V_sp V_sm], [0 1]);
end