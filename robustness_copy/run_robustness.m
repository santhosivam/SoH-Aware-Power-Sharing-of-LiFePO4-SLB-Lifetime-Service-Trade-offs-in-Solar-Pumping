S = load('climate.mat'); Cbase = S.C;
P0 = mpc_params;
o0 = struct('Ymax',20,'step',10,'sigSoH',0.02,'sigR',0.05,'sigSoC',0.02, ...
    'seed',1,'stopAtEol',true,'stopImmediately',true,'verbose',false,'solverStep',15);
cases = {
    'baseline',      P0.SoH0,               2023, 1.0, 1.0, 1;
    'soh_tight',     [0.86 0.83 0.80 0.78], 2023, 1.0, 1.0, 1;
    'soh_wide',      [0.98 0.84 0.75 0.70], 2023, 1.0, 1.0, 1;
    'weather_2021', P0.SoH0,               2021, 1.0, 1.0, 1;
    'weather_2022', P0.SoH0,               2022, 1.0, 1.0, 1;
    'weather_2024', P0.SoH0,               2024, 1.0, 1.0, 1;
    'aging_80_80',  P0.SoH0,               2023, 0.8, 0.8, 1;
    'aging_80_120', P0.SoH0,               2023, 0.8, 1.2, 1;
    'aging_120_80', P0.SoH0,               2023, 1.2, 0.8, 1;
    'aging_120_120',P0.SoH0,               2023, 1.2, 1.2, 1;
    'seed_2',       P0.SoH0,               2023, 1.0, 1.0, 2;
    'seed_3',       P0.SoH0,               2023, 1.0, 1.0, 3;
    'seed_4',       P0.SoH0,               2023, 1.0, 1.0, 4;
};
T = table;
for k = 1:size(cases,1)
    name = string(cases{k,1});
    P = P0; P.strategy = 3; P.SoH0 = cases{k,2};
    P.ag.calScale = cases{k,4}; P.ag.cycScale = cases{k,5};
    weatherYear = cases{k,3};
    if weatherYear == 2023
        C = Cbase;
    else
        C = load_weather_year(weatherYear);
    end
    o = o0; o.seed = cases{k,6};
    t = tic; R = sim_life(P,C,o);
    yr = R.yr(end);
    row = table(name,weatherYear,mean(C.H),mean(C.T), ...
        min(P.SoH0),max(P.SoH0)-min(P.SoH0),P.ag.calScale,P.ag.cycScale, ...
        o.seed,R.eolYear,numel(R.yr), ...
        sum(R.Eun)*365/R.nd/yr,sum(R.Vol)*365/R.nd/yr, ...
        max(R.Tmax(:)),toc(t), ...
        'VariableNames',{'scenario','weatherYear','meanGHI','meanAirC', ...
        'initialMinSoH','initialSpread','calendarScale','cycleScale', ...
        'seed','eolYears','simulatedDays','unservedKWhPerYear', ...
        'waterM3PerYear','maxModuleC','wallSeconds'});
    T = [T; row]; %#ok<AGROW>
    writetable(T,'robustness_results.csv');
    save('robustness_results.mat','T','o0','cases');
    save(sprintf('robustness_%s.mat',name),'R','P','o','C');
    fprintf('robustness %s EoL %.4f years, unserved %.2f kWh/y, wall %.1f s\n', ...
        name,R.eolYear,row.unservedKWhPerYear,row.wallSeconds);
end
