%% Final project part 1
% Prepared by John Bernabei and Brittany Scheid

% One of the oldest paradigms of BCI research is motor planning: predicting
% the movement of a limb using recordings from an ensemble of cells involved
% in motor control (usually in primary motor cortex, often called M1).

% This final project involves predicting finger flexion using intracranial EEG (ECoG) in three human
% subjects. The data and problem framing come from the 4th BCI Competition. For the details of the
% problem, experimental protocol, data, and evaluation, please see the original 4th BCI Competition
% documentation (included as separate document). The remainder of the current document discusses
% other aspects of the project relevant to BE521.


%% Start the necessary ieeg.org sessions 

clc; close all; clear;

cd('/Users/sppatankar/Developer/BE-521/')
base_path = '/Users/sppatankar/Developer/BE-521/';
addpath(genpath(fullfile(base_path, 'ieeg-matlab-1.14.49')))
addpath(genpath(fullfile(base_path, 'Project')))

username = 'spatank';
passPath = 'spa_ieeglogin.bin';

subj = 2; % change this depending on which subject is being processed

% % Load training ecog from each of three patients
% train_ecog = IEEGSession(sprintf('I521_Sub%d_Training_ecog', subj), ...
%     username, passPath);
% % Load training dataglove finger flexion values for each of three patients
% train_dg = IEEGSession(sprintf('I521_Sub%d_Training_dg', subj), ...
%     username, passPath);

clc; % remove the session loading warnings from IEEG
all_data = load('final_proj_part1_data.mat');

%% Extract dataglove and ECoG data 
% Dataglove should be (samples x 5) array 
% ECoG should be (samples x channels) array

ecog = all_data.train_ecog{subj};
dataglove = all_data.train_dg{subj};
% (1.1) There are 300000 samples in the raw recording.
% (1.2) The filter is a bandpass filter allowing signal in the range from
% 0.15 Hz to 200 Hz.

% % Split data into a train and test set (use at least 50% for training)

[m, n] = size(ecog);
P = 0.8; % percentage of training data
train_ecog = ecog(1:round(P * m), :);
train_dg = dataglove(1:round(P * m), :);
val_ecog = ecog(round(P * m) + 1:end, :);
val_dg = dataglove(round(P * m) + 1:end, :);

%% Get Features
% run getWindowedFeats function

fs = 1000; % hard code sample rate
window_length = 100/1000; % window size (s)
window_overlap = 50/1000; % window displacement (s)

% https://cs231n.github.io/convolutional-networks/
NumWins = @(xLen, fs, winLen, winDisp) ...
    ((xLen - (winLen * fs))/(winDisp * fs) + 1);
num_train_wins = ...
    NumWins(length(train_ecog(:, 1)), fs, window_length, window_overlap);
num_val_wins = ...
    NumWins(length(val_ecog(:, 1)), fs, window_length, window_overlap);

% create R matrix
R = getWindowedFeats(train_ecog, fs, window_length, window_overlap);

%% Train classifiers

% Classifier 1: Get angle predictions using optimal linear decoding. That is, 
% calculate the linear filter (i.e. the weights matrix) as defined by 
% Equation 1 for all 5 finger angles.

% Downsampling using means over windows for the dataglove signal
num_dg_channels = size(train_dg, 2);
Y_train = zeros(num_train_wins, num_dg_channels);
win_start_idx = 1;
for i = 1:num_train_wins
    win_end_idx = win_start_idx + (window_length * fs) - 1;
    curr_window = train_dg(win_start_idx:win_end_idx, :);
    Y_train(i, :) = mean(curr_window);
    win_start_idx = win_start_idx + (window_overlap * fs);
end

% Warland et al. (1997)
f = mldivide(R' * R, R' * Y_train);

Y_hat_train = R * f; 
% Upsample the predictions 
Y_hat_train_full = zeros(size(train_dg));
for channel = 1:num_dg_channels
    Y_hat_train_full(:, channel) = interp1(1:length(Y_hat_train(:, channel)), ...
        Y_hat_train(:, channel), ...
        linspace(1, length(Y_hat_train(:, channel)), size(train_dg, 1)), ...
        'pchip'); 
end
train_corrs = diag(corr(Y_hat_train_full, train_dg))


% % Alternative Model
% alt_models = struct([]);
% for channel = 1:num_dg_channels
%     Y_fing = Y_train(:, channel); % downsampled target values 
%     alt_models(channel).train_down_targets = Y_fing; % store downsampled target values
%     Y_fing_full = train_dg(:, channel); % target values
%     alt_models(channel).train_targets = Y_fing_full; % store target values
%     model = fitrensemble(R, Y_fing); % fit model; supply features and targets
%     alt_models(channel).model = model; % store model
%     Y_hat_train = predict(model, R); % generate downsampled predictions
%     alt_models(channel).train_down_preds = Y_hat_train; % store downsampled predictions
%     Y_hat_train_full = interp1(1:length(Y_hat_train), Y_hat_train, ...
%         linspace(1, length(Y_hat_train), size(train_dg, 1)), ...
%         'pchip'); % upsample the predictions
%     alt_models(channel).train_preds = Y_hat_train_full; % store downsampled predictions
%     alt_models(channel).train_corr = corr(Y_hat_train_full', train_dg(:, channel));
% end

%% Validate classifiers

R_val = getWindowedFeats(val_ecog, fs, window_length, window_overlap);

% Perform downsampling of targets
Y_val = zeros(num_val_wins, num_dg_channels);
win_start_idx = 1;
for i = 1:num_val_wins
    win_end_idx = win_start_idx + (window_length * fs) - 1;
    curr_window = val_dg(win_start_idx:win_end_idx, :);
    Y_val(i, :) = mean(curr_window);
    win_start_idx = win_start_idx + (window_overlap * fs);
end
    
Y_hat_val = R_val * f;
% Upsample the predictions 
Y_hat_val_full = zeros(size(val_dg));
for channel = 1:num_dg_channels
    Y_hat_val_full(:, channel) = interp1(1:length(Y_hat_val(:, channel)), ...
        Y_hat_val(:, channel), ...
        linspace(1, length(Y_hat_val(:, channel)), size(val_dg, 1)), ...
        'pchip'); 
end
val_corrs = diag(corr(Y_hat_val_full, val_dg))

% % Alternative Model
% for channel = 1:num_dg_channels
%     Y_fing = Y_val(:, channel); % downsampled target values 
%     alt_models(channel).val_down_targets = Y_fing; % store downsampled target values
%     Y_fing_full = val_dg(:, channel); % target values
%     alt_models(channel).val_targets = Y_fing_full; % store target values
%     Y_hat_val = predict(model, R_val); % generate downsampled predictions
%     alt_models(channel).val_down_preds = Y_hat_val; % store downsampled predictions
%     Y_hat_val_full = interp1(1:length(Y_hat_val), Y_hat_val, ...
%         linspace(1, length(Y_hat_val), size(val_dg, 1)), ...
%         'pchip'); % upsample the predictions
%     alt_models(channel).val_preds = Y_hat_val_full; % store downsampled predictions
%     alt_models(channel).val_corr = corr(Y_hat_val_full', val_dg(:, channel));
% end
