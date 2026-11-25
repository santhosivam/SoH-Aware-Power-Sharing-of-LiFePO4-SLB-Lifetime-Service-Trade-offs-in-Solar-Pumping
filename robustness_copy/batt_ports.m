function [dsoc, dvrc, dT, I, Vt, PbusAct, Ploss] = batt_ports(Pbus, soc, vrc, T, Tamb, P)
%#codegen
dsoc = zeros(1,4); dvrc = zeros(1,4); dT = zeros(1,4);
I = zeros(1,4); Vt = zeros(1,4); PbusAct = zeros(1,4); Ploss = 0;
for i = 1:4
    Q   = P.SoH(i)*P.Qrated;
    R0  = P.R0(i);
    R1  = P.R1frac*R0;
    C1  = P.tau/R1;
    s   = min(max(soc(i), 0), 1);
    ocv = P.Ns*interp1(P.socTab, P.ocvTab, s);
    if Pbus(i) >= 0
        Pb = Pbus(i)/P.etaPort;
    else
        Pb = Pbus(i)*P.etaPort;
    end
    Veff = ocv - vrc(i);
    disc = Veff^2 - 4*R0*Pb;
    if disc < 0
        Pb = 0.99*Veff^2/(4*R0);
        disc = Veff^2 - 4*R0*Pb;
    end
    Ii = (Veff - sqrt(disc))/(2*R0);
    if (soc(i) <= P.socHardMin && Ii > 0) || (soc(i) >= P.socHardMax && Ii < 0)
        Ii = 0; Pb = 0;
    end
    if Pb >= 0
        PbusAct(i) = Pb*P.etaPort;
    else
        PbusAct(i) = Pb/P.etaPort;
    end
    I(i)    = Ii;
    Vt(i)   = Veff - Ii*R0;
    dsoc(i) = -Ii/(3600*Q);
    dvrc(i) = -vrc(i)/(R1*C1) + Ii/C1;
    qgen    = Ii^2*R0 + vrc(i)^2/R1;
    dT(i)   = (qgen - P.hA*(T(i) - Tamb - P.dTcab))/P.Cth;
    Ploss   = Ploss + qgen + abs(Pb - PbusAct(i));
end
end
