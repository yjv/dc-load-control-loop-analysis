% FOURIER_COEFFS Calculate Fourier series coefficients for periodic signals
%
% This script demonstrates how to calculate Fourier series coefficients for
% periodic signals using the FFT algorithm. It computes the DC component (a0)
% and harmonic coefficients (an, bn) for the first M harmonics of a periodic
% signal defined over one period.
%
% USAGE:
%   Run as a script - modify the signal definition and parameters as needed
%
% PARAMETERS:
%   N - Number of sample points (should be large for accuracy)
%   T - Period of the function (seconds)
%   M - Number of harmonics to compute
%   x - Periodic signal definition
%
% OUTPUTS:
%   a0 - DC component (constant term)
%   an - Cosine coefficients for harmonics 1 to M
%   bn - Sine coefficients for harmonics 1 to M
%
% EXAMPLE:
%   % Default signal: x = cos(2*pi*3*t) (3 Hz cosine)
%   % Modify line 8 to define your periodic signal
%
% NOTES:
%   - Uses FFT for efficient computation of Fourier coefficients
%   - Signal is sampled over one period with N+1 points
%   - Reconstructs signal using Fourier series for verification
%   - Includes signal limiting example (clipping between -0.2 and 0.7)
%
% Author: Yosef Deray
% Date: 2025
% Version: 1.0

% Sample a periodic signal over one period
N = 10000;                   % Number of sample points (should be large)
T = 1;                      % Period of the function
t = linspace(0, T, N+1);    % Time vector for one period; N+1 returns to t=0
t(end) = [];                % Remove duplicate endpoint

% Define your function here, e.g. f(t) = cos(2*pi*3*t) + 0.5*sin(2*pi*5*t)
x = cos(2*pi*3*t);

% Compute the complex Fourier coefficients
C = fft(max(min(x, 0.7), -0.2))/(N+1);

% For plotting, the FFT output is ordered from index 1 (DC), then positive frequencies,
% then negative frequencies at the end
% If you want zero-frequency in the center:
%C = fftshift(C);

% Number of harmonics desired (up to floor(N/2) for most signals)
M = 100;   % for the first M harmonics

% Extract the a0 coefficient (DC component)
a0 = real(C(1));

% Preallocate arrays
an = zeros(1, M);
bn = zeros(1, M);

x_fft = repmat(a0, 1, length(t));

% Calculate an and bn from the complex coefficients
for n = 1:M
    if n+1 <= N    % MATLAB indices: 1-based, and FFT(k) corresponds to frequency k-1
        an(n) = 2*real(C(n+1));   % a_n = 2*Re(C_n), n > 0
        bn(n) = -2*imag(C(n+1));  % b_n = -2*Im(C_n), n > 0
        x_fft = x_fft + an(n)*cos(2*pi*n*t) + bn(n)*sin(2*pi*n*t);
    end
end

% Output
disp('a0:'); disp(a0);
disp('an:'); disp(an);
disp('bn:'); disp(bn);

plot(2*pi*t, x, 2*pi*t, x_fft);
