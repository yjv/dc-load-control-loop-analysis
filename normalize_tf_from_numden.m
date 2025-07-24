function N = normalize_tf_from_numden(num_coeffs, den_coeffs)
    
    % Normalize
    den_leading = 10^(median(log10(abs(den_coeffs(den_coeffs > 0)))));
    num_norm = num_coeffs / den_leading;
    den_norm = den_coeffs / den_leading;
    
    N = tf(num_norm, den_norm);
end