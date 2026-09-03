# APAT M8 — Single-Blow Refactor Plan (revision 4)

**From:** `APAT_v3_M7_110_5.m` — 5,199 lines, one App Designer class, 183 functions (≈95 methods, 34 file-scope functions, ~690 lines of generated layout).
**To:** `APAT_v3_M8.m` — the **same one file**, rebuilt around one dataflow.
**Supersedes:** `APAT_M8_improvement_plan_rev3.md`. Everything in revision 3 that survived a third, independent line-by-line audit of M7 **and** the owner's review is kept and is referenced, not repeated. What the owner corrected is applied in §0.1 — and each correction makes the design *simpler*, not bigger. What revision 3 got wrong or left fragile is corrected in §0.2. What was still missing is added in §0.3 (defects D36–D50) and §0.4 (structure 16–24).

This is still **one drop**. Do not patch M7. Build the destination, point the UI at it, delete every M7 name the destination replaces.

---

## 0. What changed since revision 3

### 0.1 Owner review — three comments, three simplifications

| # | Owner comment | Effect on the plan |
|---|---|---|
| O1 | *"E3/D6: in antenna patterns the θ and φ steps inside a pattern are uniform / fixed."* | Adopted as an **invariant** (I14). Uniformity is *validated once* at import (`pat_normalize`, §5.2) instead of being *tolerated everywhere*. Consequence: the solid-angle weight is **separable / rank-1**: `ΔΩ(i,j) = wθ(i)·Δφ`. `Geometry` stores an `nθ×1` vector and a scalar — not an `nθ×nφ` matrix. Every integral becomes `Δφ · wθᵀ · sum(X, 2)`; the θ sum telescopes so `Σ ΔΩ = 4π` is **exact** (to machine ε) on any full-sphere grid — no tolerance, no `median(diff)` heuristics, no non-uniform edge machinery (§5.4). Rev-3 §5.4 (`geo_build` with midpoint edges, periodic gap averaging) is **deleted**. |
| O2 | *"D19: for coverage, use the canonical pattern format (θ 0…180, φ 0…360)."* | Adopted and made structural: `cov_*` kernels take **only** `(grid, Geometry, mask, thresholds)`; there is no code path by which a display table can reach them. The canonical domain is asserted at `geo_build` (`0 ≤ θ ≤ 180`, `0 ≤ φ < 360`, ascending, uniform) and `wθ ≥ 0` follows analytically, so D19 is impossible rather than guarded (§5.8). |
| O3 | *"Coverage computation (CCDF) must be explicit / mathematically transparent."* | The coverage kernel is written so that **the code is the formula** (§5.8): the literal definition `Coverage(T) = 100·Ω{G > T}/Ω_region`, evaluated through the Ω-weighted **histogram of gain levels** and its **suffix sum** — a three-line identity (Appendix C.1) stated in the function header. A six-line *literal* reference implementation (`cov_ccdf_reference`, the N×T indicator form) stays in the file as the self-test oracle, so transparency is checked by machine, not by reading. Rev-3's `cov_dist/cov_curve` names and the "shift thresholds by −L" trick are replaced by one `cov_ccdf` returning both the curve and the reusable distribution. |

### 0.2 Revision-3 statements that were wrong, fragile, or more complex than needed

| # | Revision 3 said | Verified reality | Consequence for M8 |
|---|---|---|---|
| E12 | §5.4 `geo_build`: midpoint θ edges, `median(dP)` periodicity detection, circular gap averaging for φ, `IsFullSphere = |Σ−4π| < 1e-6·4π` | With uniform steps (O1) all of this collapses: `wθ(i) = cos(max(θᵢ−Δθ/2,0)) − cos(min(θᵢ+Δθ/2,180))`, `Δφ` scalar, `PhiPeriodic ⇔ nφ·Δφ == 360 (±1e-9)`. Σ is exact by telescoping | §5.4 rewritten; 20 lines → 8; no tolerance constant on the sphere test |
| E13 | §5.8 `cov_dist` + `cov_curve` + `cov_inverse` as three "engine" functions; thresholds "shifted by −L" to share one distribution | Correct but opaque (O3); and the −L shift is only valid for the five gain-like columns, **not** for `AR_dB`, `PLF_dB` or `Gain_PolCorrected_dB` (PLF depends on Rx settings, not L) | One `cov_ccdf` with the derivation in its header; distribution keyed by `(Revision, ParamsKey-relevant-part, column, coneKey)`; the −L shortcut applies only when `Meta.LossAdditive(col)` is true (§5.8) |
| E14 | `cov_inverse` via `arrayfun(@(cc) find(d.S >= cc, 1, 'last'))` | O(c·N) and unclear at the boundary (strict `>`). Coverage(T) ≥ c holds for **every T below** the returned level, never *at* it | `cov_inverse` documented as `sup{T : Coverage(T) ≥ c}`; implemented with one `nnz(S ≥ cW)` per query; datatip text says "≥ c % for T < …" (§5.8) |
| E15 | §5.6 `met_peak`: "pole rows: all φ share a direction, so the row's neighbours are each other → never falsely isolated" | True — and therefore a spike **at the pole can never be detected** (its neighbours are copies of itself). Also, the 4-neighbour test cannot flag a 2-sample spike (two adjacent bad samples) | Pole rows compare against the **adjacent ring** (`max(G(2,:))` / `max(G(end−1,:))`); 2-sample spikes are documented as out of scope (they are resolved features at that grid) (§5.6) |
| E16 | §5.3 `pat_resample`: `ψθ = angle(interp2(Eth))` is the phase reference; `Eph = √Pφ·e^{j(ψθ − Δφ)}` | Where `|Eθ| → 0` (any φ-polarised region, every x-dipole H-plane) `ψθ` is the phase of numerical noise → the reconstructed `Eφ` phase is noise too, and the *export* phase columns are garbage exactly where the dominant component lives | Phase reference taken from the **stronger interpolated component per cell**; the weaker one is placed by the Stokes relative phase (§5.3, Appendix B.2). Gain/AR/RCP/LCP/PLF were never affected (they are Stokes-only) |
| E17 | §5.5: `Efficiency_pct = η₀·10^{L/10}` | Only meaningful when the source is **calibrated gain**. FFS/FFE/FFD carry raw far-field E (V or V/m at 1 m for the stimulated power) and M7 labels `10·log10(|Eθ|²+|Eφ|²)` as dBi for them (D38) | `Meta.Calibration` gates efficiency, EIRP, PFD, E_RMS and the "dBi" unit label (§5.9) |
| E18 | §12 gate row 2 tolerances (`± 1e-9`, `≈ 2π(1+½Δθ)`) | With separable weights the full-sphere sum is exact and the hemisphere sum is `2π(1 − cos(90°+Δθ/2))` — a closed form, not an approximation | Gate rows rewritten with closed forms (§12) |
| E19 | §5.1 `Geometry {dOmega, Ux, Uy, Uz (nθ×nφ)}` | Four dense matrices per pattern (4 × 65k doubles) that are rank-1/outer products of axis vectors | `Geometry {wTheta(nθ×1), dPhi, sinT, cosT, cosP, sinP}`; `Ux = sinT*cosPᵀ` built on demand for cone masks and F/B (§5.4) |
| E20 | §14-13 "PLF tilt selector out of scope" | Still out of scope, but the PLF must **propagate NaN**: M7 turns `NaN` fields into "perfectly linear antenna" PLF (D41) | `met_plf` masks non-finite AR (§5.5) |

### 0.3 Defects found in this audit that revisions 2–3 did not list

Line numbers refer to `APAT_v3_M7_110_5.m`.

| # | Where | Defect | M8 mechanism |
|---|---|---|---|
| D36 | 4114–4149 | GRASP `.cut` reader: `ICOMP` is branched only on `== 2` (circular). **`ICOMP = 3` — Ludwig-3 linear co/cx, the GRASP default for linear feeds — is read as raw Eθ/Eφ.** Co/cx and θ/φ differ by a φ-dependent rotation, so polarisation class, AR, RCP/LCP split, PLF and E/H planes are wrong for every such file; only total gain survives | `io_graspCut` implements `ICOMP ∈ {1: θ/φ, 2: RHC/LHC, 3: Ludwig-3}` explicitly (Appendix B.5); any other `ICOMP` is an **error**, not a silent guess |
| D37 | 4726–4727, 4083–4084, 4143–4144, 4175–4176, 4302–4303 | Circular components are formed as `E_R = (Eθ + jEφ)/√2`, `E_L = (Eθ − jEφ)/√2`. Under the IEEE sense with the `e^{+jωt}` time convention — the convention of CST, FEKO, HFSS, GRASP and XGTD exports — an **outgoing** RHCP wave along `r̂` (with `θ̂ × φ̂ = r̂`) is `(θ̂ − jφ̂)/√2`. M7's assignment is RHCP only under `e^{−jωt}`. The same pair is used consistently in the four readers, so RHCP/LHCP *inputs* round-trip — but for every θ/φ source the derived RHCP/LHCP labels, the "Circular (RHCP)" classification, the Auto-Rx sense and the signed-AR colour may be **mirrored** | One kernel `pat_circular(Eth, Eph, Const.CircularSign)` used by every reader and by `pat_calcBase`; `Const.CircularSign ∈ {+1, −1}` documented with the derivation; gate row 26 uses an analytically RHCP source (crossed dipoles in quadrature). **Owner must confirm the sign against one trusted CP measurement** (§14-15) |
| D38 | 4166–4167 vs 4182–4190, 4216; 4733; 4635–4638; 4787–4790 | **Calibration.** UAN/FZ carry dBi-scaled fields, Excel carries dBi, gain-only text carries dB(i). CST FFS, FEKO FFE and HFSS FFD carry **raw far-field E** (V, "r·E"). M7 computes `E_Total_dB = 10·log10(|Eθ|²+|Eφ|²)` for all of them and labels it gain (dBi); efficiency, directivity-vs-gain, EIRP, PFD and E_RMS are then wrong by `10·log10(4π/(2η₀·P_ref))` (≈ −17.8 dB for 1 W) — silently | `Meta.Calibration ∈ {"gain", "field"}` per format; CST FFS header (`// Radiated/Accepted/Stimulated Power`) enables automatic normalisation `G = 4π·|rE|²/(2η₀·P_acc)`; FFE/FFD stay `"field"` unless a reference power is supplied (§14-16). Metadata row **"Level calibration"**; efficiency/EIRP/PFD/E_RMS are `n/a` and the unit label is `dB(V)` when uncalibrated (I17) |
| D39 | 2264 → 293–298 (`buildPatternData` → `app.getParam()`), 1683 | A pattern loaded on the **Coverage** tab is processed with the **Main-tab link parameters frozen at load time**, at **native** step, while the Main node is re-synced from the current view (1° resampled, current loss). Two curves in one table can therefore carry different loss, Rx mode and sampling with nothing in the label saying so | Nodes own a params-free `Pattern/Geometry/Base` (rev-3 §5.8); `pat_applyParams` runs at **compute time** from `readConfig`; every job records `ParamsKey`, `StepDeg`, `Calibration` and shows them in the node tooltip and export header |
| D40 | 4631–4638 | When the peak is "adjusted", outlier samples are set to `NaN` and dropped by `'omitnan'` — but the `4π` normalisation of efficiency and the `∫G dΩ` of directivity keep their Ω. Directivity is biased high by `Ω_spikes/4π` and the effective peak is compared against an integral missing area | Spikes are **excluded from both** numerator and Ω (`η = ∫_{¬spike} G dΩ / Ω_{¬spike}·(Ω_{¬spike}/4π)`) — i.e. renormalised — or, equivalently, filled by the neighbour maximum. One line, stated in `met_metrics` |
| D41 | 4760–4762, 4778–4779 | `polSense = sign(delta); polSense(~isfinite(delta)) = 0;` then `antennaRatio(polSense == 0) = 1e12`. **Non-finite fields become a perfectly linear antenna** with a finite PLF; NaN never reaches the output | `met_plf` computes on finite AR only; `PLF_dB(~finite) = NaN` |
| D42 | 4580 | `coverageCCDF` filters `solidAngle >= 0` — it *hides* D19 instead of failing. A geometry with negative weights should be impossible, not tolerated | `geo_build` asserts the canonical domain; `wθ ≥ 0` is then analytic; `cov_ccdf` has no weight filter (§5.8) |
| D43 | 1755–1777 | Results table: `interp1(thr, cov, unionThresholds, 'linear')` treats every curve — including freshly computed step-function CCDFs — as a polyline; values between a job's own thresholds are invented | Computed jobs are re-evaluated **exactly** from their distribution at the union thresholds; only *loaded* result curves (no distribution) are interpolated, with `'linear'` and a `⌁` marker in the column header |
| D44 | 4035–4041 | Generic gain-only text: θ/φ column identity decided by **span** (larger span → φ) with no disclosure; a θ ∈ [0,180] × φ ∈ [0,180] half-sphere file is a coin flip | `Meta.AxisOrder ∈ {"theta-phi", "phi-theta"}` + `Meta.AxisOrderSource ∈ {"header", "span-heuristic"}`; Metadata row; header names `theta/phi/az/el` take precedence over the heuristic |
| D45 | 2318–2320 | Cone membership `cosDist >= cosd(α)` with no tolerance: samples **on** the cone boundary (α a multiple of the grid step is the common case) flip in/out with 5-dp angle snapping and `cosd` round-off | `mask = dot ≥ cos(α) − 1e-12` (§5.8) — deterministic, and the same rule in `met_orientation` |
| D46 | 569–583, 373–382 | Status bar and Metadata call the **selected component's** maximum "POB … dB" — for `AR_dB` that is the most-circular sample, for `PLF_dB` the best-matched one; the wording implies beam peak | I4 already moves metrics to total gain; additionally the status text names the component: "Peak of *Axial Ratio*: … dB at (θ, φ)"; "POB" is reserved for total gain |
| D47 | 4132–4137 | `.cut` single-cut → body of revolution at **10°** φ (rev-2 D14 flagged the synthesis). Missing: the synthetic φ step is not the source step, so `Meta.StepPhi = 10` enters HPBW H-plane, coverage and the 1° resampler as if measured | Synthesis uses the **θ step** for φ (`0:Δθ:360−Δθ`), flagged `Meta.SynthesizedRevolution = true`, and coverage nodes show "(synthetic φ)" |
| D48 | 4059–4066 | Generic mag/phase layout detection: a column is "phase" if `max|value| > 100`. A dB magnitude column with a −110 dB null qualifies as phase; a phase column expressed in `[−90, 90]` does not | Layout from header names when present; heuristic uses **range** (`max − min > 180` ⇒ phase) and requires both phase columns to agree; `Meta.LayoutSource` disclosed |
| D49 | 4195–4197 | FFD θ/φ axes via `linspace(start, stop, count)` — if `stop` is written as `360` with `count = 361` the seam column is folded later (fine), but if `stop = 359` with `count = 360` the file is already open-axis; both are legal and M7 never records which | `Meta.PhiClosedInSource` recorded; `pat_normalize` folds a closing column exactly once and reports it |
| D50 | 1703, 2593–2612 | Query datatips are placed by `interp1` on the plotted polyline **and** by `coverageInterpolationLocation` on `DataIndex + InterpolationFactor` — two independent interpolations of the same point that disagree at plateaus | One exact query point from `cov_ccdf`/`cov_inverse`; the tip is placed at the exact coordinates (rev-3 §0.3-15) and the polyline is only a drawing |

### 0.4 Structural ideas added (continuing revision 3's list 7–15)

16. **Separable (rank-1) geometry.** `Geometry.wTheta (nθ×1)`, `Geometry.dPhi` (scalar). `ΔΩ = wTheta·dPhi·1ᵀ` is never stored. `∫X dΩ = dPhi · wThetaᵀ · sum(X,2)`. Full-sphere sum exact by telescoping. Memory: `nθ` doubles instead of `nθ·nφ`. Unit vectors are outer products of four axis vectors built on demand.
17. **Explicit CCDF.** `cov_ccdf` = literal definition → weighted histogram (`unique` + `accumarray`) → suffix sum → one `discretize`. Derivation in the header; literal oracle in the file; equivalence gate row.
18. **Uniform-step validation at the boundary.** One check in `pat_normalize` (`max|diff(axis) − Δ| ≤ 1e-6`) replaces every `gridStep`, `min(diff(unique(...)))` and `median(diff)` in the program. Non-uniform axes are **regularised once** (owner decision §14-17) with `Meta.Regularized = true`, or rejected.
19. **Pinned conventions.** `Const.CircularSign`, `Const.PLFTiltCos`, `Const.TimeConvention` (documentation), `Const.Eta0 = 376.730313668` in one place; every reader is a **descriptor** that names its θ convention, axis order, calibration and circular basis. Metadata shows all four.
20. **Calibration model.** `Meta.Calibration`, `Meta.RefPower_W`, `Meta.UnitLabel`. Gain-derived link quantities and efficiency exist only when calibrated. The unit label on every colorbar/axis is `Meta.UnitLabel`, never a literal `"dBi"`.
21. **Node-owned physics, compute-time params.** Coverage nodes own `Pattern/Geometry/Base`; the Main node owns a reference. Params are applied at compute time. Jobs are reproducible from `(node, ParamsKey, column, cone, thresholds)` and say so.
22. **Pole-aware, ring-based peak isolation.** `met_peak` compares pole rows against the adjacent ring; interior samples against 4 neighbours with φ wrap. Spikes are excluded consistently (numerator **and** Ω) everywhere they matter.
23. **Phase-reference-safe Stokes reconstruction.** Reference phase from the stronger interpolated component per cell; relative phase from `atan2(V, U)`. Export phases are stable in both polarisation regions.
24. **Explicit invariants on the sphere.** `geo_build` asserts domain, ascending order, uniform steps, `nφ·Δφ ≤ 360`; `PhiPeriodic ⇔ nφ·Δφ = 360`. Everything downstream is unconditional.

---

## 1. Why M8 is a different program, not a faster M7

Unchanged from revision 3 §1, condensed: M7 re-interprets the same sphere in every consumer (six table copies, display conventions stored *as data* and undone by `physicalTheta` at 8 sites, `gridStep`/`unique` at ≥ 7 sites, `solidWeights` at ≥ 6 sites, nine duplicate algorithms, state in six `UserData` slots, `cla`+`surf`+`findall`+two context menus per 3-D render, a 65k×17 uitable push per component change). Caches bolted on top are local fixes for a global dataflow mistake.

This audit adds a fourth class: **conventions are implicit.** Circular sense (D37), calibration (D38), Ludwig-3 (D36), axis order (D44), mag/phase layout (D48), θ convention (D29) are decided by heuristics or by omission and never disclosed. Two of them (D36, D38) produce wrong physics for common inputs. M8 makes every convention a named constant or a reader-descriptor field that appears in Metadata.

> **One physical pattern (grid-native, uniform). One separable geometry. One params-free base. One element-wise link layer. One config snapshot. One graphics registry. One place per convention.**
> Math never sees the app. UI never rebuilds math. Display is an index map, not a copy. Coverage is the formula.

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
| I1 | **Peak policy = spatial isolation:** a sample is a spike iff it exceeds every grid neighbour (4-neighbours with φ wrap; the adjacent **ring** for pole rows) by more than `Const.PeakExcessDB = 6`. The effective peak is the highest non-spike sample. Raw and effective peaks appear in Metadata. No quantile, no toolbox |
| I2 | **Resample in the coherency domain** (`I,Q,U,V`) for E-field sources, linear power for gain-only. Never AR / PLF / dB. Target axes = source domain at the requested step. Phase reference = stronger component per cell. `pat_calcBase` runs **after** resample, exactly once per `Pattern.Revision` |
| I3 | Canonical sphere: polar θ ∈ [0,180] ascending, φ ∈ **[0,360)** ascending, grid-native `[nθ×nφ]`, `PhiPeriodic` detected. Angles snapped to 5 decimals; **fields never rounded** |
| I4 | **Metrics, orientation and coverage boresight are defined on total gain** (or the single gain-only column). Component selection changes plots, tables and the POB marker only; status text names the component |
| I5 | Coverage: `Coverage(T) = 100·Ω{G > T}/Ω_region`, strict `>`, ties exact, computed **only** on the canonical grid with `Geometry` weights. Cones use physical unit vectors with a `−1e-12` boundary tolerance |
| I6 | Query formatting stays on the query controls; tips show exact query values from the distribution |
| I7 | Readers produce M7's canonical pack **except** the designed deltas: angle-only rounding, coverage detector, UAN φ ≥ 0, FFE blocks, θ-convention hint, **Ludwig-3 rotation, pinned circular sign, calibration model, θ-step revolution synthesis** |
| I8 | **Display invariance:** toggling elevation θ / signed φ changes zero numbers in `Pattern, Geometry, Derived, Metrics, Coverage` |
| I9 | One `.m` file. Structs + prefixed local functions. Base MATLAB only (R2023b baseline) |
| I10 | Zero graphics-object growth across repeated component / cut / span / range / query / tab actions |
| I11 | **Params-free base:** `pat_calcBase` output depends only on `Pattern`. `pat_applyParams` is element-wise and never changes a peak index, boresight, HPBW, F/B or directivity |
| I12 | **Partial-sphere honesty:** efficiency and F/B are `n/a` unless `Geometry.IsFullSphere`; resampling never creates samples outside the source domain |
| I13 | **Readers are pure, `apply*` are the only writers of `Items/Limits/Text/Visible/Enable`** |
| I14 | **Uniform axes:** `Theta` and `Phi` are arithmetic progressions (`max|diff − Δ| ≤ 1e-6°`), validated once in `pat_normalize`. `Geometry` is separable: `ΔΩ(i,j) = wTheta(i)·dPhi`; `Σ ΔΩ = 4π` **exactly** on a full sphere |
| I15 | **Explicit coverage:** `cov_ccdf`'s header states the definition and the evaluation identity; `cov_ccdf_reference` (literal N×T form) lives in the file and the self-test proves `max|Δ| < 1e-9 %` (float summation order only) on fixtures with ties, spikes, NaNs and cones |
| I16 | **Pinned conventions:** circular sense, PLF tilt, time convention, η₀, Ludwig-3 rotation, axis order, θ convention and calibration are each defined in exactly one place and disclosed in Metadata |
| I17 | **Calibration honesty:** efficiency, EIRP, PFD, E_RMS and the `dBi` label exist only when `Meta.Calibration == "gain"`; otherwise they are `n/a` and levels are labelled `dB(V)` |

---

## 4. Architecture — M7 vs M8

### 4.1 M7 dataflow (today) — hazards marked (rev-3 list + this audit)

```
FILE → readPattern (ICOMP≠2 ⇒ θ/φ ⚠D36; E_R=(Eθ+jEφ)/√2 ⚠D37; V-field as dBi ⚠D38; span/100 heuristics ⚠D44 D48)
     → rawTbl + blocks{} → normalizePattern (rounds FIELDS, folds θ twice) → stdTbl
  └─ refresh
     ├─ calcPattern(stdTbl) → patTbl ①                     (wasted if resampling)
     ├─ applyStep → resample? (Re/Im, 0..180×0..360, 'nearest' ⚠D21 D23) → calcPattern ② → viewBaseTbl
     └─ applyAngularSpan → COPY 17 cols, rewrite θ/φ, sortrows → viewTbl
        ├─ detectOrientation(viewTbl, comp) → solidWeights(DISPLAY θ) ⚠D19 → viewSolidAngle
        ├─ resolvePeak(P99.99+6) ⚠D22 → POB;  calcMetrics(comp peak, total gain, spikes dropped, Ω kept ⚠D40)
        ├─ PLF: NaN → "linear" ⚠D41;  cosd(180) tilt (D24)
        ├─ 5× cla + surf + 2 menus + triad + colorbar ⚠D35; uitable ← 65k×17
        └─ Coverage: Main node ← viewTbl (re-synced); foreign node ← getParam() at load ⚠D39
              N×T indicator → double (~260 MB); weights<0 dropped ⚠D42; table interp1 ⚠D43; cone '>=' ⚠D45
```

### 4.2 M8 dataflow (destination)

```
FILE ──► io_read(path, fmt) ──► Source { Raw, Blocks(nθ×nφ×4×F | nθ×nφ×1×F), Theta, Phi, Freqs, Meta }
                                   Meta: ThetaConvention, AxisOrder(+Source), Calibration, RefPower_W,
                                         CircularBasis, Ludwig3Applied, SynthesizedRevolution, PhiClosedInSource
             ▼
        pat_normalize(Source, freqIndex) ──► Pattern { Theta[nθ], Phi[nφ], StepTheta, StepPhi,
             │                                          Eth, Eph (nθ×nφ complex) | G (nθ×nφ),
             │                                          IsGainOnly, FreqIndex, Revision, Meta }
             │                               asserts: ascending, UNIFORM (I14), θ⊂[0,180], φ⊂[0,360)
             ▼  (optional)   pat_resample(Pattern, step)  — decimate if exact, else Stokes interp → Revision++
             ▼
        geo_build(Theta, Phi, StepTheta, StepPhi) ──► Geometry { wTheta[nθ], dPhi, sinT, cosT, cosP, sinP,
             │                                                   PhiPeriodic, IsFullSphere, OmegaSampled, AxesKey }
             ▼
        pat_calcBase(Pattern, Geometry) ──► Base { E_Total_dB, E_TH_dB, E_PH_dB, E_RCP_dB, E_LCP_dB (L=0),
             │                                     AR_dB, *_Phase, Pol, Pairs, Peaks.(col), Boresight, Planes,
             │                                     Metrics0, Revision }             (uses Const.CircularSign)
             ▼
        pat_applyParams(Base, params) ──► Derived { five gain grids +L, PLF_dB (NaN-safe), Gain_PolCorrected_dB,
             │                                       EIRP_dBW / PFD_Wm2 / E_RMS_Vm (lazy, calibrated only),
             │                                       Metrics, ParamsKey }
             ▼
        View = readConfig()        component, cut, span, limits, freqIndex, masks — never copies Pattern
        Map  = geo_displayMap(Geometry, View)   { ThetaAxis, PhiAxis, ColIdx, ThetaDir, labels, ticks }
     ┌──────────┬──────────┬──────────┬──────────────┬──────────┬──────────┐
     ▼          ▼          ▼          ▼              ▼          ▼          ▼
   PLOTS     METRICS     CUTS      COVERAGE        EXPORT     TABLES    METADATA
 G(:,ColIdx)  Base+L   row/col   cov_ccdf(G,Geo,   Pattern/   Derived+  conventions,
 dirty tabs             slices    mask,T) — canon.  Derived    mask      calibration
```

**Dependency graph (keep as the comment block above `update`):**

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

### 4.3 Layer contracts (who may write what)

Unchanged from revision 3 §4.3, plus:

| Layer | Object | Writer | Readers | Forbidden |
|---|---|---|---|---|
| Geometry | `app.Geometry` | `geo_build` on `AxesKey` miss | base, plots, cuts, coverage | materialising `ΔΩ` as a matrix outside `cov_ccdf`'s local scope |
| Conventions | `Const.*`, `Meta.*` | section B / readers | everything | literals `sqrt(2)`, `1i*`, `cosd(180)`, `"dBi"`, `120*pi` anywhere else |
| Node | `Cov_Tree` NodeData | coverage `apply*` | tree mirror, job plots | holding a **Derived** (params) — nodes hold `Pattern/Geometry/Base` or a `PatternRef`; params are applied at compute |

**Validity is one comparison per layer.** No flag families.

### 4.4 Why this is shorter (additions to revision 3 §4.4)

| Concept | M7 | M8 | What vanishes |
|---|---|---|---|
| Solid angle | `solidWeights` ×6 call sites, seam zeroing, per-node `solidAngle` vectors | `Geometry.wTheta`, `Geometry.dPhi` | `solidWeights`, `viewSolidAngle`, `NodeData.solidAngle`, `gridStep` |
| Step detection | `gridStep`/`min(diff(unique))` ≥ 7 sites | validated once; `Pattern.StepTheta/StepPhi` | all of them |
| Coverage | `coverageCCDF` (N×T) + `coverageCacheKey` + `covThresholds` + `interp1` table + two query interpolations | `cov_ccdf` + `cov_inverse` + `cov_thresholds` | 5 functions, 260 MB transient, plateau ambiguity |
| Circular components | 5 inline `(a ± 1i·b)/sqrt(2)` sites | `pat_circular` | 4 copies + the sign risk |
| Field units | implicit dBi | `Meta.Calibration`, `Meta.UnitLabel` | every literal `'dBi'`/`'dB'` in titles |

---

## 5. Data model & pipelines

### 5.1 Schemas (factory functions in section B of the file)

```matlab
Source   = struct('Raw',table(),'Blocks',[],'Theta',[],'Phi',[],'Freqs',NaN,'Meta',struct(), 'Path','','Name','','Format','')
% Meta: Format, IsGainOnly, IsCoverage, ThetaConvention ("polar"|"elevation"|"auto"), AxisOrder, AxisOrderSource,
%       Calibration ("gain"|"field"), RefPower_W (NaN), UnitLabel ("dBi"|"dB"|"dB(V)"), CircularBasis, Ludwig3Applied,
%       SynthesizedRevolution, PhiClosedInSource, Regularized, GainColumns, LossAdditive (per column), Excel summary …
Pattern  = struct('Theta',[],'Phi',[],'StepTheta',NaN,'StepPhi',NaN,'Eth',[],'Eph',[],'G',[],'IsGainOnly',false, ...
                  'FreqIndex',1,'Revision',uint64(0),'Meta',struct())
Geometry = struct('wTheta',[],'dPhi',NaN,'sinT',[],'cosT',[],'cosP',[],'sinP',[], ...
                  'PhiPeriodic',false,'IsFullSphere',false,'OmegaSampled',NaN,'AxesKey',"")
Base     = struct('Cols',struct(),'Peaks',struct(),'Pol',"n/a",'Pairs',struct('Linear',["E_TH","E_PH"],'Circular',["E_RCP","E_LCP"]), ...
                  'Boresight',1,'Planes',struct('ePhi',0,'hType',"Theta",'hValue',90,'source',"principal"),'Metrics0',struct(),'Revision',uint64(0))
Derived  = struct('Cols',struct(),'Metrics',struct(),'ParamsKey',"",'Revision',uint64(0))
View, Map, Graphics — as revision 3 §5.1
CovDist  = struct('g',[],'w',[],'S',[],'Omega',NaN,'Key',"")   % Ω-weighted gain histogram + suffix sum (§5.8)
```

### 5.2 Canonicalize — `pat_normalize(Source, freqIndex)`

1. Apply `Meta.ThetaConvention` (`elevation` → θ = 90−θ; `auto` → the M7 heuristic, recorded as `Meta.ThetaInterpreted`); θ<0 → (−θ, φ+180); θ>180 → (360−θ, φ+180). **Once.**
2. `φ = mod(φ,360)`; snap θ, φ to 5 decimals (**angles only**).
3. Dedupe directions (`unique([φ θ],'rows','first')`); a supplied φ=360 column folds into φ=0 (`Meta.PhiClosedInSource = true`).
4. Axes: `Theta = unique(θ)`, `Phi = unique(φ)`. **Uniformity (I14):** `StepTheta = (Theta(end)−Theta(1))/(nθ−1)`; assert `max|diff(Theta) − StepTheta| ≤ 1e-6`; same for φ (`StepPhi = 360/nφ` when the span closes, else `(Phi(end)−Phi(1))/(nφ−1)`). Failure → §14-17 (regularise with `Meta.Regularized = true`, or error `APAT:NonUniformGrid`).
5. Regularity test `nθ·nφ == N`; if false → one `scatteredInterpolant` per primitive onto the native-step grid inside the source hull; `Meta.Regularized = true`.
6. Reshape grid-major: `Eth = reshape(…, nθ, nφ)`, θ down rows, φ across columns, both ascending. **No seam column.**

Result: `Pattern.Eth(i,j)` is the field at `(Theta(i), Phi(j))`. Nothing else is ever indexed; nothing downstream ever measures a step again.

### 5.3 Resample — `pat_resample(Pattern, stepDeg)` (corrects E16)

- **Domain:** `θq = Theta(1):step:Theta(end)`, `φq = Phi(1):step:Phi(end)` (+ periodic closure through `[Phi, Phi(1)+360]` when `PhiPeriodic`). Never outside the source hull (D21).
- **Decimate** per axis when the native step is an integer multiple of `step` and the axis contains the targets (bit-exact).
- **E-field:** `[I,Q,U,V] = pat_stokes(Eth,Eph)`; `interp2` each (linear). Reconstruct `Pθ = (I+Q)/2`, `Pφ = (I−Q)/2`, `Δψ = atan2(V,U) = ∠(Eθ·Eφ*)`. **Phase reference (E16):** interpolate both `Eth` and `Eph` complex-linearly; per cell, if `Pθ ≥ Pφ` then `ψθ = ∠Eth_c`, `ψφ = ψθ − Δψ`; else `ψφ = ∠Eph_c`, `ψθ = ψφ + Δψ`. `Eth = √Pθ·e^{jψθ}`, `Eph = √Pφ·e^{jψφ}` (Appendix B.2). Gain, AR, RCP/LCP and PLF are exact functions of `I,Q,U,V`; only the export phases carry interpolation error, and they are now referenced to the component that actually has energy.
- **Gain-only:** linear power in, dB out, per `Meta.GainColumns`; non-gain columns linear.
- `Revision++`; FFD/FFE blocks resampled lazily per `(FreqIndex, step)`.

### 5.4 Geometry — `geo_build(Theta, Phi, StepTheta, StepPhi)` (replaces rev-3 §5.4; O1)

```matlab
function G = geo_build(th, ph, dth, dph)
%GEO_BUILD Separable solid-angle weights for a uniform θ×φ grid (I14).
%   ΔΩ(i,j) = wTheta(i)·dPhi,   wTheta(i) = cos θᵢ⁻ − cos θᵢ⁺,   θᵢ∓ = clamp(θᵢ ∓ Δθ/2, 0°, 180°)
%   Σᵢ wTheta(i) telescopes to cos θ₁⁻ − cos θₙ⁺  (= 2 when the end cells reach both poles);
%   Σⱼ dPhi = nφ·Δφ (= 2π when periodic)  ⇒  Σ ΔΩ = 4π exactly on a full sphere.
th = th(:); ph = ph(:);
assert(th(1) >= 0 && th(end) <= 180 && ph(1) >= 0 && ph(end) < 360, 'APAT:Geometry', 'grid not canonical');
lo = max(th - dth/2, 0);  hi = min(th + dth/2, 180);
G.wTheta = cosd(lo) - cosd(hi);                       % nθ×1, ≥ 0 analytically (lo ≤ hi on [0,180])
G.dPhi   = deg2rad(dph);                              % scalar
G.PhiPeriodic  = abs(numel(ph)*dph - 360) < 1e-9;
G.OmegaSampled = sum(G.wTheta) * numel(ph) * G.dPhi;
G.IsFullSphere = G.PhiPeriodic && lo(1) == 0 && hi(end) == 180;   % exact conditions, no tolerance on Σ
G.sinT = sind(th); G.cosT = cosd(th); G.cosP = cosd(ph).'; G.sinP = sind(ph).';   % unit vectors on demand:
G.AxesKey = geo_axesKey(th, ph);                      %   Ux = sinT*cosP, Uy = sinT*sinP, Uz = cosT*ones(1,nφ)
end
```

- Uniform 1° full sphere (θ 0…180, φ 0…359): `Σ wTheta = 2` exactly, `360·dPhi = 2π` → `Σ ΔΩ = 4π` to machine ε. Identical to M7's `solidWeights` on every uniform full-sphere fixture (gate row 2 is now an *identity*, not a tolerance).
- Hemisphere θ 0…90: `Σ wTheta = 1 − cos(90.5°)` (closed form), `IsFullSphere = false`, `OmegaSampled` shown in Metadata as "Sampled solid angle: 2.0087π sr (50.2 %)". The half-step overhang at a non-polar end is M7-compatible and documented; §14-18 offers the domain-exact alternative.
- Pole-free grids (θ = 0.5:1:179.5) still sum to `4π` exactly because `lo(1) = 0` and `hi(end) = 180` after clamping.
- Integrals everywhere: `Ω-weighted sum(X) = G.dPhi * (G.wTheta.' * sum(X, 2, 'omitnan'))`. Cone / F/B dot products: `sinT*cosP*cx + sinT*sinP*cy + cosT*cz` (one `nθ×nφ` temporary, when needed).

### 5.5 Derive — `pat_calcBase(Pattern, Geometry)` and `pat_applyParams(Base, params)`

As revision 3 §5.5, with these changes:

- Circular components from **one** kernel: `[Er, El] = pat_circular(Eth, Eph, Const.CircularSign)` → `Er = (Eth − j·s·Eph)/√2`, `El = (Eth + j·s·Eph)/√2`, `s = Const.CircularSign` (`+1` = IEEE with `e^{+jωt}`; `−1` reproduces M7). Equivalent Stokes form: `Prcp = (I − s·V)/2`, `Plcp = (I + s·V)/2` (D37).
- Ω-weighted polarisation class: `sum(P .* wTheta, 'all')` per component (dPhi cancels).
- **Spike-consistent integrals (D40):** `keep = ~Peaks.E_Total_dB.mask & isfinite(G)`; `∫G dΩ = dPhi·wThetaᵀ·sum(10.^(G/10).*keep, 2)`; `Ω_keep` likewise; `η₀ = ∫G dΩ / 4π · (4π/Ω_keep)`; `D_peak = 4π·10^{G_peak/10}/∫G dΩ · (Ω_keep/4π)` — i.e. spikes are removed from both sides. Stated in one comment line.
- `met_plf(AR_dB, RxMode, RxAR_dB, Pairs, Const.PLFTiltCos)`: computes on `isfinite(AR_dB)` only; result `NaN` elsewhere (D41). Exactly-linear samples (`AR_dB = NaN` per §14-10) map to `r_a = ∞` **explicitly** via a branch, not via `1e12`.
- Gain-only: `+L` only on `Meta.GainColumns`; `Meta.LossAdditive(col)` marks the columns whose coverage distribution may be shifted by `−L` (E13).
- Link quantities (`EIRP_dBW`, `PFD_Wm2`, `E_RMS_Vm`) and `Efficiency_pct` are computed only when `Meta.Calibration == "gain"` (I17); otherwise `NaN` with a Metadata reason.

### 5.6 Metrics — `met_*`

**`met_peak(G, excessDB, periodicPhi, poleRows)`** (I1, corrects E15):

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

**`met_planes`**, **`met_orientation`**, **`met_hpbw`** as revision 3 (orientation uses the same `−1e-12` cone tolerance as coverage, D45). **`met_metrics`** gates `Efficiency_pct`/`FrontBack_dB` on `IsFullSphere` (I12) and `Efficiency_pct`/link quantities on calibration (I17).

### 5.7 Cuts — `geo_cut(Pattern, Derived, type, value, cols)`

As revision 3 §5.7 (grid-native row/column slices; one extract feeds the 2-D cuts and both 3-D overlays).

### 5.8 Coverage — `cov_*` (O2, O3; replaces rev-3 §5.8)

**Definition (I5).** For a region `R` of the canonical sphere (whole sphere, or a cone of half-angle `α` about a unit vector `ĉ`), gain grid `G` (dB) and thresholds `T`:

```
Coverage(T) [%] = 100 · Ω{G > T} / Ω_R,        Ω{G > T} = Σ_{(i,j) ∈ R,  G(i,j) > T}  ΔΩ(i,j),
ΔΩ(i,j) = wTheta(i) · dPhi,                      Ω_R = Σ_{(i,j) ∈ R, G finite} ΔΩ(i,j)
```

Strict `>`; ties exact; samples with non-finite gain belong to neither numerator nor denominator (M7 semantics, now stated).

**Evaluation identity (Appendix C.1).** Let `g₁ < g₂ < … < g_n` be the distinct gain levels inside `R` and `ω_k = Σ_{G(i,j) = g_k} ΔΩ(i,j)` their total solid angles (the Ω-weighted histogram). Then `Ω{G > T} = Σ_{k : g_k > T} ω_k = S(k_T)` where `S(k) = Σ_{m ≥ k} ω_m` (suffix sum) and `k_T` is the index of the first level exceeding `T`. Building the histogram is O(N log N) once; each threshold is one binary search.

**The kernel — the code is the formula:**

```matlab
function [C, d] = cov_ccdf(G, geo, mask, T)
%COV_CCDF  Coverage(T) [%] = 100 · Ω{G > T} / Ω_region      (Ω-weighted CCDF, strict '>')
%   Ω{G > T} = Σ_{(i,j)∈region, G(i,j)>T} ΔΩ(i,j),   ΔΩ(i,j) = geo.wTheta(i)·geo.dPhi     (canonical grid only)
%   Identity: with (g_k, ω_k) the Ω-weighted histogram of G over the region and S(k) = Σ_{m≥k} ω_m,
%             Ω{G > T} = S(k_T),  k_T = first k with g_k > T.   Reference form: cov_ccdf_reference (self-test oracle).
dOmega = geo.wTheta .* geo.dPhi .* ones(1, size(G, 2));    % ΔΩ(i,j), implicit expansion (local, never stored)
v      = mask & isfinite(G);                                % region ∩ valid samples
[g, ~, bin] = unique(G(v));                                 % distinct gain levels g_1 < … < g_n
w      = accumarray(bin, dOmega(v));                        % ω_k : solid angle at level g_k   (weighted histogram)
S      = [flipud(cumsum(flipud(w))); 0];                    % S(k) = Ω{G ≥ g_k};  S(n+1) = 0;  S(1) = Ω_region
kT     = discretize(T(:), [-Inf; g; Inf]);                  % kT−1 = #{g_k ≤ T}  ⇒  g_kT is the first level > T
C      = 100 * S(kT) / S(1);                                % Coverage(T)
d      = struct('g', g, 'w', w, 'S', S, 'Omega', S(1));     % reusable distribution (queries, tables, re-thresholding)
end
```

```matlab
function C = cov_ccdf_reference(G, geo, mask, T)            % literal definition — self-test oracle only, O(N·T)
dOmega = geo.wTheta .* geo.dPhi .* ones(1, size(G, 2)); v = mask & isfinite(G); g = G(v); w = dOmega(v);
C = zeros(size(T)); for k = 1:numel(T), C(k) = 100 * sum(w(g > T(k))) / sum(w); end
end
```

```matlab
function T = cov_inverse(d, c)                              % sup{ T : Coverage(T) ≥ c }   (D31, E14)
%   Coverage is a non-increasing step function of T; it is ≥ c for every T below the returned level g_k*,
%   where k* is the last level with S(k*) ≥ c·Ω_region/100.  Returns NaN when c exceeds Coverage(−∞) = 100.
T = nan(size(c)); W = d.Omega;
for q = 1:numel(c), k = nnz(d.S >= c(q)*W/100); if k >= 1 && k <= numel(d.g), T(q) = d.g(k); end, end
end
```

```matlab
function m = cov_coneMask(geo, thetaDeg, phiDeg, alphaDeg)  % physical unit vectors; deterministic boundary (D45)
c = [sind(thetaDeg)*cosd(phiDeg), sind(thetaDeg)*sind(phiDeg), cosd(thetaDeg)];
m = (geo.sinT*geo.cosP)*c(1) + (geo.sinT*geo.sinP)*c(2) + geo.cosT*ones(1,numel(geo.cosP))*c(3) >= cosd(alphaDeg) - 1e-12;
end
```

```matlab
function T = cov_thresholds(tMin, tMax, step)               % D18: counting, not accumulation
n = round((tMax - tMin)/step); T = tMin + (0:n).'*step; if T(end) < tMax - 1e-9, T(end+1) = tMax; end
end
```

**Where it runs.**

- Input is always `(Derived.Cols.(col) | Base.Cols.(col), app.Geometry | node.Geometry, mask, T)`. A `View`, a `Map` or a table **cannot** be passed — there is no signature for it (O2).
- One distribution per `(Revision, column, ParamsKey-part, coneKey)`, kept in `app.CovDists` (`dictionary`). `ParamsKey-part` is empty for `LossAdditive` columns (the distribution at L=0 is reused with `T − L`) and the full key otherwise (E13).
- Threshold spinners → `cov_ccdf` re-evaluation from `d` (`discretize` only). Queries → `cov_ccdf` / `cov_inverse` exact; tips at exact coordinates.
- Results table (D43): computed jobs re-evaluated exactly at the union of thresholds; loaded-file curves interpolated linearly and flagged in the header.
- Foreign nodes (D39): own `Pattern/Geometry/Base` built at load by the same `pat_*/geo_*`; `pat_applyParams` at compute time with the current `readConfig`; job metadata records `ParamsKey`, `StepDeg`, `Calibration`, `SynthesizedRevolution`.
- Spherical coverage on a `LossAdditive` column at a new loss costs one `discretize` — no recompute.

**Cost.** 1° full sphere (`181×360 = 65,160` samples), 501 thresholds: M7 ≈ 260 MB transient and O(N·T); M8 ≈ 1 MB, one sort (≈ 5 ms), curve ≈ 0.1 ms. The reference oracle on the same input would take ≈ 30 M comparisons and is run only in the self-test on ≤ 10k-sample fixtures.

### 5.9 Import — `io_*` (adds D36, D37, D38, D44, D47, D48, D49)

Reader **descriptor** (rev-2 §5.9 idea, now complete):

```matlab
Formats = dictionary(key → struct( ...
   'order',  [θ φ c1 c2 c3 c4],          'kind',  "reim" | "magphase" | "gain", ...
   'basis',  "theta-phi" | "rhc-lhc" | "lhc-rhc" | "ludwig3", ...
   'theta',  "polar" | "elevation" | "auto", ...
   'calib',  "gain" | "field",           'unit',  "dBi" | "dB" | "dB(V)", ...
   'source', "XGTD UAN" | "CST FFS" | …))
```

| Format | basis | theta | calib | Notes |
|---|---|---|---|---|
| UAN / FZ (XGTD) | theta-phi (mag dB + phase) | polar | **gain** | header gives ranges; φ ≥ 0 on export |
| OUT (GRASP) | rhc-lhc | polar | field* | *unless header states dBi; `pat_circular` |
| CUT (GRASP) | `ICOMP` 1 θφ / 2 RHC-LHC / 3 **Ludwig-3** (D36) | auto (own fold) | field* | single cut → revolution at **Δθ** (D47); other `ICOMP` → error |
| FFS (CST) | theta-phi (Re/Im) | polar | **field → gain** via header power (D38) | `// Radiated/Accepted/Stimulated Power` → `G = 4π·|rE|²/(2η₀·P_acc)` |
| FFE (FEKO) | theta-phi | polar | field | blocks per `#Frequency`/`#Request` (D27); `RefPower_W` optional (§14-16) |
| FFD (HFSS) | theta-phi | polar | field | `PhiClosedInSource` recorded (D49); `RefPower_W` optional |
| Excel matrix 1/2/3 | theta-phi / rhc-lhc / both | polar | **gain** (dBi sheets) | `pat_circular` for format 2 |
| Generic text (6 variants) | per selector | auto | gain | axis order from header, else span heuristic **disclosed** (D44); mag/phase layout from header, else range rule (D48) |
| Generic gain-only | — | auto | gain | `Meta.GainColumns`, `LossAdditive` |
| Coverage results | — | — | — | stricter detector (rev-2) |

One kernel each: `io_fieldsToComplex(vals, kind)`, `io_toThetaPhi(c1, c2, basis, phiDeg)` (θφ / circular via `pat_circular` inverse / **Ludwig-3 rotation**, Appendix B.5), `io_calibrate(Eth, Eph, calib, P_ref)`.

### 5.10 Export — lazy, canonical

As revision 3 §5.10. Additionally every export header (Results, UAN, Cut, Coverage) carries the convention block: `ThetaConvention`, `CircularSign`, `Calibration/UnitLabel`, `PLFTiltCos`, `ParamsKey`, `StepDeg`, `Revision`, `ReleaseName`.

---

## 6. Orchestration

### 6.1 `update(app, scope)` — the dispatcher

As revision 3 §6.1. Two additions:

| User action | scope | Recompute | Render |
|---|---|---|---|
| Reference power (uncalibrated source, if §14-16 adopted) | `calib` | `io_calibrate` → `pat_calcBase` → params | as `freq` |
| Coverage compute | — | `pat_applyParams(node.Base, readConfig)` if not `LossAdditive` → `cov_ccdf` | curve, table, legend, node tooltip |

Ladder: `source ⊃ freq ⊃ step ⊃ calib ⊃ params ⊃ component ⊃ {span, cut, range, annot, camera}`.

### 6.2 Callback shape, guard, visibility, choices

As revision 3 §6.2 (`guard` with `Busy`, `readConfig`/`readCoverageConfig` pure, `applyChoices`, `applyVisibility`, checkpoint handle, env-gated profiler).

### 6.3 Range controller, 6.4 Status & lifecycle

As revision 3 (AR theme touches only the full-pattern colour scale, D20; one timer; `shutdown`).

---

## 7. Rendering — retained mode

As revision 3 §7 (registry + dirty keys, lazy visible-tab rendering, exact display permutation, lazy tables). One addition: every colorbar label, axis label and datatip unit is `Meta.UnitLabel` (I17); the coverage axes title shows the region and the formula string `Coverage(T) = 100·Ω{G>T}/Ω_R`.

---

## 8. Correctness designed in (merged table — additions to revision 3 §8)

| M7 defect | Why M8 cannot contain it |
|---|---|
| Ludwig-3 `.cut` read as θ/φ (D36) | `io_toThetaPhi` branches on the descriptor basis; unknown `ICOMP` is an error |
| Circular sense implicit ×5 (D37) | `pat_circular` + `Const.CircularSign` + CP fixture gate |
| Field units labelled dBi (D38) | `Meta.Calibration`; `UnitLabel` on every label; gated link quantities |
| Coverage node params frozen at load (D39) | nodes are params-free; `pat_applyParams` at compute time |
| Spikes dropped from ∫ but not from Ω (D40) | `keep` mask applied to both sides in one expression |
| NaN → linear PLF (D41) | `met_plf` finite-only |
| Negative weights filtered (D42) | `geo_build` asserts domain; `wTheta ≥ 0` analytic |
| Table `interp1` on computed CCDFs (D43) | exact re-evaluation from the distribution |
| Undisclosed axis-order / layout heuristics (D44, D48) | descriptor + `Meta.*Source` + Metadata rows |
| Cone boundary flicker (D45) | `−1e-12` tolerance, one function for coverage and orientation |
| "POB" on non-gain components (D46) | status text names the component; POB reserved for total gain |
| Synthetic 10° revolution (D47) | Δθ synthesis, flagged |
| Seam-closure ambiguity in FFD (D49) | recorded, folded once |
| Two query interpolations (D50) | one exact query point |
| Pole spikes undetectable (E15) | ring neighbourhood |
| Phase reference from a null component (E16) | stronger-component reference |
| Everything in revision 3 §8 | unchanged |

---

## 9. Destination file layout

```
classdef APAT_v3_M8 < matlab.apps.AppBase
  %% A  UI component properties           generated; do not hand-rename
  %% B  Constants + schema factories       Const (PeakExcessDB=6, ConeHalfAngleDeg=45, PowerFloor, Bounds=[-250 100],
  %%                                       ARLimits=[-30 30], AutoRangeSpanDB=50, AngleDecimals=5, UniformTolDeg=1e-6,
  %%                                       PLFTiltCos=-1, CircularSign=+1|-1 (§14-15), Eta0=376.730313668,
  %%                                       PrincipalAxes, HiddenOutputColumns, Formats, Defaults, ReleaseName)
  %%                                       newSource/newPattern/newGeometry/newBase/newDerived/newView/newMap/newGraphics/newCovDist
  %% C  State properties (private)         Source, Pattern, Geometry, Base, Derived, View, Map, Graphics, CutCache,
  %%                                       CovDists, RangeGroups, StatusTimer, OperationDialog, Busy, isClosing
  %% D  Orchestration (private)            readConfig, readCoverageConfig, update(scope), applyChoices, applyVisibility,
  %%                                       applyRanges, applyMetadata, applyTables, applyCoverageResult, guard, setStatus, shutdown
  %% E  Callbacks (private)                one-liners
  %% F  Renderers (private)                renderFull(k), renderCut, renderOverlay, renderPOB, renderCoverageJob, renderQuery
  %% G  Public API                         ctor, delete, closeRequest;  Static: selfTest, version
  %% H  createComponents                   generated layout; no ValueChangedFcn on range widgets
end

%% Local functions — app-free, alert-free, H1 one-liner, ≤ ~60 lines each
%%   io_*    io_read, io_columns, io_fieldsToComplex, io_toThetaPhi, io_ludwig3ToThetaPhi, io_calibrate, io_ffd, io_ffe,
%%           io_graspCut, io_excelMatrix, io_excelSummary, io_isCoverageTable, io_findHeaderLines
%%   pat_*   pat_normalize, pat_validateUniform, pat_resample, pat_decimate, pat_stokes, pat_fromStokes, pat_circular,
%%           pat_calcBase, pat_applyParams, pat_applyLink
%%   geo_*   geo_build, geo_axesKey, geo_displayMap, geo_cut, geo_integrate
%%   met_*   met_peak, met_orientation, met_planes, met_metrics, met_hpbw, met_plf
%%   cov_*   cov_ccdf, cov_ccdf_reference, cov_inverse, cov_coneMask, cov_thresholds
%%   util_*  util_fmtNumber, util_db, util_ticks, util_clampRange, util_displayRange, util_plotTheme, util_arColormap,
%%           util_coneLabel, util_nearest
```

**Size budget (lines):** UI layout 690 · io 390 · pat/geo/met/cov 430 · orchestration + apply 420 · renderers 340 · callbacks 110 · schemas/constants 130 · selfTest 280 · comments/headers 200 → **≈ 2,990** (≤ 3,000 stands; geometry and coverage shrank, readers and self-test grew).

---

## 10. Fold / delete (additions to revisions 2–3 §10)

| Keep | Delete |
|---|---|
| `geo_build` (separable) | `solidWeights`, `gridStep`, `viewSolidAngle`, `NodeData.solidAngle`, rev-3's midpoint/median `geo_build` |
| `cov_ccdf` + `cov_ccdf_reference` + `cov_inverse` + `cov_coneMask` | `coverageCCDF`, `coverageCacheKey`, `covThresholds`, `coverageQueryPoint`, `coverageInterpolationLocation`, rev-3 `cov_dist/cov_curve`, the `interp1` in `covRebuildTable` for computed jobs |
| `pat_circular` | five inline `(Eθ ± 1i·Eφ)/sqrt(2)` sites |
| `io_ludwig3ToThetaPhi` | the `ICOMP == 2 … else` branch in the `.cut` reader |
| `io_calibrate`, `Meta.Calibration`, `Meta.UnitLabel` | every literal `'dBi'`, `'dB'` in plot titles, colorbar labels, status text |
| `pat_validateUniform` | every `min(diff(unique(...)))`, `median(diff(...))` |
| `Const.Eta0`, `Const.CircularSign`, `Const.PLFTiltCos` | `sqrt(30*…)` (uses η₀ implicitly), `cosd(180)`, `1e12` |

Rule unchanged: if a name in the right column still exists in the file, the blow is incomplete.

---

## 11. Refactoring strategy — one blow, one work order

1. **Core first, no widgets.** Section B factories and every `io_/pat_/geo_/met_/cov_/util_` local function. Prove them with the Static `selfTest` (§12 rows 1–30).
2. **Golden capture from M7** on the fixture set. The `goldenHash` row compares with the **designed deltas** listed in code: rev-3's list **plus** Ludwig-3 rotation, circular sign (if `+1` is adopted), calibration gating, θ-step revolution synthesis, spike renormalisation, NaN PLF, exact table evaluation, ring-based pole peaks, phase-reference choice.
3. **Paste `createComponents`** minus range-widget `ValueChangedFcn`; title from `Const.ReleaseName`.
4. **State + orchestration**: properties, `readConfig`, `readCoverageConfig`, `update`, `applyChoices`, `applyVisibility`, `applyRanges`, `guard` (with `Busy`), `shutdown`, one timer, one menu, `RangeGroups`.
5. **Renderers** in retained mode with dirty keys; verify I10 and lazy-render equivalence before wiring more callbacks.
6. **Retarget every callback** to the one-liner shape.
7. **Coverage**: nodes hold `PatternRef` or their own `Pattern/Geometry/Base`; distributions in `app.CovDists`; params at compute time.
8. **Delete §10 names in the same edit.** `grep` the right columns of all three §10 tables: any hit → stop.
9. **Run §12.** Fix the destination; never resurrect `viewTbl`.

**What this strategy refuses** — unchanged (no M7.111 patch, no interim clones, no widget-wrapping helpers, no spinner-keyed caches, no toolbox calls, no stored seam column, no Re/Im resampling path, no percentile fallback). Added: **no `nθ×nφ` solid-angle matrix stored anywhere**, **no coverage entry point that accepts a table**, **no inline `sqrt(2)` circular split**, **no unit literal outside `Meta.UnitLabel`**.

---

## 12. Release gate (`APAT_v3_M8.selfTest()` — Static, no UI)

Returns a table `name / pass / detail`. All must pass. Rows 1–21 as revision 3 with the corrections below; rows 22–30 new.

| # | Check | Assertion |
|---|---|---|
| 1 | `peakSpatial` | as rev 3, **plus**: +10 dB spike on the θ=0 pole row of a flat grid → `wasAdjusted`, `spikeCount == nφ`; uniform pole row never flagged |
| 2 | `solidAngle` | `Σ wTheta·nφ·dPhi == 4π` to `≤ 4·eps(4π)` on 1°, 2°, 5°, 0.5° and on θ = 0.5:1:179.5; hemisphere θ 0…90: `Σ = 2π(1 − cos 90.5°)` to 1e-12 and `IsFullSphere = false`; half-plane φ 0…180 → `PhiPeriodic = false`; `all(wTheta ≥ 0)`; identical to M7 `solidWeights` on every uniform full-sphere fixture (bit-exact after seam removal) |
| 3 | `gridNative` | as rev 3 |
| 4 | `ccdfEquivalence` | `cov_ccdf` vs `cov_ccdf_reference`: `max|Δ| < 1e-9 %` (summation-order rounding only; measured ≈ 7e-12 % on a 65k-sample 1° sphere) on fixtures with ties, NaNs, a cone, a hemisphere, and a spike; strict `>` at a tie threshold; `C(−Inf) == 100`, `C(+Inf) == 0` |
| 5 | `coverageInverse` | for 50 random `c`: `cov_ccdf(T − 1e-9) ≥ c` and `cov_ccdf(T) < c` (or `T` is the minimum level); plateau returns the plateau's upper level; `c > 100 → NaN` |
| 6 | `coneMask` | dot-product mask ≡ angular-distance mask on 20 random cones; a sample **on** the boundary is inside |
| 7–13 | as revision 3 | (`normalizePrecision`, `resampleCoherency`, `displayInvariance`, `metricsSemantic`, `paramsSplit`, `polarizationWeighted`, `planes`) |
| 8b | `resamplePhaseRef` | y-polarised dipole (|Eθ| ≈ 0 on the H-plane), 2° → 1°: export `E_PH_Phase` error < 1° everywhere; rev-3 formula would give random phase |
| 14 | `readers` | as rev 3, **plus**: `.cut` with `ICOMP=3` of an x-polarised dipole → `Pol = "Linear (Horizontal)"`, `AR_dB` ≥ 40 on axis (rev-3 reader gives ≈ 0 dB AR at φ = 45°); `ICOMP=7` → error `APAT:UnsupportedICOMP` |
| 15–21 | as revision 3 | |
| 22 | `uniformAxes` | 1° grid passes; grid with one 0.999° gap fails with `APAT:NonUniformGrid` (or `Meta.Regularized = true`, per §14-17); `StepTheta/StepPhi` exact |
| 23 | `separableIntegral` | `geo_integrate(X)` ≡ `sum(X(:) .* dOmegaMatrix(:))` < 1e-12 on random `X`; F/B and cone energy identical to the dense form |
| 24 | `spikeRenormalisation` | isotropic 0 dBi pattern + one +20 dB spike: `Efficiency_pct = 100 ± 1e-9`, `PeakDirectivity_dB = 0 ± 1e-9` (M7 gives 100·(1 − ΔΩ_spike/4π) and a biased D) |
| 25 | `plfNaN` | `AR_dB = NaN` at 10 samples → `PLF_dB = NaN` there, finite elsewhere; exactly-linear (§14-10 sentinel) → `PLF = −3 dB` for a CP wave, `−∞→floor` for a cross-linear wave |
| 26 | `circularSign` | crossed dipoles fed in quadrature under `e^{+jωt}` (Eθ = 1, Eφ = −j at +Z) → `E_RCP_dB − E_LCP_dB > 60 dB` with `CircularSign = +1`; sign `−1` reproduces M7 bit-exactly on the fixtures |
| 27 | `calibration` | CST FFS fixture with `P_acc = 1 W` and `|rE|² = 2η₀/(4π)` → `E_Total_dB = 0 dBi`; FFE fixture → `UnitLabel = "dB(V)"`, `Efficiency_pct = NaN`, `EIRP` column absent |
| 28 | `coverageParams` | foreign node + Main node from the same file at the same step and loss → identical curves; changing loss after load changes both (M7: only Main) |
| 29 | `tableExact` | union table values for computed jobs equal `cov_ccdf` at the union thresholds (no interpolation); loaded curve column carries the `⌁` header |
| 30 | `conventionsDisclosed` | Metadata contains rows `θ convention`, `Axis order`, `Level calibration`, `Circular sense`, `PLF tilt`, `Synthesized revolution` (when applicable); export headers contain the same block |

Also: Code Analyzer clean; ≤ 3,000 lines; ≤ 6 public methods; §10 names gone; `grep -c "findall\|findobj\|UserData\|reshape\|prctile\|solidWeights\|gridStep\|sqrt(2)\|cosd(180)\|'dBi'" APAT_v3_M8.m` → 0 outside `createComponents` and `Const`.

---

## 13. Risks & platform baseline

| Risk | Handling |
|---|---|
| A legitimate source with a non-uniform axis (hand-edited CSV, merged measurements) | `pat_validateUniform` fails loudly or regularises once (§14-17); Metadata says so. M7 could not render such grids correctly anyway (`gridComp` NaN holes) |
| `Const.CircularSign` chosen wrong | It is one constant, one gate row, one Metadata row; flipping it is a one-line change with a full self-test. The owner verification (§14-15) is a precondition of step 2 |
| CST FFS header variants (older versions omit power lines) | fall back to `"field"` with disclosure; never guess a power |
| Ludwig-3 sign convention (GRASP vs. FEKO definitions differ by the reference axis) | `io_ludwig3ToThetaPhi(…, refAxis)` with `refAxis` from the descriptor; gate row 14 uses an x-dipole and a y-dipole |
| Coherency reconstruction over-states purity between samples | bounded by the cell; gate row 8 |
| Spatial peak policy flags unresolved beams | truth; Metadata wording; §14-1 |
| Half-step Ω overhang at non-polar domain ends | M7-compatible; `OmegaSampled` shown; §14-18 |
| MATLAB release | **R2023b baseline**; `dictionary`, `discretize`, `accumarray`, `circshift`, `jsonencode` are base MATLAB |
| Toolboxes | none |

---

## 14. Open decisions for the owner — with recommendations

Items 1–14 as revision 3 (recommendations unchanged), with the owner's review now closing three of them:

- **Closed by O1:** uniform axes are an invariant (I14) — rev-3 §14 had no item for it; the non-uniform machinery is deleted.
- **Closed by O2:** coverage operates only on the canonical grid via `Geometry` — supersedes any "coverage on the view table" behaviour.
- **Closed by O3:** explicit CCDF formulation (`cov_ccdf` + oracle) — supersedes rev-3 §14-5's first alternative (interpolate on the displayed polyline); exact evaluation is adopted.

New items:

15. **Circular sense** — adopt `Const.CircularSign = +1` (IEEE, `e^{+jωt}`: `E_R = (Eθ − jEφ)/√2`) — **recommended, after the owner verifies one known-sense CP pattern in APAT M7 shows the mirrored label** — or keep `−1` (M7 behaviour) and document it as "`e^{−jωt}` convention". Either way the sign becomes explicit and tested.
16. **Uncalibrated sources (FFE/FFD, FFS without power lines)** — (a) disclosure only, levels in `dB(V)`, link quantities `n/a` (**recommended for M8**); (b) add a "Reference power (W)" spinner visible only for `"field"` sources so the user can calibrate (M8.1 candidate, ≈ 25 lines).
17. **Non-uniform axis at import** — (a) error `APAT:NonUniformGrid` with the offending axis and gap (**recommended**: it is not an antenna pattern grid); (b) regularise onto the modal step with `Meta.Regularized = true`.
18. **Ω at non-polar domain ends** — (a) half-step overhang clamped to the sphere (M7-compatible, **recommended**, golden-equivalent); (b) domain-exact edges (`hi(end) = Theta(end)` when `Theta(end) < 180`) so a θ 0…90 hemisphere sums to exactly 2π. (b) breaks bit-exactness with M7 on partial spheres only.
19. **Ludwig-3 reference axis for `.cut`** — GRASP's definition (co-pol along the feed's principal plane as defined in the job) vs. FEKO's (φ = 90° reference). **Recommended:** GRASP definition for `.cut`, exposed as `Meta.Ludwig3Ref`, with the two fixtures in gate row 14.
20. **Coverage node provenance display** — show `ParamsKey`-derived text ("L = 1.5 dB, Rx Auto, 1°") in the node tooltip only (**recommended**) or in the legend label as well.

---

## 15. Outcome

| Metric | M7.110_5 | M8 (rev 4) |
|---|---|---|
| Lines (one file) | 5,199 | ≤ 3,000 |
| Public methods | ~90 | ≤ 6 |
| Pattern copies per refresh | 6 (+2 per coverage node) | 1 canonical + 1 params-free base + 1 element-wise derived |
| Solid-angle storage | `N` doubles ×(view + every node) | `nθ` doubles + 1 scalar |
| Step / seam / weight special cases | ≥ 17 sites | 0 (validated once; separable; open axis) |
| Coverage kernel | N×T indicator, ~260 MB, O(N·T), 5 helpers | `cov_ccdf` (10 lines = the formula), O(N log N) + O(T log N), oracle-verified |
| Conventions defined implicitly | 6 (circular sign, calibration, Ludwig-3, axis order, layout, θ) | 0 — each one constant/descriptor field + Metadata row |
| `UserData` state flags | 6 | 0 |
| `findall`/`findobj` outside layout | 12 | 0 |
| Duplicate algorithms | 9 (+5 circular splits) | 0 |
| Toolbox dependencies | 1 (`prctile`) | 0 |
| Known numerical-policy defects (D19, D21, D22, D23, **D36, D38, D40, D41**) | 8, silent | 0, each with a gate row |
| Component change (1° FFD) | 0.8–2 s | ≤ 120 ms |
| Loss / Rx / link change | full recompute + 5 renders | ≤ 30 ms |
| Span toggle | full recompute + redraw | ≤ 100 ms index remap |
| Coverage compute (65k × 501) | ~260 MB, O(N·T) | ≈ 1 MB, one sort; re-threshold ≈ 0.1 ms; exact inverse |
| Correctness bugs (rev-2 §0.2 + rev-3 §0.2 + this §0.2/§0.3) | 16 + 19 + **24** | 0 |

**Out of scope:** new plot types, new file formats beyond the FFE block split and the `ICOMP=3` branch, new metrics (sidelobe level, XPD, beam solid angle are one-liners on the grid — M8.1), the reference-power spinner (§14-16 b), a PLF tilt selector.

The drop is M8 when §12 is green **and** the names in §10 (all three revisions) no longer exist in the file.

---

## Appendix A — M7 line index of every defect referenced in this revision

| ID | Lines | ID | Lines | ID | Lines |
|---|---|---|---|---|---|
| D36 | 4114–4149 | D41 | 4760–4762, 4778–4779 | D46 | 569–583, 373–382 |
| D37 | 4726–4727, 4083–4084, 4143–4144, 4175–4176, 4302–4303 | D42 | 4580 | D47 | 4132–4137 |
| D38 | 4166–4167, 4182–4190, 4216, 4733, 4635–4638, 4787–4790 | D43 | 1755–1777 | D48 | 4059–4066 |
| D39 | 2264, 293–298, 1683 | D44 | 4035–4041 | D49 | 4195–4197 |
| D40 | 4631–4638 | D45 | 2318–2320 | D50 | 1703, 2593–2612 |
| E15 | rev-3 §5.6 | E16 | rev-3 §5.3 | E12–E14, E17–E20 | rev-3 §5.4, §5.8, §5.5, §12, §5.1, §14 |

Revision 2 (D1–D16) and revision 3 (D17–D35) indices are unchanged and remain authoritative for those IDs.

## Appendix B — Reference kernels

**B.1 Separable integrals**

```matlab
function s = geo_integrate(geo, X)              % Σ_ij X(i,j)·ΔΩ(i,j), NaN-safe
s = geo.dPhi * (geo.wTheta.' * sum(X, 2, 'omitnan'));
end
```

**B.2 Stokes helpers with a safe phase reference (E16)**

```matlab
function [I,Q,U,V] = pat_stokes(Eth, Eph)
Pt = abs(Eth).^2; Pp = abs(Eph).^2; C = Eth.*conj(Eph);
I = Pt + Pp; Q = Pt - Pp; U = 2*real(C); V = 2*imag(C);
end
function [Eth, Eph] = pat_fromStokes(I, Q, U, V, EthRef, EphRef)
Pt = max((I+Q)/2, 0); Pp = max((I-Q)/2, 0); dpsi = atan2(V, U);          % dpsi = ∠Eθ − ∠Eφ
useTh = Pt >= Pp;                                                          % reference = stronger component
psiT = angle(EthRef); psiP = angle(EphRef);
psiT(~useTh) = psiP(~useTh) + dpsi(~useTh);  psiP(useTh) = psiT(useTh) - dpsi(useTh);
Eth = sqrt(Pt).*exp(1i*psiT); Eph = sqrt(Pp).*exp(1i*psiP);
end
```

**B.3 Circular split, one place (D37)**

```matlab
function [Er, El] = pat_circular(Eth, Eph, s)   % s = Const.CircularSign: +1 IEEE/e^{+jωt}, −1 reproduces M7
Er = (Eth - 1i*s*Eph)/sqrt(2);  El = (Eth + 1i*s*Eph)/sqrt(2);
end
% inverse (readers):  Eth = (Er + El)/sqrt(2);  Eph = 1i*s*(Er - El)/sqrt(2);
% Stokes form:        Prcp = (I - s*V)/2;  Plcp = (I + s*V)/2
```

Derivation: with `θ̂ × φ̂ = r̂` the triad `(θ̂, φ̂, r̂)` is right-handed like `(x̂, ŷ, ẑ)`. For `e^{+jωt}` an IEEE right-hand wave travelling along `+ẑ` is `(x̂ − jŷ)/√2` (the field rotates from `x̂` toward `ŷ` in time, clockwise when viewed from behind the wave). Substituting `θ̂, φ̂` gives `E_R = (Eθ − jEφ)/√2`. Under `e^{−jωt}` the sign of `j` flips and M7's `(Eθ + jEφ)/√2` is right-hand.

**B.4 PLF, NaN-safe (D24, D41)**

```matlab
function plf = met_plf(AR_dB, rxMode, rxAR_dB, pairs, tiltCos)
ok = isfinite(AR_dB); plf = nan(size(AR_dB));
ra = 10.^(abs(AR_dB(ok))/20) .* sign(AR_dB(ok));                       % signed axial ratio (sense in the sign)
rw = 10.^(rxAR_dB/20) * (2*(rxMode=="RHCP" | (rxMode=="Auto" & pairs.Circular(1)=="E_RCP")) - 1);
p  = 0.5 + (4*ra*rw + (ra.^2-1)*(rw^2-1)*tiltCos) ./ (2*(ra.^2+1)*(rw^2+1));
plf(ok) = 10*log10(min(max(p, eps), 1));
end
```

**B.5 Ludwig-3 → θ/φ (D36)** (GRASP `ICOMP = 3`; reference axis per §14-19)

```matlab
function [Eth, Eph] = io_ludwig3ToThetaPhi(Eco, Ecx, phiDeg, refAxis)   % refAxis "x" (GRASP default) | "y"
c = cosd(phiDeg); s = sind(phiDeg); if refAxis == "y", [c, s] = deal(s, -c); end
Eth =  Eco.*c + Ecx.*s;          % E_co = Eθ cosφ − Eφ sinφ,  E_cx = Eθ sinφ + Eφ cosφ   (x-reference)
Eph = -Eco.*s + Ecx.*c;
end
```

**B.6 Calibration (D38)**

```matlab
function [Eth, Eph, meta] = io_calibrate(Eth, Eph, meta, Pref_W)         % field (r·E, V) → gain-scaled field
if meta.Calibration == "field" && isfinite(Pref_W) && Pref_W > 0
    k = sqrt(4*pi / (2*Const.Eta0*Pref_W));                              % |E_gain|² = 4π|rE|²/(2η₀P)
    Eth = Eth*k; Eph = Eph*k; meta.Calibration = "gain"; meta.UnitLabel = "dBi"; meta.RefPower_W = Pref_W;
end
end
```

## Appendix C — Derivations

**C.1 CCDF evaluation identity.** Let `R` be the region, `A = {(i,j) ∈ R : G(i,j) finite}`, and `g₁ < … < g_n` the distinct values of `G` on `A`. Define `ω_k = Σ_{(i,j)∈A, G(i,j)=g_k} ΔΩ(i,j)`. Then for any `T`,

```
Ω{G > T} = Σ_{(i,j)∈A, G(i,j)>T} ΔΩ(i,j)
         = Σ_{k : g_k > T}  Σ_{(i,j)∈A, G(i,j)=g_k} ΔΩ(i,j)        (partition A by level)
         = Σ_{k : g_k > T} ω_k
         = Σ_{k ≥ k_T} ω_k = S(k_T),   k_T = min{k : g_k > T}   (levels are sorted; empty set ⇒ k_T = n+1, S = 0)
```

`discretize(T, [-Inf; g; Inf])` returns `b` with `edge(b) ≤ T < edge(b+1)`, i.e. `g_{b−1} ≤ T < g_b`, hence `b = k_T`. Ties are exact because equal gains share one level; strictness is exact because `g_{k_T} > T` by construction. `Ω_R = S(1)`.

**C.2 Separable weights and the full-sphere sum.** With `θᵢ⁻ = max(θᵢ − Δθ/2, 0)`, `θᵢ⁺ = min(θᵢ + Δθ/2, 180°)` and a uniform axis, `θᵢ⁺ = θᵢ₊₁⁻` for all interior `i`, so `Σᵢ (cos θᵢ⁻ − cos θᵢ⁺) = cos θ₁⁻ − cos θₙ⁺`. If `θ₁ ≤ Δθ/2` and `θₙ ≥ 180° − Δθ/2` the clamps give `cos 0 − cos 180° = 2`. With `nφ·Δφ = 2π` (periodic axis), `Σ ΔΩ = 2·2π = 4π` — a telescoping identity, exact up to the rounding of `cosd` at the four clamped edges.

**C.3 Loss shift.** For a column `X = X₀ + L` (L scalar), `Ω{X > T} = Ω{X₀ > T − L}`; hence the L = 0 distribution serves every loss value for `LossAdditive` columns. Not valid for `AR_dB` (L-independent), `PLF_dB` (Rx-dependent) or `Gain_PolCorrected_dB = E_Total + PLF` (shift by L only if PLF is unchanged — i.e. same Rx settings), which is why `ParamsKey-part` is included in the key for those columns.
