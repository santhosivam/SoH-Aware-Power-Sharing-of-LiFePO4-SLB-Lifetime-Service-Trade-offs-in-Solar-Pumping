function mdl = build_mpc_model()
mdl = 'SoH_MPC_SolarPump';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);
set_param(mdl, 'Solver', 'ode4', 'SolverType', 'Fixed-step', 'FixedStep', '5', ...
    'StopTime', '86400', 'ReturnWorkspaceOutputs', 'on');
MF = 'simulink/User-Defined Functions/MATLAB Function';
INT = 'simulink/Continuous/Integrator';
x = @(c) 60 + 230*c; y = @(r) 40 + 130*r;
pos = @(c, r, w, h) [x(c) y(r) x(c)+w y(r)+h];
add_block('simulink/Sources/Clock', [mdl '/Clock'], 'Position', pos(0,1,30,30));
blk = {
 'Environment (NASA POWER day)', 'function [G,Tamb,PpumpReq] = fcn(t,P)\n[G,Tamb,PpumpReq] = env_profile(t,P);\n', 1,1
 'PV MPPT port',                 'function Ppv = fcn(G,Tamb,P)\nPpv = pv_port(G,Tamb,P);\n', 2,0
 'SoC-SoH estimator',            'function socHat = fcn(soc,P)\nsocHat = min(max(soc + P.socBias,0),1);\n', 2,3
 'Power-sharing controller',     'function [Pbus,PpumpSrv,Pcurt] = fcn(Ppv,PpumpReq,socHat,Pcorr,P)\n[Pbus,PpumpSrv,Pcurt] = share_ctrl(Ppv,PpumpReq,socHat,Pcorr,P);\n', 3,1
 'Battery ports + 2nd-life modules', 'function [dsoc,dvrc,dT,I,Vt,PbusAct,Ploss] = fcn(Pbus,soc,vrc,T,Tamb,P)\n[dsoc,dvrc,dT,I,Vt,PbusAct,Ploss] = batt_ports(Pbus,soc,vrc,T,Tamb,P);\n', 4,2
 'DC bus',                       'function dE = fcn(Ppv,Pcurt,PbusAct,PpumpSrv)\ndE = Ppv - Pcurt + sum(PbusAct) - PpumpSrv;\n', 5,0
 'Bus voltage sensor',           'function [e,Vdc] = fcn(E,P)\ne = P.Eref - E;\nVdc = sqrt(2*max(E,0)/P.Cbus);\n', 6,1.8
 'Bus voltage PI',               'function Pcorr = fcn(e,inte,P)\nPcorr = min(max(P.Kp*e + P.Ki*inte, -P.PcorrMax), P.PcorrMax);\n', 6,0
 'Solar pump (VFD+PMSM+pump)',   'function Qw = fcn(Psrv,P)\nQw = pump_model(Psrv,P);\n', 5,4
 'Accumulators',                 'function r = fcn(I,Qw,Ppv,Pcurt,Preq,Psrv,Ploss)\nr = [abs(I) max(I,0) Qw Ppv Pcurt Preq Psrv Ploss];\n', 6,4
 'Logger',                       'function y = fcn(t,G,Tamb,Ppv,Pcurt,Preq,Psrv,Pbus,soc,I,Vt,T,Vdc,Qw,acc)\ny = [t G Tamb Ppv Pcurt Preq Psrv Pbus soc I Vt T Vdc Qw acc];\n', 8,2
 };
rt = sfroot;
for k = 1:size(blk,1)
    p = [mdl '/' blk{k,1}];
    add_block(MF, p, 'Position', pos(blk{k,3}, blk{k,4}, 150, 90));
    ch = rt.find('-isa', 'Stateflow.EMChart', 'Path', p);
    ch.Script = sprintf(blk{k,2});
    d = ch.find('-isa', 'Stateflow.Data', 'Name', 'P');
    if ~isempty(d), d.Scope = 'Parameter'; end
end
set_sizes(mdl);
ints = {
 'SoC',        'P.soc0',  4,4.9, ''
 'V_RC',       'zeros(1,4)', 5,3.5, ''
 'T_cell',     'P.T0',    5,2.8, ''
 'E_bus',      'P.Eref',  6,1.2, ''
 'int_e',      '0',       7,0.6, 'lim'
 'Throughput & energy', 'zeros(1,14)', 7,4.2, ''
 };
for k = 1:size(ints,1)
    p = [mdl '/' ints{k,1}];
    add_block(INT, p, 'Position', pos(ints{k,3}, ints{k,4}, 40, 40), 'InitialCondition', ints{k,2});
    if strcmp(ints{k,5}, 'lim')
        set_param(p, 'LimitOutput', 'on', 'UpperSaturationLimit', 'P.PcorrMax/P.Ki', ...
            'LowerSaturationLimit', '-P.PcorrMax/P.Ki');
    end
end
add_block('simulink/Sinks/To Workspace', [mdl '/simlog'], 'Position', pos(9,2,80,40), ...
    'VariableName', 'simlog', 'SaveFormat', 'Array', 'Decimation', '6', 'MaxDataPoints', 'inf');
L = @(a, b) add_line(mdl, a, b, 'autorouting', 'smart');
E = 'Environment (NASA POWER day)'; PV = 'PV MPPT port'; ES = 'SoC-SoH estimator';
C = 'Power-sharing controller'; B = 'Battery ports + 2nd-life modules'; D = 'DC bus';
PI = 'Bus voltage PI'; PU = 'Solar pump (VFD+PMSM+pump)'; A = 'Accumulators'; G = 'Logger';
L('Clock/1', [E '/1']);
L([E '/1'], [PV '/1']);  L([E '/2'], [PV '/2']);
L([PV '/1'], [C '/1']);  L([E '/3'], [C '/2']);  L([ES '/1'], [C '/3']);  L([PI '/1'], [C '/4']);
L([C '/1'], [B '/1']);  L('SoC/1', [B '/2']);  L('V_RC/1', [B '/3']);  L('T_cell/1', [B '/4']);  L([E '/2'], [B '/5']);
L([B '/1'], 'SoC/1');  L([B '/2'], 'V_RC/1');  L([B '/3'], 'T_cell/1');
L('SoC/1', [ES '/1']);
VS = 'Bus voltage sensor';
L([PV '/1'], [D '/1']);  L([C '/3'], [D '/2']);  L([B '/6'], [D '/3']);  L([C '/2'], [D '/4']);
L([D '/1'], 'E_bus/1');  L('E_bus/1', [VS '/1']);
L([VS '/1'], 'int_e/1');  L([VS '/1'], [PI '/1']);  L('int_e/1', [PI '/2']);
L([C '/2'], [PU '/1']);
L([B '/4'], [A '/1']);  L([PU '/1'], [A '/2']);  L([PV '/1'], [A '/3']);  L([C '/3'], [A '/4']);
L([E '/3'], [A '/5']);  L([C '/2'], [A '/6']);  L([B '/7'], [A '/7']);  L([A '/1'], 'Throughput & energy/1');
srcs = {'Clock/1', [E '/1'], [E '/2'], [PV '/1'], [C '/3'], [E '/3'], [C '/2'], [C '/1'], 'SoC/1', ...
        [B '/4'], [B '/5'], 'T_cell/1', [VS '/2'], [PU '/1'], 'Throughput & energy/1'};
for k = 1:numel(srcs), L(srcs{k}, sprintf('%s/%d', G, k)); end
L([G '/1'], 'simlog/1');
try
note = Simulink.Annotation([mdl '/SoH-aware multi-port converter for second-life EV batteries feeding a solar pump']);
note.Position = [60 5 700 25]; note.FontSize = 12;
catch
end
save_system(mdl);
end
