function nyquist_saturation(G, fig_ny, fig_all)
% NYQUIST_SATURATION Analyze system stability with saturation nonlinearity using describing function
%
% This function performs Nyquist stability analysis for a system with saturation
% nonlinearity using the describing function method. It computes and plots the
% Nyquist plot of the linear system along with the negative reciprocal of the
% saturation describing function to determine limit cycle existence and stability.
%
% USAGE:
%   nyquist_saturation(G, fig_ny, fig_all)
%
% INPUTS:
%   G      - Linear transfer function object (tf)
%   fig_ny - Figure handle for Nyquist plot
%   fig_all- Figure handle for combined analysis plot
%
% SATURATION MODEL:
%   The saturation nonlinearity is modeled as:
%   y = min(max(x, L), U)
%   Where L = -4.98 (lower limit) and U = 21.98 (upper limit)
%
% DESCRIBING FUNCTION:
%   The describing function N(A) for saturation is computed using FFT analysis
%   of the fundamental harmonic component for different input amplitudes A.
%
% STABILITY ANALYSIS:
%   - Nyquist plot of linear system G(jω)
%   - Negative reciprocal of describing function -1/N(A)
%   - Intersections indicate potential limit cycles
%   - Stability determined by Nyquist criterion
%
% EXAMPLE:
%   % Analyze system with saturation
%   G = tf([1], [1 2 1]);
%   fig1 = figure; fig2 = figure;
%   nyquist_saturation(G, fig1, fig2);
%
% NOTES:
%   - Uses describing function method for nonlinear analysis
%   - Frequency range: 0.1 to 10^7 rad/s
%   - Amplitude range: 0 to 10*U for describing function
%   - Currently unused in main control loop analysis
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0
    % Parameters for saturation limits
    L = -4.98;
    U = 21.98;
    
    % Frequency range for Nyquist plot (rad/s)
    w = logspace(-1, 7, 50000);

    % Compute Nyquist data
    clf(fig_ny);figure(fig_ny);
    nyquist(G, w);
    [re, im] = nyquist(G, w);
    Gjw = squeeze(re + 1j*im);
    
    % Amplitude range for describing function computation
    A = linspace(0, 10*U, 50000); % amplitudes from just above saturation to 3x
    
    % Compute describing function for saturation for each amplitude A
    N = zeros(size(A));
    
    for k = 1:length(A)
        % Integrate over one period from 0 to 2pi numerically
        theta = linspace(0, 2*pi, 1000);
        x = A(k)*sin(theta);
        y = min(max(x, L), U); % saturation applied

        C = fft(y)/length(y);
        
        im_part = 2*real(C(2));   % a_n = 2*Re(C_n), n > 0
        re_part = -2*imag(C(2));  % b_n = -2*Im(C_n), n > 0
        % 
        % % Calculate fundamental component (complex)
        % re_part = (1/(pi*A(k))) * trapz(theta, y .* sin(theta));
        % im_part = -(1/(pi*A(k))) * trapz(theta, y .* cos(theta));
        N(k) = re_part + 1i*im_part;
    end
    
    % Plot setup
    clf(fig_all);figure(fig_all); hold on; grid on;
    title('Nyquist plot with Saturation Describing Function');
    xlabel('Real Axis');
    ylabel('Imaginary Axis');
    axis equal;
    
    % Plot Nyquist plot of linear system
    hG = plot(real(Gjw), imag(Gjw), 'b', 'LineWidth', 1.5);
    rowFreq = dataTipTextRow('Frequency', w);
    hG.DataTipTemplate.DataTipRows(end+1) = rowFreq;

    % Plot negative reciprocal of describing function (-1/N(A))
    hN = plot(real(-1./N), imag(-1./N), 'r', 'LineWidth', 1.5);
    rowAmp = dataTipTextRow('Amplitude', A);
    hN.DataTipTemplate.DataTipRows(end+1) = rowAmp;
    
    % === Find intersection between Nyquist curve and -1/N(A) ===
    G_points = Gjw(:);           % Column vector of complex Nyquist points
    N_points = -1./N(:);         % Column vector of describing function locus
    
    minDist = inf;   % start large
    best_k = NaN; 
    best_m = NaN;
    
    for k = 1:length(G_points)
        % Find the closest N_point to this G_point
        [d, m] = min(abs(G_points(k) - N_points));
        if d < minDist
            minDist = d;
            best_k = k;
            best_m = m;
        end
    end
    
    % Report results
    fprintf('Closest match:\n');
    fprintf('  Frequency (rad/s) for G: %.6g\n', w(best_k));
    fprintf('  Amplitude for N: %.6g\n', A(best_m));
    fprintf('  Complex point: %.6g + j%.6g\n', real(G_points(best_k)), imag(G_points(best_k)));
    
    % Highlight on plot
    plot(real(G_points(best_k)), imag(G_points(best_k)), 'ko', 'MarkerSize', 8, 'LineWidth', 2);


    legend('Nyquist plot of G(j\omega)', '-1/N(A) Describing function locus');

end