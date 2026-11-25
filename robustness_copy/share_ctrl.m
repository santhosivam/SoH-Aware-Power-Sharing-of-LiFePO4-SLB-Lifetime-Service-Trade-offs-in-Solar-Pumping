function [Pbus, PpumpSrv, Pcurt] = share_ctrl(Ppv, PpumpReq, socHat, Pcorr, P)
%#codegen
Pbus = zeros(1,4);
PpumpSrv = PpumpReq;
Pcurt = 0;
socMaxV = P.socMax*ones(1,4);
if P.strategy == 3 && P.useSocCeiling
    phi = max(P.SoHhat - P.sohEol, 0.01);
    socMaxV = P.socMax - P.saCeil*(1 - phi/max(phi));
end
Pdem = PpumpReq - Ppv + Pcorr;
if Pdem > 0
    avail = socHat > P.socMin;
    w = share_weights(socHat, true, P).*avail;
    a = waterfill(Pdem, w, P.PportMax);
    short = Pdem - sum(a);
    if short > 1e-6
        PpumpSrv = max(PpumpReq - short, 0);
        if PpumpSrv < P.pumpMin*P.Ppump
            PpumpSrv = 0;
            Pdem = -Ppv + Pcorr;
            if Pdem > 0
                a = waterfill(Pdem, w, P.PportMax);
            else
                a = zeros(1,4);
            end
        end
    end
    if Pdem > 0
        Pbus = a;
    else
        Pdem = -Pdem;
        availC = socHat < socMaxV;
        wc = share_weights(socHat, false, P).*availC;
        ac = waterfill(Pdem, wc, P.PportMax);
        Pbus = -ac;
        Pcurt = Pdem - sum(ac);
    end
else
    Psur = -Pdem;
    availC = socHat < socMaxV;
    wc = share_weights(socHat, false, P).*availC;
    ac = waterfill(Psur, wc, P.PportMax);
    Pbus = -ac;
    Pcurt = Psur - sum(ac);
end
Pcurt = max(Pcurt, 0);
end
