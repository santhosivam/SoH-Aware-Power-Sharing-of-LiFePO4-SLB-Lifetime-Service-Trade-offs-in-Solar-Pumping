function [Qw, Phyd] = pump_model(Psrv, P)
%#codegen
Phyd = P.etaPS*Psrv;
Qw = 0;
if Psrv >= P.pumpMin*P.Ppump && Phyd > 0
    rg = 1000*9.81;
    q = Phyd/(rg*P.Hs);
    for k = 1:30
        f  = rg*q*(P.Hs + P.kSys*q^2) - Phyd;
        df = rg*(P.Hs + 3*P.kSys*q^2);
        q  = q - f/df;
    end
    Qw = max(q, 0);
end
end
