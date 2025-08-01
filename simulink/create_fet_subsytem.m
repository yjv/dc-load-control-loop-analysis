function create_fet_subsytem(modelName, vds, vgs, id, capacitance_vds, capacitances, Y_iss_g, Y_oss_g, Y_rss_g, Y_iss_d, Y_oss_d, Y_rss_d, G_g, G_d, G_s)
    if exist(modelName)
        load_system(modelName);
    else
        new_system(modelName)
        open_system(modelName)
    end

    subsystemName = 'FET';
    
    % Delete existing block if exists
    if ~isempty(find_system(modelName,'SearchDepth',3,'Name',subsystemName))
        delete_block([modelName '/' subsystemName]);
    end

    % Add subsystem block
    add_block('built-in/Subsystem', [modelName '/' subsystemName]);
    open_system([modelName '/' subsystemName]);
    
    blkPath = [modelName '/' subsystemName];

    blocksInside = find_system(blkPath,'SearchDepth',1);
    for k=1:numel(blocksInside)
        if ~strcmp(blocksInside{k}, blkPath)
            delete_block(blocksInside{k});
        end
    end

    add_block('simulink/Sources/In1',[blkPath '/v_i']);
    add_block('simulink/Sources/In1',[blkPath '/v_o']);

    % Add Outport for output y
    add_block('simulink/Sinks/Out1', [blkPath '/I_s']);

    [num, den] = numden_coeffs(Y_iss_g);
    create_tf_subsystem(num, den, modelName, [subsystemName '/Y_iss_g'], 'v_i', 'v_gs');
    [num, den] = numden_coeffs(Y_oss_g);
    create_tf_subsystem(num, den, modelName, [subsystemName '/Y_oss_g'], 'v_o', 'v_gs');
    [num, den] = numden_coeffs(Y_rss_g);
    create_tf_subsystem(num, den, modelName, [subsystemName '/Y_rss_g'], 'I_d', 'v_gs');
    add_block('simulink/Math Operations/Sum', [modelName '/' subsystemName '/vgs_sum'], 'Inputs', '+++');
    add_line([modelName '/' subsystemName], 'Y_iss_g/1', 'vgs_sum/1');
    add_line([modelName '/' subsystemName], 'Y_oss_g/1', 'vgs_sum/2');
    add_line([modelName '/' subsystemName], 'Y_rss_g/1', 'vgs_sum/3');

    [num, den] = numden_coeffs(Y_iss_d);
    create_tf_subsystem(num, den, modelName, [subsystemName '/Y_iss_d'], 'v_i', 'v_ds');
    [num, den] = numden_coeffs(Y_oss_d);
    create_tf_subsystem(num, den, modelName, [subsystemName '/Y_oss_d'], 'v_o', 'v_ds');
    [num, den] = numden_coeffs(Y_rss_d);
    create_tf_subsystem(num, den, modelName, [subsystemName '/Y_rss_d'], 'I_d', 'v_ds');
    add_block('simulink/Math Operations/Sum', [modelName '/' subsystemName '/vds_sum'], 'Inputs', '+++');
    add_line([modelName '/' subsystemName], 'Y_iss_d/1', 'vds_sum/1');
    add_line([modelName '/' subsystemName], 'Y_oss_d/1', 'vds_sum/2');
    add_line([modelName '/' subsystemName], 'Y_rss_d/1', 'vds_sum/3');

    [num, den] = numden_coeffs(G_g);
    create_tf_subsystem(num, den, modelName, [subsystemName '/G_g'], 'v_gs', 'I_s');
    [num, den] = numden_coeffs(G_d);
    create_tf_subsystem(num, den, modelName, [subsystemName '/G_d'], 'v_ds', 'I_s');
    [num, den] = numden_coeffs(G_s);
    create_tf_subsystem(num, den, modelName, [subsystemName '/G_s'], 'I_d', 'I_s');
    add_block('simulink/Math Operations/Sum', [modelName '/' subsystemName '/I_s_sum'], 'Inputs', '+++');
    add_line([modelName '/' subsystemName], 'G_g/1', 'I_s_sum/1');
    add_line([modelName '/' subsystemName], 'G_d/1', 'I_s_sum/2');
    add_line([modelName '/' subsystemName], 'G_s/1', 'I_s_sum/3');

    add_block('simulink/Lookup Tables/2-D Lookup Table', [blkPath '/I_d_lookup'], 'Table', mat2str(id), 'BreakpointsForDimension1', mat2str(vgs), 'BreakpointsForDimension2', mat2str(vds));
    add_block('simulink/Lookup Tables/1-D Lookup Table', [blkPath '/C_iss_lookup'], 'Table', mat2str(capacitances.C_iss), 'BreakpointsForDimension1', mat2str(capacitance_vds));
    add_block('simulink/Lookup Tables/1-D Lookup Table', [blkPath '/C_oss_lookup'], 'Table', mat2str(capacitances.C_oss), 'BreakpointsForDimension1', mat2str(capacitance_vds));
    add_block('simulink/Lookup Tables/1-D Lookup Table', [blkPath '/C_rss_lookup'], 'Table', mat2str(capacitances.C_rss), 'BreakpointsForDimension1', mat2str(capacitance_vds));
    add_line([modelName '/' subsystemName], 'vgs_sum/1', 'I_d_lookup/1');
    add_line([modelName '/' subsystemName], 'vds_sum/1', 'I_d_lookup/2');
    add_line([modelName '/' subsystemName], 'vds_sum/1', 'C_iss_lookup/1');
    add_line([modelName '/' subsystemName], 'vds_sum/1', 'C_oss_lookup/1');
    add_line([modelName '/' subsystemName], 'vds_sum/1', 'C_rss_lookup/1');

    add_line([modelName '/' subsystemName], 'v_i/1', 'Y_iss_g/1');
    add_line([modelName '/' subsystemName], 'C_iss_lookup/1', 'Y_iss_g/2');
    add_line([modelName '/' subsystemName], 'C_oss_lookup/1', 'Y_iss_g/3');
    add_line([modelName '/' subsystemName], 'C_rss_lookup/1', 'Y_iss_g/4');

    add_line([modelName '/' subsystemName], 'v_o/1', 'Y_oss_g/1');
    add_line([modelName '/' subsystemName], 'C_iss_lookup/1', 'Y_oss_g/2');
    add_line([modelName '/' subsystemName], 'C_oss_lookup/1', 'Y_oss_g/3');
    add_line([modelName '/' subsystemName], 'C_rss_lookup/1', 'Y_oss_g/4');

    add_line([modelName '/' subsystemName], 'I_d_lookup/1', 'Y_rss_g/1');
    add_line([modelName '/' subsystemName], 'C_iss_lookup/1', 'Y_rss_g/2');
    add_line([modelName '/' subsystemName], 'C_oss_lookup/1', 'Y_rss_g/3');
    add_line([modelName '/' subsystemName], 'C_rss_lookup/1', 'Y_rss_g/4');

    add_line([modelName '/' subsystemName], 'v_i/1', 'Y_iss_d/1');
    add_line([modelName '/' subsystemName], 'C_iss_lookup/1', 'Y_iss_d/2');
    add_line([modelName '/' subsystemName], 'C_oss_lookup/1', 'Y_iss_d/3');
    add_line([modelName '/' subsystemName], 'C_rss_lookup/1', 'Y_iss_d/4');

    add_line([modelName '/' subsystemName], 'v_o/1', 'Y_oss_d/1');
    add_line([modelName '/' subsystemName], 'C_iss_lookup/1', 'Y_oss_d/2');
    add_line([modelName '/' subsystemName], 'C_oss_lookup/1', 'Y_oss_d/3');
    add_line([modelName '/' subsystemName], 'C_rss_lookup/1', 'Y_oss_d/4');

    add_line([modelName '/' subsystemName], 'I_d_lookup/1', 'Y_rss_d/1');
    add_line([modelName '/' subsystemName], 'C_iss_lookup/1', 'Y_rss_d/2');
    add_line([modelName '/' subsystemName], 'C_oss_lookup/1', 'Y_rss_d/3');
    add_line([modelName '/' subsystemName], 'C_rss_lookup/1', 'Y_rss_d/4');

    add_line([modelName '/' subsystemName], 'vgs_sum/1', 'G_g/1');
    add_line([modelName '/' subsystemName], 'C_iss_lookup/1', 'G_g/2');
    add_line([modelName '/' subsystemName], 'C_oss_lookup/1', 'G_g/3');
    add_line([modelName '/' subsystemName], 'C_rss_lookup/1', 'G_g/4');

    add_line([modelName '/' subsystemName], 'vds_sum/1', 'G_d/1');
    add_line([modelName '/' subsystemName], 'C_iss_lookup/1', 'G_d/2');
    add_line([modelName '/' subsystemName], 'C_oss_lookup/1', 'G_d/3');
    add_line([modelName '/' subsystemName], 'C_rss_lookup/1', 'G_d/4');

    add_line([modelName '/' subsystemName], 'I_d_lookup/1', 'G_s/1');
    add_line([modelName '/' subsystemName], 'C_iss_lookup/1', 'G_s/2');
    add_line([modelName '/' subsystemName], 'C_oss_lookup/1', 'G_s/3');
    add_line([modelName '/' subsystemName], 'C_rss_lookup/1', 'G_s/4');

    add_line([modelName '/' subsystemName], 'I_s_sum/1', 'I_s/1');

    %% tidy
    % Arrange subsystem blocks for clarity
    Simulink.BlockDiagram.arrangeSystem(blkPath);
    
    % Save model
    save_system(modelName);
    fprintf('Created subsystem "%s" in model "%s"\n', subsystemName, modelName);

end