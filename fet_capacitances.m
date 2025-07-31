function [C_iss, C_oss, C_rss, capacitance_vds, capacitances] = fet_capacitances(vds)
    capacitance_vds = [
    0.1
    % actually traced
    1
    1.25892541179417
    1.58489319246111
    1.99526231496888
    2.51188643150958 
    3.16227766016838
    3.98107170553497
    5.01187233627272
    6.30957344480193
    7.94328234724282
    10
    12.5892541179417
    15.8489319246111
    19.9526231496888
    25.1188643150958
    31.6227766016838
    39.8107170553497
    50.1187233627272
    63.0957344480193
    79.4328234724281
    100
    125.892541179417
    158.489319246111
    199.526231496888
    251.188643150958
    316.227766016838
    398.107170553497
    501.187233627272
    630.957344480193
    794.328234724281
    1000
    1258.92541179417 
    ];
    
    capacitances = 1e-12 * [
    % C_iss	C_oss	C_rss
    5.35e3	5.34e3	1260
    % actually traced
    5.35e3	5.34e3	1260
    5.15e3	4.8e3	960
    4.75e3	4.25e3	570
    4.62e3	4e3	    440
    4.6e3	3.8e3	415
    4.59e3	3.6e3	390
    4.58e3	3.4e3	365
    4.57e3	3.2e3	335
    4.55e3	3e3	    305
    4.53e3	2.7e3	263
    4.5e3	2.1e3	100
    4.45e3	1.78e3	59
    4.45e3	1.59e3	51
    4.43e3	1.44e3	45
    4.43e3	1.3e3	40
    4.43e3	1.17e3	36
    4.43e3	1.06e3	33
    4.43e3	950	    30
    4.43e3	850	    27.5
    4.42e3	760	    25.5
    4.42e3	690	    23.5
    4.42e3	620	    21.5
    4.41e3	555	    20
    4.4e3	500	    18.5
    4.39e3	445	    17.1
    4.38e3	400	    15.9
    4.37e3	360	    14.8
    4.36e3	325	    13.8
    4.34e3	286	    13
    4.31e3	267	    12.6
    4.3e3	264	    12.8
    4.27e3	264	    13.7
    
    ];

    % C_iss	C_oss	C_rss
    capacitances = struct( ...
        'C_iss', capacitances(:, 1), ...
        'C_oss', capacitances(:, 2), ...
        'C_rss', capacitances(:, 3)...
    );

    if ~nargin
    
        % Plotting
        figure;
        loglog(capacitance_vds, capacitances.C_iss * 1e12, 'LineWidth', 2); hold on;
        loglog(capacitance_vds, capacitances.C_oss * 1e12, 'LineWidth', 2);
        loglog(capacitance_vds, capacitances.C_rss * 1e12, 'LineWidth', 2);
        grid on;
        xlabel('V_{DS} (V)');
        ylabel('Capacitance (pF)');
        title('Capacitance vs V_{DS}');
        legend('C_{iss}', 'C_{oss}', 'C_{rss}');
    else
        if vds > max(capacitance_vds)
            error('Target is outside the range of the vector.');
        end

        C_iss = interp1(capacitance_vds, capacitances.C_iss, vds);
        C_oss = interp1(capacitance_vds, capacitances.C_oss, vds);
        C_rss = interp1(capacitance_vds, capacitances.C_rss, vds);
    end
end
