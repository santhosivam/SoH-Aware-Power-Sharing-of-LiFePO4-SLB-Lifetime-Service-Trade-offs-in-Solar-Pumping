S = load('climate.mat'); C = S.C;
P0 = mpc_params;
o = struct('Ymax',20,'step',10,'sigSoH',0,'sigR',0,'sigSoC',0, ...
    'seed',1,'stopAtEol',true,'stopImmediately',true,'verbose',false,'solverStep',15);
T = table;
for step = [10 5 1]
    for strategy = [1 3]
        P = P0; P.strategy = strategy;
        t = tic;
        oo = o; oo.step = step;
        if step == 1
            oo.Ymax = 1; oo.stopAtEol = false; oo.stopImmediately = false;
        end
        R = sim_life(P,C,oo);
        save(sprintf('convergence_step%d_s%d.mat',step,strategy),'R','oo','P');
        n = R.nd;
        row = table(step,strategy,n,o.solverStep,R.eolYear, ...
            min(R.SoH(n,:)),sum(R.Eun(1:n))*365/n, ...
            sum(R.Esrv(1:n))*365/n,sum(R.Vol(1:n))*365/n, ...
            toc(t), ...
            'VariableNames',{'dayStep','strategy','daysPerYear','solverStepSeconds', ...
            'eolYears','year1WeakestSoH','year1UnservedKWh', ...
            'year1ServedKWh','year1WaterM3','wallSeconds'});
        T = [T; row]; %#ok<AGROW>
        writetable(T,'convergence_results.csv');
        fprintf('convergence %d days/year, strategy %d: EoL %.4f, year1 SoH %.6f, year1 unserved %.2f, wall %.1f s\n', ...
            n,strategy,R.eolYear,row.year1WeakestSoH, ...
            row.year1UnservedKWh,row.wallSeconds);
    end
end
