function [G, Tamb, PpumpReq] = env_profile(t, P)
%#codegen
tod = mod(t, 86400)/3600;
G = 0;
if tod > P.tsr && tod < P.tsr + P.L
    Gpk = P.H*1000*pi/(2*P.L);
    G = Gpk*sin(pi*(tod - P.tsr)/P.L);
end
Tamb = P.Tmean + P.Tamp*sin(2*pi*(tod - 9)/24);
PpumpReq = 0;
if (tod >= P.dayOn && tod < P.dayOff) || (tod >= P.eveOn && tod < P.eveOff)
    PpumpReq = P.Ppump;
end
end
