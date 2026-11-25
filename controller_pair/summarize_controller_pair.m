A = load('controller_pair_1.mat'); B = load('controller_pair_2.mat');
R1 = A.R; R2 = B.R;
assert(R1.nd == R2.nd);
n11 = 11*R1.nd;
nCommon = min(numel(R1.yr),numel(R2.yr));
T = table;
for h = 1:2
    if h == 1, n = n11; label = "11 complete years";
    else, n = nCommon; label = "to full-controller EOL"; end
    for j = 1:2
        if j == 1, R = R1; name = "fully enabled";
        else, R = R2; name = "without resistance weighting"; end
        assert(numel(R.yr) >= n);
        w = 365/R.nd;
        row = table(label,name,n,R.yr(n),R.eolYear, ...
            sum(R.Esrv(1:n))*w,sum(R.Eun(1:n))*w, ...
            sum(R.Ecurt(1:n))*w,sum(R.Eloss(1:n))*w, ...
            sum(R.Vol(1:n))*w,max(R.Tmax(1:n,:),[],1), ...
            max(R.Ipeak(1:n,:),[],1), ...
            'VariableNames',{'horizon','controller','simulatedDays','years', ...
            'eolYears','deliveredKWh','unservedKWh','curtailedKWh', ...
            'batteryLossKWh','waterM3','peakModuleC','peakCurrentA'});
        T = [T;row]; %#ok<AGROW>
    end
end
writetable(T,'controller_comparison.csv');
disp(T);
