function filtered_eeg = filter_data(raw_eeg)
%
% filter_data.m
%
% Instructions: Write a filter function to clean underlying data.
%               The filter type and parameters are up to you.
%               Points will be awarded for reasonable filter type,
%               parameters, and correct application. Please note there 
%               are many acceptable answers, but make sure you aren't 
%               throwing out crucial data or adversely distorting the 
%               underlying data!
%
% Input:    raw_eeg (samples x channels)
%
% Output:   clean_data (samples x channels)

fs = 1000; % sampling rate
n = 2; % fourth-order filter
Rp = 0.5; % ripple in the passband
Rs = 120; % attenuation in the stopband
Wp = [0.15, 200]/(fs/2); % normalized bandpass frequencies
[b, a] = ellip(n, Rp, Rs, Wp, 'bandpass');

filtered_eeg = zeros(size(raw_eeg)); % applied column wise
for i = 1:size(raw_eeg, 2)
    filtered_eeg(:, i) = filtfilt(b, a, raw_eeg(:, i));
end

% % Plotting code for filter testing in debugger
% Y = fft(raw_eeg(:, 1));
% L = size(raw_eeg, 1);
% P2 = abs(Y/L);
% P1 = P2(1:L/2+1);
% P1(2:end-1) = 2*P1(2:end-1);
% f = 1000*(0:(L/2))/L;
% figure; 
% subplot(1, 2, 1);
% plot(f, P1) 
% title('Single-Sided Amplitude Spectrum of X(t)')
% xlabel('f (Hz)')
% ylabel('|P1(f)|')
% 
% Y = fft(filtered_eeg(:, 1));
% L = size(filtered_eeg, 1);
% P2 = abs(Y/L);
% P1 = P2(1:L/2+1);
% P1(2:end-1) = 2 * P1(2:end-1);
% f = 1000 * (0:(L/2))/L;
% subplot(1, 2, 2);
% plot(f, P1) 
% title('Single-Sided Amplitude Spectrum of Filtered X(t)')
% xlabel('f (Hz)')
% ylabel('|P1(f)|')
    
end