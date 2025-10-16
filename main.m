% MAIN: Foot vs Idle (eyes-open + eyes-closed) on BCICIV_2a (Graz 2a)
% Features: FFT-based PSD (via calc_PSD) -> bandpowers (mu 8–12 Hz, beta 13–30 Hz)
% Classifier: LDA (subject-specific)
% Reports:
%   1) TRAIN metrics (fit & evaluate on full T-file)
%   2) CV metrics (5-fold stratified cross-validation on T-file)
%
% Saves outputs in: output/csv_outputs/
% Requires helpers: load_bci_gdf.m, extract_foot_and_rest.m, features_from_epochs.m,
%                   epoch_bandpowers.m, calc_PSD.m, calc_metrics.m

clear; clc; rng(42);   % reproducibility

dataDir = 'BCICIV_2a_gdf';        % contains A01T.gdf ... A09T.gdf
subjects = arrayfun(@(k) sprintf('A%02d', k), 1:9, 'UniformOutput', false);

% Settings
EEG_CH = 1:22;                     % 22 EEG channels (exclude EOG)
foot_epoch_sec = 4;                % 4 s after cue onset (2→6 s window)
bands = [8 12; 13 30];             % mu, beta (Hz)
dummy_win_sec = 1.0;               % kept for signature compatibility (unused in FFT path)
dummy_overlap = 0.5;               % kept for signature compatibility (unused in FFT path)
K = 5;                              % CV folds

% Create output directory if missing
outDir = fullfile('output', 'csv_outputs');
if ~exist(outDir, 'dir')
    mkdir(outDir);
    fprintf('Created output directory: %s\n', outDir);
end

% -------- Tables: one for TRAIN, one for CV --------
results_train = table('Size',[0 6], ...
    'VariableTypes',{'string','double','double','double','double','double'}, ...
    'VariableNames',{'Subject','Accuracy','Sensitivity','Specificity','F1_score','Precision'});

results_cv = table('Size',[0 7], ...
    'VariableTypes',{'string','double','double','double','double','double','double'}, ...
    'VariableNames',{'Subject','Accuracy','Sensitivity','Specificity','F1_score','Precision','Acc_SD'});

for s = 1:numel(subjects)
    sid = subjects{s};
    trainPath = fullfile(dataDir, [sid 'T.gdf']);

    if ~isfile(trainPath)
        warning('Missing TRAIN file: %s (skipping subject)', trainPath);
        continue;
    end

    fprintf('\n=== Subject %s ===\n', sid);

    % -------- Load & featureize TRAIN (T-file) --------
    [sigTr, hdrTr] = load_bci_gdf(trainPath);
    [epochsTr, yTr] = extract_foot_and_rest(sigTr, hdrTr, EEG_CH, foot_epoch_sec);

    if isempty(yTr) || numel(unique(yTr)) < 2
        fprintf('  Not enough labeled data/classes for %s -> skipping.\n', sid);
        continue;
    end

    XTr = features_from_epochs(epochsTr, hdrTr.SampleRate, bands, dummy_win_sec, dummy_overlap);

    % -------- TRAIN metrics (fit & eval on full TRAIN) --------
    mdl_full = fitcdiscr(XTr, yTr, 'DiscrimType','linear');
    yhatTr = predict(mdl_full, XTr);
    mTr = calc_metrics(yTr, yhatTr);

    fprintf('  TRAIN | Acc %.3f | F1 %.3f | Sens %.3f | Spec %.3f | Prec %.3f\n', ...
        mTr.Accuracy, mTr.F1_score, mTr.Sensitivity, mTr.Specificity, mTr.Precision);

    % Append TRAIN row
    results_train = [results_train; {sid, ...
        mTr.Accuracy, mTr.Sensitivity, mTr.Specificity, mTr.F1_score, mTr.Precision}]; %#ok<AGROW>

    % -------- CV metrics (5-fold stratified) --------
    cvp = cvpartition(yTr, 'KFold', K, 'Stratify', true);
    y_cv_true = []; y_cv_pred = [];
    acc_folds = nan(K,1);

    for f = 1:cvp.NumTestSets
        tr = training(cvp,f); te = test(cvp,f);

        ytr_f = yTr(tr);
        if numel(unique(ytr_f)) < 2
            fprintf('  CV fold %d skipped (single-class training set).\n', f);
            continue;
        end

        mdl_f = fitcdiscr(XTr(tr,:), ytr_f, 'DiscrimType','linear');
        yhat_f = predict(mdl_f, XTr(te,:));
        y_cv_true = [y_cv_true; yTr(te)]; %#ok<AGROW>
        y_cv_pred = [y_cv_pred; yhat_f];  %#ok<AGROW>
        acc_folds(f) = mean(yhat_f == yTr(te));
    end

    if isempty(y_cv_true)
        mCV = struct('Accuracy',nan,'Sensitivity',nan,'Specificity',nan,'F1_score',nan,'Precision',nan);
        acc_sd = nan;
        fprintf('  CV   | metrics NaN (insufficient valid folds)\n');
    else
        mCV = calc_metrics(y_cv_true, y_cv_pred);
        acc_sd = std(acc_folds, 'omitnan');
        fprintf('  CV    | Acc %.3f | F1 %.3f | Sens %.3f | Spec %.3f | Prec %.3f | Acc_SD %.3f\n', ...
            mCV.Accuracy, mCV.F1_score, mCV.Sensitivity, mCV.Specificity, mCV.Precision, acc_sd);
    end

    % Append CV row
    results_cv = [results_cv; {sid, ...
        mCV.Accuracy, mCV.Sensitivity, mCV.Specificity, mCV.F1_score, mCV.Precision, acc_sd}]; %#ok<AGROW>
end

% -------- Display Tables --------
disp(' ');
disp('TRAIN metrics (full fit on T-file):');
disp(results_train);

disp(' ');
disp('CV metrics (5-fold stratified on T-file; metrics from concatenated out-of-fold predictions):');
disp(results_cv);

% -------- Save Outputs --------
trainFile = fullfile(outDir, 'lda_train_only.csv');
cvFile    = fullfile(outDir, 'lda_cv_only.csv');

writetable(results_train, trainFile);
writetable(results_cv,    cvFile);

fprintf('\nSaved results to:\n  %s\n  %s\n', trainFile, cvFile);

% -------- Mean ± SD summaries --------
fprintf('\nTRAIN Mean ± SD over subjects:\n');
for j = 2:width(results_train)
    col = results_train{:,j};
    fprintf('  %s: %.3f ± %.3f\n', results_train.Properties.VariableNames{j}, ...
        mean(col,'omitnan'), std(col,'omitnan'));
end

fprintf('\nCV Mean ± SD over subjects:\n');
for j = 2:width(results_cv)-1
    col = results_cv{:,j};
    fprintf('  %s: %.3f ± %.3f\n', results_cv.Properties.VariableNames{j}, ...
        mean(col,'omitnan'), std(col,'omitnan'));
end
fprintf('  Acc_SD (mean over subjects): %.3f\n', mean(results_cv.Acc_SD,'omitnan'));
