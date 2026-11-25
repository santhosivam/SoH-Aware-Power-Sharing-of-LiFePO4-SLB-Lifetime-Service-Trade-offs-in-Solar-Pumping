function w = share_weights(socHat, isDischarge, P)
%#codegen
Qhat = P.SoHhat*P.Qrated;
w = ones(1,4);
switch P.strategy
    case 1
        w = ones(1,4);
    case 2
        w = Qhat;
    otherwise
        phi  = max(P.SoHhat - P.sohEol, 0.01);
        phin = phi/max(phi);
        rfac = ones(1,4);
        if P.useResistanceWeight
            rfac = (P.Rhat/mean(P.Rhat)).^(-P.beta);
        end
        if isDischarge
            w = Qhat.*max(socHat - P.socMin, 0).*rfac;
        else
            hfac = ones(1,4);
            if P.useSohWeight
                hfac = phin.^P.gamma;
            end
            w = Qhat.*hfac.*rfac;
        end
end
end
