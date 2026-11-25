function S = aging_step(S, D, P, Ndays)
ag = P.ag; thor = Ndays*86400;
useRF = exist('rainflow', 'file') == 2;
for i = 1:4
    TK  = D.T(:,i) + 273.15;
    s   = D.soc(:,i);
    kTq = mean(ag.kTq*exp(-ag.EaQ/ag.Rgas*(1./TK - 1/ag.Tref)));
    kTr = mean(ag.kTr*exp(-ag.EaR/ag.Rgas*(1./TK - 1/ag.Tref)));
    kSq = mean(2.85750*(s - 0.5).^3 + 0.60225);
    kSr = mean(3.3903*(s - 0.5).^2 + 1.56040);
    kc  = kTq*kSq;
    teq = (S.qcal(i)/kc)^2;
    S.qcal(i) = S.qcal(i) + kc*(sqrt(teq + thor) - sqrt(teq));
    S.rinc(i) = S.rinc(i) + kTr*kSr*thor;
    fec = Ndays*D.AhAbs(i)/(2*P.Qrated);
    if fec > 1e-6
        if useRF
            c = rainflow(s);
            cnt = c(:,1); dep = c(:,2);
        else
            cnt = 1; dep = max(s) - min(s);
        end
        wgt = cnt.*dep;
        if sum(wgt) <= 0, wgt = ones(size(dep)); end
        kDq = sum((4.0253*(dep - 0.6).^3 + 1.09230).*wgt)/sum(wgt);
        kDr = sum((6.8477*(dep - 0.5).^3 + 0.91882).*wgt)/sum(wgt);
        Ia  = abs(D.I(:,i)); act = Ia > 0.01*P.Qrated;
        cr  = 0; if any(act), cr = mean(Ia(act))/P.Qrated; end
        kq  = kDq*(0.0971 + 0.063*cr);
        kr  = kDr*(0.0023 - 0.0018*cr);
        feq = (100*S.qcyc(i)/kq)^2;
        S.qcyc(i) = S.qcyc(i) + 0.01*kq*(sqrt(feq + fec) - sqrt(feq));
        S.rinc(i) = S.rinc(i) + 0.01*kr*fec;
        S.fec(i)  = S.fec(i) + fec;
    end
end
S.SoH = 1 - S.qcal - S.qcyc;
S.R0  = P.R00 + P.R0new*S.rinc;
end
