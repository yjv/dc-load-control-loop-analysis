function H_tf = tf_from_sym(H_sym)
    [num_sym, den_sym] = numden(H_sym);
    num_coeffs = sym2poly(num_sym);
    den_coeffs = sym2poly(den_sym);
    H_tf = tf(num_coeffs, den_coeffs);
end
