A = load('controller_pair_1.mat'); B = load('controller_pair_2.mat');
T = table;
for j = 1:2
    if j == 1, R = A.R; name = "fully enabled";
    else, R = B.R; name = "without resistance weighting"; end
    n = 11*R.nd;
    for i = 1:4
        row = table(name,i,R.SoH(n,i),mean(R.socMean(1:n,i)), ...
            sum(R.AhDis(1:n,i))*365/R.nd, ...
            'VariableNames',{'controller','module','sohAt11Years', ...
            'meanSocAt11Years','dischargeAhAt11Years'});
        T = [T;row]; %#ok<AGROW>
    end
end
writetable(T,'controller_module_state.csv');
disp(T);
