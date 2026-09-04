# APAT M8 — Review Findings & Comparison

**Subject reviewed:** `APAT_v3_M7_110_5.m` — 5,199 lines, one App Designer-style class, 183 functions (95 methods, 34 file-scope functions), 622 lines of hand-written layout in `createComponents` (3072–3693) plus 58 lines of layout helpers (3013–3070).
**Also reviewed:** the previous improvement-plan draft (`APAT_M8_improvement_plan_rev8.md`, 987 lines) and its companion (`APAT_M8_improvement_plan_rev8_Review_Findings.md`, 232 lines), together with the owner's three new directions: make the coverage design explicit and mathematically transparent, remove the self-test and its fixtures entirely, keep the performance tracker minimal.
**Companion document:** `APAT_M8_Improvement_Plan.md` — the standalone plan. It does **not** refer to this document or to any earlier draft; it is anchored only to M7 line numbers and its own appendices. This document is the *audit trail*: what was checked, what stands from the previous draft, what was changed and why, and how the defect IDs map.

---

## 1. Method

1. The whole M7 file was read again, section by section, nothing sampled: properties/constants 1–251, public methods 252–1931, private callbacks 1933–3011, layout 3013–3694, lifecycle/self-test 3695–3875, readers 3877–4563, numerical core 4565–5200.
2. Call graphs traced by hand — load → `refresh` → `applyStep` → `applyAngularSpan` → `updateViewResults` → renderers; `Single_Switch_EHplaneValueChanged` → `onCutChanged` → `drawSpatial3D`; component / cut / range / span callbacks; the coverage tab end to end including tree selection, checked-nodes, clear and reset. This pass additionally traced every **call site** of `setCoverageUI`, `finalizeCoverageJobs`, `syncCoveragePattern`, `coverageDisplayRange`, `cutData`, `plotCut`, `updateMetadata`, and every `.UserData` **assignment** (§4.2).
3. Hot-spot counts re-taken mechanically with `grep` (§3). Every number quoted in the previous draft was re-measured; one was corrected (`Layout.Row/Column` statements: 183, not 190).
4. Every finding of the previous register was re-verified against the cited lines before being kept (§4.1). Three new findings and one sharpened finding came out of the call-site tracing (§4.2).
5. The three owner directions were applied one by one (§2); for each, the plan text, the kernels, the register and the size budget were adjusted so that the plan stands on its own.
6. The previous plan's design was then tested for *further* collapse under the new directions. Removing the self-test removes not just a section but three helper kernels and a gate-row vocabulary; making coverage transparent removed `accumarray`/`discretize` and simplified the job model; the perf tracker became eight lines inside the orchestration layer (§5).

---

## 2. Owner directions applied in this pass

| # | Owner direction | How it is applied in the plan |
|---|---|---|
| O1 | Review the whole code deeply; improve architecture/algorithm/dataflow so the logic is concise, transparent, fast and robust; target < ~3,000 lines, conciseness of *logic* not of formatting. | Architecture retained from the previous draft where it was already sound (§7); five further collapses found (§5); budget sum now 2,210, target ≤ 2,500, ceiling 3,000. Every saving is a removed algorithm, path, copy or section — no line-joining. |
| O2 | **Coverage** in the previous plan "seems complex / not explicit / not mathematically transparent". | Rewritten as *the definition, verbatim* (plan §6.9, A.1): `Coverage(T) = 100·Ω_R(G>T)/Ω_R` is stated once; `cov_dist` is bookkeeping (region samples, their ΔΩ, sorted), `cov_eval` is the literal tail sum per threshold, `cov_inverse` is one `find` on the reverse cumulative weight. `accumarray`, `discretize`, `unique`-binning and the `cov_eval_reference` twin are gone; the cone mask is the spherical law of cosines in one line. §6 below explains the trade-off. |
| O3 | **Remove the self-test and everything related** (fixtures, gate rows, `uiInventory`, reference kernels). | Section I of the file layout, the 30-row release gate, the `fx_*` generators, `cov_eval_reference`, the static `selfTest()` and every "gate row N" cross-reference are removed. Verification is now plan §13: hand checks during development, real-file regression, timing comparison. The static `grep` checks are kept (they are a shell one-liner, not code in the file). |
| O4 | **Keep the performance tracker**, minimal; the current one is already concise. | Kept as one eight-line method `perf(app, stage)` (plan §7.5) with the **same record shape and the same base-workspace variable name pattern** as M7 (`Perf_<class>`), so M7 and M8 timings compare directly; additionally exposed as `app.Perf`. Begin/end are automatic inside `on(scope)`; `update` marks stages. `assignin` — flagged as a hygiene defect (F48) in the previous draft — is **retired as a defect** because it is the owner's chosen inspection channel; it is now exactly one permitted site in the static checks. |
| O5 | Findings/comparison and the standalone plan must be separate; the plan must not refer to previous plan revisions. | Two files. The plan has no "previous draft", "this revision", "rev8", "new in this review" or "retired" language; defect IDs are renumbered contiguously (D01–D70) so the plan has no gaps that would hint at a history. The mapping is in §8 of this document. |

---

## 3. M7 anatomy in numbers (re-measured this pass)

| Fact | Count / lines | Consequence |
|---|---|---|
| Functions | 183 (95 methods, 34 file-scope, plus nested/self-test) | — |
| Table copies of one sphere per refresh | 6 (`rawTbl, stdTbl, patTbl, viewBaseTbl, viewTbl, uanTbl`, 189–194) + 2 per coverage node (1684–1686) | Every stage re-derives grid structure from a long table. |
| `physicalTheta(` call sites | 13 | Display convention stored *in the data* (453) and undone downstream — forgotten in 3 numerical paths (D02). |
| `gridStep(` / `solidWeights(` / `resolvePeak(` | 17 / 6 / 10 | Step, ΔΩ and the 65k-sample `prctile` are recomputed per consumer. |
| `findall` + `findobj` / `cla(` / `drawnow` | 11 / 6 / 8 | Renderers locate their own objects by tag; every change rebuilds. |
| `UserData` tokens / **assignment sites on widgets** | 43 / 14 (342, 455, 602, 1446, 1489, 1542, 1814, 1817, 2071, 2117, 2518, 2802, 2840 + table `Properties.UserData` ×5) | Flags in `Single_DropDown_step`, `CutFieldBasisDropDown`, `Single_DropDown_output`, `Cov_gridPanel_Parm`, both status labels, plus per-marker annotation records. |
| `NodeData` tokens | 48 | Coverage state spread over tree nodes with ad-hoc fields; four are dead (D49). |
| `setCoverageUI(` call sites | 7 (1691, 1724, 1794, 1795, 1991, 2233, 2251, 2407 — 1794/1795 consecutive) | Visibility code re-enters numerics (D53, new). |
| `finalizeCoverageJobs(` call sites | 5 | Each one rebuilds the table, the legend and the visibility. |
| `syncCoveragePattern(` call sites | 4 (1509, 1689, 2484, 2749) | Each runs `coverageDisplayRange` → `resolvePeak` → `prctile`. |
| Constants threaded through signatures | `PeakPercentile` at 13 sites | Six signatures carry two constants. |
| Columns computed eagerly per refresh | 17 (9 hidden by default) | EIRP/PFD/E_RMS/phases computed for 65k samples even when never shown. |
| Full-pattern tabs rendered per change | 5 (1 visible), **7 on load when the overlay box is checked** | Dominant cost of component change and load (D54, D69). |
| Duplicate algorithms | `cutGeometry` ≡ `calcCutGeometry`; `gainDisplayRange` ≡ `coverageDisplayRange`; 4 inline circular splits (9 `sqrt(2)`); 5 near-identical six-column reader cases; two identical table constructions 4318–4326 | A policy change must be made in 2–5 places. |
| **Layout** | **622 lines in `createComponents`, 118 widget constructors, 183 `Layout.Row/Column` statements, 16 grids** | Hand-written, therefore compressible without touching a widget. |
| Excel summary reader | 164 lines (4400–4563) | One consumer (`frequencyMHz → hasFrequency`, 4337), never read for Excel (D30). |
| Empty `catch` blocks | 5 (1108, 1183, 1493, 2641, 2666) | Errors swallowed (D70, new). |
| Blank / comment-only lines | 467 / 334 | Not a target; the budgets count statements. |
| Toolbox dependency | `prctile` ×1 (5113) — Statistics and Machine Learning Toolbox | M7 does not run on base MATLAB. |
| Self-test | `runSelfTest` 3715–3858 (144 lines) + 12 `pass*` fields | Removed by owner direction O3. |
| Perf tracker | `startPerf` 1922–1930 (9 lines, nested closures) + `perfTracker` property (237) + 26 call-site tokens | Kept, reduced to one method (O4). |

---

## 4. Findings

### 4.1 Previous register — re-verified

All 71 rows of the previous register (F01–F71, with F13 and F15 already retired as conventions) were checked against the cited lines. All stand. Notes on the ones that needed a second look this pass:

| Previous ID | Note |
|---|---|
| F10 | Re-confirmed the mechanism: `regionGain > thresholds.'` (4593) is a 65,160 × 501 logical (32.6 MB); `regionWeight.' * indicator` (4597) is `mtimes` with a logical operand, promoted to double → 261 MB. The new plan's `cov_eval` loop does the same arithmetic with `O(N)` memory (plan B.9). |
| F34 | **Sharpened.** The 65k percentile does not only run on tree *selection* (2749); it runs on every *checkbox* toggle through `Cov_TreeCheckedNodesChanged` (2702) → `finalizeCoverageJobs` (1724) → `setCoverageUI` (1548) → `Cov_ButtonGroup_CovTypeSelectionChanged` (2484, when Conical) → `syncCoveragePattern` → `coverageDisplayRange` (1663) → `resolvePeak` → `prctile`. Recorded as D37 with the cascade. |
| F41/F60 | Re-confirmed the load sequence: 351 `updateViewResults(…, renderFull=false, updateCut=false)` → 355 `Single_Switch_EHplaneValueChanged` → `onCutChanged` → `plotCut` and, with the overlay checked, `drawSpatial3D` → `drawPattern3D` ×2 → 357 `renderAllFullPatterns` ×5. Seven surface renders on load. |
| F48 | **Retired as a defect** (owner direction O4): `assignin('base', …)` is the owner's inspection channel for timings. Kept as the single permitted `assignin` site inside `perf`. |
| F51 | **Retired** (owner direction O3): with no self-test there is nothing to make static. |
| F58 | Re-confirmed: `cutCols` returns `VariableNames(3)` for gain-only (1329); `cutData` titles with `app.comp()` (1386). |
| F62 | Re-confirmed by `grep`: `userEdited`, `lastPreset`, `evaluationBounds`, `displayBounds` each have one write site (1589, 1598, 1615) and zero reads. |
| F67 | Re-confirmed the caller set of `covThresholds`: 1758 (`covRebuildTable`, run on every check/uncheck and selection) and 2298 (compute). The spinner write at 1523 can therefore fire from a tree click. |
| F69 | Re-confirmed the schema mismatch: `emptyGridCache` (5198–5199) seeds a flat struct; `gridComp` (501–503) tests `cache.topology.valid`. |

### 4.2 New findings (this pass)

| New ID | M7 lines | Finding |
|---|---|---|
| **D52** | 332–335 | **Duplicate dropdown items when the native step is already 1°.** `refresh` sets `Items = {sprintf('STEP: %g°', app.step), 'STEP: 1°'}`; for a 1° source both strings are `'STEP: 1°'`. The control is hidden in that case (`Visible = nonCanonical`, 343), so nothing breaks visibly, but `Value` is then ambiguous and `strcmp(Items, Value)` at 2117/2802-style lookups would return two hits. Closed in `applyChoices` (one item when native = 1°). |
| **D53** | 1691, 1724, 1794–1795, 1991, 2233, 2251, 2407 | **`setCoverageUI` re-entrancy.** Seven call sites, two of them consecutive in `covLoadResults` (1794 via `finalizeCoverageJobs`, then 1795 directly). In `"pattern"` mode it calls `Cov_ButtonGroup_CovTypeSelectionChanged` (1548), which calls `syncCoveragePattern` (2484) — a *visibility* routine triggers percentile and orientation work. Closed by one `applyVisibility` at the end of `update` that never calls numerics. |
| **D70** | 1108, 1183, 1493, 2641, 2666 | **Five empty `catch` blocks.** Datatip-template fallback (1101–1110, nested twice), `camup` (1181–1184), HPBW bound markers (1481–1494), query datatip template (2639–2642) and the `InterpolationFactor` fallback (2656–2668). Every failure in those regions is silent, including programming errors. Closed: no empty `catch`; the one legitimate fallback (datatip template) is a single `try` that notes the failure in `app.Status`. |
| D37 (sharpened F34) | see §4.1 | Checkbox → percentile cascade. |

### 4.3 Checked and left unchanged (from the previous pass, re-confirmed)

- Excel **matrix** readers (`readExcelMatrix`, `readExcelMatrixSheet`, 4227–4398): logic correct; only the duplicated `raw`/`block` construction (4318–4326) collapses to one.
- `calcHPBW` (4860–4880): correct wrap-aware crossing; kept verbatim as `met_hpbw`.
- `calcOrientation` cone rule (4845–4850): correct once fed physical unit vectors and total gain; kept as `met_orientation`, now written with the same spherical-law-of-cosines expression as the coverage cone mask so there is one cone test in the file.
- `planeSettings` (634–642): kept verbatim as `met_planes`.
- `fmtNumber` regexes (704–711): correct except `-0` (D64).
- `solidWeights` seam zeroing (5173–5174): consistent for M7's tables; unnecessary with a seam-free `Pattern`.
- `.cut` negative-θ fold and 10° revolution (4130–4137): kept.
- `writeUANFile` header text (1903–1906): kept; only `maximum_gain` changes (D29).
- `coverageCCDF` (4565–4598): the *definition* it implements is correct and is exactly what the new `cov_eval` computes; only its memory footprint and its cache key were wrong (D10). The plan's §13.1 uses M7's output as the numerical reference for `cov_eval` at `L = 0`.

---

## 5. Changes to the plan in this pass — and why

### 5.1 Coverage (owner direction O2)

| Aspect | Previous draft | This plan | Why |
|---|---|---|---|
| Statement of the problem | Definition given in a kernel comment; implementation via `unique` → `accumarray` → `flipud(cumsum(flipud(…)))` → `discretize(T, [−Inf; g; Inf])` with a bin-edge argument (B.2) | Definition stated in §6.9 as four display equations (`ΔΩ`, `Ω_R`, `Ω_R(G>T)`, `Coverage`), then three functions each described as one formula | The previous kernel was correct but required the reader to verify a bin-edge convention, an `accumarray` grouping and a double `flipud`. The owner found it opaque. |
| `cov_dist` | distinct levels + aggregated weights + `S` via double flip | region samples **sorted**, their weights, `Ω_R`, `S = cumsum(w,'reverse')` (one built-in, one comment: `S_k = Ω_R(G ≥ g_k)`) | Aggregation of equal levels is unnecessary for correctness; removing it removes `unique`/`accumarray`. `cumsum(…,'reverse')` is the direct expression of `Σ_{m≥k}`. |
| `cov_eval` | `k = discretize(T, [−Inf; d.g; Inf]); cov = 100·S(k)/Ω` | `for each T: cov = 100·Σ_{g_k > T} w_k / Ω_R` — the definition | Costs 501 × 65k ≈ 30 ms (B.9), below the plot time; `O(N)` memory; nothing to verify. |
| `cov_inverse` | `nnz(d.S ≥ c·Ω/100)` | `find(100·S/Ω ≥ c, 1, 'last')` on the same sorted list, with the semantics written out (B.2: "highest level whose coverage still reaches c %") | Same result, stated as a search instead of a count. |
| Cone mask | rank-1 products of stored `sinT·cosP` etc. | spherical law of cosines `cos γ = cos θ cos θc + sin θ sin θc cos(φ − φc)` by implicit expansion; `Geometry` no longer stores `sinT/cosT/cosP/sinP` | Recognisable formula; four fields fewer in `Geometry`; the same expression serves `met_orientation`. |
| `cov_eval_reference` | kept for the self-test | removed | O3; M7's own `coverageCCDF` is the hand-check reference at `L = 0` (plan §13.1). |
| Table for loaded results files | "nearest-lower sample of their own curve" | `job_eval`: `interp1(…, 'previous')` — the step-function reading — for loaded curves; exact `cov_eval` for computed jobs; blanks outside a loaded curve's range | Makes the rule for loaded curves explicit and puts the only `interp1` in one named place. |
| Job registry | `app.covJobs` cell mirrored from the tree with a validity filter (M7 1743–1753) | the tree **is** the registry: `jobs = [Results.Children.Children]`; a job node holds `{id, k | Curve, col, region, T, L, Line, Query}` | One property and one filter fewer; no mirror to desynchronise. |
| Query artefacts | tagged lines found with `findall` | handles stored in `job.Query` | I11; Clear/Reset/visibility become `set`/`delete` on known handles. |

### 5.2 Self-test removal (owner direction O3)

| Removed | Where it was | What replaces it |
|---|---|---|
| Section I (`static selfTest`, 30 gate rows, `fx_*` fixture generators) | file layout, §13 "Release gate", budget row I (150 lines) | plan §13.1 hand checks (Command Window, nothing kept), §13.2 real-file regression, §13.3 timing comparison |
| `cov_eval_reference` | A.1 | M7's `coverageCCDF` output at `L = 0` as the reference (§13.1) |
| `uiInventory` gate row | §9, §13-28, I15 | a throw-away inventory script run once in work-order step 7 and discarded |
| "each defect has a self-test row or static check" | §10 preamble, §17 | "closed structurally"; static `grep` checks retained (§11) because they are a shell command, not file content |
| Gate-row cross-references in §6, §10, §16 | throughout | removed |
| F51 (self-test needs a live app) | register | retired |

Budget effect: −150 lines (section I) and −10 lines (numerical core: no reference kernel). New sum 2,210; target moved from ≤ 2,600 to ≤ 2,500.

### 5.3 Performance tracker (owner direction O4)

| Aspect | M7 | Previous draft | This plan |
|---|---|---|---|
| Mechanism | `startPerf` returns a `save` closure; two nested functions; `perfTracker` handle property swapped between a no-op and `track`; 26 call-site tokens | "Profiling into `app.Perf` only when `getenv("APAT_PROFILE")` is set; no `assignin`" | one method `perf(app, stage)`, eight lines; `on(scope)` brackets every action with `begin`/`end`; `update` marks stages; record shape **identical to M7's** (`AppVersion, Operation, Stages, TotalSeconds`); written to `app.Perf` **and** to `Perf_<class>` in the base workspace |
| Why | — | hygiene | the owner's stated purpose is to *compare* M8 against M7; same shape + same channel makes that a side-by-side table (plan §13.3). Stage names are chosen to line up with M7's. |
| Properties | `perfTracker` (function handle) | `Perf` | `Perf` (public, read-only) + `PerfRun` (private, transient) |

### 5.4 Other collapses found while re-testing the design

| Topic | Previous draft | This plan | Saving |
|---|---|---|---|
| Reader disclosure | `Meta` carried `ThetaConvention`, `ThetaDecidedBy`, `AxisOrder`, `AxisDecidedBy`, `SynthesizedRevolution`, `PhiClosedInSource`, `Notes` | `Meta = {Format, Unit, UnitLabel, IsGainOnly, ColNames, Notes}`; every reader decision is one sentence in `Notes`, shown in Metadata | six fields, their factory defaults and their Metadata rows → one string array (≈ 20 lines) |
| Visibility | `applyVisibility` existed but `update` rows still listed `applyVisibility` per action | `applyVisibility` runs **once** at the end of every `update`; visibility never calls numerics | closes new D53; removes `setControls`, `updateInputVisibility`, the `refresh` visibility block (360–372) and the `onComponentChanged` block (2828–2832) from the deleted-name list explicitly |
| Generic-format reinterpretation | `onTextFormatChanged` / `onCovTextFormatChanged` still implied | both are `update("source")` on the cached `Source.Raw` | two callbacks |
| Status | one timer (already) | `setStatus` written out in six lines (A.14); `restoreStatus`, `disposeStatusTimer`, `stopStatusTimer` named as deleted | clarity |
| Geometry | stored `sinT, cosT, cosP, sinP` | not stored; unit vectors formed on demand | four fields |
| Deleted-name list | 66 names | 91 names (+ `prepareTextFormat`, `onTextFormatChanged`, `onCovTextFormatChanged`, `covJobNodes`, `updateInputVisibility`, `setCoverageUI`, `setControls`, `coverageArtifacts`, `restoreStatus`, `disposeStatusTimer`, `stopStatusTimer`, `runSelfTest`, `pat_axis` added to the kept list) | follows from the items above |

### 5.5 Size arithmetic

| Section | Previous budget | This plan | Δ | Source |
|---|---|---|---|---|
| A + B | 230 | 230 | 0 | `Perf/PerfRun` replace `perfTracker`; `Meta` smaller |
| C orchestration | 300 | 300 | 0 | `perf` added (8), `applyVisibility` centralised (−) |
| D renderers | 400 | 400 | 0 | |
| E coverage UI | 280 | 260 | −20 | tree as registry; `job_eval/job_inverse`; no `covJobs`, no tag search |
| F export | 70 | 70 | 0 | |
| G layout | 320 | 320 | 0 | |
| H lifecycle | 50 | 50 | 0 | |
| I self-test | 150 | **0** | −150 | O3 |
| readers | 330 | 330 | 0 | |
| numerical core | 260 | 250 | −10 | no `cov_eval_reference`; simpler `cov_*`; `Geometry` fields |
| **Total** | **2,390 sum; ≤ 2,600 target** | **2,210 sum; ≤ 2,500 target; 3,000 ceiling** | **−180** | |

---

## 6. The coverage trade-off, stated plainly

The previous draft's `discretize`-based evaluation is `O(T log N)`; the new literal loop is `O(T·N)`. On the largest realistic grid (1° × 1°, 65,160 samples) with 501 thresholds the loop costs ≈ 30 ms — below the time MATLAB needs to draw the curve — and it allocates one logical vector per threshold instead of the 261 MB matrix of M7. For a 0.5° × 0.5° grid (260k samples) it is ≈ 120 ms, still interactive. In exchange, `cov_eval` reads as the definition and requires no bin-edge convention to be verified. Should a future grid make the loop noticeable, `sum(d.w(d.g > T))` can be replaced by `d.S(find(d.g > T, 1))` on the already-sorted list without changing any other line — that alternative is noted in the plan's A.1 reading guide by construction (`S` is already computed for the inverse).

---

## 7. Design-axis comparison — previous draft vs this plan

| Axis | Previous draft | **This plan** |
|---|---|---|
| Pattern representation | grid-native `Pattern` + `Map`, uniform axes asserted | same |
| Where patterns live | `app.Pats(k)` registry; nodes store `k` | same; **the tree is also the job registry** |
| Geometry | separable `wθ·Δφ` + stored unit-vector factors | separable `wθ·Δφ` only; unit vectors on demand |
| Columns | `Cols` struct array with `fn` | same |
| Loss | offset at point of use; efficiency ×`10^{L/10}` | same |
| Peak | spatial isolation, 6 dB | same |
| Resampling | decimate or `interp2` | same |
| E/H planes | principal-axis rule (M7) | same |
| Signed AR at linear samples | −100 dB (M7), mask shared with PLF | same |
| Metrics | total gain | same |
| **Coverage** | sorted + `accumarray` + `discretize`; reference twin | **definition verbatim: `cov_dist / cov_eval / cov_inverse`, spherical-law cone mask, `job_eval/job_inverse`** |
| Readers | `io_fields` + 9 specs; Excel summary via `xl_lookup` | same; **`Meta` disclosure collapsed to `Notes`** |
| Orchestration | `update(scope)` + `on` + build-then-commit | same; **`applyVisibility` once per update; `perf` inside `on`** |
| Range UI | descriptor-driven `applyRange` + `Range.Auto` | same |
| Layout | declarative, ≤ 320 lines, inventory gate row | same; inventory check is a throw-away script in the work order |
| Performance tracking | env-gated `app.Perf`, no `assignin` | **`perf` method; M7-compatible record; `app.Perf` + base variable** |
| Self-test | 30 rows + fixtures + reference kernels | **none** |
| Verification | release gate | **hand checks + real-file regression + timing comparison** |
| Size | ≤ 2,600 / 3,000 | **≤ 2,500 / 3,000** (budget sum 2,210) |
| Defects catalogued | 71 (F01–F71; F13, F15 retired) | **70 (D01–D70)**: F48, F51 retired; D52, D53, D70 new |
| Open decisions | 0 | 0 |

---

## 8. Defect ID mapping (previous register → this plan)

Renumbered contiguously so the standalone plan has no gaps. Same category order as before.

| Previous | This plan | | Previous | This plan | | Previous | This plan | | Previous | This plan |
|---|---|---|---|---|---|---|---|---|---|---|
| F01 | D01 | | F16 | D19 | | F28 | D31 | | F41 | D54 |
| F02 | D02 | | F17 | D20 | | F29 | D32 | | F42 | D55 |
| F03 | D03 | | F18 | D21 | | F30 | D33 | | F43 | D56 |
| F04 | D04 | | F19 | D22 | | F31 | D34 | | F44 | D57 |
| F05 | D05 | | F20 | D23 | | F32 | D35 | | F45 | D58 |
| F06 | D06 | | F21 | D24 | | F33 | D36 | | F46 | D59 |
| F07 | D07 | | F22 | D25 | | F34 | D37 (sharpened) | | F47 | D60 |
| F08 | D08 | | F23 | D26 | | F35 | D38 | | F49 | D61 |
| F09 | D09 | | F24 | D27 | | F36 | D39 | | F50 | D62 |
| F10 | D10 | | F25 | D28 | | F37 | D40 | | F52 | D63 |
| F11 | D11 | | F27 | D29 | | F38 | D41 | | F53 | D64 |
| F12 | D12 | | F66 | D30 | | F39 | D42 | | F54 | D65 |
| F14 | D13 | | | | | F40 | D43 | | F55 | D66 |
| F26 | D14 | | | | | F61 | D44 | | F56 | D67 |
| F58 | D15 | | | | | F62 | D45 | | F57 | D68 |
| F59 | D16 | | | | | F63 | D46 | | F60 | D69 |
| F64 | D17 | | | | | F65 | D47 | | *new* | D70 |
| F70 | D18 | | | | | F67 | D48 | | | |
| | | | | | | F68 | D49 | | | |
| | | | | | | F69 | D50 | | | |
| | | | | | | F71 | D51 | | | |
| | | | | | | *new* | D52 | | | |
| | | | | | | *new* | D53 | | | |

**Retired:** F13, F15 (decided conventions — plan §15-6, §15-2); F48 (`assignin` — owner's inspection channel, kept in `perf`); F51 (self-test — removed entirely).

---

## 9. What was considered and not admitted (proportionality)

| Candidate | Reason not admitted |
|---|---|
| A vectorised `cov_eval` via `histcounts`/`discretize` as the primary path | Owner asked for transparency; the literal loop is fast enough (§6) and reads as the definition. The sorted `S` remains available if a one-line swap is ever wanted. |
| Keeping a *reduced* self-test (e.g. 5 rows) | Owner asked for complete removal; partial retention would keep the fixture vocabulary and a gate section. |
| Replacing `assignin` in the perf tracker with an env-gated property only | Owner compares timings through the base-workspace variable today; keeping the channel costs one line and makes the M7/M8 comparison direct. |
| Interpolating computed coverage curves for the table union (M7 `interp1`) | Exact evaluation from the distribution is available at the same cost; interpolation would fabricate values between step levels. |
| Storing `ΔΩ(i,j)` as a matrix in `Geometry` | Rank-1 by construction; formed locally where needed (`cov_dist`, `geo_integrate` never needs it). |
| A "reader DSL" | Five column orders + three block-structured formats; a spec row and small readers suffice. |
| Keeping Excel summary metadata "for future use" | No consumer today; `xl_lookup` reads any labelled cell in one line if ever needed. |
| Changing any widget, arrangement or default | Out of scope by rule. |

---

## 10. Residual risks specific to this pass

| Change | Residual risk | Disposition |
|---|---|---|
| No in-file tests | A kernel regression can only be caught by the hand checks and the real-file regression | Every kernel is one formula with the formula above it; §13.1 lists the checks; §13.2 runs every format against M7 with an explicit list of allowed deltas. |
| `cov_eval` loop | Cost grows with `T·N`; a 0.25° grid with 2,000 thresholds would take ≈ 1 s | Not a realistic APAT input today; the one-line swap to `d.S(find(d.g > T, 1))` is available (§6). |
| `assignin` retained | Base-workspace pollution with one variable per app class | Owner's choice; one variable, overwritten per action. |
| Loaded-curve step semantics (`'previous'`) | A user comparing a loaded CSV to its recomputed original sees identical values only at the CSV's own thresholds | The table blanks off-grid cells for loaded curves; the plan states the rule in §6.9. |

---

## 11. Summary

- The whole M7 file was re-read; every previous finding stands; three new hygiene/dataflow defects were found (D52 duplicate step items, D53 visibility→numerics re-entrancy, D70 empty `catch` blocks) and one was sharpened (D37: the percentile runs on checkbox toggles, not only selection).
- The three owner directions are applied: **coverage is now the written definition** (`cov_dist / cov_eval / cov_inverse`, one formula each, spherical-law cone mask, `O(N)` memory); **the self-test and all fixtures are gone**, replaced by hand checks, real-file regression and a timing comparison; **the performance tracker is kept** as one eight-line method producing M7's record shape in M7's channel plus `app.Perf`.
- Further collapses: `Meta` disclosure → `Notes`; the tree as job registry; `applyVisibility` once per update; `Geometry` without stored unit-vector factors; both text-format callbacks → `update("source")`.
- The standalone plan is anchored only to M7 line numbers; defect IDs are renumbered D01–D70 with the mapping in §8.
- Size: budget sum 2,210 lines, target ≤ 2,500, ceiling 3,000 — same widgets, features and formats.
