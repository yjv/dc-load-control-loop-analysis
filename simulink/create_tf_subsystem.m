function create_tf_subsystem(sym_num, sym_den, modelName, subsystemName, inputName, outputName)
    % CREATE TFSUBSYSTEMSYMBOLIC Builds a Simulink subsystem implementing a 
    % symbolic transfer function with parameters C_iss, C_oss, C_rss as inputs.
    %
    % Inputs:
    %   sym_num - symbolic numerator coefficient vector, depends on (C_iss, C_oss, C_rss)
    %   sym_den - symbolic denominator coefficient vector (monic, leading 1), depends on same params
    %   modelName - name of Simulink model (.slx)
    %   subsystemName - name of subsystem to create inside model
    %
    % The subsystem has inputs:
    %   u - the input signal
    %   C_iss, C_oss, C_rss - scalar parameters
    %
    % Outputs:
    %   y - output signal
    %
    % The subsystem contains:
    %  - A MATLAB Function block computing numeric coeffs from symbolic expressions at runtime
    %  - Variable-Gain blocks whose gain is driven by these coeff outputs
    %  - Integrator and Sum blocks arranged in controllable canonical form
    
    %% Check Symbolic Toolbox availability
    if ~license('test','Symbolic_Toolbox')
        error('Symbolic Math Toolbox is required for this function.');
    end
    % 
    % %% Ensure denominator is monic
    % den_lead = coeffs(sym_den(1),'All');
    % if ~isequal(den_lead, sym(1))
    %     error('Denominator polynomial must be monic (leading coefficient = 1).');
    % end
    % 
    
    % Add subsystem block
    add_block('built-in/Subsystem', [modelName '/' subsystemName]);
    open_system([modelName '/' subsystemName]);
    
    blkPath = [modelName '/' subsystemName];
    
    % Clear existing subsystem contents
    blocksInside = find_system(blkPath,'SearchDepth',1);
    for k=1:numel(blocksInside)
        if ~strcmp(blocksInside{k}, blkPath)
            delete_block(blocksInside{k});
        end
    end

    % Number of coefficients
    n = length(sym_den) - 1; % denominator order
    m = length(sym_num) - 1; % numerator order
    % 
    % if m < n
    %     sym_num = [zeros(n - m) sym_num];
    % end
    % 
    % if m > n
    % 
    % end
    
    %% Add inputs: u, C_iss, C_oss, C_rss
    add_block('simulink/Sources/In1',[blkPath '/' inputName]);
    add_block('simulink/Sources/In1',[blkPath '/C_iss']);
    add_block('simulink/Sources/In1',[blkPath '/C_oss']);
    add_block('simulink/Sources/In1',[blkPath '/C_rss']);
    
    % Add Outport for output y
    add_block('simulink/Sinks/Out1', [blkPath '/' outputName]);
    
    %% Add MATLAB Function block to compute numeric coefficients
    % This block will have inputs: C_iss, C_oss, C_rss and outputs: num, den as vectors
    %% Generate the MATLAB function to compute coeff vectors numerically
    % Variables:
    C_iss = sym('C_iss','real');
    C_oss = sym('C_oss','real');
    C_rss = sym('C_rss','real');

    matlabFunctionBlock([blkPath '/CoeffCalculator'], sym_num', sym_den', 'Vars', {C_iss, C_oss, C_rss}, 'Outputs', {'num','den'});

    %% Connect parameter inputs to MATLAB Function block
    add_line(blkPath, 'C_iss/1', 'CoeffCalculator/1', 'autorouting', 'on');
    add_line(blkPath, 'C_oss/1', 'CoeffCalculator/2', 'autorouting', 'on');
    add_line(blkPath, 'C_rss/1', 'CoeffCalculator/3', 'autorouting', 'on');
    
    %% Now build transfer function realization: controllable canonical form with variable gains fed by outputs from MATLAB Function block
    
    % The MATLAB Function block outputs num and den vectors; we split elements to feed variable Gain blocks.
    % To do that, add Demux blocks or use BusSelector to route vector elements.
    
    % Add Demux blocks to split numerator and denominator coeff vector signals
    
    % Demux for numerator coefficients (length m+1)
    add_block('simulink/Signal Routing/Demux', [blkPath '/Demux_num'], ...
        'Outputs', num2str(m+1));
    
    % Demux for denominator coefficients (length n+1)
    add_block('simulink/Signal Routing/Demux', [blkPath '/Demux_den'], ...
        'Outputs', num2str(n+1));
    
    % Connect outputs of CoeffCalculator to Demux blocks
    add_line(blkPath, 'CoeffCalculator/1', 'Demux_num/1', 'autorouting', 'on');
    add_line(blkPath, 'CoeffCalculator/2', 'Demux_den/1', 'autorouting', 'on');

    add_block('simulink/Math Operations/Sum', [blkPath '/OutputSum'], 'Inputs', '++');


    % Feedforwards for numerator (as negative gains)
    for i = 1:m+1
        % Add Product block to multiply integrator_i output by numerator coeff b_i
        add_block('simulink/Math Operations/Product', [blkPath sprintf('/Prod_num_%d', i)]);
        % Connect integrator_i output to Product input1
        add_line(blkPath, [inputName '/1'], sprintf('Prod_num_%d/1', i), 'autorouting', 'on');
        % Connect Demux_den output i+1 to Product input2
        add_line(blkPath, sprintf('Demux_num/%d', i), sprintf('Prod_num_%d/2', i), 'autorouting', 'on');
    end

    % Feedbacks for denominator (as negative gains)
    for i = 1:n+1
        % Add Product block to multiply integrator_i output by numerator coeff b_i
        add_block('simulink/Math Operations/Product', [blkPath sprintf('/Prod_den_%d', i)]);
        % Connect integrator_i output to Product input1
        add_line(blkPath, 'OutputSum/1', sprintf('Prod_den_%d/1', i), 'autorouting', 'on');
        % Connect Demux_den output i+1 to Product input2
        add_line(blkPath, sprintf('Demux_den/%d', i), sprintf('Prod_den_%d/2', i), 'autorouting', 'on');
    end

    add_line(blkPath, 'Prod_den_1/1', sprintf('%s/1', outputName));

    % Inside subsystem: add integrators, sum blocks, and link gains
    for i = 1:n
        add_block('simulink/Continuous/Integrator', ...
            [modelName '/' subsystemName '/Int' num2str(i)]);

        if i == 1
            sumInputs = '+-';
        else
            sumInputs = '++-';
        end

        add_block('simulink/Math Operations/Sum', [modelName '/' subsystemName '/Sum' num2str(i)], 'Inputs', sumInputs);

        add_line([modelName '/' subsystemName], ...
            ['Sum' num2str(i) '/1'], ['Int' num2str(i) '/1']);

        if i > 1
            add_line([modelName '/' subsystemName], ...
             ['Int' num2str(i - 1) '/1'], ['Sum' num2str(i) '/2']);
        end

        if i <= m + 1
            % Connect Product output to Sum_num input i+1
            add_line(blkPath, sprintf('Prod_num_%d/1', m+2-i), sprintf('Sum%d/1', i), 'autorouting', 'on');
        end

        if i == 1
            port = 2;
        else
            port = 3;
        end

        % Connect Product output to Sum_num input i+1
        add_line(blkPath, sprintf('Prod_den_%d/1', n+2-i), sprintf('Sum%d/%d', i, port), 'autorouting', 'on');
    end

    if n
        add_line([modelName '/' subsystemName], ['Int' num2str(n) '/1'], 'OutputSum/2');
    end

    if m >= n
        outputInputBlockName = 'Prod_num_1';

        for i = 2:m + 1 - n
            add_block('simulink/Continuous/Derivative', [modelName '/' subsystemName '/Der' num2str(i - 1)]);
            add_block('simulink/Math Operations/Sum', [modelName '/' subsystemName '/Sum_der' num2str(i - 1)], 'Inputs', '++');

            % Connect Product output to Sum_num input i+1
            add_line(blkPath, sprintf('%s/1', outputInputBlockName), sprintf('Der%d/1', i - 1), 'autorouting', 'on');
            add_line([modelName '/' subsystemName], sprintf('Der%d/1', i - 1), ['Sum_der' num2str(i - 1) '/1']);
            add_line([modelName '/' subsystemName], sprintf('Prod_num_%d/1', i), ['Sum_der' num2str(i - 1) '/2']);
            outputInputBlockName = ['Sum_der' num2str(i - 1)];
        end

        add_line(blkPath, sprintf('%s/1', outputInputBlockName), 'OutputSum/1');
    end

    %% tidy
    % Arrange subsystem blocks for clarity
    Simulink.BlockDiagram.arrangeSystem(blkPath);
    
    % Save model
    save_system(modelName);
    fprintf('Created symbolic transfer function subsystem "%s" in model "%s"\n', subsystemName, modelName);
end
