function run_case(caseName)
%RUN_CASE Reproduce one simulation study from the repository root.
%   run_case('smoke') tests one weather day.
%   See README.md for the complete list and expected runtimes.

root = fileparts(mfilename('fullpath'));
name = lower(string(caseName));
oldDir = pwd;
oldStrategy = getenv('SOH_STRATEGY');
oldNoR = getenv('SOH_NO_R');
cleanup = onCleanup(@() restore_state(oldDir, oldStrategy, oldNoR)); %#ok<NASGU>

if bdIsLoaded('SoH_MPC_SolarPump')
    close_system('SoH_MPC_SolarPump', 0);
end
setenv('SOH_STRATEGY', '');
setenv('SOH_NO_R', '');

switch name
    case "smoke"
        folder = "model_copy"; scripts = strings(0);
    case "full_es"
        folder = "full_daily_s1"; scripts = "run_full_daily.m";
        setenv('SOH_STRATEGY', '1');
    case "full_sa"
        folder = "full_daily_s3"; scripts = "run_full_daily.m";
        setenv('SOH_STRATEGY', '3');
    case "full_sa_no_r"
        folder = "full_daily_no_r"; scripts = "run_full_daily.m";
        setenv('SOH_STRATEGY', '3'); setenv('SOH_NO_R', '1');
    case "ablation"
        folder = "model_copy"; scripts = "run_ablation.m";
    case "representative_convergence"
        folder = "model_copy"; scripts = "run_convergence.m";
    case "controller_pair"
        folder = "controller_pair";
        scripts = ["run_controller_pair.m", "summarize_controller_pair.m", ...
                   "summarize_controller_state.m"];
    case "energy_balance"
        folder = "controller_pair"; scripts = "run_energy_balance.m";
    case "robustness_es"
        folder = "paired_es"; scripts = "run_paired_es.m";
    case "robustness_sa"
        folder = "robustness_copy"; scripts = "run_robustness.m";
    case "same_min_sa"
        folder = "stress_copy"; scripts = "run_fixed_min.m";
    case "figures"
        cd(root);
        run('summarize_full_daily.m');
        run('make_full_daily_main_figures.m');
        fprintf('MATLAB figures are in %s\n', fullfile(root, 'figures'));
        return;
    otherwise
        error('Unknown case "%s". See README.md.', name);
end

target = fullfile(root, folder);
assert(isfile(fullfile(target, 'climate.mat')), 'Missing climate.mat in %s', target);
assert(isfile(fullfile(target, 'SoH_MPC_SolarPump.slx')), 'Missing Simulink model in %s', target);
cd(target);

if name == "smoke"
    C = load('climate.mat'); C = C.C;
    P = mpc_params;
    P.strategy = 3; P.solverStep = 15;
    P.H = C.H(1); P.Tmean = C.T(1);
    P.Tamp = max((C.Tmax(1)-C.Tmin(1))/2, 0);
    P.tsr = C.tsr(1); P.L = C.L(1);
    P.T0 = (C.T(1)+P.dTcab)*ones(1,4);
    D = run_day(P);
    assert(all(isfinite(D.soc(:))) && all(isfinite(D.Vdc(:))), ...
        'Nonfinite state in one-day smoke test');
    assert(abs(D.Ereq-D.Esrv-D.Eunserved) < 1e-8, ...
        'Pump energy accounting failed');
    fprintf('Smoke test passed: day 1, served %.3f kWh, water %.3f m^3\n', ...
        D.Esrv, D.Vol);
else
    for script = scripts
        fprintf('Running %s in %s\n', script, target);
        run(char(script));
    end
end
end

function restore_state(oldDir, oldStrategy, oldNoR)
if bdIsLoaded('SoH_MPC_SolarPump')
    close_system('SoH_MPC_SolarPump', 0);
end
cd(oldDir);
setenv('SOH_STRATEGY', oldStrategy);
setenv('SOH_NO_R', oldNoR);
end
