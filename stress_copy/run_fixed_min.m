S = load('climate.mat'); C = S.C;
P0 = mpc_params;
o = struct('Ymax',20,'step',10,'sigSoH',0.02,'sigR',0.05,'sigSoC',0.02, ...
    'seed',1,'stopAtEol',true,'stopImmediately',true,'verbose',false,'solverStep',15);
cases = {
    'same_min_tight', [0.88 0.84 0.83 0.72];
    'same_min_wide',  [0.98 0.82 0.75 0.72];
};
T = table;
for k = 1:size(cases,1)
    name = string(cases{k,1});
    P = P0; P.strategy = 3; P.SoH0 = cases{k,2};
    t = tic; R = sim_life(P,C,o);
    yr = R.yr(end);
    row = table(name,min(P.SoH0),mean(P.SoH0),max(P.SoH0)-min(P.SoH0), ...
        R.eolYear,sum(R.Eun)*365/R.nd/yr,sum(R.Vol)*365/R.nd/yr, ...
        toc(t),'VariableNames',{'scenario','initialMinSoH','initialMeanSoH', ...
        'initialSpread','eolYears','unservedKWhPerYear','waterM3PerYear','wallSeconds'});
    T = [T; row]; %#ok<AGROW>
    writetable(T,'robustness_fixed_min.csv');
    save(sprintf('robustness_%s.mat',name),'R','P','o','C');
    fprintf('fixed minimum %s EoL %.4f years, unserved %.2f kWh/y, wall %.1f s\n', ...
        name,R.eolYear,row.unservedKWhPerYear,row.wallSeconds);
end
