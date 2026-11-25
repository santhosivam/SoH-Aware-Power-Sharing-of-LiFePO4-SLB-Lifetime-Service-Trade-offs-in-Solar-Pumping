S = load('climate.mat'); C = S.C;
P0 = mpc_params;
o = struct('Ymax',20,'step',10,'sigSoH',0.02,'sigR',0.05,'sigSoC',0.02, ...
    'seed',1,'stopAtEol',true,'stopImmediately',true,'verbose',true,'solverStep',15);
for j = 1:2
    P = P0; P.strategy = 3;
    P.useResistanceWeight = j == 1;
    R = sim_life(P,C,o);
    save(sprintf('controller_pair_%d.mat',j),'R','P','o','-v7.3');
    fprintf('controller %d EOL %.5f days %d\n',j,R.eolYear,numel(R.yr));
end
