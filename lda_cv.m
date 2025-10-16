function [meanAcc, stdAcc] = lda_cv(X, y, K)
% LDA_CV  K-fold stratified CV with linear discriminant analysis.

    if nargin < 3, K = 5; end
    cv = cvpartition(y, 'KFold', K, 'Stratify', true);
    acc = zeros(K,1);

    for f = 1:K
        tr = training(cv,f); te = test(cv,f);
        Mdl = fitcdiscr(X(tr,:), y(tr), 'DiscrimType','linear');
        yhat = predict(Mdl, X(te,:));
        acc(f) = mean(yhat == y(te));
    end
    meanAcc = mean(acc);
    stdAcc  = std(acc);
end
