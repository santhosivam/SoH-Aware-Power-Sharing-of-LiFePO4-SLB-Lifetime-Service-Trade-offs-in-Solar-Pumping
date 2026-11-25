function Ppv = pv_port(G, Tamb, P)
%#codegen
Tc  = Tamb + (P.NOCT - 20)/800*G;
Ppv = P.Ppv_stc*(G/1000)*(1 + P.gammaT*(Tc - 25))*P.etaMPPT*P.derate;
Ppv = max(Ppv, 0);
end
