function [features] = get_features(clean_data, fs)
%
% get_features.m
%
% Instructions: Write a function to calculate features.
%               Please create 4 OR MORE different features for each channel.
%               Some of these features can be of the same type (for example, 
%               power in different frequency bands, etc) but you should
%               have at least 2 different types of features as well
%               (Such as frequency dependent, signal morphology, etc.)
%               Feel free to use features you have seen before in this
%               class, features that have been used in the literature
%               for similar problems, or design your own!
%
% Input:    clean_data: (samples x channels)
%           fs:         sampling frequency
%
% Output:   features:   (1 x (channels * features))

% Your code here (8 points)

num_channels = size(clean_data, 2);

num_features = 6;

% LLFn = @(x) sum(abs(diff(x)));
% areaFn = @(x) sum(abs(x));
% energyFn = @(x) sum(x.^2);

features = zeros(num_channels, num_features);

for channel = 1:num_channels
    signal = clean_data(:, channel);
    features(channel, 1) = bandpower(signal, fs, [5, 15]);
    features(channel, 2) = bandpower(signal, fs, [20, 25]);
    features(channel, 3) = bandpower(signal, fs, [75, 115]);
    features(channel, 4) = bandpower(signal, fs, [125, 160]);
    features(channel, 5) = bandpower(signal, fs, [160, 175]);
    features(channel, 6) = mean(signal);
%     features(channel, 7) = LLFn(signal);
%     features(channel, 8) = areaFn(signal);
%     features(channel, 9) = energyFn(signal);
end

features = features(:);

end

