function D = run_day(P, mdl, mode)
if nargin < 2, mdl = 'SoH_MPC_SolarPump'; end
if nargin < 3, mode = 'normal'; end
in  = Simulink.SimulationInput(mdl);
if isfield(P, 'solverStep')
    in = in.setModelParameter('FixedStep', num2str(P.solverStep));
    P = rmfield(P, 'solverStep');
end
in = in.setModelParameter('SimulationMode', mode);
in = in.setVariable('P', P);
out = sim(in);
Y = out.simlog; if ndims(Y) == 3, Y = permute(Y, [3 2 1]); end
D.t    = Y(:,1);   D.G = Y(:,2);  D.Tamb = Y(:,3);
D.Ppv  = Y(:,4);   D.Pcurt = Y(:,5); D.Preq = Y(:,6); D.Psrv = Y(:,7);
D.Pbus = Y(:,8:11); D.soc = Y(:,12:15); D.I = Y(:,16:19); D.Vt = Y(:,20:23);
D.T    = Y(:,24:27); D.Vdc = Y(:,28); D.Qw = Y(:,29);
acc = Y(end,30:43);
D.AhAbs = acc(1:4)/3600;  D.AhDis = acc(5:8)/3600;  D.Vol = acc(9);
D.Epv = acc(10)/3.6e6; D.Ecurt = acc(11)/3.6e6; D.Ereq = acc(12)/3.6e6;
D.Esrv = acc(13)/3.6e6; D.Eloss = acc(14)/3.6e6;
D.Eunserved = D.Ereq - D.Esrv;
end
