S = load('climate.mat'); C = S.C;
P = mpc_params;
P.strategy = str2double(getenv('SOH_STRATEGY'));
o = struct('Ymax',20,'step',1,'sigSoH',0,'sigR',0,'sigSoC',0, ...
    'seed',1,'stopAtEol',true,'stopImmediately',true,'verbose',true,'solverStep',15);
t = tic;
R = sim_life(P,C,o);
save(sprintf('full_daily_s%d.mat',P.strategy),'R','P','o','-v7.3');
fprintf('FULL DAILY strategy %d EOL %.6f years, days %d, elapsed %.1f s\n', ...
    P.strategy,R.eolYear,numel(R.yr),toc(t));
