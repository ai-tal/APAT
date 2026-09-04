# APAT M8 — Architecture & Improvement Plan

**From:** `APAT_v3_M7_110_5.m` — 5,199 lines, one App Designer-style class, 183 functions (95 methods, 34 file-scope functions, the rest nested/self-test), 622 lines of hand-written layout in `createComponents` (3072–3693).

**To:** `APAT_v3_M8.m` — the **same one file**, the **same widgets, feature set and input formats**, rebuilt around one grid-native pattern, one derivation function, one pattern registry shared by both tabs, one dispatcher, one declarative layout and one eight-line performance tracker. Base MATLAB (R2023b baseline), **no toolboxes**.

**Size:** budget sum **≈ 2,130 lines** (§11), target **≤ 2,500**, hard ceiling **3,000**. Conciseness means fewer algorithms, fewer copies and fewer paths — never joined lines, shortened names or removed comments.

**Delivery:** one drop. The numerical core is written first, the UI is pointed at it, and every M7 name the core replaces is deleted in the same edit. No dual paths, no compatibility shims.

All **line numbers** refer to `APAT_v3_M7_110_5.m`. Defect IDs (**D01–D74**) are local to this plan (register in §10).

---

## 0. Proportionality rule (governs every item below)

> A change is admitted only if it (a) fixes a verified defect for an input APAT already accepts, or (b) removes code, or (c) is required by another admitted item.

Out of scope by consequence: new file formats or variants, new plot/cut types, new metrics, toolbox dependencies, calibration from anything but the pattern file's own value columns, changes to the set of widgets or their arrangement, moving UI handles out of declared App Designer-style properties, any self-test or fixture code, any cache or memoisation layer whose saving cannot be felt by the user.

---

## 1. Executive summary

M7 is feature-complete and careful in places, but long and slow for five structural reasons:

1. **The same sphere is re-interpreted by every consumer.** One pattern is materialised as six long tables per refresh (189–194) plus two per coverage node (1684–1686). The *display* convention (elevation θ, signed φ) is written into the data (439–459) and undone by `physicalTheta` at 13 sites — and forgotten at three, so solid-angle weights, boresight and front-to-back are wrong whenever the elevation view is active (D02). Grid structure is re-derived everywhere (`gridStep` ×17, `solidWeights` ×6, `unique/ismember/sub2ind` in `gridComp` 499–519).

2. **UI callbacks own algorithms.** A component change re-runs orientation and metrics, rebuilds all five full-pattern views with `cla`+`surf` (one is visible), creates new context menus and colorbars, and pushes a 65k×17 table to a `uitable`. A parameter change resets the user's cut and colour range (D55). State lives in 14 widget `UserData` slots and 48 `NodeData` touches.

3. **Main and Coverage keep two copies of the same idea.** The Main tab holds a pattern in `viewTbl`; the Coverage tab copies it into a tree node (`pattern`, `sourceTable`, `solidAngle`, `boresightIndex`, …) and three functions exist only to keep the copies in step (`syncCoverageNodeFromView`, `syncCoveragePattern`, `covPatternTarget`). Every tree click — and every checkbox toggle, through `finalizeCoverageJobs → setCoverageUI → Cov_ButtonGroup_CovTypeSelectionChanged → syncCoveragePattern` — re-runs a 65k-sample percentile (D37). A 30 ms coverage computation is wrapped in a per-node cache keyed by the threshold vector and an eagerly built inverse curve (D10, D56).

4. **Several numerical policies are silently wrong for legitimate inputs:** fields rounded to 5 decimals (D03), `Re/Im` interpolation under phase slope (D04), gain-only dB interpolated linearly on regular grids despite the option that claims otherwise (D16), hemispheres extrapolated to full spheres (D05), a *toolbox* percentile peak policy that can demote a real pencil beam (D01), NaN fields turned into a definite PLF (D08), raw far fields labelled dBi with an efficiency (D23), metrics computed from whichever component is selected (D12), a gain-only cut that always plots column 3 whatever the user selected (D15), non-uniform grids accepted and then mis-weighted (D18).

5. **The layout is scripted, not declared, and the readers carry dead weight.** 622 lines build 118 widgets with 185 separate `Layout.Row/Column` statements; the Excel summary reader spends 164 lines (4400–4563) extracting metadata that nothing in APAT displays (D30).

M8 keeps the UI and changes the program underneath it:

> **One grid-native pattern on uniform axes. One separable geometry. One derivation function that turns pattern + parameters into every column and every base fact, eagerly — it costs tens of milliseconds, so nothing is memoised. One pattern registry serving Main and Coverage. One `update(scope)` with build-then-commit. One config reader. Coverage as one five-line kernel whose result is a curve; every read of a curve — query, inverse query, table union — is the same `interp1` idiom. Retained graphics that render only what is visible. One declarative `place()` for the layout. One convention per constant, shown in Metadata. One eight-line performance tracker to measure the gain.**

Expected outcome (§16): ≈ 2,130 lines with every widget preserved; zero duplicate algorithms; zero toolbox calls; zero cache keys; component change ≈ one `CData` assignment; parameter change ≈ one 40 ms derivation plus a redraw of the visible tab; coverage compute ≈ 30 ms with no state to invalidate; 74 catalogued defects closed structurally.

---

## 2. Goals and non-goals

**Goals**

1. Correct physics for every supported input: solid angle, peak, resampling, polarisation sense, principal planes, unit disclosure.
2. One implementation per concept; one declaration per widget; one pattern object per loaded file, whichever tab uses it.
3. Every user action recomputes only its invalidation radius and touches only the graphics it changes — and **never resets a user choice that the action did not invalidate**.
4. Every convention is pinned in one place and visible to the user.
5. Same file, same widgets, same features, same or better output on all existing inputs (deliberate deltas listed in §10 and §15).
6. Every numerical kernel is readable as the formula it implements (coverage, geometry, peak, PLF each fit on a screen with their equation above them).
7. **≈ 2,130 lines budgeted; ≤ 2,500 target; 3,000 ceiling.**

**Non-goals:** new formats/variants, new plots/cuts/metrics, external calibration, a PLF tilt selector, polarisation-tilt-based E/H plane selection, non-uniform (irregular) source grids, a UI-handle struct, in-file self-tests or fixtures, memoisation of columns or coverage distributions, exact (non-interpolated) coverage queries between threshold samples.

---

## 3. Governing rule and invariants

### 3.1 The rule

```matlab
cfg    = app.readConfig();          % the ONLY place widget .Value is read
result = f(data, cfg);              % app-free, alert-free, widget-free
app.apply*(result);                 % the ONLY places Items/Limits/Text/Visible/CData are written
```

Every callback is one expression in the layout: `'ValueChangedFcn', @(~,~) app.on("cut")`. `on(scope)` owns `try/catch`, cancellation, the busy flag, the performance record, build-then-commit and the single `drawnow`.

### 3.2 Invariants (the drop is invalid if any of these move)

| # | Invariant |
|---|---|
| I1 | **Canonical pattern:** polar θ ascending in [0,180], φ ascending in [0,360), **uniform steps asserted once** (`APAT:NonUniformGrid` otherwise, §15-1), grid-native `nθ×nφ`, no seam column. `PhiPeriodic` is a *fact* measured from the source, never assumed (D17). Angles snapped to 5 decimals; **field values never rounded**. |
| I2 | **Separable geometry:** `ΔΩ(i,j) = wθ(i)·Δφ`; `Σ ΔΩ = 4π` exactly on a full sphere (telescoping, B.1). Nothing else measures a step or computes a weight. |
| I3 | **Parameters enter in one function.** `pat_derive(Pattern, Geometry, params)` is the only function that reads loss, Rx mode/AR, Pt or R. It returns every column and every base fact. Nothing downstream adds, scales or shifts a value. |
| I4 | **Physical quantities are defined on total gain** (or the first `gain`-kind column). Component selection changes plots, tables, cuts and the POB marker only. |
| I5 | **Peak policy = spatial isolation.** A sample is a spike iff it exceeds every grid neighbour (4-neighbours, φ-wrap when periodic) by more than `Const.PeakExcessDB = 6` (§15-3). Effective peak = highest non-spike sample. Raw and effective peaks both reported. No percentile, no toolbox. |
| I6 | **Resampling never interpolates dB, AR or PLF.** Exact decimation when `native/target ∈ ℕ`; otherwise bilinear on the φ-closed grid: E-field per component as linear power + unit phasor, gain-kind columns as linear power, other kinds linear (D04, D16). Target axes never leave the source domain (D05). Columns are derived **after** resampling. |
| I7 | **Coverage is the definition, verbatim:** `Coverage(T) = 100·Ω_R(G > T)/Ω_R`, strict `>`, canonical grid only, cone membership by the spherical law of cosines, one kernel (`cov_curve`, A.1). **A coverage job is a curve `{T, cov}`** whether computed or loaded from a results file; every read of a curve — query at T, inverse query at c %, table union — is `interp1` on that curve (§6.9). No distribution cache, no threshold-keyed cache. |
| I8 | **Display invariance:** toggling elevation θ / signed φ changes zero numbers in `Pattern, Geometry, Derived`; cut-value controls follow the display convention (D46). |
| I9 | **Partial-sphere and unit honesty:** efficiency and F/B are `n/a` unless `Geometry.IsFullSphere`; efficiency, EIRP, PFD, E_RMS exist only for `Meta.Unit == "dBi"`; every level label carries `Meta.UnitLabel`. `Meta.Unit` is a static property of the format (§15-4). |
| I10 | **Circular decomposition** lives in one function (`pol_circular`, A.4) with `E_R = (Eθ + jEφ)/√2`, `E_L = (Eθ − jEφ)/√2` — the IEEE right-hand component under `e^{+jωt}` (B.4). |
| I11 | **Widgets:** read only in `readConfig`/`readCoverageConfig`; written only in `apply*`/renderers. No `.UserData` on widgets. No `findall`; `findobj` at exactly one site (user-created datatips in Coverage "Clear", §7.4). UI handles stay declared properties (App Designer style, §15-7). |
| I12 | **Graphics are retained:** each view owns its handles in `Gfx`; `cla` only when grid size changes; render only the visible full-pattern tab. |
| I13 | **Build-then-commit:** every `update` stage computes into locals and assigns the registry entry in one final step; cancel or error leaves the previous state fully intact (D44). |
| I14 | **One pattern registry.** `app.Pats(k)` holds `{Name, Path, Source, Pattern, Geometry, Derived, Params}`; the Main tab is `app.Pats(app.Main)`; coverage tree nodes store `k`. No second copy, no sync function. The coverage tree **is** the job registry (§6.9). |
| I15 | **One file, no toolboxes**, R2023b baseline; every widget of M7 exists with the same property name, parent, row/column and defaults (checked against the M7 inventory during the layout step, §12-7). |
| I16 | **Measured, not assumed:** `app.Perf` records every `on(scope)` with per-stage seconds in the same record shape M7 writes (§7.5), so M7 and M8 timings compare directly. |

---

## 4. Architecture

### 4.1 M7 dataflow today — hazards marked

```
FILE → readPattern   ICOMP≠2 read as θ/φ ⚠D19 · UAN header ignored ⚠D21 · FFE blocks merged ⚠D22
     │               raw fields as dBi ⚠D23 · rmmissing ⚠D24 · span/">100" heuristics ⚠D25 D26 · cov detector ⚠D27
     │               Excel summary: 164 lines → one unused flag ⚠D30
     → rawTbl + blocks{}
     → normalizePattern (rounds FIELDS ⚠D03 · elevation heuristic ⚠D28 · seam always ⚠D17 · no spacing check ⚠D18) → stdTbl
     └─ refresh
        ├─ calcPattern(stdTbl) → patTbl                       (discarded when 1° follows ⚠D09)
        ├─ applyStep → integer filter ⚠D06 | resample Re/Im 'nearest' to full sphere ⚠D04 D05 | dB linear on regular grids ⚠D16
        │            → calcPattern → viewBaseTbl
        └─ applyAngularSpan → copy 17 cols, rewrite θ/φ, sortrows → viewTbl (+viewRevision ⚠D38)
           ├─ detectOrientation(viewTbl, comp ⚠D12) → solidWeights(display θ ⚠D02) → viewSolidAngle
           ├─ resolvePeak(prctile ⚠D01) → POB; calcMetrics(component peak ⚠D12, display θ ⚠D02, spikes ∫-only ⚠D07)
           ├─ PLF: NaN → linear ⚠D08 · pol label sphere-mean ⚠D13
           ├─ 5× cla+surf ⚠D57 · new menus ⚠D58 · colorbar/triad ⚠D59 · uitable ← 65k×17 ⚠D43 · cutData ×3 ⚠D61
           ├─ EHplane → onCutChanged → drawSpatial3D → drawPattern3D ×2, then renderAllFullPatterns ×5 ⚠D72
           ├─ Process/params → whole refresh: cut reset, colour range reset, 5 renders ⚠D55
           ├─ gain-only cut = column 3 regardless of component ⚠D15
           └─ Coverage: node ← viewTbl ×2 ⚠D36 · N×T logical→double 261 MB ⚠D10 · cache keyed by thresholds + eager inverse ⚠D56
                        presets widen ⚠D39 · dead range state ⚠D45 · getter writes a spinner ⚠D48 · dead node fields ⚠D49 D54
                        checkbox → percentile cascade ⚠D37 · setCoverageUI ×7 ⚠D53 · query tip: helper + 3 fallbacks ⚠D74
```

### 4.2 M8 dataflow — destination

```
FILE ─► io_read(path, fmt) ─► Source { Raw(table, Input tab), Blocks{f} (nθ×nφ×4 | nθ×nφ×nC), Theta, Phi, Freqs,
                                       Meta{Format, Unit, UnitLabel, IsGainOnly, ColNames, Notes} }
                                  ▼
       pat_build(Source, f) ─► Pattern { Theta[nθ], Phi[nφ], dTheta, dPhi, Eth, Eph (complex nθ×nφ) | G.(name) (nθ×nφ),
                                         IsGainOnly, Freq, Revision, Meta }        asserts I1 once (uniform, regular)
                                  ▼
       optional pat_resample(Pattern, step) → Revision++ (I6)
       geo_build(Pattern) ─► Geometry { wTheta[nθ], dPhi, dOmega (nθ×nφ), Omega, PhiPeriodic, IsFullSphere }
                                  ▼
       pat_derive(Pattern, Geometry, params) ─► Derived { Cols.(name) (nθ×nφ, every column, at the current params),
                                                          Peak, Pol{pairs,label}, Boresight, Planes{E,H}, Metrics }
                                  ▼
       app.Pats(k) = { Name, Path, Source, Pattern, Geometry, Derived, Params }   ◄── ONE entry per loaded file (I14)
                    │  Main tab reads Pats(app.Main); a coverage tree node stores k
                    ▼
       View = readConfig()   component, cut, span, ranges, params{L, Rx, Pt, R}, freqIndex, stepChoice, traces — never copies Pattern
       Map  = geo_displayMap(Geometry, View)   { ColIdx, ThetaAxis, PhiAxis, ThetaDir, labels, ticks }
       ┌──────────┬───────────┬───────────┬──────────────┬───────────┬───────────┐
       ▼          ▼           ▼           ▼              ▼           ▼           ▼
     PLOTS      CUTS       METRICS     COVERAGE        TABLES      EXPORT     METADATA
   Cols(:,ColIdx) geo_cut  Derived.Metrics cov_curve(Cols.(c)) lazy, mask   lazy      conventions, unit, notes
```

**Dependency graph** (kept as the comment block above `update`):

```
SOURCE ─► PATTERN(Rev) ─► GEOMETRY ─► DERIVED(Rev, Params)        all stored in Pats(k)
                                        │
                                        ├─► PLOTS / CUTS / TABLES / METADATA (+Map)
                                        └─► COVERAGE job = curve {T, cov}      (tree node)
VIEW ─► MAP ─► ColIdx / axes / ticks / labels / cut-value domain    (touches nothing above)
```

If a function needs something not on a path from its inputs, it is reaching into the app; that line does not belong in M8.

### 4.3 Layer contracts

| Layer | Object | Writer | Readers | Forbidden |
|---|---|---|---|---|
| Source | `Pats(k).Source` | `io_read` | `update("source")`, Input tab | math, renderers |
| Pattern | `Pats(k).Pattern` | `pat_build`, `pat_resample` (committed by `update`) | all below | widget values, `cla` |
| Geometry | `Pats(k).Geometry` | `geo_build` (on Revision change) | derive, coverage, plots | any second step measurement |
| Derived | `Pats(k).Derived` | `pat_derive` (on Revision or Params change) | plots, cuts, tables, export, coverage, metadata, status | reading a widget; being partially recomputed |
| View / Map | `app.View`, `app.Map` | `readConfig`, `geo_displayMap` | orchestration, renderers | math kernels |
| Conventions | `Const.*`, `Meta.*` | file section B / readers | everything | literals `sqrt(2)`, `1i*`, `cosd(180)`, `"dBi"`, `-100` anywhere else |
| Coverage node | `NodeData` | coverage `apply*` | tree, curves, table, queries | pattern copies; a pattern node holds only `k`; a job holds `{id, label, T, cov, Line, Query}` |
| Graphics | `app.Gfx` | renderers | renderers | `findall`/Tag search |
| Layout | `createComponents` | `place`, `labelled`, `patternTab` | — | `Layout.Row =` outside `place` |
| Perf | `app.Perf` | `perf` (called by `on` and `update`) | the developer | anything else |

Validity is one comparison per layer (`Revision`, `Params`). No flag families, no widget `UserData`, no cache keys.

### 4.4 Why this is shorter

| Concept | M7 | M8 | What vanishes |
|---|---|---|---|
| Physical vs display angles | `viewTbl` + `physicalTheta` ×13 | `Pattern` is polar; `Map` is a permutation + labels | `applyAngularSpan`, `physicalTheta`, seam duplication, D02/D38/D46 |
| Pattern identity | 6 tables (+2 per node) | `Pats(k)` with one `Derived` | five properties and every assignment to them |
| Main ↔ Coverage | node copies + `syncCoverageNodeFromView`, `syncCoveragePattern`, `covPatternTarget`, `covFindByPath`, `covJobs` | node stores `k`; `Pats` is the single source; the tree is the job list | five functions + one property, `orientationComponent`, `componentBounds`, `sourceTable`, `viewRevision` on nodes (D36, D37, D49) |
| Step / seam / ΔΩ | `gridStep` ×17, `solidWeights` ×6, `gridCache` | `Pattern.dTheta/dPhi`, `Geometry.dOmega` | all of them, plus `emptyGridCache` (D50) |
| Processing | `calcPattern` (17 eager columns into a table) + `resolvePeak` ×10 + `calcOrientation` + `calcMetrics` with constants threaded through six signatures | `pat_derive` — one function, matrices in, struct out, once per (Revision, Params) | `calcPattern`, `chooseGain`, `componentMap`, `isARComponent`, `isGainDBColumn`, `HiddenOutputColumns`, `robustRange`, constant threading (D47), `detectOrientation`, `computeMetrics`, `updateSelectedComponentPeak` |
| Parameters | `FieldScale` through the whole pipeline; a change re-runs the full refresh (cut reset, range reset, 5 renders) | `pat_derive` again (≈ 40 ms) → redraw the visible tab, cut `YData`, metadata | D55 and the whole `refresh` cascade |
| Cut geometry | `cutGeometry` ≡ `calcCutGeometry`; `cutData` ×3 per change; `cutCols` | `geo_cut` (slices) once per change | one twin, the status side effect, two extractions, D15 |
| Coverage | `coverageCCDF` N×T + node cache keyed by thresholds + eager inverse + 2 query interpolations + interpolation-location helper + 3 datatip fallbacks + 5 label variants | `cov_curve` (5 lines) → curve; `cov_at`/`thr_at` (one `interp1` each); one label | `coverageCacheKey`, `coverageCache`, `inverseCov/inverseThr`, `coverageQueryPoint`, `coverageInterpolationLocation`, `coverageArtifacts`, the 261 MB transient (D10, D56, D74) |
| Circular split | 4 inline copies | `pol_circular` (+ inverse) | 3 copies |
| Resampling | regular + scattered paths, `'nearest'` extrapolation, integer filter | decimate-or-bilinear on the uniform grid | `interpolateScattered`, `scatteredInterpolant`, `Extrapolation` option, the 0.3° trap (D06) |
| Readers | 5 near-identical six-column cases + 6 generic variants; 164-line Excel summary | one `io_fields(M, spec)` + a 9-row spec table; one `xl_lookup` for the frequency cell | ≈ 120 + ≈ 150 lines (D30) |
| Reader disclosure | 6 boolean/enum flags in `userData` | `Meta.Notes` (string array shown in Metadata) | `validateSourceModel`, `isDep/isMultiBlock/hasFrequency/quantityType/absoluteCalibration/polarizationBasis` |
| Range UI | `onRangeUIChanged` scopes + coverage twins + startup arrays + 9-field state (4 dead) | one descriptor-driven `applyRange(group, limits)` + `Range.Auto` per group | `syncCoverageXRange`, `setCoverageRange`, `coverageRangeState`, `markCoverageThresholdUserEdit` (D45) |
| Visibility | `updateInputVisibility`, `refresh` block (360–372), `onComponentChanged` block, `setCoverageUI` ×7 call sites, `setControls` | `applyVisibility` once at the end of `update` | four functions and the cascade of D53 |
| Annotations | ≈ 250 lines over 6 functions | handles created once, `Visible` toggled | the whole layer |
| Status | timer per message + `UserData` | one timer + `app.Status` | `restoreStatus`, `disposeStatusTimer`, `stopStatusTimer` |
| Performance tracking | `startPerf` closures + `perfTracker` handle + 26 call-site tokens | `perf(stage)` — 8 lines, begin/end automatic in `on` | nested functions, the handle property |
| Orchestration | 14 functions (`refresh … syncCoverageNodeFromView`) | `update(scope)` | ≈ 500 lines of bodies |
| Layout | 622 lines, 185 `Layout.*` statements | `place()` — one line per widget | ≈ 320 lines |
| Self-test | `runSelfTest` (144 lines) | none | the method |

---

## 5. Data model

### 5.1 Schemas (factory functions in file section B)

```matlab
Source   = struct('Raw',table,'Blocks',{{}},'Theta',[],'Phi',[],'Freqs',NaN,'Meta',meta)
Meta     = struct('Format',"",'Unit',"dBi"|"dB",'UnitLabel',"dBi"|"dB (rel. field)",'IsGainOnly',false, ...
                  'ColNames',strings(0),'Notes',strings(0))        % Notes: one sentence per reader decision, shown in Metadata
Pattern  = struct('Theta',[],'Phi',[],'dTheta',NaN,'dPhi',NaN,'Eth',[],'Eph',[],'G',struct(), ...
                  'IsGainOnly',false,'Freq',NaN,'Revision',0,'Meta',meta)
Geometry = struct('wTheta',[],'dPhi',NaN,'dOmega',[],'Omega',NaN,'PhiPeriodic',false,'IsFullSphere',false)
Params   = struct('L',0,'RxMode',"Auto",'RxAR_dB',6,'Pt_dBW',0,'R_m',1)      % read once by readConfig, consumed by pat_derive only
Derived  = struct('Cols',struct(),'Peak',peak,'Pol',struct('pairs',...,'label',""),'Boresight',1, ...
                  'Planes',struct('E',[type value],'H',[type value]),'Metrics',metrics)
View     = struct('Component',"",'Cut',struct('type',"Theta",'value',0),'SignedPhi',false,'Elevation',false, ...
                  'Basis',"Circular",'BasisAuto',true,'Traces',[true true true],'HPBW',false,'POB',false, ...
                  'StepChoice',"native",'FreqIndex',1,'OutMask',logical([]),'Camera',...)
Range    = struct('full',[-40 10],'cut',[-40 10],'cov',[-40 10],'covX',[-40 10],'Auto',struct('full',true,...))
```

- `Pattern.G` (gain-only) is a struct of `nθ×nφ` matrices named by `Meta.ColNames`.
- `Derived.Cols` holds **every** column of §5.2 that exists for the source, already at the current `Params`. There is no lazy column, no memo key, no `+L` anywhere downstream (I3).
- A `Pats` entry made on the Coverage tab is derived with the parameters current at load time; its `Params` are shown in the node tooltip and in every job label (`L=<L> dB`). Re-deriving a foreign entry is one `pat_derive` call, triggered when its node is selected and the Main parameters differ (`Params` mismatch is the only test).

### 5.2 Column table — `Const.Cols` (metadata only; formulas live in `pat_derive`)

```matlab
%  name                   label            kind      unit     hidden
Cols = colDefs({ ...
 'E_Total_dB'            'Total Gain'     'gain'    'level'  false
 'E_TH_dB'               'Etheta Gain'    'gain'    'level'  true
 'E_PH_dB'               'Ephi Gain'      'gain'    'level'  true
 'E_RCP_dB'              'RHCP Gain'      'gain'    'level'  false
 'E_LCP_dB'              'LHCP Gain'      'gain'    'level'  false
 'AR_dB'                 'Axial Ratio'    'ar'      'dB'     false
 'PLF_dB'                'PLF'            'plf'     'dB'     false
 'Gain_PolCorrected_dB'  'Polarized Gain' 'gain'    'level'  false
 'E_TH_Phase'            'Etheta Phase'   'phase'   'deg'    true
 'E_PH_Phase'            'Ephi Phase'     'phase'   'deg'    true
 'E_RCP_Phase'           'RHCP Phase'     'phase'   'deg'    true
 'E_LCP_Phase'           'LHCP Phase'     'phase'   'deg'    true
 'EIRP_dBW'              'EIRP'           'link'    'dBW'    true
 'PFD_Wm2'               'PFD'            'link'    'W/m^2'  true
 'E_RMS_Vm'              'E_RMS'          'link'    'V/m'    true
});
```

- **Formulas** are plain assignments in `pat_derive` (A.3), one line each, in this order, so the reader sees the mathematics in code rather than in anonymous functions inside a table.
- **Gain-only sources:** rows are synthesised from `Meta.ColNames` with `kind = util_colKind(name)` (`gain|directivity|eirp|…db` → `gain`, `ar|axial` → `ar`, `phase|deg` → `phase`, else `other`; `other` never receives loss and is never the peak column). The peak column is the first `gain` row (D14). **Cuts and coverage use the selected column** (D15, §15-8).
- One array drives: component dropdown items (`kind ∈ {gain, ar, plf}` ∩ available), Results-filter defaults (`hidden`), colour theme (`kind == "ar"` → signed map, `Const.ARLimits = [−30 30]`), cut trace pairs, coverage component list, parameter-control visibility (`plf` → Rx controls, `link` → Pt/R controls, `gain` present → Loss), unit labels, and the resampling domain (`gain` → linear power).

### 5.3 View table — `Const.Views` (five full-pattern tabs behind one renderer)

```matlab
%  name        axesProp              rangeProp       kind        camera
Views = {'contour'  'Single_Axes_Ctr'    'Range_Ctr'    'pcolor'    []
         'circular' 'Single_paxPattern'  'Range_Cir'    'fisheye'   []
         'sphere3D' 'Single_Axes_3dSph'  'Range_3dSph'  'sphere'    [135 25]
         'polar3D'  'Single_Axes_3dPol'  'Range_3dPol'  'polar'     [135 25]
         'rect3D'   'Single_Axes_3dRect' 'Range_3dRect' 'rect'      [-35 35]};
```

`renderFull(k)` reads this row; the only per-kind code is the coordinate expression (§8).

### 5.4 Range groups — `Const.RangeGroups`

```matlab
%  group   sliders (props)                                              minSpinners (5|1|1|1)  maxSpinners  hard        minGap
   full    {Range_Ctr Range_Cir Range_3dSph Range_3dPol Range_3dRect}   …                      …            [-250 100]  1
   cut     {Range_Cut}                                                  {Range_Cut_Min}        {Range_Cut_Max}          [-250 100]  1
   cov     {}                                                           {Cov_Spinner_ThreshMin} {Cov_Spinner_ThreshMax} [-250 100]  0.1
   covX    {Cov_Spinner_XRange}                                         {Cov_Spinner_XMin}     {Cov_Spinner_XMax}       [-250 100]  0.1
```

`applyRange(group, limits)` is the only writer of these widgets (§7.4).

### 5.5 Pattern registry — `app.Pats`

- `update("source")` replaces the entry with the same `Path` (build-then-commit, I13) and sets `app.Main`.
- The Coverage "Main → Coverage" button adds a tree node with `k = app.Main` (or selects the existing one). A file loaded on the Coverage tab creates an entry through the same `pat_build → geo_build → pat_derive` chain — **one code path for both tabs** (D36).
- A `step`/`freq`/`params` change on the Main tab rewrites `Pats(app.Main)` in place; coverage nodes that reference it see the new `Derived` on their next compute. Existing job curves are results of the run that produced them and are never invalidated (their label records component, region and `L`).
- `Cov_Button_Reset` deletes coverage nodes and every `Pats` entry not referenced by the Main tab.

---

## 6. Pipelines

### 6.1 Import — `io_read(path, textFormat)`

One dispatcher by extension; every reader returns a `Source`. Rules shared by all readers:

- `Meta.Unit/UnitLabel` is fixed per format (§15-4): UAN/FZ/OUT/Excel → `dBi`; FFD/FFE/FFS/CUT/generic E-field → `dB (rel. field)`; gain-only → `dBi` when a header says `dBi`, else `dB`.
- Every heuristic decision (axis order by span, magnitude/phase layout, elevation fold, body of revolution) becomes one sentence in `Meta.Notes` (D20, D25, D26, D28).
- Six-column field files (UAN/FZ, OUT, FFD, FFE, FFS, generic linear/rcp/lcp × rect/magphase) go through **one** `io_fields(M, spec)` (A.10) with a nine-row spec table (column order, magnitude domain, basis). The CUT reader keeps its block parser; `ICOMP ∉ {1,2}` errors (D19); `ICOMP = 2` uses `pol_fromCircular`.
- UAN header lines are validated (`APAT:UnsupportedUAN`, D21). FEKO FFE splits blocks on `#Frequency:`; FFD keeps its block split; both fill `Source.Freqs` and the frequency dropdown (D22).
- Generic text: `rmmissing` only on θ/φ and the used columns (D24); coverage detection = `threshold/coverage` keyword **or** the strict no-header rule (D27).
- Excel matrix workbooks: one `readExcelMatrix` (sheet discovery + matrix read kept, the duplicated `raw`/`block` construction 4318–4326 collapsed), and **one** `xl_lookup(summarySheet, 'Pattern Simulation Freq (MHz):')` for the frequency (A.11) — the remaining 164 lines of summary parsing are deleted (D30).

### 6.2 Canonicalise — `pat_build(Source, f)`

1. Fold θ < 0 (elevation input, per reader) to polar; drop a φ = 360 column when a φ = 0 column exists (the seam is a *display* artefact); snap angles to 5 decimals; sort both axes.
2. Assert uniform, regular axes once (`util_assertUniform`, A.12) — otherwise `APAT:NonUniformGrid` with the offending axis and gaps in the message (§15-1, D18).
3. Reshape the four field columns (or the gain columns) to `nθ×nφ` by index arithmetic, not by `unique/ismember`.
4. `Revision = 1`; `pat_resample` increments it.

### 6.3 Resample — `pat_resample(Pattern, stepDeg)`

- `kθ = dTheta_target/dTheta`, `kφ` likewise. If both are integers within `1e-9`: **decimate** (`P.Eth(1:kθ:end, 1:kφ:end)`), exact by construction (D06).
- Otherwise: target axes `θ' = θ₁ : step : θₙ`, `φ' = φ₁ : step : φₘ` (never outside the source domain, D05); bilinear `interp2` on the φ-closed grid when periodic (append column 1 at φₘ + Δφ), per quantity:
  - E-field: `|E|²` and `E/|E|` per component, recombined as `sqrt(P')·u'/|u'|` (B.5) — one `pat_interp(X, kind)` for `"power"`, `"phasor"`, `"linear"` (D04).
  - Gain-only: `gain` kind as linear power (`10^(G/10)` → interpolate → `10·log10`), others linear (D16).
- `Revision++`; columns are derived afterwards (I6, D09).

### 6.4 Geometry — `geo_build(Pattern)` (A.2)

`wTheta`, `dPhi`, `dOmega = wTheta·dPhi` (stored, 0.5 MB at 1°), `Omega`, `PhiPeriodic`, `IsFullSphere`. The integral of any grid is `sum(X .* G.dOmega, 'all', 'omitnan')`.

### 6.5 Derive — `pat_derive(P, G, prm)` (A.3) — once per (Revision, Params)

In this order, each a few lines:

1. **Columns** (`Derived.Cols`) for E-field sources: `Eth·s, Eph·s` with `s = 10^(L/20)`; total, θ, φ, RHCP, LHCP levels; phases; signed AR (A.5); PLF (A.6); polarised gain; EIRP, PFD, E_RMS. Gain-only sources: `Cols.(name) = G.(name) + L` for `gain` kinds, unchanged otherwise (D14).
2. **Peak** on the total-gain column (`met_peak`, I5).
3. **Polarisation**: pairs and label from the main-beam region (samples within the boresight cone, Ω-weighted mean power), not the sphere mean (D13); Rx `Auto` sense from the leading circular pair member.
4. **Boresight**: `met_orientation` — principal axis whose 45° cone holds the most `10^{G/10}·ΔΩ` (M7 rule 4845–4850) with the same spherical-law-of-cosines test as the coverage cone.
5. **Planes**: `met_planes(axis)` (A.7).
6. **Metrics** (`met_metrics`): directivity `10·log10(4π·10^{Gp/10}/∫10^{G/10}dΩ)` with spikes removed from **both** numerator and `Ω` (`keep` mask, D07); efficiency `100·∫10^{G/10}dΩ/4π` only when `IsFullSphere && Unit == "dBi"`; F/B on the antipode of the peak, `n/a` unless `IsFullSphere` (I9); HPBW on the E and H cuts through `geo_cut` + `met_hpbw` (M7 `calcHPBW` verbatim); AR at the peak.

The cost at 1°×1° is ≈ 40 ms. Because that is below one frame, `pat_derive` is simply called again whenever `Revision` or `Params` change; there is no per-column memo, no loss offset and no `Rx` key (I3).

### 6.6 Parameters

`readConfig` converts the widgets once: `L` in dB, `Pt_dBW` (`dBm → −30`, `W → 10·log10`), `R_m` (`km → ×1000`, floor `Const.DistanceFloorM`). The **Process** button is `on("params")`: `pat_derive` → commit → redraw the visible tab, cut traces, metadata, tables if visible. It does **not** touch the cut controls, the colour ranges or the step choice (D55).

### 6.7 Metrics — `met_*`

All on total gain (I4). `met_peak` (A.3.1), `met_orientation`, `met_planes` (A.7), `met_hpbw`, `met_metrics`. Status reads "POB" only for total gain and "Peak of *<component>*" otherwise (D12).

### 6.8 Cuts — `geo_cut(P, C, type, value)`

Returns `{angle (0..360), y, theta, phi, fixed, snapped}` from two column slices (`Theta` cut: φ and φ+180) or one row slice (`Phi` cut); closing point appended for the polar line. One call per cut change serves the polar cut, the rectangular cut, both 3-D overlays and HPBW (D61). Gain-only cuts use `View.Component` (D15). Angles are remapped to the display convention by `Map` at render time; the cut-value spinner domain comes from `Map` too (D46).

### 6.9 Coverage — `cov_*` (I7, A.1) — the definition, written out

**Definition.** For a region `R` of the sampled sphere (whole sphere, or a cone of half-angle α about `(θc, φc)`) and a level grid `G` (dB):

```
ΔΩ(i,j)     = wθ(i) · Δφ                                    cell solid angle (Geometry, §6.4)
Ω_R         = Σ_{(i,j)∈R, G finite}      ΔΩ(i,j)            solid angle of the region
Ω_R(G > T)  = Σ_{(i,j)∈R, G(i,j) > T}    ΔΩ(i,j)            solid angle where the level exceeds T
Coverage(T) = 100 · Ω_R(G > T) / Ω_R     [%]                strict ">"; non-increasing in T
```

**Region.** `(i,j) ∈ cone ⇔ cos γᵢⱼ ≥ cos α`, `cos γᵢⱼ = cos θᵢ cos θc + sin θᵢ sin θc cos(φⱼ − φc)` (spherical law of cosines, one line). Spherical coverage: every sample. Empty region → `Coverage ≡ 0` and the status says so.

**Kernel — one function, five lines (A.1):** `cov = cov_curve(C, G.dOmega, mask, T)` evaluates the definition at every requested `T` (`arrayfun` over thresholds; memory `O(N)`; 501 × 65k ≈ 30 ms). There is no indicator matrix (M7's `N×T` logical is promoted to double inside `mtimes`, 261 MB at 65k × 501, D10), no sorted distribution, no cache.

**A job is a curve.** `Compute Coverage` calls `cov_curve` on `Pats(k).Derived.Cols.(component)` (already at the current `L`, I3) with the current thresholds and region, plots one line, and stores `{id, label, T, cov, Line, Query}` in the job node. A job loaded from a results file stores exactly the same fields from the file's columns. From here on **nothing distinguishes the two**.

**Every read of a curve is the same idiom** (A.1):

```matlab
cov_at(job, T)   →  interp1(job.T, job.cov, T, 'linear', NaN)                     % "Coverage at T"
thr_at(job, c)   →  [cv, i] = unique(job.cov, 'last');  interp1(cv, job.T(i), c, 'linear', NaN)   % "Threshold at c %"
```

`unique(…, 'last')` keeps, for each coverage level, the **highest** threshold that still reaches it, which makes the non-increasing curve strictly monotone for `interp1` and returns the upper end of every plateau. Both are linear reads of the sampled curve between its threshold samples; the threshold step is the fidelity control, exactly as in M7. The table rows are the union of the checked jobs' thresholds and every cell is `cov_at(job, T_union)` (`NaN` → blank outside a curve's range).

**Recompute instead of cache.** A changed threshold vector, region or component is a new `Compute` click and a new 30 ms `cov_curve`. No threshold-keyed cache, no eager inverse curve, no `coverageCache` on nodes (D10, D56).

**Thresholds.** `T = tMin + (0:n).'·step`, `n = round((tMax − tMin)/step)` — by counting (D11), read by `readCoverageConfig` **without writing any widget** (D48).

**Orientation for conical jobs.** `Auto` resolves to `Pats(k).Derived.Boresight` (total gain, once per derivation — no per-click recomputation, D37); an explicit axis sets the cone-centre spinners; the spinner values are authoritative for the region, as in M7. The job label records the actual centre; there is no `orientationMode` field (D49).

**Jobs.** The coverage tree **is** the job registry: pattern/results nodes are children of the Results root, jobs are their children; `jobs = [app.Cov_TreeNode_Results.Children.Children]` (there is no `covJobs` property). A job node holds `{id, label, T, cov, Line, Query}` — nothing else (D49, D54).

**Presets.** Threshold window and X-range from `util_presetRange(Derived.Peak of the selected column)` while `Range.Auto.cov/covX`; never widen on their own; a user edit clears `Auto` (D39, D45).

**Queries.** "Coverage at T" = `cov_at`; "Threshold at c %" = `thr_at`. One `datatip(job.Line, x, y)` at the coordinate (R2023b accepts the coordinate form; no `DataIndex`/`InterpolationFactor` bookkeeping, no fallback chain, D74), two projection lines from `ax.XLim(1)`/`ax.YLim(1)` (D65), handles stored in `job.Query` so check/uncheck, Clear and Reset are `set(...,'Visible')`/`delete` on known handles.

**Labels.** One job label `R<id> <region> · <column> · L=<L> dB`; the table column name is derived from it — replacing M7's five variants (`tag, tagFull, tableTag, displayTag, label`, 2329–2343, 1701–1708). Selection status: the label, `Coverage at 50 %` via `thr_at`, and the curve maximum.

### 6.10 Export — lazy, canonical

- **Results:** built on demand from `Derived.Cols` (checked columns), angles in the *display* convention via `Map` — from data, not from the `uitable` (2142).
- **Cut:** the current `geo_cut` struct.
- **UAN:** from `Pattern` scaled by `10^(L/20)`, canonical φ ∈ [0,360) + closing column as XGTD expects, `maximum_gain` = total-gain peak (D29).
- **Coverage table:** the table as displayed.
- One `writeTable(T, path)` chooses tab/comma/xlsx by extension; `writeUAN` adds the header.

---

## 7. Orchestration

### 7.1 `readConfig` / `readCoverageConfig`

The only functions that read widget values. They return `View` + `Params` (§5.1) and a coverage counterpart (`component, thresholds, region, query`). Step choice, cut-basis auto-selection (`BasisAuto`) and the output-filter mask live in `View` (D34), initialised from the source on `update("source")`. Neither function writes a widget (D48).

### 7.2 `update(app, scope)` — the dispatcher

| User action | scope | Recompute | Render |
|---|---|---|---|
| Load / Process-with-format-change / text format | `source` | `io_read → pat_build → (resample if 1°) → geo_build → pat_derive` → **commit `Pats(k)`** | `applyChoices`, metadata, presets (if `Auto`), visible full tab, cuts, tables if visible |
| Frequency block (FFD/FFE) | `freq` | `pat_build(block) → geo_build → pat_derive` → commit | as `source` minus choices |
| Native ↔ 1° | `step` | `pat_resample → geo_build → pat_derive` → commit | as `freq` |
| Process (loss / Rx / Pt / R) | `params` | `pat_derive` → commit | `CData` visible tab, cut `YData`, metadata rows, tables if visible — cut controls and ranges untouched (D55) |
| Component | `component` | nothing | `CData` visible tab (+ radius on polar-3D, `ZData` rect-3D), cut traces for gain-only, POB, titles, colorbar theme |
| Elevation / signed φ | `span` | **nothing numeric**; `geo_displayMap` | `CData(:,ColIdx)`, axes vectors, ticks, labels, cut `XData` remap, cut-value domain, POB re-index |
| Cut controls / E-H / basis / traces | `cut` | `geo_cut` | cut lines + both overlays from one extract, HPBW |
| Ranges / colour step | `range` | nothing | `clim/zlim/RLim` + ticks of the visible tab; other tabs dirty |
| POB / HPBW toggles / tab change | `annot` | nothing | `Visible` of registry handles; **stale tab → render on selection** |
| 3-D view | `camera` | nothing | `view/camup` |
| Coverage load / Main→Coverage | `covSource` | `io_read → … → pat_derive` into a new `Pats` entry (or select existing) | tree node, presets |
| Coverage compute | `covRun` | `cov_curve` | curve, table, legend, status |
| Coverage thresholds / query / check / select | `covQuery` | `cov_at` / `thr_at` | line `Visible`, table, query tips, highlight |

Ladder: `source ⊃ freq ⊃ step ⊃ params ⊃ {component, span, cut, range, annot, camera}`. `update` runs the stages at or below the requested rung, calls `perf(stage)` after each, marks non-visible full-pattern tabs dirty, renders the visible one, ends with **one** `applyVisibility` (D53, D69) and returns; `on` issues the single `drawnow limitrate`. Overlays are drawn by `renderFull` only (D72).

Deleted as bodies: `refresh`, `updateViewResults`, `refreshAngularView`, `applyStep`, `applyAngularSpan`, `stepChanged`, `onComponentChanged`, `renderAllFullPatterns`, `drawSpatial3D`, `initRanges`, `selectBlock`, `activateSource`, `buildPatternData`, `prepareTextFormat`, `onTextFormatChanged`, `onCovTextFormatChanged`, `syncCoveragePattern`, `syncCoverageNodeFromView`, `covPatternTarget`, `covFindByPath`, `covJobNodes`, `gridComp`, `gridGeom`, `invalidateDerived`, `emptyGridCache`, `physicalTheta`, `cutGeometry`, `calcCutGeometry`, `cutData`, `cutCols`, `componentMap`, `preferredComponent`, `updateComponentItems`, `updateSelectedComponentPeak`, `computeMetrics`, `planeSettings`, `updateCutControl`, `updateInputVisibility`, `setCoverageUI`, `setControls`, `gainDisplayRange`, `coverageDisplayRange`, `robustRange`, `onRangeUIChanged`, `setCoverageRange`, `syncCoverageXRange`, `markCoverageThresholdUserEdit`, `clearCoverageSync`, `coverageCacheKey`, `covThresholds`, `coverageInterpolationLocation`, `coverageQueryPoint`, `coverageSummaryMaximum`, `coverageTableTag`, `coneCenterLabel`, `coverageArtifacts`, `clearAnnotations`, `refreshAnnotations`, `createPOBDataTip`, `ensureFullPatternPOBAnnotations`, `initializeFullPatternPOBRecords`, `updateFullPatternPOBVisibility`, `findRenderedPatternSurface`, `configurePlotContextMenu`, `startPerf`, `restoreStatus`, `disposeStatusTimer`, `stopStatusTimer`, `detectOrientation`, `calcOrientation`, `calcPattern`, `calcMetrics`, `resolvePeak`, `coverageCCDF`, `getParam`, `resetParams` (becomes `applyChoices` defaults + `on("params")`), `runSelfTest`, `readExcelSummary`, `summaryValue`, `summaryRowValue`, `summaryNumeric`, `findSummaryLabel`, `normalizeSummaryLabel`, `interpolateRegular`, `interpolateScattered`, `isGainDBColumn`, `validateSourceModel`, `chooseGain`, `solidWeights`, `gridStep`, `normalizePattern`, `resampleCanonical`.

### 7.3 `on` — guard: try/catch, cancel, busy, build-then-commit, timing

```matlab
function on(app, scope, title)
if app.Busy, return; end                              % drops re-entrant slider storms
app.Busy = true; c = onCleanup(@() app.setBusy(false));
app.perf("begin " + scope);
try
    app.update(scope); drawnow limitrate
catch err
    if err.identifier == "APAT:Cancelled", app.setStatus(app.Single_StatusBar, 'Cancelled.', true);
    else, app.showError(err, title); end               % state untouched: update commits only at its end (I13)
end
app.perf("end");
end
```

Long stages (`source`, `step`, `covSource`) run behind the existing cancellable `uiprogressdlg`; `checkCancelled` sits between stages, not inside kernels. Coverage load parses **inside** the guard (D64). Same-file reselect = reload (D42).

### 7.4 `applyChoices`, `applyVisibility`, `applyRange`, status, lifecycle

- `applyChoices` — the only writer of data-derived `Items/ItemsData/Limits/Step/Text`: component items (Main and Coverage) from `Cols ∩ available`, cut-value limits/step from `Pattern` via `Map` (once, D40/D46), step dropdown items (**one** item when the native step already is 1°, D52), block items, trace checkbox labels, parameter defaults (the former `resetParams`).
- `applyVisibility` — the only writer of `Visible/Enable`, computed from `Meta`, `View.Component` kind and coverage state; called once at the end of every `update` (D53); parameter controls follow the **selected component and source kind**, not the table filter (D69).
- `applyRange(group, limits)` — one descriptor-driven controller for the four groups of §5.4: widen-then-set slider limits, spinner limits `[hard(1), hi−gap]`/`[lo+gap, hard(2)]`, then the axes (`clim/zlim/RLim/XLim`). The AR theme sets **only** `full` to `Const.ARLimits` (D41). `Range.Auto.(group)` becomes false on the first user edit; presets re-apply on `source/freq/step` only and never widen by themselves (D39).
- Status: one reusable `timer` created in `startupFcn` (D63); `setStatus(label, msg, transient)` in six lines (A.14); persistent message stored in `app.Status.(label)`, not in widget `UserData`. Status names the component ("Peak of *Axial Ratio*") and reserves "POB" for total gain (D12).
- Coverage "Clear": deletes `job.Query` handles and `findobj(job.Line, 'Type', 'datatip')` (user-created tips are not app-owned) for the selected subtree — the one permitted `findobj` (I11). "Reset": `delete(app.Cov_TreeNode_Results.Children)`, drop unreferenced `Pats` entries, `applyRange("covX", default)`.
- Window title from `Const.ReleaseName` (D71).
- Lifecycle: `shutdown` stops the timer, deletes the dialog and the context menu, clears `Gfx`; `delete`/`closeRequest` call it once.

### 7.5 Performance tracker — `perf(app, stage)` (kept, eight lines)

Purpose: measure M8 against M7 with the same record. M7 writes `Perf_APAT_v3_M7_110_5 = {AppVersion, Operation, Stages(table Stage/Seconds), TotalSeconds}` to the base workspace at the end of each timed operation (1922–1930). M8 keeps exactly that record shape and destination so the two can be compared side by side, and additionally keeps it in a public read-only property `app.Perf`.

```matlab
function perf(app, stage)                       % perf("begin <op>") | perf("<stage>") | perf("end")
if startsWith(stage, "begin"), app.PerfRun = struct('Op', extractAfter(stage, 6), 'T0', tic, 'T', tic, 'Rows', cell(0,2)); return; end
if isempty(app.PerfRun), return; end
app.PerfRun.Rows(end+1,:) = {char(stage), toc(app.PerfRun.T)}; app.PerfRun.T = tic;
if stage ~= "end", return; end
app.Perf = struct('AppVersion', class(app), 'Operation', app.PerfRun.Op, ...
    'Stages', cell2table(app.PerfRun.Rows, 'VariableNames', {'Stage','Seconds'}), 'TotalSeconds', toc(app.PerfRun.T0));
assignin('base', "Perf_" + class(app), app.Perf); app.PerfRun = [];
end
```

`on` brackets every user action with `begin`/`end`; `update` calls `perf("<stage>")` after each stage it runs (`Read file`, `Build pattern`, `Resample`, `Geometry`, `Derive`, `Render`, `Tables`, `Coverage`). Nothing else touches timing. Replaces `startPerf`'s nested closures, the `perfTracker` handle property and 26 call-site tokens.

---

## 8. Rendering — retained mode (I12)

```matlab
function renderFull(app, k)                     % k: row of Const.Views; called only for the visible tab or a dirty tab on selection
v = Const.Views(k, :); s = app.Gfx.Full(k); P = app.pat(); C = app.col()(:, app.Map.ColIdx);
key = app.fullKey(k); if strcmp(s.Key, key), return; end
[X, Y, Z] = app.viewCoords(v.kind, P, C);      % 5 short cases: pcolor | fisheye | sphere | polar | rect
if isgraphics(s.Surface) && isequal(size(s.Surface.CData), size(C))
    set(s.Surface, 'XData', X, 'YData', Y, 'ZData', Z, 'CData', C);      % in-place
else
    cla(s.Axes); s.Surface = app.newSurface(v.kind, s.Axes, X, Y, Z, C);
    s.Surface.ContextMenu = app.Gfx.Menu;                                % triad once
end
app.applyTheme(s, k); app.placeMarker(s, app.pat().Derived.Peak.index); app.renderOverlay(s, v.kind);
app.Gfx.Full(k).Key = key;
end
```

- `fullKey = strjoin([Revision, ParamsKey, Component, Map.Key, RangeKey, OverlayKey], "|")`.
- `update` renders only the **visible** full-pattern tab; the tab-change callback renders a stale tab on selection (D57).
- One `uicontextmenu` created at startup and assigned to every axes/surface (D58); one colorbar and one triad per axes, created with the axes (D59); POB marker + datatip per view created once and re-indexed (D70).
- **Polar-3D radius** is one function `util_polarRadius(values, limits)` used by the surface and the overlay (D60).
- **Display map** (A.8) is an exact permutation: signed φ → `perm = [j0:nφ, 1:j0−1]`, `ColIdx = [perm perm(1)]` when periodic (closing column for display only), `PhiAxis` relabelled; elevation → `ThetaAxis = 90 − Theta`, `YDir = 'normal'`. Fisheye / 3-D geometry stays physical; only tick labels change.
- **Cuts:** three lines per axes created once (`Visible` toggles), HPBW regions and bound markers reused, legends created once and relabelled; the HPBW/POB trace is named in the label when it is not Total (D62). The unreachable seam-interpolation branch of M7 (1375–1379) does not exist: the closing column comes from `Map`.
- **Tables:** pushed only when the Results tab is visible and the key changed; numeric matrix + `ColumnName` (D43).
- **Metadata:** one function builds a `{label, value}` cell from `Meta`, `Geometry`, `Derived`, `Params`, `Const` (conventions rows) and `Meta.Notes`; `fmtNumber` never prints `-0` (D67).
- Every colorbar label, axis label and datatip unit is `Meta.UnitLabel` (I9). The coverage axes title shows the region and the formula `Coverage(T) = 100·Ω_R(G>T)/Ω_R`.

---

## 9. Layout — declarative construction

The M7 layout is hand-written MATLAB, not App Designer output (helpers at 3015–3070 prove it). The **widget set, names, parents, rows/columns and defaults are frozen**; only the *statements* that build them change. Three helpers replace 185 `Layout.*` lines and 118 constructor blocks:

```matlab
function h = place(~, ctor, parent, row, col, varargin)           % one line per widget
h = ctor(parent, varargin{:}); h.Layout.Row = row; h.Layout.Column = col;
end
function [lbl, h] = labelled(app, parent, text, row, col, ctor, varargin)   % right-aligned label + control
lbl = app.place(@uilabel, parent, row, col, 'Text', text, 'HorizontalAlignment', 'right');
h = app.place(ctor, parent, row, col+1, varargin{:});
end
function [tab, g, ax, sl, mn, mx] = patternTab(app, group, title, axesTitle, needsAxes)    % as M7 createPatternTab
```

Example (M7 3548–3553 → one line):

```matlab
[app.ThresholdMindBSpinnerLabel, app.Cov_Spinner_ThreshMin] = app.labelled(g, 'Threshold Min (dB):', 2, 3, @uispinner, ...
    'Value', -40, 'ValueChangedFcn', @(~,~) app.on("covRange"));
```

Rules: grids declared with their `RowHeight/ColumnWidth` inline; callbacks are `@(~,~) app.on("scope")`; no `Layout.Row =` outside `place`; property names unchanged and **kept as declared properties** (≈ 170 handle declarations in section A stay — App Designer style, §15-7). Budget: **≤ 320 lines** for the same 118 widgets. Parity with M7 is checked once during the layout step (§12-7) with a ten-line throw-away script that lists handle name, class, parent, row, column and key defaults for both apps; the script is not part of the delivered file.

---

## 10. Defect register — why M8 cannot contain them

Each row: M7 lines → defect → M8 mechanism.

### 10.1 Numerical policy

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| D01 | 5085–5139 | `prctile` (Statistics Toolbox) + grid-independent percentile peak policy can demote a real pencil beam | `met_peak` spatial isolation (I5) |
| D02 | 2810→4834–4851, 4643, 2552 | Display (elevation) θ used for ΔΩ, unit vectors, F/B, coverage-node boresight | `Pattern` is always polar; display is `Map` (I8) |
| D03 | 4904–4907 | Field values rounded to 5 decimals | angles-only snap (I1) |
| D04 | 4920–5041, 5059 | `Re/Im` interpolation loses magnitude under phase slope | power + unit-phasor per component (§6.3) |
| D05 | 4980–4984, 5061–5066 | Target always full sphere; `'nearest'` fabricates data outside the source | target axes within the source domain; no extrapolation |
| D06 | 421–424 | Integer-degree filter yields a 3° grid from 0.3° | exact decimation iff `k ∈ ℕ`, else interpolation |
| D07 | 4630–4641, 5170–5172 | Spikes removed from ∫ only; efficiency/F-B on partial spheres | `keep` mask in numerator **and** Ω; `IsFullSphere` gate (I9) |
| D08 | 4761–4779 | NaN AR → PLF of a perfectly linear antenna | `pol_plf` NaN-safe; one `isLinear` mask shared with AR |
| D09 | 315, 432 | `calcPattern` twice per refresh when 1° is active | columns derived after resampling, once |
| D10 | 4593–4597, 2275–2279 | `N×T` logical promoted to double in `mtimes` (261 MB at 65k×501); cache keyed by thresholds | `cov_curve` `O(N)` memory; no cache (§6.9) |
| D11 | 1525 | Threshold vector by colon accumulation | counting |
| D12 | 2810–2811, 569–583, 4615–4636 | Orientation, POB **and `calcMetrics`' `peakGain`** come from the selected component: with AR/PLF selected the directivity is `AR_peak` over the total-gain integral, F/B is `AR_peak − G_back` | I4; metrics only on total gain; status names the component |
| D13 | 4743–4757 | Polarisation label from sphere-mean powers | main-beam Ω-weighted pairs; label from `AR_p` and the leading pair member |
| D14 | 4713–4715, 5160 | Gain-only: loss on all columns (incl. AR); peak column = column 3 | `Cols` kinds via `util_colKind` |
| D15 | 1329 vs 1386, 2833 | Gain-only cut always plots column 3 (`VariableNames(3)`), while the title and component dropdown name the selected column | `geo_cut` on `View.Component` (§15-8) |
| D16 | 5002–5012 vs 5019–5022, 4922–4923 | `LinearPowerForGain` honoured only on the scattered path; the regular-grid path interpolates gain-only dB linearly | one `pat_interp(X, kind)` |
| D17 | 4915–4917 | `normalizePattern` always appends a φ = 360 copy even for non-periodic sources | `PhiPeriodic` measured (§6.2); closing column only in `Map` |
| D18 | 4886–4893, 4913–4914 vs 5070–5076, 4853–4858 | Non-uniform / irregular grids accepted silently; every ΔΩ from `gridStep` (the *minimum* gap) then under-weights wider cells in Ω, directivity, efficiency and coverage | `pat_build` asserts uniform, regular axes once → `APAT:NonUniformGrid` (§15-1); scattered path deleted |

### 10.2 Import and disclosure

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| D19 | 4139–4149 | `.cut` `ICOMP ∉ {1,2}` read as θ/φ | `APAT:UnsupportedICOMP` |
| D20 | 4132–4137 | Body of revolution synthesised silently | one `Meta.Notes` sentence (§15-5) |
| D21 | 4162–4167 | UAN header not validated | header assertions; `APAT:UnsupportedUAN` |
| D22 | 4155–4159, 4185–4190, 4913 | FEKO multi-frequency blocks merged; first kept silently | block split on `#Frequency:`; frequency dropdown |
| D23 | 4159–4190, 4638, 1290 | Raw fields labelled dBi; efficiency printed | `Meta.Unit/UnitLabel` per format; I9 gating (§15-4) |
| D24 | 4013 | `rmmissing` drops rows with NaN in unused columns | drop only on θ/φ/used-column NaN |
| D25 | 4035–4041 | Axis order by span even with headers; undisclosed | header names first; decision noted |
| D26 | 4059 | Mag/phase layout by `> 100` | header names; range rule with agreement; else error |
| D27 | 4021–4023 | 2-column gain cut detected as coverage | keyword **or** strict no-header rule |
| D28 | 4886–4893 | Elevation heuristic applied to every format | decision per reader; noted |
| D29 | 1902 | UAN `maximum_gain` = component max | total-gain peak |
| D30 | 4227–4563 (4400–4563) | 164-line Excel summary parser (`readExcelSummary` + 5 helpers) feeds one field, `frequencyMHz → hasFrequency`, never read for Excel sources (`freqs = NaN` at 4345) | one `xl_lookup` for the frequency cell → `Source.Freqs`, shown in Metadata; the rest deleted |

### 10.3 Dataflow and state

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| D31 | 189–194, 439–459, 480–487 | Six tables; display convention in data; `physicalTheta` ×13 | grid-native `Pattern` + `Map` |
| D32 | 4853, 5164, 499–536 | Step/ΔΩ/grid rebuilt per consumer | `Pattern.d*`, `Geometry` |
| D33 | 658–688 ≡ 4812–4832; 865–886 ≡ 1559–1579; 4 circular splits; 5 six-column reader cases; two identical table constructions 4318–4326 | Duplicate algorithms | `geo_cut`, `util_presetRange`, `pol_circular`, `io_fields` |
| D34 | 14 widget `UserData` sites | State in widget `UserData` | `View`, `Range`, `Status` (I11) |
| D35 | 282, 1336, 1355 | Readers/getters write widgets; extractor writes status | `readConfig` reads; `apply*` write; transient snap status |
| D36 | 1684–1686, 2264 vs 297, 2290–2293 | Node table copies; Main node live, foreign nodes frozen params | `Pats(k)` registry (I14); one derivation path; `Params` shown |
| D37 | 1663, 2749; cascade 2702→1724→1548→2484→1663 | 65k `prctile` on every tree click **and every checkbox toggle** (`Cov_TreeCheckedNodesChanged → finalizeCoverageJobs → setCoverageUI → Cov_ButtonGroup_CovTypeSelectionChanged → syncCoveragePattern → coverageDisplayRange`) | `Derived.Peak` per entry; no visibility→numeric cascade |
| D38 | 458 | Display toggles invalidate coverage keys | no keys; `Revision` only changes on data change |
| D39 | 1590, 1596, 914 | Presets and sliders only widen | `applyRange` with `Range.Auto` |
| D40 | 345 vs 653 | Cut-value `Step` set twice | `applyChoices` once |
| D41 | 837–847 → 893–899 | AR theme collapses the cut range | AR theme touches `full` only |
| D42 | 2000–2010 vs 2119–2126 | Same-file reselect refused; Process re-parses | reselect = reload, one `update("source")` |
| D43 | 4802–4807, 590–608, 2208 | 17 eager columns into a long table; 65k×17 `uitable` push per change | `Derived.Cols` matrices; tables lazy |
| D44 | 2040 → 2053, 2024–2062 | `activateSource` commits `rawTbl/ffdBlocks/srcUD/stdTbl` before `refresh`; cancel/error leaves new metadata with old view | build-then-commit (I13) |
| D45 | 232–235, 1589, 1598, 1613–1616, 2409–2412 | Four write-only fields (`userEdited`, `lastPreset`, `evaluationBounds`, `displayBounds`) and a three-wire callback (`markCoverageThresholdUserEdit`) whose only effect is never read | `Range.Auto.cov/covX` cleared by the range callback itself |
| D46 | 644–656 vs 1361–1365, 1427 | Cut-value spinner domain is canonical while plots/HPBW label use the signed/elevation convention | cut-value domain through `Map` in `applyChoices` (I8) |
| D47 | 13 sites (297, 315, 405, 432, 574, 628, 631, 872, 1568, 4612, …) | `PeakPercentile`/`PeakMaxExcessDB` threaded through six signatures | `Const.PeakExcessDB` read by `met_peak` only |
| D48 | 1512–1531 ← 1758, 2298 | `covThresholds` is a getter with a side effect: it rewrites `Cov_Spinner_ThreshMax.Value` (1523) and is called from `covRebuildTable` on every check/uncheck and selection change | `readCoverageConfig` reads only; clamping is `applyRange("cov")` |
| D49 | 1656, 2553 (write) / no read; 2300, 2359; 1684–1686 | Dead node state: `componentBounds` (written twice via `robustRange`, never read — `robustRange` itself is dead), `orientationMode` (initialised `"Spherical"`, stored on conical jobs too), `sourceTable`/`viewRevision` copies per node | nodes hold `k` or `{id, label, T, cov, Line, Query}` only |
| D50 | 5198–5199 ← 1936 vs 501–513 | `emptyGridCache` seeds `{valid,theta,…}` (flat) while `gridComp/gridGeom` test `cache.topology.*`; the seeded cache is always invalid | `Geometry` + `Derived`; both gone |
| D51 | 202, 331–332 | `app.step` property written and read only on the next line | gone with `refresh` |
| D52 | 332–335 | When the native step is already 1°, the step dropdown receives two identical items `{'STEP: 1°','STEP: 1°'}` (hidden, but an ambiguous `Value`) | `applyChoices` emits one item when native = 1° |
| D53 | 1691, 1724, 1794–1795, 1991, 2233, 2251, 2407 | `setCoverageUI` is called from seven sites (twice in a row in `covLoadResults`, 1794–1795) and re-enters `Cov_ButtonGroup_CovTypeSelectionChanged`, which re-enters `syncCoveragePattern` — visibility code triggers numerics | one `applyVisibility` at the end of `update`; visibility never calls numerics |
| D54 | 1686, 1707–1709, 2361–2367, 243 | **More write-only state:** job fields `tablePrecision`, `summarySource`, `sourceKind`, `coneTheta`, `conePhi`, `coneAngle` and `orientationIndex` (read only by the self-test, 3828) are written and never read by the application; the constant `StandardColumns` (243) has no reader | a job holds six fields; no unused constant |
| D55 | 2112–2134 → 314 → 351, 355, 357 | **Process (loss/Rx/Pt/R) runs the whole `refresh`:** `updateViewResults(true, …)` re-presets the colour range the user set, `Single_Switch_EHplaneValueChanged` snaps the cut controls back to the E/H switch, and `renderAllFullPatterns` redraws five views — for a change that alters only values | `on("params")` = `pat_derive` + redraw of the visible tab; cut controls and ranges untouched (§6.6) |
| D56 | 1703, 1706–1707; 2275–2279, 2349–2356 | Per-job **eager inverse curve** (`unique(coverage,'last')` at creation, stored as `inverseCov/inverseThr`) and a per-node `coverageCache` struct keyed by component, revision, region and the threshold vector — infrastructure around a 30 ms computation | a job is `{T, cov}`; `thr_at` derives the inverse when asked; no cache (§6.9) |

### 10.4 Graphics, UI, hygiene

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| D57 | 997–1013, 1015–1023 | All 5 views rendered per change | visible tab only; dirty keys |
| D58 | 1210–1219; 992, 1229, 1233, 2891 | New context menu per render; 11 `findall/findobj` | one menu at startup; registry |
| D59 | 805, 1297–1308, 1261 | Colorbar/triad recreated | created with the axes |
| D60 | 1251–1253 vs 1317; 1237 vs 1265 | Polar-3D overlay radius mismatch (surface renormalises by its own max, overlay does not) | `util_polarRadius` |
| D61 | 2833–2834; 1396, 1311, 2846 | Cut plotted twice; `cutData` ×3 | one `geo_cut` per change |
| D62 | 1438, 1458 | Cut POB/HPBW on first checked trace | named in label |
| D63 | 1818, 1817 | Timer per status; dead statement `UserData = UserData` | one timer; gone |
| D64 | 2256 | Parse outside `try` | `on` guard |
| D65 | 2648 | Hard-coded −250 | `ax.XLim(1)` |
| D66 | 785 | `plotTheme` ignores its argument | `util_theme(kind, limits)` |
| D67 | 704–711 | `-0` | `util_fmtNumber` |
| D68 | 507 | `pi` shadowed | gone with `gridComp` |
| D69 | 610–622 | Parameter visibility follows table filter | follows component kind |
| D70 | 947–972, 1026–1084, 2849–2924 | 250 lines of annotation bookkeeping | create-once handles |
| D71 | 3073 vs 248 | Title/version mismatch | title from `Const.ReleaseName` |
| D72 | 355 → 2797 → 2846 → 1231–1238, then 357 | With "overlay cut" checked, load renders both 3-D surfaces in `drawSpatial3D` and again in `renderAllFullPatterns` | overlays drawn only inside `renderFull` of the visible tab (§8) |
| D73 | 1108, 1183, 1493, 2641, 2666 | Five empty `catch` blocks swallow every error, including the ones a developer needs to see | no empty `catch`; the one datatip-template fallback (1101–1110) is a single `try`, with the failure noted in `app.Status` |
| D74 | 2598–2611, 2647–2668 | **Query datatip:** a 14-line `coverageInterpolationLocation` helper computes `DataIndex`/`InterpolationFactor`, then three nested `try/catch` fallbacks create the tip — for one datatip at a known `(x, y)` | `datatip(job.Line, x, y, 'SnapToDataVertex','off')` — one call (§6.9) |

---

## 11. Destination file layout and size budget

```
classdef APAT_v3_M8 < matlab.apps.AppBase
  A  properties: UI handles (≈170, unchanged names) + state {Pats, Main, View, Map, Range, Gfx, Status, Busy, Perf, PerfRun}     190
  B  constants & factories: Const (Cols, Views, RangeGroups, PrincipalAxes, PeakExcessDB, ARLimits, ReleaseName, …), schemas  40
  C  orchestration: readConfig, readCoverageConfig, on, update, applyChoices, applyVisibility, applyRange, perf, status       280
  D  renderers: renderFull, viewCoords, newSurface, applyTheme, placeMarker, renderOverlay, renderCut, renderTables, metadata  400
  E  coverage UI: tree, compute, load, query, table, legend, clear/reset, export                                                220
  F  export: results, cut, UAN, coverage, writeTable                                                                            70
  G  layout: createComponents with place/labelled/patternTab                                                                   320
  H  lifecycle: startupFcn, shutdown, delete, closeRequest, showError, checkCancelled                                            50
end
% file-scope functions
  I  readers: io_read, io_fields (+ spec), io_cut, io_excelMatrix, xl_lookup, io_headerLines                                   330
  J  numerical core: pat_build, pat_resample, pat_interp, geo_build, geo_displayMap, geo_cut, pat_derive, met_*, pol_*, cov_*, util_*  230
                                                                                                                        ─────────
                                                                                                                 sum ≈ 2,130
```

Target ≤ 2,500; ceiling 3,000. Blank and comment lines are not counted against the budget; statements are.

Static checks after the drop (shell one-liners, not file content): `grep -c "prctile\|scatteredInterpolant\|findall" = 0`; `grep -c "findobj" = 1`; `grep -c "UserData" = 0`; `grep -c "assignin" = 1`; `grep -c "sqrt(2)" = 2` (inside `pol_circular`/`pol_fromCircular`); `grep -c "interp1(" = 2` (inside `cov_at`/`thr_at`); `grep -c "Layout.Row" ≤ 3` (inside `place`/`patternTab`); `grep -c "catch$" = 0`.

---

## 12. Work order — one drop, core first

1. **Numerical core (J):** `pat_build`, `util_assertUniform`, `pat_resample`/`pat_interp`, `geo_build`, `geo_displayMap`, `geo_cut`, `pol_*`, `met_*`, `pat_derive`, `cov_curve`/`cov_coneMask`/`cov_thresholds`/`cov_at`/`thr_at`, `util_*`. Hand checks of §13.1.
2. **Readers (I):** `io_read` dispatcher, `io_fields` + spec table, `io_cut`, `io_excelMatrix` + `xl_lookup`, `io_headerLines`. Each reader returns a `Source`; every heuristic writes a `Meta.Notes` sentence.
3. **State & constants (A, B):** `Pats`, `View`, `Map`, `Range`, `Gfx`, `Status`; `Const.*`; schema factories.
4. **Orchestration (C):** `readConfig`, `readCoverageConfig`, `on`, `update` with the ladder of §7.2, `applyChoices`, `applyVisibility`, `applyRange`, `setStatus`, `perf`.
5. **Renderers (D):** `renderFull` + `viewCoords` + `newSurface`, `renderCut`, `renderTables`, metadata, POB marker, overlays, theme.
6. **Coverage UI (E):** tree handling, compute, load results, query, table, legend, clear/reset, export.
7. **Layout (G):** `createComponents` rewritten with `place`/`labelled`/`patternTab`; run the throw-away inventory script against M7 and fix any mismatch.
8. **Export (F), lifecycle (H).**
9. **Delete** every M7 name listed in §7.2 in the same edit; run the static checks of §11; run §13.2 and §13.3.

---

## 13. Verification — without in-file tests

### 13.1 Developer checks during step 1 (Command Window, five minutes, nothing kept)

- `geo_build` on `0:1:180 × 0:1:359`: `abs(G.Omega − 4π) < 1e-12`; `IsFullSphere = true`; on `0:1:90 × 0:1:359`: `Omega ≈ 2π`, `IsFullSphere = false`.
- `pat_resample` from 0.5° to 1°: bit-identical to `P.Eth(1:2:end, 1:2:end)`; from 0.3° to 1°: target axes end at the source maximum.
- `pat_interp("phasor")` on two samples `e^{j0}`, `e^{j120°}`: midpoint magnitude 1 (not 0.5), angle 60°.
- `met_peak` on a flat 0 dB sphere with one +20 dB sample: `wasAdjusted = true`, `value = 0`; on a pencil beam (Gaussian, 3° HPBW, 30 dB peak): `wasAdjusted = false`.
- `pol_circular`: `Eth = 1/√2, Eph = −j/√2` → `E_R = 1, E_L = 0`.
- `pol_plf`: AR = +∞ (RHCP) with Rx RHCP, `RxAR = 0` → 0 dB; with Rx LHCP → ≤ −100 dB; AR = NaN → NaN.
- `cov_curve` on the flat sphere with thresholds `[−1 0 1]`: `[100 0 0]` (strict `>`); on `0:1:90` hemisphere with mask = all: `Ω_R ≈ 2π`, coverage `[100 0 0]`. Compare with M7 `coverageCCDF` on the same table and thresholds: identical to `1e-9`.
- `cov_at` / `thr_at` on the curve `T = [0 1 2 3]`, `cov = [100 60 60 0]`: `cov_at(0.5) = 80`, `thr_at(60) = 2` (upper end of the plateau), `thr_at(30) = 2.5`.
- `geo_displayMap` with signed φ on `0:1:359`: `PhiAxis(1) = −180`, `numel(ColIdx) = 361`, `C(:, ColIdx(1)) == C(:, 181)`.

### 13.2 Regression on real files (step 9)

Every format in the M7 file filter (UAN, FZ, OUT, CUT, FFD, FFE, FFS, XLSX, CSV/TXT/DAT gain-only and generic six-column, a coverage CSV) opened in M7 and M8 side by side:

- POB value and direction identical, except where D01 (percentile vs isolation) or D12 (component peak) applies — listed per file.
- Directivity, efficiency, F/B, HPBW identical on full-sphere `dBi` sources; `n/a` in M8 where I9 applies — listed per file.
- Coverage curves identical at `L = 0` on the same thresholds; identical after a loss change (M7 recomputed vs M8 recomputed).
- Every widget present with the same name, parent, row, column, default (inventory script).

### 13.3 Timing comparison (the reason the perf tracker is kept)

Same file, same sequence of actions in both apps; read `Perf_APAT_v3_M7_110_5` and `Perf_APAT_v3_M8` after each: load, component change, loss change (Process), span toggle, cut change, coverage compute with 501 thresholds, coverage checkbox toggle. Expected orders of magnitude at 1°×1°: load ≈ same (file I/O bound); component change ≤ 0.1 s (one `CData`); Process ≤ 0.2 s; span toggle ≤ 0.1 s; coverage compute ≤ 0.1 s; checkbox toggle ≈ 0 s.

---

## 14. Risks and platform baseline

| Risk | Disposition |
|---|---|
| Non-uniform source grids now error (`APAT:NonUniformGrid`) | Deliberate (§15-1); the message names the axis and the gaps; every real APAT input seen so far is uniform. |
| Peak policy change (percentile → isolation) moves the POB on some files | Listed per file in §13.2; both raw and effective peaks are shown in Metadata. |
| Coverage query values between threshold samples are linear reads of the curve | Same as M7; the threshold step is the fidelity control and is shown in the job label. |
| Foreign coverage patterns derived at load-time parameters | `Params` are visible in the node tooltip and in every job label; re-derived on selection when they differ. |
| `assignin` in `perf` writes one base-workspace variable per app class | One variable, overwritten per action; the owner's inspection channel. |
| R2023b baseline: `datatip(h, x, y)`, `cumsum(…,'reverse')`, `arrayfun`, implicit expansion, `pagemtimes` not needed | All in base MATLAB since R2019b or earlier. |

---

## 15. Decided conventions (closed; each is one constant or one line of behaviour)

1. **Uniform grids only.** `pat_build` asserts `max|Δ − median(Δ)| < 1e-6°` per axis and `nθ·nφ = N`; otherwise `APAT:NonUniformGrid`.
2. **Signed AR at linear samples = −100 dB** (M7 floor kept); the same `isLinear` mask makes PLF use the linear limit.
3. **Peak isolation excess = 6 dB** (`Const.PeakExcessDB`); 4-neighbourhood; φ wraps when periodic.
4. **`Meta.Unit` per format:** UAN/FZ/OUT/Excel = `dBi`; FFD/FFE/FFS/CUT/generic field = `dB (rel. field)`; gain-only = header-driven, default `dB`.
5. **Body of revolution** for single-cut `.cut` files at 10° φ steps (M7 rule), disclosed in `Meta.Notes`.
6. **E/H planes by principal axis** (A.7); no polarisation-tilt selection.
7. **UI handles remain declared properties** in App Designer style; no handle struct.
8. **Gain-only cuts and coverage use the selected column**; the peak column for metrics is the first `gain`-kind column.
9. **Coverage reads are `interp1` on the job curve** (`linear`, `NaN` outside); inverse reads use the upper end of plateaus.
10. **Loss applies to `gain`-kind columns only**; PFD and E_RMS take it through EIRP.

---

## 16. Outcome

- ≈ 2,130 statements budgeted (target ≤ 2,500), the same 118 widgets, the same formats and features.
- One pattern object per loaded file; one derivation function; one dispatcher; one layout helper; one coverage kernel; one curve-read idiom.
- Zero toolbox calls, zero `UserData`, zero `findall`, zero cache keys, zero empty `catch`.
- Component change = one `CData`; Process = one 40 ms derivation + one redraw; span toggle = a permutation; coverage compute = 30 ms; checkbox toggle = a `Visible`.
- 74 catalogued defects closed by construction, each traceable to one mechanism in §3–§9.

---

## Appendix A — Reference kernels (MATLAB, base only)

### A.1 Coverage family — the definition, verbatim

```matlab
function cov = cov_curve(C, dOmega, mask, T)
%COV_CURVE Coverage(T) = 100 · Ω_R(C > T) / Ω_R,   Ω_R(C > T) = Σ_{(i,j)∈R, C(i,j) > T} ΔΩ(i,j)   (I7, strict ">")
v = mask & isfinite(C);                                   % R ∩ finite samples
g = C(v); w = dOmega(v); Omega = sum(w);                  % levels, their solid angles, Ω_R
cov = zeros(size(T)); if Omega <= 0, return; end          % empty region → 0 %
cov = 100 * arrayfun(@(t) sum(w(g > t)), T) / Omega;      % the definition, one threshold at a time (O(N) memory)
end

function m = cov_coneMask(P, thC, phC, alphaDeg)
%COV_CONEMASK (i,j) ∈ cone ⇔ cos γ ≥ cos α,   cos γ = cos θᵢ cos θc + sin θᵢ sin θc cos(φⱼ − φc)   (spherical law of cosines)
m = cosd(P.Theta(:))*cosd(thC) + sind(P.Theta(:))*sind(thC).*cosd(P.Phi(:).' - phC) >= cosd(alphaDeg) - 1e-12;   % nθ×nφ
end

function T = cov_thresholds(tMin, tMax, step)              % counting, not accumulation
n = round((tMax - tMin)/step); T = tMin + (0:n).'*step; if T(end) < tMax - 1e-9, T(end+1) = tMax; end
end

function y = cov_at(job, T)
%COV_AT Coverage at threshold(s) T, read off the job's curve (linear between samples, NaN outside).
y = interp1(job.T, job.cov, T, 'linear', NaN);
end

function T = thr_at(job, c)
%THR_AT Threshold at coverage c %: inverse read of the same curve. For each coverage level keep the highest
%       threshold that still reaches it ('last'), which makes the non-increasing curve strictly monotone.
[cv, i] = unique(job.cov, 'last');
if numel(cv) < 2, T = nan(size(c)); return; end
T = interp1(cv, job.T(i), c, 'linear', NaN);
end
```

Reading guide: `cov_curve` **is** the definition — for each threshold, add up the solid angle of the region samples above it and divide by the region's solid angle. `cov_at` and `thr_at` are the two directions of reading a sampled curve; they are the only `interp1` calls in the file and serve queries, the selection status and the table union alike.

### A.2 Geometry and separable integral

```matlab
function G = geo_build(P)
%GEO_BUILD Separable cell solid angles on the uniform grid (I2).
%   wθ(i) = cos(θᵢ − Δθ/2) − cos(θᵢ + Δθ/2), edges clipped to [0°,180°];   Δφ in radians;   ΔΩ(i,j) = wθ(i)·Δφ
%   Full sphere: Σ wθ = cos 0° − cos 180° = 2 (telescoping) and nφ·Δφ = 2π  ⇒  Σ ΔΩ = 4π exactly (B.1).
lo = max(P.Theta(:) - P.dTheta/2, 0); hi = min(P.Theta(:) + P.dTheta/2, 180);
G.wTheta = cosd(lo) - cosd(hi);
G.dPhi = deg2rad(P.dPhi);
G.PhiPeriodic = abs(numel(P.Phi)*P.dPhi - 360) < 1e-6;
G.IsFullSphere = G.PhiPeriodic && lo(1) == 0 && hi(end) == 180;
G.dOmega = G.wTheta * G.dPhi * ones(1, numel(P.Phi));    % nθ×nφ, 0.5 MB at 1°; used by derive, metrics and coverage
G.Omega = sum(G.dOmega, 'all');
end

function I = geo_integrate(X, G)                          % ∫ X dΩ over finite samples
I = sum(X .* G.dOmega, 'all', 'omitnan');
end
```

### A.3 Derivation — columns, peak, base facts in one function

```matlab
function D = pat_derive(P, G, prm)
%PAT_DERIVE Every column and every base fact of a pattern at the given parameters (I3). ≈ 40 ms at 1°×1°.
if P.IsGainOnly
    D.Cols = P.G; for n = string(fieldnames(P.G)).', if util_colKind(n) == "gain", D.Cols.(n) = P.G.(n) + prm.L; end, end
    total = D.Cols.(util_firstGainCol(P));
else
    s = 10^(prm.L/20); Eth = P.Eth*s; Eph = P.Eph*s;                     % loss as an incident-field scale
    Er = pol_circular(Eth, Eph, 1); El = pol_circular(Eth, Eph, 2);
    C.E_Total_dB = 10*log10(max(abs(Eth).^2 + abs(Eph).^2, eps));
    C.E_TH_dB = 20*log10(max(abs(Eth), eps));  C.E_PH_dB = 20*log10(max(abs(Eph), eps));
    C.E_RCP_dB = 20*log10(max(abs(Er), eps));  C.E_LCP_dB = 20*log10(max(abs(El), eps));
    [C.AR_dB, isLinear] = pol_signedAR(Er, El);
    D.Pol = pol_classify(Eth, Eph, Er, El, G, boresightMask);               % pairs + label from the main beam (§6.5-3)
    C.PLF_dB = pol_plf(C.AR_dB, isLinear, prm.RxMode, prm.RxAR_dB, D.Pol.pairs.Circular(1));
    C.Gain_PolCorrected_dB = C.E_Total_dB + C.PLF_dB;
    C.E_TH_Phase = rad2deg(angle(Eth)); C.E_PH_Phase = rad2deg(angle(Eph));
    C.E_RCP_Phase = rad2deg(angle(Er)); C.E_LCP_Phase = rad2deg(angle(El));
    C.EIRP_dBW = prm.Pt_dBW + C.E_Total_dB;
    C.PFD_Wm2 = 10.^(C.EIRP_dBW/10) ./ (4*pi*prm.R_m^2);
    C.E_RMS_Vm = sqrt(30*10.^(C.EIRP_dBW/10)) ./ prm.R_m;
    D.Cols = C; total = C.E_Total_dB;
end
D.Peak = met_peak(total, G.PhiPeriodic, Const.PeakExcessDB);              % I5
D.Boresight = met_orientation(total, P, G, D.Peak);                          % principal axis, 45° cone
D.Planes = met_planes(D.Boresight);                                          % A.7
D.Metrics = met_metrics(total, P, G, D.Peak, D.Planes, D.Cols);              % directivity, efficiency, F/B, HPBW, AR@peak (I9)
end
```

(`pol_classify` runs before `pol_plf` because the Rx `Auto` sense needs the leading circular pair member; the boresight cone used for classification is the peak-centred 45° cone, so it does not depend on `D.Boresight`.)

#### A.3.1 Spatial peak (I5)

```matlab
function K = met_peak(C, periodic, excessDB)
%MET_PEAK Effective peak = highest sample that is not an isolated spike.
%   spike(i,j) ⇔ C(i,j) − max(4 grid neighbours) > excessDB;  φ wraps when periodic; pole rows see the adjacent ring.
[n, m] = size(C); nb = -inf(n, m);
nb(2:n, :) = max(nb(2:n, :), C(1:n-1, :));  nb(1:n-1, :) = max(nb(1:n-1, :), C(2:n, :));      % θ neighbours
if periodic, L = circshift(C, 1, 2); R = circshift(C, -1, 2);
else,        L = [-inf(n,1) C(:, 1:m-1)]; R = [C(:, 2:m) -inf(n,1)]; end
nb = max(nb, max(L, R));                                                                      % φ neighbours
K.spike = isfinite(C) & (C - nb > excessDB);
[K.rawValue, K.rawIndex] = max(C(:), [], 'omitnan');
cand = C; cand(K.spike) = -Inf; [K.value, K.index] = max(cand(:));
K.wasAdjusted = K.spike(K.rawIndex); K.spikeCount = nnz(K.spike);
end
```

### A.4 Circular decomposition — one place (I10)

```matlab
function E = pol_circular(Eth, Eph, which)
%POL_CIRCULAR RHCP (which = 1) / LHCP (which = 2) components of E = Eθ θ̂ + Eφ φ̂.
%   Convention: e^{+jωt}, (θ̂, φ̂, r̂) right-handed. IEEE right-hand unit vector ê_R = (θ̂ − jφ̂)/√2; the RHCP
%   component is the projection on the conjugate basis, E_R = E·ê_R* = (Eθ + jEφ)/√2;  E_L = (Eθ − jEφ)/√2.
%   Check: E = ê_R ⇒ Eθ = 1/√2, Eφ = −j/√2 ⇒ E_R = 1, E_L = 0.  (B.4)
if which == 1, E = (Eth + 1i*Eph)/sqrt(2); else, E = (Eth - 1i*Eph)/sqrt(2); end
end

function [Eth, Eph] = pol_fromCircular(Er, El)            % inverse: OUT / CUT ICOMP=2 / Excel format 2 / generic rcp/lcp
Eth = (Er + El)/sqrt(2); Eph = (Er - El)/(1i*sqrt(2));
end
```

### A.5 Signed axial ratio (M7 floor kept) and the shared linear mask

```matlab
function [AR, isLinear] = pol_signedAR(Er, El)
%POL_SIGNEDAR Signed AR in dB: +  RHCP-sense, −  LHCP-sense; −100 dB at (numerically) linear samples (§15-2).
r = abs(Er); l = abs(El); d = r - l;
isLinear = isfinite(d) & abs(d) <= eps .* max(r + l, 1);
AR = min(20*log10((r + l) ./ max(abs(d), eps)), 250) .* sign(d);
AR(isLinear) = -100;
end
```

### A.6 PLF, NaN-safe, linear limit shared with A.5

```matlab
function plf = pol_plf(AR_dB, isLinear, rxMode, rxAR_dB, leadingCircular)
%POL_PLF Polarisation loss factor between the antenna ellipse (AR_dB, signed) and the incident wave (rxMode, rxAR_dB),
%   major axes orthogonal (M7 convention, cos 2Δτ = −1):
%   PLF = 1/2 + (4·ρa·ρw − (ρa² − 1)(ρw² − 1)) / (2(ρa² + 1)(ρw² + 1)),  ρ = signed linear axial ratio (+RHCP, −LHCP).
switch rxMode, case "RHCP", sw = 1; case "LHCP", sw = -1; otherwise, sw = 2*(leadingCircular == "E_RCP") - 1; end
ra = 10.^(abs(AR_dB)/20) .* sign(AR_dB); ra(isLinear) = 1e12;             % linear antenna ⇒ |ρa| → ∞
rw = sw * 10^(rxAR_dB/20);
plf = 0.5 + (4*ra*rw - (ra.^2 - 1)*(rw^2 - 1)) ./ (2*(ra.^2 + 1)*(rw^2 + 1));
plf = 10*log10(min(max(plf, eps), 1)); plf(~isfinite(AR_dB)) = NaN;      % NaN in ⇒ NaN out (D08)
end
```

### A.7 E/H plane selection — principal-axis rule (M7 634–642, §15-6)

```matlab
function S = met_planes(axisIndex)
%MET_PLANES E-plane: θ-cut through the boresight axis' φ. H-plane: the orthogonal cut — a φ-cut at θ = 90° for a
%   transverse axis (±X, ±Y), a θ-cut at φ = 90° for ±Z.
A = Const.PrincipalAxes;
S.E = struct('type', "Theta", 'value', A.phi(axisIndex));
if A.theta(axisIndex) == 90, S.H = struct('type', "Phi", 'value', 90); else, S.H = struct('type', "Theta", 'value', 90); end
end
```

### A.8 Display map (permutation, no copy)

```matlab
function M = geo_displayMap(P, G, view)
%GEO_DISPLAYMAP Column permutation and axis relabelling for the display convention; no data is copied or changed (I8).
n = numel(P.Phi); j0 = find(P.Phi >= 180, 1); perm = 1:n;
if view.SignedPhi && ~isempty(j0), perm = [j0:n, 1:j0-1]; end
M.ColIdx = perm; if G.PhiPeriodic, M.ColIdx(end+1) = perm(1); end          % closing column for display only
M.PhiAxis = P.Phi(perm); if view.SignedPhi, M.PhiAxis(M.PhiAxis >= 180) = M.PhiAxis(M.PhiAxis >= 180) - 360; end
if G.PhiPeriodic, M.PhiAxis(end+1) = M.PhiAxis(1) + 360; end
if view.Elevation, M.ThetaAxis = 90 - P.Theta; M.ThetaDir = "normal";  M.ThetaLabel = "Elevation";
else,              M.ThetaAxis = P.Theta;      M.ThetaDir = "reverse"; M.ThetaLabel = "Theta"; end
M.Key = sprintf('%d|%d', view.SignedPhi, view.Elevation);
end
```

### A.9 Number formatting and preset range

```matlab
function s = util_fmtNumber(v, prec)                       % compact (≤ 2 dp, no trailing zeros, never "-0") or fixed
if ~(isscalar(v) && isnumeric(v) && isfinite(v)), s = 'n/a'; return; end
if nargin < 2, s = regexprep(sprintf('%.2f', v + 0), '\.?0+$', ''); else, s = sprintf(['%.' num2str(prec) 'f'], v + 0); end
if strcmp(s, '-0'), s = '0'; end
end

function b = util_presetRange(peak)                        % 50-dB window under the next multiple of 5 above the peak
if ~isfinite(peak), b = [-40 10]; return; end
hi = 5*ceil(peak/5); b = min(max([hi - 50, hi], -250), 100);
end
```

### A.10 Six-column field reader — one converter, nine specs

```matlab
%  key            order (θ φ a b c d → columns)   domain      basis       unit
%  'uan'          [1 2 3 5 4 6]                    'magphase'  'thetaphi'  'dBi'     % θ φ |Eθ|dB |Eφ|dB ∠Eθ ∠Eφ
%  'ffd'          [1 2 3 4 5 6]                    'rect'      'thetaphi'  'dB'
%  'ffe'          [1 2 3 4 5 6]                    'rect'      'thetaphi'  'dB'
%  'ffs'          [1 2 3 4 5 6]                    'rect'      'thetaphi'  'dB'
%  'out'          [1 2 3 4 5 6]                    'rect'      'rcplcp'    'dBi'
%  'linear-rect'  [1 2 3 4 5 6]                    'rect'      'thetaphi'  'dB'
%  'linear-mp'    [1 2 3 4 5 6] | interleaved      'magphase'  'thetaphi'  'dB'
%  'rcp-*'        …                                …           'rcplcp'    'dB'
%  'lcp-*'        …                                …           'lcprcp'    'dB'
function [Eth, Eph] = io_fields(M, spec)
A = M(:, spec.order(3:6));
if spec.domain == "magphase", c1 = 10.^(A(:,1)/20).*exp(1i*deg2rad(A(:,2))); c2 = 10.^(A(:,3)/20).*exp(1i*deg2rad(A(:,4)));
else,                          c1 = complex(A(:,1), A(:,2));                 c2 = complex(A(:,3), A(:,4)); end
switch spec.basis
    case "thetaphi", Eth = c1; Eph = c2;
    case "rcplcp",   [Eth, Eph] = pol_fromCircular(c1, c2);
    case "lcprcp",   [Eth, Eph] = pol_fromCircular(c2, c1);
end
end
```

### A.11 Excel summary — one lookup instead of a parser

```matlab
function v = xl_lookup(path, sheet, label)                 % numeric value to the right of a labelled cell, NaN if absent
C = readcell(path, 'Sheet', sheet, 'Range', 'A1:H70'); v = NaN;
[r, c] = find(cellfun(@(x) (ischar(x) || isstring(x)) && strcmpi(strtrim(x), label), C), 1);
if ~isempty(r), for k = c+1:size(C, 2), if isnumeric(C{r, k}) && isfinite(C{r, k}), v = C{r, k}; return; end, end, end
end
```

### A.12 Uniformity assertion (I1, §15-1)

```matlab
function step = util_assertUniform(axis, name)
d = diff(axis); step = median(d);
if numel(axis) > 1 && any(abs(d - step) > 1e-6)
    error('APAT:NonUniformGrid', '%s axis is not uniform: steps range %.6g°..%.6g° (APAT requires uniform grids).', name, min(d), max(d));
end
end
```

### A.13 Declarative layout helpers — see §9.

### A.14 Status with one timer

```matlab
function setStatus(app, label, msg, transient)
stop(app.StatusTimer); label.Text = char(msg);
if ~transient, app.Status.(label.Tag) = char(msg); return; end
app.StatusTimer.TimerFcn = @(~,~) set(label, 'Text', app.Status.(label.Tag)); start(app.StatusTimer);
end
```

---

## Appendix B — Derivations

**B.1 Exact 4π.** With `wθ(i) = cos(lo_i) − cos(hi_i)` and adjacent cells sharing their boundary (`hi_i = lo_{i+1}`), `Σ wθ = cos(lo_1) − cos(hi_n)`; clipping gives `lo_1 = 0`, `hi_n = 180` on a full θ axis, so `Σ wθ = 2`. With `nφ·Δφ = 2π`, `Σ ΔΩ = 2·2π = 4π` exactly, independent of the step. No seam column exists, so no weight is zeroed.

**B.2 Coverage reads.** `cov_curve` returns the step function `Coverage(T)` sampled at the requested thresholds. `cov_at` reads it linearly between samples; with the threshold step chosen by the user this is the same fidelity M7 presents and the same value the plotted polyline shows at that abscissa. `thr_at` inverts the sampled curve: `unique(cov, 'last')` keeps one threshold per coverage level (the highest, i.e. the upper end of a plateau), producing a strictly increasing `(cov, T)` pair list for `interp1`.

**B.3 Loss.** Fields are scaled by `10^{L/20}` inside `pat_derive`, so every level column shifts by `L` and every field-derived quantity (EIRP, PFD, E_RMS) follows through its own formula. Peak index, boresight, HPBW, directivity and F/B are unchanged by a uniform shift; efficiency scales by `10^{L/10}` (M7-compatible). Because the whole derivation costs ≈ 40 ms, nothing is kept at `L = 0` and no consumer adds `L`.

**B.4 Circular basis.** Under `e^{+jωt}` with `(θ̂, φ̂, r̂)` right-handed, the IEEE right-hand circular unit vector is `ê_R = (θ̂ − jφ̂)/√2`. The RHCP component of `E = Eθ θ̂ + Eφ φ̂` is `E·ê_R* = (Eθ + jEφ)/√2`; LHCP is `(Eθ − jEφ)/√2`. Check: `E = ê_R` gives `E_R = 1, E_L = 0`.

**B.5 Power + unit-phasor interpolation.** Adjacent samples `E₁ = A e^{jψ₁}`, `E₂ = A e^{jψ₂}`, `Δ = ψ₂ − ψ₁`. Linear `Re/Im` gives a midpoint magnitude `A|cos(Δ/2)|` (−6 dB at 120°, 0 at 180°); power interpolation gives `A²` exactly. The unit-phasor midpoint `(e^{jψ₁} + e^{jψ₂})/2 = e^{j(ψ₁+ψ₂)/2}·cos(Δ/2)` has the circular-mean angle for every `|Δ| < 180°`; renormalising it to unit length and multiplying by `√P` restores a field with the right magnitude and the mean phase.

**B.6 Cost of the literal coverage loop.** `arrayfun` over 501 thresholds on 65,160 samples is 501 comparisons of a 65k vector plus 501 masked sums ≈ 30 ms in MATLAB; on a 0.5° grid (260k samples) ≈ 120 ms. M7's vectorised form (`regionGain > thresholds.'`, then `regionWeight.' * indicator`) does the same arithmetic but first materialises a 65k × 501 logical (32.6 MB) that `mtimes` promotes to double (261 MB). Nothing is cached because a fresh evaluation is below the time MATLAB needs to draw the curve.
