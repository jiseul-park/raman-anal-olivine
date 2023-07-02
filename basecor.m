function [w, bgd, rmse] = basecor(y, lambda, ratio)
N = length(y); 
D = diff(speye(N),2);
H = lambda*D'*D;
w = ones(N,1);
while true
    W = spdiags(w, 0, N, N);
    % Cholesky decomposition
    C = chol(W + H);
    bgd = C \ (C'\(w.*y));
    d = y-bgd;
    % make d-, and get w^t with m and s
    dn = d(d<0);
    m = mean(dn);
    s = std(dn);
    wt = 1./ (1+exp(2* (d-(2*s-m))/s));
    % check exit condition and backup
    if norm(w-wt)/norm(w) < ratio, break;
    end
    w = wt;
    rmse = sqrt(sum((y-bgd).^2)/N);
end
