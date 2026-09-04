# APAT M8 — Review Findings & Comparison

**Subject reviewed:** `APAT_v3_M7_110_5.m` — 5,199 lines, one App Designer-style class, 183 functions (95 methods, 34 file-scope functions, the rest nested/self-test), 622 lines of hand-written layout in `createComponents` (3072–3693) plus 58 lines of layout helpers (3013–3070).

**Companion document:** `APAT_M8_Improvement_Plan.md` — the standalone plan. This document is the *audit trail*: what was checked, what stands from the previous draft, what was changed and why, and how the defect IDs map.

---

## 1. Method

1. The whole M7 file was read again, section by section, nothing sampled: properties/constants 1–251, public methods 252–1931, private callbacks 1933–3011, layout 3013–3694, lifecycle/self-test 3695–3875, readers 3877–4563, numerical core 4565–5200.
2. Call graphs traced by hand — load → `refresh` → `applyStep` → `applyAngularSpan` → `updateViewResults` → renderers; **`onProcess` → `refresh`** (this pass, §4.2 D55); `Single_Switch_EHplaneValueChanged` → `onCutChanged` → `drawSpatial3D`; component / cut / range / span callbacks; the coverage tab end to end including tree selection, checked-nodes, compute, query, clear and reset.
3. Hot-spot counts re-taken mechanically with `grep` (§3). One count was corrected (`Layout.Row/Column` statements: 185, not 183).
4. Every row of the previous register (D01–D70) was re-verified against the cited lines before being kept (§4.1). Four new findings came out of the tracing and of a write/read audit of every `NodeData` field and every constant (§4.2).
5. The owner's directions were applied one by one (§2); for each, the plan text, the kernels, the register and the size budget were adjusted so that the plan stands on its own.
6. The previous plan's design was then tested for *further* collapse under O1 and O2. The result: once the pattern is grid-native, **every derived quantity costs tens of milliseconds** — so the previous plan's memoised column cache, loss-as-offset invariant, distribution cache and two-kind job model are optimisations of things that no longer need optimising. Removing them removes concepts, fields, keys and functions (§5).

---

## 2. Owner directions applied in this pass

| # | Owner direction | How it is applied in the plan |
|---|---|---|
| O1 | Deep re-review; more concise logic; ≤ ≈ 3,000 lines. | Whole file re-read (§1). Beyond the previous plan, four more collapses (§5.2–5.5): eager `pat_derive` instead of a memoised column cache; parameters in one function instead of a loss offset carried by every consumer; `Const.Cols` as metadata only, with the formulas as plain lines in `pat_derive`; `Geometry.dOmega` stored once instead of rebuilt as a rank-1 product at three sites. Budget sum moves from 2,210 to **≈ 2,130**; target ≤ 2,500; ceiling 3,000. |
| O2 | Coverage query via `interp1` on the curve, as M7; no complex distribution machinery. | Coverage is now **one kernel** `cov_curve` (five lines, the definition verbatim, `arrayfun` over thresholds) whose result is a curve, plus **two two-line reads** `cov_at` / `thr_at` — the exact M7 `interp1` idiom (`unique(cov,'last')` for the inverse). Gone: `cov_dist`, `cov_eval`, `cov_inverse`, `job_eval`, `job_inverse`, the sorted `S` vector, `Pats(k).Dist`, `regionTag` keys, the loss-shift `T − L`, the computed-vs-loaded job distinction. A job is `{id, label, T, cov, Line, Query}` whatever its origin. §6 states the trade-off. |
| O3 | Separate documents; plan standalone. | Two files. The plan has no "previous draft", "this revision", "new in this review" or "retired" language; defect IDs are contiguous D01–D74 in category order, so the plan shows no history. The mapping is in §8 of this document. |

Directions kept from the previous pass and still in force: no self-test or fixtures in the file; the performance tracker kept as one eight-line method with M7's record shape and base-workspace channel.

---

## 3. M7 anatomy in numbers (re-measured this pass)

| Fact | Count / lines | Consequence |
|---|---|---|
| Functions | 183 (95 methods, 34 file-scope, plus nested/self-test) | — |
| Table copies of one sphere per refresh | 6 (`rawTbl, stdTbl, patTbl, viewBaseTbl, viewTbl, uanTbl`, 189–194) + 2 per coverage node (1684–1686) | Every stage re-derives grid structure from a long table. |
| `physicalTheta(` call sites | 13 | Display convention stored *in the data* (453) and undone downstream — forgotten in 3 numerical paths (D02). |
| `gridStep(` / `solidWeights(` / `resolvePeak(` | 17 / 6 / 10 | Step, ΔΩ and the 65k-sample `prctile` are recomputed per consumer. |
| `findall` + `findobj` / `cla(` / `drawnow` | 11 / 6 / 8 | Renderers locate their own objects by tag; every change rebuilds. |
| `UserData` tokens / assignment sites on widgets | 43 / 14 | Flags in `Single_DropDown_step`, `CutFieldBasisDropDown`, `Single_DropDown_output`, `Cov_gridPanel_Parm`, both status labels, plus per-marker annotation records. |
| `NodeData` tokens | 48 | Coverage state spread over tree nodes; **eleven** fields are write-only (D49 + D54). |
| `setCoverageUI(` / `finalizeCoverageJobs(` / `syncCoveragePattern(` call sites | 7 / 5 / 4 | Visibility code re-enters numerics (D53); each sync runs `prctile` (D37). |
| `app.refresh()` call sites | 4 (1804 `resetParams`, 2053 `onLoad`, 2128 `onProcess`, 2803 `onFFDChanged`) | Two of the four are parameter-only changes that nevertheless run the full pipeline (D55). |
| Constants threaded through signatures | `PeakPercentile` at 13 sites | Six signatures carry two constants. |
| Columns computed eagerly per refresh | 17 (9 hidden by default) | Cheap in matrices; expensive as a 65k-row table pushed to `uitable`. |
| Full-pattern tabs rendered per change | 5 (1 visible), 7 on load when the overlay box is checked | Dominant cost of component change and load (D57, D72). |
| Duplicate algorithms | `cutGeometry` ≡ `calcCutGeometry`; `gainDisplayRange` ≡ `coverageDisplayRange`; 4 inline circular splits (9 `sqrt(2)`); 5 near-identical six-column reader cases; two identical table constructions 4318–4326 | A policy change must be made in 2–5 places. |
| `interp1(` | 4 (2595, 2596 query; 1766 table; 858 colormap) | The curve-read idiom already exists in M7 — three of the four sites are the ones M8 keeps. |
| Coverage query path | `coverageQueryPoint` (4 lines) + `coverageInterpolationLocation` (14) + `covRunQuery` (71, with 3 nested `try/catch`) | ≈ 90 lines to place one datatip and two dotted lines per curve (D74). |
| **Layout** | **622 lines in `createComponents`, 118 widget constructors, 185 `Layout.Row/Column` statements, 16 grids** | Hand-written, therefore compressible without touching a widget. |
| Excel summary reader | 164 lines (4400–4563) | One consumer (`frequencyMHz → hasFrequency`, 4337), never read for Excel (D30). |
| Empty `catch` blocks | 5 (1108, 1183, 1493, 2641, 2666) | Errors swallowed (D73). |
| Toolbox dependency | `prctile` ×1 (5113) — Statistics and Machine Learning Toolbox | M7 does not run on base MATLAB. |
| Self-test | `runSelfTest` 3715–3858 (144 lines) + 12 `pass*` fields | Removed (owner direction, previous pass). |
| Perf tracker | `startPerf` 1922–1930 + `perfTracker` property (237) + 26 call-site tokens | Kept, reduced to one method. |

---

## 4. Findings

### 4.1 Previous register — re-verified

All 70 rows of the previous register (D01–D70) were checked against the cited lines. All stand. Notes on the ones re-examined in the light of O2:

| Previous ID | Note |
|---|---|
| D10 | Re-confirmed: `regionGain > thresholds.'` (4593) is a 65,160 × 501 logical (32.6 MB); `regionWeight.' * indicator` (4597) is `mtimes` with a logical operand, promoted to double → 261 MB. The plan's `cov_curve` does the same arithmetic with `O(N)` memory and no cache at all (the previous draft still kept a per-(column, region) distribution cache; now split as D10 memory + new D56 cache/eager-inverse). |
| D11 | `thresholds = (tMin:step:tMax)'` (1525) plus an appended `tMax` — kept as "counting" in the plan. |
| D36 | Foreign coverage patterns: the previous draft resolved this with `L` applied at compute time from an `L = 0` distribution. With parameters entering only in `pat_derive`, the plan instead shows the entry's `Params` in the node tooltip and every job label and re-derives on selection when they differ — one mechanism, no shift arithmetic. |
| D37 | Cascade re-confirmed (2702 → 1724 → 1548 → 2484 → 1663 → `resolvePeak` → `prctile`). Closed by `Derived.Peak` computed once per derivation. |
| D48 | `covThresholds` writes `Cov_Spinner_ThreshMax.Value` (1523) and is called from `covRebuildTable` (1758) on every check/uncheck — a table rebuild can move a spinner. Unchanged. |
| D49 | Re-confirmed and extended: the write/read audit of every `NodeData` field found seven more write-only fields (new D54). |
| D57 (prev. D54) | Re-confirmed: `renderAllFullPatterns` (997–1013) loops over all five specs regardless of the selected tab. |

### 4.2 New findings (this pass)

| New ID | M7 lines | Finding |
|---|---|---|
| **D54** | 1686, 1707–1709, 2361–2367, 243 | **Seven more write-only fields and one dead constant.** Job `NodeData` fields `tablePrecision` (1707), `summarySource` (1708), `sourceKind` (1686), `coneTheta`, `conePhi`, `coneAngle` (2365–2367) are assigned and never read anywhere in the application; `orientationIndex` (1709, 2361) is read only by the self-test (3828). The constant `StandardColumns` (243) has no reader. Found by grepping every field name for a read site. Closed: a job node holds `{id, label, T, cov, Line, Query}` and nothing else; the constant does not exist. |
| **D55** | 2112–2134 → 314 → 351, 355, 357 | **A parameter change resets user choices it did not invalidate.** `onProcess` (Process button: loss, Rx mode/AR, Pt, R) calls `refresh`, which (a) calls `updateViewResults(true, …)` — `refreshRanges = true` re-applies the automatic colour-range preset over whatever range the user had set; (b) calls `Single_Switch_EHplaneValueChanged` (355), which rewrites `Single_DropDown_cutType/cutValue` from the E/H switch, discarding a manually chosen cut; (c) calls `renderAllFullPatterns` (357), redrawing five views. `resetParams` (1804) does the same. Only values changed; the cut geometry, the display convention and the user's range did not. Closed: `on("params")` = `pat_derive` + redraw of the visible tab, cut `YData` and metadata; cut controls and ranges untouched. |
| **D56** | 1703, 1706–1707; 2275–2279, 2349–2356 | **Cache infrastructure around a 30 ms computation.** `covAddJob` eagerly computes the inverse curve (`unique(coverage,'last')`, 1703) and stores it as `inverseCov/inverseThr` on every job (1706–1707); `Cov_Button_computeCovPushed` builds a `coverageCacheKey` from component, revision, region tag and the threshold vector (2275–2279) and keeps a `coverageCache` struct on the pattern node (2349–2356) — so a changed threshold step is a guaranteed miss, and the status line has a "reused cached CCDF" branch (2374). The computation it protects costs ≈ 30 ms (B.6 of the plan). Closed: no cache; the inverse is derived by `thr_at` when a query asks for it. |
| **D74** | 2598–2611, 2647–2668 | **One datatip, four code paths.** `coverageInterpolationLocation` (14 lines) converts an exact `x` into a `DataIndex` + `InterpolationFactor`, then `covRunQuery` tries `datatip(...,'DataIndex',…,'InterpolationFactor',…)`, falls back to `datatip(line, x, y)`, then tries to set the three properties afterwards inside a third `try`, with two of the three `catch` blocks empty. The R2023b baseline accepts `datatip(h, x, y, 'SnapToDataVertex','off')` directly. Closed: one call. |

### 4.3 Checked and left unchanged (re-confirmed)

- Excel **matrix** readers (`readExcelMatrix`, `readExcelMatrixSheet`, 4227–4398): logic correct; only the duplicated `raw`/`block` construction (4318–4326) collapses to one.
- `calcHPBW` (4860–4880): correct wrap-aware crossing; kept verbatim as `met_hpbw`.
- `calcOrientation` cone rule (4845–4850): correct once fed physical unit vectors and total gain; kept as `met_orientation`, written with the same spherical-law-of-cosines expression as the coverage cone mask.
- `planeSettings` (634–642): kept verbatim as `met_planes`.
- `fmtNumber` regexes (704–711): correct except `-0` (D67).
- `.cut` negative-θ fold and 10° revolution (4130–4137): kept.
- `writeUANFile` header text (1903–1906): kept; only `maximum_gain` changes (D29).
- `coverageCCDF` (4565–4598): the *definition* it implements is correct and is exactly what `cov_curve` computes; only its memory footprint was wrong (D10). The plan's §13.1 uses M7's output as the numerical reference.
- `coverageQueryPoint` (2593–2596) and the table union in `covRebuildTable` (1766): the **`interp1` idiom itself is kept** — it becomes `cov_at`/`thr_at` and the only two `interp1` calls in the file.

---

## 5. Changes to the plan in this pass — and why

### 5.1 Coverage (owner direction O2)

| Aspect | Previous draft | This plan | Why |
|---|---|---|---|
| Kernel | `cov_dist` (sort samples, weights, `Ω_R`, reverse-cumulative `S`) + `cov_eval` (loop) + `cov_inverse` (`find` on `S`) | **`cov_curve`** — five lines: mask, levels, weights, `Ω_R`, `arrayfun(@(t) sum(w(g > t)), T)` | The definition needs no sorted list. Sorting existed only to make the inverse exact; the owner prefers the `interp1` inverse. |
| Job model | two kinds: computed `{k, col, region, T, L}` (re-evaluated from the distribution) vs loaded `{Curve}`; two dispatchers `job_eval` / `job_inverse` | **one kind**: `{id, label, T, cov, Line, Query}` for both | Once every job is a curve, computed and loaded jobs are indistinguishable; the dispatchers and the `isfield(j,'k')` branches disappear. |
| Query / inverse / table | `job_eval` → `cov_eval(d, T − L)`; `job_inverse` → `cov_inverse(d, c) + L`; table = `job_eval(T_union)` | `cov_at(job, T) = interp1(job.T, job.cov, T)`; `thr_at(job, c) = interp1(unique(cov,'last'), T(i), c)`; table = `cov_at(job, T_union)` | M7's idiom, one line each, no special cases. Values between threshold samples are linear reads of the curve — the same numbers the plotted polyline shows. |
| Loss | distribution at `L = 0`, `T − L` shift (derivation B.3) | column already at `L` (`pat_derive`), curve computed directly | Follows from §5.3; no shift arithmetic anywhere. |
| Cache | `Pats(k).Dist.(colKey).(regionTag)` keyed by `Revision` | **none** | A compute click costs ≈ 30 ms; a cache adds keys, invalidation and a code path that cannot be felt. |
| Query artefacts | one `datatip` at the exact coordinate (already) | same, and D74 documents why M7's four paths go | — |
| Selection status | `job_inverse(50)` + max | `thr_at(job, 50)` + `max(job.cov)` | — |
| Lines | ≈ 60 (kernels) + dispatchers | ≈ 25 | — |

### 5.2 Eager derivation instead of a memoised column cache (O1)

| Aspect | Previous draft | This plan | Why |
|---|---|---|---|
| Columns | `Const.Cols` rows carry `fn(P,G,prm)` handles; `col(app,k,name)` evaluates on demand and memoises in `Pats(k).ColCache` under a per-kind key (`Revision`, `Revision|Rx`, `Revision|Pt|R|L`) | **`pat_derive(P, G, prm)`** computes every column and every base fact into `Pats(k).Derived` in one pass; recomputed when `Revision` or `Params` change | 17 matrices at 1° = 8.8 MB and ≈ 40 ms. Memoisation saved nothing a user can feel and cost a cache struct, three key formats and an accessor on every read. |
| `Const.Cols` | registry **and** materialiser (anonymous functions in a cell table) | metadata only (`name, label, kind, unit, hidden`); formulas are plain lines in `pat_derive` | Mathematics reads better as sequential assignments than as `@(P,G,prm)` cells; the table keeps what it is good at (driving dropdowns, filters, theme, visibility). |
| Base facts | `pat_baseFacts` once per Revision | folded into `pat_derive` (peak, polarisation, boresight, planes, metrics) | One function, one commit, one validity test. |

### 5.3 Parameters in one function instead of loss as an offset (O1)

| Aspect | Previous draft | This plan | Why |
|---|---|---|---|
| Invariant I3 | "Loss is an offset": columns at `L = 0`, `+L` applied by plots, tables, export, coverage (`T − L`), efficiency `×10^{L/10}` | "Parameters enter in one function": `pat_derive` scales the fields by `10^{L/20}` (M7's `FieldScale`), everything downstream is value-agnostic | The offset invariant made a loss change free but put `lossAdd` flags in the column table, `+L` in six consumers and a shift in coverage. A 40 ms re-derivation removes all of it and keeps the pipeline linear. |
| `params` scope | `loss` (no recompute) and `params` (memo keys only) as two rows | one `params` row: `pat_derive` → redraw | — |
| New defect surfaced | — | D55 (Process resets cut and colour range) | Found while tracing what `on("params")` must *not* do. |

### 5.4 Geometry

| Aspect | Previous draft | This plan | Why |
|---|---|---|---|
| `ΔΩ` matrix | forbidden in `Geometry` ("rank-1 by construction"); formed locally in `cov_dist` and wherever an integral was needed | `Geometry.dOmega` stored once (nθ×nφ, 0.5 MB) | Three local reconstructions → one field; `geo_integrate` and `cov_curve` become one-liners. |

### 5.5 Other collapses

| Topic | Previous draft | This plan | Saving |
|---|---|---|---|
| `resetParams` | kept as a callback | defaults live in `applyChoices`; the button is `on("params")` | one function |
| `coneCenterLabel`, `coverageTableTag` | implied deleted | named in the deleted list | clarity |
| Update ladder | `source ⊃ freq ⊃ step ⊃ {loss, params, component} ⊃ …` | `source ⊃ freq ⊃ step ⊃ params ⊃ {component, span, cut, range, annot, camera}` | one rung fewer, one rule ("params re-derives") |
| Static checks | `interp1` not listed | `grep -c "interp1(" = 2` (the two reads) | — |

### 5.6 Size arithmetic

| Section | Previous budget | This plan | Δ | Source |
|---|---|---|---|---|
| A properties | 190 | 190 | 0 | `Derived` replaces `ColCache` + `Dist`; `Params` added |
| B constants | 40 | 40 | 0 | `Cols` without `fn` column |
| C orchestration | 300 | 280 | −20 | no `col()` accessor/memo keys; one `params` rung |
| D renderers | 400 | 400 | 0 | |
| E coverage UI | 260 | 220 | −40 | no dispatchers, no cache, one job kind, one datatip call |
| F export | 70 | 70 | 0 | |
| G layout | 320 | 320 | 0 | |
| H lifecycle | 50 | 50 | 0 | |
| I readers | 330 | 330 | 0 | |
| J numerical core | 250 | 230 | −20 | `cov_*` 25 lines instead of 60; `pat_derive` replaces `pat_baseFacts` + column `fn`s |
| **Total** | **2,210 sum; ≤ 2,500 target** | **≈ 2,130 sum; ≤ 2,500 target; 3,000 ceiling** | **−80** | |

---

## 6. The coverage trade-off, stated plainly

The previous draft evaluated coverage **exactly** at any threshold (from a sorted distribution) and inverted it exactly. This plan evaluates the definition exactly **at the thresholds the user asked for** (`cov_curve`), and reads everything else — a query at an arbitrary `T`, a threshold at `c %`, a table cell at another job's threshold — **linearly between those samples** with `interp1`, as M7 does.

What is given up: a query at `T = −12.3 dB` on a job computed with a 1 dB step returns the linear read between the −13 and −12 samples, not the exact step-function value. What is gained: one job kind, no distribution cache, no inverse bookkeeping, ≈ 35 fewer lines, and a numerical behaviour identical to M7's, which the owner has been using. The threshold step is visible in the job label and is the fidelity control; a finer step is a 30 ms recompute.

If an exact read is ever wanted, `cov_curve(C, dOmega, mask, q)` at the single query threshold is the same kernel and the same cost — it would require the job to keep `k` and the region, which is precisely the second job kind this pass removed. The plan lists that as a non-goal so the decision is explicit.

---

## 7. Design-axis comparison — previous draft vs this plan

| Axis | Previous draft | **This plan** |
|---|---|---|
| Pattern representation | grid-native `Pattern` + `Map`, uniform axes asserted | same |
| Where patterns live | `app.Pats(k)` registry; nodes store `k`; tree is job registry | same |
| Geometry | separable `wθ·Δφ`, `ΔΩ` never stored | separable, **`dOmega` stored once** |
| Columns | `Const.Cols` with `fn`; memoised `col(app,k,name)`; `ColCache` | **`pat_derive` eager; `Const.Cols` metadata only; `Derived` struct** |
| Loss | offset at point of use; `T − L` in coverage; efficiency `×10^{L/10}` | **inside `pat_derive` only** |
| Peak | spatial isolation, 6 dB | same |
| Resampling | decimate or `interp2` (power + phasor) | same |
| E/H planes | principal-axis rule | same |
| Metrics | total gain | same |
| **Coverage** | `cov_dist / cov_eval / cov_inverse`, `job_eval / job_inverse`, `Dist` cache, two job kinds | **`cov_curve` + `cov_at` / `thr_at` (`interp1`), no cache, one job kind** |
| Readers | `io_fields` + 9 specs; `xl_lookup`; `Meta.Notes` | same |
| Orchestration | `update(scope)` + `on`; `loss` and `params` rungs | same; **one `params` rung**; Process no longer resets cut/range (D55) |
| Range UI | descriptor-driven `applyRange` + `Range.Auto` | same |
| Layout | declarative, ≤ 320 lines | same |
| Performance tracking | `perf` method; M7-compatible record | same |
| Self-test | none | none |
| Size | ≤ 2,500 / 3,000 (sum 2,210) | **≤ 2,500 / 3,000 (sum ≈ 2,130)** |
| Defects catalogued | 70 (D01–D70) | **74 (D01–D74)**: D54, D55, D56, D74 new |
| Open decisions | 0 | 0 |

---

## 8. Defect ID mapping (previous register → this plan)

New rows were inserted in category order so the standalone plan stays contiguous.

| Previous | This plan | | Previous | This plan | | Previous | This plan |
|---|---|---|---|---|---|---|---|
| D01–D53 | **unchanged** | | D54 | D57 | | D63 | D66 |
| *new* | **D54** (write-only job fields, dead constant) | | D55 | D58 | | D64 | D67 |
| *new* | **D55** (Process resets cut & range, 5 renders) | | D56 | D59 | | D65 | D68 |
| *new* | **D56** (threshold-keyed cache + eager inverse) | | D57 | D60 | | D66 | D69 |
| | | | D58 | D61 | | D67 | D70 |
| | | | D59 | D62 | | D68 | D71 |
| | | | D60 | D63 | | D69 | D72 |
| | | | D61 | D64 | | D70 | D73 |
| | | | D62 | D65 | | *new* | **D74** (query datatip: helper + 3 fallbacks) |

Cross-references inside the plan (§1, §4.1, §7.2, §8, invariants) were re-pointed to the new numbers.

---

## 9. What was considered and not admitted (proportionality)

| Candidate | Reason not admitted |
|---|---|
| Keeping the sorted distribution for an exact inverse, with `interp1` only for the table | Two ways to read one curve; the owner asked for one. |
| Exact query for computed jobs, `interp1` for loaded ones | Re-introduces the two job kinds and the dispatchers this pass removed (§6). |
| A vectorised `cov_curve` via `histcounts`/`cumsum` (`O(N log N)`) | The literal `arrayfun` form reads as the definition and costs ≈ 30 ms; the vectorised form needs a bin-edge convention to be verified. |
| Memoising `pat_derive` by `(Revision, Params)` key | It *is* recomputed only when one of the two changes — the "key" is the commit itself; a separate cache would be a second copy of the same fact. |
| Keeping "loss as offset" for a zero-cost loss change | Costs `lossAdd` flags, `+L` in six consumers and a coverage shift to save 40 ms once per Process click. |
| Live parameter updates (no Process button) | Changes the widget set/behaviour; out of scope by rule. |
| Storing `ΔΩ` only as `wTheta` and `dPhi` | Three local reconstructions versus one 0.5 MB field. |
| Changing any widget, arrangement or default | Out of scope by rule. |

---

## 10. Residual risks specific to this pass

| Change | Residual risk | Disposition |
|---|---|---|
| `interp1` reads between threshold samples | A user comparing a query value to a fine-step recompute sees a small difference | Same as M7; the step is in the job label; a finer step is 30 ms. |
| Eager `pat_derive` on every Process click | ≈ 40 ms at 1°; ≈ 160 ms at 0.5° | Below the redraw time; measured by `perf` (§13.3 of the plan). |
| Foreign coverage entries derived at load-time `Params` | A job computed on a foreign pattern uses that pattern's `L`, not the Main tab's | Shown in the node tooltip and in every job label; re-derived on selection when the Main parameters differ. |
| No in-file tests | A kernel regression can only be caught by the hand checks and the real-file regression | Every kernel is one formula with the formula above it; plan §13.1 lists the checks; §13.2 runs every format against M7. |
| `assignin` retained in `perf` | Base-workspace variable per app class | Owner's inspection channel; one variable, overwritten per action. |

---

## 11. Summary

- The whole M7 file was re-read; every previous finding stands; four new defects were found — write-only job fields and a dead constant (D54), a parameter change that resets the user's cut and colour range and redraws five views (D55), cache infrastructure and an eager inverse around a 30 ms computation (D56), and a four-path datatip creation for one known coordinate (D74).
- Owner direction O2 is applied: **coverage is one five-line kernel producing a curve, and every read of a curve is `interp1`** (`cov_at`, `thr_at`) — M7's own idiom, no distribution cache, no inverse bookkeeping, one job kind.
- Under O1 the design collapsed further: **eager `pat_derive`** replaces the memoised column cache and the base-facts step; **parameters enter in one function** instead of being carried as an offset by every consumer; `Const.Cols` is metadata only; `Geometry.dOmega` is stored once.
- The standalone plan is anchored only to M7 line numbers; defect IDs are contiguous D01–D74 with the mapping in §8.
- Size: budget sum ≈ 2,130 lines, target ≤ 2,500, ceiling 3,000 — same widgets, features and formats.
