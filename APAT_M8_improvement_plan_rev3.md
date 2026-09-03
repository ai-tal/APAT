# APAT M8 — Single-Blow Refactor Plan (revision 3)

**From:** `APAT_v3_M7_110_5.m` — 5,199 lines, one App Designer class, 183 functions (≈95 methods, 34 file-scope functions, ~690 lines of generated layout).
**To:** `APAT_v3_M8.m` — the **same one file**, rebuilt around one dataflow.
**Supersedes:** `APAT_M8_improvement_plan.md` (revision 2). Everything in revision 2 that survived a second, independent line-by-line audit of M7 is kept. What was wrong in revision 2 is corrected in §0.1 (three of those corrections are outright bugs *in the plan*). What was missing is added in §0.2 (defects) and §0.3 (structure).

This is still **one drop**. Do not patch M7. Build the destination, point the UI at it, delete every M7 name the destination replaces.

---

## 0. What changed since revision 2 (second audit)

### 0.1 Revision-2 statements that were wrong, unverifiable, or self-contradictory

| # | Revision 2 said | Verified reality | Consequence for M8 |
|---|---|---|---|
| E1 | §5.4 `geo_build`: `dPh = diff([ph(1); midpoints; ph(end)]); dPh(end)=0` "identical to M7 on uniform grids" | On a 1° grid **with** the seam column the φ widths sum to **359.5°**, not 360° (first column gets ½°, seam gets 0, nothing absorbs the other ½°). `Σ dΩ = 4π·359.5/360` → `IsFullSphere` is **never true** → efficiency permanently `n/a`, and release-gate row 2 would fail on day one | Periodic φ widths must be computed **circularly** (§5.4). Making φ an **open** axis (E5) removes the special case entirely |
| E2 | D1: "sort-based quantile `sorted(ceil(p·n))`", and gate row 1: "identical to M7 `prctile` (< 1e-12)" | MATLAB `prctile` interpolates linearly between order statistics at positions `100·(i−0.5)/n`; `ceil(p·n)` is a different estimator. The two claims contradict each other | Moot: the percentile policy itself is replaced (D22, §5.6). If a prctile-compatible quantile is kept for golden comparison only, use the exact formula in Appendix B |
| E3 | D6: "`solidWeights` assumes a uniform θ step; partial spheres get a truncated last cell and a wrong efficiency" | M7 clamps cell edges at 0°/180° exactly as the plan's "edge-based" formula does; on uniform grids they are identical. The **real** partial-sphere defects are different: negative dΩ in elevation mode (D19), a fabricated hemisphere on 1° resampling (D21), and no `IsFullSphere` gate | Keep edge-based dΩ (needed for non-uniform axes), but fix the stated reasons and add the correct gates |
| E4 | I2: "Interpolate **primitive fields only** (Re/Im Eθ, Eφ)" | Linear Re/Im interpolation of a field with a fast phase slope (antenna offset from the coordinate origin — the common case for vehicle/platform patterns) produces **amplitude nulls / −7 dB errors at midpoints** (D23) | I2 rewritten: resample in the **coherency (Stokes) domain** (§5.3) |
| E5 | I3: "φ=360 seam present as the **last column**, dΩ = 0 on the seam" | A stored seam column forces every integral, export, coverage mask, peak search and `unique` to special-case one column, and caused E1 | I3 rewritten: **open φ axis** `[0,360)`; the closing column is a *display index* (`Map.ColIdx`), never data (§0.3-9) |
| E6 | §5.3 `pat_resample` target axes | Unspecified; M7 (4980–4984) always targets 0..180 × 0..360 and fills holes with `'nearest'` → hemispheric sources are silently extended over the whole sphere | Target = **source domain** at the requested step (§5.3) |
| E7 | I1: "Peak policy: **P99.99 + 6 dB** … applied to a value vector only" | The policy is **resolution-independent** and rejects any *real* beam whose −6 dB footprint is < ~6.5 deg² (HPBW ≲ 2°), even at 0.1° sampling where the beam is perfectly resolved (D22, numbers in §5.6). A 40 dBi dish is reported ~10–17 dB low with the wrong direction | I1 rewritten: **grid-native spatial isolation test** (§5.6). No quantile, no toolbox |
| E8 | §5.1 `Derived.M [N×C]` + `Cols` dictionary + `reshape` everywhere | One more indirection than needed; `reshape(M(:,Cols("…")))` at every consumer | **Grid-native** storage: every derived quantity *is* an `[nθ×nφ]` matrix (§0.3-7). No `reshape`, no index map, no dictionary |
| E9 | §6.1 `params` scope: "`pat_calc` (Geometry reused) → metrics" | Loss is a pure additive offset on gain-like dB grids; Rx settings touch only PLF; Pt/R touch only EIRP/PFD/E_RMS. None of them change peak **indices**, orientation, HPBW, F/B or directivity | **Base / Params split** (§0.3-8): physics once per revision, link budget as O(N) element-wise post-ops |
| E10 | §7 keeps M7's eager render of all five full-pattern plots on every topology pass | Three `surf` on 65k points are the dominant cost of load / step / component changes, and four of the five tabs are hidden at any time | **Dirty-flagged lazy rendering** per tab (§0.3-12) |
| E11 | §10 "Delete `covThresholds` → pure `cov_thresholds`" only | M7's `tMin:step:tMax` accumulates floating error and `interp1` at 1767 throws on duplicate thresholds in loaded result files (D18) | `cov_thresholds` uses `round((max−min)/step)` counting and `unique` |

### 0.2 Defects found in this audit that revision 2 did not list

Line numbers refer to `APAT_v3_M7_110_5.m`.

| # | Where | Defect | M8 mechanism |
|---|---|---|---|
| D17 | 4711–4715 | Gain-only path adds `GainLoss_dB` to **every** column from 3 onward — including AR, phase or any non-gain column present in a generic CSV | Loss applies to `isGainDBColumn` columns only; `pat_applyParams` owns it |
| D18 | 1512–1531, 1767 | Threshold vector `tMin:step:tMax` accumulates floating error (0.1 steps), then `tMax` is appended → near-duplicate last samples; `interp1` in `covRebuildTable` errors on duplicate thresholds from a loaded results file | `cov_thresholds(min,max,step) = min + (0:n)*step, n = round((max−min)/step)`; `unique` on loaded curves |
| D19 | 2810 → 4837–4838, 4845–4848; 631 | With **elevation θ** active, `calcOrientation` computes `solidWeights` and unit vectors from *display* θ ∈ [−90,90]: `cosd(θ−Δ/2) − cosd(θ+Δ/2)` is **negative** for θ < 0 → `viewSolidAngle` has negative weights over half the sphere; cone energies, `Efficiency_pct`, `PeakDirectivity_dB` and `FrontBack_dB` are garbage (the 0–100 % gate hides some of it). Coverage is unaffected only because 1505–1507 recompute with `physicalTheta` | Geometry is built once from **physical** axes (I8); display never reaches math |
| D20 | 835–848 → 888–899 | Selecting the Axial-Ratio component routes `[−30 30]` through scope `"all"`, which also rewrites the **cut** range → cut plots collapse to ±30 dB although cuts never display AR | AR theme applies to full-pattern colour scale only; `RangeGroups` are independent |
| D21 | 4980–4984, 5061–5066 | Resampling always targets 0..180 × 0..360 and fills misses with `'nearest'` → a **hemispheric** source acquires a fabricated back hemisphere (a copy of the θ=90 ring); efficiency/F-B are then computed on invented data | Resample within the **source domain**; `IsFullSphere=false` gates efficiency and F/B |
| D22 | 5085–5139 (policy), 245–246 | P99.99 + 6 dB rejects any beam whose −6 dB footprint is < ~6.5 deg², **independent of grid step** (the 1e-4 tail scales with N exactly as sample density does). Verified: Gaussian beam, 40 dBi — 1° grid / HPBW 1.5°: flagged (excess 10.7 dB); 0.25° grid / HPBW 1.5°: flagged (11.4 dB) although 4-neighbours are within 0.3 dB; 0.1° grid / HPBW 1.0°: flagged (24.7 dB). Reported POB is then the highest sample *below* P99.99 — many dB low, wrong direction, and the outlier mask blanks the whole main lobe from the directivity integral | `met_peak`: a sample is a spike iff it exceeds **all grid neighbours** by more than 6 dB (§5.6). Accepts every resolved beam at any step; flags isolated samples at any step; pole rows handled; toolbox-free |
| D23 | 4954–5059 (I2 design) | Linear Re/Im interpolation of Eθ/Eφ: with a phase slope of 120° per sample (10 λ phase-centre offset at 2° step) the midpoint magnitude is `cos(60°)` = **−6 dB**; at 180° per sample it is a null | Interpolate **coherency parameters** `I, Q, U, V` (slowly varying, physically averageable), reconstruct magnitudes and relative phase exactly; absolute phase from complex interpolation is used **only** for the phase export columns (§5.3) |
| D24 | 4783 | PLF uses `cosd(180)` — i.e. cos 2Δτ = −1, the **worst-case tilt** between wave and antenna ellipses. Correct as a conservative choice, but a magic number and undocumented | `Const.PLFTiltCos = -1` with a doc line; listed in Metadata as "PLF: worst-case tilt" |
| D25 | 4769–4771, 785–800 | Exactly-linear samples get signed AR = **−100 dB**, which the ±30 dB blue-white-red map renders as **saturated LHCP-blue**; neighbouring samples flip sign by round-off → speckle between deep blue and deep red in every linear-polarised region | Undefined sense → `NaN` (rendered as axes background, documented as "linear / sense undefined"). Open decision §14-10 |
| D26 | 4682–4689, 634–642 | E-plane is always the θ-cut at the principal-axis φ and H-plane at φ+90, regardless of polarisation → **swapped** for y-polarised or rotated-linear antennas; ill-defined for CP | `met_planes`: E-plane φ from the polarisation tilt at the peak (`τ = ½·atan2(U, Q)`), H = E+90; fallback to principal axes when AR < 3 dB or gain-only (§5.6) |
| D27 | 4154–4159, 4185–4190, 4913 | FEKO `.ffe` files with several frequency / request blocks are concatenated; `unique(…,'first')` in `normalizePattern` silently keeps block 1. No selector, no warning | `io_ffe` splits on `#Frequency`/`#Request` header lines into `Blocks` exactly like FFD; the frequency dropdown serves both |
| D28 | 345 vs 653 | Cut-value spinner `Step` is set to `max(thetaStep,1)` in `refresh`, then to `min(diff(values))` in `updateCutControl` | `applyChoices` sets it once from `Pattern` |
| D29 | 4886–4888 | θ ∈ [−90,90] is auto-interpreted as **elevation** for every format inside `normalizePattern` (a math function). `.cut` folds first so it is safe there; a generic polar file with negative θ is misread | Reader emits `Source.Meta.ThetaConvention ∈ {polar, elevation, auto}`; `pat_normalize` applies it and Metadata shows the interpretation |
| D30 | 704–711 | `fmtNumber` compact mode prints `-0` for tiny negative values | one `regexprep('^-0$','0')` in `util_fmtNumber` |
| D31 | 1703, 2593–2596 | Inverse query (threshold for a coverage %) uses `interp1` on `unique(coverage,'last')` → on flat CCDF plateaus the answer is an arbitrary point of the plateau; on rising round-off the map is non-monotone | `cov_inverse(d, c)` returns the exact step-function threshold from the distribution (§5.8) |
| D32 | 2142 | Results export writes `Single_Table_DataOut.Data` — the **uitable copy**; with lazy table pushes (§7.3) it would export stale data | Export builds from `Derived` + `View.ResultMask` |
| D33 | 1336 | `cutCols` (a *read* helper) rewrites checkbox `Text` | `applyChoices` labels; `readConfig` reads |
| D34 | 2029–2036 | Coverage-results files loaded through the **Main** Load button restore `Single_EditField_Path` correctly, but the format dropdown visibility is decided in `prepareTextFormat` before the coverage check (282–283) | `io_read` is pure; `applyVisibility` decides afterwards |
| D35 | 1256–1262, 1146, 1268 | Each 3-D render creates 3 `quiver3` + 3 `text` (triad), **two** context menus and a new colorbar | registry, create-once (already in rev-2 §7; counts corrected here: 2 menus + 6 triad objects + 1 colorbar per render) |

### 0.3 Structural ideas added (continuing revision 2's list 1–6)

7. **Grid-native storage.** `Pattern.Eth, Pattern.Eph` (complex) and every `Derived.*` quantity are `[nθ×nφ]` matrices. A φ-cut is `G(i,:)`, a θ-cut is `[G(:,j); flipud(G(1:end-1,j2))]`, CData is `G(:, Map.ColIdx)`, coverage is `G(:)` against `dOmega(:)`. No `reshape`, no linear index, no dictionary, no `sub2ind`, anywhere.
8. **Base / Params split.** `pat_calcBase(Pattern)` is params-free and runs once per `Pattern.Revision`: gain grids at 0 dB loss, AR, phases, polarisation class & pairs, per-column peaks, boresight, HPBW, F/B, directivity, η₀. `pat_applyParams(Base, params)` is element-wise: `+L` on five gain grids, PLF from AR and Rx settings, EIRP/PFD/E_RMS lazily. A loss change costs five `+` operations and a `CData` push.
9. **Open φ axis; closing is display.** `Pattern.Phi ∈ [0,360)`, `Geometry.PhiPeriodic = true` when the last cell wraps to the first. Renderers use `Map.ColIdx = [perm, perm(1)]` to close the surface. Exports, integrals, peaks, coverage and `unique` never see a duplicate column. E1 cannot exist.
10. **Coherency-domain resampling.** Interpolate `I=|Eθ|²+|Eφ|², Q=|Eθ|²−|Eφ|², U=2Re(Eθ Eφ*), V=2Im(Eθ Eφ*)` (linear, in the source domain); reconstruct `|Eθ|, |Eφ|, ∠(Eθ Eφ*)` exactly. RCP/LCP powers, AR, PLF and total gain are functions of these four alone. Absolute phase (export only) from complex interpolation of Eθ.
11. **Spatial peak policy.** Spike ⇔ `G − max(4-neighbours) > 6 dB` on the grid (φ wraps when periodic; pole rows share direction). Resolution-aware by construction, toolbox-free, O(N), and it yields the outlier mask for free.
12. **Dirty-flagged lazy rendering.** `Graphics.Full(k).Key` records `(Revision, ParamsKey, Component, MapKey, RangeKey)` last rendered. `update` renders only the **visible** full-pattern tab; `fullPatternTabChanged` renders a stale tab on selection. Load cost drops by the three hidden `surf` calls.
13. **`applyChoices`.** All data-derived widget *population* (component items, cut spinner limits/step, step dropdown items, FFD/FFE block items, coverage component items, checkbox labels) happens in one method from `Pattern/Derived`. `readConfig` reads, `apply*` writes — no function does both (removes D9, D28, D33).
14. **Polarisation-aware principal planes.** E-plane through the peak along the field tilt; H-plane orthogonal; principal-axis fallback. Correct HPBW E/H for every linear orientation (D26).
15. **Exact coverage queries.** Both directions of the query come from the weighted distribution: `cov_curve(d,T)` and `cov_inverse(d,c)` are O(log N) step-function evaluations; the plotted curve is still the sampled polyline, tips are placed at exact coordinates (D31).

---

## 1. Why M8 is a different program, not a faster M7

Unchanged from revision 2, condensed: M7 re-interprets the same sphere in every consumer (six table copies, display conventions stored *as data* and undone by `physicalTheta` at 8 sites, `gridStep`/`unique` at ≥ 7 sites, `solidWeights` at ≥ 6 sites, nine duplicate algorithms, state in six `UserData` slots, `cla`+`surf`+`findall`+two context menus per 3-D render, a 65k×17 uitable push per component change). Caches bolted on top (`viewRevision`, `gridCache`, `coverageCacheKey`) are local fixes for a global dataflow mistake.

To that list this audit adds: **three of M7's numerical policies are wrong for legitimate inputs** (D19 elevation dΩ, D22 peak policy, D23 resampling), not merely slow. M8 is therefore a correctness release as much as a performance one; the golden-capture step (§11-2) must record these as *designed deltas*.

> **One physical pattern (grid-native). One geometry. One params-free base. One element-wise link layer. One config snapshot. One graphics registry.**
> Math never sees the app. UI never rebuilds math. Display is an index map, not a copy.

---

## 2. One rule

```matlab
cfg    = app.readConfig();          % ONLY place widget .Value is read
result = f(data, cfg)               % app-free, alert-free, widget-free
app.apply(result)                   % ONLY place handles / labels / Items / Limits are written
```

Every callback body is:

```matlab
function onSomething(app, ~)
    app.guard("Title", @() app.update("scope"));
end
```

`guard` owns `try/catch`, cancellation, the busy flag (re-entrancy), and the single `drawnow`.

---

## 3. Invariants (the drop is invalid if any of these move)

| # | Invariant |
|---|---|
| I1 | **Peak policy = spatial isolation:** a sample is a spike iff it exceeds every grid neighbour by more than `Const.PeakExcessDB = 6`. The effective peak is the highest non-spike sample. Both raw and effective peaks appear in Metadata. No quantile, no toolbox |
| I2 | **Resample in the coherency domain** (`I,Q,U,V`) for E-field sources, linear power for gain-only. Never AR / PLF / dB. Target axes = source domain at the requested step. `pat_calcBase` runs **after** resample, exactly once per `Pattern.Revision` |
| I3 | Canonical sphere: polar θ ∈ [0,180] ascending, φ ∈ **[0,360)** ascending, grid-native `[nθ×nφ]`, `PhiPeriodic` detected. Angles snapped to 5 decimals; **fields never rounded** |
| I4 | **Metrics, orientation and coverage boresight are defined on total gain** (or the single gain-only column). Component selection changes plots, tables and the POB marker only |
| I5 | Coverage: `Coverage(T) = 100·Ω(G > T)/Ω_region`, strict `>`, ties exact, from a weighted distribution. Cones use physical unit vectors |
| I6 | Query formatting stays on the query controls; tips show exact query values |
| I7 | Readers produce M7's canonical pack **except** the designed deltas: angle-only rounding, coverage detector, UAN φ ≥ 0, FFE blocks, θ-convention hint |
| I8 | **Display invariance:** toggling elevation θ / signed φ changes zero numbers in `Pattern, Geometry, Derived, Metrics, Coverage` and produces no negative dΩ anywhere |
| I9 | One `.m` file. Structs + prefixed local functions. Base MATLAB only (R2023b baseline) |
| I10 | Zero graphics-object growth across repeated component / cut / span / range / query / tab actions |
| I11 | **Params-free base:** `pat_calcBase` output depends only on `Pattern`. `pat_applyParams` is element-wise and never changes a peak index, boresight, HPBW, F/B or directivity |
| I12 | **Partial-sphere honesty:** efficiency and F/B are `n/a` unless `Geometry.IsFullSphere`; resampling never creates samples outside the source domain |
| I13 | **Readers are pure, `apply*` are the only writers of `Items/Limits/Text/Visible/Enable`** |

---

## 4. Architecture — M7 vs M8

### 4.1 M7 dataflow (today) — unchanged from revision 2 §4.1, with the newly found hazards marked

```
FILE → readPattern → rawTbl + blocks{} → normalizePattern (rounds FIELDS, folds θ twice) → stdTbl
  └─ refresh
     ├─ calcPattern(stdTbl) → patTbl ①               (wasted if resampling)
     ├─ applyStep → resample? (Re/Im, 0..180×0..360, 'nearest' fill ⚠D21 D23) → calcPattern ② → viewBaseTbl
     └─ applyAngularSpan → COPY 17 cols, rewrite θ/φ, sortrows → viewTbl
        ├─ detectOrientation(viewTbl, comp) → solidWeights(DISPLAY θ) ⚠D19  → viewSolidAngle
        ├─ resolvePeak(P99.99+6) ⚠D22 → POB;  calcMetrics(comp peak, total gain, DISPLAY θ) ⚠D19
        ├─ initRanges → "all" → cut range ⚠D20
        ├─ 5× cla + surf + 2 menus + triad + colorbar ⚠D35; uitable ← 65k×17
        └─ Coverage clones viewTbl twice per node; N×T indicator → double (~260 MB)
```

### 4.2 M8 dataflow (destination)

```
FILE ──► io_read(path, fmt) ──► Source { Raw, Blocks(nθ×nφ×4×F | nθ×nφ×1×F), Theta, Phi, Freqs, Meta }
                                   Meta.ThetaConvention, .SynthesizedRevolution, .Regularized
             ▼
        pat_normalize(Source, freqIndex) ──► Pattern { Theta[nθ], Phi[nφ], Eth, Eph (nθ×nφ complex) | G (nθ×nφ),
             │                                          IsGainOnly, FreqIndex, Revision, Meta }
             ▼  (optional)   pat_resample(Pattern, step)  — decimate if exact, else coherency interp  → Revision++
             ▼
        geo_build(Theta, Phi) ──► Geometry { dOmega, Ux, Uy, Uz (nθ×nφ), PhiPeriodic, IsFullSphere, AxesKey }
             ▼
        pat_calcBase(Pattern, Geometry) ──► Base { E_Total_dB, E_TH_dB, E_PH_dB, E_RCP_dB, E_LCP_dB (at L=0),
             │                                     AR_dB, *_Phase, Pol, Pairs, Peaks.(col) = {value,index,mask},
             │                                     Boresight, Planes {ePhi,hType,hValue}, Metrics0, Revision }
             ▼
        pat_applyParams(Base, params) ──► Derived { five gain grids +L, PLF_dB, Gain_PolCorrected_dB,
             │                                       EIRP_dBW / PFD_Wm2 / E_RMS_Vm (lazy), Metrics, ParamsKey }
             ▼
        View = readConfig()        component, cut, span, limits, freqIndex, masks — never copies Pattern
        Map  = geo_displayMap(Geometry, View)   { ThetaAxis, PhiAxis, ColIdx, ThetaDir, labels, ticks }
     ┌──────────┬──────────┬──────────┬──────────┬──────────┐
     ▼          ▼          ▼          ▼          ▼          ▼
   PLOTS     METRICS     CUTS      COVERAGE    EXPORT     TABLES
 G(:,ColIdx)  Base+L   row/col    cov_dist    Pattern/   Derived+mask
 dirty tabs             slices   unique+accum  Derived   (visible only)
```

**Dependency graph (keep as the comment block above `update`):**

```
SOURCE ─► PATTERN(Rev) ─► GEOMETRY(AxesKey) ─► BASE(Rev) ─► DERIVED(Rev, ParamsKey)
                                  │                │              │
                                  │        ┌───────┼──────┐   ┌───┴────┐
                                  ▼        ▼       ▼      ▼   ▼        ▼
                              COV DIST  ORIENT  PLANES  PEAKS  PLOTS  TABLES/EXPORT
                                  │
                              CURVE(T) / INVERSE(c)
VIEW ─► MAP ─► ColIdx / axes / ticks / labels          (touches nothing above)
```

If a function needs something not on a path from its inputs, it is reaching into the app. That line does not belong in M8.

### 4.3 Layer contracts (who may write what)

| Layer | Object | Writer | Readers | Forbidden |
|---|---|---|---|---|
| Source | `app.Source` | `io_read` via load / format / Process | `update("source")` | math, renderers |
| Pattern | `app.Pattern` | `pat_normalize`, `pat_resample` | all below | widget `.Value`, `cla`, display conventions, rounding of fields |
| Geometry | `app.Geometry` | `geo_build` on `AxesKey` miss | base, plots, cuts, coverage | copying Pattern |
| Base | `app.Base` | `pat_calcBase` on `Revision` miss | derived, metrics, coverage | params of any kind |
| Derived | `app.Derived` | `pat_applyParams` on `ParamsKey` miss | plots, tables, export, coverage | changing an index, a mask or an angle |
| View | `app.View` | `readConfig()` only | orchestration, renderers | math kernels |
| Map | `app.Map` | `geo_displayMap(Geometry, View)` | renderers only | anything numeric |
| Choices | widget `Items/Limits/Text` | `applyChoices` only | — | readers |
| CoverageCfg | `readCoverageConfig()` | callbacks | `cov_*` | widget mutation |
| Node | `Cov_Tree` NodeData | coverage `apply*` | tree mirror, job plots | pattern tables (holds a `PatternRef` + its own `Base/Geometry` for foreign files) |
| Graphics | `app.Graphics` | renderers only | renderers only | `findall`/`findobj`/Tag search |

**Validity is one comparison per layer:** `Geometry.AxesKey == geo_axesKey(Pattern)`, `Base.Revision == Pattern.Revision`, `Derived.ParamsKey == jsonencode(params)`, `Graphics.Full(k).Key == currentKey`, `CovDists(distKey)`. No flag families.

### 4.4 Why this is shorter (additions to revision 2 §4.4)

| Concept | M7 | M8 | What vanishes |
|---|---|---|---|
| Component grid | `gridComp` (cache, `ismember`, `sub2ind`, shadowed `pi`) | `Derived.(comp)` **is** the grid | `gridComp`, `gridGeom`, `emptyGridCache`, `invalidateDerived`, every `reshape` |
| Loss / Rx / link change | full `calcPattern` + orientation + metrics + 5 renders | five `+L`, one element-wise PLF, `CData` on the visible tab | nothing to cache |
| Seam | rows appended in `normalizePattern`, zeroed in `solidWeights`, dropped in `applyAngularSpan`, re-added in `cutData` | `Map.ColIdx(end) = ColIdx(1)` | four seam sites |
| Peak | `prctile`, four call sites with `~,~` args | `met_peak(G)` once per column, cached in `Base.Peaks` | `resolvePeak`, toolbox |
| Cut | `cutGeometry` ≡ `calcCutGeometry`, `find(abs(..)<1e-9)`, `unique('stable')`, seam interpolation | `geo_cut`: `nearest` on an axis + two column indices | both twins, `cutData`, `cutCols` |
| Coverage | N×T indicator, `interp1` tables, `unique('last')` inverse | `cov_dist` + `cov_curve` + `cov_inverse` | `coverageCCDF`, `coverageQueryPoint`, `coverageInterpolationLocation`, `coverageCacheKey` |

---

## 5. Data model & pipelines

### 5.1 Schemas (factory functions in section B of the file)

```matlab
Source   = struct('Raw',table(),'Blocks',[],'Theta',[],'Phi',[],'Freqs',NaN,'Meta',struct(), ...
                  'Path','','Name','','Format','')
% Meta: Format, IsGainOnly, IsCoverage, ThetaConvention ("polar"|"elevation"|"auto"), SynthesizedRevolution,
%       Regularized, GainColumns (gain-only: logical per column), Frequency info, Excel summary
Pattern  = struct('Theta',[],'Phi',[],'Eth',[],'Eph',[],'G',[],'IsGainOnly',false,'FreqIndex',1, ...
                  'StepTheta',NaN,'StepPhi',NaN,'Revision',uint64(0),'Meta',struct())
Geometry = struct('dOmega',[],'Ux',[],'Uy',[],'Uz',[],'PhiPeriodic',false,'IsFullSphere',false,'AxesKey',"")
Base     = struct('Cols',struct(),  ...        % Cols.E_Total_dB … each nθ×nφ (gain grids at L = 0)
                  'Peaks',struct(), ...        % Peaks.(col) = struct(value,index,rawValue,rawIndex,mask,wasAdjusted)
                  'Pol',"n/a",'Pairs',struct('Linear',["E_TH","E_PH"],'Circular',["E_RCP","E_LCP"]), ...
                  'Boresight',1,'Planes',struct('ePhi',0,'hType',"Theta",'hValue',90,'source',"principal"), ...
                  'Metrics0',struct(),'Revision',uint64(0))
Derived  = struct('Cols',struct(),'Metrics',struct(),'ParamsKey',"",'Revision',uint64(0))
View     = struct('Component',"E_Total_dB",'CutType',"Theta",'CutValue',0,'CutBasis',"Circular", ...
                  'CutCols',string.empty,'ElevationTheta',false,'SignedPhi',false, ...
                  'GainLim',[-40 10],'CutLim',[-40 10],'ColorStep',5,'OneDegree',false,'FreqIndex',1, ...
                  'ResultMask',logical.empty,'ShowPOB',true,'ShowHPBW',false,'ShowHPBWBounds',false, ...
                  'Overlay',false,'View3D',"iso",'RangeAuto',true)
Map      = struct('ThetaAxis',[],'PhiAxis',[],'ColIdx',[],'ThetaDir','reverse','ThetaLabel',"Theta", ...
                  'PhiLim',[0 360],'ThetaLim',[0 180],'Key',"")
Graphics = struct('Full',struct('Axes',{},'Surface',{},'Colorbar',{},'POBMarker',{},'POBTip',{},'Overlay',{}, ...
                                'Triad',{},'Key',{}), ...
                  'Cut',struct('PolarLines',gobjects(0),'RectLines',gobjects(0),'Regions',gobjects(0), ...
                               'BoundMarkers',gobjects(0),'BoundTips',gobjects(0),'POB',gobjects(0),'Key',""), ...
                  'Cov',dictionary(double.empty,cell.empty),'Menu',gobjects(0))
```

`Base.Cols` / `Derived.Cols` are structs of grids; `fieldnames` is the schema; `isfield` replaces `isKey`; `struct2table(structfun(@(g) g(:), …))` builds the results table at the edge.

### 5.2 Canonicalize — `pat_normalize(Source, freqIndex)`

1. Apply `Meta.ThetaConvention`: `elevation` → θ = 90−θ; `auto` → the M7 heuristic (θ<0 and range ⊂ [−90,90]) **and** `Meta.ThetaInterpreted = "elevation"` is recorded for Metadata; otherwise θ<0 → (−θ, φ+180). Then θ>180 → (360−θ, φ+180). **Once.**
2. `φ = mod(φ,360)`; snap θ, φ to 5 decimals (**angles only**).
3. Dedupe directions (`unique([φ θ],'rows','first')`); pole rows keep all φ samples (grid regularity).
4. Regularity test `nθ·nφ == N`. If false → **one** `scatteredInterpolant` per primitive (`F.Values = column`) onto the native-step grid inside the source hull; `Meta.Regularized = true`.
5. Reshape grid-major: `Eth = reshape(…, nθ, nφ)` with θ down rows, φ across columns, both ascending.
6. **No seam column.** If a φ=360 column was supplied it was folded into φ=0 by step 2/3.

Result: `Pattern.Eth(i,j)` is the field at `(Theta(i), Phi(j))`. Nothing else is ever indexed.

### 5.3 Resample — `pat_resample(Pattern, stepDeg)`

- **Domain:** `θq = Theta(1):step:Theta(end)`, `φq = Phi(1):step:Phi(end)` (+ periodic closure when `PhiPeriodic`: the query wraps through 360 using `[Phi, Phi(1)+360]` as the interpolation axis). Never outside the source hull (D21).
- **Decimate** when both native steps are integer multiples of `step` and the axes contain the target values (bit-exact).
- **E-field:** compute `I, Q, U, V` grids; `interp2` each (linear; periodic column appended on the fly); reconstruct
  `Pθ=(I+Q)/2, Pφ=(I−Q)/2, C=(U+jV)/2`; `ψθ = angle(interp2(Eth))` (complex-linear, phase export only);
  `Eth = √Pθ·e^{jψθ}`, `Eph = √Pφ·e^{j(ψθ − angle(C))}`. Gain, AR, RCP/LCP split and PLF are exact functions of `I,Q,U,V`; only the export phase carries interpolation error (D23).
- **Gain-only:** linear power in, dB out, per gain column; non-gain columns linear.
- `Revision++`; FFD/FFE blocks resampled lazily per `(FreqIndex, step)`.

### 5.4 Geometry — `geo_build(Theta, Phi)` (corrects E1)

```matlab
function G = geo_build(th, ph)
th = th(:); ph = ph(:); nT = numel(th); nP = numel(ph);
% θ cell edges: midpoints, end cells extended by half a step and clamped to the sphere (M7-compatible)
if nT > 1, dT = diff(th); eTh = [max(th(1)-dT(1)/2,0); (th(1:end-1)+th(2:end))/2; min(th(end)+dT(end)/2,180)];
else,      eTh = [0; 180]; end
% φ cell widths: circular when the axis closes on itself, edge-based otherwise
dP = diff(ph);
G.PhiPeriodic = nP > 1 && abs((360 - (ph(end)-ph(1))) - median(dP)) < 1e-6;
if G.PhiPeriodic
    gap = [ph(1)+360-ph(end); dP];                  % gap preceding each sample (wrapped)
    wPh = (gap + gap([2:end 1])) / 2;               % each cell owns half of both adjacent gaps → Σ = 360
elseif nP > 1
    wPh = diff([ph(1)-dP(1)/2; (ph(1:end-1)+ph(2:end))/2; ph(end)+dP(end)/2]);
else
    wPh = 360;
end
G.dOmega = (cosd(eTh(1:end-1)) - cosd(eTh(2:end))) * deg2rad(wPh).';    % nθ×nφ, all ≥ 0
G.IsFullSphere = abs(sum(G.dOmega,'all') - 4*pi) < 1e-6*4*pi;
[P, T] = meshgrid(ph, th);
G.Ux = sind(T).*cosd(P); G.Uy = sind(T).*sind(P); G.Uz = cosd(T);
G.AxesKey = geo_axesKey(th, ph);                    % e.g. jsonencode({th, ph}) hashed
end
```

Uniform 1°: `wPh ≡ 1`, `Σ = 360°`, Σ dΩ = 4π; identical to M7 on every uniform full-sphere fixture (gate row 2 now provable). Hemisphere: Σ ≈ 2π(1 + ½Δθ·sin 90°) → `IsFullSphere = false`. Non-uniform and partial φ spans handled without branches elsewhere. `dOmega ≥ 0` always (D19 impossible).

### 5.5 Derive — `pat_calcBase(Pattern, Geometry)` and `pat_applyParams(Base, params)`

`pat_calcBase` (same physics as M7 4723–4800, at `FieldScale = 1`):

- `Pθ, Pφ, C = Eth.*conj(Eph)`; `I, Q, U, V`; `Prcp = (I+V)/2`, `Plcp = (I−V)/2`; total `I`.
- dB via one `util_db(P) = 10*log10(max(P, Const.PowerFloor))`.
- Signed AR from `√Prcp, √Plcp` as M7; exactly-linear samples → `NaN` (open decision §14-10) instead of −100.
- **Ω-weighted** polarisation class and pairs: `sum(P.*dOmega,'all')` per component (D5).
- `Peaks.(col) = met_peak(grid, 6, PhiPeriodic)` for every gain-like column, lazily on first request but always for `E_Total_dB`.
- `Boresight = met_orientation(E_Total_dB, Geometry, Peaks.E_Total_dB)`.
- `Planes = met_planes(Pattern, Peaks.E_Total_dB, Boresight)` (D26).
- `Metrics0 = met_metrics(Base, Geometry)`: HPBW E/H from `geo_cut` slices, F/B from `min(Ux·ux+Uy·uy+Uz·uz)`, directivity, `η0` (only if `IsFullSphere`), AR at peak.

`pat_applyParams(Base, params)`:

```matlab
L = params.GainLoss_dB;
for c = ["E_Total_dB","E_TH_dB","E_PH_dB","E_RCP_dB","E_LCP_dB"], D.Cols.(c) = Base.Cols.(c) + L; end
D.Cols.AR_dB = Base.Cols.AR_dB;  % phases copied by reference (MATLAB COW — no cost)
D.Cols.PLF_dB = met_plf(Base.Cols.AR_dB, params.RxMode, params.RxAR_dB, Base.Pairs, Const.PLFTiltCos);
D.Cols.Gain_PolCorrected_dB = D.Cols.E_Total_dB + D.Cols.PLF_dB;
% EIRP_dBW / PFD_Wm2 / E_RMS_Vm are added by pat_applyLink(D, params) only when ResultMask or export asks
D.Metrics = Base.Metrics0;  D.Metrics.PeakGain_dB = Base.Peaks.E_Total_dB.value + L;
D.Metrics.Efficiency_pct = Base.Metrics0.Efficiency_pct * 10^(L/10);
D.ParamsKey = jsonencode(params);
```

Gain-only: `+L` only on `Meta.GainColumns` (D17).

### 5.6 Metrics — `met_*`

**`met_peak(G, excessDB, periodicPhi)`** — the I1 policy (replaces `resolvePeak` and `prctile`):

```matlab
function P = met_peak(G, excessDB, periodicPhi)
nb = -inf(size(G));
nb(2:end,:)   = max(nb(2:end,:),   G(1:end-1,:));           % θ neighbours
nb(1:end-1,:) = max(nb(1:end-1,:), G(2:end,:));
if periodicPhi, Lf = circshift(G,1,2); Rt = circshift(G,-1,2);
else, Lf = [-inf(size(G,1),1) G(:,1:end-1)]; Rt = [G(:,2:end) -inf(size(G,1),1)]; end
nb = max(nb, max(Lf, Rt));                                    % φ neighbours
P.mask = isfinite(G) & (G - nb > excessDB);                   % isolated spikes
[P.rawValue, P.rawIndex] = max(G(:), [], 'omitnan');
cand = G; cand(P.mask) = -Inf; [P.value, P.index] = max(cand(:));
P.wasAdjusted = P.mask(P.rawIndex); P.spikeCount = nnz(P.mask);
end
```

Verified behaviour (Gaussian 40 dBi beam): 1°/1.5° HPBW → accepted (P99.99 rejected it); 0.25° and 0.1° grids → accepted; 1°/1.2° HPBW → flagged as **unresolved** (neighbours −8.4 dB) — correctly, and Metadata says "peak adjusted: unresolved/isolated (n samples)". Pole rows: all φ share a direction, so the row's neighbours are each other → never falsely isolated. Isolated single-sample spikes are flagged at every step.

**`met_planes(Pattern, peak, boresight)`** (D26): at the peak, `τ = ½·atan2(U, Q)` (tilt of the polarisation ellipse relative to θ̂). E-plane = θ-cut at `φ_E = nearestPhi(Phi(jpeak) + τ)` when `AR_dB(peak) ≥ 3` and E-field data exist; H-plane = `φ_E + 90` (or the φ-cut at the boresight ring for ±X/±Y boresights, as M7 634–642). Fallback = M7's principal-axis planes; `Planes.source ∈ {"polarization","principal"}` is shown in Metadata.

**`met_orientation`**, **`met_hpbw`** as revision 2. **`met_metrics`** gates `Efficiency_pct` and `FrontBack_dB` on `IsFullSphere` (I12).

### 5.7 Cuts — `geo_cut(Pattern, Derived, type, value, cols)`

Grid-native:

- **Phi cut** (fixed θ): `i = nearest(Theta, value)`; `angle = Phi`; `data = D.(c)(i,:).'`; closed for display by `Map.ColIdx`.
- **Theta cut** (fixed φ): `j = nearest(Phi, mod(value,360))`, `j2 = nearest(Phi, mod(Phi(j)+180,360))`; `angle = [Theta; 360 − Theta(end−1:−1:1)]`; `data = [D.(c)(:,j); D.(c)(end−1:−1:1, j2)]` (pole at 180 once, 0 and 360 both present).
- Returns `struct(angle, theta, phi, data, fixedAngle, symbol, snapped)`; pure; cached per `(Revision, ParamsKey, type, value, cols)`. One extract feeds the two 2-D cut axes **and** both 3-D overlays (rev-2 audit item "×3").

### 5.8 Coverage — `cov_*`

```matlab
function d = cov_dist(G, dOmega, mask)                    % O(N log N), once per distKey
v = mask(:) & isfinite(G(:)) & dOmega(:) > 0;
[gu, ~, ic] = unique(G(v));                               % ties collapse → strict '>' exact
wu = accumarray(ic, dOmega(v)); W = sum(wu);
d.g = gu; d.S = [flip(cumsum(flip(wu))); 0] * (100/W);    % S(k) = 100·Ω(G ≥ gu(k))/W, S(end) = 0
d.W = W;
end
function c = cov_curve(d, T)                              % O(T log N)
k = discretize(T(:), [-Inf; d.g; Inf]);  c = d.S(k);      % 100·Ω(G > T)/W
end
function T = cov_inverse(d, c)                            % exact threshold for coverage c (D31)
% largest threshold whose coverage is still ≥ c: S is non-increasing in k
k = arrayfun(@(cc) find(d.S >= cc, 1, 'last'), c(:));      % k ≤ n+1
T = nan(size(c)); ok = k <= numel(d.g); T(ok) = d.g(k(ok));
end
```

- `distKey = sprintf('%d|%s|%s|%s', Revision, ParamsKey, component, coneKey)` — but since loss is additive, the dist for `(Revision, component)` at L=0 is shared and thresholds are shifted by `−L` at evaluation. One dist per `(Revision, component, coneKey)`.
- Cone mask: `Ux*cx + Uy*cy + Uz*cz >= cosd(α)`.
- Threshold spinners → `cov_curve` only. Table union of checked jobs → exact per-job re-evaluation. Queries → `cov_curve` / `cov_inverse`, tips at exact coordinates on the sampled polyline (§14-5).
- `cov_thresholds(min,max,step)`: `n = round((max−min)/step); T = min + (0:n)'*step; if T(end) < max − 1e-9, T(end+1) = max; end` (D18). Loaded result files pass through `unique`.
- Foreign coverage files: the node owns its own `Pattern/Geometry/Base` built by the same `pat_*/geo_*` functions at load; the Main node holds a `PatternRef` and reads `app.Base/Geometry`.

### 5.9 Import — `io_*`

Revision 2 §5.9 stands (descriptor table, `readmatrix`, one RHCP↔θφ kernel, one mag/phase kernel, stricter coverage detector, `.cut` synthesis flagged). Additions:

- `io_ffe`: split FEKO files on `#Frequency:` / `#Request Name:` header lines into `Blocks(:,:,:,f)` with `Freqs` (D27).
- Every reader fills `Meta.ThetaConvention` (`polar` for UAN/FZ/OUT/FFS/FFE/FFD/Excel; `auto` for generic text and `.cut` after its own fold) (D29).
- Gain-only readers fill `Meta.GainColumns = isGainDBColumn(names)` (D17).
- Header names for generic text are read with one `fgetl` before `readmatrix`, so the coverage-header rule still works.

### 5.10 Export — lazy, canonical

- Results: `Derived.Cols` masked by `View.ResultMask`, θ/φ from `Pattern` (physical), built on click (D32).
- UAN: from `Pattern` (φ ∈ [0,360), no seam), 5 dp, φ-major; `maximum_gain` per §14-4.
- Cut: from the cached extract. Coverage: numeric table + `ColumnFormat`.

---

## 6. Orchestration

### 6.1 `update(app, scope)` — the dispatcher

| User action | scope | Recompute | Render |
|---|---|---|---|
| Load / Process / text format | `source` | `io_read` → `pat_normalize` → (resample if 1°) → `geo_build` (AxesKey miss) → `pat_calcBase` → `pat_applyParams` | `applyChoices`, `applyVisibility`, metadata, ranges preset (`RangeAuto`), **visible** full tab, cuts, tables if visible |
| FFD/FFE block | `freq` | `pat_normalize(block)` → geometry shared if `AxesKey` equal → base → params | as `source` minus choices |
| Native ↔ 1° | `step` | `pat_resample` → `geo_build` → base → params | as `freq` |
| Loss / Pt / R / Rx | `params` | `pat_applyParams` (element-wise) | `CData` on visible tab, cut `YData`, metadata rows, tables if visible; auto-range shifts by L only if `RangeAuto` |
| Component | `component` | `Base.Peaks.(col)` (cached) | `CData` visible tab (+ radius on polar-3D, `ZData` rect-3D), POB, titles, colorbar theme |
| Elevation / signed φ | `span` | **nothing numeric**; `geo_displayMap` | `CData(:,ColIdx)`, axes vectors, ticks, labels, cut `XData` remap, POB re-index |
| Cut controls | `cut` | `geo_cut` (cached) | 2-D cut lines + both overlays from one extract, HPBW |
| Ranges / colour step | `range` | nothing | `clim/zlim/RLim` + ticks of the visible tab; other tabs marked dirty |
| POB / HPBW / tab change | `annot` | nothing | visibility of registry handles; **stale tab → render on selection** |
| 3-D view | `camera` | nothing | `view/camup` |
| Coverage thresholds | — | `cov_curve` | line `YData` |
| Coverage query | — | `cov_curve` / `cov_inverse` | query lines / tips (registry) |

Ladder: `source ⊃ freq ⊃ step ⊃ params ⊃ component ⊃ {span, cut, range, annot, camera}`. `update` runs the stages at or below the requested rung, marks every non-visible full-pattern tab dirty, renders the visible one, then **one** `drawnow limitrate`.

Deleted bodies: `refresh`, `updateViewResults`, `refreshAngularView`, `applyStep`, `applyAngularSpan`, `stepChanged`, `onComponentChanged`, `renderAllFullPatterns`, `drawSpatial3D`, `initRanges`, `selectBlock`, `activateSource`.

**Worked contrast — loss spinner on a 1° FFD**

| M7 | M8 |
|---|---|
| `refresh` → `calcPattern` (complex math on 65k) → orientation → metrics → 5× `cla/surf` → tables → cuts | five matrix adds → `CData` on one surface → cut `YData` → 4 metadata strings. ≤ 30 ms |

### 6.2 Callback shape, guard, visibility, choices

```matlab
function guard(app, title, fn)                     % the only try/catch in the UI layer
if app.isClosing || app.Busy, return; end          % re-entrancy: drawnow/timers cannot re-enter a stage
app.Busy = true; c = onCleanup(@() app.setBusy(false));
try, fn(); drawnow limitrate
catch err
    if err.identifier == "APAT:Cancelled", app.setStatus(app.Single_StatusBar,'Cancelled.',true);
    else, app.showError(err, title); end
end
end
```

- `readConfig()` / `readCoverageConfig()` — the only `.Value` readers; pure.
- `applyChoices(app)` — the only writer of `Items/ItemsData/Limits/Step/Text` derived from data (§0.3-13).
- `applyVisibility(app)` — the only writer of `Visible/Enable`, computed from `Source.Meta`, `View`, coverage state.
- Long stages receive a `checkpoint` handle; `perf` recording only when `getenv("APAT_PROFILE")` is set.

### 6.3 Range controller, 6.4 Status & lifecycle

As revision 2, with one correction: the AR theme changes **only** the full-pattern colour scale (`RangeGroups.full` with `ARLimits`), never `RangeGroups.cut` (D20). `View.RangeAuto` becomes false the first time the user edits a full-pattern range; presets are re-applied only on `source/freq/step`.

---

## 7. Rendering — retained mode

### 7.1 Registry and dirty flags

`Graphics.Full(k).Key = strjoin([Revision, ParamsKey, Component, Map.Key, RangeKey], "|")`. Recipe:

```matlab
function renderFull(app, k)
key = app.currentFullKey(k); s = app.Graphics.Full(k);
if s.Key == key, return; end
G = app.Derived.Cols.(app.View.Component)(:, app.Map.ColIdx);
if isgraphics(s.Surface) && isequal(size(s.Surface.CData), size(G)), set(s.Surface, 'CData', G, <coords>);
else, cla(s.Axes); s.Surface = <surf|pcolor|surface>(...); s.Surface.ContextMenu = app.Graphics.Menu; <triad once>; end
<theme, ticks, labels, POB DataIndex, overlay from cut extract>
app.Graphics.Full(k).Key = key;
end
```

`fullPatternTabChanged` → `renderFull(selected)`; `update` → `renderFull(visible)` only. POB marker/tip per tab created once; `DataIndex` updated. Cut lines: three per axes created once, unused `Visible='off'`. One `uicontextmenu`, one triad per 3-D axes, one colorbar per axes.

### 7.2 Display map — exact permutation (fixes rev-2's "fixed in code")

```matlab
function m = geo_displayMap(G, V, ph, th)
nP = numel(ph);
if V.SignedPhi
    j0 = find(ph >= 180, 1);                       % first column at or beyond 180°
    perm = [j0:nP, 1:j0-1];                        % 180…359, 0…179   → −180…179
    m.PhiAxis = ph(perm); m.PhiAxis(1:nP-j0+1) = m.PhiAxis(1:nP-j0+1) - 360; m.PhiLim = [-180 180];
else
    perm = 1:nP; m.PhiAxis = ph; m.PhiLim = [0 360];
end
if G.PhiPeriodic, m.ColIdx = [perm perm(1)]; m.PhiAxis(end+1) = m.PhiAxis(1) + 360;   % closing column
else,             m.ColIdx = perm; end
m.ThetaAxis = th; m.ThetaDir = 'reverse'; m.ThetaLim = [0 180]; m.ThetaLabel = "Theta";
if V.ElevationTheta, m.ThetaAxis = 90 - th; m.ThetaDir = 'normal'; m.ThetaLim = [-90 90]; m.ThetaLabel = "Elevation"; end
m.Key = sprintf('%d|%d', V.SignedPhi, V.ElevationTheta);
end
```

Rendering = `CData = G(:, ColIdx)`, `XData = PhiAxis`, `YData = ThetaAxis`. Fisheye / 3-D spherical / 3-D polar geometry is physical; only tick labels change. `ColIdx(1:end-1)` is asserted to be a permutation in the self-test.

### 7.3 Tables

As revision 2 (push only when the Results tab is visible and the key changed; numeric matrix + `ColumnName`). Export never reads the uitable (D32).

---

## 8. Correctness designed in (merged table)

| M7 defect | Why M8 cannot contain it |
|---|---|
| Fields rounded to 5 dp (4904) | `pat_normalize` snaps angles only |
| θ folded twice (4895, 4908) | one fold, one convention hint |
| Metrics mix component peak with total gain (2810→4609) | I4 |
| Orientation / dΩ on elevation θ, negative weights (4837–4848, D19) | Geometry from physical axes once; `dOmega ≥ 0` asserted |
| P99.99 rejects resolved pencil beams (D22) | spatial `met_peak` |
| Re/Im interpolation nulls (D23) | coherency-domain resample |
| Fabricated hemisphere on resample (D21) | source-domain targets; `IsFullSphere` gates |
| Loss added to non-gain columns (D17) | `Meta.GainColumns` |
| AR selection collapses cut range (D20) | independent range groups |
| Fixed E/H planes (D26) | `met_planes` |
| `prctile` dependency; `pi` shadowed; unweighted polarisation; `makeValidName` cache keys; single-cut CSV as coverage; UAN signed φ; coverage on FFD block 1; overlay radius mismatch; `cutData` ×3; 3-D drawn twice on load; menus/triads/colorbars leaked; readers writing widgets; `Cov_Button_LoadPushed` outside try; timer per message; `assignin`; duplicate range/display/cut algorithms; version drift | as revision 2 §8 |
| Threshold float drift / `interp1` duplicates (D18) | `cov_thresholds`, `unique` |
| Inverse query on plateaus (D31) | `cov_inverse` |
| FFE blocks merged (D27) | `io_ffe` |
| Export from uitable (D32) | export from `Derived` |
| −100 dB linear AR rendered as LHCP (D25) | `NaN` + background colour (pending §14-10) |

---

## 9. Destination file layout

```
classdef APAT_v3_M8 < matlab.apps.AppBase
  %% A  UI component properties           generated; do not hand-rename
  %% B  Constants + schema factories       Const (PeakExcessDB=6, ConeHalfAngleDeg=45, PowerFloor, Bounds=[-250 100],
  %%                                       ARLimits=[-30 30], AutoRangeSpanDB=50, AngleDecimals=5, PLFTiltCos=-1,
  %%                                       PrincipalAxes, HiddenOutputColumns, Formats, Defaults, ReleaseName)
  %%                                       newSource/newPattern/newGeometry/newBase/newDerived/newView/newMap/newGraphics
  %% C  State properties (private)         Source, Pattern, Geometry, Base, Derived, View, Map, Graphics, CutCache,
  %%                                       CovDists, RangeGroups, StatusTimer, OperationDialog, Busy, isClosing
  %% D  Orchestration (private)            readConfig, readCoverageConfig, update(scope), applyChoices, applyVisibility,
  %%                                       applyRanges, applyMetadata, applyTables, applyCoverageResult, guard, setStatus,
  %%                                       shutdown
  %% E  Callbacks (private)                one-liners
  %% F  Renderers (private)                renderFull(k), renderCut, renderOverlay, renderPOB, renderCoverageJob,
  %%                                       renderQuery — write app.Graphics.* only
  %% G  Public API                         ctor, delete, closeRequest;  Static: selfTest, version
  %% H  createComponents                   generated layout; no ValueChangedFcn on range widgets
end

%% Local functions — app-free, alert-free, H1 one-liner, ≤ ~60 lines each
%%   io_*    io_read, io_columns, io_fieldsToComplex, io_toThetaPhi, io_ffd, io_ffe, io_graspCut, io_excelMatrix,
%%           io_excelSummary, io_isCoverageTable, io_findHeaderLines
%%   pat_*   pat_normalize, pat_resample, pat_decimate, pat_stokes, pat_fromStokes, pat_calcBase, pat_applyParams,
%%           pat_applyLink, pat_validate
%%   geo_*   geo_build, geo_axesKey, geo_displayMap, geo_cut, geo_coneMask
%%   met_*   met_peak, met_orientation, met_planes, met_metrics, met_hpbw, met_plf
%%   cov_*   cov_dist, cov_curve, cov_inverse, cov_thresholds, cov_validate
%%   util_*  util_fmtNumber, util_db, util_ticks, util_clampRange, util_displayRange, util_plotTheme,
%%           util_arColormap, util_coneLabel, util_nearest
```

**Size budget (lines):** UI layout 690 · io 360 · pat/geo/met/cov 470 · orchestration + apply 420 · renderers 340 · callbacks 110 · schemas/constants 120 · selfTest 240 · comments/headers 200 → **≈ 2,950** (≤ 3,000 stands).

---

## 10. Fold / delete (additions to revision 2 §10)

| Keep | Delete |
|---|---|
| `met_peak` | `resolvePeak`, `prctile`, `PeakPercentile`, `PeakMaxExcessDB` (→ `Const.PeakExcessDB`) |
| `pat_calcBase` + `pat_applyParams` | `calcPattern`, `getParam` (→ part of `readConfig`), `FieldScale` |
| `Derived.Cols.(name)` grids | every `reshape`, `gridComp`, `gridGeom`, `gridCache`, `viewSolidAngle` |
| `Map.ColIdx` | seam rows in `normalizePattern` (4915–4917), seam zeroing in `solidWeights` (5173–5174), seam handling in `applyAngularSpan` (445–451) and `cutData` (1368–1380) |
| `met_planes` | `planeSettings`, the E/H branch in `calcMetrics` (4671–4683) |
| `cov_inverse` | `inverseCov/inverseThr` fields, `coverageQueryPoint`, `coverageInterpolationLocation` |
| `applyChoices` | `updateComponentItems`, `updateCutControl`, `cutCols` label writes, step-dropdown writes in `refresh` (332–345), FFD item writes in `onLoad` (2043–2050) |
| `Graphics.Full(k).Key` | eager `renderAllFullPatterns` loop, `fullPatternSpecs().render` |
| `Const.PLFTiltCos` | literal `cosd(180)` |

Rule unchanged: if a name in the right column still exists in the file, the blow is incomplete.

---

## 11. Refactoring strategy — one blow, one work order

1. **Core first, no widgets.** Section B factories and every `io_/pat_/geo_/met_/cov_/util_` local function. Prove them with the Static `selfTest` (§12 rows 1–20).
2. **Golden capture from M7** on the fixture set (`Derived`-equivalent tables, metrics, coverage curves, plot `CData`). The `goldenHash` row compares with the **designed deltas** listed in code: angle-only rounding, Ω-weighted polarisation, edge dΩ on non-uniform axes, metrics on total gain, coverage detector, UAN φ, **spatial peak policy**, **coherency resampling**, **source-domain resampling**, **polarisation-aware planes**, **NaN linear AR**, **gain-only loss on gain columns only**.
3. **Paste `createComponents`** minus range-widget `ValueChangedFcn`; title from `Const.ReleaseName`.
4. **State + orchestration**: properties, `readConfig`, `readCoverageConfig`, `update`, `applyChoices`, `applyVisibility`, `applyRanges`, `guard` (with `Busy`), `shutdown`, one timer, one menu, `RangeGroups`.
5. **Renderers** in retained mode with dirty keys; verify I10 and the lazy-render equivalence before wiring more callbacks.
6. **Retarget every callback** to the one-liner shape.
7. **Coverage**: nodes hold `PatternRef` or their own `Pattern/Geometry/Base`; distributions in `app.CovDists`.
8. **Delete §10 names in the same edit.** `grep` the right columns of both §10 tables: any hit → stop.
9. **Run §12.** Fix the destination; never resurrect `viewTbl`.

**What this strategy refuses** — unchanged (no M7.111 patch, no interim clones, no widget-wrapping helpers, no spinner-keyed caches, no toolbox calls). Added: **no stored seam column "for convenience"**, **no Re/Im resampling path "for compatibility"**, **no percentile fallback in `met_peak`**.

---

## 12. Release gate (`APAT_v3_M8.selfTest()` — Static, no UI)

Returns a table `name / pass / detail`. All must pass.

| # | Check | Assertion |
|---|---|---|
| 1 | `peakSpatial` | Gaussian 40 dBi beam: (1°, HPBW 1.5°), (0.25°, 1.5°), (0.1°, 1.0°) → `wasAdjusted=false`, value 40 ± 1e-9, correct index; (1°, 1.2°) → `wasAdjusted=true`, `spikeCount ≥ 1`; single isolated +10 dB sample on a flat 100k grid → adjusted, `rawIndex` = spike; pole-row uniform values never flagged |
| 2 | `solidAngle` | `Σ dΩ = 4π ± 1e-9` on 1°, 2°, 5°, 0.5° and a non-uniform θ axis; **`Σ wPh = 360` exactly on periodic axes**; hemisphere `Σ ≈ 2π(1+½Δθ)` with `IsFullSphere=false`; half-plane φ ∈ [0,180] with `PhiPeriodic=false`; `all(dOmega ≥ 0)` including after an elevation-θ source |
| 3 | `gridNative` | `Pattern.Eth(i,j)` equals the meshgrid-built field; no φ=360 column; `Map.ColIdx(1:end-1)` is a permutation for both spans; `ColIdx(end)==ColIdx(1)` iff periodic |
| 4 | `ccdfEquivalence` | `cov_curve` vs legacy N×T (with ties and duplicates) max |Δ| < 1e-12 on 3 fixtures; strict `>` at a tie threshold |
| 5 | `coverageInverse` | `cov_curve(d, cov_inverse(d,c)) ≥ c` and `cov_curve(d, nextafter(T)) < c` for 50 random c; plateau case returns the plateau's upper threshold |
| 6 | `coneMask` | dot-product mask ≡ angular-distance mask on 20 random cones |
| 7 | `normalizePrecision` | −120 dB cross-pol Re/Im bit-exact after normalize; angles snapped; one fold (θ=200 → 160, φ+180); `ThetaConvention` honoured and reported |
| 8 | `resampleCoherency` | Synthetic field with 120°/sample phase slope, 2° → 1°: max |ΔGain| < 0.01 dB, max |ΔAR| < 0.01 dB, RCP/LCP split < 0.01 dB vs analytic (Re/Im path would show ≈ 6 dB dips); native samples bit-exact on the decimation path; hemisphere in → hemisphere out (no rows beyond θ=90) |
| 9 | `displayInvariance` | polar → elevation / signed φ: identical `Base`, `Derived`, boresight, F/B, Ω, spherical & conical coverage |
| 10 | `metricsSemantic` | metrics with `View.Component="AR_dB"` equal metrics with `"E_Total_dB"` |
| 11 | `paramsSplit` | `pat_applyParams(pat_calcBase(P), L)` ≡ M7-style `calcPattern(FieldScale=10^(L/20))` on every column < 1e-10; peak indices, boresight, HPBW, F/B, directivity unchanged for L ∈ {−10, 0, 7.3}; efficiency scales by `10^(L/10)` |
| 12 | `polarizationWeighted` | pole-dense synthetic that M7 misclassifies is classified by Ω-weighted power |
| 13 | `planes` | x-polarised, y-polarised and 37°-rotated linear dipoles at +Z: E-plane φ = 0, 90, 37 (±grid snap); CP source falls back to principal planes with `Planes.source="principal"` |
| 14 | `readers` | every extension via temp fixtures; single-cut gain CSV is a pattern; FFD 2-block → `Blocks` nθ×nφ×4×2 and `Freqs`; **FFE 2-frequency file → 2 blocks**; gain-only CSV with an `AR` column: loss applied to gain columns only |
| 15 | `cutGeometry` | θ-cut wraps through the opposite φ with 0 and 360 both present and 180 once; φ-cut at θ=90 returns one row; identical extract feeds overlays |
| 16 | `thresholds` | `cov_thresholds(-40,10,0.1)` has 501 samples, `T(end)==10` exactly; loaded curve with duplicate thresholds evaluates without error |
| 17 | `uanExport` | φ ∈ [0,360), no seam, φ-major, after a signed-φ view; `maximum_gain` per §14-4 |
| 18 | `arLinear` | exactly-linear field: `AR_dB` is `NaN` (or the chosen sentinel per §14-10) and no sign speckle across a linear region |
| 19 | `lazyRender` (UI, optional) | after load only the selected tab has a surface; selecting each other tab creates its surface once with `CData` equal to eager rendering; 20 cycles of component/span/range/tab → constant object counts (I10) |
| 20 | `goldenHash` (fixtures) | matches M7 captures except the designed deltas listed in code |
| 21 | `perf` (UI, optional) | 1° FFD: load ≤ 2 s (one visible tab), component ≤ 120 ms, **loss ≤ 30 ms**, span ≤ 100 ms, cut ≤ 60 ms, coverage dist ≤ 50 ms, re-curve ≤ 5 ms, query ≤ 5 ms |

Also: Code Analyzer clean; ≤ 3,000 lines; ≤ 6 public methods; §10 names gone; `grep -c "findall\|findobj\|UserData\|reshape\|prctile" APAT_v3_M8.m` → 0 outside `createComponents`.

---

## 13. Risks & platform baseline

| Risk | Handling |
|---|---|
| Coherency reconstruction slightly over-states polarisation purity between samples (pure-state reconstruction of a partially polarised interpolant) | bounded by the interpolation cell; `pat_calcBase` may consume the degree-of-polarisation grid directly later — the Stokes grids are already there. Gate row 8 bounds AR error |
| Spatial peak policy flags genuinely unresolved beams | that is the truth; Metadata shows raw and effective peak with "unresolved/isolated" wording and the spike count; owner decision §14-1 |
| Edge dΩ on partial spheres extends the last ring by half a step | M7-compatible; documented; `IsFullSphere` and Metadata show the sampled Ω |
| Grid-native storage vs. irregular sources | regularised once at import with a Metadata flag (M7 could not render them anyway) |
| Stale retained surfaces after step/source | keys include `Revision`; `cla` only when `size(CData)` changes |
| Signed-φ permutation | gate row 3 |
| FFD/FFE grids differ by frequency | `AxesKey` miss → new Geometry |
| MATLAB release | **R2023b baseline** (`uislider('range')` already requires it); `dictionary`, `xregion/thetaregion`, `datatip InterpolationFactor` available |
| Toolboxes | none. `prctile` removed by design; `interp2`, `scatteredInterpolant`, `discretize`, `accumarray`, `circshift`, `jsonencode` are base MATLAB |

---

## 14. Open decisions for the owner (answer before step 1) — with recommendations

1. **Peak policy** — adopt the spatial isolation test (recommended; designed delta) or keep P99.99 + 6 dB (known to mis-report high-gain antennas, §5.6)? If kept, at minimum apply it per θ-ring density or scale the percentile with the beam footprint.
2. **Resampling domain** — coherency (`I,Q,U,V`) (recommended) or Re/Im?
3. **Seam** — open φ axis with `Map.ColIdx` closure (recommended) or stored 360 column?
4. **UAN `maximum_gain`** — M7 semantics (max of E_TH/E_PH) or peak total gain (recommended: total; it is what XGTD normalises against).
5. **Coverage queries** — exact step-function values from the distribution (recommended) or interpolate on the displayed polyline (M7)?
6. **Partial-sphere efficiency / F-B** — `n/a` with a Metadata note (recommended) or value + "partial sphere" suffix?
7. **Body-of-revolution `.cut` synthesis** — keep with a Metadata flag (recommended) or refuse single cuts?
8. **Cut-value spinner units** — display units converted to physical in `readConfig` (recommended) or always physical?
9. **Results table** — push only when visible (recommended) or always?
10. **Signed AR of exactly-linear samples** — `NaN` rendered as axes background with a legend note (recommended), or M7's −100 dB (renders as LHCP-blue), or a dedicated third colour?
11. **E/H-plane definition** — polarisation-aware with principal-axis fallback (recommended) or M7's fixed principal planes?
12. **Lazy tab rendering** — on (recommended) or eager (M7)?
13. **PLF tilt assumption** — keep worst-case (`cos 2Δτ = −1`, M7, recommended for link budgets) and document it, or add an "aligned/worst/mean" selector later (out of scope for M8)?
14. **θ-convention for generic text** — `auto` heuristic with Metadata disclosure (recommended) or a required UI choice?

---

## 15. Outcome

| Metric | M7.110_5 | M8 (rev 3) |
|---|---|---|
| Lines (one file) | 5,199 | ≤ 3,000 |
| Public methods | ~90 | ≤ 6 |
| Pattern copies per refresh | 6 (+2 per coverage node) | 1 canonical + 1 params-free base + 1 element-wise derived |
| Grid index maps / `reshape` | `gridCache` + `ismember` + `sub2ind` | **0** — everything is already a grid |
| Seam special cases | 4 sites | 0 (display index) |
| `UserData` state flags | 6 | 0 |
| `findall`/`findobj` outside layout | 12 | 0 |
| Duplicate algorithms | 9 | 0 |
| Toolbox dependencies | 1 (`prctile`) | 0 |
| Known numerical-policy defects (D19, D21, D22, D23) | 4, silent | 0, each with a gate row |
| Component change (1° FFD) | 0.8–2 s | ≤ 120 ms |
| Loss / Rx / link change | full recompute + 5 renders | ≤ 30 ms |
| Load (1° FFD) | 5 eager renders | 1 visible render (≤ 2 s) |
| Span toggle | full recompute + redraw | ≤ 100 ms index remap |
| Coverage compute (65k × 501) | ~260 MB transient, O(N·T) | O(N log N) once, O(T log N) per curve; exact inverse |
| Context menus / triads / colorbars per 3-D render | 2 / 6 / 1 leaked | 0 |
| Correctness bugs (rev-2 §0.2 + §8 + this §0.2) | 16 + 19 | 0 |

**Out of scope:** new plot types, new file formats beyond the FFE block split, new metrics (sidelobe level, XPD, beam solid angle are one-liners on the grid and can follow in M8.1), per-control helper families, spinner-keyed caches.

The drop is M8 when §12 is green **and** the names in §10 (both revisions) no longer exist in the file.

---

## Appendix A — M7 line index of every defect referenced (rev 2 D1–D16 kept; rev 3 D17–D35 added)

| ID | Lines | ID | Lines | ID | Lines |
|---|---|---|---|---|---|
| D1 | 5113 | D13 | 3715 | D25 | 4769–4771, 785–800 |
| D2 | 507 | D14 | 4132–4137 | D26 | 4682–4689, 634–642 |
| D3 | 1237 vs 1265 | D15 | 785 | D27 | 4154–4159, 4185–4190, 4913 |
| D4 | 355 → 2846 → 1235, 357 | D16 | 1902 | D28 | 345 vs 653 |
| D5 | 4743–4744 | D17 | 4711–4715 | D29 | 4886–4888 |
| D6 | 5170–5172, 4638 (restated E3) | D18 | 1512–1531, 1767 | D30 | 704–711 |
| D7 | 1663 | D19 | 2810 → 4837–4848, 631 | D31 | 1703, 2593–2596 |
| D8 | 2256 | D20 | 835–848 → 888–899 | D32 | 2142 |
| D9 | 282 | D21 | 4980–4984, 5061–5066 | D33 | 1336 |
| D10 | 3073 vs 248 | D22 | 5085–5139, 245–246 | D34 | 282–283, 2029–2036 |
| D11 | 2648 | D23 | 4954–5059 | D35 | 1146, 1256–1262, 1268 |
| D12 | 1818 | D24 | 4783 | | |

## Appendix B — Reference kernels

**B.1 prctile-compatible quantile** (golden comparison only; not used by M8 logic):

```matlab
function q = util_prctileCompat(x, p)
s = sort(x(isfinite(x))); n = numel(s); if n == 0, q = NaN; return; end
pos = p/100*n + 0.5;                                   % MATLAB prctile: p_i = 100*(i-0.5)/n
if pos <= 1, q = s(1); elseif pos >= n, q = s(n);
else, i = floor(pos); q = s(i) + (pos-i)*(s(i+1)-s(i)); end
end
```

**B.2 Stokes helpers**

```matlab
function [I,Q,U,V] = pat_stokes(Eth, Eph)
Pt = abs(Eth).^2; Pp = abs(Eph).^2; C = Eth.*conj(Eph);
I = Pt + Pp; Q = Pt - Pp; U = 2*real(C); V = 2*imag(C);
end
function [Eth, Eph] = pat_fromStokes(I, Q, U, V, psiTheta)
Pt = max((I+Q)/2, 0); Pp = max((I-Q)/2, 0); dphi = atan2(V, U);         % ∠(Eth·conj(Eph))
Eth = sqrt(Pt).*exp(1i*psiTheta); Eph = sqrt(Pp).*exp(1i*(psiTheta - dphi));
end
% Circular powers straight from Stokes (used by pat_calcBase, no reconstruction needed):
%   Prcp = (I + V)/2,  Plcp = (I − V)/2,  total = I,  Ω-weighted class: sum(I.*dOmega), sum(V.*dOmega) sign, …
```

**B.3 Cone mask and orientation**

```matlab
mask = G.Ux*c(1) + G.Uy*c(2) + G.Uz*c(3) >= cosd(alphaDeg);            % nθ×nφ logical
w = 10.^((Gtot - peak)/10) .* G.dOmega; w(~isfinite(w) | peakMask) = 0;  % cone energy weights
E = arrayfun(@(k) sum(w(G.Ux*A(k,1)+G.Uy*A(k,2)+G.Uz*A(k,3) >= cosd(45)),'all'), 1:6); [~, boresight] = max(E);
```
