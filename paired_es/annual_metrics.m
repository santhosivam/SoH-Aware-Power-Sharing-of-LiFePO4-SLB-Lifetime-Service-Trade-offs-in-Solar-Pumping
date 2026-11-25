function A = annual_metrics(RR)
A = cell(1, numel(RR));
for s = 1:numel(RR)
    R = RR{s}; y = ceil(R.yr - 1e-9); w = 365/R.nd; ny = max(y);
    a.year = (1:ny)'; a.util = zeros(ny,1); a.Eun = zeros(ny,1); a.Vol = zeros(ny,1);
    a.Ecurt = zeros(ny,1); a.Esrv = zeros(ny,1); a.SoHmin = zeros(ny,1); a.cap = zeros(ny,1);
    for k = 1:ny
        r = y == k;
        a.util(k) = mean(R.util(r)); a.Eun(k) = sum(R.Eun(r))*w; a.Vol(k) = sum(R.Vol(r))*w;
        a.Ecurt(k) = sum(R.Ecurt(r))*w; a.Esrv(k) = sum(R.Esrv(r))*w;
        a.SoHmin(k) = min(R.SoH(find(r, 1, 'last'), :)); a.cap(k) = sum(R.SoH(find(r, 1, 'last'), :));
    end
    A{s} = a;
end
end
