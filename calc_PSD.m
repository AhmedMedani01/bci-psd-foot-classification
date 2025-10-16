function [PS, feats, freqR] = calc_PSD(RF)

RF(isnan(RF)) = 9999;
Nr=length(RF);
xdftR = fft(RF);
TR=1/(2*pi*Nr)*abs(xdftR).^2;

feats = [std(xdftR'); var(xdftR'); rms(xdftR'); sum(abs(xdftR'))];  %#ok
freqR=0:(2*pi)/Nr:2*pi-(2*pi)/Nr;
% plot(freqR/pi,10*log10(TR))
% PS= reshape(TR.',[],1);
PS = TR;

end