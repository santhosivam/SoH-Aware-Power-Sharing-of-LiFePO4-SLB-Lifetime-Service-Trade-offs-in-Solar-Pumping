S = load('climate.mat'); C = S.C;
P0 = mpc_params; P0.solverStep = 15;
[~,iMinH] = min(C.H); [~,iMaxH] = max(C.H);
[~,iMinT] = min(C.T); [~,iMaxT] = max(C.T);
days = unique([1 iMinH iMaxH iMinT iMaxT 365]);
T = table;
for strategy = [1 3]
    for j = 1:numel(days)
        d = days(j); P = P0; P.strategy = strategy;
        P.SoH = P.SoH0; P.R0 = P.R00;
        P.SoHhat = P.SoH; P.Rhat = P.R0; P.socBias = zeros(1,4);
        P.H = C.H(d); P.Tmean = C.T(d);
        P.Tamp = max((C.Tmax(d)-C.Tmin(d))/2,0);
        P.tsr = C.tsr(d); P.L = C.L(d);
        P.T0 = (C.T(d)+P.dTcab)*ones(1,4);
        D = run_day(P);
        Pb = D.I.*D.Vt;
        PbusAct = zeros(size(Pb));
        pos = Pb >= 0;
        PbusAct(pos) = Pb(pos)*P.etaPort;
        PbusAct(~pos) = Pb(~pos)/P.etaPort;
        pIn = D.Ppv-D.Pcurt+sum(PbusAct,2)-D.Psrv;
        integratedKWh = trapz(D.t,pIn)/3.6e6;
        deltaBusKWh = 0.5*P.Cbus*(D.Vdc(end)^2-D.Vdc(1)^2)/3.6e6;
        residualKWh = integratedKWh-deltaBusKWh;
        scaleKWh = max(D.Epv+D.Esrv,1);
        row = table(strategy,d,D.Epv,D.Ecurt,D.Ereq,D.Esrv,D.Eunserved, ...
            D.Eloss,deltaBusKWh,residualKWh,abs(residualKWh)/scaleKWh, ...
            max(abs(D.Vdc-P.Vref)), ...
            'VariableNames',{'strategy','day','pvKWh','curtailedKWh','demandKWh', ...
            'servedKWh','unservedKWh','batteryLossKWh','busDeltaKWh', ...
            'busResidualKWh','relativeBusResidual','maxBusErrorV'});
        T = [T;row]; %#ok<AGROW>
    end
end
writetable(T,'energy_balance_checks.csv');
disp(T);
