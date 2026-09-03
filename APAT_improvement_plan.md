# APAT M8 — Single-Blow Refactor Plan

**From:** `APAT_v3_M7_110_5.m` (one App Designer class + ~90 methods + 30 local functions)  
**To:** `APAT_v3_M8.m` — the **same one file**, rewritten around one dataflow.  
**M7 analysis (not this file):** [`APAT_code_review.md`](APAT_code_review.md)

This is **one drop**. Do not patch M7, do not ship half-tables, do not run old and new pipelines together. Build the destination, point the UI at it, delete every M7 name that the destination replaces.

---

## 1. Why M8 is a different program, not a faster M7

M7 is feature-complete and numerically serious. It is long because **the same physical pattern is re-interpreted in every consumer**, and because **UI callbacks own algorithms**. That produces:

- six table copies of one sphere (`raw → std → pat → viewBase → view → uan`, plus two more on each coverage node)
- display conventions (elevation θ, signed φ) stored as **data**, then undone with `physicalTheta` in seven places
- `calcPattern` twice, `solidWeights`/`unique`/`gridStep` many times, `cla` + `findall` on every click
- duplicate algorithms (`cutGeometry` ≡ `calcCutGeometry`, two range helpers, RHCP→θφ four times, mag/phase three times)
- state hidden in widget `UserData`, so every callback re-discovers configuration

Adding caches on top of that (M7’s `viewRevision`, `gridCache`, `coverageCacheKey`) does not shorten the program: each cache is a **local** fix for a **global** dataflow mistake. M8’s strategy is the opposite:

> **One physical pattern. One geometry. One derived matrix. One config snapshot. One graphics registry.**  
> Math never sees the app. UI never rebuilds math. Display is a mapping, not a copy.

Concision is not “write denser MATLAB.” It is **one implementation per concept**, so `refresh` / `applyStep` / `applyAngularSpan` / `updateViewResults` / `syncCoverageNodeFromView` / `coverageArtifacts` have nothing left to do and are deleted.

---

## 2. One rule

```matlab
cfg    = app.readConfig();                 % ONLY place widget .Value is read
result = <pure local function>(data, cfg)  % app-free, alert-free
app.apply(result)                          % ONLY place handles / labels are written
```

A callback coordinates. It does not contain the algorithm.  
Elevation θ and signed φ are **axis mapping** (`XData`/`YData`/ticks), never a second pattern table.

---

## 3. Invariants (the drop is invalid if any of these move)

- Peak policy: **P99.99 + 6 dB**.
- Interpolate **primitive fields only** (`Re/Im Eθ, Eφ`, or linear power for gain-only). Never AR / PLF / dB. `pat_calc` runs **after** resample.
- Canonical sphere: polar θ ∈ [0,180], φ ∈ [0,360], φ=360 seam present, **dΩ = 0** on the seam. Snap **angles only** to 5 decimals — not Re/Im / gain.
- Coverage: `Coverage(T) = 100 · Ω(G > T) / Ω_region` (strict `>`). Cones and orientation use **physical** angles.
- Query unit formatting stays on the query controls (`%g dB` / `%g%%`); datatips show the exact query value.
- Readers produce the same canonical pack as M7 **except** where M7 was wrong (angle-only rounding, coverage-file detector, UAN φ ≥ 0).
- Result stays **one `.m` file**. Structs + prefixed local functions. No packages.

---

## 4. Architecture — M7 vs M8

### 4.1 M7 dataflow (today): copy, reinterpret, search

```
FILE
 └─ readPattern  →  rawTbl + blocks{} + freqs + userData
      └─ normalizePattern  →  stdTbl          (also rounded Re/Im)
           └─ refresh
                ├─ calcPattern(stdTbl)           → patTbl          ①
                ├─ applyStep
                │    └─ resample? calcPattern    → viewBaseTbl     ② again
                └─ applyAngularSpan
                     └─ COPY 17 columns, mutate θ/φ, sortrows → viewTbl
                          ├─ detectOrientation(viewTbl.Theta)      ③ display θ as polar
                          ├─ calcMetrics (solidWeights again)
                          ├─ 5× cla + surf + new uicontextmenu
                          ├─ uitable ← viewTbl (even if hidden)
                          └─ Coverage clones viewTbl twice into NodeData
                               └─ Compute: sync again, rebuild cone trig,
                                  coverageCCDF as N×T, cache key = thresholds
```

Every arrow is a **full pattern**. Consumers do not share geometry. UI spans change physics. Coverage is a second app bolted onto a cloned table.

### 4.2 M8 dataflow (destination): derive once, project cheaply

```
FILE
 └─ io_readPattern
      │  Source.Raw          (Input tab only)
      │  Source.Blocks       Θ × Φ × F × 4 primitives  (or packs sharing Θ/Φ)
      │  Source.Freqs, .Meta
      ▼
 pat_normalize  ──►  Pattern { Theta, Phi, E|Gain, Revision }
      │                 polar sphere, angles snapped, seam added
      ▼
 pat_analyzeGrid ──►  GridInfo { regular?, steps, unique axes, LinIdx }
      │
      ├── pat_resample (only if step ≠ 1°)     geometry once, F.Values many
      │         │
      │         ▼  Pattern.Revision++
      │
      ├── pat_calc(params) ──► Derived { M[N×C], Cols, ParamHash }
      │                           EIRP/PFD/E_RMS filled lazily
      │
      └── geo_build ────────► Geometry { UnitVectors, dOmega, grids, ConeMasks }
                                Revision == Pattern.Revision  (the only validity test)

 View  = readConfig()          labels, limits, component, freqIndex, cut, masks
                               NEVER copies Pattern

        ┌────────────┼────────────┬────────────┐
        ▼            ▼            ▼            ▼
     PLOTS        METRICS      COVERAGE      EXPORT
     Graphics.*   met_*        dist cache    on click
     CData/XData  from geo     coneKey       from Pattern
     ticks=map    + Derived    query O(log N)  (φ ≥ 0)
```

**Dependency graph (keep this in the file as a comment above `update`):**

```
RAW
 │
 ▼
CANONICAL PATTERN  (Revision)
 │
 ├───────────────┐
 ▼               ▼
GEOMETRY      DERIVED.M
 │               │
 ├───────┐       ├───────┬────────┐
 ▼       ▼       ▼       ▼        ▼
METRICS COVERAGE PLOTS  CUTS    EXPORT
          │
          ▼
   SORTED DISTRIBUTION
          │
     ┌────┴────┐
     ▼         ▼
 THRESHOLD   QUERY
```

If a function needs something not on a path from its inputs, it is reaching into the app. That line does not belong in M8.

### 4.3 Layer contracts (who may write what)

| Layer | Object | Writer | Readers | Forbidden |
|---|---|---|---|---|
| Source | `app.Source` | load / format / FFD select | `update("source")` | math, renderers |
| Pattern | `app.Pattern` | `pat_normalize`, `pat_resample` | all below | UI `.Value`, `cla` |
| Geometry | `app.Geometry` | `geo_build` on revision miss | plots, metrics, coverage, cuts | copying Pattern |
| Derived | `app.Derived` | `pat_calc` on (revision, param) miss | plots, metrics, tables, export | interpolating dB columns |
| View | `app.View` | `readConfig()` only | orchestration, renderers | math kernels |
| Cfg | `CoverageConfig`, `ExportConfig` | `readCoverageConfig` / `readExportConfig` | `cov_*`, export | widget mutation |
| Node | `newNode()` | coverage `apply` | tree mirror, job plots | `pattern` + `sourceTable` twins |
| Graphics | `app.Graphics` | renderers only | renderers only | `findall` / Tag search |

**Validity is one comparison:** `cache.Revision == Pattern.Revision` (plus `ParamHash` for Derived, `coneKey` for a coverage dist). No `CanonicalValid` / `ViewValid` / `CoverageValid` flag families — those flags are how M7 forgot to invalidate.

Generated UI names stay (`Singel_CheckBox_overlayCut`, `Cov_Tabel`). `readConfig` aliases them. Do not fight App Designer in this drop.

### 4.4 Why this is shorter

M7 length is mostly **glue that exists because data is in the wrong shape**.

| Concept | M7 (many implementations) | M8 (one) | Lines that vanish |
|---|---|---|---|
| Physical angles | `viewTbl` + `physicalTheta` ×7 | Pattern is already polar | `applyAngularSpan` clone, `physicalTheta`, display-θ bugs |
| Pattern identity | 6 tables + 2 node copies | Pattern + Derived.M | `stdTbl/patTbl/viewBaseTbl/viewTbl/uanTbl` properties and every assignment |
| Refresh | `refresh` → `applyStep` → `applyAngularSpan` → `updateViewResults` → `renderAll…` | `update(scope)` | those five bodies (~400–600 lines) |
| Cut geometry | app method + file-scope twin | `geo_cutGeometry` | one copy + `cutData` status side-effect |
| Grid / dΩ | `gridCache` (wrong schema) + `emptyGridCache` + `solidWeights` ×8 | `geo_build` | both caches, repeated `unique`/`gridStep` |
| Coverage | monolith callback + N×T CCDF + Tag search | `cov_compute` + sorted dist + stored handles | `syncCoverageNodeFromView`, `coverageCacheKey`, `coverageArtifacts` |
| RHCP↔θφ, mag/phase | 3–4 inline copies | `io_circToLin`, `io_magPhaseToComplex` | reader bloat |
| Range UI | two controllers + startup slider arrays | `fullPatternSpecs` + one range fn | `setCoverageRange` ∩ `syncCoverageXRange` |
| State | 6× `UserData` + 9-field range state | `View` | flag plumbing |
| Graphics lookup | 10× `findall`, 2× `findobj`, 2 menus/render | registry | search helpers, leak paths |

**Target:** ≈ 3,400 lines (−35 %), ≤ 8 public methods, 0 duplicate algorithms. `createComponents` (~1,800 lines) stays; the cut is in **orchestration + math + render**, which is where M7 is both long and slow.

---

## 5. Destination file layout

```
classdef APAT_v3_M8 < matlab.apps.AppBase
  %% A  UI component properties          generated; do not hand-rename
  %% B  Constants + schema factories     newSource, newPattern, newGeometry,
  %%                                     newDerived, newView, newNode, newGraphics
  %% C  Orchestration (private)          readConfig, readCoverageConfig,
  %%                                     update(scope), apply*
  %% D  Callbacks (private)              thin: read → compute → apply, one try/catch
  %% E  Renderers (private)              write app.Graphics.* only
  %% F  Public API                       ctor, delete, closeRequest, runSelfTest
  %% G  createComponents                 generated layout; wire ValueChanged in startup
end

%% Local functions — app-free, alert-free, H1 one-liner, ≤ ~60 lines
%%   io_*    io_readPattern, io_circToLin, io_magPhaseToComplex, io_fieldPack
%%   pat_*   pat_normalize, pat_analyzeGrid, pat_resample, pat_calc, pat_validate
%%   geo_*   geo_build, geo_coneMask, geo_cutGeometry
%%   cov_*   cov_buildDistribution, cov_evaluate, cov_queryCoverage,
%%           cov_queryThreshold, cov_validateConfig, cov_compute
%%   met_*   met_orientation, met_metrics, met_hpbw, met_resolvePeak
%%   util_*  util_fmtNumber, util_gridStep, util_ticks, util_plotTheme, util_radius
```

A helper exists only if it (1) removes real duplication, (2) is one algorithm, (3) has reusable I/O, (4) simplifies the call site. Otherwise fold it back. Prefixes are the namespace: there is no second `cutGeometry` hiding as an app method.

---

## 6. Pipelines (inputs, outputs, cost)

Each stage is a **pure function**. The dispatcher below decides which stages run; stages never call UI.

### 6.1 Import — `io_*`

```
path + format  →  Source { Raw, Blocks[Θ,Φ,F,4], Freqs, Meta }
```

- Dispatch by extension through a name→fn map, not a 400-line `switch` with inline conversions.
- Shared: `io_circToLin`, `io_magPhaseToComplex`, `io_fieldPack(StandardColumns)`, `pat_closePhiSeam`.
- Coverage-file detector: header match **or** (`numel(unique(col2))>1 && ~looksLikeAngleGrid(col1)`). Single-cut gain CSV is a pattern.
- FFD: reshape **once** to Θ×Φ×F×4 (or packs sharing Θ/Φ). Frequency switch is an index, not `normalizePattern` + full `refresh`.

### 6.2 Canonicalize — `pat_normalize` + `pat_analyzeGrid`

```
Source block  →  Pattern { Theta, Phi, E|Gain, Revision }
              →  GridInfo { regular, ThetaStep, PhiStep, uTheta, uPhi, LinIdx }
```

- One θ>180 fold with φ+180; wrap φ; duplicate φ=360 seam; round **θ/φ only**.
- This is the **only** place the sphere is standardized. Renderers do not re-fold.

### 6.3 Resample — `pat_resample`

```
Pattern + GridInfo + step  →  Pattern' (Revision++)
```

- Regular: build `phiGrid`/`thetaGrid`/periodic seam **once**; `interp2` per primitive column.
- Irregular: one `scatteredInterpolant` on (φ,θ); `F.Values = v(:)` per column. Method id: `irregular-scattered-reused-geometry`.
- Gain-only: linear power on the value vector only.
- `needsResample` ⇔ `ThetaStep ≠ 1 || PhiStep ≠ 1`. Then **one** `pat_calc`. Delete M7’s second `calcPattern` inside `applyStep`.

### 6.4 Derive — `pat_calc`

```
Pattern + params  →  Derived { M[N×C], Cols, ParamHash, Revision }
```

Columns live in `M`, not a 17-column table. `Cols` is name→index. EIRP / PFD / E_RMS depend only on Pt, R, and total gain — fill when the Results filter or export asks, not on every cut checkbox.

A `table` is built only for (a) Results uitable = angle map + `M(:, mask)`, (b) export on click. Hidden uitables are not pushed (M7’s 65k-row tax).

### 6.5 Geometry — `geo_build`

```
Pattern + GridInfo  →  Geometry { UnitVectors[N×3], dOmega[N] seam=0,
                                  ThetaGrid, PhiGrid, Ux,Uy,Uz, ConeMasks, Revision }
```

- Built **once per Pattern.Revision**. Shared across FFD frequencies when Θ/Φ match.
- `met_orientation` uses `UnitVectors`; it does not rebuild sample vectors.
- Conical mask: `UnitVectors * sph2unit(θ,φ).' >= cosd(α)`, cached by `coneKey`. **Threshold edits do not rebuild the cone.**

### 6.6 Coverage — `cov_*`

```
Derived + Geometry + CoverageConfig
    → dist { g, ccdf, wSample }     O(N log N), keyed (component, revision, coneKey)
    → curve(T)                      O(T log N)
    → queryCoverage / queryThreshold O(log N)
```

```matlab
v = mask & isfinite(gain) & dOmega > 0;
[g, ord] = sort(gain(v));  w = dOmega(v); w = w(ord);
dist.g = g;
dist.ccdf = 100 * flip(cumsum(flip(w))) / sum(w);   % survival
dist.wSample = 100 * w / sum(w);                    % strict-'>' tie correction
```

This **eliminates** `coverageCacheKey`, `makeValidName` (63-char collisions), and the N×T indicator (~25 MB on 1° × 0.1 dB). `cfg.FreqIndex` is required.

Compute callback:

```matlab
cfg = app.readCoverageConfig();
[ok, msg] = cov_validateConfig(cfg);  if ~ok, uialert(...); return; end
result = cov_compute(app.Pattern, app.Geometry, app.Derived, cfg);
app.applyCoverageResult(result);
```

No `syncCoverageNodeFromView` inside Compute. The node syncs when `Pattern.Revision` changes.

### 6.7 Metrics / cuts — `met_*` + `geo_cutGeometry`

```
Derived + Geometry + View.cut  →  peak, boresight, HPBW, F/B, efficiency
                               →  cut samples cached (revision, type, value, cols)
```

Always physical angles. Display mapping is applied only when writing cut-plot `XData`. `geo_cutGeometry` is **pure** (no `setStatus`). Overlay and 2-D cuts share one extract — M7 runs `cutData` twice when overlay is on.

### 6.8 Export — lazy, canonical

```
Export requested  →  generate only that representation from Pattern / Derived  →  write
```

UAN from Pattern (φ ≥ 0) even if the view is signed. No pre-built `uanTbl`.

---

## 7. Dispatcher — one function replaces the refresh family

```matlab
function update(app, scope)
% "source" > "params" > "step" > "span" > "component" > "cut" > "range"
```

This is the **refactoring strategy for control flow**: M7 has a separate method per widget that each re-enters the whole pipeline. M8 classifies the **invalidation radius** of the event.

| User action | scope | Recompute | Render |
|---|---|---|---|
| Load / format / FFD index / Process | `source` or `params` | normalize → resample if 1° → `pat_calc` **once** → `geo_build` | topology path (`cla` only if grid **size** changed) |
| Native vs 1° step | `step` | resample → `pat_calc` → `geo_build` | topology path |
| Elevation / signed-φ | `span` | **nothing** | remap `XData`/`YData` + ticks: θ′=90−θ, φ′=φ−360·(φ>180) |
| Component dropdown | `component` | grid of that column, peak, orientation, metrics | **`CData` only** (rect3D +`ZData`; polar3D radius from cached unit vectors) |
| Cut type/value / E-H / field basis | `cut` | cached extract | cut plots + overlay from the **same** extract |
| Colorbar / cut RLim | `range` | **nothing** | `clim`/`zlim`/`RLim` + ticks |
| Coverage threshold spinner | — | **nothing** on Pattern | `cov_evaluate(dist, T)` |
| Coverage query | — | **nothing** | `cov_query*` + `updateCoverageQuery` handles |

Delete as **bodies** (they become one-liners or vanish): `refresh`, `updateViewResults`, `refreshAngularView`, `applyStep`, `applyAngularSpan`, `stepChanged`, `onComponentChanged`.

Non-selected full-pattern tabs and Data uitables refresh on first show when `renderedRevision ≠ Derived.Revision`.

**Worked contrast — component change on a 1° FFD**

| M7 | M8 |
|---|---|
| `onComponentChanged` → `updateViewResults` → orientation + metrics + tables + `plotCut` + `renderAllFullPatterns` → 5× `cla`/`surf` + 2 menus each 3D + uitable push | `update("component")` → `Derived.Grids(name)` → set `CData` (and polar radius) on existing surfaces; cut lines `YData` if needed |
| 0.8–2 s | ≤ 150 ms |

**Worked contrast — θ-span switch**

| M7 | M8 |
|---|---|
| Clone 17 columns, rewrite Theta, `sortrows`, bump revision, **re-detect orientation on elevation angles**, redraw everything | `View.elevationTheta = true`; rewrite tick labels and `YData` of contour/rect3D; math unchanged |
| Physical boresight can jump | Display invariance (gate item) |

---

## 8. Callbacks and retained-mode graphics

Every user action:

```matlab
function onSomething(app, ~)
try
    cfg = app.readConfig();                 % or readCoverageConfig
    result = <pure>(app.Pattern, app.Geometry, app.Derived, cfg);
    app.applySomething(result);
catch err
    app.showError(err, "…");
end
end
```

- `readConfig()` is the only Main `.Value` reader; `readCoverageConfig()` the only Coverage reader (`component, thresholds, region, cone, orientation, freqIndex, query`).
- Getters are **pure**. Threshold list construction must not write `ThreshMax`; `apply` writes clamped UI.
- One `try/catch` per operation. Math does not `uialert`. POB datatip creation may stay a local graphics fallback.
- `perfTracker` `assignin` only if `APAT_PROFILE` is set.
- Range controls: one descriptor-driven controller. `startupFcn` wires lambdas. No orphaned `createCallbackFcn(@onRangeUIChanged)` with the wrong arity.

**Graphics registry** (create once, update fields):

```matlab
app.Graphics.Full(k).{Axes, Surface, Colorbar, Title, XYZ, POB, CutOverlay}
app.Graphics.Cut.{PolarLines, RectLines, Tips}
app.Graphics.Coverage.Jobs(id).{Line, Query.(mode).{V, H, Tip}}
app.Graphics.ContextMenu     % ONE, startupFcn
```

```matlab
if isgraphics(s.Surface)
    set(s.Surface, 'CData', grid);          % + X/Y/Z when mapping or polar radius
else
    s.Surface = surf/pcolor/polarplot(...); % topology / first draw only
end
```

- `cla` only when topology changes (grid size, number of cut traces).
- Zero `findall`/`findobj` on query, check, colorbar, or datatip paths.
- XYZ triad, colorbar, titles, POB/HPBW: create once; then `DataIndex` / `String` / `Ticks`.
- R2025a WebGL: `CData`/`XData` is the fast path; `cla`+`surf` is the slow path.

---

## 9. Correctness designed in (not a pre-patch)

Do not “fix M7 then refactor.” These defects cannot exist in the pipeline above.

| M7 defect | Why M8 cannot contain it |
|---|---|
| Re/Im rounded to 5 decimals | `pat_normalize` snaps **θ/φ only** |
| θ>180 folded twice | one fold |
| 63-char `makeValidName` cache collisions | no threshold-keyed struct fields |
| Single-cut gain detected as coverage | stricter detector + fixture |
| UAN writes signed φ | export from Pattern, φ ∈ [0,360] |
| Coverage uses FFD block 1 | `freqIndex` required in View/cfg |
| Elevation poisons orientation/metrics | math sees only Pattern |
| `calcPattern` twice; `solidWeights` ×8 | one `pat_calc`, one `geo_build` |
| 2 context menus per 3D render | one menu at startup |
| Getter mutates spinner | pure cfg; apply writes UI |
| Duplicate cut / range / conversion code | one prefixed function each |
| `UserData` flags; status bypass | `View` + `setStatus` only |

---

## 10. Fold / delete (same drop — the concision checklist)

If a name in the right column still exists, the blow is incomplete.

| Keep | Delete |
|---|---|
| `geo_cutGeometry` | `cutGeometry` method |
| `Geometry` | `gridCache`, `emptyGridCache`, `viewSolidAngle`, `viewRevision`, `physicalTheta`, `viewTbl`, `viewBaseTbl`, `patTbl`, `stdTbl`, `uanTbl` |
| `util_fmtNumber` | `fmtStatusAngle` |
| `gainDisplayRange` | `coverageDisplayRange` |
| one range controller | `setCoverageRange` + `syncCoverageXRange` |
| `updateCoverageQuery` | `coverageArtifacts` |
| `fullPatternSpecs` | `fullSliders/fullMins/fullMaxs` |
| `View` | six `UserData` flags, unused `coverageRangeState` fields, `componentBounds`, `orientationMode` |
| `met_resolvePeak(values,pct,excess)` | ignored extra args |
| `update(scope)` | `refresh`, `updateViewResults`, `refreshAngularView`, `applyStep`, `applyAngularSpan` |
| `cov_compute` | `syncCoverageNodeFromView` inside Compute |
| `StandardColumns`, `ReleaseName` | 8 column literals; title `M7.110` |
| numeric coverage table + `ColumnFormat` | `compose('%.2f')` string table |

---

## 11. Refactoring strategy — one blow, one work order

This is **construction order**, not shipped milestones. Nothing is released until §12 is green.

The strategy is **core first, UI last, delete in the same edit**:

1. **New file, local-function core only.** Write `io_/pat_/geo_/cov_/met_/util_` + schema factories. No widgets. Prove them with an extended `runSelfTest` (peak, Ω, CCDF vs N×T, cone, normalize precision, resample identity, display invariance, readers including single-cut gain, cut wrap). At this point M8 math is already the product; the app is a shell.
2. **Paste `createComponents` as-is.** Layout is expensive. Strip `ValueChangedFcn` entries with the wrong arity. Do not rename generated properties.
3. **Install the layer objects** on the app (`Source/Pattern/Geometry/Derived/View/Graphics`), `readConfig` / `readCoverageConfig`, `update(scope)`, retained-mode renderers, one context menu, one range controller.
4. **Retarget every callback** to the thin shape (load, process, FFD, step, span, component, cut, range, coverage compute/query/check/export). `startupFcn` wires ranges and stores Graphics axes handles.
5. **Delete M7 method bodies and table properties in that same edit.** Dual-read (`viewTbl` **and** `Derived.M`) is forbidden. If a §10 name remains, stop — the blow is incomplete.
6. **Run §12.** On failure, fix the destination. Do not resurrect `viewTbl`.

**What this strategy refuses**

- An M7.111 “correctness patch” that still has six tables (you would rewrite those lines twice).
- An interim `viewBaseTbl` clone “until display mapping is ready” (that *is* the expensive view).
- New helpers that wrap widgets (`updateXMinSpinner`). Finish the descriptor.
- Caches keyed on spinner values instead of `(revision, cfg hash)`.

---

## 12. Release gate (`runSelfTest` in the same file)

Returns `name / pass / detail`. All must pass.

| Check | Assertion |
|---|---|
| `peak` | P99.99+6 dB on a spiked synthetic |
| `solidWeights` | Σ dΩ = 4π ± 1e-9; seam weight 0 |
| `ccdfEquivalence` | sorted dist vs legacy N×T **with duplicates**, max \|Δ\| < 1e-12; inverse query round-trips |
| `coneMask` | dot-product ≡ angular-distance, 20 random cones |
| `normalizePrecision` | −120 dB cross-pol bit-exact; θ/φ snapped |
| `resampleIdentity` | native-sample error < 1e-10; irregular path reuses one interpolant |
| `displayInvariance` | polar → elevation / signed-φ: identical boresight, F/B, Ω, spherical & conical coverage |
| `readers` | every extension; single-cut gain CSV is **not** coverage |
| `cutGeometry` | θ-cut wraps through opposite φ |
| `uanExport` | φ ≥ 0 after signed-φ view |
| `graphicsLeak` | `uicontextmenu`, `datatip`, `ColorBar` counts constant across 20 component/cut changes |
| `goldenHash` | `Derived.M` and plot `CData`/`ZData` match M7 on fixtures **except** designed precision/detector/UAN fixes |
| `perf` | 1° FFD: load ≤ 3 s, component ≤ 150 ms, cut ≤ 60 ms, coverage build ≤ 50 ms, re-query ≤ 5 ms |

Also: Code Analyzer clean; ≤ ~3,400 lines; ≤ 8 public methods; §10 names gone.

---

## 13. Risks (handled in the same drop)

| Risk | Handling |
|---|---|
| Matrix vs table drift | `Derived` façade for uitable/export; golden hashes |
| Stale retained surfaces after step/span | `update("source"|"step")` may `cla` if **grid size** changed; span only remaps `XData`/`YData` |
| CCDF `>` vs `≥` | `dist.wSample` tie correction; duplicate-value equivalence test |
| `dictionary` missing | `containers.Map` if `exist('dictionary','class')` is false |
| FFD grids differ by frequency | share Geometry only when Θ/Φ match; else revision bump |
| App Designer property names | leave generated names; alias in `View` |

---

## 14. Outcome

| Metric | M7.110_5 | M8 |
|---|---|---|
| Lines (one file) | 5,200 | ≈ 3,400 |
| Public methods | ~90 | ≤ 8 |
| Pattern copies / refresh | 6 (+2 per coverage node) | 1 canonical + 1 derived matrix |
| `UserData` state flags | 6 | 0 |
| Duplicate algorithms | 8 | 0 |
| Component change (1° FFD) | 0.8–2 s | ≤ 150 ms (`CData`) |
| Threshold / query | full CCDF | ≤ 5 ms lookup |
| Context menus per 3D render | 2 leaked | 0 |
| Known precision / cache / detector bugs | 3 | 0 |

**Out of scope:** new plot types, formats, metrics, per-control helper families, spinner-keyed caches.

The drop is M8 when §12 is green **and** the names in §10 no longer exist in the file.
