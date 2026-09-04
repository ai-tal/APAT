# APAT M8 — Architecture & Improvement Plan (rev 6)

**From:** `APAT_v3_M7_110_5.m` — 5,199 lines, one App Designer class, 183 functions (95 methods, 34 file-scope functions, ≈ 680 lines of generated layout at 3013–3693).
**To:** `APAT_v3_M8.m` — the **same one file**, the **same generated layout**, the **same feature set and input formats**, rebuilt around one dataflow. Base MATLAB (R2023b baseline), **no toolboxes**.
**Delivery:** one drop. The numerical core is written and self-tested first; the UI is then pointed at it; every M7 name the core replaces is deleted in the same edit. No dual paths.
**Line numbers** in this document refer to `APAT_v3_M7_110_5.m`. Defect IDs (**F01–F57**) are labels local to this plan (register in §9).

---

## 0. Proportionality rule (governs every item below)

> A change is admitted only if it (a) fixes a verified defect for an input APAT already accepts, or (b) removes code, or (c) is required by another admitted item.

Consequences that follow directly from the rule and are **out of scope**: new file formats or format variants (Ludwig-3 cuts, companion/sidecar files, header-driven calibration), new plot or cut types, new metrics, Stokes-parameter formulations, toolbox dependencies, changes to the generated layout.

---

## 1. Executive summary

M7 is feature-complete and numerically careful in places, but it is long and slow for one structural reason: **the same sphere is re-interpreted by every consumer**, and **UI callbacks own algorithms**.

- One pattern is materialised as six long tables per refresh (189–194) plus two per coverage node (1684–1686). The display convention (elevation θ, signed φ) is written into the data (439–459) and undone by `physicalTheta` at 13 sites — and forgotten at three, so solid-angle weights, boresight and F/B are wrong whenever the elevation view is active (F02).
- Grid structure and solid angle are rebuilt by every consumer (`gridStep` ×17, `solidWeights` ×6, `unique/ismember/sub2ind` in `gridComp`).
- Every user action re-enters most of the pipeline: a component change re-runs orientation and metrics, rebuilds all five full-pattern views with `cla`+`surf` (one is visible), creates new context menus and colorbars, and pushes a 65k×17 table to a `uitable`.
- Several numerical policies are silently wrong for legitimate inputs: fields rounded to 5 decimals (F03), `Re/Im` interpolation of fields with phase slope (F04), hemispheres extrapolated to full spheres (F05), a toolbox percentile peak policy that can demote a real pencil beam (F01), NaN fields turned into a definite PLF (F08), raw far fields labelled dBi with an efficiency (F20), E/H planes that ignore polarisation (F13).

M8 keeps the UI and changes the program underneath it:

> **One grid-native pattern. One separable geometry. One column table that is also the materialiser. Loss is an offset. One `update(scope)`. One config reader. Retained graphics that render only what is visible. One place per convention, shown in Metadata. A static self-test as the release gate.**

Expected outcome (§16): fewer lines than M7 with the layout untouched; zero duplicate algorithms; zero toolbox calls; component change ≈ one `CData` assignment; loss change ≈ zero recomputation; coverage evaluation independent of the number of thresholds; 57 catalogued defects closed, each with a self-test row or a static check.

---

## 2. Goals and non-goals

**Goals**

1. Correct physics for every supported input: solid angle, peak, resampling, polarisation sense, principal planes, unit disclosure.
2. One implementation per concept.
3. Every user action recomputes only its invalidation radius and touches only the graphics it changes.
4. Everything numerical is testable without a UI — and tested.
5. Every convention is pinned in one place and visible to the user.
6. Same file, same layout, same features, same or better output on all existing inputs (deliberate deltas are listed in §9 and §15).

**Non-goals** (candidates for a later milestone, not this one): new formats/variants, new plots/cuts/metrics, calibration from anything other than the pattern file's own value columns, a PLF tilt selector.

---

## 3. Governing rule and invariants

### 3.1 The rule

```matlab
cfg    = app.readConfig();          % the ONLY place widget .Value is read
result = f(data, cfg);              % app-free, alert-free, widget-free
app.apply*(result);                 % the ONLY places Items/Limits/Text/Visible/CData are written
```

Every callback body is one line: `function onX(app, ~), app.guard("Title", "scope"); end`. `guard` owns `try/catch`, cancellation, the busy flag and the single `drawnow`.

### 3.2 Invariants (the drop is invalid if any of these move)

| # | Invariant |
|---|---|
| I1 | **Canonical pattern:** polar θ ascending in [0,180], φ ascending in [0,360), uniform steps validated once, grid-native `nθ×nφ`, no seam column. Angles snapped to 5 decimals; **field values never rounded**. |
| I2 | **Separable geometry:** `ΔΩ(i,j) = wθ(i)·Δφ`; `Σ ΔΩ = 4π` exactly on a full sphere (telescoping, Appendix B.1). Nothing else measures a step or computes a weight. |
| I3 | **Loss is an offset.** All level columns are computed at `L = 0`. `L` is added at display/table/export and by threshold shift in coverage. Peak index, boresight, HPBW, directivity, F/B are loss-independent by construction. |
| I4 | **Physical quantities are defined on total gain** (or the single gain column). Component selection changes plots, tables and the POB marker only. |
| I5 | **Peak policy = spatial isolation.** A sample is a spike iff it exceeds every grid neighbour (4-neighbours, φ-wrap, adjacent ring for pole rows) by more than `Const.PeakExcessDB = 6`. Effective peak = highest non-spike sample. Raw and effective peaks are both reported. No percentile, no toolbox. |
| I6 | **Resampling never interpolates dB, AR or PLF.** Exact decimation when `target/native ∈ ℕ`; otherwise E-field per component as linear power + unit phasor, gain-only as linear power. Target axes never leave the source domain. Columns are computed **after** resampling. |
| I7 | **Coverage:** `Coverage(T) = 100·Ω{G > T}/Ω_R`, strict `>`, ties exact, canonical grid only, cone membership by unit-vector dot product with `−1e-12` tolerance. Query values come from the distribution, never from the drawn polyline. |
| I8 | **Display invariance:** toggling elevation θ / signed φ changes zero numbers in `Pattern, Geometry, Cols, Metrics, Coverage`. |
| I9 | **Partial-sphere and unit honesty:** efficiency and F/B are `n/a` unless `Geometry.IsFullSphere`; efficiency, EIRP, PFD, E_RMS exist only for `Meta.Unit == "dBi"` sources; every level label carries `Meta.UnitLabel`. |
| I10 | **Circular decomposition** lives in one function (`pol_circular`, Appendix A.4) with M7's convention `E_R = (Eθ + jEφ)/√2`, `E_L = (Eθ − jEφ)/√2` — the IEEE right-hand component under `e^{+jωt}` (Appendix B.5) — and one fixture that fails if it drifts. |
| I11 | **Widgets:** read only in `readConfig`/`readCoverageConfig`; written only in `apply*`. No `.UserData` on widgets. No `findall/findobj`. |
| I12 | **Graphics are retained:** each view owns its handles in a registry; `cla` only when grid size changes; render only the visible full-pattern tab. |
| I13 | **One file, no toolboxes**, R2023b baseline; the generated layout block is byte-identical except callback targets. |

---

## 4. Architecture

### 4.1 M7 dataflow today — hazards marked

```
FILE → readPattern            ICOMP≠2 read as θ/φ ⚠F16 · UAN header ignored ⚠F18 · FFE blocks merged ⚠F19
       │                       raw fields as dBi ⚠F20 · rmmissing ⚠F21 · span/">100" heuristics ⚠F22 F23 · cov detector ⚠F24
       → rawTbl + blocks{} → normalizePattern   (rounds FIELDS ⚠F03 · elevation heuristic ⚠F25 · seam rows) → stdTbl
  └─ refresh
     ├─ calcPattern(stdTbl) → patTbl                                   (discarded whenever 1° follows ⚠F09)
     ├─ applyStep → integer filter ⚠F06 | resample Re/Im to full sphere 'nearest' ⚠F04 F05 → calcPattern → viewBaseTbl
     └─ applyAngularSpan → copy 17 cols, rewrite θ/φ, sortrows → viewTbl (+viewRevision ⚠F35)
        ├─ detectOrientation(viewTbl, comp ⚠F12) → solidWeights(display θ ⚠F02) → viewSolidAngle
        ├─ resolvePeak(prctile ⚠F01) → POB;  calcMetrics(display θ ⚠F02, spikes ∫-only ⚠F07, principal planes ⚠F13)
        ├─ PLF: NaN → linear ⚠F08 · pol label sphere-mean ⚠F14 · linear AR → −100 ⚠F15
        ├─ 5× cla+surf ⚠F41 · new menus ⚠F42 · colorbar/triad ⚠F43 · uitable ← 65k×17 ⚠F40 · cutData ×3 ⚠F45
        └─ Coverage: node ← viewTbl ×2 ⚠F33 · N×T logical ⚠F10 · key includes thresholds ⚠F10 · presets widen ⚠F36
```

### 4.2 M8 dataflow — destination

```
FILE ─► io_read(path, fmt) ─► Source { Raw(table, for the Input tab), Blocks{f} (nθ×nφ×4 | nθ×nφ×nC),
                                       Theta, Phi, Freqs, Meta{Format, Unit, UnitLabel, ThetaConvention(+how decided),
                                       AxisOrder(+how decided), IsGainOnly, ColNames, SynthesizedRevolution,
                                       PhiClosedInSource, Regularized, Notes} }
            ▼
     pat_build(Source, f) ─► Pattern { Theta[nθ], Phi[nφ], dTheta, dPhi, Eth, Eph (complex nθ×nφ) | G.(name) (nθ×nφ),
            │                          IsGainOnly, Freq, Revision, Meta }        asserts I1 once
            ▼  optional    pat_resample(Pattern, step)  → Revision++            (I6)
            ▼
     geo_build(Pattern) ─► Geometry { wTheta[nθ], dPhi, sinT, cosT, cosP, sinP, PhiPeriodic, IsFullSphere, Omega }
            ▼
     Cols (struct array, Const) ─► col(app, name)  memoised nθ×nφ per (Revision, key(name))     (I3: computed at L = 0)
            │                       Base facts computed once per Revision: Peak (total), Pol{pairs, label, tilt},
            │                       Boresight, Planes{E,H as grid cuts}, Metrics0
            ▼
     View = readConfig()      component, cut, span, ranges, params{L, Rx, Pt, R}, freqIndex   — never copies Pattern
     Map  = geo_displayMap(Geometry, View)   { ColIdx, ThetaAxis, PhiAxis, ThetaDir, labels, ticks }
   ┌──────────┬───────────┬───────────┬──────────────┬───────────┬───────────┐
   ▼          ▼           ▼           ▼              ▼           ▼           ▼
 PLOTS      CUTS       METRICS     COVERAGE        TABLES      EXPORT     METADATA
 col+L      slices     Metrics0+L  cov_dist(col)   lazy, mask  lazy       conventions,
 (:,ColIdx) +L                     eval(T−L)                               unit, decisions
```

**Dependency graph** (kept as the comment block above `update`):

```
SOURCE ─► PATTERN(Rev) ─► GEOMETRY ─► COLS(Rev, name) ─► BASE FACTS(Rev)
                                          │                   │
                                     COV DIST(Rev,name)   METRICS(+L)  PLOTS/CUTS/TABLES (+L, Map)
VIEW ─► MAP ─► ColIdx / axes / ticks / labels      (touches nothing above)
PARAMS ─► L (offset), Rx (PLF column only), Pt/R (link columns only)
```

If a function needs something not on a path from its inputs, it is reaching into the app; that line does not belong in M8.

### 4.3 Layer contracts

| Layer | Object | Writer | Readers | Forbidden |
|---|---|---|---|---|
| Source | `app.Source` | `io_read` | `update("source")`, Input tab | math, renderers |
| Pattern | `app.Pattern` | `pat_build`, `pat_resample` | all below | widget values, `cla` |
| Geometry | `app.Geometry` | `geo_build` (on Revision change) | cols, metrics, coverage, plots | storing an `nθ×nφ` ΔΩ matrix |
| Cols | `app.ColCache` | `col(app,name)` | plots, cuts, tables, export, coverage | any parameter other than Rx for `PLF`, Pt/R for link columns |
| Base facts | `app.Base` | `pat_baseFacts` (once per Revision) | metrics, planes, status | loss |
| View / Map | `app.View`, `app.Map` | `readConfig`, `geo_displayMap` | orchestration, renderers | math kernels |
| Conventions | `Const.*`, `Meta.*` | file section B / readers | everything | literals `sqrt(2)`, `1i*`, `cosd(180)`, `"dBi"` anywhere else |
| Coverage node | `NodeData` | coverage `apply*` | tree, curves | holding table copies; nodes hold a `Pattern` + `Geometry` (or a reference to the app's by Revision) and `Dist.(name)` |
| Graphics | `app.Gfx` | renderers | renderers | `findall`/`findobj`/Tag search |

Validity is one comparison per layer (`Revision`, `key`, `Key`). No flag families, no widget `UserData`.

### 4.4 Why this is shorter

| Concept | M7 | M8 | What vanishes |
|---|---|---|---|
| Physical vs display angles | `viewTbl` + `physicalTheta` ×13 | `Pattern` is polar; `Map` is a permutation + labels | `applyAngularSpan`, `physicalTheta`, seam duplication, F02/F35 |
| Pattern identity | 6 tables (+2 per node) | `Pattern` + memoised `Cols` | five properties and every assignment to them |
| Step / seam / ΔΩ | `gridStep` ×17, `solidWeights` ×6, `gridCache` | `Pattern.dTheta/dPhi`, `Geometry.wTheta/dPhi` | all of them |
| Processing | `calcPattern` (17 eager columns) + `resolvePeak` ×10 | `Cols(k).fn` on demand + `Base` once | `calcPattern`, `chooseGain`, `componentMap`, `isARComponent`, `isGainDBColumn`, `HiddenOutputColumns` |
| Loss | `FieldScale` through the whole pipeline | `+L` at point of use | the reprocess on loss change |
| Cut geometry | `cutGeometry` ≡ `calcCutGeometry`; `cutData` ×3 per change | `geo_cut` (slices) once per change | one twin, the status side effect, two extractions |
| Coverage | `coverageCCDF` N×T + key with thresholds + `interp1` table + 2 query interpolations | `cov_dist` (once) + `cov_eval` + `cov_inverse` | 5 helpers, 260 MB transient, plateau ambiguity |
| Circular split | 4 inline copies | `pol_circular` (+ inverse) | 3 copies |
| Range UI | `onRangeUIChanged` scopes + coverage twins + startup arrays | one descriptor-driven `applyRange(group, limits)` | `syncCoverageXRange`, `setCoverageRange`, `coverageRangeState` |
| Annotations | ≈ 250 lines over 6 functions | handles created once, `Visible` toggled | the whole layer |
| Orchestration | `refresh, applyStep, applyAngularSpan, updateViewResults, refreshAngularView, stepChanged, onComponentChanged, renderAllFullPatterns, drawSpatial3D, initRanges, selectBlock, activateSource, syncCoveragePattern, syncCoverageNodeFromView` | `update(scope)` | ≈ 500 lines of bodies |

---

## 5. Data model

### 5.1 Schemas (factory functions in file section B)

```matlab
Source   = struct('Raw',table,'Blocks',{{}},'Theta',[],'Phi',[],'Freqs',NaN,'Meta',meta)
Meta     = struct('Format',"",'Unit',"dBi"|"dB",'UnitLabel',"dBi"|"dB (rel. field)",'ThetaConvention',"polar"|"elevation", ...
                  'ThetaDecidedBy',"format"|"header"|"range",'AxisOrder',"theta-phi"|"phi-theta",'AxisDecidedBy',"format"|"header"|"span", ...
                  'IsGainOnly',false,'ColNames',strings(0),'SynthesizedRevolution',false,'PhiClosedInSource',false, ...
                  'Regularized',false,'Notes',strings(0))
Pattern  = struct('Theta',[],'Phi',[],'dTheta',NaN,'dPhi',NaN,'Eth',[],'Eph',[],'G',struct(),'IsGainOnly',false, ...
                  'Freq',NaN,'Revision',uint64(0),'Meta',meta)
Geometry = struct('wTheta',[],'dPhi',NaN,'sinT',[],'cosT',[],'cosP',[],'sinP',[],'PhiPeriodic',false,'IsFullSphere',false,'Omega',NaN)
Base     = struct('Peak',peak,'Pol',struct('Label',"",'Pairs',pairs,'TiltDeg',NaN,'ARatPeak_dB',NaN), ...
                  'Boresight',1,'Planes',struct('E',cutSpec,'H',cutSpec,'Source',"polarization"|"principal"), ...
                  'Metrics0',struct(),'Revision',uint64(0))
View     = struct('Component',"",'CutType',"Theta"|"Phi",'CutValue',0,'Basis',"Linear"|"Circular",'Traces',[t r l], ...
                  'SignedPhi',false,'Elevation',false,'RangeFull',[lo hi],'RangeCut',[lo hi],'CStep',5, ...
                  'Params',struct('L',0,'RxMode',"Auto",'RxAR_dB',6,'Pt_dBW',0,'R_m',1),'FreqIndex',1,'StepChoice',"native"|"1deg")
Map      = struct('ColIdx',[],'ThetaAxis',[],'PhiAxis',[],'ThetaDir',"reverse"|"normal",'ThetaLabel',"",'PhiTicks',[])
Gfx      = struct('Full',struct('Axes',{},'Surface',{},'Colorbar',{},'Triad',{},'Overlay',{},'Marker',{},'Tip',{},'Key',{}), ...
                  'Cut',struct('Polar',[],'Rect',[],'Regions',[],'Bounds',[],'Key',""),'Menu',gobjects(0),'Timer',[])
NodeData = struct('kind',"pattern"|"results"|"job", ...  pattern: Pattern, Geometry, Base, Dist (struct per column), Name, Path
                  ...)                                    job: id, Dist ref, name, thresholds, curve handle, region spec
```

### 5.2 Column table — `Const.Cols` (registry **and** materialiser)

```matlab
%   name                   label            kind     unit     lossAdd hidden  fn(P, G, prm)  → nθ×nφ (level columns at L = 0)
Cols = colDefs({ ...
 'E_Total_dB'           'Total Gain'     'gain'   'level'  true   false   @(P,~,~) db10(abs(P.Eth).^2 + abs(P.Eph).^2)
 'E_TH_dB'              'Etheta Gain'    'gain'   'level'  true   true    @(P,~,~) db20(abs(P.Eth))
 'E_PH_dB'              'Ephi Gain'      'gain'   'level'  true   true    @(P,~,~) db20(abs(P.Eph))
 'E_RCP_dB'             'RHCP Gain'      'gain'   'level'  true   false   @(P,~,~) db20(abs(pol_circular(P.Eth,P.Eph,1)))
 'E_LCP_dB'             'LHCP Gain'      'gain'   'level'  true   false   @(P,~,~) db20(abs(pol_circular(P.Eth,P.Eph,2)))
 'AR_dB'                'Axial Ratio'    'ar'     'dB'     false  false   @(P,~,~) pol_signedAR(P.Eth,P.Eph)
 'PLF_dB'               'PLF'            'plf'    'dB'     false  false   @(P,G,prm) pol_plf(colAR(P), prm.RxMode, prm.RxAR_dB, pairs(P))
 'Gain_PolCorrected_dB' 'Polarized Gain' 'gain'   'level'  true   false   @(P,G,prm) colTotal(P) + colPLF(P,prm)
 'E_TH_Phase'           'Etheta Phase'   'phase'  'deg'    false  true    @(P,~,~) rad2deg(angle(P.Eth))
 'E_PH_Phase'           'Ephi Phase'     'phase'  'deg'    false  true    @(P,~,~) rad2deg(angle(P.Eph))
 'E_RCP_Phase'          'RHCP Phase'     'phase'  'deg'    false  true    @(P,~,~) rad2deg(angle(pol_circular(P.Eth,P.Eph,1)))
 'E_LCP_Phase'          'LHCP Phase'     'phase'  'deg'    false  true    @(P,~,~) rad2deg(angle(pol_circular(P.Eth,P.Eph,2)))
 'EIRP_dBW'             'EIRP'           'link'   'dBW'    true   true    @(P,G,prm) prm.Pt_dBW + colTotal(P)
 'PFD_Wm2'              'PFD'            'link'   'W/m^2'  false  true    @(P,G,prm) 10.^((prm.Pt_dBW + colTotal(P) + prm.L)/10) ./ (4*pi*prm.R_m^2)
 'E_RMS_Vm'             'E_RMS'          'link'   'V/m'    false  true    @(P,G,prm) sqrt(30*10.^((prm.Pt_dBW + colTotal(P) + prm.L)/10)) ./ prm.R_m });
```

- **Memo key** per column: `gain/ar/phase` → `Revision`; `plf`, `Gain_PolCorrected_dB` → `Revision|RxMode|RxAR`; `link` → `Revision|Pt|R|L`. `col(app,name)` returns the cached matrix or evaluates `fn` once.
- **Loss** (`lossAdd`): `+L` applied by the consumer (`CData = col + L`, table/export column `+ L`, coverage threshold `T − L`). `PFD`/`E_RMS` take `L` inside `fn` because they are non-linear in it.
- **Gain-only sources:** rows are synthesised from `Meta.ColNames` with `kind` from `util_colKind(name)` (`gain|directivity|eirp|…db` → `gain`, `ar|axial` → `ar`, `phase|deg` → `phase`, else `other`; `other` never receives loss and is never the peak column). The peak column is the first `gain` row (F26).
- One array drives: component dropdown items (`kind ∈ {gain, ar, plf}` ∩ available), Results-filter defaults (`hidden`), colour theme (`kind == "ar"` → signed map, `Const.ARLimits = [−30 30]`), cut trace pairs, coverage component list, parameter-control visibility (`plf` → Rx controls, `link` → Pt/R controls, `lossAdd` present → Loss), unit labels, and the resampling domain for gain-only (`gain` → linear power).

---

## 6. Pipelines

### 6.1 Import — `io_read(path, textFormat)`

Small `switch` on extension (as M7), with these corrections. Every reader returns `Source`; every decision it makes is recorded in `Meta` and shown in Metadata.

| Format | Convention (unchanged) | Unit class | Corrections |
|---|---|---|---|
| UAN / FZ (XGTD) | θ φ E_TH_dB E_PH_dB E_TH_deg E_PH_deg | `dBi` | Read the `begin_<parameters>…end_<parameters>` block (regex on the header lines M7 already skips). **Assert** `magnitude dB`, `phase degrees`, `polarization theta_phi` when present; any other value → `APAT:UnsupportedUAN` with the offending keyword (F18). Export writes `maximum_gain` = peak of **total** gain (F27). |
| OUT (GRASP) | θ φ Re/Im RHC, Re/Im LHC | `dB` | θ/φ from `pol_circular` inverse (one place). |
| CUT (GRASP) | blocks; `ICUT`, `ICOMP` | `dB` | `ICOMP == 1` → θ/φ; `ICOMP == 2` → RHC/LHC via inverse; **any other `ICOMP` → `APAT:UnsupportedICOMP`** (F16). Single cut → body of revolution at 10° φ, `Meta.SynthesizedRevolution = true`, shown (F17). Negative-θ fold stays in this reader (it is a `.cut` convention). |
| FFS (CST) | φ θ Re/Im Eθ, Re/Im Eφ | `dB` | none |
| FFE (FEKO) | θ φ Re/Im Eθ, Re/Im Eφ (+ gain columns) | `dB` | **Split blocks** on `#Frequency:` header lines (a 6-line pre-scan, same shape as the FFD separator logic); blocks feed the existing frequency dropdown (F19). Reject `#Coordinate System: UV` with a message. *(Optional, §15-4: if a `Gain(Total)` column is present, `Unit = "dBi"` by scaling the fields once.)* |
| FFD (HFSS) | header triples; Re/Im Eθ, Re/Im Eφ; θ-major | `dB` | `Meta.PhiClosedInSource` when the φ axis ends at start+360. |
| Excel matrix 1/2/3 | fixed sheets, C3 origin | `dBi` | one `Raw` build instead of two identical tables (4326–4330). |
| Generic text (7 selectors) | selector | `dBi` | **No `rmmissing`**: drop rows only when θ, φ or a *used* column is NaN (F21). Axis order from header names `theta|phi|az|el` when present, else span heuristic — `Meta.AxisDecidedBy` (F22). Mag/phase layout: header names when present, else range rule `max−min > 180 ⇒ phase` requiring **both** phase columns to agree, else error (F23). Coverage detector requires a header keyword (`threshold`/`coverage`) **or** (`nCols ≤ 3` and no header and second column in [0,100] and first strictly monotonic) — a headed 2-column gain cut is a pattern (F24). |
| Gain-only text | selector 1 | `dBi` | `Meta.ColNames` from header; `util_colKind` (F26). |

**θ-convention decision moves into the readers** (F25): formats with a fixed convention (UAN, OUT, CUT, FFS, FFE, FFD, Excel) never run a heuristic. Generic text: header name `el|elevation` → elevation; header `theta` → polar; no header → M7's range rule, recorded as `ThetaDecidedBy = "range"` and shown.

The Input tab shows `Source.Raw` (as today). Nothing else reads it.

### 6.2 Canonicalise — `pat_build(Source, f)`

1. θ-convention: if `Meta.ThetaConvention == "elevation"`, `θ = 90 − el`. Fold `θ < 0` → `(−θ, φ+180)`; `θ > 180` → `(360−θ, φ+180)`. Once.
2. `φ = mod(φ, 360)`; snap θ, φ to `Const.AngleDecimals = 5` (**angles only**, F03).
3. Dedupe directions (`unique([φ θ],'rows','first')`); a supplied φ = 360 column folds into φ = 0 (`PhiClosedInSource`).
4. Axes: `Theta = unique(θ)`, `Phi = unique(φ)`. **Uniformity (I1):** `dTheta = (Theta(end)−Theta(1))/(nθ−1)`, assert `max|diff(Theta) − dTheta| ≤ Const.UniformTolDeg = 1e-6`; likewise φ (`dPhi = 360/nφ` when periodic). Failure → regularise once (§15-1) with `Meta.Regularized = true`, or error.
5. Regularity `nθ·nφ == N`; if false → one `scatteredInterpolant` per primitive onto the native-step grid **inside the source hull**, `Meta.Regularized = true`.
6. Reshape grid-major: `Eth = reshape(…, nθ, nφ)` (θ down rows, φ across columns) — or `G.(name)` for gain-only. **No seam column.**

`Pattern.Eth(i,j)` is the field at `(Theta(i), Phi(j))`. Nothing downstream ever measures a step or indexes a table again.

### 6.3 Resample — `pat_resample(Pattern, stepDeg)`

**Domain:** `θq = Theta(1):step:Theta(end)`, `φq = Phi(1):step:Phi(end)` (closure through `[Phi, Phi(1)+360]` when periodic). Never outside the source hull (F05).

**Decimation** (I6): per axis, if `k = step/native` is an integer (`|k − round(k)| < 1e-9`) select every `k`-th sample — bit-exact (F06). Both axes exact ⇒ no interpolation at all (0.5° → 1°, 0.25° → 1°; 0.3° → 1° goes through interpolation and yields a **1°** grid).

**E-field interpolation — magnitude/phase separable, per component:**

```matlab
function E = pat_resampleField(E, interp)     % interp = bilinear on the φ-closed source grid
mag = abs(E);  z = E ./ max(mag, realmin);    % unit phasor, zero-safe
Pq  = interp(mag.^2);                         % linear POWER: no phase-slope dip (F04)
Zq  = interp(z);                              % circular mean of neighbouring phases: no unwrapping
E   = sqrt(max(Pq, 0)) .* (Zq ./ max(abs(Zq), realmin));
end
```

Where a component is null its phase is irrelevant because it multiplies `√P ≈ 0` (Appendix B.4). **Gain-only:** `10.^(G/10)` in, bilinear, `10*log10(max(·, realmin))` out for `kind == "gain"`; other kinds linear. `Revision++`; blocks are resampled lazily per `(FreqIndex, step)`.

### 6.4 Geometry — `geo_build(Pattern)`

```matlab
function G = geo_build(P)
%GEO_BUILD Separable solid-angle weights for a uniform θ×φ grid (I2).
%   ΔΩ(i,j) = wTheta(i)·dPhi,  wTheta(i) = cos θᵢ⁻ − cos θᵢ⁺,  θᵢ∓ = clamp(θᵢ ∓ dθ/2, 0, 180)
%   Σ wTheta telescopes to cos θ₁⁻ − cos θₙ⁺ (= 2 when the end cells reach both poles); Σ dPhi = nφ·dφ (= 2π when periodic).
th = P.Theta(:); ph = P.Phi(:);
lo = max(th - P.dTheta/2, 0);  hi = min(th + P.dTheta/2, 180);
G.wTheta = cosd(lo) - cosd(hi);  G.dPhi = deg2rad(P.dPhi);
G.PhiPeriodic  = abs(numel(ph)*P.dPhi - 360) < 1e-9;
G.Omega        = sum(G.wTheta) * numel(ph) * G.dPhi;
G.IsFullSphere = G.PhiPeriodic && lo(1) == 0 && hi(end) == 180;
G.sinT = sind(th); G.cosT = cosd(th); G.cosP = cosd(ph).'; G.sinP = sind(ph).';
end
```

- Integrals everywhere: `geo_integrate(G, X) = G.dPhi * (G.wTheta.' * sum(X, 2, 'omitnan'))`.
- Unit vectors on demand (`Ux = sinT*cosP`, `Uy = sinT*sinP`, `Uz = cosT*ones(1,nφ)`): one temporary, never stored.
- Hemisphere 0…90: `IsFullSphere = false`; Metadata shows "Sampled solid angle: 2.01π sr (50.2 %)"; efficiency and F/B `n/a` (I9).

### 6.5 Base facts — `pat_baseFacts(P, G)` (once per Revision, at L = 0)

- `Peak = met_peak(colTotal)` (I5, Appendix A.3).
- `Pol`: at the peak sample, `AR_p = AR_dB(peak)`, tilt `τ = ½·atan2(2·Re(Eθ·conj(Eφ)), |Eθ|² − |Eφ|²)` (polarisation-ellipse tilt from θ̂ toward φ̂; Appendix B.6). Pairs (co/cross order for cut traces and Auto-Rx sense) from Ω-weighted mean power over the **main-beam region** `colTotal ≥ Peak − 10 dB` (not the whole sphere, F14). Label: `|AR_p| ≤ Const.CircularAR_dB = 3` → `"Circular (RHCP|LHCP)"` by sign; else `"Linear/Elliptical (AR x dB, tilt τ°)"`, with "vertical/horizontal" appended only for an equatorial boresight (`|τ| < 45°` ⇒ vertical).
- `Boresight = met_orientation(colTotal, G)`: principal axis whose 45° cone holds the most Ω-weighted power (as M7 4845–4850) — from **physical** unit vectors (F02), on **total gain** (F12).
- `Planes` (F13): grid cuts chosen from `τ` — ±Z boresight: `φ_E = wrap(φ_peak + sign(cos θ_peak)·τ)` snapped to `Phi`, E = θ-cut @ `φ_E`, H = θ-cut @ `φ_E + 90`; equatorial boresight: `|τ| < 45°` ⇒ E = θ-cut @ boresight φ, H = φ-cut @ θ = 90, else swapped; oblique or `IsGainOnly` or circular (`|AR_p| ≤ 3`) ⇒ M7's principal-axis rule; `Planes.Source ∈ {"polarization","principal"}` shown in Metadata.
- `Metrics0 = met_metrics(P, G, Peak, Planes)` at L = 0 (§6.7).

### 6.6 Parameters

`View.Params = {L, RxMode, RxAR_dB, Pt_dBW, R_m}` from `readConfig`. **No pipeline stage.** `L` is added by consumers (I3); Rx settings invalidate only the `plf` memo key; Pt/R only the `link` keys. Metadata's peak/EIRP rows are `Metrics0.* + L`.

### 6.7 Metrics — `met_*`

**`met_peak`** (Appendix A.3): 4-neighbour maximum with φ-wrap; pole rows compare against the adjacent ring. Returns `mask, value, index, rawValue, rawIndex, wasAdjusted, spikeCount`.

**`met_hpbw`**: M7's `calcHPBW` (wrap-aware linear crossing), unchanged, on any cut struct.

**`met_metrics`** (F07, I9):

```matlab
keep = ~Peak.mask & isfinite(Gt);                                   % spikes removed from BOTH numerator and Ω
IG   = geo_integrate(G, 10.^(Gt/10) .* keep);  Ok = geo_integrate(G, double(keep));
D_peak_dB = 10*log10( 10^(Peak.value/10) * Ok / IG );               % scale-free (valid for dBi and relative field)
eta_pct   = 100 * IG / Ok;                                          % only if IsFullSphere && Unit == "dBi", else NaN
FB_dB     = Peak.value - Gt(antipodeIndex);                         % only if IsFullSphere; nearest grid sample to −r̂_peak (as M7)
HPBW_E/H  = met_hpbw(geo_cut(Planes.E)), met_hpbw(geo_cut(Planes.H))
```

`ARatPeak_dB`, `PeakTheta/Phi` (physical), `TiltDeg`, `Planes.Source`, `Omega`, `UnitLabel`, `SynthesizedRevolution`, `Regularized`, `ThetaDecidedBy`, `AxisDecidedBy` all go to Metadata.

**`pol_plf`** (Appendix A.6): finite-AR samples only; exactly-linear samples (`AR = NaN` by policy, §15-2) handled by the explicit `r_a → ∞` limit; `PLF_dB(~finite) = NaN` (F08). `Const.PLFTiltCos = −1` (worst-case tilt, as M7) documented and shown in one Metadata "Conventions" row.

**`pol_signedAR`** (F15): `AR = (|E_R|+|E_L|)/||E_R|−|E_L||`, `AR_dB = min(20·log10 AR, 250)·sign(|E_R|−|E_L|)`; exactly equal components → `NaN` (white on the signed map; recommendation §15-2).

### 6.8 Cuts — `geo_cut(P, colName, type, value)`

Grid-native slices, exact, zero arithmetic:

- **φ-cut** (fixed θ): `i = nearest(Theta, v)`; `angle = Phi`; `data = C(i,:).'`; closed for display by `Map.ColIdx`.
- **θ-cut** (fixed φ): `j = nearest(Phi, mod(v,360))`, `j2 = nearest(Phi, mod(Phi(j)+180, 360))`; `angle = [Theta; 360 − Theta(end−1:−1:1)]`; `data = [C(:,j); C(end−1:−1:1, j2)]`.

Returns `struct(angle, thetaDeg, phiDeg, data.(c), fixedAngle, symbol, snapped)`; pure; cached per `(Revision, type, value, cols)`. **One extract** feeds the polar cut, the rectangular cut and both 3-D overlays (F45). Snapping is reported by the renderer as a *transient* status (F32). `+L` applied at render.

### 6.9 Coverage — `cov_*` (I7)

**Definition (in the kernel header):**

```
Coverage(T) = 100 · Ω{G > T} / Ω_R,   Ω{G > T} = Σ_{(i,j)∈R, G(i,j)>T} wθ(i)·Δφ,   Ω_R = Σ_{(i,j)∈R, G finite} wθ(i)·Δφ
```

**Distribution once, evaluate anywhere** (Appendix A.1): `d = cov_dist(C, G, mask)` sorts the region's finite gains with their weights and stores `(g_k ascending, ω_k, S_k = Σ_{m≥k} ω_m, Ω_R)`. `cov_eval(d, T) = 100·S(k_T)/Ω_R` with `k_T = first k : g_k > T` (`histc`-free `discretize`). `cov_inverse(d, c)` = the exact level `sup{T : Coverage(T) ≥ c}`. Memory: `O(N)`; time: one sort per (node, column, region) — thresholds, queries and table rebuilds are then free. The literal `N×T` form is kept as `cov_eval_reference` for the self-test only.

- **Cache key:** `(Revision, column, regionTag)` — thresholds are **not** in the key (F10). Loss by shift: `cov_eval(d, T − L)` for `lossAdd` columns; non-additive columns (`PLF`, `Gain_PolCorrected`) include the Rx key.
- **Region:** `cov_coneMask(G, θc, φc, α)`: `Ux·cx + Uy·cy + Uz·cz ≥ cosd(α) − 1e-12`; spherical = all. Empty region → `Coverage ≡ 0`, status says so.
- **Nodes:** a pattern node holds `Pattern, Geometry, Base` (the Main-file node references the app's by Revision) and `Dist.(column)`; jobs hold their `Dist` reference, thresholds and curve handle. Nodes created on the Coverage tab are processed with the same parameter path as Main (`L` at compute time) — no frozen parameters (F33). Job labels state column, region and `L`.
- **Thresholds:** `T = tMin + (0:n).'·step` by counting (F11).
- **Presets:** threshold window and X-range are set from the *current* node/column peak when the user has not edited them (`CovRangeAuto`), and never widen on their own (F36).
- **Table:** union of checked jobs' thresholds, each column `cov_eval(d_j, T_union − L_j)` — exact, no `interp1`.
- **Queries:** value from `cov_eval`/`cov_inverse`; datatip placed at the exact coordinate; projection lines from `ax.XLim(1)`/`ax.YLim(1)` (F50).

### 6.10 Export — lazy, canonical

- **Results:** built on demand from `Cols` (checked columns, `+L` where `lossAdd`), angles in the *display* convention via `Map` (as today) — from the data, not from the `uitable` (2142).
- **Cut:** the current `geo_cut` struct.
- **UAN:** from `Pattern` at `L` (fields scaled by `10^(L/20)`), canonical φ ∈ [0,360) + closing column as XGTD expects, `maximum_gain` = total-gain peak + L (F27).

---

## 7. Orchestration

### 7.1 `readConfig` / `readCoverageConfig`

The only functions that read widget values. They return the `View` struct (§5.1) and a coverage counterpart (`component, thresholds, region, query`). Step choice, cut basis auto-selection and output-filter mask live in `View` (F31), initialised from the source on `update("source")`.

### 7.2 `update(app, scope)` — the dispatcher

| User action | scope | Recompute | Render |
|---|---|---|---|
| Load / Process / text format | `source` | `io_read → pat_build → (resample if 1°) → geo_build → pat_baseFacts` | `applyChoices`, `applyVisibility`, metadata, range presets (if `RangeAuto`), visible full tab, cuts, tables if visible |
| Frequency block (FFD/FFE) | `freq` | `pat_build(block) → geo_build (if axes changed) → baseFacts` | as `source` minus choices |
| Native ↔ 1° | `step` | `pat_resample → geo_build → baseFacts` | as `freq` |
| Loss | `loss` | **nothing** | `CData = col + L` on visible tab, cut `YData`, metadata rows, tables if visible |
| Rx / Pt / R | `params` | `plf`/`link` memo keys only | as `loss` if the visible component depends on them |
| Component | `component` | `col(name)` (memoised) | `CData` visible tab (+ radius on polar-3D, `ZData` rect-3D), POB, titles, colorbar theme |
| Elevation / signed φ | `span` | **nothing numeric**; `geo_displayMap` | `CData(:,ColIdx)`, axes vectors, ticks, labels, cut `XData` remap, POB re-index |
| Cut controls / E-H / basis / traces | `cut` | `geo_cut` (cached) | cut lines + both overlays from one extract, HPBW |
| Ranges / colour step | `range` | nothing | `clim/zlim/RLim` + ticks of the visible tab; other tabs marked dirty |
| POB / HPBW toggles / tab change | `annot` | nothing | `Visible` of registry handles; **stale tab → render on selection** |
| 3-D view | `camera` | nothing | `view/camup` |
| Coverage compute | — | `cov_dist` (if key miss) → `cov_eval(T − L)` | curve, table, legend, status |
| Coverage thresholds / query | — | `cov_eval` / `cov_inverse` | line `YData` / query tips |

Ladder: `source ⊃ freq ⊃ step ⊃ {loss, params, component} ⊃ {span, cut, range, annot, camera}`. `update` runs the stages at or below the requested rung, marks non-visible full-pattern tabs dirty, renders the visible one, then **one** `drawnow limitrate`.

Deleted as bodies: `refresh`, `updateViewResults`, `refreshAngularView`, `applyStep`, `applyAngularSpan`, `stepChanged`, `onComponentChanged`, `renderAllFullPatterns`, `drawSpatial3D`, `initRanges`, `selectBlock`, `activateSource`, `syncCoveragePattern`, `syncCoverageNodeFromView`, `gridComp`, `gridGeom`, `invalidateDerived`, `physicalTheta`, `cutGeometry`, `cutData`, `cutCols`, `componentMap`, `preferredComponent`, `updateComponentItems`, `updateSelectedComponentPeak`, `computeMetrics`, `planeSettings`, `updateCutControl`, `gainDisplayRange`, `coverageDisplayRange`, `onRangeUIChanged`, `setCoverageRange`, `syncCoverageXRange`, `coverageCacheKey`, `covThresholds`, `coverageInterpolationLocation`, `clearAnnotations`, `refreshAnnotations`, `createPOBDataTip`, `ensureFullPatternPOBAnnotations`, `initializeFullPatternPOBRecords`, `findRenderedPatternSurface`, `configurePlotContextMenu`, `startPerf`.

### 7.3 `guard` — try/catch, cancel, busy

```matlab
function guard(app, title, scope)
if app.Busy, return; end                              % drops re-entrant slider storms; nothing else can re-enter
app.Busy = true; c = onCleanup(@() app.setBusy(false));
try
    app.update(scope); drawnow limitrate
catch err
    if err.identifier == "APAT:Cancelled", app.setStatus(app.Single_StatusBar, 'Cancelled.', true);
    else, app.showError(err, title); end
end
end
```

Long stages (`source`, `step`, coverage compute) run behind the existing cancellable `uiprogressdlg`; `checkCancelled` sits between stages, not inside kernels. Coverage load parses **inside** the guard (F49).

### 7.4 `applyChoices`, `applyVisibility`, `applyRange`, status, lifecycle

- `applyChoices` — the only writer of data-derived `Items/ItemsData/Limits/Step/Text`: component items (Main and Coverage) from `Cols ∩ available`, cut-value limits/step from `Pattern` (once, F37), step dropdown items, block items, trace checkbox labels.
- `applyVisibility` — the only writer of `Visible/Enable`, computed from `Meta`, `View.Component` kind and coverage state; parameter controls follow the **selected component and source kind**, not the table filter (F55).
- `applyRange(group, limits)` — one descriptor-driven controller for three groups: `full` (5 sliders + 10 spinners), `cut` (1 + 2), `cov` (X-range + threshold spinners). The AR theme sets **only** `full` to `Const.ARLimits` (F38). `RangeAuto` flags become false on the first user edit; presets re-apply on `source/freq/step` only, and never widen by themselves (F36).
- Status: one reusable `timer` created in `startupFcn` (F47); `setStatus(label, msg, transient)`; the pattern/POB line is the persistent message; snaps and confirmations are transient. Status names the component ("Peak of *Axial Ratio*") and reserves "POB" for total gain (F12).
- Same-file reselect = reload (F39). Window title from `Const.ReleaseName` (F57).
- Profiling: `perf` records stage times into `app.Perf` only when `getenv("APAT_PROFILE")` is set; no `assignin` (F48).
- Lifecycle: `shutdown` stops the timer, deletes the dialog and the context menu, clears the registry; `delete`/`closeRequest` call it once.

---

## 8. Rendering — retained mode (I12)

```matlab
function renderFull(app, k)                                  % k = visible tab index
key = app.fullKey(k);  s = app.Gfx.Full(k);  if s.Key == key, return; end
C = app.col(app.View.Component) + app.View.Params.L * app.colLossAdd(app.View.Component);
C = C(:, app.Map.ColIdx);
if isgraphics(s.Surface) && isequal(size(s.Surface.CData), size(C))
    set(s.Surface, 'CData', C, <XData/YData/ZData per kind>);     % in-place
else
    cla(s.Axes); s.Surface = <surf|pcolor|surface>(...); s.Surface.ContextMenu = app.Gfx.Menu; <triad once>
end
<colorbar limits/ticks, theme, title, POB marker re-index>;  app.Gfx.Full(k).Key = key;
end
```

- `fullKey = strjoin([Revision, Component, L*lossAdd, RxKey (if plf), Map.Key, RangeKey], "|")`.
- `update` renders only the **visible** full-pattern tab; the tab-change callback renders a stale tab on selection (F41). Load cost drops by four `surf` calls.
- One `uicontextmenu` created at startup and assigned to every axes/surface (F42); one colorbar and one triad per axes, created with the axes (F43); POB marker + datatip per view created once and re-indexed (F56).
- **Polar-3D radius** is one function `util_polarRadius(values, limits)` used by the surface and the overlay (F44).
- **Display map** is an exact permutation: signed φ → `perm = [j0:nφ, 1:j0−1]` (`j0` = first column ≥ 180), `ColIdx = [perm perm(1)]` when periodic (closing column for display only), `PhiAxis` relabelled; elevation → `ThetaAxis = 90 − Theta`, `YDir = 'normal'`. Fisheye / 3-D geometry stays physical; only tick labels change.
- **Cuts:** three lines per axes created once (`Visible` toggles), HPBW regions and bound markers reused; the HPBW/POB trace is named in the label when it is not Total (F46).
- **Tables:** pushed only when the Results tab is visible and the key changed; numeric matrix + `ColumnName` (F40).
- Every colorbar label, axis label and datatip unit is `Meta.UnitLabel` (I9). The coverage axes title shows the region and `Coverage(T) = 100·Ω{G>T}/Ω_R`.

---

## 9. Defect register — why M8 cannot contain them

Each row: M7 lines → defect → M8 mechanism. Every row has a self-test row (§12) or a static check.

### 9.1 Numerical policy

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| F01 | 5085–5139 | `prctile` (toolbox) + grid-independent percentile peak policy can demote a real pencil beam | `met_peak` spatial isolation (I5) |
| F02 | 2810→4834–4851, 4643, 2552 | Display (elevation) θ used for ΔΩ, unit vectors, F/B, coverage-node boresight | `Pattern` is always polar; display is `Map` (I8) |
| F03 | 4904–4907 | Field values rounded to 5 decimals | angles-only snap (I1) |
| F04 | 4920–5041, 5059 | `Re/Im` interpolation loses magnitude under phase slope | power + unit-phasor per component (§6.3) |
| F05 | 4980–4984, 5061–5066 | Target always full sphere; `'nearest'` fabricates data outside the source | target axes within the source domain; no extrapolation |
| F06 | 421–424 | Integer-degree filter yields a 3° grid from 0.3° | exact decimation iff `k ∈ ℕ`, else interpolation |
| F07 | 4630–4641, 5170–5172 | Spikes removed from ∫ only; efficiency/F-B on partial spheres | `keep` mask in numerator **and** Ω; `IsFullSphere` gate (I9) |
| F08 | 4761–4779 | NaN AR → PLF of a perfectly linear antenna | `pol_plf` NaN-safe |
| F09 | 315, 432 | `calcPattern` twice per refresh when 1° is active | columns computed after resampling, on demand |
| F10 | 4593–4597, 2275–2279 | `N×T` transient; cache keyed by thresholds | `cov_dist` once, `cov_eval` any `T` |
| F11 | 1525 | Threshold vector by colon accumulation | counting |
| F12 | 2810, 569–583 | Boresight/metrics/POB on the selected component | I4; status names the component |
| F13 | 634–642, 4671–4686 | E/H planes ignore polarisation (y-pol swaps them) | tilt-angle rule → grid cuts; `Planes.Source` shown |
| F14 | 4743–4757 | Polarisation label from sphere-mean powers | main-beam Ω-weighted pairs; label from `AR_p` and `τ` |
| F15 | 4769–4771 | Exactly-linear samples placed at the LHCP end of the signed AR map | `NaN` (white) — §15-2 |

### 9.2 Import and disclosure

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| F16 | 4139–4149 | `.cut` `ICOMP ∉ {1,2}` read as θ/φ | `APAT:UnsupportedICOMP` |
| F17 | 4132–4137 | Body of revolution synthesised silently | `Meta.SynthesizedRevolution`, shown |
| F18 | 4162–4167 | UAN header not validated | header assertions; `APAT:UnsupportedUAN` |
| F19 | 4155–4159, 4185–4190, 4913 | FEKO multi-frequency blocks merged; first kept silently | block split on `#Frequency:`; frequency dropdown |
| F20 | 4159–4190, 4638, 1290 | Raw fields labelled dBi; efficiency printed | `Meta.Unit/UnitLabel` per format; I9 gating |
| F21 | 4013 | `rmmissing` drops rows with NaN in unused columns | drop only on θ/φ/used-column NaN |
| F22 | 4035–4041 | Axis order by span even with headers; undisclosed | header names first; `AxisDecidedBy` |
| F23 | 4059 | Mag/phase layout by `> 100` | header names; range rule with agreement; else error |
| F24 | 4021–4023 | 2-column gain cut detected as coverage | keyword **or** strict no-header rule |
| F25 | 4886–4893 | Elevation heuristic applied to every format | decision per reader; `ThetaDecidedBy` |
| F26 | 4713–4715, 5160 | Gain-only: loss on all columns; peak column = column 3 | `Cols` kinds via `util_colKind` |
| F27 | 1902 | UAN `maximum_gain` = component max | total-gain peak + L |

### 9.3 Dataflow and state

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| F28 | 189–194, 439–459, 480–487 | Six tables; display convention in data; `physicalTheta` ×13 | grid-native `Pattern` + `Map` |
| F29 | 4853, 5164, 499–536 | Step/ΔΩ/grid rebuilt per consumer | `Pattern.d*`, `Geometry` |
| F30 | 658–688 ≡ 4812–4832; 865–886 ≡ 1559–1579; 5141–5152; 4 circular splits | Duplicate algorithms | `geo_cut`, `util_presetRange`, `pol_circular` |
| F31 | 18 sites | State in widget `UserData` | `View` (I11) |
| F32 | 282, 1336, 1355 | Readers/getters write widgets; extractor writes status | `readConfig` reads; `apply*` write; transient snap status |
| F33 | 1684–1686, 2264 vs 297, 2290–2293 | Node table copies; Main node live, foreign nodes frozen params | nodes hold `Pattern/Geometry/Base` + `Dist`; `L` at compute; labelled |
| F34 | 1663, 2749 | 65k sort on every tree click | `Base.Peak` cached per node |
| F35 | 458 | Display toggles invalidate coverage keys | keys use `Revision` only |
| F36 | 1590, 1596, 914 | Presets and sliders only widen | `applyRange` with `RangeAuto` |
| F37 | 345 vs 653 | Cut-value `Step` set twice | `applyChoices` once |
| F38 | 837–847 → 893–899 | AR theme collapses the cut range | AR theme touches `full` only |
| F39 | 2000–2010 vs 2119–2126 | Same-file reselect refused; Process re-parses | reselect = reload, one `update("source")` |
| F40 | 4802–4807, 590–608, 2208 | 17 eager columns; 65k×17 `uitable` push per change | memoised `Cols`; tables lazy |

### 9.4 Graphics, UI, hygiene

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| F41 | 997–1013, 1015–1023 | All 5 views rendered per change | visible tab only; dirty keys |
| F42 | 1210–1219; 992, 1229, 1233, 2891 | New context menu per render; 11 `findall/findobj` | one menu at startup; registry |
| F43 | 805, 1297–1308, 1261 | Colorbar/triad recreated | created with the axes |
| F44 | 1251–1253 vs 1317; 1237 vs 1265 | Polar-3D overlay radius mismatch | `util_polarRadius` |
| F45 | 2833–2834; 1396, 1311, 2846 | Cut plotted twice; `cutData` ×3 | one `geo_cut` per change |
| F46 | 1438, 1458 | Cut POB/HPBW on first checked trace | named in label |
| F47 | 1818, 1817 | Timer per status; dead statement | one timer; gone |
| F48 | 1928 | `assignin('base')` | env-gated `app.Perf` |
| F49 | 2256 | Parse outside `try` | `guard` |
| F50 | 2648 | Hard-coded −250 | `ax.XLim(1)` |
| F51 | 3715 | Self-test needs a live app | `static selfTest()` |
| F52 | 785 | `plotTheme` ignores its argument | `util_theme(kind, limits)` |
| F53 | 704–711 | `-0` | `util_fmtNumber` |
| F54 | 507 | `pi` shadowed | gone with `gridComp` |
| F55 | 610–622 | Parameter visibility follows table filter | follows component kind |
| F56 | 947–972, 1026–1084, 2849–2924 | 250 lines of annotation bookkeeping | create-once handles |
| F57 | 3073 vs 248 | Title/version mismatch | title from `Const.ReleaseName` |

---

## 10. Destination file layout and size budget

```
classdef APAT_v3_M8 < matlab.apps.AppBase
  A  properties: UI handles (unchanged, ≈ 170) · Source Pattern Geometry Base ColCache View Map Gfx Busy Perf CovState
  B  Constant: Const (ReleaseName, PeakExcessDB=6, CircularAR_dB=3, ARLimits=[-30 30], AngleDecimals=5,
               UniformTolDeg=1e-6, PLFTiltCos=-1, RangeHardLimits=[-250 100], PrincipalAxes, Cols)
  C  orchestration: readConfig readCoverageConfig update guard col applyChoices applyVisibility applyRange setStatus
  D  renderers: renderFull(k) renderCut renderCoverage geo_displayMap util_theme util_polarRadius annotations
  E  coverage UI: node add/select/check, compute, query, table, export
  F  export: results, cut, UAN
  G  generated layout (byte-identical except callback targets)                     ≈ 680
  H  lifecycle: constructor, startupFcn (menu, timer, groups), shutdown, delete, closeRequest
  I  static selfTest + fixture generators fx_*
end
% ---- file-scope, app-free ----
io_read io_uan io_out io_cut io_ffs io_ffe io_ffd io_excel io_text util_colKind
pat_build pat_resample pat_resampleField geo_build geo_integrate geo_cut
pat_baseFacts met_peak met_orientation met_planes met_hpbw met_metrics
pol_circular pol_signedAR pol_tilt pol_plf
cov_dist cov_eval cov_inverse cov_coneMask cov_thresholds cov_eval_reference
util_fmtNumber util_presetRange util_nearest
```

| Section | Budget (lines) |
|---|---|
| A + B (properties, constants, `Cols`) | ≤ 260 |
| C (orchestration) | ≤ 380 |
| D (renderers) | ≤ 520 |
| E (coverage UI) | ≤ 380 |
| F (export) | ≤ 90 |
| G (layout, unchanged) | ≈ 680 |
| H (lifecycle) | ≤ 90 |
| I (self-test + fixtures) | ≤ 220 |
| readers (all formats) | ≤ 520 |
| numerical core | ≤ 360 |
| **Total** | **≤ 3,500 target, 3,600 ceiling** (M7: 5,199) |

Static checks at the gate: `grep -c "physicalTheta\|gridStep\|solidWeights\|findall\|findobj\|assignin\|prctile\|\.UserData"` on widget names = 0; `sqrt(2)`/`1i*` outside `pol_circular` = 0; `cosd(180)` outside `Const` = 0; `"dBi"` outside `Meta`/`Const` = 0; `cla(` only in `renderFull` topology branch; `drawnow` only in `guard`, the progress dialog and startup.

---

## 11. Work order — one drop, core first

1. **Core (file-scope, no UI):** `pat_build`, `geo_build`, `geo_integrate`, `pol_*`, `met_*`, `cov_*`, `pat_resample`, `geo_cut`, readers with `Meta`. Write `selfTest` alongside; run it green before touching the class.
2. **Class state:** replace the six table properties and the flag families with `Source/Pattern/Geometry/Base/ColCache/View/Map/Gfx`. Add `Const.Cols`, `col()`.
3. **Orchestration:** `readConfig`, `update(scope)`, `guard`, `applyChoices`, `applyVisibility`, `applyRange`, `setStatus` with one timer.
4. **Renderers:** `renderFull` (five kinds behind one function via a small per-kind table), `renderCut`, display map, create-once annotations, one context menu.
5. **Coverage tab:** nodes with `Pattern/Geometry/Base/Dist`, compute via `cov_dist/eval`, exact table, queries, presets under `RangeAuto`.
6. **Export** from data, UAN header from total-gain peak.
7. **Re-point callbacks** in the layout block to one-line `guard` calls. Delete every replaced M7 name in the same edit (list in §7.2). Run the static checks.
8. **Regression on real files:** one of each format (UAN, FZ, OUT, CUT single + multi, FFS, FFE single + multi-frequency, FFD single + multi, Excel 1/2/3, generic gain, generic E-field ×6, a coverage-results CSV). Compare total-gain peak/POB, HPBW, directivity, coverage at three thresholds against M7 at `L = 0` on **polar** display; every delta must be one listed in §9 (e.g. F01, F03, F05, F07, F13) and explained in the release notes.

---

## 12. Release gate — `APAT_v3_M8.selfTest()` (Static, no UI)

Fixture generators (`fx_*`, analytic, tiny): `fx_isotropic(dθ,dφ)`, `fx_dipole(axis)` (Hertzian, x/y/z), `fx_cp(sense)` (crossed dipoles in quadrature), `fx_gauss(θ0,φ0,hpbw)`, `fx_hemisphere`, `fx_spike(base, at)`, `fx_phaseSlope(kλ)`.

| # | Row | Assertion |
|---|---|---|
| 1 | `geometryFullSphere` | `Geometry.Omega == 4π` to 1e-12 for 1°, 2°, 5°, 0.5° grids and for pole-free `0.5:1:179.5` |
| 2 | `geometryHemisphere` | `Omega == 2π(1 − cos 90.5°)`… closed form; `IsFullSphere == false` |
| 3 | `integrate` | `geo_integrate(X) ≡ sum(X(:).*ΔΩ(:))` (dense) to 1e-12 on random `X` |
| 4 | `coverageOracle` | `cov_eval(d, T) ≡ cov_eval_reference(G, mask, T, ΔΩ)` to 1e-12 on 200 random `T`, including ties; `C(−Inf) = 100`, `C(+Inf) = 0`, strict `>` at a tie |
| 5 | `coverageInverse` | 50 random `c`: `cov_eval(d, T⁻) ≥ c` and `cov_eval(d, T) < c` just above; `c > 100 → NaN` |
| 6 | `coverageLossShift` | `cov_eval(d(G), T − L) ≡ cov_eval(d(G + L), T)` |
| 7 | `coneMask` | dot-product mask ≡ angular-distance mask on 20 random cones; boundary sample inside |
| 8 | `normalizePrecision` | fields bit-identical through `pat_build`; angles snapped; θ > 180 folded once; φ = 360 column folded with `PhiClosedInSource` |
| 9 | `resampleDecimate` | 0.5° → 1°, 0.25° → 1°, θ 0.5°/φ 1° → 1°: bit-exact selections; 0.3° → 1° yields a 1° grid |
| 10 | `resamplePower` | `fx_phaseSlope(10λ)` 2° → 1°: total-gain error at native samples 0, at midpoints < 0.05 dB (M7's `Re/Im` path: > 3 dB) |
| 11 | `resampleDomain` | `fx_hemisphere` 2° → 1°: no sample with θ > 90 |
| 12 | `peakSpike` | `fx_spike`: `wasAdjusted`, `value == base`, `spikeCount == 1`; pole-row spike detected; `fx_gauss(hpbw = 2°)` at 1°: **not** adjusted |
| 13 | `lossOffset` | for every `lossAdd` column: `col(P_L) == col(P_0) + L`; peak index, boresight, HPBW, directivity identical |
| 14 | `displayInvariance` | `Map` permutation is a bijection; `CData(:,ColIdx)` reproduces the physical grid under inverse permutation; metrics identical across the four span/elevation combinations |
| 15 | `circularSense` | `fx_cp("RHCP")` (`Eθ = 1, Eφ = −j`): `E_RCP_dB − E_LCP_dB > 60 dB`; `"LHCP"` symmetric; inverse∘forward = identity |
| 16 | `planes` | `fx_dipole("x")` on +Z: E-plane = θ-cut @ φ = 0, H @ 90; `fx_dipole("y")`: E @ 90, H @ 0; `fx_dipole("z")` (equatorial): E = θ-cut, H = φ-cut @ 90; `fx_cp` → `Planes.Source == "principal"` |
| 17 | `polarisationLabel` | `fx_dipole("x")` → Linear, tilt 0°; `fx_dipole("y")` → tilt 90°; `fx_cp("LHCP")` → "Circular (LHCP)"; label unchanged when 20 dB of far sidelobes are added |
| 18 | `plfNaN` | `PLF_dB(NaN AR) == NaN`; RHCP wave on RHCP antenna `AR = 0` → 0 dB; on LHCP → ≤ −30 dB; exactly-linear sample → linear-limit value |
| 19 | `metricsIsotropic` | `fx_isotropic`: directivity 0 dB, efficiency 100 %, F/B 0 dB; `fx_hemisphere`: efficiency/F-B NaN |
| 20 | `hpbwGauss` | `fx_gauss(hpbw = 20°)`: `met_hpbw` = 20° ± 0.1° on both planes |
| 21 | `readers` | each format fixture → canonical `Pattern`; `.cut ICOMP = 3` → `APAT:UnsupportedICOMP`; UAN `magnitude linear` → `APAT:UnsupportedUAN`; FFE 2-frequency fixture → 2 blocks; generic file with a sparse 7th column keeps all rows; headed 2-column gain cut is a pattern; header `el` → elevation with `ThetaDecidedBy == "header"` |
| 22 | `uniformAxes` | 1° passes; one 0.999° gap → regularised (`Regularized == true`) or `APAT:NonUniformGrid` per §15-1 |
| 23 | `fmtNumber` | `-0.001 → "0"`, `12.50 → "12.5"`, fixed precision preserved |
| 24 | `thresholds` | `cov_thresholds(-40, 10, 0.1)` has 501 exact elements |

The gate passes only when all rows pass **and** the static checks of §10 return zero.

---

## 13. Performance targets and measurement

Measured with `APAT_PROFILE=1` on a 1°×1° full sphere (181 × 360 = 65,160 samples), after warm-up:

| Action | M7 (typical, same machine) | M8 target |
|---|---|---|
| Load UAN → first plot visible | 5 renders + tables | ≤ 40 % of M7 (one render, lazy tables) |
| Component change | orientation + metrics + 5 renders + table push | ≤ 120 ms (one memoised column + one `CData`) |
| Loss change | full reprocess + 5 renders | ≤ 30 ms (offset + `CData`) |
| Span/elevation toggle | `sortrows` 17 cols + 5 renders | ≤ 60 ms (permutation) |
| Cut change | `cutData` ×3 + 3 redraws | ≤ 40 ms |
| Coverage compute (500 thresholds) | 260 MB transient, `N×T` | ≤ 1 MB, one sort; thresholds change ≈ 5 ms |
| Tree click | 65k `prctile` | ≈ 0 |

---

## 14. Risks and platform baseline

| Risk | Mitigation |
|---|---|
| A real-file delta against M7 that is not in §9 | Step 8 of the work order blocks release until it is explained or fixed |
| `pcolor`/`surf` `CData` in-place update semantics differ across releases | R2023b baseline; the topology branch (`cla` + recreate) is the fallback and is exercised by the size-change path |
| Datatip API differences | only `datatip(h, x, y)`/`DataIndex` are used; no `InterpolationFactor` |
| Regularisation of irregular grids changes numbers vs M7 | disclosed (`Regularized`) and listed as a designed delta |
| One-file constraint limits unit-test tooling | static `selfTest` + fixtures live in the file; CI calls `APAT_v3_M8.selfTest()` |

---

## 15. Open decisions — with recommendations

1. **Non-uniform source axes:** (a) error, or (b) regularise once onto the native minimum step inside the hull and disclose. **Recommend (b)**; the self-test covers both.
2. **Exactly-linear samples in the signed-AR view:** NaN (white) vs 0 dB. **Recommend NaN**; PLF uses the linear-limit branch.
3. **Peak excess:** keep 6 dB. **Recommend yes**; it is now a spatial rule so it is grid-aware.
4. **FEKO `Gain(Total)` column for `dBi` labelling of `.ffe`:** 3 lines, data already in memory. **Recommend defer** unless FEKO is a primary source.
5. **Body-of-revolution φ step for single `.cut`:** keep 10°. **Recommend keep**, disclosed.
6. **E/H planes for oblique boresights:** principal-axis fallback (recommended) vs. nearest grid plane through the peak.

---

## 16. Outcome

- **One dataflow**: `Source → Pattern → Geometry → Cols/Base → (View, Map) → renderers`, with loss as an offset.
- **Fewer lines** than M7 with the layout untouched (budget ≤ 3,500, ceiling 3,600).
- **Zero** duplicate algorithms, toolbox calls, `findall/findobj`, widget `UserData`, `assignin`.
- **Correct physics** for every accepted input: polar geometry always, no field rounding, no fabricated samples, grid-aware peak, polarisation-aware planes, honest units.
- **Speed**: component/loss/span changes are index and offset operations; coverage cost is independent of the threshold count.
- **Every convention** (circular sense, PLF tilt, peak excess, AR limits, unit class, θ/axis decisions) is one constant or `Meta` field and appears in Metadata.
- **57 defects** closed, each traceable to a self-test row or a static check.

---

## Appendix A — Reference kernels (MATLAB, base only)

### A.1 Coverage family

```matlab
function d = cov_dist(C, G, mask)
%COV_DIST Ω-weighted distribution of the level grid C over a region.
%   Coverage(T) = 100·Ω{C > T}/Ω_R with Ω{C > T} = Σ_{(i,j)∈R, C(i,j)>T} wθ(i)·dφ  (canonical grid only).
%   Sorting the region's values gives levels g_1 ≤ … ≤ g_n with weights ω_k; S(k) = Σ_{m≥k} ω_m,
%   so Ω{C > T} = S(k_T) with k_T = first k such that g_k > T. Reference: cov_eval_reference (self-test).
v = mask & isfinite(C);
w = (G.wTheta .* G.dPhi) .* ones(1, size(C, 2));            % ΔΩ(i,j), local temporary
[g, ~, bin] = unique(C(v));                                  % distinct levels g_1 < … < g_n (ties merged: pole rows repeat)
w = accumarray(bin, w(v));                                   % ω_k = Σ ΔΩ over samples at level g_k
d.g = g; d.S = flipud(cumsum(flipud(w))); d.Omega = sum(w);  % S(k) = Σ_{m≥k} ω_m ; Ω_R = S(1)
end

function cov = cov_eval(d, T)
% Coverage(T) [%] for any thresholds T (vector). k_T = first index with g_k > T  ⇔  bin edge search.
cov = zeros(size(T));
if isempty(d.g) || d.Omega <= 0, return; end
k = discretize(T, [-Inf; d.g; Inf]);                         % edge(k) ≤ T < edge(k+1)  ⇒ g_k ≤ T < g_{k+1} ⇒ first level > T is k
S = [d.S; 0];                                                % S(n+1) = 0 (nothing above the last level)
cov = 100 * S(k) / d.Omega;                                  % note: k already points to the first level > T
end

function T = cov_inverse(d, c)
% sup{ T : Coverage(T) ≥ c }: the level g_k* where k* is the last level with S(k*) ≥ c·Ω/100 (NaN if none / c > 100).
T = nan(size(c));
if isempty(d.g), return; end
for q = 1:numel(c)
    k = nnz(d.S >= c(q) * d.Omega / 100);                    % S is non-increasing ⇒ count = last index satisfying it
    if k >= 1, T(q) = d.g(k); end
end
end

function m = cov_coneMask(G, thC, phC, alphaDeg)
cx = sind(thC)*cosd(phC); cy = sind(thC)*sind(phC); cz = cosd(thC);
m = (G.sinT*G.cosP)*cx + (G.sinT*G.sinP)*cy + (G.cosT*ones(1,numel(G.cosP)))*cz >= cosd(alphaDeg) - 1e-12;
end

function T = cov_thresholds(tMin, tMax, step)          % counting, not accumulation
n = round((tMax - tMin)/step); T = tMin + (0:n).'*step; if T(end) < tMax - 1e-9, T(end+1) = tMax; end
end

function cov = cov_eval_reference(C, mask, T, dOmega)   % literal N×T form — self-test oracle only
v = mask(:) & isfinite(C(:)); g = C(v); w = dOmega(v); cov = zeros(size(T));
for k = 1:numel(T), cov(k) = 100 * sum(w(g > T(k))) / sum(w); end
end
```

### A.2 Separable integral

```matlab
function I = geo_integrate(G, X)      % ∫ X dΩ over the sampled grid, NaN-safe
I = G.dPhi * (G.wTheta.' * sum(X, 2, 'omitnan'));
end
```

### A.3 Spatial peak

```matlab
function P = met_peak(C, periodicPhi, excessDB)
%MET_PEAK A sample is an isolated spike iff it exceeds ALL its grid neighbours by more than excessDB.
%   Neighbours: θ±1 (rows), φ±1 (columns, wrapped when periodic). Pole rows (θ = 0 or 180) compare against the
%   adjacent ring's maximum because every φ sample on a pole row is the same physical direction.
[n, m] = size(C);
up = [C(1,:); C(1:n-1,:)];  dn = [C(2:n,:); C(n,:)];
if periodicPhi, lf = C(:,[m 1:m-1]); rt = C(:,[2:m 1]); else, lf = [C(:,1) C(:,1:m-1)]; rt = [C(:,2:m) C(:,m)]; end
nb = max(max(up, dn), max(lf, rt));
if n > 1, nb(1,:) = max(C(2,:)); nb(n,:) = max(C(n-1,:)); end   % pole rows vs adjacent ring
P.mask = isfinite(C) & (C - nb > excessDB);
[P.rawValue, P.rawIndex] = max(C(:), [], 'omitnan');
cand = C; cand(P.mask) = -Inf; [P.value, P.index] = max(cand(:));
P.wasAdjusted = P.mask(P.rawIndex); P.spikeCount = nnz(P.mask);
end
```

### A.4 Circular decomposition — one place (I10)

```matlab
function E = pol_circular(Eth, Eph, which)
%POL_CIRCULAR RHCP (which = 1) / LHCP (which = 2) components of E = Eθ θ̂ + Eφ φ̂.
%   Convention: e^{+jωt}, (θ̂, φ̂, r̂) right-handed. IEEE right-hand unit vector ê_R = (θ̂ − jφ̂)/√2; the RHCP
%   component is the projection on the conjugate basis, E_R = E·ê_R* = (Eθ + jEφ)/√2; E_L = (Eθ − jEφ)/√2.
%   Check: E = ê_R ⇒ Eθ = 1/√2, Eφ = −j/√2 ⇒ E_R = 1, E_L = 0.  (Appendix B.5)
if which == 1, E = (Eth + 1i*Eph)/sqrt(2); else, E = (Eth - 1i*Eph)/sqrt(2); end
end

function [Eth, Eph] = pol_fromCircular(Er, El)         % inverse, used by OUT / CUT ICOMP=2 / Excel format 2
Eth = (Er + El)/sqrt(2);  Eph = (Er - El)/(1i*sqrt(2));
end
```

### A.5 Signed axial ratio and polarisation tilt

```matlab
function AR = pol_signedAR(Eth, Eph)
r = abs(pol_circular(Eth, Eph, 1)); l = abs(pol_circular(Eth, Eph, 2)); d = r - l;
AR = min(20*log10((r + l) ./ max(abs(d), realmin)), 250) .* sign(d);
AR(abs(d) <= eps(max(r + l, 1))) = NaN;                % exactly linear: no sense (§15-2)
end

function tau = pol_tilt(Eth, Eph)
%POL_TILT Polarisation-ellipse tilt (deg) from θ̂ toward φ̂ at one direction (Appendix B.6).
tau = 0.5 * atan2d(2*real(Eth .* conj(Eph)), abs(Eth).^2 - abs(Eph).^2);
end
```

### A.6 PLF, NaN-safe

```matlab
function plf = pol_plf(AR_dB, rxMode, rxAR_dB, pairs, tiltCos)
ok = isfinite(AR_dB); plf = nan(size(AR_dB));
rw = 10.^(rxAR_dB/20) * (2*(rxMode == "RHCP" | (rxMode == "Auto" & pairs.Circular(1) == "E_RCP")) - 1);
ra = 10.^(abs(AR_dB(ok))/20) .* sign(AR_dB(ok));                                   % signed axial ratio
p  = 0.5 + (4*ra*rw + (ra.^2 - 1)*(rw^2 - 1)*tiltCos) ./ (2*(ra.^2 + 1)*(rw^2 + 1));
plf(ok) = 10*log10(min(max(p, eps), 1));
lin = isnan(AR_dB);                                                                 % exactly linear: r_a → ∞
plf(lin) = 10*log10(min(max(0.5 + (rw^2 - 1)*tiltCos/(2*(rw^2 + 1)), eps), 1));
end
```

### A.7 E/H plane selection from the tilt

```matlab
function planes = met_planes(P, base)                % base: Peak, TiltDeg, ARatPeak_dB, Boresight (index into PrincipalAxes)
[i, j] = ind2sub(size(P.Eth), base.Peak.index); thp = P.Theta(i); php = P.Phi(j);
ax = Const.PrincipalAxes; axTh = ax.theta(base.Boresight); axPh = ax.phi(base.Boresight);
usePol = ~P.IsGainOnly && isfinite(base.ARatPeak_dB) && abs(base.ARatPeak_dB) > Const.CircularAR_dB;
if usePol && axTh ~= 90                                                           % ±Z boresight
    phE = mod(php + sign(cosd(thp)) * base.TiltDeg, 180);
    planes = struct('E', cut("Theta", phE), 'H', cut("Theta", phE + 90), 'Source', "polarization");
elseif usePol                                                                     % equatorial boresight
    if abs(base.TiltDeg) < 45, planes = struct('E', cut("Theta", axPh), 'H', cut("Phi", 90), 'Source', "polarization");
    else,                      planes = struct('E', cut("Phi", 90), 'H', cut("Theta", axPh), 'Source', "polarization"); end
else                                                                              % gain-only / circular / oblique
    if axTh == 90, planes = struct('E', cut("Theta", axPh), 'H', cut("Phi", 90), 'Source', "principal");
    else,          planes = struct('E', cut("Theta", axPh), 'H', cut("Theta", axPh + 90), 'Source', "principal"); end
end
    function s = cut(type, v), s = struct('Type', type, 'Value', mod(v, 360)); end
end
```

### A.8 Display map (permutation, no copy)

```matlab
function M = geo_displayMap(P, G, view)
n = numel(P.Phi); j0 = find(P.Phi >= 180, 1); perm = 1:n;
if view.SignedPhi && ~isempty(j0), perm = [j0:n, 1:j0-1]; end
M.ColIdx = perm; if G.PhiPeriodic, M.ColIdx(end+1) = perm(1); end          % closing column for display only
M.PhiAxis = P.Phi(perm); if view.SignedPhi, M.PhiAxis(M.PhiAxis >= 180) = M.PhiAxis(M.PhiAxis >= 180) - 360; end
if G.PhiPeriodic, M.PhiAxis(end+1) = M.PhiAxis(1) + 360; end
if view.Elevation, M.ThetaAxis = 90 - P.Theta; M.ThetaDir = "normal"; M.ThetaLabel = "Elevation";
else,              M.ThetaAxis = P.Theta;      M.ThetaDir = "reverse"; M.ThetaLabel = "Theta"; end
M.Key = sprintf('%d|%d', view.SignedPhi, view.Elevation);
end
```

### A.9 Number formatting and preset range

```matlab
function s = util_fmtNumber(v, prec)           % compact (≤ 2 dp, no trailing zeros, never "-0") or fixed
if ~(isscalar(v) && isnumeric(v) && isfinite(v)), s = 'n/a'; return; end
if nargin < 2, s = sprintf('%.2f', v); s = regexprep(s, '\.?0+$', ''); else, s = sprintf('%.*f', prec, v); end
if strcmp(s, '-0'), s = '0'; end
end

function b = util_presetRange(peakValue, span, hard)   % [ceil5(peak) − span, ceil5(peak)] clamped to hard limits
if ~isfinite(peakValue), b = [-40 10]; return; end
hi = 5*ceil(peakValue/5); b = min(max([hi - span, hi], hard(1)), hard(2)); if diff(b) < 1, b(1) = max(hard(1), b(2) - span); end
end
```

---

## Appendix B — Derivations

**B.1 Separable weights and the full-sphere sum.** With `θᵢ⁻ = max(θᵢ − Δθ/2, 0)`, `θᵢ⁺ = min(θᵢ + Δθ/2, 180°)` on a uniform axis, `θᵢ⁺ = θᵢ₊₁⁻` for interior `i`, so `Σᵢ (cos θᵢ⁻ − cos θᵢ⁺) = cos θ₁⁻ − cos θₙ⁺`. If `θ₁ ≤ Δθ/2` and `θₙ ≥ 180° − Δθ/2` the clamps give `cos 0 − cos 180° = 2`; with `nφ·Δφ = 2π`, `Σ ΔΩ = 4π`.

**B.2 CCDF identity.** Partition the region by distinct level: `Ω{G > T} = Σ_{k : g_k > T} ω_k = Σ_{k ≥ k_T} ω_k = S(k_T)`, `k_T = min{k : g_k > T}` (empty ⇒ `S = 0`). `discretize(T, [−∞; g; ∞])` returns the bin with `g_k ≤ T < g_{k+1}`, i.e. the index of the first level strictly above `T` is that bin index when `S` is padded with `S(n+1) = 0`. Strict `>` and exact ties follow.

**B.3 Loss shift.** For a level column `X = X₀ + L`, `Ω{X > T} = Ω{X₀ > T − L}`; one distribution at `L = 0` serves every loss value. Not valid for `AR_dB` (L-independent), `PLF_dB` (Rx-dependent) or `Gain_PolCorrected_dB` when Rx settings change — hence the Rx key for those columns.

**B.4 Power + unit-phasor interpolation.** Adjacent samples `E₁ = A e^{jψ₁}`, `E₂ = A e^{jψ₂}`, `Δ = ψ₂ − ψ₁`. Linear `Re/Im` gives a midpoint magnitude `A|cos(Δ/2)|` (−6 dB at 120°, 0 at 180°); power interpolation gives `A²` exactly. The unit-phasor midpoint `(e^{jψ₁} + e^{jψ₂})/2 = e^{j(ψ₁+ψ₂)/2}·cos(Δ/2)` has the circular-mean angle for every `|Δ| < 180°`; where `|E| → 0` the phasor is arbitrary but multiplies `√P → 0`.

**B.5 Circular sense.** For propagation along `+r̂` with `(θ̂, φ̂, r̂)` right-handed and `e^{+jωt}`, the IEEE right-hand unit vector is `ê_R = (θ̂ − jφ̂)/√2` (the analogue of `(x̂ − jŷ)/√2` for `+ẑ`, Balanis §2.12: `Ex` leads `Ey` by 90°). Writing `E = E_R ê_R + E_L ê_L` and solving: `Eθ = (E_R + E_L)/√2`, `Eφ = −j(E_R − E_L)/√2` ⇒ `E_R = (Eθ + jEφ)/√2`, `E_L = (Eθ − jEφ)/√2`, i.e. `E_R = E·ê_R*`. Fixture: `Eθ = 1, Eφ = −j` ⇒ `E_R = √2, E_L = 0`.

**B.6 Polarisation-ellipse tilt.** For `E = Eθ θ̂ + Eφ φ̂` with `Eθ = a e^{jα}`, `Eφ = b e^{jβ}`, the major axis makes the angle `τ` with `θ̂` where `tan 2τ = 2ab cos(β − α)/(a² − b²)` (Balanis eq. 2-xx). Since `2ab cos(β−α) = 2 Re(Eθ conj(Eφ))` and `a² − b² = |Eθ|² − |Eφ|²`, `τ = ½·atan2(2 Re(Eθ conj Eφ), |Eθ|² − |Eφ|²)` — computed directly on the complex components. Undefined for circular states (both arguments → 0), which is why `met_planes` falls back when `|AR| ≤ 3 dB`.

**B.7 Plane snapping for a ±Z boresight.** At the pole sample with azimuth `φ_p`, `θ̂ = ±(cos φ_p, sin φ_p, 0)` (sign = `cos θ_p`), `φ̂ = (−sin φ_p, cos φ_p, 0)`. The co-pol tangent `t̂ = cos τ θ̂ + sin τ φ̂` lies in the vertical plane at azimuth `φ_p + sign(cos θ_p)·τ`; the H-plane is that azimuth + 90°.
