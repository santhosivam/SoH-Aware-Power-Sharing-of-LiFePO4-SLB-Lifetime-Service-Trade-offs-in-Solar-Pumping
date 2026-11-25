# Final verification results

## Full-daily lifetime convergence

The 365-day-per-year cases used zero injected estimator error, the same as the 37- and 73-day convergence runs. Each run continued to the first module reaching SoH 0.65. The base scenario and 15 s solver step were unchanged.

| Days/year | ES threshold, y | SA threshold, y | SA benefit, y |
| ---: | ---: | ---: | ---: |
| 37 | 8.8725 | 11.6202 | 2.7477 |
| 73 | 8.7776 | 11.5414 | 2.7638 |
| 365 | 8.9526 | 11.8139 | 2.8612 |

First-year all-daily service values are in full_daily_summary.csv. For a matched eight-year horizon, full-daily cumulative service is:

| Controller | Delivered, kWh | Unserved, kWh | Cell and port loss, kWh | Water, m³ |
| --- | ---: | ---: | ---: | ---: |
| ES | 62086.8 | 2153.2 | 2028.4 | 281458 |
| SA full | 61864.2 | 2375.8 | 2144.5 | 280629 |
| SA no resistance | 61870.8 | 2369.2 | 2131.6 | 280610 |

On 12 initial-state weather-day/controller checks, including the minimum-irradiance day, the largest reconstructed bus-energy residual was 8.68e-15 kWh, or 1.74e-16 of daily PV plus served energy. This is a numerical identity check of the averaged model, not physical validation.

## Controller selection at matched horizons

| Horizon | Controller | Life, y | Delivered, kWh | Cell and port loss, kWh | Water, m³ | Max logged temperature, °C | Max logged current, A |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 11 complete years | fully enabled | 11.582 | 86834.7 | 3087.5 | 393599 | 42.83 | 21.85 |
| 11 complete years | without resistance weighting | 12.083 | 86843.8 | 3068.8 | 393619 | 43.00 | 21.37 |
| to full-controller EOL | fully enabled | 11.582 | 91581.5 | 3264.8 | 415111 | 44.43 | 21.85 |
| to full-controller EOL | without resistance weighting | 12.083 | 91590.8 | 3245.4 | 415132 | 44.70 | 21.37 |

Logged peaks are sampled every 90 s (15 s solver step and decimation six); they are not guaranteed continuous-time maxima. The removal of resistance weighting is preferred for the base model on lifetime, delivered energy, and loss, subject to hardware validation and thermal limits.
In the full-daily eight-year comparison, removing resistance weighting changes delivered pump energy by +6.7 kWh, combined cell/port loss by -12.9 kWh, and water by -18.9 m³. The water change is small but adverse.
At 11 matched years, M4 mean SoC is 0.318 with full SA and 0.286 without resistance weighting. M4 SoH is 0.6532 and 0.6552. The lower SoC is consistent with less calendar aging, despite higher discharge throughput; this is an inference from the assumed aging law.

## Paired robustness

Each row uses identical weather, initial SoH, calendar/cycle coefficient multipliers, and estimator-error seed in ES and SA. Random seed variation is separated from deterministic scenario changes.

| Scenario | ES lifetime, y | SA lifetime, y | SA benefit, y | SA/ES ratio |
| --- | ---: | ---: | ---: | ---: |
| baseline | 8.840 | 11.582 | +2.742 | 1.310 |
| soh_tight | 15.722 | 18.680 | +2.958 | 1.188 |
| soh_wide | 6.356 | 8.430 | +2.074 | 1.326 |
| same_min_tight | 8.840 | 11.624 | +2.784 | 1.315 |
| same_min_wide | 8.841 | 11.565 | +2.724 | 1.308 |
| weather_2021 | 9.689 | 12.911 | +3.222 | 1.333 |
| weather_2022 | 9.834 | 12.990 | +3.156 | 1.321 |
| weather_2024 | 9.135 | 12.221 | +3.086 | 1.338 |
| aging_80_80 | 13.816 | 18.255 | +4.439 | 1.321 |
| aging_80_120 | 12.363 | 16.888 | +4.525 | 1.366 |
| aging_120_80 | 6.437 | 8.333 | +1.896 | 1.295 |
| aging_120_120 | 6.154 | 8.093 | +1.939 | 1.315 |
| seed_2 | 8.887 | 11.580 | +2.693 | 1.303 |
| seed_3 | 8.826 | 11.520 | +2.693 | 1.305 |
| seed_4 | 8.868 | 11.612 | +2.744 | 1.309 |

Deterministic scenario benefit range: 1.896–4.525 years. Four paired error seeds: mean benefit 2.718 years, sample SD 0.029 years. This SD describes four model draws, not field uncertainty.

## Reproducibility and limits

The archived model was rebuilt from the supplied MATLAB script in R2025b because its R2026b SLX file is incompatible with the available release. Archived and rebuilt 5 s daily trajectories matched. All new long-horizon cases use the checked 15 s fixed step, MATLAB ode4, the supplied Coimbatore 2023 NASA POWER weather or the additional NASA POWER years documented in docs/PROTOCOL.md, and the listed seeds. MATLAB source copies, run scripts, raw MAT outputs, and CSV tables are in this repository. The model is averaged, uses an assumed estimator-error distribution and transferred cell-aging parameters, and has no retired-module or hardware validation.
