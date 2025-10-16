function X = features_from_epochs(epochs, fs, bands, win_sec, overlap)
% FEATURES_FROM_EPOCHS  Welch PSD bandpowers per channel, log-scaled.
% epochs: cell of [T x channels]; bands: [B x 2] in Hz.

    X = zeros(numel(epochs), numel(epochs{1}(1,:)) * size(bands,1));
    for i = 1:numel(epochs)
        X(i,:) = epoch_bandpowers(epochs{i}, fs, bands, win_sec, overlap);
    end
end
