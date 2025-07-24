function [g_m, r_o, vds, vgs, id] = drain_curves(~)
    persistent vds_loaded;
    persistent vgs_loaded;
    persistent id_loaded;

    if isempty(id_loaded)
        % Step 1: Load CSV data. It is formatter so that the first row, excluding
        % the frist cell are the vds values and the first column, excluding the top
        % cell is the vgs values
        data = readmatrix('MSC025SMA120B4/MSC025SMA120B4_drain_curves_2d.csv');
        vds_loaded = data(1,2:end);
        vgs_loaded = data(2:end,1);
        id_loaded  = data(2:end,2:end);
        
        % vds = vds(vds <= 60);
    
        id_loaded = id_loaded(:, 1:length(vds_loaded));
    end

    vds = vds_loaded;
    vgs = vgs_loaded;
    id = id_loaded;

    % Step 4: Compute finite differences
    [dId_dVds, dId_dVgs] = gradient(id, vds, vgs);
    
    if ~nargin
        
        max_id = 6;

        % Step 5: Find max derivative points
        [~, idx_dVds] = max(abs(dId_dVds(:)));
        [vgs_idx1, vds_idx1] = ind2sub(size(id), idx_dVds);
        vds_max1 = vds(vds_idx1);
        vgs_max1 = vgs(vgs_idx1);
        
        [~, idx_dVgs] = max(abs(dId_dVgs(:)));
        [vgs_idx2, vds_idx2] = ind2sub(size(id), idx_dVgs);
        vds_max2 = vds(vds_idx2);
        vgs_max2 = vgs(vgs_idx2);

        % Step 6: Create mesh for plotting
        [VDS, VGS] = meshgrid(vds, vgs);

        % Step 7: Plot the original Id surface
        figure;
        surf(VGS, VDS, id, 'EdgeColor', 'none');
        set(gca, 'XDir', 'reverse');
        xlabel('V_{gs}'); ylabel('V_{ds}'); zlabel('I_d');
        title('I_d(V_{gs}, V_{ds})');
        view(45,30); colorbar;
        hold on;
        plot3(vgs_max1, vds_max1, id(vgs_idx1, vds_idx1), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
        plot3(vgs_max2, vds_max2, id(vgs_idx2, vds_idx2), 'go', 'MarkerSize', 10, 'LineWidth', 2);
        contour3(VGS, VDS, id, [max_id, max_id], 'r', 'LineWidth', 2);
        legend('I_d Surface', 'Max ∂I_d/∂V_{ds}', 'Max ∂I_d/∂V_{gs}');
        
        % Step 8: Visualize derivative magnitudes
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
        
        % Step 9: Print result
        fprintf('Max ∂I_d/∂V_{ds} at V_{ds} = %.4f, V_{gs} = %.4f, dI_d/dV_{ds} = %.4f\n', ...
                vgs_max1, vds_max1, dId_dVds(vgs_idx1, vds_idx1));
        fprintf('Max ∂I_d/∂V_{gs} at V_{ds} = %.4f, V_{gs} = %.4f, dI_d/dV_{gs} = %.4f\n', ...
                vgs_max2, vds_max2, dId_dVgs(vgs_idx2, vds_idx2));
    else
        g_m = dId_dVgs;
        r_o = 1 ./ dId_dVds;
    end
end