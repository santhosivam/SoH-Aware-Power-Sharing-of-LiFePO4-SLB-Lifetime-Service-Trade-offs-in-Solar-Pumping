S = load('climate.mat'); C = S.C;
[~,a] = min(C.H); [~,b] = max(C.H);
[~,c] = min(C.T); [~,d] = max(C.T);
idx = unique([a b c d]);
T = table;
for day = idx
    for strategy = [1 3]
        P = mpc_params; P.strategy = strategy;
        P.H = C.H(day); P.Tmean = C.T(day);
        P.Tamp = max((C.Tmax(day)-C.Tmin(day))/2,0);
        P.tsr = C.tsr(day); P.L = C.L(day);
        P.T0 = (C.T(day)+P.dTcab)*ones(1,4);
        D5 = run_day(P);
        P.solverStep = 15;
        D15 = run_day(P);
        row = table(day,strategy,C.H(day),C.T(day), ...
            min(D15.Vdc),max(D15.Vdc), ...
            D15.Esrv-D5.Esrv,D15.Eunserved-D5.Eunserved, ...
            max(abs(D15.soc(end,:)-D5.soc(end,:))), ...
            'VariableNames',{'day','strategy','GHI','airC', ...
            'minBusV','maxBusV','deltaServedKWh','deltaUnservedKWh', ...
            'maxEndSoCDifference'});
        T = [T; row]; %#ok<AGROW>
        writetable(T,'solver15_stress_check.csv');
        fprintf('stress day %d strategy %d Vdc [%.2f %.2f] dSoC %.6f\n', ...
            day,strategy,row.minBusV,row.maxBusV,row.maxEndSoCDifference);
    end
end
