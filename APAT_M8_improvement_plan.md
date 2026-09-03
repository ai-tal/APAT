# APAT M8 — Single-Blow Refactor Plan (revision 2)

**From:** `APAT_v3_M7_110_5.m` — 5,200 lines, one App Designer class, ~95 methods (≈90 of them `Access = public`), 34 file-scope functions.
**To:** `APAT_v3_M8.m` — the **same one file**, rebuilt around one dataflow.
**Supersedes:** `APAT_improvement_plan.md` (draft 1). Everything in draft 1 that survived a line-by-line audit of M7 is kept; what was wrong is corrected in §0; what was missing is added.

This is still **one drop**. Do not patch M7. Build the destination, point the UI at it, delete every M7 name the destination replaces.

---

## 0. What changed since draft 1 (audit results)

The whole M7 file was read, not sampled. Three classes of change:

### 0.1 Draft claims that were wrong or imprecise

| Draft 1 said | M7 actually | Consequence for M8 |
|---|---|---|
| "`createComponents` (~1,800 lines) stays" | `createComponents` + 3 layout helpers = **~690 lines** (3015–3697). Methods = ~2,760 lines, local functions = ~1,320 | Size target can be tighter: **≤ 3,000 lines** (−42 %), not 3,400 |
| "`calcPattern` runs twice" | Twice **only when resampling** (315, then 432). But when it does, the first full-grid `calcPattern` is 100 % wasted | M8: `pat_calc` runs once, **after** resample — draft rule stands, reason corrected |
| "`cutData` runs twice with overlay on" | **Three times**: `plotCut` (1396) + once **per 3-D axis** in `overlayCut3D` (1311 ×2). Each may fire `setStatus` → a new `timer` | One cut extract per `update("cut")`, shared by 2-D cuts and both overlays |
| "`dictionary` may be missing → `containers.Map` fallback" | M7 already uses `uislider(...,'range')` (3059) → **R2023b minimum**; `dictionary` (R2022b) is guaranteed | Drop the fallback. Baseline = R2023b (see §13) |
| "Elevation θ only poisons orientation/metrics" | Also: with **any non-Total component selected**, `calcMetrics` receives the *component's* peak (index+value) and combines it with **total gain** → `PeakGain_dB`, `FrontBack_dB`, `PeakDirectivity_dB` are wrong (e.g. AR peak − total back-lobe). Boresight is detected on AR_dB, which has no energy meaning | New invariant §3: **metrics & orientation are defined on total gain only**; component selection affects plots and the POB marker |
| "~25 MB N×T indicator" | `regionWeight.' * indicator` (4597) promotes the logical N×T to **double** before the product: 65k × 501 ≈ **260 MB** transient | Sorted distribution is mandatory, not a nicety |

### 0.2 Defects found that draft 1 did not list

| # | Where (M7 line) | Defect | M8 mechanism |
|---|---|---|---|
| D1 | 5113 | `prctile` → **Statistics & ML Toolbox dependency** for the peak policy | `met_resolvePeak` uses a sort-based quantile (`sorted(ceil(p·n))`, toolbox-free) |
| D2 | 507 | `[~, pi] = ismember(...)` **shadows `pi`** inside `gridComp` | Gone with `gridComp` (grid-major layout, §5.2) |
| D3 | 1237 vs 1265 | Overlay cut in polar-3D scaled with the **slider value** on re-overlay but with **theme limits** on full render → radius mismatch for AR | One `View.limits` used by surface and overlay |
| D4 | 355 → 2846 → 1235, then 357 | On load with overlay checked, `Single_Switch_EHplaneValueChanged` renders both 3-D surfaces **before** `renderAllFullPatterns` renders them again | `update("source")` renders once, in dependency order |
| D5 | 4743–4744 | Polarization classification uses **unweighted** `mean(|E|²)` → sample-density bias toward the poles | `pat_calc` receives `Geometry.dOmega`; classification is Ω-weighted |
| D6 | 5170–5172, 4638 | `solidWeights` assumes a **uniform** θ step; partial spheres (hemispheric FFD) get a truncated last cell and a **wrong efficiency** that is still displayed | `geo_build` uses cell-edge (midpoint) dΩ — exact for uniform and non-uniform axes; `Geometry.isFullSphere` gates efficiency |
| D7 | 1663 | `syncCoveragePattern` runs `resolvePeak` (P99.99 on 65k samples) on **every tree selection change** | Peak per `(revision, component)` cached in `Derived.Peaks` |
| D8 | 2256 | `Cov_Button_LoadPushed` calls `prepareTextFormat` **outside** its `try` | One `guard()` per callback (§6.2) |
| D9 | 282 | `prepareTextFormat` (a reader path) **writes** `dropdown.Value` | Readers are pure; `apply` writes widgets |
| D10 | 3073 vs 248 | Window title says `M7.110`, `ReleaseName` says `M7.110_5` | Title built from `ReleaseName` |
| D11 | 2648 | Query projection line starts at hard-coded `-250` | `ax.XLim(1)` |
| D12 | 1818 | A **new `timer` object per transient status** message | One reusable timer created in `startupFcn` |
| D13 | 3715 | `runSelfTest` needs a **live app** (constructs the whole UI) | `selfTest` is a **Static** method exercising local functions only |
| D14 | 4132–4137 | Single-cut `.cut` is silently expanded into a body of revolution at 10° φ | Keep, but record `Meta.synthesizedRevolution = true` and show it in Metadata |
| D15 | 785 | `plotTheme(app, ~)` ignores its second argument; callers pass slider values | `util_plotTheme(component, gainLim)` |
| D16 | 1902 | UAN `maximum_gain` = max of E_TH_dB / E_PH_dB, not total gain | Open decision §14 |

### 0.3 Structural ideas added (the "ingenious" part)

1. **Pattern is always a regular grid in grid-major order** (θ fastest, φ slowest, φ=360 seam as last column). Every derived grid is `reshape(M(:,c), nTheta, nPhi)` — no `unique`, `ismember`, `sub2ind`, `LinIdx`, or grid cache at all. Cuts are **row/column slices**. Irregular sources are resampled once at import (M7 could not render them anyway — `gridComp` produced NaN holes).
2. **Geometry before Derived.** `geo_build` depends only on the angular axes, so `pat_calc` can consume `dOmega` (fixes D5) and metrics never recompute weights.
3. **Coverage = sorted weighted distribution + unique-gain aggregation.** `unique` + `accumarray` collapses ties, which makes strict `>` exact by construction and makes evaluation `discretize`-based, O(T log N).
4. **Display convention = axis map + column permutation**, never data. Draft 1 said "remap XData"; that is insufficient for signed φ because `pcolor/surf` need monotonic X — M8 permutes columns (`View.colPerm`) and re-labels.
5. **Readers are a descriptor table**, not a 240-line `switch`. Five formats (UAN/FZ/OUT/FFS/FFE + 6 generic text variants) share one column-mapping kernel; only FFD, CUT and XLSX keep bespoke parsers.
6. **One `guard`, one `update(scope)`, one `applyVisibility`, one range controller, one status timer, one context menu, one graphics registry.**

---

## 1. Why M8 is a different program, not a faster M7

M7 is feature-complete and numerically serious. It is long and slow because **the same physical pattern is re-interpreted in every consumer** and **UI callbacks own algorithms**:

- six table copies of one sphere (`rawTbl → stdTbl → patTbl → viewBaseTbl → viewTbl → uanTbl`, plus `pattern` + `sourceTable` on every coverage node)
- display conventions (elevation θ, signed φ) stored as **data**, then undone by `physicalTheta` at **8 sites** (480, 578, 676, 1359, 1505, 1683, 2155, 2317)
- `gridStep`/`unique` on the angle columns at ≥ 7 sites; `solidWeights` at ≥ 6 sites
- duplicate algorithms: `cutGeometry` ≡ `calcCutGeometry`; `gainDisplayRange` ≡ `coverageDisplayRange`; RHCP→θφ ×4 (4083, 4143, 4175, 4309); mag/phase→complex ×3 (4069, 4166, 4301); two range controllers
- state hidden in six widget `UserData` slots + a 9-field `coverageRangeState`
- `cla` + `surf` + `findall` + **two new `uicontextmenu`** per 3-D render (1146, 1268); 65k×17 uitable push on every component change (2208)

Adding caches on top (`viewRevision`, `gridCache`, `coverageCacheKey`) did not shorten the program: each is a **local** fix for a **global** dataflow mistake.

> **One physical pattern (grid-major). One geometry. One derived matrix. One config snapshot. One graphics registry.**
> Math never sees the app. UI never rebuilds math. Display is a mapping, not a copy.

---

## 2. One rule

```matlab
cfg    = app.readConfig();                       % ONLY place widget .Value is read
result = <pure local function>(data, cfg)        % app-free, alert-free, widget-free
app.apply(result)                                % ONLY place handles / labels are written
```

A callback coordinates; it does not contain the algorithm. Every callback body is:

```matlab
function onSomething(app, ~)
    app.guard("Title", @() app.update("scope"));
end
```

---

## 3. Invariants (the drop is invalid if any of these move)

| # | Invariant |
|---|---|
| I1 | Peak policy: **P99.99 + 6 dB**, toolbox-free quantile, applied to a value vector only |
| I2 | Interpolate **primitive fields only** (Re/Im Eθ, Eφ, or linear power for gain-only). Never AR / PLF / dB. `pat_calc` runs **after** resample, exactly once per `(Pattern.Revision, ParamHash)` |
| I3 | Canonical sphere: polar θ ∈ [0,180], φ ∈ [0,360], φ=360 seam present as the **last column**, dΩ = 0 on the seam, **grid-major order**. Snap **angles only** to 5 decimals |
| I4 | **Metrics, orientation, and coverage boresight are defined on total gain** (`E_Total_dB`, or the single gain-only column). Component selection changes plots, tables, and the POB marker — never the physics summary |
| I5 | Coverage: `Coverage(T) = 100·Ω(G > T)/Ω_region`, strict `>`, ties exact. Cones and orientation use **physical** angles and unit vectors |
| I6 | Query unit formatting stays on the query controls (`%g dB` / `%g%%`); datatips show the exact query value |
| I7 | Readers produce the same canonical pack as M7 **except** where M7 was wrong (angle-only rounding, coverage-file detector, UAN φ ≥ 0, Ω-weighted polarization) |
| I8 | Display invariance: toggling elevation θ / signed φ changes **zero** numbers in Derived, Metrics, or Coverage |
| I9 | One `.m` file. Structs + prefixed local functions. No packages, no toolboxes beyond base MATLAB |
| I10 | Zero graphics-object growth across repeated component / cut / span / query actions |

---

## 4. Architecture — M7 vs M8

### 4.1 M7 dataflow (today): copy, reinterpret, search

```
FILE
 └─ readPattern  →  rawTbl + blocks{} + freqs + userData
      └─ normalizePattern  →  stdTbl          (rounds Re/Im too; folds θ twice)
           └─ refresh
                ├─ calcPattern(stdTbl)            → patTbl          ① (wasted if resampling)
                ├─ applyStep
                │    └─ resample? calcPattern     → viewBaseTbl     ② again
                └─ applyAngularSpan
                     └─ COPY 17 columns, mutate θ/φ, sortrows → viewTbl
                          ├─ detectOrientation(viewTbl, comp)  ③ on display θ, on AR
                          ├─ calcMetrics(peak of comp, total gain) ④ mixed semantics
                          ├─ 5× cla + surf + 2 uicontextmenu + findall
                          ├─ uitable ← viewTbl (65k×17, even if hidden)
                          ├─ E/H toggle → cutData ×3 → 3-D drawn early, then again
                          └─ Coverage clones viewTbl twice into NodeData
                               └─ Compute: sync again, rebuild cone trig,
                                  N×T indicator (→ double, ~260 MB), cache key = thresholds
```

### 4.2 M8 dataflow (destination): derive once, project cheaply

```
FILE
 └─ io_read(path, format)
      │  Source.Raw          long table (Input tab only)
      │  Source.Blocks       nθ·nφ × 4 × F primitives  (or × 1 for gain-only)
      │  Source.Axes         θ, φ axis vectors (as read)      Source.Freqs, Source.Meta
      ▼
 pat_normalize  ──►  Pattern { Theta[nθ], Phi[nφ] (incl. 360), E[N×4|N×1], Revision,
      │                        StepTheta, StepPhi, IsGainOnly, FreqIndex }
      │                 fold once, wrap φ, close seam, snap angles, GRID-MAJOR, regular by construction
      ▼
 pat_resample (only if step ≠ 1° and 1° requested; decimate if exact)   → Pattern.Revision++
      │
 geo_build(Pattern) ──► Geometry { UnitVectors[N×3], dOmega[N] (edge-based, seam=0),
      │                            ThetaGrid, PhiGrid, IsFullSphere, Revision }
      ▼
 pat_calc(Pattern, Geometry.dOmega, params) ──► Derived { M[N×C], Cols (dictionary),
      │                                                  Peaks (per column, lazy),
      │                                                  Pol, Pairs, ParamHash, Revision }
      │                                                  EIRP/PFD/E_RMS lazy
      ▼
 View = readConfig()      component, cut, span, limits, freqIndex, masks — NEVER copies Pattern
 DisplayMap(Geometry, View) { thetaAxis', phiAxis', colPerm, thetaDir, labels }

        ┌────────────┬────────────┬────────────┬────────────┐
        ▼            ▼            ▼            ▼            ▼
     PLOTS        METRICS      CUTS        COVERAGE      EXPORT
   Graphics.*     met_*        row/col     cov_dist      on click
   CData/perm   total gain     slices      unique+accum  from Pattern
```

**Dependency graph (keep this as the comment block above `update`):**

```
RAW ──► PATTERN (Revision) ──► GEOMETRY ──► DERIVED.M (Revision, ParamHash)
                                  │              │
                    ┌─────────────┼──────────────┼──────────────┐
                    ▼             ▼              ▼              ▼
                 METRICS        CUTS           PLOTS         COVERAGE DIST
               (total gain)  (row/col)      (CData, perm)  (component, cone)
                                                               │
                                                        ┌──────┴──────┐
                                                        ▼             ▼
                                                    CURVE(T)      QUERY
VIEW ──► DISPLAYMAP ──► axis labels / colPerm / ticks   (touches nothing above)
```

If a function needs something not on a path from its inputs, it is reaching into the app. That line does not belong in M8.

### 4.3 Layer contracts (who may write what)

| Layer | Object | Writer | Readers | Forbidden |
|---|---|---|---|---|
| Source | `app.Source` | `io_read` via load / format / Process | `update("source")` | math, renderers |
| Pattern | `app.Pattern` | `pat_normalize`, `pat_resample`, `pat_selectFreq` | all below | widget `.Value`, `cla`, display conventions |
| Geometry | `app.Geometry` | `geo_build` on revision miss | pat_calc, plots, metrics, cuts, coverage | copying Pattern |
| Derived | `app.Derived` | `pat_calc` on (revision, ParamHash) miss | plots, metrics, tables, export, coverage | interpolating dB columns |
| View | `app.View` | `readConfig()` only | orchestration, renderers | math kernels |
| DisplayMap | `app.Map` | `geo_displayMap(Geometry, View)` | renderers only | anything numeric |
| CoverageCfg | `readCoverageConfig()` | callbacks | `cov_*` | widget mutation |
| Node | `Cov_Tree` NodeData | coverage `apply*` | tree mirror, job plots | pattern tables |
| Graphics | `app.Graphics` | renderers only | renderers only | `findall`/`findobj`/Tag search |

**Validity is one comparison:** `cache.Revision == Pattern.Revision` (plus `ParamHash` for Derived, `distKey` for a coverage distribution). No flag families.

Generated UI names stay (`Singel_CheckBox_overlayCut`, `Cov_Tabel`). `readConfig` aliases them.

### 4.4 Why this is shorter

| Concept | M7 (many implementations) | M8 (one) | What vanishes |
|---|---|---|---|
| Physical angles | `viewTbl` + `physicalTheta` ×8 | Pattern is polar; `Map` is labels + `colPerm` | `applyAngularSpan`, `physicalTheta`, display-θ bugs |
| Grid access | `gridComp` (cache, `ismember`, `sub2ind`, shadowed `pi`) + `gridGeom` | `reshape(M(:,c), nθ, nφ)` | both caches, `emptyGridCache`, `invalidateDerived` |
| Pattern identity | 6 tables + 2 per node | `Pattern` + `Derived.M` | five table properties and every assignment |
| Refresh | `refresh` → `applyStep` → `applyAngularSpan` → `updateViewResults` → `renderAll…` | `update(scope)` | five bodies (~500 lines) |
| Cut geometry | app method + file-scope twin + `find(abs(..)<1e-9)` | `geo_cut(Pattern, type, value)` → row/col indices | one copy, status side-effect, three-fold extraction |
| Ω / grid steps | `solidWeights` ×6, `gridStep` ×7 | `geo_build` | repeated scans |
| Coverage | monolith callback + N×T + `makeValidName` keys | `cov_dist` + `cov_curve` + `cov_query` | `syncCoverageNodeFromView`, `coverageCacheKey`, `coverageArtifacts` |
| Readers | 240-line `switch` with inline conversions | descriptor table + `io_fieldsToComplex` | RHCP→θφ ×4, mag/phase ×3 |
| Range UI | two controllers + startup arrays + orphaned generated callbacks | `RangeGroup` descriptors + one fn | `setCoverageRange` ∩ `syncCoverageXRange` |
| State | 6× `UserData` + `coverageRangeState` | `View` + `CovView` | flag plumbing |
| Graphics | 10× `findall`, 2× `findobj`, 2 menus/render, 3 quivers/render | registry | search helpers, leak paths |
| Errors | 12 `try/catch` shapes | `guard()` | boilerplate |
| Lifecycle | `delete` + `closeRequestImpl` + 3 timer methods | `shutdown()` + one timer | duplication |

**Target:** ≤ 3,000 lines (−42 %), ≤ 6 public methods (ctor, `delete`, `closeRequest`, `selfTest` (Static), `Version` (Static)), 0 duplicate algorithms, 0 toolbox calls.

---

## 5. Data model & pipelines

### 5.1 Schemas (factory functions in section B of the file)

```matlab
Source   = struct('Raw',table(),'Blocks',[],'Theta',[],'Phi',[],'Freqs',NaN,'Meta',struct(), ...
                  'Path','', 'Name','', 'Format','')
Pattern  = struct('Theta',[],'Phi',[],'E',[],'IsGainOnly',false,'FreqIndex',1, ...
                  'StepTheta',NaN,'StepPhi',NaN,'Revision',uint64(0),'Meta',struct())
Geometry = struct('UnitVectors',[],'dOmega',[],'ThetaGrid',[],'PhiGrid',[], ...
                  'IsFullSphere',false,'Revision',uint64(0))
Derived  = struct('M',[],'Cols',dictionary(string.empty,double.empty),'Labels',dictionary(...), ...
                  'Peaks',dictionary(string.empty,cell.empty),'Pol','n/a','Pairs',struct(), ...
                  'ParamHash',"", 'Revision',uint64(0))
View     = struct('Component',"E_Total_dB",'CutType',"Theta",'CutValue',0,'CutBasis',"Circular", ...
                  'CutCols',string.empty,'ElevationTheta',false,'SignedPhi',false, ...
                  'GainLim',[-40 10],'CutLim',[-40 10],'ColorStep',5,'OneDegree',false, ...
                  'FreqIndex',1,'ResultMask',logical.empty,'ShowPOB',true,'ShowHPBW',false, ...
                  'ShowHPBWBounds',false,'Overlay',false,'View3D',"iso")
Map      = struct('ThetaAxis',[],'PhiAxis',[],'ColPerm',[],'ThetaDir','reverse', ...
                  'ThetaLabel',"Theta",'PhiLim',[0 360],'ThetaLim',[0 180])
Graphics = struct('Full',struct('Axes',{},'Surface',{},'Colorbar',{},'POB',{},'Overlay',{},'Triad',{}), ...
                  'Cut',struct('Polar',gobjects(0),'Rect',gobjects(0),'HPBW',gobjects(0),'Tips',gobjects(0)), ...
                  'Cov',dictionary(double.empty,cell.empty),'Menu',gobjects(0))
```

`Cols` maps `"E_Total_dB" → column index`; `Peaks` caches `met_resolvePeak` results per column (fixes D7).

### 5.2 Canonicalize — `pat_normalize(Source, freqIndex)`

```
Source block  →  Pattern (regular, grid-major, seam-closed)
```

1. One θ fold: if `any(θ<0)` and range ⊂ [−90, 90] → θ = 90−θ (elevation source); else θ<0 → (−θ, φ+180). Then θ>180 → (360−θ, φ+180). **Once.**
2. `φ = mod(φ,360)`; snap θ, φ to 5 decimals (**angles only** — D: M7 4904 rounds fields).
3. Dedupe directions (`unique([φ θ],'rows','first')`).
4. Regularity test: `nθ·nφ == N`. If false → `pat_resample` to the native step (min positive spacing) with `scatteredInterpolant` **once**, `F.Values = column` per primitive. Record `Meta.regularized = true`.
5. Order rows grid-major: `sortrows([φ θ])` so `E` reshapes to `[nθ, nφ]` with θ down the rows.
6. Append the seam column: copy of φ=0 column with φ=360.

Result: `Pattern.E(:,k)` reshaped is the k-th primitive on the `[nθ, nφ]` grid. No index map anywhere.

### 5.3 Resample — `pat_resample(Pattern, stepDeg)`

- If both native steps are exact multiples of `stepDeg` → **decimate** (index rows/cols), bit-exact (keeps M7's `applyStep` fast path 421–424).
- Else regular `interp2` per primitive column with the periodic φ seam already present (no column append needed — I3 guarantees the seam).
- Gain-only: linear power in, dB out.
- `Revision++`. FFD blocks share the same axes, so resampling is done once per **block** lazily on frequency switch, cached per `(FreqIndex, step)`.

### 5.4 Geometry — `geo_build(Pattern)`

```matlab
th = Pattern.Theta(:); ph = Pattern.Phi(:);               % axes, ph(end) == 360
eTh = [0; (th(1:end-1)+th(2:end))/2; 180];                 % θ cell edges (clamped)
dPh = diff([ph(1); (ph(1:end-1)+ph(2:end))/2; ph(end)]);   % φ cell widths
dPh(end) = 0;                                              % seam column carries no area
dO  = (cosd(eTh(1:end-1)) - cosd(eTh(2:end))) * deg2rad(dPh(:)).';   % [nθ × nφ]
G.dOmega = dO(:);  G.IsFullSphere = abs(sum(G.dOmega) - 4*pi) < 1e-9;
[G.PhiGrid, G.ThetaGrid] = meshgrid(ph, th);
G.UnitVectors = [sind(G.ThetaGrid(:)).*cosd(G.PhiGrid(:)), sind(G.ThetaGrid(:)).*sind(G.PhiGrid(:)), cosd(G.ThetaGrid(:))];
```

Edge-based cells are exact for uniform grids (identical to M7 on every M7 fixture) and correct for non-uniform axes and partial spheres (fixes D6). `IsFullSphere` gates efficiency and labels partial-sphere Ω in Metadata.

### 5.5 Derive — `pat_calc(Pattern, dOmega, params)`

Same physics as M7 4703–4810, with:
- Ω-weighted polarization classification (`sum(|E|².*dΩ)`), fixes D5.
- Output as `M[N×C]` + `Cols` dictionary; `EIRP/PFD/E_RMS` columns filled by `pat_calcLink(Derived, params)` only when the Results mask or export asks.
- One floor constant `Const.PowerFloor = eps` used everywhere (M7 mixes `eps` and −100 dB).
- `Peaks` dictionary populated lazily by `met_peak(Derived, col)`.

### 5.6 Metrics — `met_*`

- `met_orientation(gainTotal, Geometry, peak)`: cone energy on `UnitVectors * AxisVectors.' ≥ cosd(45)`. Always total gain (I4).
- `met_metrics(Derived, Geometry, boresightIndex)`: peak (total), HPBW E/H via `geo_cut` row/col slices, F/B via `UnitVectors * peakVector` minimum, directivity, efficiency (only if `IsFullSphere`), AR at peak.
- `met_resolvePeak(values, pct, excessDB)`: toolbox-free quantile.
- `met_hpbw(angleDeg, gainDB)`: M7 4860–4880 unchanged.

### 5.7 Cuts — `geo_cut(Pattern, type, value)`

Grid-major means:
- **Phi cut** (fixed θ): row `i = nearest(Theta, value)` → `angle = Phi`, samples `M(i + nθ·(0:nφ−1), cols)`.
- **Theta cut** (fixed φ): columns `j` (nearest φ) and `j2` (nearest φ+180) → `angle = [Theta; 360−Theta(end−1:−1:1)]`, samples `[M(rows_j); M(rows_j2 reversed, minus pole)]`.
Returns `struct(angle, rows, fixedAngle, symbol, snapped)`. Pure. Display mapping (signed angles, seam duplication) is applied in the renderer via `Map`.

### 5.8 Coverage — `cov_*`

```matlab
function d = cov_dist(gain, dOmega, mask)                 % O(N log N), once per distKey
    v = mask & isfinite(gain) & dOmega > 0;
    [gu, ~, ic] = unique(gain(v));                        % ties collapse here → strict '>' is exact
    wu = accumarray(ic, dOmega(v));  W = sum(wu);
    d.g = gu;  d.S = [flip(cumsum(flip(wu))); 0] * (100 / W);   % S(k) = 100·Ω(G ≥ gu(k))/W, S(end)=0
end
function c = cov_curve(d, T)                              % O(T log N)
    k = discretize(T(:), [-Inf; d.g; Inf]);               % k−1 = #(gu ≤ T)
    c = d.S(k);                                           % 100·Ω(G > T)/W
end
```

`distKey = sprintf('%d|%s|%s', Derived.Revision, component, coneKey)`; `coneKey = "sph"` or `"con|θ|φ|α"` (`%.6g`). Cone mask: `Geometry.UnitVectors * c(:) >= cosd(α)`.

- Threshold spinners → `cov_curve` only (no recompute).
- Table union of checked jobs: **exact** re-evaluation via each job's dist (no `interp1` on CCDF as in M7 1767).
- Queries: on the **displayed curve** (linear between threshold samples, as M7) for consistency with the plotted line; `dist` kept for exact table values. (Open decision §14 if exact-step queries are preferred.)
- `readCoverageConfig()` is pure: builds the threshold vector without writing `ThreshMax`; `applyCoverageConfig` writes clamped widgets.

### 5.9 Import — `io_*`

```matlab
Formats = dictionary of ext/format → struct( ...
   'order',   [thetaCol phiCol c1 c2 c3 c4], ...   % column mapping
   'kind',    "reim" | "magphase" | "gain", ...
   'basis',   "linear" | "rcp_lcp" | "lcp_rcp", ...
   'source',  "XGTD UAN" | ...)
```

- `io_read(path, format)` → dispatch: `xlsx/xls → io_excelMatrix`, `ffd → io_ffd`, `cut → io_graspCut`, everything else → `io_columns(path, Formats(key))`.
- `io_columns`: `readmatrix` (not `readtable`+`detectImportOptions`: faster) → `io_fieldsToComplex(vals, desc)` → `io_toThetaPhi(c1, c2, desc.basis)` (the single RHCP↔θφ implementation) → `Source`.
- Coverage detector for generic text: header match **or** (`numel(unique(col2)) > 1 && ~looksLikeAngleGrid(col1) && all(0 ≤ col2 ≤ 100)`), where `looksLikeAngleGrid` = ≥ 3 distinct values, span ≤ 360, near-constant spacing. A single-cut gain CSV is a pattern.
- FFD: reshape once to `N × 4 × F`; `Source.Freqs` aligned; frequency switch = `pat_normalize(Source, f)` on that block only (geometry shared when axes match).
- `.cut` single-cut synthesis kept, flagged (`Meta.synthesizedRevolution`).

### 5.10 Export — lazy, canonical

- Results: `array2table(M(:, mask), 'VariableNames', names)` with θ/φ from Pattern (physical). Built on click.
- UAN: from Pattern (φ ∈ [0,360), seam column dropped), rounded 5 dp, sorted φ-major as XGTD expects. Never from the view.
- Cut: from the cached extract.
- Coverage: numeric table with `ColumnFormat` (no `compose('%.2f')` string table).

---

## 6. Orchestration

### 6.1 `update(app, scope)` — the dispatcher that replaces the refresh family

| User action | scope | Recompute | Render |
|---|---|---|---|
| Load / Process / FFD index / text format | `source` | `io_read` (if needed) → `pat_normalize` → resample if 1° → `geo_build` → `pat_calc` → orientation → metrics | full topology pass (`cla` **only** if grid size changed), cuts, tables (visible ones), metadata, ranges preset |
| Parameters (loss, Pt, R, Rx) | `params` | `pat_calc` (Geometry reused) → metrics | `CData` on 5 surfaces, cut `YData`, tables, metadata |
| Native ↔ 1° step | `step` | `pat_resample` → `geo_build` → `pat_calc` → metrics | topology pass |
| Component dropdown | `component` | `met_peak(col)` (cached) | `CData` only (+ polar-3D radius, rect-3D `ZData`), POB marker, title, colorbar theme, cut columns if basis follows |
| Elevation / signed φ | `span` | **nothing numeric**; `geo_displayMap` | `CData(:,perm)`, `XData/YData` axes, ticks, labels, cut `XData` remap, POB re-index |
| Cut type / value / E–H / basis / checkboxes | `cut` | `geo_cut` (cached per revision+type+value) | 2-D cut lines + both 3-D overlays from **one** extract, HPBW |
| Colorbar / cut range / color step | `range` | nothing | `clim`/`zlim`/`RLim` + ticks |
| POB / HPBW checkboxes / tab change | `annot` | nothing | visibility of registry handles |
| 3-D view dropdown | `camera` | nothing | `view`/`camup` on 3 axes |
| Coverage threshold spinners | — | `cov_curve` | line `YData` |
| Coverage query | — | interpolation | query lines / tips (registry) |

Scopes form a strict ladder: `source ⊃ step ⊃ params ⊃ component ⊃ {span, cut, range, annot, camera}`. `update` runs the stages at or below the requested rung, in this order, then **one** `drawnow limitrate`.

Deleted as bodies: `refresh`, `updateViewResults`, `refreshAngularView`, `applyStep`, `applyAngularSpan`, `stepChanged`, `onComponentChanged`, `renderAllFullPatterns`, `drawSpatial3D`, `initRanges`.

**Worked contrast — component change on a 1° FFD**

| M7 | M8 |
|---|---|
| `onComponentChanged` → `updateViewResults` → orientation (on the new component) + metrics (mixed) + 65k×17 uitable push + `plotCut` + 5× `cla`/`surf` + 2 menus per 3-D axis + POB re-creation | `update("component")` → `reshape(M(:,c))` → `set(Surface,'CData')` ×5 (+radius on polar-3D, `ZData` on rect-3D) → POB `DataIndex` → title strings |
| 0.8–2 s | ≤ 150 ms |

**Worked contrast — θ-span switch**

| M7 | M8 |
|---|---|
| Clone 17 columns, rewrite θ, `sortrows`, bump revision, wipe caches, **re-detect orientation on elevation angles**, redraw everything | `View.ElevationTheta = true` → `Map.ThetaAxis = 90 − Theta`, `Map.ThetaDir = 'normal'`; rewrite `YData`/ticks of contour & rect-3D; fisheye radial labels; cut `XData`; math untouched |

### 6.2 Callback shape, guard, visibility

```matlab
function guard(app, title, fn)                 % the only try/catch in the UI layer
    if app.isClosing, return; end
    try, fn();
    catch err
        if err.identifier == "APAT:Cancelled", app.setStatus(app.Single_StatusBar, 'Cancelled.', true);
        else, app.showError(err, title); end
    end
end
```

- `readConfig()` is the only Main `.Value` reader; `readCoverageConfig()` the only Coverage reader. Both pure.
- `applyVisibility(app)` is the **one** place that computes `Visible/Enable` for every panel/control from `Source.Meta`, `View.ResultMask`, and coverage state (replaces the scattered `set(...,'Visible')` in `refresh`, `onComponentChanged`, `updateInputVisibility`, `setCoverageUI`, `Cov_ButtonGroup_CovTypeSelectionChanged`).
- Long operations: pipeline stages receive `checkpoint` (a function handle, default no-op) so cancel works without stages knowing about `uiprogressdlg`.
- `perf` recording is enabled only when `getenv("APAT_PROFILE")` is non-empty; no `assignin` otherwise.

### 6.3 Range controller (one descriptor family)

```matlab
RangeGroup = struct('name',"full"|"cut"|"cov", 'sliders',[...], 'mins',[...], 'maxs',[...], ...
                    'bounds',[-250 100], 'minGap',1|0.1, 'apply',@(lim) ...)
```

`onRange(app, group, src, value)` implements the one algorithm M7 has twice (widen `Limits`, set `Value`, narrow `Limits`, set spinner `Limits`, call `apply`). `startupFcn` wires the lambdas; the generated `createCallbackFcn(app,@onRangeUIChanged,true)` on `Single_Plot_Cmin/Cmax` (3287, 3294 — wrong arity, currently overwritten at 1971) is removed from `createComponents`.

### 6.4 Status & lifecycle

- One `timer` created in `startupFcn` (`ExecutionMode='singleShot'`, `StartDelay=3`); `setStatus(..., temporary=true)` does `stop; start`. `restoreStatus` reads `label.UserData` (kept as the one legitimate `UserData` use: persistent message text) — or better, `app.StatusPersistent` dictionary keyed by label. Choose the dictionary; zero `UserData`.
- `shutdown(app)` = stop timer, delete dialog, delete registry handles. `delete(app)` and `closeRequest` both call it once.

---

## 7. Rendering — retained mode

### 7.1 Registry

```matlab
app.Graphics.Full(k).{Axes, Surface, Colorbar, Title, Triad(3 quiver + 3 text), POBMarker, POBTip, Overlay}
app.Graphics.Cut.{PolarLines(3), RectLines(3), PolarRegion, RectRegion, BoundMarkers(4), BoundTips(4), POB(2)}
app.Graphics.Cov(jobId) = struct('Line', h, 'Q', struct('cov',[V H Tip],'thr',[V H Tip]))
app.Graphics.Menu   % one uicontextmenu, created in startupFcn, assigned to every axes and surface
```

Recipe used by every renderer:

```matlab
if isgraphics(s.Surface), set(s.Surface, 'CData', grid, <XYZ only when topology/map changed>);
else,                     s.Surface = surf|pcolor|surface(...);  s.Surface.ContextMenu = app.Graphics.Menu; end
```

- `cla` only when the grid size changes (`size(grid) ~= size(s.Surface.CData)`).
- Cut lines: create 3 lines per axes once; unused ones `Visible='off'`; update `XData/YData/ThetaData/RData/Color/DisplayName`. Legend created once, `String` updated.
- XYZ triad created once per 3-D axes.
- Datatip templates: create once; update `DataTipRows(k).Value` arrays.
- POB: one marker + one datatip per full-pattern tab, created once; `update("component"|"span")` sets `XData/YData/ZData` + `DataIndex`. `createPOBDataTip` fallback logic shrinks to the graceful-degradation branch.
- Overlay: one `plot3` per 3-D axes; `update("cut")` sets its data from the shared extract; scale uses `View.GainLim` (fixes D3).

### 7.2 Display map (span) — precise recipe

```matlab
function m = geo_displayMap(G, V)
    ph = G.PhiGrid(1,:);  th = G.ThetaGrid(:,1);
    if V.SignedPhi
        keep  = ph < 360;                              % drop seam column
        left  = find(ph > 180 & keep);  right = find(ph <= 180 & keep);
        m.ColPerm = [left, right(1), right(2:end)];     % ... −180..0..180 (φ=180 shown as −180 first, 180 last)
        m.ColPerm = [left, right, right(1)];            % duplicate φ=0/180 handling: exactly one 180 and one −180
        m.PhiAxis = ph(m.ColPerm); m.PhiAxis(m.PhiAxis > 180) = m.PhiAxis(m.PhiAxis > 180) - 360;
        m.PhiLim = [-180 180];
    else
        m.ColPerm = 1:numel(ph);  m.PhiAxis = ph;  m.PhiLim = [0 360];
    end
    m.ThetaAxis = th;  m.ThetaDir = 'reverse';  m.ThetaLim = [0 180];  m.ThetaLabel = "Theta";
    if V.ElevationTheta, m.ThetaAxis = 90 - th; m.ThetaDir = 'normal'; m.ThetaLim = [-90 90]; m.ThetaLabel = "Elevation"; end
end
```

(The exact permutation for the −180/180 duplicate is fixed in code; the point is: **rendering = `CData(:, ColPerm)`, `XData = PhiAxis`, `YData = ThetaAxis`**, and fisheye/3-D spherical/3-D polar only change **tick labels** because their geometry is physical already.)

### 7.3 Tables

- `Single_Table_DataOut.Data` is pushed only when the Results tab is the selected data tab **and** `renderedRevision ≠ (Derived.Revision, ParamHash, ResultMask)`. Push a numeric matrix + `ColumnName`, not a table.
- Input table: once per Source (as M7).
- Metadata: rebuilt from `Pattern/Geometry/Derived/Metrics` — includes `regularized`, `synthesizedRevolution`, `IsFullSphere` rows.

---

## 8. Correctness designed in

| M7 defect | Why M8 cannot contain it |
|---|---|
| Re/Im rounded to 5 dp (4904) | `pat_normalize` snaps θ/φ only |
| θ>180 folded twice (4895, 4908) | one fold |
| Metrics mix component peak with total gain (2810→4609) | I4: metrics see total gain only |
| Orientation detected on AR / on elevation θ (4838–4848) | `met_orientation(gainTotal, Geometry)` — physical unit vectors |
| `prctile` toolbox dependency (5113) | sort-based quantile |
| `pi` shadowed (507) | no `gridComp` |
| Unweighted polarization class (4743) | Ω-weighted |
| Uniform-step Ω, wrong partial-sphere efficiency (5170, 4638) | edge-based dΩ; `IsFullSphere` gate |
| 63-char `makeValidName` cache collisions (2277) | `distKey` string in a `dictionary` |
| Single-cut gain detected as coverage (4022) | stricter detector + fixture |
| UAN writes signed φ (2155) | export from Pattern |
| Coverage uses FFD block 1 (2264) | `View.FreqIndex` flows into node ref |
| Overlay radius mismatch (1237/1265) | one `View.GainLim` |
| `cutData` ×3, `calcPattern` wasted on native grid (315/432), 3-D drawn twice on load (355/357) | `update` ladder, one extract, one derive |
| 2 context menus per 3-D render; 3 quivers per render; POB recreated | registry, create-once |
| `covThresholds` writes `ThreshMax`; `prepareTextFormat` writes dropdown (1523, 282) | pure getters/readers |
| `Cov_Button_LoadPushed` outside try (2256) | `guard` |
| Per-message `timer` (1818); `assignin` on every op (1928) | one timer; env-gated profiler |
| Duplicate `gainDisplayRange`/`coverageDisplayRange`, `cutGeometry`/`calcCutGeometry`, two range controllers | one of each |
| Version string drift (3073 vs 248) | one `ReleaseName` |

---

## 9. Destination file layout

```
classdef APAT_v3_M8 < matlab.apps.AppBase
  %% A  UI component properties           generated; do not hand-rename
  %% B  Constants + schema factories       Const (PeakPercentile, PeakMaxExcessDB, Bounds, PrincipalAxes, StandardColumns,
  %%                                       HiddenOutputColumns, Formats, ReleaseName), newSource/newPattern/newGeometry/
  %%                                       newDerived/newView/newMap/newGraphics/newRangeGroups
  %% C  State properties (private)         Source, Pattern, Geometry, Derived, View, Map, Graphics, CutCache, CovDists,
  %%                                       RangeGroups, StatusTimer, OperationDialog, isClosing
  %% D  Orchestration (private)            readConfig, readCoverageConfig, update(scope), applyVisibility, applyRanges,
  %%                                       applyMetadata, applyTables, applyCoverageResult, guard, setStatus, shutdown
  %% E  Callbacks (private)                one-liners: guard(title, @() update(scope)) or coverage equivalents
  %% F  Renderers (private)                renderFull(k), renderCut, renderOverlay, renderPOB, renderCoverageJob,
  %%                                       renderQuery — write app.Graphics.* only
  %% G  Public API                         ctor, delete, closeRequest;  Static: selfTest, version
  %% H  createComponents                   generated layout; NO ValueChangedFcn for range widgets (wired in startupFcn)
end

%% Local functions — app-free, alert-free, H1 one-liner, ≤ ~60 lines each
%%   io_*    io_read, io_columns, io_fieldsToComplex, io_toThetaPhi, io_ffd, io_graspCut, io_excelMatrix, io_excelSummary,
%%           io_isCoverageTable, io_findHeaderLines
%%   pat_*   pat_normalize, pat_resample, pat_decimate, pat_calc, pat_calcLink, pat_validate
%%   geo_*   geo_build, geo_displayMap, geo_cut, geo_coneMask
%%   met_*   met_resolvePeak, met_quantile, met_orientation, met_metrics, met_hpbw
%%   cov_*   cov_dist, cov_curve, cov_queryCoverage, cov_queryThreshold, cov_thresholds, cov_validate
%%   util_*  util_fmtNumber, util_ticks, util_clampRange, util_displayRange, util_plotTheme, util_arColormap,
%%           util_coneLabel, util_hash
```

A helper exists only if it (1) removes real duplication, (2) is one algorithm, (3) has reusable I/O, (4) simplifies the call site. Otherwise fold it back.

**Size budget (lines):** UI layout 690 · io 330 · pat/geo/met/cov 420 · orchestration + apply 450 · renderers 380 · callbacks 120 · schemas/constants 110 · selfTest 200 · comments/headers 200 → **≈ 2,900**.

---

## 10. Fold / delete (the concision checklist)

If a name in the right column still exists in the file, the blow is incomplete.

| Keep | Delete |
|---|---|
| `geo_cut` | `cutGeometry`, `calcCutGeometry`, `cutData`, `cutCols` (→ `readConfig`) |
| `Geometry` + `reshape` | `gridCache`, `emptyGridCache`, `gridComp`, `gridGeom`, `invalidateDerived`, `viewSolidAngle`, `viewRevision`, `physicalTheta`, `solidWeights` |
| `Pattern`, `Derived.M` | `rawTbl` (→ `Source.Raw`), `stdTbl`, `patTbl`, `viewBaseTbl`, `viewTbl`, `uanTbl`, `ffdBlocks`, `srcUD` |
| `update(scope)` | `refresh`, `updateViewResults`, `refreshAngularView`, `applyStep`, `applyAngularSpan`, `stepChanged`, `onComponentChanged`, `renderAllFullPatterns`, `drawSpatial3D`, `initRanges`, `selectBlock`, `activateSource` |
| `met_metrics`, `met_orientation` | `computeMetrics`, `detectOrientation`, `calcOrientation`, `calcMetrics`, `updateSelectedComponentPeak`, `POB/POBth/POBph/polLabel/polPairs/boresightIndex/antennaMetrics/peakInfo` properties (→ `Derived`, `Metrics`) |
| `met_resolvePeak` + `met_quantile` | `resolvePeak(values,pct,excess,~,~)` with ignored args; `prctile` |
| `util_displayRange` | `gainDisplayRange`, `coverageDisplayRange`, `robustRange` |
| `applyRanges` + `RangeGroups` | `onRangeUIChanged`, `setCoverageRange`, `syncCoverageXRange`, `clearCoverageSync`, `markCoverageThresholdUserEdit`, `coverageRangeState`, `fullPatternSpecs`, `applyFullPatternRange`, `clampRange` (→ util) |
| `cov_dist`/`cov_curve` | `coverageCCDF`, `coverageCacheKey`, `covThresholds` (→ pure `cov_thresholds`), `syncCoverageNodeFromView`, `syncCoveragePattern`, `coverageArtifacts`, `coverageQueryPoint`, `coverageInterpolationLocation`, `covJobs` cell |
| `applyVisibility` | `updateInputVisibility`, `setCoverageUI`, `setControls`, scattered `set(...,'Visible')` |
| `Graphics` registry | `AnnotationSources`, `FullPatternPOBRecords`, `initializeFullPatternPOBRecords`, `findRenderedPatternSurface`, `clearAnnotations`, `refreshAnnotations`, `configurePlotContextMenu`, `ensureFullPatternPOBAnnotations`, `updateFullPatternPOBVisibility`, every `findall`/`findobj` |
| `guard` | 12 ad-hoc `try/catch` blocks, `showError` duplicates |
| one status timer | `disposeStatusTimer`, `stopStatusTimer`, `restoreStatus(timer)` |
| `shutdown` | `closeRequestImpl` + `cleanupResources` + duplicated `delete` body |
| `io_columns` + `Formats` | the UAN/FZ/OUT/FFS/FFE `switch`, generic 6-column branch, RHCP→θφ ×4, mag/phase ×3, `validateSourceModel` (→ `newSource` defaults) |
| `util_fmtNumber` | `fmtStatusAngle` |
| `Const.ReleaseName` | literal `M7.110` in title |
| numeric coverage table + `ColumnFormat` | `compose('%.2f')` string table |
| `View` | `Single_DropDown_step.UserData`, `CutFieldBasisDropDown.UserData`, `Single_DropDown_output.UserData`, `Cov_gridPanel_Parm.UserData`, both `StatusBar.UserData`, `defaultParams` (→ `Const.Defaults`) |
| `selfTest` (Static) | `runSelfTest(app)` |

---

## 11. Refactoring strategy — one blow, one work order

Construction order, not shipped milestones. Nothing is released until §12 is green.

1. **New file, core only.** Write section B factories and every `io_/pat_/geo_/met_/cov_/util_` local function. No widgets. Prove them with the Static `selfTest` (§12 rows 1–14). At this point M8 math is already the product; the app is a shell.
2. **Golden capture from M7.** Before touching UI, run M7 on the fixture set and save `Derived`-equivalent tables, metrics, coverage curves, and plot `CData` to `.mat`. The §12 `goldenHash` row compares against these, with the **designed deltas** listed (angle-only rounding, Ω-weighted polarization, edge dΩ on non-uniform fixtures, metrics on total gain, detector, UAN φ).
3. **Paste `createComponents` as-is**, minus range-widget `ValueChangedFcn` entries. Fix the title to use `Const.ReleaseName`. Do not rename generated properties.
4. **Install state + orchestration**: properties, `readConfig`, `readCoverageConfig`, `update`, `applyVisibility`, `applyRanges`, `guard`, `shutdown`, one timer, one context menu, `RangeGroups`.
5. **Renderers** in retained mode against the registry. Verify I10 with the `graphicsLeak` test before wiring more callbacks.
6. **Retarget every callback** to the one-liner shape. `startupFcn` wires ranges, stores axes handles into `Graphics`, creates the menu and timer.
7. **Coverage**: nodes hold `PatternRef` (path, revision, freqIndex); Compute reads `app.Derived/Geometry` when the node is the Main pattern, else the node's own `Derived/Geometry` (built by the same `pat_*`/`geo_*` functions at Coverage-Load time). Distributions live in `app.CovDists` (dictionary by `distKey`).
8. **Delete §10 names in the same edit.** Dual-read (`viewTbl` **and** `Derived.M`) is forbidden. `grep` the §10 right column: any hit → stop.
9. **Run §12.** On failure, fix the destination. Do not resurrect `viewTbl`.

**What this strategy refuses**

- An M7.111 "correctness patch" that still has six tables.
- An interim `viewBaseTbl` clone "until display mapping is ready".
- New helpers that wrap widgets (`updateXMinSpinner`). Finish the descriptor.
- Caches keyed on spinner values instead of `(revision, cfg hash)`.
- Any `toolbox` call (`prctile`, `interp1` is base — fine; `scatteredInterpolant` is base — fine).

---

## 12. Release gate (`APAT_v3_M8.selfTest()` — Static, no UI)

Returns a table `name / pass / detail`. All must pass.

| # | Check | Assertion |
|---|---|---|
| 1 | `peak` | P99.99 + 6 dB on a 100k-sample spiked vector: `wasAdjusted`, value = baseline, `rawIndex` = spike; identical to M7 `prctile` result on 5 random vectors (< 1e-12) |
| 2 | `solidAngle` | Σ dΩ = 4π ± 1e-9 on 1°, 2°, 5°, and a **non-uniform** θ axis; seam column weight 0; hemisphere Σ = 2π ± 1e-9 and `IsFullSphere = false` |
| 3 | `gridMajor` | `reshape(Pattern.E(:,1), nθ, nφ)` equals `meshgrid`-built field; seam column equals φ=0 column |
| 4 | `ccdfEquivalence` | `cov_curve` vs legacy N×T (with duplicates and ties) max \|Δ\| < 1e-12 on 3 fixtures; strict `>` at a tie threshold |
| 5 | `coverageInverse` | `cov_queryThreshold(cov_queryCoverage(T)) == T` on the sampled curve within 1e-9 |
| 6 | `coneMask` | dot-product mask ≡ angular-distance mask on 20 random cones |
| 7 | `normalizePrecision` | −120 dB cross-pol Re/Im bit-exact after normalize; θ/φ snapped; one fold (θ = 200 → 160, φ+180) |
| 8 | `resampleIdentity` | native-sample error < 1e-10; decimation path bit-exact; irregular path uses **one** `scatteredInterpolant` (count via a spy counter) |
| 9 | `displayInvariance` | polar → elevation / signed φ: identical `Derived.M`, boresight, F/B, Ω, spherical & conical coverage; `Map.ColPerm` is a permutation |
| 10 | `metricsSemantic` | metrics with `View.Component = "AR_dB"` equal metrics with `"E_Total_dB"` |
| 11 | `polarizationWeighted` | a pole-dense synthetic that M7 misclassifies is classified by dominant Ω-weighted power |
| 12 | `readers` | every extension via temp fixtures; single-cut gain CSV is **not** coverage; FFD 2-block file yields `Blocks` of size N×4×2 and correct `Freqs` |
| 13 | `cutGeometry` | θ-cut wraps through the opposite φ with 361 samples (0 = 360); φ-cut at θ=90 returns one row |
| 14 | `uanExport` | φ ∈ [0,360), no seam duplicate, sorted φ-major, after a signed-φ view |
| 15 | `graphicsLeak` (UI, optional) | counts of `uicontextmenu`, `datatip`, `ColorBar`, `Line`, `Surface` constant across 20 component/cut/span/query cycles |
| 16 | `goldenHash` (fixtures) | `Derived.M`, plot `CData`, coverage curves match M7 captures **except** the designed deltas (listed in code) |
| 17 | `perf` (UI, optional) | 1° FFD: load ≤ 3 s, component ≤ 150 ms, span ≤ 100 ms, cut ≤ 60 ms, coverage dist ≤ 50 ms, threshold re-curve ≤ 5 ms, re-query ≤ 5 ms |

Also: Code Analyzer clean (no shadowed builtins, no unused args); ≤ 3,000 lines; ≤ 6 public methods; §10 names gone; `grep -c "findall\|findobj\|UserData" APAT_v3_M8.m` → 0 outside `createComponents`.

---

## 13. Risks & platform baseline

| Risk | Handling |
|---|---|
| Matrix vs table drift in tables/export | `Derived` façade builds tables only at the two edges (uitable, export); golden hashes |
| Stale retained surfaces after step/source | `update("source"|"step")` compares grid size; `cla` only on change; otherwise `XData/YData/ZData/CData` all reset |
| Signed-φ column permutation errors | `displayInvariance` test + `ColPerm` is-a-permutation assertion |
| CCDF `>` vs `≥` | unique+accumarray aggregation makes ties exact; equivalence test with duplicates |
| FFD grids differ by frequency | share Geometry only when axes match; else revision bump |
| Edge-based dΩ vs M7 on uniform fixtures | identical by construction (midpoints of a uniform axis = ±Δ/2); asserted in row 2 |
| App Designer property names | leave generated names; alias in `readConfig` |
| MATLAB release | **Baseline R2023b** (already required by `uislider('range')`); this unlocks `dictionary`, `xregion/thetaregion`, `datatip InterpolationFactor`. Remove all "older release" fallbacks except the POB datatip graceful branch |
| Toolboxes | none. `prctile` removed. `scatteredInterpolant`, `interp2`, `discretize`, `accumarray` are base MATLAB |

---

## 14. Open decisions for the owner (answer before step 1)

1. **UAN `maximum_gain`** — keep M7 semantics (max over E_TH_dB / E_PH_dB components) or switch to peak total gain? (D16)
2. **Coverage queries** — interpolate on the displayed curve (M7 behaviour, proposed default) or return the exact step-function value from the distribution?
3. **Partial-sphere efficiency** — show `n/a` (proposed) or show the value with a "partial sphere" suffix?
4. **Body-of-revolution `.cut` synthesis** — keep with a Metadata flag (proposed) or refuse single cuts?
5. **Cut-value spinner units** — spinner value is interpreted in the current display convention (elevation / signed) and converted to physical in `readConfig` (proposed), or always physical?
6. **Results table** — push only when the Results tab is visible (proposed) or always?

---

## 15. Outcome

| Metric | M7.110_5 | M8 |
|---|---|---|
| Lines (one file) | 5,200 | ≤ 3,000 |
| Public methods | ~90 | ≤ 6 |
| Pattern copies per refresh | 6 (+2 per coverage node) | 1 canonical + 1 derived matrix |
| Grid index maps / caches | `gridCache` + `ismember` + `sub2ind` | `reshape` |
| `UserData` state flags | 6 | 0 |
| `findall`/`findobj` outside layout | 12 | 0 |
| Duplicate algorithms | 9 | 0 |
| Toolbox dependencies | 1 (`prctile`) | 0 |
| Component change (1° FFD) | 0.8–2 s | ≤ 150 ms |
| Span toggle | full recompute + redraw | ≤ 100 ms remap |
| Coverage compute (65k × 501 thresholds) | ~260 MB transient, O(N·T) | O(N log N) once, O(T log N) per curve |
| Threshold / query | full CCDF | ≤ 5 ms |
| Context menus per 3-D render | 2 leaked | 0 |
| Known correctness bugs (§0.2 + §8) | 16 | 0 |

**Out of scope:** new plot types, new file formats, new metrics, per-control helper families, spinner-keyed caches.

The drop is M8 when §12 is green **and** the names in §10 no longer exist in the file.
