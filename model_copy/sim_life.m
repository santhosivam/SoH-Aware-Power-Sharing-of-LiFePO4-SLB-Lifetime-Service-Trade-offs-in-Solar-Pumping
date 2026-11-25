function R = sim_life(P, C, o)
S.qcal = P.calSplit*(1 - P.SoH0);
S.qcyc = (1 - P.calSplit)*(1 - P.SoH0);
S.rinc = zeros(1,4); S.fec = zeros(1,4);
S.SoH  = 1 - S.qcal - S.qcyc; S.R0 = P.R00;
rs = RandStream('mt19937ar', 'Seed', o.seed);
days = 1:o.step:365; nd = numel(days);
nMax = o.Ymax*nd;
R.yr = zeros(nMax,1); R.SoH = zeros(nMax,4); R.R0 = zeros(nMax,4); R.SoHhat = zeros(nMax,4);
R.Esrv = zeros(nMax,1); R.Eun = zeros(nMax,1); R.Ereq = zeros(nMax,1); R.Ecurt = zeros(nMax,1);
R.Vol = zeros(nMax,1); R.Eloss = zeros(nMax,1); R.util = zeros(nMax,1); R.AhDis = zeros(nMax,4);
R.strand = zeros(nMax,1); R.Tmax = zeros(nMax,4); R.socMean = zeros(nMax,4);
R.Ipeak = zeros(nMax,4); R.Epv = zeros(nMax,1);
soc0 = 0.5*ones(1,4); T0 = (C.T(1) + P.dTcab)*ones(1,4);
k = 0; R.eolYear = NaN; tic;
for y = 1:o.Ymax
    for j = 1:nd
        d = days(j); k = k + 1;
        eS = rs.randn(1,4); eR = rs.randn(1,4); eC = rs.randn(1,4);
        P.SoH = S.SoH; P.R0 = S.R0;
        P.SoHhat  = min(max(S.SoH + o.sigSoH*eS, 0.3), 1.0);
        P.Rhat    = S.R0.*max(1 + o.sigR*eR, 0.2);
        P.socBias = o.sigSoC*eC;
        P.H = C.H(d); P.Tmean = C.T(d); P.Tamp = max((C.Tmax(d) - C.Tmin(d))/2, 0);
        P.tsr = C.tsr(d); P.L = C.L(d);
        P.soc0 = soc0; P.T0 = T0;
        if isfield(o, 'solverStep'), P.solverStep = o.solverStep; end
        D = run_day(P);
        soc0 = D.soc(end,:); T0 = D.T(end,:);
        Quse = S.SoH*P.Qrated*(P.socMax - P.socMin);
        R.util(k) = sum(D.AhDis)/sum(Quse);
        un = (D.Preq - D.Psrv) > 1;
        if any(un)
            i1 = find(un, 1);
            Vn = P.Ns*3.3;
            R.strand(k) = sum(max(D.soc(i1,:) - P.socMin, 0).*S.SoH*P.Qrated)*Vn/1000;
        end
        R.yr(k) = (y - 1) + j/nd;
        R.SoHhat(k,:) = P.SoHhat;
        R.Esrv(k) = D.Esrv; R.Eun(k) = D.Eunserved; R.Ereq(k) = D.Ereq; R.Ecurt(k) = D.Ecurt;
        R.Vol(k) = D.Vol; R.Eloss(k) = D.Eloss; R.AhDis(k,:) = D.AhDis;
        R.Tmax(k,:) = max(D.T); R.socMean(k,:) = mean(D.soc);
        R.Ipeak(k,:) = max(abs(D.I),[],1); R.Epv(k) = D.Epv;
        S = aging_step(S, D, P, 365/nd);
        R.SoH(k,:) = S.SoH; R.R0(k,:) = S.R0;
        if isnan(R.eolYear) && min(S.SoH) <= P.sohEol
            if k > 1
                m0 = min(R.SoH(k-1,:)); m1 = min(S.SoH);
                R.eolYear = R.yr(k-1) + (m0 - P.sohEol)/(m0 - m1)*(R.yr(k) - R.yr(k-1));
            else
                R.eolYear = R.yr(k);
            end
        end
        if isfield(o, 'stopImmediately') && o.stopImmediately && ~isnan(R.eolYear)
            break;
        end
    end
    if o.verbose, fprintf('strategy %d  year %d  minSoH %.4f  t=%.0fs\n', P.strategy, y, min(S.SoH), toc); end
    if o.stopAtEol && ~isnan(R.eolYear), break; end
end
f = fieldnames(R);
for q = 1:numel(f)
    if size(R.(f{q}),1) == nMax, R.(f{q}) = R.(f{q})(1:k,:); end
end
R.S = S; R.nd = nd; R.step = o.step;
end
