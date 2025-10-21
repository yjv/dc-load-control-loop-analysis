function [Y_i, Y_o, Y_i_sym, Y_o_sym, I, I_sol, V_sol, g_m_r, r_o_r, C_iss_r, C_oss_r, C_rss_r, vds, vgs, id] = fet_small_signal(Z_i_s_r, Z_o_p_r, Z_o_s_r, r_g, c_g, vds_divisor, vgs_divisor, max_vds)
% FET_SMALL_SIGNAL Generate MSC017SMA120B4N MOSFET small-signal admittance and transconductance transfer functions
%
% This function generates small-signal admittance and transconductance transfer functions (Y_i, Y_o) for the
% MSC017SMA120B4N MOSFET based on its drain current characteristics and capacitance data.
% The transfer functions are used in control loop analysis for G3 and G4 transfer functions.
%
% USAGE:
%   [Y_i, Y_o, ...] = fet_small_signal(Z_i_s_r, Z_o_p_r, Z_o_s_r, r_g, c_g, vds_divisor, vgs_divisor, max_vds)
%
% INPUTS:
%   Z_i_s_r    - Source impedance at MOSFET input (gate) (Ω)
%   Z_o_p_r    - Parallel source impedance at MOSFET output (drain) (Ω)
%   Z_o_s_r    - Series source impedance at MOSFET output (drain) (Ω)
%   r_g        - Additional gate resistance (external to FET) (Ω)
%   c_g        - Additional gate capacitance (external to FET) (F)
%   vds_divisor- Vds resolution divisor (balances precision vs calculation speed)
%   vgs_divisor- Vgs resolution divisor (balances precision vs calculation speed)
%   max_vds    - Maximum Vds for analysis (V)
%
% OUTPUTS:
%   Y_i        - Callable function that returns MOSFET input transconductance transfer function
%   Y_o        - Callable function that returns MOSFET output transconductance transfer function
%   Y_i_sym    - Symbolic input admittance transfer function
%   Y_o_sym    - Symbolic output admittance transfer function
%   I          - Symbolic current equations (I_d, I_s, I_g)
%   I_sol      - Solved current equations in terms of V_i and V_o
%   V_sol      - Solved voltage equations (V_ds, V_gs)
%   g_m_r      - Transconductance matrix (∂Id/∂Vgs) (S)
%   r_o_r      - Output resistance matrix (∂Vds/∂Id) (Ω)
%   C_iss_r    - Input capacitance matrix (F)
%   C_oss_r    - Output capacitance matrix (F)
%   C_rss_r    - Reverse transfer capacitance matrix (F)
%   vds        - Drain-source voltage points (V)
%   vgs        - Gate-source voltage points (V)
%   id         - Drain current characteristics (A)
%
% SMALL-SIGNAL MODEL:
%   The function uses the standard MOSFET small-signal model with:
%   - C_gs: Gate-source capacitance
%   - C_gd: Gate-drain capacitance
%   - C_ds: Drain-source capacitance
%   - g_m: Transconductance
%   - r_o: Output resistance
%
%   Current equations:
%   I_d = g_m*V_gs + V_ds/r_o + V_ds*s*C_ds - (V_gs-V_ds)*s*C_gd
%   I_s = V_gs*s*C_gs + g_m*V_gs + V_ds/r_o + V_ds*s*C_ds
%   I_g = (V_gs-V_ds)*s*C_gd + V_gs*s*C_gs
%
% CAPACITANCE MAPPING:
%   Datasheet capacitances are mapped to small-signal model:
%   - C_iss = C_gs + C_gd (input capacitance)
%   - C_oss = C_ds + C_gd (output capacitance)
%   - C_rss = C_gd (reverse transfer capacitance)
%
% EXAMPLE:
%   % Generate MOSFET transconductance functions
%   [Y_i, Y_o] = fet_small_signal(1e3, 1e9, 5, 0, 0, 1, 1, 800);
%
%   % Get transconductance at specific operating point
%   Y_i_tf = Y_i(60, 10);  % Vds=60V, Vgs=10V
%   Y_o_tf = Y_o(60, 10);  % Vds=60V, Vgs=10V
%
% NOTES:
%   - Uses persistent variables to cache data for performance
%   - Interpolates MOSFET characteristics from measured data
%   - Transfer functions are normalized for numerical stability
%   - Used in control loop analysis for G3 and G4 transfer functions
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
    % Define symbolic variables for MOSFET small-signal analysis
    % Small-signal capacitances
    C_ds = sym('C_ds');  % Drain-source capacitance
    C_gd = sym('C_gd');  % Gate-drain capacitance  
    C_gs = sym('C_gs');  % Gate-source capacitance
    % Small-signal parameters
    g_m = sym('g_m');    % Transconductance
    r_o = sym('r_o');    % Output resistance
    % Datasheet capacitances
    C_iss = sym('C_iss'); % Input capacitance (C_gs + C_gd)
    C_oss = sym('C_oss'); % Output capacitance (C_ds + C_gd)
    C_rss = sym('C_rss'); % Reverse transfer capacitance (C_gd)
    % Voltages and impedances
    V_gs = sym('V_gs');  % Gate-source voltage
    V_ds = sym('V_ds');  % Drain-source voltage
    s = sym('s');        % Complex frequency
    V_o = sym('V_o');    % Output voltage
    V_i = sym('V_i');    % Input voltage
    Z_o_s = sym('Z_o_s'); % Series output impedance
    Z_i_s = sym('Z_i_s'); % Series input impedance

    if isempty(vds_divisor)
        vds_divisor = 1;
    end

    if isempty(vgs_divisor)
        vgs_divisor = 1;
    end

    if isempty(max_vds)
        max_vds = 800;
    end

    % Calculate individual current components for small-signal model
    I_C_gs = V_gs*s*C_gs;        % Gate-source capacitive current
    I_C_gd = (V_gs-V_ds)*s*C_gd; % Gate-drain capacitive current
    I_r_o = V_ds/r_o;            % Output resistance current
    I_C_ds = V_ds*s*C_ds;        % Drain-source capacitive current

    % Assemble current equations for drain, source, and gate terminals
    % Based on MOSFET small-signal model with transconductance and capacitances
    I = collect([ ...
        g_m*V_gs + I_r_o + I_C_ds - I_C_gd  % I_d: Drain current
        I_C_gs + g_m*V_gs + I_r_o + I_C_ds  % I_s: Source current  
        I_C_gd + I_C_gs                     % I_g: Gate current
    ], [V_gs, V_ds]);

    % Map datasheet capacitances to small-signal model capacitances
    % C_ds = C_oss - C_rss, C_gs = C_iss - C_rss + c_g, C_gd = C_rss
    I = subs(I, [C_ds, C_gs, C_gd], [C_oss-C_rss (C_iss-C_rss + c_g) C_rss]);

    % Set up voltage equations accounting for source impedances
    V_ds_eq = V_ds == V_o - Z_o_s * I(1);  % Drain voltage with series output impedance
    V_gs_eq = V_gs == V_i - Z_i_s * I(3);  % Gate voltage with series input impedance

    % Solve for V_ds and V_gs in terms of external voltages V_i and V_o
    % This accounts for voltage drops across source impedances
    [V_ds_sol, V_gs_sol] = solve([V_ds_eq V_gs_eq], [V_ds V_gs]);
    V_sol = struct('V_ds', collect(V_ds_sol, [V_i, V_o]), 'V_gs', collect(V_gs_sol, [V_i, V_o]));

    % Substitute solved voltages back into current equations
    I_sol = collect(simplify(subs(I, [V_ds V_gs], [V_sol.V_ds V_sol.V_gs])), [V_i, V_o]);

    % Organize current equations into structure format
    I = struct( ...
        'I_d', I(1),...    % Drain current equation
        'I_s', I(2),...    % Source current equation
        'I_g', I(3)...     % Gate current equation
    );

    % Organize solved current equations into structure format
    I_sol = struct( ...
        'I_d', I_sol(1),... % Solved drain current
        'I_s', I_sol(2),... % Solved source current
        'I_g', I_sol(3)...  % Solved gate current
    );

    % Calculate input and output transconductance transfer functions
    Y_i_sym = subs(I_sol.I_s, [V_o V_i], [0 1]);  % Input transconductance (V_o=0, V_i=1)
    Y_o_sym = subs(I_sol.I_s, [V_o V_i], [1 0]);  % Output transconductance (V_o=1, V_i=0)

    % Extract MOSFET characteristics from drain curves data
    [g_m_r, r_o_r, vds, vgs, id] = drain_curves(vds_divisor, vgs_divisor, max_vds);

    % Get capacitance data from FET datasheet
    [C_iss_r, C_oss_r, C_rss_r] = fet_capacitances(vds);

    % Expand capacitance matrices to match Vgs grid dimensions
    % Capacitances are independent of Vgs, so replicate across Vgs dimension
    C_iss_r = repmat(C_iss_r, length(vgs), 1);
    C_oss_r = repmat(C_oss_r, length(vgs), 1);
    C_rss_r = repmat(C_rss_r, length(vgs), 1);

    % Helper function to generate coefficient evaluation functions
    % This function creates MATLAB function handles for evaluating symbolic
    % coefficients with actual MOSFET parameter values
    function coeff_funs = generate_coeff_funs(coeffs)
        % Initialize cell array for coefficient functions
        coeff_funs = cell(length(coeffs));
       
        % Use persistent variable to track function generation
        persistent count;

        if isempty(count)
            count = 0;
        end

        % Convert each symbolic coefficient to evaluable function
        for i = 1:length(coeffs)
            count = count + 1;
            coeff = coeffs(i);
            % Convert symbolic coefficient to MATLAB function handle
            coeff_fun = matlabFunction(coeff, 'Vars', [g_m r_o C_iss C_oss C_rss]);
            % Create function handle that evaluates with actual MOSFET parameter matrices
            coeff_fun = @() coeff_fun(g_m_r, r_o_r, C_iss_r, C_oss_r, C_rss_r);
            coeff_funs{i} = coeff_fun;
        end
    end

    % Helper function to generate transfer function coefficients
    % This function evaluates coefficient functions and assembles them into
    % transfer function numerator and denominator coefficients
    function coeffs = generate_coeffs(num_coeff_funs, den_coeff_funs, vds_dc, vgs_dc)
        % Initialize zero matrix for handling zero coefficients
        zero_fill = zeros(size(r_o_r));
        
        % Process each coefficient pair (numerator and denominator)
        for i = 1:length(num_coeff_funs)
            % Evaluate numerator and denominator coefficient functions
            num_coeff_fun = num_coeff_funs{i};
            num_coeff = num_coeff_fun();
            den_coeff_fun = den_coeff_funs{i};
            den_coeff = den_coeff_fun();

            % Handle zero coefficients by replacing with zero matrix
            if num_coeff == 0
                num_coeff = zero_fill;
            end

            if den_coeff == 0
                den_coeff = zero_fill;
            end

            % Interpolate coefficients at specific operating point if provided
            if nargin == 4
                num_coeff = interp2(vds, vgs, num_coeff, vds_dc, vgs_dc);
                den_coeff = interp2(vds, vgs, den_coeff, vds_dc, vgs_dc);
            end

            % Assemble coefficients into transfer function format
            if i == 1
                % First coefficient: create initial coefficient structure
                coeffs = cellfun(@(num, den) [num; den], num2cell(num_coeff), num2cell(den_coeff), 'UniformOutput', false);
            elseif i == length(num_coeff_funs)
                % Last coefficient: normalize the final transfer function
                coeffs = cellfun(@(l, num, den) normalize_tf_from_numden([l(1, :) num], [l(2, :) den]), coeffs, num2cell(num_coeff), num2cell(den_coeff), 'UniformOutput', false);
            else
                % Middle coefficients: append to existing structure
                coeffs = cellfun(@(l, num, den) [l(1, :) num; l(2, :) den], coeffs, num2cell(num_coeff), num2cell(den_coeff), 'UniformOutput', false);
            end
        end

        % Convert cell array to matrix format
        coeffs = cell2mat(coeffs);
    end

    % Substitute actual impedance values into symbolic transfer functions
    % Account for external gate resistance and parallel/series output impedances
    Y_i_sub = subs(Y_i_sym, [Z_i_s r_o Z_o_s], [(Z_i_s_r + r_g) 1/(1/Z_o_p_r + 1/r_o) Z_o_s_r]);
    Y_o_sub = subs(Y_o_sym, [Z_i_s r_o Z_o_s], [(Z_i_s_r + r_g) 1/(1/Z_o_p_r + 1/r_o) Z_o_s_r]);

    % Process input transconductance transfer function
    [Y_i_num, Y_i_den] = numden(Y_i_sub);
    Y_i_num_coeffs = coeffs(Y_i_num, s, 'All');
    Y_i_den_coeffs = coeffs(Y_i_den, s, 'All');
    max_coeffs = max([length(Y_i_num_coeffs) length(Y_i_den_coeffs)]);

    % Pad coefficient arrays to equal length for processing
    Y_i_num_coeffs = [zeros(1, max_coeffs - length(Y_i_num_coeffs)) Y_i_num_coeffs];
    Y_i_den_coeffs = [zeros(1, max_coeffs - length(Y_i_den_coeffs)) Y_i_den_coeffs];
    % Generate coefficient evaluation functions
    Y_i_num_coeff_funs = generate_coeff_funs(Y_i_num_coeffs);
    Y_i_den_coeff_funs = generate_coeff_funs(Y_i_den_coeffs);
    % Create callable input transconductance function
    Y_i = @(varargin) generate_coeffs(Y_i_num_coeff_funs, Y_i_den_coeff_funs, varargin{:});
    
    % Process output transconductance transfer function
    [Y_o_num, Y_o_den] = numden(Y_o_sub);
    Y_o_num_coeff_funs = generate_coeff_funs(coeffs(Y_o_num, s, 'All'));
    Y_o_den_coeff_funs = generate_coeff_funs(coeffs(Y_o_den, s, 'All'));
    % Create callable output transconductance function
    Y_o = @(varargin) generate_coeffs(Y_o_num_coeff_funs, Y_o_den_coeff_funs, varargin{:});
end