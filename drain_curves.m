function [g_m, r_o, vds, vgs, id] = drain_curves(vds_divisor, vgs_divisor, max_vds)
% DRAIN_CURVES Extract MOSFET small-signal parameters from drain current characteristics
%
% This function loads MSC017SMA120B4N MOSFET drain current characteristics from CSV data and 
% calculates small-signal parameters (transconductance g_m and output resistance r_o). 
% It supports both analysis and visualization modes.
%
% USAGE:
%   [g_m, r_o, vds, vgs, id] = drain_curves(vds_divisor, vgs_divisor, max_vds)
%   drain_curves()  % Visualization mode
%
% INPUTS:
%   vds_divisor - Vds resolution divisor (balances precision vs calculation speed)
%   vgs_divisor - Vgs resolution divisor (balances precision vs calculation speed)
%   max_vds     - Maximum Vds for analysis (V)
%
% OUTPUTS:
%   g_m  - Transconductance matrix (∂Id/∂Vgs) in S
%   r_o  - Output resistance matrix (∂Vds/∂Id) in Ω
%   vds  - Drain-source voltage points (V)
%   vgs  - Gate-source voltage points (V)
%   id   - Drain current characteristics (A)
%
% DATA FORMAT:
%   The function expects a CSV file with the following structure:
%   - First row: Vds values (excluding first cell)
%   - First column: Vgs values (excluding first cell)
%   - Data matrix: Id values corresponding to (Vgs, Vds) combinations
%
% EXAMPLE:
%   % Extract parameters with default resolution
%   [g_m, r_o, vds, vgs, id] = drain_curves(1, 1, 800);
%
%   % Visualize characteristics
%   drain_curves();
%
% NOTES:
%   - Uses persistent variables to cache loaded data for performance
%   - g_m and r_o are calculated using MATLAB's gradient function
%   - Visualization mode shows 3D surface plots and parameter maps
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
    % Persistent variables to cache loaded data for performance
    persistent vds_loaded;
    persistent vgs_loaded;
    persistent id_loaded;

    % Load MOSFET characterization data from CSV file
    if isempty(id_loaded)
        % CSV format: first row = Vds values, first column = Vgs values, data = Id values
        data = readmatrix('MSC025SMA120B4/MSC025SMA120B4_drain_curves_2d.csv');
        vds_loaded = data(1,2:end);      % Vds values (excluding first cell)
        vgs_loaded = data(2:end,1);      % Vgs values (excluding first cell)
        id_loaded  = data(2:end,2:end);  % Id matrix corresponding to (Vgs, Vds) combinations
    end

    % Return loaded data
    vds = vds_loaded;
    vgs = vgs_loaded;
    id = id_loaded;

    % Calculate finite differences for small-signal parameters
    [dId_dVds, dId_dVgs] = gradient(id, vds, vgs);
    
    % Visualization mode - create plots when no input arguments provided
    if ~nargin
        max_id = 3;  % Maximum current for contour plotting

        % Find operating points with maximum derivatives
        % Maximum ∂Id/∂Vds (minimum output resistance)
        [~, idx_dVds] = max(abs(dId_dVds(:)));
        [vgs_idx1, vds_idx1] = ind2sub(size(id), idx_dVds);
        vds_max1 = vds(vds_idx1);
        vgs_max1 = vgs(vgs_idx1);
        
        % Maximum ∂Id/∂Vgs (maximum transconductance)
        [~, idx_dVgs] = max(abs(dId_dVgs(:)));
        [vgs_idx2, vds_idx2] = ind2sub(size(id), idx_dVgs);
        vds_max2 = vds(vds_idx2);
        vgs_max2 = vgs(vgs_idx2);

        % Create mesh grid for 3D plotting
        [VDS, VGS] = meshgrid(vds, vgs);

        % Plot 3D surface of drain current characteristics
        figure;
        surf(VGS, VDS, id, 'EdgeColor', 'none');
        set(gca, 'XDir', 'reverse');
        xlabel('V_{gs}'); ylabel('V_{ds}'); zlabel('I_d');
        title('I_d(V_{gs}, V_{ds})');
        view(45,30); colorbar;
        hold on;
        % Mark maximum derivative points
        plot3(vgs_max1, vds_max1, id(vgs_idx1, vds_idx1), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
        plot3(vgs_max2, vds_max2, id(vgs_idx2, vds_idx2), 'go', 'MarkerSize', 10, 'LineWidth', 2);
        % Add current limiting contour
        contour3(VGS, VDS, id, [max_id, max_id], 'r', 'LineWidth', 2);
        legend('I_d Surface', 'Max ∂I_d/∂V_{ds}', 'Max ∂I_d/∂V_{gs}');
        
        % Create 2D parameter maps showing derivative magnitudes
        figure;
        subplot(1,2,1);
        imagesc(vds, (vgs), (abs(dId_dVds)));
        set(gca, 'YDir', 'normal');
        title('∂I_d/∂V_{ds} (1/r_o)');
        xlabel('V_{ds}'); ylabel('V_{gs}'); colorbar;
        hold on;
        plot(vds_max1, vgs_max1, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
        
        subplot(1,2,2);
        imagesc(vds, (vgs), (abs(dId_dVgs)));
        set(gca, 'YDir', 'normal');
        title('∂I_d/∂V_{gs} (g_m)');
        xlabel('V_{ds}'); ylabel('V_{gs}'); colorbar;
        hold on;
        plot(vds_max2, vgs_max2, 'go', 'MarkerSize', 10, 'LineWidth', 2);
        
        % Print maximum derivative values and locations
        fprintf('Max ∂I_d/∂V_{ds} at V_{ds} = %.4f, V_{gs} = %.4f, dI_d/dV_{ds} = %.4f\n', ...
                vgs_max1, vds_max1, dId_dVds(vgs_idx1, vds_idx1));
        fprintf('Max ∂I_d/∂V_{gs} at V_{ds} = %.4f, V_{gs} = %.4f, dI_d/dV_{gs} = %.4f\n', ...
                vgs_max2, vds_max2, dId_dVgs(vgs_idx2, vds_idx2));
    else
        % Analysis mode - return small-signal parameters with specified resolution
        
        % Set default values for optional parameters
        if isempty(vds_divisor)
            vds_divisor = 1;
        end
    
        if isempty(vgs_divisor)
            vgs_divisor = 1;
        end
    
        if isempty(max_vds)
            max_vds = 800;
        end

        % Calculate small-signal parameters
        g_m = dId_dVgs;          % Transconductance (S)
        r_o = 1 ./ dId_dVds;     % Output resistance (Ω)

        % Limit Vds range and adjust data matrices accordingly
        vds = vds(1, 1:min([length(vds(vds <= max_vds))+1 length(vds)]));
        id = id(:, 1:length(vds));
        g_m = g_m(:, 1:length(vds));
        r_o = r_o(:, 1:length(vds));
        
        % Apply resolution divisors for coarser sampling
        vds = vds(1, 1:vds_divisor:end);
        g_m = g_m(1:vgs_divisor:end, 1:vds_divisor:end);
        r_o = r_o(1:vgs_divisor:end, 1:vds_divisor:end);
        id = id(1:vgs_divisor:end, 1:vds_divisor:end);
        vgs = vgs(1:vgs_divisor:end, 1);
    end
end