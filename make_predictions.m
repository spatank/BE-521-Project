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
    fprintf('Subject %d processing.\n', i);
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
    load(sprintf('/Users/sppatankar/Developer/BE-521/Project/alt_models_subj_%d.mat', i), 'alt_models')
    num_dg_channels = 5;
    Y_hat_test_full = zeros(size(subj_test_ecog, 1), num_dg_channels);
    for channel = 1:num_dg_channels
        model = alt_models(channel).channel_model; % get trained model
        Y_hat_test_channel = R * model.coef + model.coef0;
        Y_hat_test_full(:, channel) = interp1(1:length(Y_hat_test_channel), Y_hat_test_channel, ...
            linspace(1, length(Y_hat_test_channel), size(subj_test_ecog, 1)), ...
            'pchip'); % upsample the predictions
    end
    if i == 1
        predicted_dg{i} = smoothdata(Y_hat_test_full, 'movmean', 2700);
    end
    if i == 2 
        predicted_dg{i} = smoothdata(Y_hat_test_full, 'movmean', 2100);
    end
    if i == 3 
        predicted_dg{i} = smoothdata(Y_hat_test_full, 'movmean', 1830);
    end
end





end

