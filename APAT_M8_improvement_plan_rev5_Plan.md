# PART B — APAT M8: standalone architecture & improvement plan

**From:** `APAT_v3_M7_110_5.m` — 5,199 lines, one App Designer class, 183 functions (≈95 methods, 34 file-scope functions, ~690 lines of generated layout).
**To:** `APAT_v3_M8.m` — the **same one file**, rebuilt around one dataflow. Base MATLAB (R2023b baseline, no toolboxes).
**Delivery mode:** one drop. The destination is built core-first, the UI is pointed at it, and every M7 name the destination replaces is deleted in the same edit. No interim dual paths.

Line numbers in this part refer to `APAT_v3_M7_110_5.m`.

---

## 1. Executive summary

M7 is feature-complete and numerically serious; it is long and slow because **the same physical pattern is re-interpreted by every consumer** and **UI callbacks own algorithms**. Concretely:

- One sphere is materialised as six tables per refresh (`rawTbl → stdTbl → patTbl → viewBaseTbl → viewTbl → uanTbl`, 189–194) plus two more per coverage node (1684–1686). Display conventions (elevation θ, signed φ) are written **into the data** (439–459) and undone by `physicalTheta` at eight call sites.
- Geometry is recomputed everywhere: `gridStep`/`unique` at ≥ 7 sites, `solidWeights` at ≥ 6 sites, `sind/cosd` of all samples inside every orientation and cone call.
- Every user action re-enters the whole pipeline: a component change costs `calcPattern`-class work, five `cla`+`surf`, two new context menus per 3-D axes, a new colorbar, a 65k×17 `uitable` push.
- Several numerical policies are **wrong for legitimate inputs**, silently: solid-angle weights from display θ (negative over half the sphere in elevation mode), Re/Im rounding of the fields, linear Re/Im interpolation of fields with phase slope, a grid-independent percentile peak policy, spikes removed from ∫ but not from Ω, NaN fields turned into a "perfectly linear" PLF, raw far fields labelled dBi, Ludwig-3 cuts read as θ/φ, a basis-dependent polarisation label.
- Conventions (circular sense, time convention, calibration, axis order, mag/phase layout, θ convention) are implicit and undisclosed.

M8 is a different program with the same UI:

> **One canonical grid-native pattern. One separable geometry. One params-free base. One element-wise derived layer. One config snapshot. One graphics registry. One place per convention. One column registry.**
> Math never sees the app. UI never rebuilds math. Display is an index map, not a copy. Coverage is the formula. Every convention is a named constant shown in Metadata.

Outcome (§16): ≈ 3,150 lines (−37 %), ≤ 6 public methods, 0 duplicate algorithms, 0 toolbox calls, component change ≤ 120 ms, loss change ≤ 30 ms, coverage compute ≈ 1 MB instead of 260 MB, 66 catalogued defects closed with a self-test row each.

---

## 2. Goals and non-goals

**Goals**

1. Correct physics for every supported input (calibration, polarisation sense, principal planes, solid angle, resampling, peak).
2. One implementation per concept; no algorithm exists twice.
3. Every user action recomputes only its invalidation radius and touches only the graphics it changes.
4. Everything numerical is testable without a UI, and is tested.
5. Every convention is explicit, pinned in one place, and disclosed to the user.
6. Same file, same generated layout, same feature set, same or better output on all existing inputs (deltas are *designed* and listed).

**Non-goals** (M8.1 candidates): new plot types, new file formats beyond those listed in §6.1, new metrics beyond §6.7 (sidelobe level, XPD, beam solid angle are one-liners on the grid afterwards), a PLF tilt selector, a reference-power entry for sources that carry no calibration data at all.

---

## 3. Governing rule and invariants

### 3.1 The rule

```matlab
cfg    = app.readConfig();      % the ONLY place a widget .Value is read
result = f(data, cfg)           % app-free, alert-free, widget-free
app.apply*(result)              % the ONLY places handles / Items / Limits / Text / Visible are written
```

Every callback body is one line:

```matlab
function onSomething(app, ~), app.guard("Title", "scope"); end
```

`guard` owns `try/catch`, cancellation, the busy flag with deferred replay (§7.3), and the single `drawnow`.

### 3.2 Invariants (the drop is invalid if any of these move)

| # | Invariant |
|---|---|
| I1 | **Peak policy = spatial isolation.** A sample is a spike iff it exceeds every grid neighbour (4-neighbours, φ wraps when periodic; the adjacent **ring** for pole rows) by more than `Const.PeakExcessDB = 6`. Effective peak = highest non-spike sample. Raw and effective peaks are both reported. No quantile, no toolbox. |
| I2 | **Resampling never interpolates dB, AR or PLF.** E-field: per-component linear power + unit phasor (§6.3). Gain-only: linear power. Exact decimation whenever the target step is an integer multiple of the native step. Target axes stay inside the source domain. `pat_calcBase` runs **after** resampling, once per `Pattern.Revision`. |
| I3 | **Canonical sphere:** polar θ ∈ [0,180] ascending, φ ∈ [0,360) ascending, grid-native `[nθ×nφ]`, uniform steps validated once, `PhiPeriodic` detected, **no seam column**. Angles snapped to 5 decimals; **fields never rounded**. |
| I4 | **Metrics, orientation, principal planes and coverage boresight are defined on total gain** (or the single gain column). Component selection changes plots, tables and the POB marker only; status text names the component. |
| I5 | **Coverage:** `Coverage(T) = 100·Ω{G > T}/Ω_R`, strict `>`, ties exact, computed **only** on the canonical grid with `Geometry` weights. Cone membership uses physical unit vectors with a `−1e-12` boundary tolerance. |
| I6 | Query formatting stays on the query controls; datatips show exact values from the distribution, never from the drawn polyline. |
| I7 | **Display invariance:** toggling elevation θ / signed φ changes zero numbers in `Pattern, Geometry, Base, Derived, Metrics, Coverage`. |
| I8 | **Params-free base:** `pat_calcBase` depends only on `Pattern` (+ `Geometry`). `pat_applyParams` is element-wise and never changes a peak index, boresight, HPBW, F/B or directivity. |
| I9 | **Partial-sphere honesty:** efficiency and F/B are `n/a` unless `Geometry.IsFullSphere`; resampling never creates samples outside the source domain. |
| I10 | **Calibration honesty:** efficiency, EIRP, PFD, E_RMS and the `dBi` label exist only when `Meta.Calibration ∈ {"gain","directivity"}`; otherwise they are `n/a` and levels are labelled `dB(V)`. Directivity is scale-free and is always available. |
| I11 | **Uniform axes:** `Theta`, `Phi` are arithmetic progressions (`max|diff − Δ| ≤ 1e-6°`), validated once. `Geometry` is separable: `ΔΩ(i,j) = wTheta(i)·dPhi`; `Σ ΔΩ = 4π` **exactly** on a full sphere. |
| I12 | **Explicit coverage:** `cov_ccdf`'s header states the definition and the evaluation identity; `cov_ccdf_reference` (literal N×T form) lives in the file and the self-test proves `max|Δ| < 1e-9 %`. |
| I13 | **Pinned conventions:** circular sense, time convention, η₀, PLF tilt, Ludwig-3 reference axis, axis order, θ convention, calibration source are each defined in exactly one place and disclosed in Metadata and export headers. |
| I14 | **Readers are pure; `apply*` are the only writers** of `Items/ItemsData/Limits/Step/Text/Visible/Enable`. |
| I15 | Zero graphics-object growth across repeated component / cut / span / range / query / tab actions. |
| I16 | One `.m` file. Structs + prefixed local functions. Generated UI names unchanged. |
| I17 | **Column semantics live in `Const.Columns`.** No function tests a column name against a literal. |
| I18 | **Spike-mask scope:** the mask affects only effective-peak reporting, auto-range presets, orientation weighting and the renormalised metric integrals. Grids, plots, tables, exports and coverage are raw. |

---

## 4. Architecture

### 4.1 M7 dataflow (today) — hazards marked

```
FILE → readPattern (ICOMP≠2 ⇒ θ/φ ⚠D36; E_R=(Eθ+jEφ)/√2 ⚠D37; raw rE as dBi ⚠D38; FFE gain cols dropped ⚠D56;
      │           UAN header ignored ⚠D55; span/100/rmmissing heuristics ⚠D44 D48 D58)
      → rawTbl + blocks{} → normalizePattern (rounds FIELDS ⚠D61, folds θ twice, elevation heuristic ⚠D29) → stdTbl
  └─ refresh
     ├─ calcPattern(stdTbl) → patTbl ①                        (wasted whenever resampling follows)
     ├─ applyStep → integer-sample filter ⚠D53 | resample Re/Im 0..180×0..360 'nearest' ⚠D21 D23 → calcPattern ② → viewBaseTbl
     └─ applyAngularSpan → COPY 17 cols, rewrite θ/φ, sortrows → viewTbl (+ viewRevision)
        ├─ detectOrientation(viewTbl, comp) → solidWeights(DISPLAY θ) ⚠D19 → viewSolidAngle
        ├─ resolvePeak(P99.99+6, prctile) ⚠D1 D22 → POB;  calcMetrics(comp peak + total gain ⚠, spikes dropped from ∫ only ⚠D40)
        ├─ PLF: NaN → "linear" ⚠D41;  cosd(180) tilt (D24);  label V/H from sphere mean ⚠D63
        ├─ 5× cla + surf + 2 menus + triad + colorbar ⚠D35; uitable ← 65k×17; cutData ×3 ⚠D52
        └─ Coverage: Main node ← viewTbl (cloned twice); foreign node ← getParam() at load ⚠D39
              N×T logical→double (~260 MB); weights<0 filtered ⚠D42; table interp1 ⚠D43; presets only widen ⚠D60
```

Every arrow is a **full pattern**. Consumers do not share geometry. UI spans change physics. Coverage is a second app bolted onto a cloned table.

### 4.2 M8 dataflow (destination)

```
FILE ──► io_read(path, fmt) ──► Source { Raw, Blocks(nθ×nφ×4×F | nθ×nφ×nC×F), Theta, Phi, Freqs, Meta }
                                   Meta: Format, ThetaConvention, AxisOrder(+Source), Calibration(+Source), RefPower_W,
                                         UnitLabel, CircularBasis, Ludwig3Applied, SynthesizedRevolution,
                                         PhiClosedInSource, Regularized, Columns (registry rows for gain-only)
             ▼
        pat_normalize(Source, freqIndex) ──► Pattern { Theta[nθ], Phi[nφ], StepTheta, StepPhi,
             │                                          Eth, Eph (nθ×nφ complex) | G.(col) (nθ×nφ),
             │                                          IsGainOnly, FreqIndex, Revision, Meta }
             │                               asserts: ascending, UNIFORM (I11), θ⊂[0,180], φ⊂[0,360)
             ▼  (optional)   pat_resample(Pattern, step)  — decimate if exact, else power+phasor interp → Revision++
             ▼
        geo_build(Theta, Phi, StepTheta, StepPhi) ──► Geometry { wTheta[nθ], dPhi, sinT, cosT, cosP, sinP,
             │                                                   PhiPeriodic, IsFullSphere, OmegaSampled, AxesKey }
             ▼
        pat_calcBase(Pattern, Geometry) ──► Base { Cols.(E_Total_dB, E_TH_dB, E_PH_dB, E_RCP_dB, E_LCP_dB @L=0,
             │                                     AR_dB, *_Phase), Pol, Pairs, CopolAxis, Peaks.(col),
             │                                     Boresight, Planes, Metrics0, Revision }      (Const.CircularSign)
             ▼
        pat_applyParams(Base, params) ──► Derived { gain grids +L, PLF_dB (NaN-safe), Gain_PolCorrected_dB,
             │                                       EIRP_dBW / PFD_Wm2 / E_RMS_Vm (lazy, calibrated only),
             │                                       Metrics, ParamsKey }
             ▼
        View = readConfig()        component, cut, span, limits, freqIndex, masks — never copies Pattern
        Map  = geo_displayMap(Geometry, View)   { ThetaAxis, PhiAxis, ColIdx, ThetaDir, labels, ticks }
     ┌──────────┬──────────┬──────────┬──────────────┬──────────┬──────────┐
     ▼          ▼          ▼          ▼              ▼          ▼          ▼
   PLOTS     METRICS     CUTS      COVERAGE        EXPORT     TABLES    METADATA
 G(:,ColIdx)  Base+L   slices /   cov_ccdf(G,Geo,   Pattern/   Derived+  conventions,
  dirty tabs           great circ  mask,T) canon.   Derived    mask      calibration
```

**Dependency graph** (kept as the comment block above `update`):

```
SOURCE ─► PATTERN(Rev) ─► GEOMETRY(AxesKey) ─► BASE(Rev) ─► DERIVED(Rev, ParamsKey)
                                  │                │              │
                                  │        ┌───────┼──────┐   ┌───┴────┐
                                  ▼        ▼       ▼      ▼   ▼        ▼
                              COV CCDF  ORIENT  PLANES  PEAKS  PLOTS  TABLES/EXPORT
                                  │
                              CURVE(T) / INVERSE(c)     ← (grid, Geometry, mask) only — no View, no table
VIEW ─► MAP ─► ColIdx / axes / ticks / labels          (touches nothing above)
```

If a function needs something not on a path from its inputs, it is reaching into the app. That line does not belong in M8.

### 4.3 Layer contracts

| Layer | Object | Writer | Readers | Forbidden |
|---|---|---|---|---|
| Source | `app.Source` | `io_read` | `update("source")` | math, renderers |
| Pattern | `app.Pattern` | `pat_normalize`, `pat_resample` | all below | widget `.Value`, `cla` |
| Geometry | `app.Geometry` | `geo_build` on `AxesKey` miss | base, plots, cuts, coverage | storing an `nθ×nφ` ΔΩ matrix |
| Base | `app.Base` | `pat_calcBase` on `Revision` miss | derived, coverage nodes | params of any kind |
| Derived | `app.Derived` | `pat_applyParams` on `(Revision, ParamsKey)` miss | plots, metrics, tables, export | interpolation |
| View / Map | `app.View`, `app.Map` | `readConfig`, `geo_displayMap` | orchestration, renderers | math kernels |
| Conventions | `Const.*`, `Meta.*` | section B / readers | everything | literals `sqrt(2)`, `1i*`, `cosd(180)`, `"dBi"`, `120*pi` anywhere else |
| Node | `Cov_Tree` NodeData | coverage `apply*` | tree mirror, job plots | holding a `Derived`; nodes hold `Pattern/Geometry/Base` or a `PatternRef` |
| Graphics | `app.Graphics` | renderers | renderers | `findall`/`findobj`/Tag search |

**Validity is one comparison per layer** (`Revision`, `AxesKey`, `ParamsKey`, `Key`). No flag families.

### 4.4 Why this is shorter

| Concept | M7 (many implementations) | M8 (one) | What vanishes |
|---|---|---|---|
| Physical angles | `viewTbl` + `physicalTheta` ×8 | `Pattern` is polar; display is `Map` | `applyAngularSpan`, `physicalTheta`, display-θ bugs |
| Pattern identity | 6 tables + 2 per node | `Pattern` + `Base.Cols` + `Derived.Cols` | five table properties and every assignment |
| Refresh | `refresh → applyStep → applyAngularSpan → updateViewResults → renderAll…` | `update(scope)` | ≈ 500 lines of orchestration bodies |
| Step / seam / dΩ | `gridStep` ×7, `solidWeights` ×6, seam zeroing, `gridCache` | `Pattern.Step*`, `Geometry.wTheta/dPhi` | all of them |
| Cut geometry | `cutGeometry` + `calcCutGeometry` twins; `cutData` ×3 | `geo_cut` (slices) + `geo_greatCircle` | one twin, the status side-effect, two extra extractions |
| Coverage | `coverageCCDF` N×T + `coverageCacheKey` + `covThresholds` + `interp1` table + 2 query interpolations | `cov_ccdf` + `cov_inverse` + `cov_coneMask` + `cov_thresholds` | 5 helpers, 260 MB transient, plateau ambiguity |
| Circular components | 5 inline `(a ± 1i·b)/sqrt(2)` sites | `pat_circular` | 4 copies + the sign risk |
| Column semantics | `HiddenOutputColumns`, `componentMap`, `isARComponent`, `isGainDBColumn`, `cutCols` lists, 6 literals in `updateInputVisibility` | `Const.Columns` | six sites |
| Range UI | two controllers + startup slider arrays | one descriptor-driven controller | `setCoverageRange ∩ syncCoverageXRange`, `fullSliders/Mins/Maxs` |
| State | 6× `UserData`, 9-field `coverageRangeState` | `View` | flag plumbing |
| Graphics lookup | 12× `findall/findobj`, 2 menus per render | registry | search helpers, leaks |
| Units | implicit dBi | `Meta.UnitLabel` | every literal `'dBi'`/`'dB'` in titles |

---

## 5. Data model

### 5.1 Schemas (factory functions in file section B)

```matlab
Source   = struct('Raw',table(),'Blocks',[],'Theta',[],'Phi',[],'Freqs',NaN,'Meta',struct(),'Path','','Name','','Format','')
Pattern  = struct('Theta',[],'Phi',[],'StepTheta',NaN,'StepPhi',NaN,'Eth',[],'Eph',[],'G',struct(),'IsGainOnly',false, ...
                  'FreqIndex',1,'Revision',uint64(0),'Meta',struct(),'PhaseCoherence',NaN)
Geometry = struct('wTheta',[],'dPhi',NaN,'sinT',[],'cosT',[],'cosP',[],'sinP',[], ...
                  'PhiPeriodic',false,'IsFullSphere',false,'OmegaSampled',NaN,'AxesKey',"")
Base     = struct('Cols',struct(),'Peaks',struct(),'Pol',"n/a",'Pairs',struct('Linear',["E_TH","E_PH"],'Circular',["E_RCP","E_LCP"]), ...
                  'CopolAxis',[NaN NaN NaN],'Tilt_deg',NaN,'Boresight',1, ...
                  'Planes',struct('E',struct(),'H',struct(),'source',"principal"),'Metrics0',struct(),'Revision',uint64(0))
Derived  = struct('Cols',struct(),'Metrics',struct(),'ParamsKey',"",'Revision',uint64(0))
View     = struct('Component',"E_Total_dB",'SignedPhi',false,'ElevationTheta',false,'CutType',"Theta",'CutValue',0, ...
                  'CutBasis',"Circular",'CutTraces',[true false false],'Plane',"E",'FreqIndex',1,'RangeFull',[-40 10], ...
                  'RangeCut',[-40 10],'RangeAuto',true,'ColorStep',5,'ResultMask',[],'POB',true,'HPBW',false,'Overlay',false,'Camera',"iso")
Map      = struct('ThetaAxis',[],'PhiAxis',[],'ColIdx',[],'ThetaDir','reverse','ThetaLim',[0 180],'PhiLim',[0 360],'ThetaLabel',"Theta",'Key',"")
CovDist  = struct('g',[],'w',[],'S',[],'Omega',NaN,'Key',"")           % Ω-weighted gain histogram + suffix sum (§6.9)
Graphics = struct('Full',<1×5 struct: Axes,Surface,Colorbar,Triad,POB,Overlay,Key>,'Cut',<PolarLines,RectLines,HPBWRegions,Tips>, ...
                  'Coverage',<Jobs(id): Line, Query.(mode).(V,H,Tip)>,'Menu',gobjects(0))
```

### 5.2 Column registry — `Const.Columns`

```matlab
%  name                    label             kind      lossAdd  hidden  unit
Const.Columns = cell2table({ ...
  'E_Total_dB'             'Total Gain'      'gain'    true     false   'level'
  'E_TH_dB'                'Etheta Gain'     'gain'    true     true    'level'
  'E_PH_dB'                'Ephi Gain'       'gain'    true     true    'level'
  'E_RCP_dB'               'RHCP Gain'       'gain'    true     false   'level'
  'E_LCP_dB'               'LHCP Gain'       'gain'    true     false   'level'
  'AR_dB'                  'Axial Ratio'     'ar'      false    false   'dB'
  'PLF_dB'                 'PLF'             'plf'     false    false   'dB'
  'Gain_PolCorrected_dB'   'Polarized Gain'  'gain'    true     false   'level'
  'E_TH_Phase'             'Etheta Phase'    'phase'   false    true    'deg'
  'E_PH_Phase'             'Ephi Phase'      'phase'   false    true    'deg'
  'E_RCP_Phase'            'RHCP Phase'      'phase'   false    true    'deg'
  'E_LCP_Phase'            'LHCP Phase'      'phase'   false    true    'deg'
  'EIRP_dBW'               'EIRP'            'link'    true     true    'dBW'
  'PFD_Wm2'                'PFD'             'link'    false    true    'W/m^2'
  'E_RMS_Vm'               'E_RMS'           'link'    false    true    'V/m'}, ...
  'VariableNames', {'name','label','kind','lossAdditive','hidden','unit'});
```

One table drives: component dropdown items (`kind ∈ {gain, ar, plf}`), results-filter defaults (`hidden`), colour theme (`kind == "ar"` → signed AR map), loss application (`lossAdditive`), coverage distribution keys (`lossAdditive` → the L=0 distribution is reused with `T − L`), link-parameter visibility (`kind == "link"` → Pt/R controls; `kind == "plf"` → Rx controls), resampling domain (`kind == "gain"` → linear power), unit labels (`'level'` → `Meta.UnitLabel`). For gain-only sources the registry rows are synthesised from the header names by `util_columnKind(name)` (`gain|directivity|eirp|…dB` → `gain`; `ar|axial` → `ar`; `phase|deg` → `phase`; else `other`), which also fixes the "column 3 whatever it is" fallback (D54).

---

## 6. Pipelines

### 6.1 Import — `io_*`

Every reader is a **descriptor** plus at most one format-specific parser. Descriptors are data:

```matlab
Formats = dictionary(key → struct( ...
   'order',  [θ φ c1 c2 c3 c4],           'kind',   "reim" | "magphase" | "gain", ...
   'basis',  "theta-phi" | "rhc-lhc" | "lhc-rhc" | "ludwig3", ...
   'theta',  "polar" | "elevation" | "auto", ...
   'calib',  "gain" | "directivity" | "field" | "header",   'unit', "dBi" | "dB" | "dB(V)", ...
   'source', "XGTD UAN" | "CST FFS" | …))
```

| Format | basis | θ | calibration | Notes |
|---|---|---|---|---|
| UAN / FZ (XGTD) | θφ mag+phase | polar | **header** | Parse `begin_<parameters>…end_<parameters>`: `magnitude dB|linear`, `phase degrees|radians`, `polarization theta_phi|…` (others → error), `pattern gain|…`, `maximum_gain` (recorded, compared with the computed peak) (D55). φ ≥ 0 on export. |
| OUT (GRASP) | rhc-lhc | polar | field* | *unless a header states dBi; `pat_circular` inverse |
| CUT (GRASP) | `ICOMP` 1 θφ / 2 RHC-LHC / 3 **Ludwig-3** | auto (own fold) | field* | Single cut → body of revolution at **Δθ**, flagged `SynthesizedRevolution` (D14, D47). Any other `ICOMP` → `APAT:UnsupportedICOMP` (D36). |
| FFS (CST) | θφ Re/Im | polar | **header** | `// Radiated/Accepted/Stimulated Power` → `G = 4π·|rE|²/(2η₀·P_acc)` (D38) |
| FFE (FEKO) | θφ Re/Im | polar | **columns** | `#Result Type: Gain|Directivity` + columns 7–9 → `k² = 10^{X_total/10}/(|Eθ|²+|Eφ|²)`, verified constant across samples (`std < 1e-6 dB`) (D56). Blocks split on `#Frequency:`/`#Request Name:` (D27). `#Coordinate System: UV` → error. |
| FFD (HFSS) | θφ Re/Im | polar | **sibling `.txt`** | θ outer / φ inner ordering (verified). Companion `<name>.txt` → accepted power per frequency (D57); absent → `"field"`. `PhiClosedInSource` recorded (D49). |
| Excel matrix 1/2/3 | θφ / rhc-lhc / both | polar | gain (dBi sheets) | `pat_circular` for format 2 |
| Generic text (6 variants) | per selector | auto | gain | axis order from header names (`theta/phi/az/el`), else span heuristic **disclosed** (D44); mag/phase layout from header, else range rule `max−min > 180 ⇒ phase`, both phase columns must agree (D48); no `rmmissing` — rows are dropped only when θ, φ or a *used* column is NaN (D58) |
| Generic gain-only | — | auto | gain | registry rows from header via `util_columnKind` (D17, D54) |
| Coverage results | — | — | — | detector requires header keywords **or** (`nCols < 6` **and** first column strictly monotone **and** all other columns ∈ [0,100] **and** first column does not look like an angle axis `0:Δ:≥180`) |

One kernel each: `io_fieldsToComplex(vals, kind)`, `io_toThetaPhi(c1, c2, basis, phiDeg)` (θφ / circular inverse via `pat_circular` / Ludwig-3 rotation, Appendix A.7), `io_calibrate(Eth, Eph, meta, calibSource)` (Appendix A.8). All readers return the same `Source` pack; none touches a widget (D9, D34).

### 6.2 Canonicalise — `pat_normalize(Source, freqIndex)`

1. Apply `Meta.ThetaConvention` (`elevation` → θ = 90−θ; `auto` → θ<0 with range ⊂ [−90,90] ⇒ elevation, recorded as `Meta.ThetaInterpreted`); θ<0 → (−θ, φ+180); θ>180 → (360−θ, φ+180). **Once.** (D29)
2. `φ = mod(φ,360)`; snap θ, φ to `Const.AngleDecimals = 5` (**angles only**, D61).
3. Dedupe directions (`unique([φ θ],'rows','first')`); a supplied φ=360 column folds into φ=0 (`Meta.PhiClosedInSource = true`).
4. Axes: `Theta = unique(θ)`, `Phi = unique(φ)`. **Uniformity (I11):** `StepTheta = (Theta(end)−Theta(1))/(nθ−1)`; assert `max|diff(Theta) − StepTheta| ≤ Const.UniformTolDeg`; same for φ (`StepPhi = 360/nφ` when the span closes). Failure → `APAT:NonUniformGrid` (or regularise once with `Meta.Regularized = true`, §15-2).
5. Regularity `nθ·nφ == N`; if false → one `scatteredInterpolant` per primitive onto the native-step grid inside the source hull; `Meta.Regularized = true`.
6. Reshape grid-major: `Eth = reshape(…, nθ, nφ)` (θ down rows, φ across columns). **No seam column.**

`Pattern.Eth(i,j)` is the field at `(Theta(i), Phi(j))`. Nothing downstream ever measures a step or indexes a table again.

### 6.3 Resample — `pat_resample(Pattern, stepDeg)` (magnitude/phase-separable, per component)

**Domain:** `θq = Theta(1):step:Theta(end)`, `φq = Phi(1):step:Phi(end)` (periodic closure through `[Phi, Phi(1)+360]` when `PhiPeriodic`). Never outside the source hull (D21).

**Decimation:** per axis, if `k = step/nativeStep` is an integer (`|k − round(k)| < 1e-9`), select every `k`-th sample — bit-exact, no arithmetic (D53). Both axes exact ⇒ no interpolation at all.

**E-field interpolation — magnitude/phase separable, per component:**

```matlab
function [E, coh] = pat_resampleField(E, interp)        % interp = bilinear on the (φ-closed) source grid
mag = abs(E);  z = E ./ max(mag, realmin);              % unit phasor, zero-safe
Pq  = interp(mag.^2);                                   % linear POWER: no phase-slope dip, ever
Zq  = interp(z);                                        % circular mean of neighbouring phases: no unwrapping
coh = abs(Zq);                                          % 1 = phase well sampled … 0 = phase under-sampled
E   = sqrt(max(Pq, 0)) .* (Zq ./ max(coh, realmin));
end
```

Why this is right and sufficient:

- The magnitude defect of linear Re/Im interpolation (D23: at 120° phase change per sample the midpoint magnitude is `cos 60°` = −6 dB; at 180° it is a null) cannot occur — power is interpolated as power.
- The phase of the interpolated phasor is the circular mean of the neighbours' phases, which is the correct first-order value for any phase slope below 180°/sample; no unwrapping and no reference component are needed. Where a component is (near) zero its phase is meaningless **and harmless**, because it multiplies `√P ≈ 0`.
- The relative phase `ψθ − ψφ` — which determines AR, RCP/LCP split and PLF — is the difference of two circular means; the interpolation error is bounded by the cell and vanishes where either component vanishes.
- `min(coh)` and the count of cells with `coh < Const.PhaseCoherenceMin = 0.5` go into `Pattern.PhaseCoherence` and a Metadata row ("Phase under-sampled cells: n") — a free diagnostic that no other method offers.

**Gain-only:** `10.^(G/10)` in, bilinear, `10*log10(max(·, Const.PowerFloor))` out, for registry kind `gain`; other kinds linear.

`Revision++`. FFD/FFE blocks are resampled lazily per `(FreqIndex, step)`.

### 6.4 Geometry — `geo_build(Theta, Phi, StepTheta, StepPhi)`

```matlab
function G = geo_build(th, ph, dth, dph)
%GEO_BUILD Separable solid-angle weights for a uniform θ×φ grid (I11).
%   ΔΩ(i,j) = wTheta(i)·dPhi,   wTheta(i) = cos θᵢ⁻ − cos θᵢ⁺,   θᵢ∓ = clamp(θᵢ ∓ Δθ/2, 0°, 180°)
%   Σᵢ wTheta(i) telescopes to cos θ₁⁻ − cos θₙ⁺ (= 2 when the end cells reach both poles);
%   Σⱼ dPhi = nφ·Δφ (= 2π when periodic)  ⇒  Σ ΔΩ = 4π exactly on a full sphere.
th = th(:); ph = ph(:);
assert(th(1) >= 0 && th(end) <= 180 && ph(1) >= 0 && ph(end) < 360, 'APAT:Geometry', 'grid not canonical');
lo = max(th - dth/2, 0);  hi = min(th + dth/2, 180);
G.wTheta = cosd(lo) - cosd(hi);                       % nθ×1, ≥ 0 analytically
G.dPhi   = deg2rad(dph);                              % scalar
G.PhiPeriodic  = abs(numel(ph)*dph - 360) < 1e-9;
G.OmegaSampled = sum(G.wTheta) * numel(ph) * G.dPhi;
G.IsFullSphere = G.PhiPeriodic && lo(1) == 0 && hi(end) == 180;
G.sinT = sind(th); G.cosT = cosd(th); G.cosP = cosd(ph).'; G.sinP = sind(ph).';
G.AxesKey = geo_axesKey(th, ph);                      % unit vectors on demand: Ux = sinT*cosP, Uy = sinT*sinP, Uz = cosT*ones(1,nφ)
end
```

- Integrals everywhere: `geo_integrate(G, X) = G.dPhi * (G.wTheta.' * sum(X, 2, 'omitnan'))`.
- Hemisphere θ 0…90: `Σ wTheta = 1 − cos 90.5°` (closed form), `IsFullSphere = false`; Metadata shows "Sampled solid angle: 2.0087π sr (50.2 %)".
- Pole-free grids (θ = 0.5:1:179.5) still sum to `4π` because the end cells are clamped to the poles.
- Cone / F/B dot products: `(sinT*cosP)*cx + (sinT*sinP)*cy + cosT*ones(1,nφ)*cz` — one `nθ×nφ` temporary, never stored.

### 6.5 Base — `pat_calcBase(Pattern, Geometry)`

Same physics as M7 4723–4800 at `FieldScale = 1`, with these changes:

- Circular components from **one** kernel: `[Er, El] = pat_circular(Eth, Eph, Const.CircularSign)` → `Er = (Eth − j·s·Eph)/√2`, `El = (Eth + j·s·Eph)/√2`; `s = +1` is IEEE sense under `e^{+jωt}` (Appendix A.4), `s = −1` reproduces M7 (D37).
- dB via one `util_db(P) = 10*log10(max(P, Const.PowerFloor))`.
- Signed AR from `|Er|, |El|` as M7; exactly-linear samples → `NaN` instead of −100 dB (D25, §15-6).
- **Ω-weighted** component powers for the polarisation class: `Pc = geo_integrate(G, |E_c|²)` for θ, φ, R, L (D5).
- **Co-pol axis at the effective peak** (Appendix A.5): `[a, τ, ok] = met_copolAxis(Eth(p), Eph(p), θp, φp, AR_dB(p))`. Polarisation wording (D63):
  - circular if `max(P_R, P_L) > max(P_θ, P_φ)` **and** `|AR_dB(p)| < Const.CircularAR_dB = 3` → `"Circular (RHCP|LHCP)"` from the sign of `AR_dB(p)`;
  - else linear: `"Linear (co-pol ≈ ±X|±Y|±Z)"` when `|a·axis| ≥ cos 22.5°`, otherwise `"Linear (tilted τ° from θ̂)"`; when the boresight is within 45° of the horizon plane the alias "Vertical" (`|a_z| ≥ cos 45°`) / "Horizontal" is appended, because there the words have a meaning.
  - `Pairs.Linear/Circular` ordering (co first) still comes from the Ω-weighted powers.
- `Peaks.(col) = met_peak(grid, Const.PeakExcessDB, PhiPeriodic, isPole)` for every registry `gain` column on first request, always for `E_Total_dB`.
- `Boresight = met_orientation(E_Total_dB, Geometry, Peaks.E_Total_dB)` (45° cones about ±X/±Y/±Z, spike-masked, `−1e-12` tolerance shared with coverage, D45).
- `Planes = met_planes(...)` (§6.7). `Metrics0 = met_metrics(Base, Geometry)`.

### 6.6 Params — `pat_applyParams(Base, params)`

```matlab
L = params.GainLoss_dB;  R = Const.Columns;
for c = R.name(R.lossAdditive & isfield(Base.Cols, R.name)).', D.Cols.(c) = Base.Cols.(c) + L; end
D.Cols.AR_dB = Base.Cols.AR_dB;                                   % copy-on-write, no cost
D.Cols.PLF_dB = met_plf(Base.Cols.AR_dB, params.RxMode, params.RxAR_dB, Base.Pairs, Const.PLFTiltCos);   % NaN-safe (D41)
D.Cols.Gain_PolCorrected_dB = D.Cols.E_Total_dB + D.Cols.PLF_dB;
% EIRP_dBW / PFD_Wm2 / E_RMS_Vm added by pat_applyLink(D, params) only when ResultMask or export asks, and only if calibrated (I10)
D.Metrics = Base.Metrics0;  D.Metrics.PeakGain_dB = Base.Peaks.E_Total_dB.value + L;
D.Metrics.Efficiency_pct = Base.Metrics0.Efficiency_pct * 10^(L/10);      % NaN stays NaN (uncalibrated / partial)
D.ParamsKey = jsonencode(params);
```

A loss change is five matrix additions and one `CData` push. Nothing else moves (I8).

### 6.7 Metrics — `met_*`

**`met_peak`** (I1; Appendix A.3): 4-neighbour maximum with φ wrap; pole rows compare against the adjacent ring (a spike on a pole row is otherwise undetectable because all φ samples of the row are copies of one direction). Returns `mask, value, index, rawValue, rawIndex, wasAdjusted, spikeCount`.

**`met_copolAxis`** (Appendix A.5): major axis `a` of the polarisation ellipse at one direction, from the complex field alone: `χ = ½·arg(Eθ² + Eφ²)`, `a = Re((Eθ θ̂ + Eφ φ̂)·e^{−jχ})/‖·‖`; undefined (`ok = false`) when `|AR| < 3 dB`.

**`met_planes`** (D26): with `r̂` the peak direction and `a` the co-pol axis (`a ⊥ r̂` by construction):
- **E-plane** = great circle through `r̂` with tangent `a`; **H-plane** = great circle with tangent `r̂ × a`. Both sampled by `geo_greatCircle` (§6.8) at the native θ step — exact for **any** boresight and polarisation, not only ±Z / equatorial ones.
- Fallback (`ok = false`, i.e. CP, or gain-only): M7's principal-axis planes (E = θ-cut at the boresight φ; H = φ-cut at θ=90 for ±X/±Y, θ-cut at φ+90 for ±Z). `Planes.source ∈ {"polarization","principal"}` is shown in Metadata.
- The interactive E/H switch shows the same planes (§15-8 offers grid-snapped display as an alternative).

**`met_hpbw`**: as M7 `calcHPBW` (wrap-aware linear crossing); operates on any cut struct.

**`met_metrics`** (D40, I9, I10):

```matlab
keep = ~P.mask & isfinite(G);                                   % spikes removed from BOTH sides
IG   = geo_integrate(geo, 10.^(G/10) .* keep);  Ok = geo_integrate(geo, double(keep));
D_peak = 10*log10( 4*pi * 10^(P.value/10) / IG * (Ok/(4*pi)) );  % scale-free: valid for gain, directivity and raw field
eta    = (IG / Ok) * 100;                                        % only if IsFullSphere && Calibration ∈ {gain}; else NaN
FB     = P.value - max(G(coneMask(antipode(P), Const.BackConeDeg)));   % only if IsFullSphere; back region = 30° cone about the antipode
```

`AxialRatioAtPeak_dB`, `PeakTheta/Phi` (physical), `Tilt_deg`, `CopolAxis`, `Planes.source`, `PhaseCoherence`, `OmegaSampled`, `Calibration` all go to Metadata.

**`met_plf`** (Appendix A.6): finite-AR samples only; exactly-linear (`AR = NaN` by policy) handled by an explicit `ra = ∞` branch; `PLF_dB(~finite) = NaN` (D41). `Const.PLFTiltCos = −1` (worst-case tilt, D24) documented and shown.

### 6.8 Cuts — `geo_cut` and `geo_greatCircle`

Grid-native slices (exact, zero arithmetic):

- **φ-cut** (fixed θ): `i = nearest(Theta, v)`; `angle = Phi`; `data = D.(c)(i,:).'`; closed for display by `Map.ColIdx`.
- **θ-cut** (fixed φ): `j = nearest(Phi, mod(v,360))`, `j2 = nearest(Phi, mod(Phi(j)+180,360))`; `angle = [Theta; 360 − Theta(end−1:−1:1)]`; `data = [D.(c)(:,j); D.(c)(end−1:−1:1, j2)]`.

Great-circle cuts (Appendix A.9): direction `d(α) = cos α·r̂ + sin α·t̂`, `α = 0:StepTheta:360−StepTheta`; `(θ,φ)` from `d`; values by bilinear `interp2` of the **dB grid** with the φ-closing column. This is a 1-D *display/measurement* sampling of the derived grid (the same operation `calcHPBW` already performs between two samples); it never feeds back into `Pattern`. Used for E/H planes and offered as "Plane through peak (custom tangent)" in the cut-type list.

Every cut returns `struct(angle, theta, phi, data.(c), fixedAngle, symbol, snapped, kind)`; pure; cached per `(Revision, ParamsKey, type, value, cols)`. **One extract** feeds the polar cut, the rectangular cut and both 3-D overlays (D52 ×3). Snapping is reported by the renderer as a transient status, never permanent (D52).

### 6.9 Coverage — `cov_*`

**Definition (I5).** For region `R` (sphere or cone of half-angle `α` about `ĉ`), gain grid `G` (dB) and thresholds `T`:

```
Coverage(T) [%] = 100 · Ω{G > T} / Ω_R,     Ω{G > T} = Σ_{(i,j)∈R, G(i,j)>T} ΔΩ(i,j),
ΔΩ(i,j) = wTheta(i) · dPhi,                   Ω_R = Σ_{(i,j)∈R, G finite} ΔΩ(i,j)
```

Strict `>`; ties exact; non-finite gain belongs to neither numerator nor denominator.

**Evaluation identity** (Appendix B.1): with `g₁ < … < g_n` the distinct levels in `R` and `ω_k` their solid angles, `Ω{G > T} = S(k_T)`, `S(k) = Σ_{m≥k} ω_m`, `k_T = first k with g_k > T`.

**Kernel — the code is the formula** (Appendix A.1 has the full set):

```matlab
function [C, d] = cov_ccdf(G, geo, mask, T)
%COV_CCDF  Coverage(T) [%] = 100 · Ω{G > T} / Ω_region      (Ω-weighted CCDF, strict '>')
%   Ω{G > T} = Σ_{(i,j)∈region, G(i,j)>T} ΔΩ(i,j),   ΔΩ(i,j) = geo.wTheta(i)·geo.dPhi     (canonical grid only)
%   Identity: (g_k, ω_k) = Ω-weighted histogram of G over the region, S(k) = Σ_{m≥k} ω_m  ⇒  Ω{G > T} = S(k_T),
%             k_T = first k with g_k > T.  Reference form: cov_ccdf_reference (self-test oracle).
v = mask & isfinite(G);
if ~any(v, 'all'), C = zeros(size(T)); d = newCovDist(); return; end        % empty region (cone outside domain)
dOmega = geo.wTheta .* geo.dPhi .* ones(1, size(G, 2));                     % ΔΩ(i,j), local, never stored
[g, ~, bin] = unique(G(v));                                                 % distinct gain levels g_1 < … < g_n
w  = accumarray(bin, dOmega(v));                                            % ω_k
S  = [flipud(cumsum(flipud(w))); 0];                                        % S(k) = Ω{G ≥ g_k}; S(n+1) = 0; S(1) = Ω_R
kT = discretize(T(:), [-Inf; g; Inf]);                                      % g_{kT−1} ≤ T < g_{kT}
C  = 100 * S(kT) / S(1);
d  = struct('g', g, 'w', w, 'S', S, 'Omega', S(1), 'Key', "");
end
```

`cov_ccdf_reference` (literal N×T loop, self-test oracle), `cov_inverse(d, c) = sup{T : Coverage(T) ≥ c}` via `nnz(S ≥ c·Ω/100)`, `cov_coneMask` (unit vectors, `−1e-12`), `cov_thresholds(min,max,step)` by counting (`n = round((max−min)/step)`, D18).

**Where it runs.**

- Input is always `(Base|Derived grid, Geometry, mask, T)`. A `View`, a `Map` or a table **cannot** be passed — there is no signature for it.
- One distribution per `(Revision, column, ParamsKey-part, coneKey)` in `app.CovDists` (`dictionary`). `ParamsKey-part` is empty for `lossAdditive` columns (the L=0 distribution is reused with `T − L`, Appendix B.3) and the full key otherwise.
- Threshold spinners → re-evaluation from `d` (`discretize` only). Queries → `cov_ccdf` / `cov_inverse` exact; tips at exact coordinates (D31, D50).
- Results table: computed jobs re-evaluated **exactly** at the union of thresholds; loaded-file curves interpolated linearly and flagged `⌁` in the header (D43). Numeric table + `ColumnFormat`.
- Foreign nodes own `Pattern/Geometry/Base` built at load by the same `pat_*/geo_*`; `pat_applyParams` at compute time from the current `readConfig`; every job records `ParamsKey, StepDeg, Calibration, SynthesizedRevolution` (D39). The Main node holds a `PatternRef`.
- Threshold and X-range presets are **re-derived per active node/component** (peak-referenced 50-dB window) and applied only while `View.CovRangeAuto`; they never widen monotonically (D60).

**Cost.** 1° sphere (65,160 samples), 501 thresholds: M7 ≈ 260 MB transient, O(N·T); M8 ≈ 1 MB, one sort (≈ 5 ms), curve ≈ 0.1 ms.

### 6.10 Export — lazy, canonical

- Results: `Derived.Cols` masked by `View.ResultMask`, θ/φ from `Pattern` (physical), built on click; never from the `uitable` (D32).
- UAN: from `Pattern` (φ ∈ [0,360), no seam), 5 dp, φ-major; `maximum_gain` per §15-5.
- Cut: from the cached extract. Coverage: numeric table.
- Every export header carries the convention block: `ThetaConvention, CircularSign, Calibration/UnitLabel, PLFTiltCos, Ludwig3Ref (if used), ParamsKey, StepDeg, Revision, ReleaseName`.

---

## 7. Orchestration

### 7.1 `readConfig` / `readCoverageConfig`

Pure. The only `.Value` readers. Cut value is converted from display units to physical in `readConfig` (§15-9). Threshold list construction never writes a spinner (M7 1521–1524 did).

### 7.2 `update(app, scope)` — the dispatcher

| User action | scope | Recompute | Render |
|---|---|---|---|
| Load / Process / text format | `source` | `io_read` → `pat_normalize` → (resample if 1°) → `geo_build` (AxesKey miss) → `pat_calcBase` → `pat_applyParams` | `applyChoices`, `applyVisibility`, metadata, range presets (if `RangeAuto`), **visible** full tab, cuts, tables if visible |
| FFD/FFE block | `freq` | `pat_normalize(block)` → geometry shared if `AxesKey` equal → base → params | as `source` minus choices |
| Native ↔ 1° | `step` | `pat_resample` → `geo_build` → base → params | as `freq` |
| Loss / Pt / R / Rx | `params` | `pat_applyParams` (element-wise) | `CData` on visible tab, cut `YData`, metadata rows, tables if visible |
| Component | `component` | `Base.Peaks.(col)` (cached) | `CData` visible tab (+ radius on polar-3D, `ZData` rect-3D), POB, titles, colorbar theme |
| Elevation / signed φ | `span` | **nothing numeric**; `geo_displayMap` | `CData(:,ColIdx)`, axes vectors, ticks, labels, cut `XData` remap, POB re-index |
| Cut controls / E-H / basis | `cut` | `geo_cut` or `geo_greatCircle` (cached) | 2-D cut lines + both overlays from **one** extract, HPBW |
| Ranges / colour step | `range` | nothing | `clim/zlim/RLim` + ticks of the visible tab; other tabs marked dirty |
| POB / HPBW / tab change | `annot` | nothing | visibility of registry handles; **stale tab → render on selection** |
| 3-D view | `camera` | nothing | `view/camup` |
| Coverage compute | — | `pat_applyParams(node.Base, cfg)` if not `lossAdditive` → `cov_ccdf` | curve, table, legend, node tooltip |
| Coverage thresholds | — | re-evaluate from `d` | line `YData` |
| Coverage query | — | `cov_ccdf` / `cov_inverse` | query lines / tips (registry) |

Ladder: `source ⊃ freq ⊃ step ⊃ params ⊃ component ⊃ {span, cut, range, annot, camera}`. `update` runs the stages at or below the requested rung, marks non-visible full-pattern tabs dirty, renders the visible one, then **one** `drawnow limitrate`.

Deleted as bodies (they become one-liners or vanish): `refresh`, `updateViewResults`, `refreshAngularView`, `applyStep`, `applyAngularSpan`, `stepChanged`, `onComponentChanged`, `renderAllFullPatterns`, `drawSpatial3D`, `initRanges`, `selectBlock`, `activateSource`, `syncCoverageNodeFromView`.

**Worked contrasts**

| Action | M7 | M8 |
|---|---|---|
| Component change, 1° FFD | `onComponentChanged → updateViewResults` → orientation + metrics + tables + `plotCut` + 5× `cla/surf` + 2 menus each + uitable push; 0.8–2 s | `update("component")` → `Base.Peaks` hit → `CData` on the visible surface (+ polar radius), cut `YData`; ≤ 120 ms |
| Loss spinner | `refresh` → `calcPattern` on 65k complex → everything above | five matrix adds → `CData` → cut `YData` → 4 metadata strings; ≤ 30 ms |
| θ-span switch | clone 17 columns, rewrite θ, `sortrows`, re-detect orientation **on elevation angles** (negative dΩ), redraw all | `Map` permutation; tick labels and `YData`; math untouched; ≤ 100 ms |

### 7.3 `guard` — try/catch, cancel, busy with deferred replay

```matlab
function guard(app, title, scope)
if app.isClosing, return; end
if app.Busy, app.Pending = max(app.Pending, scopeRank(scope)); return; end     % defer, don't drop
app.Busy = true; c = onCleanup(@() app.setBusy(false));
try
    app.update(scope); drawnow limitrate
    while app.Pending > 0, s = app.Pending; app.Pending = 0; app.update(scopeName(s)); drawnow limitrate; end
catch err
    if err.identifier == "APAT:Cancelled", app.setStatus(app.Single_StatusBar, 'Cancelled.', true);
    else, app.showError(err, title); end
end
end
```

Only `ValueChangingFcn` storms (slider drags) are dropped while busy; a click made during a load is replayed once at the end.

### 7.4 `applyChoices`, `applyVisibility`, range controller, status, lifecycle

- `applyChoices` — the only writer of data-derived `Items/ItemsData/Limits/Step/Text`: component items and coverage component items from `Const.Columns ∩ Base.Cols`, cut-value limits/step from `Pattern` (once, D28), step dropdown items, FFD/FFE block items, checkbox labels (D33).
- `applyVisibility` — the only writer of `Visible/Enable`, computed from `Source.Meta`, `View`, registry kinds and coverage state (D34).
- **Range controller:** `RangeGroups.full` (5 sliders + 10 spinners) and `RangeGroups.cut` are two instances of one descriptor-driven `applyRange(group, limits)`. The AR theme sets **only** `RangeGroups.full` to `Const.ARLimits` (D20). `View.RangeAuto` becomes false the first time the user edits a range; presets re-apply only on `source/freq/step`. Coverage X-range and threshold spinners are a third instance (D60).
- **Status:** one reusable `timer` created in `startupFcn` (D12); `setStatus(label, msg, transient)`; the pattern/POB line is the *persistent* message; snaps and confirmations are transient (D52). Status text names the component: "Peak of *Axial Ratio*: … dB at (θ, φ)"; "POB" is reserved for total gain (D46).
- **Lifecycle:** `shutdown` stops the timer, deletes the dialog, clears the registry; `delete`/`closeRequest` call it once. Profiling (`perf`) records only when `getenv("APAT_PROFILE")` is set and never writes to the base workspace (D65).

---

## 8. Rendering — retained mode

**Registry and dirty keys.** `Graphics.Full(k).Key = strjoin([Revision, ParamsKey, Component, Map.Key, RangeKey], "|")`.

```matlab
function renderFull(app, k)
key = app.currentFullKey(k); s = app.Graphics.Full(k);
if s.Key == key, return; end
G = app.Derived.Cols.(app.View.Component)(:, app.Map.ColIdx);
if isgraphics(s.Surface) && isequal(size(s.Surface.CData), size(G)), set(s.Surface, 'CData', G, <coords>);
else, cla(s.Axes); s.Surface = <surf|pcolor|surface>(...); s.Surface.ContextMenu = app.Graphics.Menu; <triad once>; end
<theme, ticks, labels, POB DataIndex, overlay from the cut extract with the SAME radius mapping as the surface>
app.Graphics.Full(k).Key = key;
end
```

- `update` renders only the **visible** full-pattern tab; `fullPatternTabChanged` renders a stale tab on selection. Load cost drops by the three hidden `surf` calls.
- `cla` only when topology changes (grid size). Zero `findall`/`findobj` on any path. One `uicontextmenu` (startup), one triad per 3-D axes, one colorbar per axes, POB marker/tip per tab created once and re-indexed (D35).
- **Polar-3D radius** is one function `util_polarRadius(values, limits)` used by the surface and the overlay (D51, D3).
- **Display map** is an exact permutation: `perm = [j0:nφ, 1:j0−1]` for signed φ (`j0 = first column ≥ 180`), `ColIdx = [perm perm(1)]` when periodic (closing column for display only), `ThetaAxis = 90 − Theta` and `YDir = 'normal'` for elevation. Fisheye / 3-D geometry stays physical; only tick labels change.
- **Cuts:** three lines per axes created once (`Visible` toggles), HPBW regions and bound tips re-used; the HPBW/POB trace is named in the label ("HPBW (E_RCP)") when it is not Total (D62).
- **Tables:** pushed only when the Results tab is visible and the key changed; numeric matrix + `ColumnName`.
- Every colorbar label, axis label and datatip unit is `Meta.UnitLabel` (I10). The coverage axes title shows the region and the formula string `Coverage(T) = 100·Ω{G>T}/Ω_R`.

---

## 9. Defect register (consolidated) — why M8 cannot contain them

Grouped by class. Each row: M7 lines → defect → M8 mechanism. Every row has a self-test row or a static check in §12.

### 9.1 Numerical policy

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| D1 | 5113 | `prctile` → Statistics Toolbox dependency for the peak policy | `met_peak`, base MATLAB |
| D19 | 2810 → 4837–4848, 631 | With elevation θ active, `calcOrientation`/`calcMetrics` use display θ: `cosd(θ−Δ/2) − cosd(θ+Δ/2)` is **negative** for θ<0 → negative dΩ over half the sphere; cone energies, efficiency, directivity, F/B garbage | Math sees only `Pattern` (polar); `Geometry` asserts the domain |
| D21 | 4980–4984, 5061–5066 | Resampling targets 0..180×0..360 and fills misses with `'nearest'` → a hemispheric source acquires a fabricated back hemisphere | Resample inside the source domain; `IsFullSphere` gates η and F/B |
| D22 | 5085–5139, 245–246 | P99.99 + 6 dB rejects any beam whose −6 dB footprint is < ≈ 6.5 deg², independent of grid step (a 40 dBi Gaussian beam with 1.5° HPBW is "adjusted" on 1°, 0.25° and 0.1° grids alike) | Spatial isolation (I1), resolution-aware by construction |
| D23 | 4954–5059 | Linear Re/Im interpolation of Eθ/Eφ: 120° phase change per sample → −6 dB at the midpoint; 180° → null | Power + unit-phasor interpolation (§6.3) |
| D40 | 4631–4638 | Spike samples set to NaN for `∫G dΩ` but Ω keeps their area → directivity biased high, η biased low | `keep` mask on both sides (§6.7) |
| D41 | 4760–4762, 4778–4779 | `polSense(~finite) = 0` then `antennaRatio(polSense==0) = 1e12` → NaN fields become a perfectly linear antenna with finite PLF | `met_plf` finite-only; NaN propagates |
| D42 | 4580 | `coverageCCDF` filters `solidAngle ≥ 0`, hiding D19 instead of failing | `geo_build` asserts; `wTheta ≥ 0` analytic; no filter |
| D53 | 421–424 | 1° "decimation" keeps integer-degree samples: exact only if `1/step ∈ ℕ`; 0.3° → **3°** grid | Per-axis exact decimation iff `step/native ∈ ℕ` |
| D61 | 4906 | Re/Im rounded to 5 dp: 1 % error at `|E| = 1e-3`, 10 % at `1e-4`, destroyed at `1e-5` — sidelobes of raw-field sources corrupted | Angles only (I3) |
| D5 | 4743–4744 | Polarisation class from **unweighted** `mean(|E|²)` → pole-density bias | Ω-weighted powers |
| D24 | 4783 | PLF uses `cosd(180)` (worst-case tilt) as an undocumented magic number | `Const.PLFTiltCos = −1`, documented, shown |
| D25 | 4769–4771, 785–800 | Exactly-linear samples get AR = −100 dB → saturated "LHCP-blue"; round-off speckle between deep blue and deep red across every linear region | `NaN` → axes background (§15-6) |
| D45 | 2318–2320 | Cone membership `≥ cosd(α)` without tolerance flickers for samples on the boundary | `−1e-12`, one function for coverage and orientation |
| D18 | 1512–1531, 1767 | `tMin:step:tMax` accumulates error, `tMax` appended → near-duplicate thresholds; `interp1` errors on duplicates | `cov_thresholds` by counting; `unique` on loaded curves |
| D31 | 1703, 2593–2596 | Inverse query via `interp1(unique(cov,'last'))` → arbitrary point on plateaus, non-monotone on round-off | `cov_inverse` exact |
| D43 | 1755–1777 | Results table `interp1` on computed step-function CCDFs invents values | Exact re-evaluation from the distribution |
| D50 | 1703, 2593–2612 | Query tip placed by two independent interpolations that disagree at plateaus | One exact query point |

### 9.2 Physics and conventions

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| D36 | 4114–4149 | GRASP `.cut` `ICOMP` branched only on `== 2`; **`ICOMP = 3` (Ludwig-3 co/cx, the linear-feed default) read as raw θ/φ** → AR, RCP/LCP, PLF, E/H planes wrong; only total gain survives | `io_toThetaPhi(…, "ludwig3")` (Appendix A.7); other `ICOMP` → error |
| D37 | 4726–4727, 4083–4084, 4143–4144, 4175–4176, 4302–4303 | `E_R = (Eθ + jEφ)/√2` at five sites; under the `e^{+jωt}` convention of CST/FEKO/HFSS/GRASP/XGTD an outgoing RHCP wave is `(θ̂ − jφ̂)/√2` → derived RHCP/LHCP labels, "Circular (RHCP)" class, Auto-Rx sense and signed-AR colour may be **mirrored** for every θ/φ source (inputs already in RHC/LHC round-trip) | `pat_circular(Eth, Eph, Const.CircularSign)` everywhere; CP fixture gate; owner verification (§15-1) |
| D38 | 4166–4167 vs 4182–4190, 4216, 4733, 4635–4638, 4787–4790 | UAN/FZ carry dBi-scaled fields, Excel dBi, gain-only dB(i); CST FFS / FEKO FFE / HFSS FFD carry **raw r·E (V)**. M7 labels `10·log10(|Eθ|²+|Eφ|²)` dBi for all → efficiency, EIRP, PFD, E_RMS off by `10·log10(4π/(2η₀P))` (≈ −17.8 dB at 1 W), silently | `Meta.Calibration` per source (§6.1); `io_calibrate` from FFE columns / FFD `.txt` / FFS header / UAN header; `UnitLabel` on every label; link quantities gated (I10) |
| D55 | 4162–4167 | UAN header block ignored (`magnitude linear`, `phase radians`, non-θφ polarisation, `maximum_gain`) | UAN header parser; unsupported values → error, not guess |
| D56 | 4156–4159, 4185–4190 | FEKO `Gain(Total)`/`Directivity(Total)` columns discarded; UV coordinate files not rejected | Self-calibration from columns 7–9; `#Coordinate System` check |
| D57 | 4192–4219 | HFSS companion `.txt` (accepted/radiated power) never read | Parsed when present |
| D26 | 4682–4689, 634–642 | E-plane always the θ-cut at the principal-axis φ, H at +90° → swapped for y-/rotated-linear antennas; ill-defined for CP | Co-pol axis + great-circle planes; principal fallback |
| D63 | 4745–4757 | "Linear (Vertical/Horizontal)" from sphere-averaged `|Eθ|²` vs `|Eφ|²`: any broadside x- **or** y-polarised element is "Horizontal"; basis-dependent, not physical | Co-pol axis wording (§6.5) |
| D29 | 4886–4888 | θ ∈ [−90,90] auto-interpreted as elevation for every format inside a math function | `Meta.ThetaConvention` from the reader; `pat_normalize` applies; Metadata shows |
| D44 | 4035–4041 | Generic gain-only: θ/φ identity decided by span, undisclosed | Header names first; heuristic disclosed |
| D48 | 4059–4066 | Mag/phase layout: "phase if `max|v| > 100`" — a −110 dB null qualifies, a [−90,90] phase does not | Header names; range rule; both phase columns must agree; disclosed |
| D47 / D14 | 4132–4137 | Single `.cut` → body of revolution at **10°** φ, unflagged; 10° enters HPBW, coverage, resampling as if measured | Δθ synthesis; `Meta.SynthesizedRevolution`; shown |
| D49 | 4195–4197 | FFD closing φ column ambiguity never recorded | `PhiClosedInSource` |
| D16 | 1902 | UAN `maximum_gain` = max of E_TH/E_PH, not total gain | §15-5 |
| D46 | 569–583, 373–382 | "POB … dB" reported for the selected component (AR → most-circular sample) | Status names the component; POB = total gain (I4) |

### 9.3 Dataflow and state

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| D17 | 4711–4715 | Gain-only: loss added to **every** column from 3 on (AR, phase…) | `lossAdditive` in the registry |
| D54 | 4033–4048, 5154–5161 | Gain-only fallback column = column 3 whatever it is | `util_columnKind` |
| D39 | 2264, 293–298, 1683 | Coverage-tab pattern processed with Main-tab params frozen at load, native step; Main node re-synced live → two curves in one table with different loss/step, unlabelled | Params-free nodes; params at compute; job provenance |
| D7 | 1663 | `syncCoveragePattern` runs `resolvePeak` (65k sort) on every tree selection | Peaks cached in `Base.Peaks` |
| D9, D33, D34 | 282, 1336, 282–283/2029–2036 | Readers/getters write widgets (`dropdown.Value`, checkbox `Text`, visibility before the coverage check) | `readConfig` reads; `apply*` write (I14) |
| D28 | 345 vs 653 | Cut-value spinner `Step` set twice differently | `applyChoices` once |
| D32 | 2142 | Results export writes the `uitable` copy | Export from `Derived` |
| D20 | 835–848 → 888–899 | AR component routes `[−30 30]` through scope `"all"` → cut plots collapse to ±30 dB | AR theme touches `RangeGroups.full` only |
| D27 | 4154–4159, 4185–4190, 4913 | FEKO multi-block files concatenated; `unique(…,'first')` keeps block 1 silently | `io_ffe` block split; block dropdown |
| D2 | 507 | `[~, pi] = ismember(...)` shadows `pi` | gone with `gridComp` |
| D60 | 1590, 1596 | Threshold/X-range presets only widen | Presets per node/component under `CovRangeAuto` |
| D58 | 4009–4013 | `rmmissing` drops rows with NaN in unused columns | Drop only when θ/φ/used column is NaN |
| D30 | 704–711 | `fmtNumber` prints `-0` | `util_fmtNumber` |
| D64 | 2000–2012, 2119–2126 | Same-file reselect refused while Process re-parses anyway | One `update("source")`; reselect = reload |

### 9.4 UI, graphics, hygiene

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| D3, D51 | 1237 vs 1265; 1251–1253 vs 1317 | Polar-3D overlay radius mismatches the surface (slider vs theme limits; double normalisation) | One `util_polarRadius` |
| D4, D59 | 355 → 2846 → 1235, 357; 2833 → 2797 → 2845, 2834 | Both 3-D surfaces rendered twice on load with overlay on; cut plotted twice on gain-only component change | `update` renders once in dependency order |
| D35 | 1146, 1256–1262, 1268 | Each 3-D render creates 3 `quiver3` + 3 `text`, **two** context menus, a new colorbar | Registry, create-once (I15) |
| D52 | 1355 | Snapped cut writes a **permanent** status; `cutData` ×3 per change | One extract; transient status |
| D62 | 1438, 1458 | Cut POB/HPBW on the first *checked* trace, unlabelled | Named in the label |
| D8 | 2256 | `Cov_Button_LoadPushed` parses outside its `try` | `guard` |
| D10 | 3073 vs 248 | Window title `M7.110` vs `ReleaseName` `M7.110_5` | Title from `Const.ReleaseName` |
| D11 | 2648 | Query projection line starts at hard-coded −250 | `ax.XLim(1)` |
| D12 | 1818 | New `timer` per transient status | One timer |
| D13 | 3715 | `runSelfTest` needs a live app | Static `selfTest` |
| D15 | 785 | `plotTheme(app, ~)` ignores its argument | `util_plotTheme(component, limits)` |
| D6 | 5170–5172, 4638 | Truncated last cell / efficiency displayed on partial spheres | Separable weights; `IsFullSphere` gate |
| D65 | 1922–1929 | `assignin('base')` on every operation | Env-gated profiler, in-app storage |
| D66 | 1817 | Dead statement in `setStatus` | Gone |

---

## 10. Destination file layout and size budget

```
classdef APAT_v3_M8 < matlab.apps.AppBase
  %% A  UI component properties           generated; do not hand-rename (Cov_Tabel, Singel_CheckBox_overlayCut stay)
  %% B  Constants + schema factories       Const (PeakExcessDB=6, ConeHalfAngleDeg=45, BackConeDeg=30, PowerFloor,
  %%                                       Bounds=[-250 100], ARLimits=[-30 30], AutoRangeSpanDB=50, AngleDecimals=5,
  %%                                       UniformTolDeg=1e-6, PhaseCoherenceMin=0.5, CircularAR_dB=3,
  %%                                       PLFTiltCos=-1, CircularSign=+1|-1 (§15-1), Eta0=376.730313668,
  %%                                       PrincipalAxes, Columns (registry), Formats (descriptors), Defaults, ReleaseName)
  %%                                       newSource/newPattern/newGeometry/newBase/newDerived/newView/newMap/newGraphics/newCovDist
  %% C  State properties (private)         Source, Pattern, Geometry, Base, Derived, View, Map, Graphics, CutCache,
  %%                                       CovDists, RangeGroups, StatusTimer, OperationDialog, Busy, Pending, isClosing
  %% D  Orchestration (private)            readConfig, readCoverageConfig, update(scope), applyChoices, applyVisibility,
  %%                                       applyRanges, applyMetadata, applyTables, applyCoverageResult, guard, setStatus, shutdown
  %% E  Callbacks (private)                one-liners
  %% F  Renderers (private)                renderFull(k), renderCut, renderOverlay, renderPOB, renderCoverageJob, renderQuery
  %% G  Public API                         ctor, delete, closeRequest;  Static: selfTest, version
  %% H  createComponents                   generated layout; no ValueChangedFcn on range widgets
end

%% Local functions — app-free, alert-free, H1 one-liner, ≤ ~60 lines each
%%   io_*    io_read, io_columns, io_fieldsToComplex, io_toThetaPhi, io_ludwig3ToThetaPhi, io_calibrate, io_uanHeader,
%%           io_ffd, io_ffdSidecar, io_ffe, io_ffsHeader, io_graspCut, io_excelMatrix, io_excelSummary,
%%           io_isCoverageTable, io_findHeaderLines
%%   pat_*   pat_normalize, pat_validateUniform, pat_resample, pat_resampleField, pat_decimateAxis, pat_circular,
%%           pat_calcBase, pat_applyParams, pat_applyLink
%%   geo_*   geo_build, geo_axesKey, geo_integrate, geo_displayMap, geo_cut, geo_greatCircle, geo_unitVectors
%%   met_*   met_peak, met_copolAxis, met_orientation, met_planes, met_metrics, met_hpbw, met_plf
%%   cov_*   cov_ccdf, cov_ccdf_reference, cov_inverse, cov_coneMask, cov_thresholds
%%   util_*  util_fmtNumber, util_db, util_ticks, util_clampRange, util_displayRange, util_plotTheme, util_arColormap,
%%           util_polarRadius, util_coneLabel, util_nearest, util_columnKind
%%   fx_*    fx_isotropic, fx_dipole(axis), fx_crossedDipolesCP(sense), fx_gaussianBeam(hpbw, step), fx_hemisphere,
%%           fx_spike, fx_phaseSlope(offsetLambda)      — synthetic fixtures shared by selfTest
```

**Size budget (lines):** UI layout 690 · io 470 · pat/geo/met/cov 470 · orchestration + apply 420 · renderers 340 · callbacks 110 · schemas/constants/registry 160 · selfTest + fixtures 330 · comments/headers 160 → **≈ 3,150** (hard ceiling 3,300; −37 % vs M7).

---

## 11. Work order — one blow

Construction order, not shipped milestones. Nothing is released until §12 is green.

1. **Core first, no widgets.** Section B factories, `Const.Columns`, `Formats`, every `io_/pat_/geo_/met_/cov_/util_/fx_` local function. Prove them with the Static `selfTest` (§12 rows 1–36).
2. **Golden capture from M7** on the fixture set and on the owner's real files. The `goldenHash` row compares with the **designed deltas** listed in code: angle-only rounding, coverage detector, UAN φ ≥ 0, FFE blocks, θ-convention hint, Ludwig-3 rotation, circular sign (if `+1`), calibration gating, Δθ revolution synthesis, spike renormalisation, NaN PLF, exact table evaluation, ring-based pole peaks, power/phasor resampling, great-circle planes, polarisation wording, exact decimation.
3. **Paste `createComponents`** minus range-widget `ValueChangedFcn` (wired by the controller in `startupFcn`); title from `Const.ReleaseName`.
4. **State + orchestration**: properties, `readConfig`, `readCoverageConfig`, `update`, `applyChoices`, `applyVisibility`, `applyRanges`, `guard` (busy + deferred replay), `shutdown`, one timer, one menu, `RangeGroups`.
5. **Renderers** in retained mode with dirty keys; verify I15 (object counts constant) and lazy-render equivalence before wiring more callbacks.
6. **Retarget every callback** to the one-liner shape.
7. **Coverage**: nodes hold `PatternRef` or their own `Pattern/Geometry/Base`; distributions in `app.CovDists`; params at compute time; presets per node.
8. **Delete the M7 names in the same edit** (§12 static list). `grep` any hit → stop.
9. **Run §12.** Fix the destination; never resurrect `viewTbl`.

**What this strategy refuses:** an M7.111 "correctness patch" that keeps six tables; an interim `viewBaseTbl` clone "until display mapping is ready"; new helpers that wrap widgets; caches keyed on spinner values; toolbox calls; a stored seam column; a Re/Im resampling path; a percentile fallback; an `nθ×nφ` solid-angle matrix stored anywhere; a coverage entry point that accepts a table; an inline `sqrt(2)` circular split; a unit literal outside `Meta.UnitLabel`; a column-name literal outside `Const.Columns`.

---

## 12. Release gate — `APAT_v3_M8.selfTest()` (Static, no UI)

Returns a table `name / pass / detail`. All must pass. Fixtures come from `fx_*`.

| # | Check | Assertion |
|---|---|---|
| 1 | `peakSpatial` | Gaussian 40 dBi beam, HPBW 1.5°, on 1°/0.25°/0.1° grids → not adjusted; +10 dB single-sample spike → adjusted, `spikeCount == 1`; spike on the θ=0 pole row → adjusted, `spikeCount == nφ`; uniform pole row never flagged |
| 2 | `solidAngle` | `Σ wTheta·nφ·dPhi == 4π` to `≤ 4·eps(4π)` on 1°, 2°, 5°, 0.5° and θ = 0.5:1:179.5; hemisphere: `2π(1 − cos 90.5°)` to 1e-12 and `IsFullSphere = false`; half-plane φ 0…180 → `PhiPeriodic = false`; `all(wTheta ≥ 0)`; bit-exact with M7 `solidWeights` on uniform full spheres |
| 3 | `gridNative` | `Eth(i,j)` equals the source sample at `(Theta(i),Phi(j))` for UAN, FFD (θ-outer/φ-inner), FFS, FFE, Excel fixtures; no seam column |
| 4 | `ccdfEquivalence` | `cov_ccdf` vs `cov_ccdf_reference`: `max|Δ| < 1e-9 %` on fixtures with ties, NaNs, a cone, a hemisphere, a spike, **an empty cone**; strict `>` at a tie; `C(−Inf) = 100`, `C(+Inf) = 0` |
| 5 | `coverageInverse` | 50 random `c`: `Coverage(T − 1e-9) ≥ c` and `Coverage(T) < c` (or `T` is the minimum level); plateau → upper level; `c > 100 → NaN` |
| 6 | `coneMask` | dot-product mask ≡ angular-distance mask on 20 random cones; a sample **on** the boundary (α = k·Δθ, snapped angles) is inside |
| 7 | `normalizePrecision` | fields bit-identical through `pat_normalize`; angles snapped; θ>180 folded once; φ=360 column folded into 0 with `PhiClosedInSource` |
| 8 | `resampleDecimate` | 0.5° → 1°, 0.25° → 1°, θ 0.5°/φ 1° → 1°: bit-exact selections; 0.3° → 1° goes through interpolation and yields a **1°** grid (M7 gave 3°) |
| 9 | `resamplePower` | `fx_phaseSlope(10 λ)` at 2° → 1°: total-gain error at native samples 0, at midpoints < 0.1 dB (Re/Im path gives −6 dB); `PhaseCoherence` reported; y-dipole H-plane `E_PH_Phase` error < 1° everywhere |
| 10 | `displayInvariance` | toggling `SignedPhi`/`ElevationTheta`: `Pattern, Geometry, Base, Derived, Metrics` byte-identical; `ColIdx(1:end−1)` is a permutation |
| 11 | `metricsSemantic` | with `AR_dB` selected, `PeakGain_dB`, `FrontBack_dB`, `PeakDirectivity_dB`, `Boresight` equal those with `E_Total_dB` selected |
| 12 | `paramsSplit` | loss ±3 dB, Rx mode/AR changes: every gain grid shifts by exactly L; peak index, boresight, HPBW, F/B, directivity unchanged |
| 13 | `polarizationWeighted` | x-dipole → `"Linear (co-pol ≈ ±X)"`, y-dipole → `±Y`, z-dipole → `±Z` (+ "Vertical" alias, horizon boresight); 45°-rotated dipole → `"tilted 45°"`; `fx_crossedDipolesCP` → `"Circular (RHCP)"` |
| 14 | `planes` | x-dipole: E-plane HPBW = the analytic E-plane value (90° for Hertzian), H-plane = 360° flat (`NaN` HPBW); y-dipole swapped correctly (M7 swaps them); oblique 45° boresight beam: E/H HPBW within 0.1° of analytic (grid-snapped planes would err by > 5°) |
| 15 | `copolAxis` | `a ⊥ r̂`; linear field → `a ∥ Re(E)`; CP → `ok = false` |
| 16 | `greatCircle` | circle through +Z with tangent x̂ reproduces the φ=0/180 θ-cut bit-exactly at grid nodes; circle in the equator reproduces the θ=90 φ-cut |
| 17 | `readers` | every format fixture → canonical pack; `.cut ICOMP=3` x-dipole → `co-pol ≈ ±X`, `AR ≥ 40 dB` on axis (M7 gives ≈ 0 dB AR at φ = 45°); y-dipole fixture too; `ICOMP=7` → `APAT:UnsupportedICOMP`; UAN `magnitude linear` fixture parsed; UAN `polarization ludwig3` → error; single-cut gain CSV is a pattern, not coverage; FFE 9-column file keeps all rows; generic file with a sparse 7th column keeps all rows (D58) |
| 18 | `calibration` | FFE fixture with `Gain(Total)` → `E_Total_dB == Gain(Total)` to 1e-9, `Calibration = "gain"`; FFE `Directivity` → `"directivity"`, efficiency `NaN`; FFS with `P_acc = 1 W` and `|rE|² = 2η₀/4π` → 0 dBi; FFD with sidecar → calibrated; FFD without → `UnitLabel = "dB(V)"`, EIRP absent, directivity present |
| 19 | `circularSign` | `fx_crossedDipolesCP("RHCP")` (Eθ = 1, Eφ = −j at +Z under `e^{+jωt}`) → `E_RCP_dB − E_LCP_dB > 60 dB` with `CircularSign = +1`; `−1` reproduces M7 bit-exactly |
| 20 | `uniformAxes` | 1° passes; one 0.999° gap → `APAT:NonUniformGrid` (or `Regularized`, §15-2); `StepTheta/StepPhi` exact |
| 21 | `separableIntegral` | `geo_integrate(X)` ≡ dense `sum(X(:).*dOmega(:))` < 1e-12; F/B and cone energy identical to the dense form |
| 22 | `spikeRenormalisation` | isotropic 0 dBi + one +20 dB spike: `Efficiency_pct = 100 ± 1e-9`, `PeakDirectivity_dB = 0 ± 1e-9` |
| 23 | `plfNaN` | `AR = NaN` at 10 samples → `PLF = NaN` there, finite elsewhere; exactly-linear → −3 dB vs CP wave; cross-linear → floor |
| 24 | `lossShift` | coverage of `E_Total_dB` at L = 2.5 dB via the L=0 distribution with `T − L` equals direct computation exactly; `PLF_dB` coverage is keyed by params (not shifted) |
| 25 | `coverageParams` | foreign node + Main node from the same file, same step/loss → identical curves; changing loss after load changes both |
| 26 | `tableExact` | union-table values for computed jobs equal `cov_ccdf` at the union thresholds; loaded curve column carries `⌁` |
| 27 | `thresholds` | `cov_thresholds(−40, 10, 0.1)` has 501 unique values, last = 10 exactly |
| 28 | `displayMap` | signed-φ permutation and closing column; elevation axis; `Key` changes iff the switches change |
| 29 | `polarRadius` | surface and overlay radii from one function agree at the cut samples for three different range settings |
| 30 | `columnsRegistry` | every column produced by `pat_calcBase`/`pat_applyParams` exists in `Const.Columns`; gain-only fixture with columns `[Theta Phi AR_dB Gain_dBi]` → default component `Gain_dBi`, loss applied to `Gain_dBi` only |
| 31 | `hpbwWrap` | beam centred at φ = 359° on a φ-cut → correct HPBW across the wrap; interpolated bounds within 1e-6° of analytic |
| 32 | `exportUAN` | φ ∈ [0,360), no duplicate directions, 5 dp, header block present; `maximum_gain` per §15-5 |
| 33 | `fmtNumber` | `-0.001` compact → `"0"`, never `"-0"`; explicit precision preserved |
| 34 | `conventionsDisclosed` | Metadata rows: `θ convention`, `Axis order`, `Level calibration`, `Circular sense`, `PLF tilt`, `Planes source`, `Phase coherence`, `Synthesized revolution` (when applicable); export headers contain the same block |
| 35 | `graphicsStable` (optional, UI) | after 20× component / span / cut / range / query / tab actions the graphics object count is unchanged (I15) |
| 36 | `goldenHash` | outputs on the fixture set equal the M7 capture except the designed deltas enumerated in code |

**Static checks (part of the gate):** Code Analyzer clean; ≤ 3,300 lines; ≤ 6 public methods; the following are **absent** outside `createComponents`, `Const` and `pat_normalize`:

```
viewTbl viewBaseTbl patTbl stdTbl uanTbl physicalTheta gridCache emptyGridCache viewSolidAngle viewRevision
solidWeights gridStep coverageCCDF coverageCacheKey covThresholds coverageArtifacts coverageQueryPoint
coverageInterpolationLocation syncCoverageNodeFromView setCoverageRange syncCoverageXRange resolvePeak prctile
calcCutGeometry cutGeometry fullSliders fullMins fullMaxs HiddenOutputColumns componentMap isARComponent isGainDBColumn
findall findobj UserData reshape sub2ind sqrt(2) cosd(180) 1e12 'dBi' assignin
```

---

## 13. Performance targets and how they are measured

| Action (1° FFD, 65k samples) | M7 | M8 target | Measured by |
|---|---|---|---|
| Load + first render | 3–6 s | ≤ 1.5 s (one base, one visible surface) | `APAT_PROFILE=1`, stage table |
| Component change | 0.8–2 s | ≤ 120 ms | same |
| Loss / Rx / link change | full recompute + 5 renders | ≤ 30 ms | same |
| Span toggle | full recompute + redraw | ≤ 100 ms | same |
| Cut change | 3 extractions + `cla` | ≤ 40 ms | same |
| Coverage compute (501 T) | ~260 MB, O(N·T) | ≈ 1 MB, ≈ 5 ms; re-threshold ≈ 0.1 ms | `memory`/`tic` in selfTest |
| Tree selection | `prctile` on 65k | ≤ 5 ms | same |
| Graphics objects | grow per render | constant | gate row 35 |

---

## 14. Risks and platform baseline

| Risk | Handling |
|---|---|
| A legitimate source with a non-uniform axis | `pat_validateUniform` fails loudly or regularises once (§15-2); Metadata says so. M7 could not render such grids correctly either (`gridComp` NaN holes). |
| `Const.CircularSign` chosen wrong | One constant, one gate row, one Metadata row; flipping it is a one-line change with a full self-test. Owner verification (§15-1) precedes step 2. |
| FEKO gain columns not constant across samples (mixed requests) | Constancy check (`std < 1e-6 dB`) fails → `"field"` with disclosure; never average. |
| CST FFS header variants without power lines; HFSS without sidecar | fall back to `"field"` with disclosure; never guess a power. |
| Ludwig-3 sign / reference axis | `io_ludwig3ToThetaPhi(…, refAxis)`; two analytic fixtures in gate row 17. |
| Phase under-sampled sources (coherence → 0) | Detected and reported; resampling still produces correct power; user is told the relative phase is unreliable in n cells. |
| Spatial peak policy flags unresolved beams | Truth; raw and effective peaks both shown; I18 keeps the raw grid everywhere else. |
| Great-circle planes surprise users expecting grid cuts | §15-8: default recommended, grid-snapped display offered as an option; Metadata states which. |
| Half-step Ω overhang at non-polar domain ends | M7-compatible; `OmegaSampled` shown; §15-3 offers the domain-exact alternative. |
| MATLAB release / toolboxes | **R2023b baseline** (`uislider 'range'` already requires it); `dictionary`, `discretize`, `accumarray`, `circshift`, `jsonencode` are base MATLAB; no toolboxes. |

---

## 15. Open decisions for the owner — with recommendations

1. **Circular sense** — adopt `Const.CircularSign = +1` (IEEE, `e^{+jωt}`, `E_R = (Eθ − jEφ)/√2`), **recommended after verifying one known-sense CP pattern in M7 shows the mirrored label**; or keep `−1` (M7 behaviour) documented as the `e^{−jωt}` convention. Either way the sign becomes explicit and tested.
2. **Non-uniform axis at import** — (a) error `APAT:NonUniformGrid` naming the axis and gap (**recommended**); (b) regularise onto the modal step with `Meta.Regularized = true`.
3. **Ω at non-polar domain ends** — (a) half-step overhang clamped to the sphere (M7-compatible, **recommended**); (b) domain-exact edges so a θ 0…90 hemisphere sums to exactly 2π (breaks bit-exactness with M7 on partial spheres only).
4. **Ludwig-3 reference axis for `.cut`** — GRASP definition (x-axis co-pol reference, **recommended**) vs. FEKO's; exposed as `Meta.Ludwig3Ref`.
5. **UAN `maximum_gain`** — M7 semantics (max of E_TH/E_PH) or peak total gain (**recommended**: it is what XGTD normalises against). When the imported UAN header carries `maximum_gain`, compare and report the difference.
6. **Signed AR of exactly-linear samples** — `NaN` rendered as axes background with a legend note (**recommended**), M7's −100 dB (LHCP-blue), or a dedicated third colour.
7. **Partial-sphere efficiency / F-B** — `n/a` with a Metadata note (**recommended**) or value + "partial sphere" suffix.
8. **E/H-plane display** — great-circle planes through the peak (**recommended**, exact for any boresight), or snap to the nearest grid cut with the exact HPBW still reported from the great circle.
9. **Cut-value spinner units** — display units converted to physical in `readConfig` (**recommended**) or always physical.
10. **Coverage node provenance** — `ParamsKey`-derived text ("L = 1.5 dB, Rx Auto, 1°, gain-calibrated") in the node tooltip (**recommended**) or also in the legend label.
11. **Body-of-revolution `.cut` synthesis** — keep with the Metadata flag (**recommended**) or refuse single cuts.
12. **θ-convention for generic text** — `auto` heuristic with Metadata disclosure (**recommended**) or a required UI choice.
13. **Lazy tab rendering and lazy tables** — on (**recommended**) or eager.

---

## 16. Outcome

| Metric | M7.110_5 | M8 |
|---|---|---|
| Lines (one file) | 5,199 | ≈ 3,150 (≤ 3,300) |
| Public methods | ~90 | ≤ 6 |
| Pattern copies per refresh | 6 (+2 per coverage node) | 1 canonical + 1 params-free base + 1 element-wise derived |
| Solid-angle storage | `N` doubles × (view + every node) | `nθ` doubles + 1 scalar |
| Step / seam / weight special cases | ≥ 17 sites | 0 |
| Coverage kernel | N×T indicator, ~260 MB, O(N·T), 5 helpers | `cov_ccdf` (12 lines = the formula), O(N log N) + O(T log N), oracle-verified |
| Conventions defined implicitly | 6 | 0 — each a constant / descriptor field + Metadata row |
| Calibration sources used | 0 of 4 available | 4 (FFE columns, FFD sidecar, FFS header, UAN header) |
| `UserData` state flags | 6 | 0 |
| `findall`/`findobj` outside layout | 12 | 0 |
| Duplicate algorithms | 9 (+5 circular splits) | 0 |
| Toolbox dependencies | 1 (`prctile`) | 0 |
| Component change (1° FFD) | 0.8–2 s | ≤ 120 ms |
| Loss / Rx / link change | full recompute + 5 renders | ≤ 30 ms |
| Span toggle | full recompute + redraw | ≤ 100 ms |
| Coverage compute (65k × 501) | ~260 MB | ≈ 1 MB; re-threshold ≈ 0.1 ms; exact inverse |
| Catalogued defects | 66, silent | 0, each with a gate row |

**The drop is M8 when §12 is green and the §12 static list returns zero hits.**

---

## Appendix A — Reference kernels (MATLAB, base only)

### A.1 Coverage family

```matlab
function C = cov_ccdf_reference(G, geo, mask, T)               % literal definition — self-test oracle only, O(N·T)
dOmega = geo.wTheta .* geo.dPhi .* ones(1, size(G, 2)); v = mask & isfinite(G); g = G(v); w = dOmega(v);
C = zeros(size(T)); if isempty(g), return; end
for k = 1:numel(T), C(k) = 100 * sum(w(g > T(k))) / sum(w); end
end

function T = cov_inverse(d, c)                                 % sup{ T : Coverage(T) ≥ c }
%   Coverage is non-increasing in T; it is ≥ c for every T below the returned level g_k*, where
%   k* is the last level with S(k*) ≥ c·Ω/100.  NaN when c > 100 or the distribution is empty.
T = nan(size(c)); if isempty(d.g), return; end
for q = 1:numel(c), k = nnz(d.S >= c(q)*d.Omega/100); if k >= 1 && k <= numel(d.g), T(q) = d.g(k); end, end
end

function m = cov_coneMask(geo, thetaDeg, phiDeg, alphaDeg)     % physical unit vectors; deterministic boundary
c = [sind(thetaDeg)*cosd(phiDeg), sind(thetaDeg)*sind(phiDeg), cosd(thetaDeg)];
m = (geo.sinT*geo.cosP)*c(1) + (geo.sinT*geo.sinP)*c(2) + geo.cosT*ones(1,numel(geo.cosP))*c(3) >= cosd(alphaDeg) - 1e-12;
end

function T = cov_thresholds(tMin, tMax, step)                  % counting, not accumulation
n = round((tMax - tMin)/step); T = tMin + (0:n).'*step; if T(end) < tMax - 1e-9, T(end+1) = tMax; end
end
```

### A.2 Separable integral

```matlab
function s = geo_integrate(geo, X)              % Σ_ij X(i,j)·ΔΩ(i,j), NaN-safe
s = geo.dPhi * (geo.wTheta.' * sum(X, 2, 'omitnan'));
end
```

### A.3 Spatial peak

```matlab
function P = met_peak(G, excessDB, periodicPhi, isPole)          % isPole = [Theta(1)==0, Theta(end)==180]
nb = -inf(size(G));
nb(2:end,:)   = max(nb(2:end,:),   G(1:end-1,:));                 % θ neighbours
nb(1:end-1,:) = max(nb(1:end-1,:), G(2:end,:));
if periodicPhi, Lf = circshift(G,1,2); Rt = circshift(G,-1,2);
else, Lf = [-inf(size(G,1),1) G(:,1:end-1)]; Rt = [G(:,2:end) -inf(size(G,1),1)]; end
nb = max(nb, max(Lf, Rt));                                         % φ neighbours
if isPole(1),   nb(1,:)   = max(G(2,:),     [], 'all'); end        % pole rows: the adjacent ring is the neighbourhood
if isPole(end), nb(end,:) = max(G(end-1,:), [], 'all'); end
P.mask = isfinite(G) & (G - nb > excessDB);                        % isolated spikes
[P.rawValue, P.rawIndex] = max(G(:), [], 'omitnan');
cand = G; cand(P.mask) = -Inf; [P.value, P.index] = max(cand(:));
P.wasAdjusted = P.mask(P.rawIndex); P.spikeCount = nnz(P.mask);
end
```

### A.4 Circular split — one place

```matlab
function [Er, El] = pat_circular(Eth, Eph, s)   % s = Const.CircularSign: +1 IEEE/e^{+jωt}, −1 reproduces M7
Er = (Eth - 1i*s*Eph)/sqrt(2);  El = (Eth + 1i*s*Eph)/sqrt(2);
end
% inverse (readers):  Eth = (Er + El)/sqrt(2);  Eph = 1i*s*(Er - El)/sqrt(2);
```

Derivation: with `θ̂ × φ̂ = r̂` the triad `(θ̂, φ̂, r̂)` is right-handed like `(x̂, ŷ, ẑ)`. Under `e^{+jωt}` an IEEE right-hand wave travelling along `+ẑ` is `(x̂ − jŷ)/√2` (Balanis, *Antenna Theory*, §2.12: the field rotates clockwise when viewed with the wave receding). Substituting `θ̂, φ̂` gives `E_R = (Eθ − jEφ)/√2`. Under `e^{−jωt}` the sign of `j` flips and M7's `(Eθ + jEφ)/√2` is right-hand.

### A.5 Co-pol axis (polarisation-ellipse major axis) — fields only

```matlab
function [a, tauDeg, ok] = met_copolAxis(Eth, Eph, thetaDeg, phiDeg, arDB)
%MET_COPOLAXIS Real unit vector along the major axis of the polarisation ellipse at one direction.
%   E = Eθ·θ̂ + Eφ·φ̂ (complex 3-vector);  χ = ½·arg(E·E) = ½·arg(Eθ² + Eφ²)  (unconjugated dot product);
%   a = Re(E·e^{−jχ}) / ‖·‖  is the major axis (Born & Wolf §1.4). Undefined for circular states (E·E → 0).
th = [cosd(thetaDeg)*cosd(phiDeg), cosd(thetaDeg)*sind(phiDeg), -sind(thetaDeg)];
ph = [-sind(phiDeg), cosd(phiDeg), 0];
chi = 0.5*angle(Eth^2 + Eph^2);
aT  = real(Eth*exp(-1i*chi)); aP = real(Eph*exp(-1i*chi));
a   = aT*th + aP*ph;  n = norm(a);
ok  = isfinite(arDB) && abs(arDB) >= Const.CircularAR_dB && n > 0;
a   = a / max(n, realmin);
tauDeg = atan2d(aP, aT);                         % tilt of the co-pol axis from θ̂ toward φ̂
end
```

Check: exactly-linear `E = e^{jα}·(real vector)` ⇒ `E·E = e^{2jα}|E|²` ⇒ `χ = α` ⇒ `a ∥ Re(E e^{−jα})` ✓. CP `Eθ = 1, Eφ = ±j` ⇒ `E·E = 0` ⇒ undefined ✓ (`ok = false`, principal-axis fallback).

### A.6 PLF, NaN-safe

```matlab
function plf = met_plf(AR_dB, rxMode, rxAR_dB, pairs, tiltCos)
ok = isfinite(AR_dB); plf = nan(size(AR_dB));
ra = 10.^(abs(AR_dB(ok))/20) .* sign(AR_dB(ok));                       % signed axial ratio (sense in the sign)
rw = 10.^(rxAR_dB/20) * (2*(rxMode=="RHCP" | (rxMode=="Auto" & pairs.Circular(1)=="E_RCP")) - 1);
p  = 0.5 + (4*ra*rw + (ra.^2-1)*(rw^2-1)*tiltCos) ./ (2*(ra.^2+1)*(rw^2+1));
plf(ok) = 10*log10(min(max(p, eps), 1));
% exactly-linear samples (AR_dB = NaN by policy, |E_R| == |E_L|): ra → ∞ ⇒ p = 0.5 + (rw²−1)·tiltCos/(2(rw²+1))
lin = isnan(AR_dB) & isfinite(rw); plf(lin) = 10*log10(min(max(0.5 + (rw^2-1)*tiltCos/(2*(rw^2+1)), eps), 1));
end
```

### A.7 Ludwig-3 → θ/φ (GRASP `ICOMP = 3`)

```matlab
function [Eth, Eph] = io_ludwig3ToThetaPhi(Eco, Ecx, phiDeg, refAxis)   % refAxis "x" (GRASP default) | "y"
c = cosd(phiDeg); s = sind(phiDeg); if refAxis == "y", [c, s] = deal(s, -c); end
Eth =  Eco.*c + Ecx.*s;          % E_co = Eθ cosφ − Eφ sinφ,  E_cx = Eθ sinφ + Eφ cosφ   (x-reference)
Eph = -Eco.*s + Ecx.*c;
end
```

### A.8 Calibration

```matlab
function [Eth, Eph, meta] = io_calibrate(Eth, Eph, meta, src)           % src: struct with one of Pacc_W | GainTotal_dB | none
switch true
    case isfield(src,'GainTotal_dB')                                     % FEKO columns (gain or directivity)
        k2 = 10.^(src.GainTotal_dB/10) ./ max(abs(Eth).^2 + abs(Eph).^2, realmin);
        assert(std(10*log10(k2(isfinite(k2))), 'omitnan') < 1e-6, 'APAT:Calibration', 'gain columns inconsistent');
        k = sqrt(median(k2(:), 'omitnan')); meta.Calibration = src.Kind;   % "gain" | "directivity"
    case isfield(src,'Pacc_W') && isfinite(src.Pacc_W) && src.Pacc_W > 0 % CST header / HFSS sidecar
        k = sqrt(4*pi / (2*Const.Eta0*src.Pacc_W)); meta.Calibration = "gain"; meta.RefPower_W = src.Pacc_W;
    otherwise
        meta.Calibration = "field"; meta.UnitLabel = "dB(V)"; return
end
Eth = Eth*k; Eph = Eph*k; meta.UnitLabel = "dBi"; meta.CalibrationSource = src.Source;
end
```

### A.9 Great-circle cut

```matlab
function C = geo_greatCircle(P, grids, rhat, that, cols)
%GEO_GREATCIRCLE Sample dB grids along the great circle through r̂ with initial tangent t̂ (t̂ ⊥ r̂).
%   d(α) = cos α·r̂ + sin α·t̂,  α = 0:Δθ:360−Δθ.  Values by bilinear interpolation of the derived dB grid
%   (φ-periodic closure).  A 1-D display/measurement sampling — never written back into Pattern.
alpha = (0:P.StepTheta:360-P.StepTheta).';
d  = cosd(alpha)*rhat(:).' + sind(alpha)*that(:).';
th = acosd(max(min(d(:,3), 1), -1));  ph = mod(atan2d(d(:,2), d(:,1)), 360);
[PG, TG] = meshgrid([P.Phi, P.Phi(1)+360], P.Theta);
C.angle = alpha; C.theta = th; C.phi = ph; C.kind = "greatcircle";
for c = cols, X = grids.(c); C.data.(c) = interp2(PG, TG, [X, X(:,1)], ph, th, 'linear'); end
end
```

### A.10 Number formatting

```matlab
function s = util_fmtNumber(v, prec)                     % compact (≤ 2 dp, no trailing zeros, never "-0") or fixed
if ~(isscalar(v) && isnumeric(v) && isfinite(v)), s = 'n/a'; return; end
if nargin < 2 || isempty(prec), s = regexprep(sprintf('%.2f', v), {'0+$', '\.$', '^-0$'}, {'', '', '0'});
else, s = sprintf('%.*f', max(0, min(5, round(prec))), v); end
end
```

---

## Appendix B — Derivations

**B.1 CCDF evaluation identity.** Let `R` be the region, `A = {(i,j) ∈ R : G(i,j) finite}`, and `g₁ < … < g_n` the distinct values of `G` on `A`. Define `ω_k = Σ_{(i,j)∈A, G(i,j)=g_k} ΔΩ(i,j)`. Then for any `T`,

```
Ω{G > T} = Σ_{(i,j)∈A, G(i,j)>T} ΔΩ(i,j)
         = Σ_{k : g_k > T}  Σ_{(i,j)∈A, G(i,j)=g_k} ΔΩ(i,j)        (partition A by level)
         = Σ_{k : g_k > T} ω_k
         = Σ_{k ≥ k_T} ω_k = S(k_T),   k_T = min{k : g_k > T}   (levels sorted; empty set ⇒ k_T = n+1, S = 0)
```

`discretize(T, [-Inf; g; Inf])` returns `b` with `edge(b) ≤ T < edge(b+1)`, i.e. `g_{b−1} ≤ T < g_b`, hence `b = k_T`. Ties are exact because equal gains share one level; strictness is exact because `g_{k_T} > T` by construction. `Ω_R = S(1)`.

**B.2 Separable weights and the full-sphere sum.** With `θᵢ⁻ = max(θᵢ − Δθ/2, 0)`, `θᵢ⁺ = min(θᵢ + Δθ/2, 180°)` and a uniform axis, `θᵢ⁺ = θᵢ₊₁⁻` for all interior `i`, so `Σᵢ (cos θᵢ⁻ − cos θᵢ⁺) = cos θ₁⁻ − cos θₙ⁺`. If `θ₁ ≤ Δθ/2` and `θₙ ≥ 180° − Δθ/2` the clamps give `cos 0 − cos 180° = 2`. With `nφ·Δφ = 2π`, `Σ ΔΩ = 4π` — exact up to the rounding of `cosd` at the clamped edges.

**B.3 Loss shift.** For a column `X = X₀ + L` (L scalar), `Ω{X > T} = Ω{X₀ > T − L}`; hence the L = 0 distribution serves every loss value for `lossAdditive` columns. Not valid for `AR_dB` (L-independent), `PLF_dB` (Rx-dependent) or `Gain_PolCorrected_dB = E_Total + PLF` when Rx settings change — which is why `ParamsKey-part` is in the key for those.

**B.4 Why power + unit-phasor interpolation is safe.** Let two adjacent samples be `E₁ = A e^{jψ₁}`, `E₂ = A e^{jψ₂}`, `Δ = ψ₂ − ψ₁`. Linear Re/Im interpolation gives midpoint magnitude `A·|cos(Δ/2)|` — −6 dB at `Δ = 120°`, 0 at `Δ = 180°`. Power interpolation gives `A²` exactly. The unit phasor midpoint is `(e^{jψ₁} + e^{jψ₂})/2 = e^{j(ψ₁+ψ₂)/2}·cos(Δ/2)`: its **angle** is the circular mean `(ψ₁+ψ₂)/2` for every `|Δ| < 180°` (correct to first order for a linear phase slope), and its **modulus** `cos(Δ/2)` is the phase-coherence diagnostic — 1 when the phase is well sampled, 0 when it is not. Where `|E| → 0` the phasor is arbitrary but multiplies `√P → 0`, so no reference component is needed. Relative phase between θ̂ and φ̂ components is the difference of two circular means, with error bounded by the cell.

**B.5 Polarisation-ellipse major axis.** For a complex field vector `E`, write `E = (a + jb)e^{jχ}` with real `a ⊥ b` (the semi-axes). Then `E·E = (|a|² − |b|²) e^{2jχ}` (the cross term vanishes because `a·b = 0`), so `χ = ½·arg(E·E)` and `a = Re(E e^{−jχ})` — the major axis when `|a| ≥ |b|`. For a circular state `|a| = |b|` and `E·E = 0`: the axis is undefined, as it must be.