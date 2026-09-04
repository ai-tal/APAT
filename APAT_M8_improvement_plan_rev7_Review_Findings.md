# APAT M8 — Review Findings & Comparison (rev 7)

**Subject reviewed:** `APAT_v3_M7_110_5.m` — 5,199 lines, one App Designer-style class, 183 functions (95 methods, 34 file-scope functions, 682 lines of hand-written layout at 3013–3694).
**Also reviewed:** the previous improvement-plan draft (rev 6 plan + rev 6 review findings) and the owner's request to make the resulting APAT more concise (target < 3,000 lines, or thereabouts).
**Companion document:** `APAT_M8_Improvement_Plan_rev7.md` — the standalone plan. It does **not** refer to this document or to any earlier draft. This document is the *audit trail*: what was checked, what stands from the previous draft, what was wrong or missing, what was added, what was cut, and why the size target moved.

---

## 1. Method

1. The whole M7 file was read again, section by section: properties/constants 1–251, public methods 252–1931, private callbacks 1933–3011, layout 3013–3694, lifecycle/self-test 3695–3875, readers 3877–4563, numerical core 4565–5200. Nothing was sampled.
2. Call graphs traced by hand: load → `refresh` → `applyStep` → `applyAngularSpan` → `updateViewResults` → renderers; `Single_Switch_EHplaneValueChanged` → `onCutChanged` → `drawSpatial3D`; component / cut / range / span callbacks; the coverage tab end to end.
3. Hot-spot counts taken mechanically with `grep` so that "X is done in N places" is a fact. Where the previous draft quoted a count, it was re-measured.
4. Every finding of the previous draft was re-verified against the code before being kept. Every new finding below cites lines and was confirmed by reading both sides of the relevant call.
5. The previous draft's *size* claim was tested against the actual composition of the file, which showed a lever the draft had excluded by assumption (§5).

---

## 2. Owner directions applied in this revision

| # | Direction | How it is applied |
|---|---|---|
| O1 | Review the whole code deeply; improve architecture/algorithm/dataflow so logic is concise, transparent, fast and robust. | Four collapsing observations (§5) now drive the plan; eight new defects found (§4.2). |
| O2 | Aim for < 3,000 lines. | Section budgets sum to 2,630; target ≤ 2,800; hard ceiling 3,000 enforced as a gate. The decisive lever is the layout (§5.4). |
| O3 | Findings/comparison and the standalone plan are separate documents; the plan must not refer to earlier revisions. | Two files. The plan is anchored only to M7 line numbers and its own appendices. |
| O4 | No over-engineering (proportionality). | Every addition below is either a verified defect fix or removes code. Two items of the previous draft were tightened further (§4.3). |

---

## 3. M7 anatomy in numbers (re-measured)

| Fact | Count / lines | Consequence |
|---|---|---|
| Table copies of one sphere per refresh | 6 (`rawTbl, stdTbl, patTbl, viewBaseTbl, viewTbl, uanTbl`, 189–194) + 2 per coverage node (1684–1686) | Every stage re-derives grid structure from a long table. |
| `physicalTheta(...)` call sites | 13 | Display convention stored *in the data* (453) and undone downstream — forgotten in 3 numerical paths (F02). |
| `gridStep(...)` / `solidWeights(...)` / `resolvePeak(...)` | 17 / 6 / 10 | Step, ΔΩ and the 65k-sample `prctile` are recomputed per consumer. |
| `findall` / `findobj` / `cla(` / `legend(` / `drawnow` | 9 / 2 / 6 / 5 / 8 | Renderers locate their own objects by tag; every change rebuilds and re-legends. |
| Widget `.UserData` used as application state | 14 sites | Flags in `Single_DropDown_step`, `CutFieldBasisDropDown`, `Single_DropDown_output`, `Cov_gridPanel_Parm`, both status labels. |
| `NodeData` read/write sites | 48 | Coverage state is spread over tree nodes with ad-hoc fields. |
| Constants threaded through signatures | `PeakPercentile` at 13 sites, `PeakMaxExcessDB` alongside | Six function signatures carry two constants. |
| Columns computed eagerly per refresh | 17 (9 hidden by default) | EIRP/PFD/E_RMS/phases computed for 65k samples even when never shown. |
| Full-pattern tabs rendered per change | 5 (1 visible), **7 on load when the overlay box is checked** | Dominant cost of component change and load (F41, F60). |
| Duplicate algorithms | `cutGeometry` ≡ `calcCutGeometry`; `gainDisplayRange` ≡ `coverageDisplayRange`; 4 inline circular splits; 5 near-identical six-column reader cases | A policy change must be made in 2–5 places. |
| **Layout** | **682 lines, 118 widget constructors, 181 `Layout.Row/Column` statements, 16 grids; helpers `createRightLabel`/`createPatternTab` already exist (3015–3070)** | **Hand-written, therefore compressible without touching a widget.** |
| Blank / comment-only lines | 801 | Not a target in itself; the budgets count real statements. |
| Dead state | `coverageRangeState`: 4 of 9 fields write-only; `markCoverageThresholdUserEdit` wired 3× with no reader | The "user edited" behaviour the comments describe does not exist. |

---

## 4. Findings

IDs **F01–F57** are carried over unchanged so the register can be cross-read; **F58–F65** are new in this review. Status: **V** = re-verified defect from the previous draft, **N** = new, **S** = sharpened (previous description understated it).

### 4.1 Previous findings — all re-verified

All 57 rows of the previous register were checked against the cited lines and stand. Two deserve a note:

| ID | St. | Note |
|---|---|---|
| F12 | **S** | The previous draft described the component-dependent *boresight and POB*. The trace goes further: `updateViewResults` (2810–2811) passes the **component** peak to `computeMetrics` → `calcMetrics`, which uses `peakInfo.value` as `peakGain` (4615–4617) against the **total-gain** integral (4635–4636). With "Axial Ratio" selected, directivity is `AR_peak_dB − 10·log10(∫G)` and F/B is `AR_peak − G_back`: the Metadata table shows meaningless numbers, not just a moved axis. The plan pins metrics to total gain (I4) and adds gate row 20. |
| C1 (circular sense) | V | Re-derived once more: `E_R = (Eθ + jEφ)/√2` is the IEEE right-hand *component* under `e^{+jωt}` (projection on the conjugate basis vector). M7 lines 4726–4727 are correct; the readers' inverse (4083–4084, 4143–4144, 4175–4176) is consistent. Nothing to change; one fixture pins it. |

### 4.2 New findings (N)

| ID | St. | M7 lines | Finding |
|---|---|---|---|
| **F58** | N | 1329 vs 1386, 2833 | **Gain-only cut plots the wrong column.** `cutCols` returns `VariableNames(3)` unconditionally for gain-only sources; `cutData` titles the cut with `app.comp()` (the selected column); `onComponentChanged` re-plots via the E/H switch. A generic gain file with several columns (e.g. Gain, AR, Directivity) shows the *first* column's cut labelled with whatever the user selected. Confirmed by reading both call sites; no code path passes the component into the cut for gain-only. |
| **F59** | N | 5002–5012 vs 5019–5022; 4922–4923 | **`LinearPowerForGain` is dead on the regular-grid path.** `resampleCanonical` converts to linear power only in the *scattered* branch. The regular branch — the normal case for every rectangular source — calls `interpolateRegular` on raw dB. The header comment ("Gain-only sources: interpolate linear power") is false, and the M7 self-test (`numericalEquivalence`, 3746–3756) evaluates only native samples, where any interpolation is exact, so it cannot detect it. Effect: gain-only 1° resampling of a 2° source under-estimates the beam between samples (≈ 0.3 dB at the half-power points of a 20° beam) and biases HPBW/coverage. |
| **F60** | N | 355 → 2797 → 2846 → 1231–1238; then 357 | **Double 3-D render on load when "overlay cut" is checked.** `refresh` calls `Single_Switch_EHplaneValueChanged` (355) before `renderAllFullPatterns` (357); it reaches `onCutChanged` → `drawSpatial3D`, which finds no surface yet and calls `drawPattern3D` for both 3-D axes; `renderAllFullPatterns` then renders all five again. Seven `surf`-class renders per load instead of five (or one). |
| **F61** | N | 2040 → 2053; 2024–2062 | **No atomic commit.** `activateSource` (2040) overwrites `rawTbl/ffdBlocks/freqs/srcUD` and `selectBlock` writes `stdTbl` before `refresh` runs. Cancel (`APAT:Cancelled`) or any error inside `refresh` returns to a UI whose source metadata, status and dropdowns describe the new file while `viewTbl`, plots and coverage still hold the old one. Nothing rolls back. |
| **F62** | N | 232–235, 1589, 1598, 1613–1616, 2409–2412 | **Dead range state and a no-op callback.** `coverageRangeState.userEdited`, `.lastPreset`, `.evaluationBounds`, `.displayBounds` are written and never read (grep: one write site each, zero reads). `markCoverageThresholdUserEdit` — wired to three spinners in the layout — sets one of them. The behaviour the comments promise (user edits protect the threshold window) is in fact provided by `presetKey` alone. |
| **F63** | N | 644–656 vs 1361–1365, 1427 | **Cut-value control ignores the display convention.** `updateCutControl` sets `Limits/Value` from canonical `[0,360)` φ or the table's θ, while `cutData`/`plotCut` present angles in the signed/elevation convention. In signed mode the spinner says 270° and the plot's x-axis and HPBW label say −90°. |
| **F64** | N | 4915–4917 | **Seam fabricated for non-periodic sources.** `normalizePattern` always appends a φ = 360 copy of the φ = 0 rows. For a half-plane or partial-azimuth source this creates a closing column that does not exist in the data; `solidWeights` then zeros it (5173–5174) by assumption rather than by fact, and the contour/rect plots show a wrap the source does not have. |
| **F65** | N (hygiene) | 297, 315, 405, 432, 574, 628, 631, 872, 1568, 3727, 3794, 4612, … | `PeakPercentile`/`PeakMaxExcessDB` threaded through six signatures at 13 call sites. Removed with the spatial peak policy (`Const.PeakExcessDB` read by `met_peak` only). |

### 4.3 Items of the previous draft tightened or corrected in this revision

| Topic | Previous draft | This revision | Why |
|---|---|---|---|
| **Layout block** | "≈ 680 lines of *generated* layout, byte-identical except callback targets"; budgeted at 680 | Hand-written (helpers at 3015–3070; free-form `createRightLabel` calls; anonymous callbacks inline) → **declarative `place/labelled/patternTab`, budget ≤ 320**, parity verified by a new `uiInventory` gate row | The single largest lever toward < 3,000; the widget set and appearance are unchanged, only the statements that build them. |
| **Reader structure** | Explicitly kept five separate `switch` cases; rejected a "descriptor dictionary" as indirection | One 9-row `Const.ReaderSpecs` + `io_fields(M, spec)` (plan A.10) | The five cases differ only in column order and encoding; a spec row is strictly less code than the case bodies (rule (b)). The dictionary rejected earlier was a *per-format parser* abstraction — that stays rejected. |
| **Resampling** | Power + unit phasor for E-fields; gain-only mentioned only in passing | One `pat_interp(X, kind)` used by **both** regular and scattered paths, with a gate row (25) on midpoints | F59 showed that the gain-only rule was never actually applied; a single kernel makes the omission impossible. |
| **Metrics on total gain** | I4 stated; F12 described as boresight/POB | F12 sharpened to include `calcMetrics`' `peakGain`; new gate row 20 | Verified consequence is worse than described. |
| **Cuts** | `geo_cut` fixed the twin functions | Trace list from `Cols`; gain-only cut on `View.Component`; cut-value domain through `Map` | F58, F63. |
| **Seam handling** | "no seam column" as a design choice | `PhiPeriodic` measured in `pat_build`, closing column only in `Map`; gate row 2 covers `fx_halfPlane` | F64 makes it a correctness point, not just tidiness. |
| **Guard** | `try/catch` + cancel + busy | + **build-then-commit** (I13): `update` assigns `Source/Pattern/Geometry/Base` in one final statement; gate row 29 | F61. |
| **Range state** | `RangeAuto` flags | `Range.Auto` per group, cleared by the range callback itself; `markCoverageThresholdUserEdit` and `coverageRangeState` deleted | F62. |
| **Update ladder** | overlays under `cut` scope | overlays drawn only inside `renderFull` of the visible tab | F60. |
| **Size** | Budget ≤ 3,500 / ceiling 3,600 | **Budgets sum 2,630; target ≤ 2,800; ceiling 3,000 as a gate**; reserve lever (UI handles in a struct, −165 lines) held as an open decision | See §5. |
| **Self-test** | 24 rows | 29 rows: + `resampleGainOnly`, `cutComponent`, `metricsOnTotal`, `uiInventory`, `commitAtomic`; `geometryPartial` extended; `fmtNumber` gains the `100 → "100"` case | Each new defect gets a row. |
| **Deleted-name list** | 48 names | 55 names (+ `buildPatternData`, `detectOrientation`, `getParam`, `markCoverageThresholdUserEdit`, `clearCoverageSync`, `coverageQueryPoint`, `coverageSummaryMaximum`, `updateFullPatternPOBVisibility`) | Follows from the new items. |

### 4.4 Checked and left unchanged

- Excel matrix/summary readers (4227–4563): logic is correct; only the five summary helpers collapse to one `xl_lookup`. No behaviour change.
- `calcHPBW` (4860–4880): correct wrap-aware crossing; kept verbatim as `met_hpbw`.
- `calcOrientation` cone rule (4845–4850): correct once fed physical unit vectors and total gain; kept as `met_orientation`.
- `fmtNumber` regexes (704–711): produce correct output for integers, `x.5`, `0`; only `-0` is wrong (F53). The single-regex form in the plan is equivalent.
- `solidWeights` seam zeroing (5173–5174): consistent for the tables M7 builds; becomes unnecessary with a seam-free `Pattern`.

---

## 5. Why the plan is structured as it is — the four collapsing observations

1. **Loss is an offset.** Every level column in M7 is `20·log10(|E|·10^{L/20}) = X₀ + L`; PLF, AR and phase do not depend on `L`. One base at `L = 0` serves all values; coverage shifts thresholds (`Ω{X > T} = Ω{X₀ > T − L}`). The reprocess on loss change disappears.
2. **Columns are functions, not tables.** One struct array `Cols` (name, label, kind, unit, `fn`) is both registry and materialiser. A component change materialises exactly one `nθ×nφ` matrix; the eager 17-column table, its hidden-column list, the AR name matcher and the gain-column matcher go with it.
3. **A grid-native pattern makes every consumer indexing.** With `Eth, Eph` as `nθ×nφ` on uniform axes, cuts are slices, the display convention is a column permutation plus labels, ΔΩ is rank-1, the cone mask is one expression, coverage is a weighted sort. `physicalTheta`, `gridStep`, `solidWeights`, `gridComp/gridGeom`, `applyAngularSpan`, both cut twins and the seam logic vanish, and F02/F28/F29/F35/F63/F64 cannot recur.
4. **The UI is declared, not scripted.** A grid child is five facts (constructor, parent, row, column, defaults). `place` states them once; 682 lines become ≤ 320 with the same widgets. This observation was missing from the previous draft, which had treated the layout as frozen generated code.

### 5.1 Size arithmetic

| Section | Previous budget | rev 7 budget | Δ | Source of the saving |
|---|---|---|---|---|
| A + B | 260 | 240 | −20 | `Views`, `RangeGroups`, `ReaderSpecs` tables replace scattered arrays |
| C orchestration | 380 | 320 | −60 | fewer scopes to special-case; `Range.Auto` replaces 9-field state |
| D renderers | 520 | 420 | −100 | five kinds behind `Const.Views` + `viewCoords`; overlays inside `renderFull` |
| E coverage UI | 380 | 320 | −60 | dead state and query interpolation helpers gone |
| F export | 90 | 80 | −10 | |
| G layout | 680 | 320 | −360 | `place/labelled/patternTab` |
| H lifecycle | 90 | 60 | −30 | one timer, one shutdown |
| I self-test | 220 | 170 | −50 | table-driven rows, shared fixtures |
| readers | 520 | 400 | −120 | `io_fields` + specs; `xl_lookup` |
| numerical core | 360 | 300 | −60 | one `pat_interp`; no constant threading |
| **Total** | **3,500 / 3,600** | **2,630 sum; ≤ 2,800 target; 3,000 ceiling** | **−870** | |

The 3,000 ceiling is a gate, not a promise; the reserve lever (§16-7 of the plan) buys another ≈ 165 lines if step 8 of the work order lands high.

---

## 6. Design-axis comparison — previous draft vs rev 7

| Axis | Previous draft | **rev 7** |
|---|---|---|
| Pattern representation | grid-native `Pattern` + `Map` | same |
| Geometry | separable `wθ·Δφ` | same, `PhiPeriodic` measured (F64) |
| Columns | `Cols` struct array with `fn` | same; gain-only cuts/coverage on the selected column (F58) |
| Loss | offset at point of use | same |
| Peak | spatial isolation, 6 dB | same; constants no longer threaded (F65) |
| Resampling | field: power + phasor; gain: linear power (stated) | **one `pat_interp(kind)` for both grid paths**, tested at midpoints (F59) |
| Metrics | total gain (I4) | same, with the `calcMetrics` consequence of F12 named and gated |
| Coverage | `cov_dist/eval/inverse`, loss by shift | same |
| Orchestration | `update(scope)` + `guard` | same + **build-then-commit** (F61); overlays in `renderFull` (F60) |
| Range UI | `applyRange` + `RangeAuto` | same; **dead state and no-op callback deleted** (F62) |
| Cut controls | via `applyChoices` | same, **domain through `Map`** (F63) |
| Readers | five `switch` cases + block split + header assertions | **`io_fields` + 9-row spec table**, block split, header assertions |
| Layout | frozen at ≈ 680 lines | **declarative, ≤ 320 lines, inventory-verified** |
| Self-test | 24 rows | 29 rows |
| Size | ≤ 3,500 / 3,600 | **≤ 2,800 / 3,000** |
| Defects catalogued | 57 | 65 (+ F12 sharpened) |

---

## 7. What was considered and not admitted (proportionality)

| Candidate | Reason not admitted |
|---|---|
| Moving all UI handles into `app.UI` struct | Saves ≈ 165 lines but loses tab-completion and per-handle typing; kept as a reserve lever only (plan §16-7). |
| A generic "reader DSL" (line grammar, tokenisers) | The formats are five column orders plus three block-structured files; a spec row covers the former, small readers the latter. |
| Caching resampled blocks for all frequencies eagerly | Lazy per `(FreqIndex, step)` is simpler and cheaper. |
| Progressive/async rendering | App Designer callbacks are serialised; the retained-mode design already makes each action sub-100 ms. |
| Removing the Input tab raw table | It is a feature; it is pushed lazily instead. |
| Changing any widget, its arrangement or defaults | Out of scope by rule; parity is enforced by the inventory gate. |

---

## 8. Decisions still open for the owner

Only items the plan cannot decide by itself; each has a recommendation in the plan §16.

1. **Non-uniform source axes** — error, or regularise once inside the hull and disclose (recommended).
2. **Exactly-linear samples in the signed-AR view** — NaN/white (recommended) or 0 dB centre.
3. **Peak excess** — keep 6 dB (recommended).
4. **FEKO `Gain(Total)` column for `dBi` labelling** — defer (recommended).
5. **Body-of-revolution φ step for single `.cut`** — keep 10°, disclosed (recommended).
6. **E/H planes for oblique boresights** — principal-axis fallback (recommended).
7. **UI handles as a struct** — keep declared properties; reserve lever only (recommended).
8. **Gain-only cut traces** — selected column only (recommended) vs selected + first gain column.
