function [all_feats] = getWindowedFeats(raw_data, fs, window_length, window_overlap)
    %
    % getWindowedFeats_release.m
    %
    % Instructions: Write a function which processes data through the steps
    %               of filtering, feature calculation, creation of R matrix
    %               and returns features.
    %
    %               Points will be awarded for completing each step
    %               appropriately (note that if one of the functions you call
    %               within this script returns a bad output you won't be double
    %               penalized)
    %
    %               Note that you will need to run the filter_data and
    %               get_features functions within this script. We also 
    %               recommend applying the create_R_matrix function here
    %               too.
    %
    % Inputs:   raw_data:       The raw data for all patients
    %           fs:             The raw sampling frequency
    %           window_length:  The length of window
    %           window_overlap: The overlap in window
    %
    % Output:   all_feats:      All calculated features
    %

% Your code here (3 points)

% First, filter the raw data
filtered_data = filter_data(raw_data);

NumWins = @(xLen, fs, winLen, winDisp) ...
    ((xLen - (winLen * fs))/(winDisp * fs) + 1);
num_wins = ...
    NumWins(length(filtered_data(:, 1)), fs, window_length, window_overlap);
% Then, loop through sliding windows
num_channels = size(filtered_data, 2);
num_features = 6;
features = zeros(num_wins, (num_channels * num_features));
win_start_idx = 1;
for i = 1:num_wins
    % Within loop calculate feature for each segment (call get_features)
    win_end_idx = win_start_idx + (window_length * fs) - 1;
    % curr_window is (window_length * fs) x channels in size
    curr_window = filtered_data(win_start_idx:win_end_idx, :);
    % output of get_features should be (1 x (channels * features))
    features(i, :) = get_features(curr_window, fs);
    win_start_idx = win_start_idx + (window_overlap * fs);
end
    
% Finally, return feature matrix
N_wind = 5;
all_feats = create_R_matrix(features, N_wind);

end