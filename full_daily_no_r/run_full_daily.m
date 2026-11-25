S = load('climate.mat'); C = S.C;
P = mpc_params;
P.strategy = str2double(getenv('SOH_STRATEGY'));
if strcmp(getenv('SOH_NO_R'),'1'), P.useResistanceWeight = false; end
o = struct('Ymax',20,'step',1,'sigSoH',0,'sigR',0,'sigSoC',0, ...
    'seed',1,'stopAtEol',true,'stopImmediately',true,'verbose',true,'solverStep',15);
t = tic;
R = sim_life(P,C,o);
if P.useResistanceWeight, tag = sprintf('s%d',P.strategy);
else, tag = 'no_r'; end
save(sprintf('full_daily_%s.mat',tag),'R','P','o','-v7.3');
fprintf('FULL DAILY strategy %d EOL %.6f years, days %d, elapsed %.1f s\n', ...
    P.strategy,R.eolYear,numel(R.yr),toc(t));
