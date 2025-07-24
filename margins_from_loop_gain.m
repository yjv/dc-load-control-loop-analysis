function [gain_margin, phase_margin, f_gain0, f_phase_neg180, f_gain20, f_gainn20] = margins_from_loop_gain(mag_db, phase, f)
    % phase_unwrapped = unwrap(deg2rad(phase));  % in radians
    % phase_unwrapped = rad2deg(phase_unwrapped);  % back to degrees

    % crossover indexes
    function f_gain = frequency_for_gain_db(mag_db, gain_db)
        idx_gain = find(mag_db < gain_db, 1, 'first');
        if isempty(idx_gain)
            f_gain = max(f);
        else
            f_gain = interp1(mag_db(idx_gain-1:idx_gain), ...
                f(idx_gain-1:idx_gain), ...
                gain_db);
        end
    end
    
    f_gain0 = frequency_for_gain_db(mag_db, 0);
    f_gain20 = frequency_for_gain_db(mag_db, 20);
    f_gainn20 = frequency_for_gain_db(mag_db, -20);

    idx_phase_cross = find(phase < -180, 1, 'first');
    if isempty(idx_phase_cross)
        f_phase_neg180 = max(f);
    else

    f_phase_neg180 = interp1(phase(idx_phase_cross-1:idx_phase_cross), ...
                     f(idx_phase_cross-1:idx_phase_cross), ...
                     -180);

    end
    
    % Phase at gain crossover (phase margin)
    phase_at_0db = interp1(f, phase, f_gain0);
    phase_margin = 180 + phase_at_0db;

    % Gain at -180 degrees (gain margin)
    gain_at_m180_dB = interp1(f, mag_db, f_phase_neg180);
    gain_margin = gain_at_m180_dB;
end