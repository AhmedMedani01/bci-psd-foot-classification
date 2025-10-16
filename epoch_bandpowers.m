function feat = epoch_bandpowers(epochEEG, fs, bands, ~, ~)
% EPOCH_BANDPOWERS  Compute log bandpowers using calc_PSD (FFT formulation)
% Returns row vector: [channels * numBands].

    numCh = size(epochEEG,2);
    numBands = size(bands,1);
    feat = zeros(1, numCh * numBands);

    for ch = 1:numCh
        sig = epochEEG(:,ch);
        [PS, ~, freqR] = calc_PSD(sig);

        % Convert rad/sample to Hz
        freqHz = freqR * fs / (2*pi);

        % Only keep positive frequencies
        halfIdx = 1:floor(numel(freqHz)/2);
        freqHz = freqHz(halfIdx);
        PS = PS(halfIdx);

        % Compute bandpowers (trapz over PSD within band)
        bp = zeros(1,numBands);
        for b = 1:numBands
            f1 = bands(b,1); f2 = bands(b,2);
            idx = freqHz >= f1 & freqHz <= f2;
            bp(b) = trapz(freqHz(idx), PS(idx));
        end
        feat(1, (ch-1)*numBands + (1:numBands)) = log10(bp + eps);
    end
end
