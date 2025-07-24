function N = normalize_tf_from_sym(H)
        [num, den] = numden(H);
        num_coeffs = sym2poly(num);
        den_coeffs = sym2poly(den);
        
        N = normalize_tf_from_numden(num_coeffs, den_coeffs);
    end