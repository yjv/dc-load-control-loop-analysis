% limits the tf poles and zeros to as close to the frequency range as
% possible while keeping it causal
function H_lim = limit_tf_to_frequencies(H, f_min, f_max)
    w_min = 2*pi*f_min;
    w_max = 2*pi*f_max;

    %% Identify zeros and poles within the target frequency range
    zeros_all = zero(H);
    poles_all = pole(H);
    
    in_range_zero = (abs(zeros_all) >= w_min) & (abs(zeros_all) <= w_max);
    in_range_pole = (abs(poles_all) >= w_min) & (abs(poles_all) <= w_max);
    
    zeros_lim = zeros_all(in_range_zero);
    poles_in_range = poles_all(in_range_pole);
        
    % Assume you already have:
    % zeros_all, poles_all, w_min, w_max, zeros_lim as previously,
    % poles_in_range (the in-range poles), etc.
    
    % Number of poles required (at least zeros + 1)
    n_required_poles = max(numel(zeros_lim) + 1, 1);
    
    if numel(poles_in_range) >= n_required_poles
        poles_lim = poles_in_range;
    else
        % Add nearest out-of-range poles
        poles_out_range = poles_all(~in_range_pole);
        dist_to_range = min(abs(abs(poles_out_range) - w_min), abs(abs(poles_out_range) - w_max));
        [~, sort_idx] = sort(dist_to_range);
        n_needed = n_required_poles - numel(poles_in_range);
        poles_extra = poles_out_range(sort_idx(1:min(n_needed, numel(sort_idx))));
        poles_lim = [poles_in_range; poles_extra];
    end
    
    % --- Step 2: Ensure conjugate pairs for complex poles ---
    
    tol = 1e-8;
    
    for i = 1:numel(poles_lim)
        p = poles_lim(i);
        % Check if complex and not real (imaginary part larger than tolerance)
        if abs(imag(p)) > tol
            conj_p = conj(p);
            % If conjugate not already in poles_lim, add it
            if ~any(abs(poles_lim - conj_p) < tol)
                poles_lim = [poles_lim; conj_p];
            end
        end
    end
    
    % Optionally, sort poles_lim by frequency
    [~, sort_idx] = sort(abs(poles_lim));
    poles_lim = poles_lim(sort_idx);

    % --- Build final transfer function ---
    gain = dcgain(H);
    H_lim = zpk(zeros_lim, poles_lim, gain);
    H_lim = gain/dcgain(H_lim) * H_lim;

end