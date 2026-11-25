S = load('climate.mat'); C = S.C;
P0 = mpc_params;
o = struct('Ymax',1,'step',10,'sigSoH',0.02,'sigR',0.05,'sigSoC',0.02, ...
    'seed',1,'stopAtEol',false,'stopImmediately',false,'verbose',false,'solverStep',15);
for s = [1 3]
    P = P0; P.strategy = s;
    t = tic; R = sim_life(P,C,o);
    fprintf('15 s strategy %d: minSoH %.8f, unserved %.5f kWh, water %.5f m3, Tmax %.5f, wall %.1f s\n', ...
        s,min(R.SoH(end,:)),sum(R.Eun)*365/R.nd, ...
        sum(R.Vol)*365/R.nd,max(R.Tmax(:)),toc(t));
    save(sprintf('solver15_year1_s%d.mat',s),'R','P','o');
end
