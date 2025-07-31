function create_tf_subsystem0(sym_num, sym_den, modelName, subsystemName, inputName, outputName)
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

    %% Ensure denominator is monic
    den_lead = coeffs(sym_den(1),'All');
    if ~isequal(den_lead, sym(1))
        error('Denominator polynomial must be monic (leading coefficient = 1).');
    end
    
    %% Open/Create model
    if exist([modelName '.slx'], 'file')
        load_system(modelName);
    else
        new_system(modelName)
        open_system(modelName)
    end
    
    % Delete existing block if exists
    % if ~isempty(find_system(modelName,'SearchDepth',3,'Name',subsystemName))
        delete_block([modelName '/' subsystemName]);
    % end
    
    % Add subsystem block
    add_block('built-in/Subsystem', [modelName '/' subsystemName], 'Position',[100 100 190 180]);
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
    if m < n
        sym_num = [sym(zeros(1,n-m)), sym_num]; % Pad numerator to length n+1
        m = n;
    end
    
    %% Add inputs: u, C_iss, C_oss, C_rss
    input_spacing = 50;
    y_pos = 100;
    add_block('built-in/Inport',[blkPath '/' inputName], 'Position',[30 y_pos 60 y_pos+20]);
    add_block('built-in/Inport',[blkPath '/C_iss'], 'Position',[30 y_pos+1*input_spacing 60 y_pos+20+1*input_spacing]);
    add_block('built-in/Inport',[blkPath '/C_oss'], 'Position',[30 y_pos+2*input_spacing 60 y_pos+20+2*input_spacing]);
    add_block('built-in/Inport',[blkPath '/C_rss'], 'Position',[30 y_pos+3*input_spacing 60 y_pos+20+3*input_spacing]);
    
    % Add Outport for output y
    add_block('built-in/Outport', [blkPath '/' outputName], 'Position', [700 100 730 120]);
    
    %% Add MATLAB Function block to compute numeric coefficients
    % This block will have inputs: C_iss, C_oss, C_rss and outputs: num, den as vectors
    %% Generate the MATLAB function to compute coeff vectors numerically
    % Variables:
    C_iss = sym('C_iss','real');
    C_oss = sym('C_oss','real');
    C_rss = sym('C_rss','real');

    matlabFunctionBlock([blkPath '/CoeffCalculator'], sym_num, sym_den, 'Vars', {C_iss, C_oss, C_rss}, 'Outputs', {'num','den'})

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
        'Outputs', num2str(m+1), 'Position', [400 y_pos+input_spacing-20 430 y_pos+input_spacing+40]);
    
    % Demux for denominator coefficients (length n+1)
    add_block('simulink/Signal Routing/Demux', [blkPath '/Demux_den'], ...
        'Outputs', num2str(n+1), 'Position', [400 y_pos+input_spacing+60 430 y_pos+input_spacing+120]);
    
    % Connect outputs of CoeffCalculator to Demux blocks
    add_line(blkPath, 'CoeffCalculator/1', 'Demux_num/1', 'autorouting', 'on');
    add_line(blkPath, 'CoeffCalculator/2', 'Demux_den/1', 'autorouting', 'on');
    
    %% Add integrators chain and sum blocks
    dx = 90;
    dy = 50;
    pos_x = 480;
    pos_y_start = y_pos;
    
    % Input signal 'u' connects to Sum block input
    % Sum block inputs: positive input from input* b0 gain, negative inputs from denominator gains
    
    sumInputs = ['+', repmat('-', 1, n)];
    add_block('built-in/Sum', [blkPath '/Sum_fb'], ...
        'Inputs', sumInputs, ...
        'Position', [pos_x-60 pos_y_start-30 pos_x-30 pos_y_start+30]);
    
    % Connect 'u' to Gain block for b0
    % b0 is numerator coefficient with highest s power => num(1)
    add_block('simulink/Math Operations/Gain', [blkPath '/Gain_num0'], ...
        'Position', [pos_x-130 pos_y_start-10 pos_x-100 pos_y_start+20]);
    
    % Set Gain block 'Gain' parameter to input port (variable gain)
    % To dynamically control gain, gain needs to be connected to an input port
    % But Simulink Gain blocks do not accept input gain signals directly — workaround is to use Product block
    % So instead, replace Gain blocks by Product blocks multiplying input signal by coefficient scalar inputs
    % This approach is used for all gains below.
    
    % Delete previously added Gain for num0 and add Product blocks accordingly
    
    % Remove the Gain_num0 block
    delete_block([blkPath '/Gain_num0']);
    
    % Add Product block instead, for variable gain multiplication
    add_block('simulink/Math Operations/Product', [blkPath '/Prod_num0'], ...
        'Position', [pos_x-130 pos_y_start-10 pos_x-100 pos_y_start+20]);
    
    % Add Inport block to take Gain scalar input for b0
    % But we have coeffs coming from Demux_num output 1 (index 1)
    
    % Trick: use Demux output connected to Product block input 2
    
    % Connect 'u' (Inport) to Prod_num0 input 1
    add_line(blkPath, [inputName '/1'], 'Prod_num0/1', 'autorouting', 'on');
    % Connect Demux_num/1 to Prod_num0 input 2
    add_line(blkPath, 'Demux_num/1', 'Prod_num0/2', 'autorouting', 'on');
    % Connect Prod_num0 output to Sum block positive input (Sum_fb input 1)
    add_line(blkPath, 'Prod_num0/1', 'Sum_fb/1', 'autorouting', 'on');
    
    % Now add integrator chain and feedback gains:
    for i=1:n
        % Add integrator i
        add_block('simulink/Continuous/Integrator', [blkPath sprintf('/Integrator%d', i)], ...
            'Position', [pos_x pos_y_start+(i-1)*dy pos_x+40 pos_y_start+40+(i-1)*dy]);
        % Add Product block for denominator feedback gain (negative feedback)
        add_block('simulink/Math Operations/Product', [blkPath sprintf('/Prod_den_%d', i)], ...
            'Position', [pos_x-150 pos_y_start+(i-1)*dy pos_x-110 pos_y_start+30+(i-1)*dy]);
        % Connect Integrator output to Product input1
        add_line(blkPath, sprintf('Integrator%d/1', i), sprintf('Prod_den_%d/1', i), 'autorouting', 'on');
        % Connect Demux_den output i+1 (since den coefficients start from 1 at index 1) to Product input2
        add_line(blkPath, sprintf('Demux_den/%d', i+1), sprintf('Prod_den_%d/2', i), 'autorouting', 'on');
        % Connect Product output to Sum_fb input i+1 (feedback negative input)
        add_line(blkPath, sprintf('Prod_den_%d/1', i), sprintf('Sum_fb/%d', i+1), 'autorouting', 'on');
    end
    
    % Connect Sum_fb output to first integrator input
    add_line(blkPath, 'Sum_fb/1', 'Integrator1/1', 'autorouting', 'on');
    
    % Chain integrator outputs to next integrator inputs (except last)
    for i=1:n-1
        add_line(blkPath, sprintf('Integrator%d/1', i), sprintf('Integrator%d/1', i+1), 'autorouting', 'on');
    end
    
    %% Numerator feedforward path for integrator outputs (b1, b2,...)
    % For i=1:n, multiply integrator_i output by b_i (numerator coeff at i+1 position)
    % Then sum all these with Prod_num0 output to form final output y
    
    % Add Sum block for numerator sum (n+1 inputs)
    add_block('built-in/Sum', [blkPath '/Sum_num'], ...
        'Inputs', repmat('+',1,n+1));
    
    % Connect Prod_num0 output (b0*u) to Sum_num input 1
    add_line(blkPath, 'Prod_num0/1', 'Sum_num/1', 'autorouting', 'on');
    
    for i=1:n
        % Add Product block to multiply integrator_i output by numerator coeff b_i
        add_block('simulink/Math Operations/Product', [blkPath sprintf('/Prod_num_%d', i)], ...
            'Position', [pos_x+60 pos_y_start+(i-1)*dy pos_x+90 pos_y_start+30+(i-1)*dy]);
        % Connect integrator_i output to Product input1
        add_line(blkPath, sprintf('Integrator%d/1', i), sprintf('Prod_num_%d/1', i), 'autorouting', 'on');
        % Connect Demux_num output i+1 to Product input2
        add_line(blkPath, sprintf('Demux_num/%d', i+1), sprintf('Prod_num_%d/2', i), 'autorouting', 'on');
        % Connect Product output to Sum_num input i+1
        add_line(blkPath, sprintf('Prod_num_%d/1', i), sprintf('Sum_num/%d', i+1), 'autorouting', 'on');
    end
    
    % Connect Sum_num output to Outport y
    add_line(blkPath, 'Sum_num/1', [outputName '/1'], 'autorouting', 'on');
    
    %% tidy
    % Arrange subsystem blocks for clarity
    Simulink.BlockDiagram.arrangeSystem(blkPath);
    
    % Save model
    save_system(modelName);
    fprintf('Created symbolic transfer function subsystem "%s" in model "%s"\n', subsystemName, modelName);
end
