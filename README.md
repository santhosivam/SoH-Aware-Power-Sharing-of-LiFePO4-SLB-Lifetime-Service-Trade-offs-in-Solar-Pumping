# SoH-aware solar-pump simulation files

This folder is the **standalone simulation and supplementary-data package** for the second-life battery solar-pumping study. It contains MATLAB/Simulink source, model files, weather inputs, saved outputs, result figures, and the scripts that produced them. The manuscript is deliberately outside this folder.

## 1. Software and model assumptions

- Tested with **MATLAB R2025b**, **Simulink**, and Signal Processing Toolbox on Windows. `aging_step.m` uses `rainflow` when available; without it, the code follows a simpler fallback and the aging results may differ.
- The included `SoH_MPC_SolarPump.slx` files were rebuilt from `build_mpc_model.m` for R2025b because the original supplied SLX was saved in R2026b. Each experiment folder contains its own working model and code variant.
- Long-horizon runs use fixed-step `ode4` at **15 seconds**, a repeated 365-day weather year, and stop at the first module crossing **SoH 0.65**, unless a driver says otherwise. The 2024 leap day was removed from the supplementary weather series.
- The results are conditional simulation predictions, with assumed aging and estimator-error parameters. There is no retired-module or hardware validation.

## 2. Folder map

| Path | Purpose |
| --- | --- |
| `model_copy/` | Base model, 8-case controller ablation, 37/73-day convergence, solver checks. |
| `full_daily_s1/` | 365-day/year equal sharing (ES), with raw lifetime output. |
| `full_daily_s3/` | 365-day/year fully enabled SoH-aware sharing (SA). |
| `full_daily_no_r/` | 365-day/year SA without resistance weighting. |
| `controller_pair/` | Matched SA controller comparison and bus-energy balance. |
| `paired_es/` | ES half of the paired robustness scenarios. |
| `robustness_copy/` | SA half of the paired robustness scenarios, including weather, SoH, aging and seed changes. |
| `stress_copy/` | Same-minimum-SoH SA cases and solver stress check. |
| `reference/results_daily.mat` | Supplied 5-second daily reference used by `model_copy/step_convergence.m`. |
| `figures/` | Five result figures: full-daily Figures 4–6, sampling convergence, paired robustness. |
| `docs/` | Verified numerical results, experiment protocol, and data provenance. |

The case folders intentionally repeat `climate.mat`, the `.slx` model, and several MATLAB functions. Their drivers load files from the **current working directory**, and some functions differ between studies. Do not add all case folders to the MATLAB path at once; use `run_case.m` so each experiment runs with its own code.

## 3. Quick start

Open MATLAB in this repository root (`Simulation files`) and run:

```matlab
run_case('smoke')
```

This loads the included model and 2023 weather, simulates one day at 15 seconds, and checks finite states and pump-energy accounting. No external input files or network access are needed. On a fresh checkout, Simulink may generate local cache files; `.gitignore` excludes them.

To inspect or rebuild the graphical model, enter a case folder in MATLAB and run:

```matlab
cd('model_copy')
open_system('SoH_MPC_SolarPump.slx')
% Optional: build_mpc_model   % recreates the SLX in this folder
```

The builder recreates the model from source and replaces that folder's SLX. The included SLX is ready for the simulations below.

## 4. Reproduce the studies

Run each command **from the repository root**. `run_case` selects the correct isolated folder, sets the required environment flags, restores your previous directory and flags, and closes the model afterwards. These long simulations can take substantial time. Existing saved MAT/CSV outputs are supplied so figures and tables can be checked without rerunning them.

```matlab
run_case('full_es')                    % full 365-day ES to first SoH 0.65
run_case('full_sa')                    % full 365-day SA to first SoH 0.65
run_case('full_sa_no_r')               % full 365-day SA without R weighting
run_case('ablation')                   % 8 SoH/R/SoC-ceiling combinations; 37 selected days/year
run_case('representative_convergence') % 37 and 73 days/year to EOL; 365 days for year 1
run_case('controller_pair')            % SA full versus SA without R, matched 37-day study
run_case('energy_balance')             % six weather days under ES and SA
run_case('robustness_es')              % paired ES scenarios
run_case('robustness_sa')              % paired SA scenarios
run_case('same_min_sa')                % same-minimum-SoH follow-up SA cases
```

For the full-daily summary and main result figures, the supplied MAT outputs are enough:

```matlab
run_case('figures')
```

This runs `summarize_full_daily.m` and `make_full_daily_main_figures.m`, updating `full_daily_summary.csv` and `figures/fig04_full_daily_soh.png`, `fig05_full_daily_bank.png`, and `fig06_full_daily_service.png`. The other two figures are reproduced from saved CSV tables with Python 3 and Pillow:

```powershell
python -m pip install -r requirements-figures.txt
python make_revision_figures.py
```

If you use MATLAB directly in a case folder, first set `SOH_STRATEGY=1` for `full_daily_s1`, `SOH_STRATEGY=3` for `full_daily_s3`, and both `SOH_STRATEGY=3` and `SOH_NO_R=1` for `full_daily_no_r`. `run_case` handles these settings automatically.

## 5. Where to check the results

| Output | Source |
| --- | --- |
| `full_daily_summary.csv` | `summarize_full_daily.m`; three complete annual MAT trajectories. |
| `model_copy/ablation_results.csv` | `run_ablation.m`. |
| `model_copy/convergence_results.csv` | `run_convergence.m`; full-daily EOL is in the separate annual MAT files. |
| `controller_pair/controller_comparison.csv`, `controller_module_state.csv` | `run_case('controller_pair')`. |
| `controller_pair/energy_balance_checks.csv` | `run_case('energy_balance')`. |
| `paired_es/paired_es_results.csv`, `robustness_copy/robustness_results.csv`, `stress_copy/robustness_fixed_min.csv` | Matched robustness scenarios; join on `scenario`. |
| `docs/FINAL_RESULTS.md` | Human-readable verification tables and limitations. |

In the supplied full-daily base case, the first SoH 0.65 crossing is **8.9526 years (ES)**, **11.8139 years (SA full)**, and **12.2323 years (SA without R weighting)**. Figure 6 uses eight identical pre-retirement years for ES and SA service comparisons. The 37-day experiments are sensitivity and screening results; no full-daily CP lifetime is claimed.

## 6. Weather, reproducibility and extension

`climate.mat` is the supplied 2023 NASA POWER daily Coimbatore profile. `weather_2021_2024.csv` and the two `weather_*.json` files provide the additional years and original API responses. `load_weather_year.m` reads the CSV relative to this repository root. The weather source and scenario definitions are documented in `docs/DATA_PROVENANCE.md` and `docs/PROTOCOL.md`. To try another year, prepare a 365-row weather series with the same columns and update a scenario driver; to try another aging law, edit the `aging_step.m` in that case folder.

The scripts fix random seeds where estimator noise is enabled. Full-daily convergence runs disable injected estimator noise, so changing the number of simulated days does not change the number of random error draws. Logged peak currents and temperatures are sampled every 90 seconds because the Simulink logger decimates the 15-second solver output by six.

`verify_package.py` checks the repository SHA-256 manifest. The source code and rebuilt models are under the MIT terms in `LICENSE-CODE`; project-generated results, figures, and original documentation are under CC BY 4.0 as scoped in `LICENSE-DATA.md`. NASA POWER inputs and the archived reference retain their stated provenance. The copyright holders and attribution names are **Jethose Vijayakumar (JCT College of Engineering and Technology, India)** and **Santhosh Paramasivam (University of Cagliari, Italy)**.
