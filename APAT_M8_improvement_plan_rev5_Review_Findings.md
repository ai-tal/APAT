# APAT M8 Plan — Revision 5

**Subject:** `APAT_v3_M7_110_5.m` (5,199 lines; one App Designer class; 183 functions: ≈95 methods, 34 file-scope functions, ~690 lines of generated layout).
**Inputs to this revision:** the full M7 source (read line-by-line, not sampled), the four earlier plan drafts (`APAT_improvement_plan.md`, `…rev2.md`, `…rev3.md`, `…rev4.md`), and the owner's two review comments.
**Structure of this document:**

- **PART A — Review / analysis findings and comparison with the previous drafts.** What was verified, what changed and why, what is new. This part talks about the drafts.
- **PART B — Standalone improvement / enhancement plan.** A complete, self-contained design + work order + release gate for `APAT_v3_M8.m`. It never refers to earlier drafts; every statement is anchored to M7 line numbers or to code in the plan itself.

Read Part B if you want the plan. Read Part A if you want to know how the plan moved and why you can trust it.

---
---

# PART A — Review, analysis and comparison findings

## A.0 Method

1. The whole M7 file was read again against the four drafts: properties (1–250), orchestration and renderers (252–3011), generated layout (3013–3693), lifecycle + `runSelfTest` (3695–3875), readers (3877–4563), numerical core (4565–5200).
2. Every defect ID from the drafts (D1–D50) was re-checked at its cited lines. All fifty stand. Where a draft's *mechanism* was wrong, over-built, or in conflict with the owner's constraints, it is corrected below (E21–E36).
3. Three external format facts that the drafts either assumed or left open were verified against vendor documentation: HFSS `.ffd` sample ordering, FEKO `.ffe` column content, and the HFSS `.ffd` companion `.txt` file. Two of them change the calibration design (E25).
4. Sixteen further defects were found (D51–D66). Each carries M7 line numbers and is reproduced in Part B's consolidated register.

## A.1 Owner constraints applied in this revision

| # | Owner instruction | Effect on the design |
|---|---|---|
| O4 | **"I don't want to use Stokes parameters."** | Every place where drafts 3–4 introduced the coherency vector `I,Q,U,V` is removed: (a) resampling (`pat_stokes`/`pat_fromStokes`, the "phase reference from the stronger component" repair), (b) the E/H-plane tilt `τ = ½·atan2(U,Q)`, (c) the "Stokes form" of the circular split `P_R = (I − sV)/2`. Each is replaced by a formulation that works **directly on the complex field components** and is at least as simple: per-component *linear-power + unit-phasor* interpolation (§A.3-E22, Part B §6.3); *polarisation-ellipse major axis* from `E·E` (Part B §6.7); circular components only ever from `pat_circular(Eθ, Eφ)` (Part B §6.5). Nothing that the Stokes formulation achieved is lost — the phase-slope defect D23 is still fixed, the null-component phase problem E16 no longer exists by construction — and one whole layer of reconstruction logic disappears. |
| O5 | **Separate the review findings from the standalone plan.** | This document has two parts. Part B does not cite any draft; it is complete on its own (data model, kernels, work order, release gate, defect register). |

The three earlier owner comments (O1 uniform steps, O2 coverage on the canonical grid only, O3 explicit CCDF) remain in force and are built into Part B as invariants.

## A.2 What the drafts got right and what is retained unchanged

The core thesis of the drafts survives a fifth reading of M7 intact and is restated in Part B without attribution:

- M7's length and slowness come from **re-interpreting one sphere in every consumer**: six table copies per refresh (`rawTbl → stdTbl → patTbl → viewBaseTbl → viewTbl → uanTbl`, +2 per coverage node), display conventions stored as data and undone by `physicalTheta` at eight sites, `gridStep`/`unique` at ≥ 7 sites, `solidWeights` at ≥ 6 sites, nine duplicate algorithms, UI state in six `UserData` slots, `cla`+`surf`+`findall`+2 context menus per 3-D render, a 65k×17 `uitable` push per component change.
- The destination is **one canonical grid-native pattern → one separable geometry → one params-free base → one element-wise derived layer**, a single `update(scope)` dispatcher, `readConfig` as the only widget reader, `apply*` as the only widget writers, retained-mode graphics with a registry, and a **static, UI-free self-test** as the release gate.
- Uniform-step invariant and **rank-1 solid-angle weights** (`ΔΩ(i,j) = wθ(i)·Δφ`, full-sphere sum exact by telescoping).
- **Explicit coverage kernel**: `Coverage(T) = 100·Ω{G > T}/Ω_R` evaluated through the Ω-weighted histogram + suffix sum, with the literal N×T oracle kept in the file for the self-test.
- Spatial-isolation peak policy (4-neighbour, φ-wrap, pole ring) replacing `prctile`.
- Pinned conventions (`Const.CircularSign`, `Const.PLFTiltCos`, `Const.Eta0`) and a per-format reader descriptor disclosed in Metadata.
- The one-blow construction order (core first, UI last, delete in the same edit).

## A.3 Corrections to statements in the previous drafts

Numbering continues the drafts' E-series.

| # | Draft statement | Verified reality / owner constraint | Consequence in Part B |
|---|---|---|---|
| E21 | rev4 §5.3: "Decimate per axis when the **native step is an integer multiple of `step`**." | Inverted. Decimation to a coarser step is exact when the **target** step is an integer multiple of the **native** step (`k = step/native ∈ ℕ`). M7 itself has the related bug D53 (`applyStep` 421–424 keeps only integer-degree samples, which is a 1° grid only when `1/native ∈ ℕ`; a 0.3° source becomes a **3°** grid). | §6.3 `pat_resample`: per-axis exact decimation iff `k ∈ ℕ`, else interpolation; gate row 8 includes a 0.3° fixture. |
| E22 | rev3 §5.3 / rev4 §5.3: resample in the coherency domain (`I,Q,U,V`), reconstruct `Eθ, Eφ` with a per-cell phase reference. | Rejected by O4. The problem it solved (D23: linear Re/Im interpolation of a field with a fast phase slope loses magnitude — −6 dB at 120°/sample) is real and must still be solved. | **Magnitude/phase-separable interpolation per component**: `|E_c|²` bilinear (linear power — no dip, ever) and the unit phasor `E_c/|E_c|` bilinear (circular mean of neighbouring phases — no unwrapping, no reference component). `E_c = √P_c · Z_c/|Z_c|`. The phasor modulus `|Z_c| ∈ [0,1]` is a free **phase-coherence diagnostic** (1 = well sampled, → 0 = phase under-sampled) reported in Metadata. Where a component is null its phase is irrelevant because it multiplies `√P ≈ 0` — the E16 failure mode cannot occur. Ten lines, one helper, no reconstruction step. |
| E23 | rev3 §5.6 (D26 fix): E-plane from the tilt `τ = ½·atan2(U,Q)`; snap to the nearest grid plane. | Stokes (O4). Also, snapping E/H to grid planes is only exact for boresights on ±Z or the equator; for an oblique beam neither the θ-cut nor a φ-cut is a principal plane. | Co-pol axis from the **polarisation-ellipse major axis**: `χ = ½·arg(Eθ² + Eφ²)`, `a = Re(E·e^{−jχ})` (Born & Wolf; one line, fields only). E-plane = great circle through the peak containing `a`; H-plane = great circle containing `r̂ × a`. `geo_greatCircle` samples any great circle from the derived grid (bilinear, φ-periodic) — exact planes for every boresight, and a new capability (arbitrary plane cuts) for free. Principal-axis fallback for CP (`|AR| < 3 dB`) and gain-only. |
| E24 | rev4 §5.5, Appendix B.3: circular powers "in Stokes form `P_R = (I − sV)/2`". | O4. | Only `pat_circular(Eθ, Eφ, s)` exists; powers are `|E_R|², |E_L|²`. |
| E25 | rev4 D38 / §14-16: FEKO `.ffe` and HFSS `.ffd` "stay `field` unless a reference power is supplied"; a "Reference power (W)" spinner proposed as M8.1. | **FEKO `.ffe` files carry `Gain(Theta) Gain(Phi) Gain(Total)` (or `Directivity(…)`) in columns 7–9, in dB** (Altair FEKO user guide, "Far Fields (.FFE)"); the `#Result Type:` header says which. M7 (4185–4190) truncates to six columns and throws them away. **HFSS `.ffd` exports are accompanied by a `.txt` of the same name listing frequencies, radiated power and accepted power** (Keysight SystemVue import notes for HFSS `.ffd`). Both give the calibration constant with **no user input**. | §6.1 `io_calibrate`: FFE → `k² = 10^{Gain_total/10}/(|Eθ|²+|Eφ|²)` (checked constant across samples to 1e-6 dB, else `"field"`), `Meta.Calibration = "gain"` or `"directivity"`; FFD → parse sibling `.txt` for accepted power; FFS → header power lines. The reference-power spinner is dropped from the roadmap; only sources with none of these remain `"field"` and are labelled so. |
| E26 | rev4 D49: FFD seam-closure ambiguity. | Verified as stated. Additionally verified: HFSS `.ffd` data order is **θ outer, φ inner** (Keysight notes: "the phi angle varies first"), which is exactly M7's `repelem(thetaAxis, nφ)` / `repmat(phiAxis, nθ, 1)` (4197). No ordering defect exists; the plan records the verified fact in the FFD descriptor. |
| E27 | rev4 §5.8 `cov_ccdf` as written. | Correct for a non-empty region. With an empty region (cone outside the sampled domain, or all-NaN column) `unique(G(v))` is empty, `S = 0`, and `S(kT)/S(1)` divides by zero → `NaN` curve and a `discretize` error on empty edges. | Kernel gains a two-line guard (`if ~any(v), C = zeros(size(T)); d = emptyDist(); return`), and gate row 4 includes an empty cone. |
| E28 | rev3 §14-16 / rev4 §6.1: a `calib` rung in the scope ladder between `step` and `params`. | With self-calibration at import (E25) there is nothing for the user to change; calibration is a property of `Source`. | Ladder is `source ⊃ freq ⊃ step ⊃ params ⊃ component ⊃ {span, cut, range, annot, camera}`. No `calib` rung. |
| E29 | rev3 §0.3-11 / rev4 I1: spatial peak policy "flags unresolved beams — correctly". | True, but the drafts did not define the **scope** of the spike mask. In M7 the mask influences peak, auto-range, orientation weights and metric integrals (with the D40 bias) but not coverage. Left implicit, an implementer may either hide the raw peak or let the mask leak into coverage. | Invariant I18 in Part B: the spike mask affects **only** effective-peak reporting, auto-range presets, orientation weighting and the (renormalised) metric integrals; the grid itself, all plots, tables, exports and coverage are raw. Metadata shows raw and effective peaks side by side with the spike count. |
| E30 | rev4 §9 size budget "≤ 3,000 lines". | The additions that this revision keeps or adds (Ludwig-3, calibration from three sources, UAN header parsing, FFE block split, great-circle cuts, fixtures) are ≈ +250 lines of reader/kernel code; the Stokes removal saves ≈ 60. | Target **≈ 3,150**, hard ceiling **3,300** (−37 % vs M7). Honest rather than round. |
| E31 | rev4 §12 row 2: "identical to M7 `solidWeights` bit-exact after seam removal". | Confirmed by expression comparison: M7 computes `cosd(max(θ−Δ/2,0)) − cosd(min(θ+Δ/2,180))` per sample times `deg2rad(Δφ)` (5170–5172) — the same floating-point expression as the separable `wθ(i)·Δφ` for every sample in row `i`. Bit-exactness holds; the row stays. |
| E32 | rev2 D5 / rev4 §5.5: "Ω-weighted polarisation class". | Necessary but not sufficient. The M7 label logic (4745–4757) is itself not physical (new defect D66): "Linear (Vertical)" iff `mean|Eθ|² ≥ mean|Eφ|²` over the sphere. For a broadside x-polarised **or** y-polarised element the sphere average of `|Eφ|²` exceeds `|Eθ|²` (2π vs 2π/3 for a Hertzian dipole), so both are "Horizontal" and the word carries no information about the field at the beam. | Linear-vs-circular is decided by Ω-weighted powers **and** `|AR|` at the peak; the linear *orientation* is reported from the co-pol axis `a` at the peak: "co-pol ≈ ±X / ±Y / ±Z" or "tilted τ° from θ̂". "Vertical/Horizontal" is kept as an alias only when the boresight lies within 45° of the horizon plane, where the words mean something. |
| E33 | rev4 D45 tolerance `−1e-12` on the cone dot product. | Correct. Note for implementers: with 5-dp angle snapping the dot product of two grid directions differs from its exact value by up to ≈ 1.7e-7 (`sin(1e-5°)`), so `1e-12` only fixes *round-off*, not *snap-off*. A sample intended to lie exactly on the cone (α a multiple of the step) is still inside because both `θ` and `α` are snapped to the same lattice. | Gate row 6 states the sample-on-boundary fixture with snapped angles explicitly. |
| E34 | rev3 §6.2 `guard` re-entrancy: "return if `Busy`". | Silently dropping a user action (e.g., a component change during a long load) is surprising. | `guard` **defers** the last requested scope (`app.Pending = max(Pending, scope)`) and replays it once when the running stage finishes; only true re-entrant *storms* (`ValueChangingFcn`) are dropped. |
| E35 | rev4 §10 grep list: `"reshape"` must be zero outside `createComponents`. | `pat_normalize` step 6 is literally `reshape(…, nθ, nφ)`; the list contradicts §5.2. | The static check excludes `pat_normalize`; the intent ("no `reshape`/`sub2ind` in consumers") is kept. |
| E36 | rev4 Appendix B.5 Ludwig-3 rotation `Eθ = Eco·c + Ecx·s`, `Eφ = −Eco·s + Ecx·c`. | Sign of the rotation depends on the reference axis and on whether GRASP's `ICOMP=3` co/cx is defined as Ludwig-3 with the x-axis as co-pol reference (GRASP default) — the draft's open decision §14-19 stands. The kernel is kept but the self-test must use **two** analytic fixtures (x-dipole and y-dipole) so a wrong sign fails loudly. | Gate row 14 has both fixtures; `Meta.Ludwig3Ref` recorded. |

## A.4 New defects found in this audit (D51–D66)

Line numbers refer to `APAT_v3_M7_110_5.m`. All are reproduced in Part B §9 with their M8 mechanism.

| # | Where | Defect | Class |
|---|---|---|---|
| D51 | 1251–1253 vs 1317 | Polar-3-D surface radius is normalised **twice** (`(G−lo)/(hi−lo)` then `/max(radius)`); the cut overlay uses only the first normalisation. Whenever the colour maximum is not the pattern maximum (any manual range) the overlay sits inside the surface and is hidden. | graphics |
| D52 | 1355 | `cutData` sets a **permanent** status ("Requested … snapped to …") on every snapped cut, overwriting the pattern/POB status line; `cutData` runs up to three times per cut change (1396, 1311×2). | UI |
| D53 | 421–424 | 1° "decimation" keeps samples whose angles are integers. Exact only if `1/step ∈ ℕ`; a 0.3° source yields a **3°** grid, silently. Mixed steps (θ 0.5°, φ 1°) miss the exact path and are interpolated. | numerical |
| D54 | 4033–4048, 5154–5161 | Gain-only CSV with several columns: `chooseGain` falls back to **column 3 whatever it is** (may be AR, phase, a second frequency). POB, orientation, auto-range and coverage default follow. | dataflow |
| D55 | 4162–4167 | XGTD UAN/FZ header (`begin_<parameters>` … `end_<parameters>`) is skipped entirely. `magnitude linear`, `phase radians`, `polarization` other than `theta_phi`, `pattern` other than `gain`, and `maximum_gain` are all ignored → silent misread for any file not in the assumed dB/degrees/θφ form. | I/O |
| D56 | 4156–4159, 4185–4190 | FEKO `.ffe`: columns 7–9 (`Gain(Total)` or `Directivity(Total)`, dB) are discarded, then gain is *re-derived* from raw `rE` in the wrong units (D38). Free, exact calibration thrown away. `#Coordinate System: UV` files are not rejected. | I/O |
| D57 | 4192–4219 | HFSS `.ffd`: the companion `<name>.txt` (frequencies, radiated/accepted power) is never read; the only calibration source for FFD is ignored. | I/O |
| D58 | 4009–4013 | Generic text import: `rmmissing(readtable(…))` drops **any row with a NaN in any column** — including trailing columns that are not used. Files with a sparse extra column lose samples silently, and the grid becomes irregular (`gridComp` NaN holes). | I/O |
| D59 | 2833 → 2797 → 2845, then 2834 | Gain-only component change calls `Single_Switch_EHplaneValueChanged` → `onCutChanged` → `plotCut`, then `updateViewResults(true, …)` → `plotCut` again: the cut is rendered twice, the cut annotations are torn down twice. | perf |
| D60 | 1590, 1596 | Threshold preset (`"threshold"`) and coverage X-range (`"plot"`) only ever **widen** (`min/max` against the current value). After a few patterns/components a 50-dB window becomes 100+ dB; the threshold vector, compute time and the results table grow without the user asking. | UI |
| D61 | 4906 | Field rounding to 5 decimals, quantified: relative error `1e-5/|E|` — 1 % (0.09 dB) at `|E| = 1e-3`, 10 % (0.8 dB) at `1e-4`, total loss at `1e-5`. CST/FEKO raw far fields are routinely `O(1e-2)` V at the peak, so sidelobes from −40 dB down are corrupted before any processing. | numerical |
| D62 | 1438, 1458 | Cut POB marker and HPBW are computed on `componentData(:,1)` = the first **checked** trace; with Total unchecked they describe a cross-pol trace while the label still says "HPBW". | UI |
| D63 | 4745–4757 | Polarisation label "Linear (Vertical/Horizontal)" from sphere-averaged `|Eθ|²` vs `|Eφ|²` — basis-dependent, not physical (see E32). | physics |
| D64 | 2000–2012, 2119–2126 | Re-selecting the loaded file in the Main file dialog is refused (forces a re-browse loop), while `Process` re-parses generic files anyway; two paths for one intent. | UX |
| D65 | 1922–1929 | `startPerf` writes `Perf_<class>` into the **base workspace** with `assignin` on every load/process/step/coverage action, unconditionally. | hygiene |
| D66 | 1817 | `statusLabel.UserData = statusLabel.UserData;` — dead statement in `setStatus`. (Trivial; listed because the line is in the one status path everything uses.) | hygiene |

Also re-confirmed as accurate (no new ID): the coverage detector false-positive on a single-cut gain CSV (4021–4023), `viewRevision` bump only in `applyAngularSpan` (458) which is reached from `refresh` via `applyStep` so parameter changes do invalidate coverage keys correctly; the `gridCache` schema mismatch between `emptyGridCache` (5199) and `gridComp` (501) is harmless because `isfield(cache,'topology')` is false and the cache is rebuilt.

## A.5 Structural changes relative to the drafts

**Removed (O4 or superseded):**

- `pat_stokes`, `pat_fromStokes`, the Stokes-domain resampling path, the per-cell phase-reference repair.
- Stokes-tilt E/H-plane selection and grid-plane snapping.
- The "reference power" spinner (E25).
- The `calib` scope rung (E28).

**Added:**

- **Column registry `Const.Columns`** (name, label, kind ∈ {gain, ar, plf, phase, link}, `lossAdditive`, `hiddenByDefault`, unit class). One table drives component items, results-filter defaults, colour theme, loss application, coverage distribution keys, link-parameter visibility, resampling domain (linear power for `gain`), and the gain-only fallback (D54). It replaces `HiddenOutputColumns`, `componentMap`, `isARComponent`, `isGainDBColumn`, `cutCols`' column lists and the six string literals in `updateInputVisibility`.
- **Non-Stokes resampling** with the phase-coherence diagnostic (E22).
- **Co-pol axis & great-circle cuts** (E23): exact E/H planes for any boresight; arbitrary plane cuts as a by-product; physical polarisation wording (D63).
- **Import self-calibration** from FFE gain columns, FFD companion `.txt`, FFS header power, UAN header (`maximum_gain`, units) — D55–D57.
- **UAN header parser** (D55) and FFE `UV` rejection (D56).
- **Fixture generators `fx_*`** (isotropic, Hertzian x/y/z dipoles, crossed dipoles in quadrature, Gaussian beam, hemisphere, spike, phase-slope offset) shared by every self-test row — the self-test becomes readable and the fixtures become the documentation of each convention.
- **Deferred replay** in `guard` (E34).
- Defect mechanisms for D51–D66.

**Kept exactly:** separable geometry, `cov_ccdf` family (+ guard), params-free base / element-wise params, `met_peak`, `update(scope)`, `readConfig`/`apply*` split, retained-mode registry with dirty keys, display map as a permutation, lazy tables/tabs, one timer, one context menu, static self-test, one-file constraint, R2023b baseline, no toolboxes.

## A.6 Design-axis comparison across the drafts

| Axis | Draft 1 | Rev 2 | Rev 3 | Rev 4 | **Rev 5 (this)** |
|---|---|---|---|---|---|
| Resampling domain | Re/Im primitives | Re/Im | Stokes `I,Q,U,V` | Stokes + phase-ref repair | **Per-component power + unit phasor** (no Stokes), coherence diagnostic |
| Peak policy | P99.99 + 6 dB | sort-based quantile | spatial isolation | + pole ring | spatial isolation + pole ring, **scope pinned (I18)** |
| Solid angle | `solidWeights` once | midpoint edges | midpoint + φ gap averaging | **separable `wθ·Δφ`** | separable (unchanged) |
| Coverage kernel | sorted dist | sorted dist | `cov_dist/curve/inverse` | `cov_ccdf` + oracle | `cov_ccdf` + oracle **+ empty-region guard** |
| E/H planes | principal axes | principal axes | Stokes tilt, grid snap | same | **ellipse major axis + great-circle cuts** |
| Polarisation label | M7 | Ω-weighted M7 | same | same | Ω-weighted class **+ co-pol axis wording** (D63) |
| Calibration | — | — | — | `Meta.Calibration`, spinner later | **self-calibration from FFE/FFD-txt/FFS/UAN**, no spinner |
| Circular sign | implicit | implicit | implicit | `Const.CircularSign` | same, owner-verify gate kept |
| Column semantics | literals | literals | `GainColumns`, `LossAdditive` | same | **`Const.Columns` registry** |
| Re-entrancy | — | — | `Busy` drop | same | **`Busy` + deferred replay** |
| Size target | ≈ 3,400 | ≤ 3,000 | ≤ 3,000 | ≤ 3,000 | **≈ 3,150, ceiling 3,300** |
| Defects catalogued | ~12 | 16 | 35 | 50 | **66** |

## A.7 Owner decisions — status after this revision

Closed by owner: uniform axes (O1), canonical-grid coverage (O2), explicit CCDF (O3), **no Stokes (O4)**, two-part document (O5).

Closed by this audit's evidence: reference-power spinner (not needed for FFE/FFD/FFS — E25); `calib` rung (E28).

Still open — recommendations are in Part B §15: circular sign, non-uniform-axis handling, Ω at non-polar domain ends, Ludwig-3 reference axis, UAN `maximum_gain` semantics, signed-AR rendering of exactly-linear samples, great-circle vs grid-snapped E/H display, coverage node provenance display, cut-value spinner units.

---
---
