%% Final project part 2
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

subj = 3; % change this depending on which subject is being processed

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
dataglove = smoothdata(dataglove, 'movmean', 200);
% (1.1) There are 300000 samples in the raw recording.
% (1.2) The filter is a bandpass filter allowing signal in the range from
% 0.15 Hz to 200 Hz.

% % Split data into a train and test set (use at least 50% for training)

[m, n] = size(ecog);
P = 1; % percentage of training data
train_ecog = ecog(1:round(P * m), :);
train_dg = dataglove(1:round(P * m), :);
% val_ecog = ecog(round(P * m) + 1:end, :);
% val_dg = dataglove(round(P * m) + 1:end, :);

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
% num_val_wins = ...
%     NumWins(length(val_ecog(:, 1)), fs, window_length, window_overlap);

% create R matrices
R_train = getWindowedFeats(train_ecog, fs, window_length, window_overlap);
% R_val = getWindowedFeats(val_ecog, fs, window_length, window_overlap);

%% Train classifiers

clc; close all;
% clearvars -except train_ecog train_dg val_ecog val_dg ...
%     num_train_wins num_val_wins R_train R_val

% Classifier 1: Get angle predictions using optimal linear decoding. That is, 
% calculate the linear filter (i.e. the weights matrix) as defined by 
% Equation 1 for all 5 finger angles.

num_dg_channels = size(train_dg, 2);

% Perform downsampling 
Y_train = zeros(num_train_wins, num_dg_channels);
for i = 1:num_dg_channels
    downsampled = decimate(train_dg(:, i), 50);
    downsampled(end) = []; % adjust window sizes
    Y_train(:, i) = downsampled';
end

% % Warland et al. (1997)
% f = pinv(R_train' * R_train) * (R_train' * Y_train);
% 
% Y_hat_train = R_train * f; 
% % Upsample the predictions 
% Y_hat_train_full = zeros(size(train_dg));
% for channel = 1:num_dg_channels
%     Y_hat_train_full(:, channel) = interp1(1:length(Y_hat_train(:, channel)), ...
%         Y_hat_train(:, channel), ...
%         linspace(1, length(Y_hat_train(:, channel)), size(train_dg, 1)), ...
%         'pchip'); 
% end
% train_corrs = diag(corr(Y_hat_train_full, train_dg))

% Alternative Model
alt_models = struct([]);
Y_hat_train_full = zeros(size(train_dg));
for channel = 1:num_dg_channels
    fprintf('Channel %d model training.\n', channel);
    Y_fing = Y_train(:, channel); % downsampled target values 
%     model = fitlm(R_train, Y_fing); % fit model; supply features and targets
%     model = fitrlinear(R_train, Y_fing);
    [B, FitInfo] = lasso(R_train, Y_fing, 'Alpha', 1);
    [~, idx_min] = min(FitInfo.MSE);
    coef = B(:, idx_min);
    coef0 = FitInfo.Intercept(idx_min);
    model.coef = coef;
    model.coef0 = coef0;
    alt_models(channel).channel_model = model; % store model
%     Y_hat_train = predict(model, R_train); % generate downsampled predictions
    Y_hat_train = R_train * coef + coef0;
    Y_hat_train_full(:, channel) = interp1(1:length(Y_hat_train), Y_hat_train, ...
        linspace(1, length(Y_hat_train), size(train_dg, 1)), ...
        'pchip'); % upsample the predictions
    alt_models(channel).train_corr = corr(Y_hat_train_full(:, channel), ...
        train_dg(:, channel));
end

% %% Validate classifiers
% 
% % Perform downsampling of targets
% Y_val = zeros(num_val_wins, num_dg_channels);
% for i = 1:num_dg_channels
%     downsampled = decimate(val_dg(:, i), 50);
%     downsampled(end) = []; % adjust window sizes
%     Y_val(:, i) = downsampled';
% end
% 
% % Y_hat_val = R_val * f;
% % % Upsample the predictions 
% % Y_hat_val_full = zeros(size(val_dg));
% % for channel = 1:num_dg_channels
% %     Y_hat_val_full(:, channel) = interp1(1:length(Y_hat_val(:, channel)), ...
% %         Y_hat_val(:, channel), ...
% %         linspace(1, length(Y_hat_val(:, channel)), size(val_dg, 1)), ...
% %         'pchip'); 
% % end
% % val_corrs = diag(corr(Y_hat_val_full, val_dg))
% 
% % Alternative Model
% Y_hat_val_full = zeros(size(val_dg));
% for channel = 1:num_dg_channels
%     fprintf('Channel %d model testing.\n', channel);
%     Y_fing = Y_val(:, channel); % downsampled target values 
%     model = alt_models(channel).channel_model; % get trained model
% %     Y_hat_val = predict(model, R_val); % generate downsampled predictions
%     Y_hat_val = R_val * model.coef + model.coef0;
%     Y_hat_val_full(:, channel) = interp1(1:length(Y_hat_val), Y_hat_val, ...
%         linspace(1, length(Y_hat_val), size(val_dg, 1)), ...
%         'pchip'); % upsample the predictions
%     alt_models(channel).val_corr = corr(Y_hat_val_full(:, channel), val_dg(:, channel));
% end

% %% Post-processing
% 
% close all;
% 
% figure;
% hold on
% plot(1:150000, train_dg(1:150000, 1), 'r')
% plot(1:150000, Y_hat_train_full(1:150000, 1), 'b')
% hold off
% legend('True', 'Prediction');
%
% figure;
% hold on
% plot(1:60000, val_dg(1:60000, 1), 'r')
% plot(1:60000, Y_hat_val_full(1:60000, 1), 'b')
% hold off
% legend('True', 'Prediction');
% 
% ks = 1000:3000;
% corrs_store = zeros(1, length(ks));
% for i = 1:length(ks)
%     k = ks(i);
%     test_2 = smoothdata(Y_hat_val_full, 'movmean', k);
%     corrs_store(i) = mean(diag(corr(test_2, val_dg)));
% end
% 
% figure;
% plot(ks, corrs_store)

