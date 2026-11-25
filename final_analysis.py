import csv
import statistics
from pathlib import Path

base = Path(__file__).resolve().parent
def rows(path):
    with path.open(newline='',encoding='utf-8-sig') as f:
        return list(csv.DictReader(f))
def f(row,key): return float(row[key])

full = {r['controller']:r for r in rows(base/'full_daily_summary.csv')}
conv = {(int(r['daysPerYear']),int(r['strategy'])):r for r in rows(base/'model_copy'/'convergence_results.csv')}
ctrl = rows(base/'controller_pair'/'controller_comparison.csv')
state = {(r['controller'],int(r['module'])):r for r in rows(base/'controller_pair'/'controller_module_state.csv')}
es = {r['scenario']:r for r in rows(base/'paired_es'/'paired_es_results.csv')}
sa = {r['scenario']:r for r in rows(base/'robustness_copy'/'robustness_results.csv')}
sa.update({r['scenario']:r for r in rows(base/'stress_copy'/'robustness_fixed_min.csv')})
assert len(es)==len(sa)==15 and set(es)==set(sa)

lines=['# Final verification results','','## Full-daily lifetime convergence','',
       'The 365-day-per-year cases used zero injected estimator error, the same as the 37- and 73-day convergence runs. Each run continued to the first module reaching SoH 0.65. The base scenario and 15 s solver step were unchanged.','',
       '| Days/year | ES threshold, y | SA threshold, y | SA benefit, y |',
       '| ---: | ---: | ---: | ---: |']
for n in (37,73,365):
    a=conv[n,1] if n<365 else full['ES']; b=conv[n,3] if n<365 else full['SA full']
    aa=f(a,'eolYears');bb=f(b,'eolYears')
    lines.append(f'| {n} | {aa:.4f} | {bb:.4f} | {bb-aa:.4f} |')
lines.extend(['',
    'First-year all-daily service values are in full_daily_summary.csv. For a matched eight-year horizon, full-daily cumulative service is:', '',
    '| Controller | Delivered, kWh | Unserved, kWh | Cell and port loss, kWh | Water, m³ |',
    '| --- | ---: | ---: | ---: | ---: |'])
for name in ('ES','SA full','SA no resistance'):
    r=full[name];lines.append(f"| {name} | {f(r,'eightYearServedKWh'):.1f} | {f(r,'eightYearUnservedKWh'):.1f} | {f(r,'eightYearBatteryLossKWh'):.1f} | {f(r,'eightYearWaterM3'):.0f} |")
bal=rows(base/'controller_pair'/'energy_balance_checks.csv')
lines.extend(['',f"On {len(bal)} initial-state weather-day/controller checks, including the minimum-irradiance day, the largest reconstructed bus-energy residual was {max(abs(f(r,'busResidualKWh')) for r in bal):.3g} kWh, or {max(f(r,'relativeBusResidual') for r in bal):.3g} of daily PV plus served energy. This is a numerical identity check of the averaged model, not physical validation.",'',
    '## Controller selection at matched horizons','',
    '| Horizon | Controller | Life, y | Delivered, kWh | Cell and port loss, kWh | Water, m³ | Max logged temperature, °C | Max logged current, A |',
    '| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |'])
for r in ctrl:
    t=max(f(r,f'peakModuleC_{i}') for i in range(1,5))
    c=max(f(r,f'peakCurrentA_{i}') for i in range(1,5))
    lines.append(f"| {r['horizon']} | {r['controller']} | {f(r,'eolYears'):.3f} | {f(r,'deliveredKWh'):.1f} | {f(r,'batteryLossKWh'):.1f} | {f(r,'waterM3'):.0f} | {t:.2f} | {c:.2f} |")
lines.extend(['','Logged peaks are sampled every 90 s (15 s solver step and decimation six); they are not guaranteed continuous-time maxima. The removal of resistance weighting is preferred for the base model on lifetime, delivered energy, and loss, subject to hardware validation and thermal limits.',
    f"In the full-daily eight-year comparison, removing resistance weighting changes delivered pump energy by {f(full['SA no resistance'],'eightYearServedKWh')-f(full['SA full'],'eightYearServedKWh'):+.1f} kWh, combined cell/port loss by {f(full['SA no resistance'],'eightYearBatteryLossKWh')-f(full['SA full'],'eightYearBatteryLossKWh'):+.1f} kWh, and water by {f(full['SA no resistance'],'eightYearWaterM3')-f(full['SA full'],'eightYearWaterM3'):+.1f} m³. The water change is small but adverse.",
    f"At 11 matched years, M4 mean SoC is {f(state[('fully enabled',4)],'meanSocAt11Years'):.3f} with full SA and {f(state[('without resistance weighting',4)],'meanSocAt11Years'):.3f} without resistance weighting. M4 SoH is {f(state[('fully enabled',4)],'sohAt11Years'):.4f} and {f(state[('without resistance weighting',4)],'sohAt11Years'):.4f}. The lower SoC is consistent with less calendar aging, despite higher discharge throughput; this is an inference from the assumed aging law.",'',
    '## Paired robustness','',
    'Each row uses identical weather, initial SoH, calendar/cycle coefficient multipliers, and estimator-error seed in ES and SA. Random seed variation is separated from deterministic scenario changes.','',
    '| Scenario | ES lifetime, y | SA lifetime, y | SA benefit, y | SA/ES ratio |',
    '| --- | ---: | ---: | ---: | ---: |'])
for name in es:
    x=f(es[name],'eolYears');y=f(sa[name],'eolYears')
    lines.append(f'| {name} | {x:.3f} | {y:.3f} | {y-x:+.3f} | {y/x:.3f} |')
det=[n for n in es if not n.startswith('seed_')]
benefits=[f(sa[n],'eolYears')-f(es[n],'eolYears') for n in det]
seeds=['baseline','seed_2','seed_3','seed_4']
seed_b=[f(sa[n],'eolYears')-f(es[n],'eolYears') for n in seeds]
lines.extend(['',f'Deterministic scenario benefit range: {min(benefits):.3f}–{max(benefits):.3f} years. Four paired error seeds: mean benefit {statistics.mean(seed_b):.3f} years, sample SD {statistics.stdev(seed_b):.3f} years. This SD describes four model draws, not field uncertainty.','',
    '## Reproducibility and limits','',
    'The archived model was rebuilt from the supplied MATLAB script in R2025b because its R2026b SLX file is incompatible with the available release. Archived and rebuilt 5 s daily trajectories matched. All new long-horizon cases use the checked 15 s fixed step, MATLAB ode4, the supplied Coimbatore 2023 NASA POWER weather or the additional NASA POWER years documented in docs/PROTOCOL.md, and the listed seeds. MATLAB source copies, run scripts, raw MAT outputs, and CSV tables are in this repository. The model is averaged, uses an assumed estimator-error distribution and transferred cell-aging parameters, and has no retired-module or hardware validation.'])
out=base/'docs'/'FINAL_RESULTS.md';out.write_text('\n'.join(lines)+'\n',encoding='utf-8');print(out)
