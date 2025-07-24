function N = normalize_tf(H)
    N = normalize_tf_from_numden(H.Numerator{1}, H.Denominator{1});
end