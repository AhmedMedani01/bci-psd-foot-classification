function metrics = calc_metrics(y_true, y_pred)
% CALC_METRICS  Compute Accuracy, Sensitivity, Specificity, F1, Precision
% for binary classification (0 = Rest, 1 = Foot).

    cm = confusionmat(y_true, y_pred);
    % Handle possible missing classes
    if size(cm,1) < 2
        cm = [cm, 0; 0, 0];
    end

    TP = cm(2,2);
    TN = cm(1,1);
    FP = cm(1,2);
    FN = cm(2,1);

    metrics.Accuracy     = (TP + TN) / sum(cm(:));
    metrics.Sensitivity  = TP / (TP + FN + eps);  % recall
    metrics.Specificity  = TN / (TN + FP + eps);
    metrics.Precision    = TP / (TP + FP + eps);
    metrics.F1_score     = 2 * (metrics.Precision * metrics.Sensitivity) / ...
                                (metrics.Precision + metrics.Sensitivity + eps);
end
