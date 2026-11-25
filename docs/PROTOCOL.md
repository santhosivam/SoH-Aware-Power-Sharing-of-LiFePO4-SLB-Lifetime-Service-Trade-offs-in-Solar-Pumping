# Simulation protocol and source provenance

## Origin and compatibility

The supplied study archive contained a MATLAB R2026b SLX and the `build_mpc_model.m` source. The SLX copies in this package were rebuilt from that builder with MATLAB R2025b. The supplied 5-second representative-day reference is `reference/results_daily.mat`; rebuilt 5-second ES, CP, and SA daily trajectories matched it. Each experiment folder has an isolated working copy of the model, climate, and functions. A case's source files should be run from that case folder only; `run_case.m` handles this.

The Simulink model is an averaged four-module LiFePO4 battery, multiport converter, photovoltaic source, and solar pump. `mpc_params.m` contains all nominal electrical, thermal, controller, pump and aging parameters. The MATLAB Function blocks call functions stored alongside the model. The long-horizon model runs one day at a time, carries SoC and module temperature into the next day, and updates SoH and resistance after each day in `aging_step.m`.

## Numerics and data

| Setting | Value |
| --- | --- |
| Solver | fixed-step `ode4`, 15 seconds for reported multi-year studies |
| Logged output interval | 90 seconds, because logger decimation is six |
| Weather | 2023 Coimbatore NASA POWER daily values from `climate.mat`; additional years in `weather_2021_2024.csv` |
| Annual repetition | one 365-day weather year repeated for each simulated second-life year |
| Retirement | first module reaching SoH 0.65; threshold time interpolated between simulated days |
| Representative sampling | 37 days/year (`step=10`) or 73 days/year (`step=5`), with aging weight `365/nd` |
| Full-daily sampling | all 365 days/year (`step=1`), with daily aging and state carryover |

The 15-second step was checked against shorter steps; 20 seconds and longer produced large DC-bus excursions. The main scripts use the included climate input without network access. `model_copy/get_climate.m` is an optional NASA POWER download helper for extensions. The two JSON files contain the source API responses; the 2024 leap day was removed when the 365-row weather series was assembled.

## Study settings

1. **Controller ablation:** `model_copy/run_ablation.m` tests all eight binary combinations of SoH charge weighting, resistance weighting, and module SoC ceilings. It holds the SA energy-proportional discharge rule fixed, uses 37 selected days/year, the same weather and seed, and a 15-second solver. The saved eight-row table includes a historical mask-7 row from an independently run identical SA baseline after a concurrent cache conflict interrupted its first ablation batch. A new clean run of the driver computes all eight masks directly.
2. **Sampling convergence:** `model_copy/run_convergence.m` tests 37 and 73 days/year to the retirement threshold and a 365-day first year for both ES and SA. Injected estimator errors are zero. The three `full_daily_*` drivers independently extend 365-day ES, full SA and SA without resistance weighting to the first threshold.
3. **Matched controller selection:** `controller_pair/run_controller_pair.m` runs full SA and SA without resistance weighting under otherwise identical 37-day settings. Its summary scripts compare 11 complete years and a second common horizon. `controller_pair/run_energy_balance.m` checks a reconstructed bus-energy identity on six weather days under ES and SA.
4. **Paired robustness:** `paired_es/run_paired_es.m` and `robustness_copy/run_robustness.m` use the same 2023 baseline, initial SoH distributions, 2021/2022/2024 weather alternatives, calendar/cycle fade multipliers, and random seeds for ES and SA. `stress_copy/run_fixed_min.m` adds two distributions with the same initial minimum and mean SoH. Scenario names link the saved CSV tables.

The baseline SoH vector is `[0.92 0.85 0.78 0.72]`. The tight and wide vectors are `[0.86 0.83 0.80 0.78]` and `[0.98 0.84 0.75 0.70]`. The same-minimum vectors are `[0.88 0.84 0.83 0.72]` and `[0.98 0.82 0.75 0.72]`. Calendar and cycle capacity-fade coefficients are independently multiplied by 0.8 or 1.2 in the four aging corners; resistance-growth coefficients remain at baseline. Error seeds 1–4 are separate random realizations, while weather, SoH and aging changes are deterministic sensitivity cases.

## Interpretation

The first threshold crossing is a modeled service criterion, not a measured field lifetime. Annual service figures under the 37-day sampling method are sensitive to sampling density. The main service comparison therefore uses eight matched complete years from the 365-day runs. The reconstructed bus-energy residual is a numerical consistency check of the averaged model, not a physical validation. See `FINAL_RESULTS.md` for values and remaining limitations.
