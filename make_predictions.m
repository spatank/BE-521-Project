function [predicted_dg] = make_predictions(test_ecog)

% INPUTS: test_ecog - 3 x 1 cell array containing ECoG for each subject, where test_ecog{i} 
% to the ECoG for subject i. Each cell element contains a N x M testing ECoG,
% where N is the number of samples and M is the number of EEG channels.

% OUTPUTS: predicted_dg - 3 x 1 cell array, where predicted_dg{i} contains the 
% data_glove prediction for subject i, which is an N x 5 matrix (for
% fingers 1:5)

% Run time: The script has to run less than 1 hour. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
num_subjects = length(test_ecog);

predicted_dg = cell(3, 1);

fs = 1000; % hard code the sample rate
window_length = 100/1000; % window size (s)
window_overlap = 50/1000; % window displacement (s)

for i = 1:num_subjects
    subj_test_ecog = test_ecog{i};
    if i == 1 % channel removed from subject 1
        subj_test_ecog(:, 61) = [];
    end
    if i == 2 % channels removed from subject 2
        subj_test_ecog(:, 21) = [];
        subj_test_ecog(:, 38) = [];
    end
    % create R matrix
    R = getWindowedFeats(subj_test_ecog, fs, window_length, window_overlap);
    load(sprintf('/Users/sppatankar/Developer/BE-521/Project/Data/f_subj_%d.mat', i), 'f')
    fprintf('Subject %d processing.\n', i);
    Y_hat_test = R * f; 
    num_dg_channels = size(Y_hat_test, 2); 
    % Upsample the predictions in each window
    Y_hat_test_full = zeros(size(subj_test_ecog, 1), num_dg_channels);
    for channel = 1:num_dg_channels
        Y_hat_test_full(:, channel) = interp1(1:length(Y_hat_test(:, channel)), ...
            Y_hat_test(:, channel), ...
            linspace(1, length(Y_hat_test(:, channel)), size(subj_test_ecog, 1)), ...
            'pchip'); 
    end
    predicted_dg{i} = Y_hat_test_full;
end





end

