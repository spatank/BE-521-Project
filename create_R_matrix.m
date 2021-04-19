function [R] = create_R_matrix(features, N_wind)
%
% create_R_matrix.m
%
% Instructions: Write a function to calculate R matrix.             
%
% Input:    features:   (samples x (channels * features))
%           N_wind:     Number of windows to use
%
% Output:   R:          (samples x (N_wind * channels * features))

% Your code here (5 points)
samples = size(features, 1);
num_raw_features = size(features, 2);
num_features = N_wind * num_raw_features;
R = NaN(samples, num_features,size(features,3));

features_augmented = cat(1,features(1:N_wind-1, :,:), features);
for iter=1:size(features,3)
    for i = 1:samples
        prev_idx_vec = i:i+N_wind-1;
        prev_window_feats = zeros(num_raw_features, N_wind);
        for j = 1:length(prev_idx_vec)
            prev_idx = prev_idx_vec(j);
            prev_window_feats(:, j) = features_augmented(prev_idx,:,iter);
        end
        R(i, :, iter) = prev_window_feats(:);
    end
end
R = cat(2,ones(size(R, 1), 1,size(R,3)), R);

end