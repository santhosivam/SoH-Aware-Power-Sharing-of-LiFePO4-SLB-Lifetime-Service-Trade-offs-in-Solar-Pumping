S = load('climate.mat'); C = S.C;
Sref = load(fullfile(fileparts(fileparts(mfilename('fullpath'))),'reference','results_daily.mat'));
DDref = Sref.DD;
d = DDref{1}.day;
for step = [10 30 60]
    for s = [1 3]
        P = mpc_params; P.strategy = s; P.solverStep = step;
        P.H = C.H(d); P.Tmean = C.T(d);
        P.Tamp = (C.Tmax(d)-C.Tmin(d))/2;
        P.tsr = C.tsr(d); P.L = C.L(d);
        P.soc0 = 0.5*ones(1,4);
        P.T0 = (C.T(d)+P.dTcab)*ones(1,4);
        for k = 1:4
            D = run_day(P);
            P.soc0 = D.soc(end,:); P.T0 = D.T(end,:);
        end
        ref = DDref{s};
        fprintf('step=%d s=%d dEsrv=%.5f dEun=%.5f dEpv=%.5f dVol=%.5f maxEndSoC=%.5f dTmax=%.5f VdcRange=[%.2f %.2f]\n', ...
            step,s,D.Esrv-ref.Esrv,D.Eunserved-ref.Eunserved, ...
            D.Epv-ref.Epv,D.Vol-ref.Vol, ...
            max(abs(D.soc(end,:)-ref.soc(end,:))), ...
            max(D.T(:))-max(ref.T(:)),min(D.Vdc),max(D.Vdc));
    end
end
