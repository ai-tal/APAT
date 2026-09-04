# APAT M8 — Review Findings & Comparison

**Subject reviewed:** `APAT_v3_M7_110_5.m` — 5,199 lines, one App Designer-style class, 183 functions (95 methods, 34 file-scope functions, 622 lines of hand-written layout in `createComponents` at 3072–3694 plus 58 lines of layout helpers at 3013–3070).
**Also reviewed:** the previous improvement-plan draft (`APAT_M8_improvement_plan_rev7.md`) and its review-findings companion, plus the owner's answers to the eight open points of that draft and the request to push conciseness further (target < 3,000 lines, or thereabouts).
**Companion document:** `APAT_M8_Improvement_Plan.md` — the standalone plan. It does **not** refer to this document or to any earlier draft. This document is the *audit trail*: what was checked, what stands from the previous draft, what was wrong, missing or over-specified, what was added, what was cut, and how the size target moved.

---

## 1. Method

1. The whole M7 file was read again, section by section: properties/constants 1–251, public methods 252–1931, private callbacks 1933–3011, layout 3013–3694, lifecycle/self-test 3695–3875, readers 3877–4563, numerical core 4565–5200. Nothing was sampled.
2. Call graphs traced by hand: load → `refresh` → `applyStep` → `applyAngularSpan` → `updateViewResults` → renderers; `Single_Switch_EHplaneValueChanged` → `onCutChanged` → `drawSpatial3D`; component / cut / range / span callbacks; the coverage tab end to end including tree selection, checked-nodes and reset.
3. Hot-spot counts taken mechanically with `grep` so that "X is done in N places" is a fact. Where the previous draft quoted a count, it was re-measured (§3).
4. Every finding of the previous draft was re-verified against the code before being kept. Every new finding below cites lines and was confirmed by reading both the writer and every reader of the state involved (a `grep` for read sites is quoted where the claim is "never read").
5. The eight owner decisions were applied one by one; for each, the plan text, the constants, the kernels, the defect register and the self-test rows were adjusted so that no open point remains (§2, §6).
6. The previous draft's design was then tested for *further* collapse under the new decisions: two of them (uniform-only grids, principal-axis planes) remove whole code paths, and one additional structural lever (a shared pattern registry) was found (§5).

---

## 2. Owner directions applied in this revision

| # | Owner direction | How it is applied in the plan |
|---|---|---|
| O1 | Review the whole code deeply; improve architecture/algorithm/dataflow so the logic is concise, transparent, fast and robust. | Five collapsing observations (§5) now drive the plan; six new defects found (§4.2); two previous "defects" reclassified as decided conventions (§4.4). |
| O2 | Aim for < 3,000 lines — conciseness of *logic*, not of formatting. | Section budgets now sum to 2,390; target ≤ 2,600; hard ceiling 3,000 enforced as a gate. Every saving in §5.1 is a removed algorithm, path or copy — no line-joining. |
| O3 | Findings/comparison and the standalone plan are separate documents; the plan must not refer to earlier revisions. | Two files. The plan is anchored only to M7 line numbers and its own appendices. |
| O4 | Close the eight open points as decided (see §6). | All eight are now a "Decided conventions" table in the plan (§16 there) with a constant or a one-line rule each; the plan has no "open decisions" section. |
| O5 | Keep App Designer style for UI handles. | The "handles in a struct" reserve lever is withdrawn entirely; declared properties are an invariant (I11) and a gate row (28). |

---

## 3. M7 anatomy in numbers (re-measured)

| Fact | Count / lines | Consequence |
|---|---|---|
| Table copies of one sphere per refresh | 6 (`rawTbl, stdTbl, patTbl, viewBaseTbl, viewTbl, uanTbl`, 189–194) + 2 per coverage node (1684–1686) | Every stage re-derives grid structure from a long table. |
| `physicalTheta(...)` call sites | 13 | Display convention stored *in the data* (453) and undone downstream — forgotten in 3 numerical paths (F02). |
| `gridStep(...)` / `solidWeights(...)` / `resolvePeak(...)` | 17 / 6 / 10 | Step, ΔΩ and the 65k-sample `prctile` are recomputed per consumer. |
| `findall` / `findobj` / `cla(` / `legend(` / `drawnow` | 9 / 2 / 6 / 5 / 8 | Renderers locate their own objects by tag; every change rebuilds and re-legends. |
| Widget `.UserData` used as application state | 14 sites (43 `UserData` tokens in total) | Flags in `Single_DropDown_step`, `CutFieldBasisDropDown`, `Single_DropDown_output`, `Cov_gridPanel_Parm`, both status labels. |
| `NodeData` read/write sites | 48 | Coverage state is spread over tree nodes with ad-hoc fields; four of them are dead (F68). |
| Constants threaded through signatures | `PeakPercentile` at 13 sites, `PeakMaxExcessDB` alongside | Six function signatures carry two constants. |
| Columns computed eagerly per refresh | 17 (9 hidden by default) | EIRP/PFD/E_RMS/phases computed for 65k samples even when never shown. |
| Full-pattern tabs rendered per change | 5 (1 visible), **7 on load when the overlay box is checked** | Dominant cost of component change and load (F41, F60). |
| Duplicate algorithms | `cutGeometry` ≡ `calcCutGeometry`; `gainDisplayRange` ≡ `coverageDisplayRange`; 4 inline circular splits (9 `sqrt(2)`, 14 `1i`); 5 near-identical six-column reader cases; two identical table constructions in the Excel reader (4318–4324) | A policy change must be made in 2–5 places. |
| **Layout** | **622 lines in `createComponents`, 118 widget constructors, 190 `Layout.Row/Column` statements (95 + 95), 16 grids; helpers `createRightLabel`/`createPatternTab` already exist (3015–3070)** | Hand-written, therefore compressible without touching a widget. |
| **Excel summary reader** | **164 lines (4400–4563): `readExcelSummary` + `summaryValue`, `summaryRowValue`, `summaryNumeric`, `findSummaryLabel`, `normalizeSummaryLabel`, `toDouble`** | Produces ≈ 25 metadata fields; `grep` shows exactly one consumer (`frequencyMHz → hasFrequency`, 4337) and that flag is never read for Excel (F66). |
| `sqrt(2)` / `1i` literals | 9 / 14 | Circular convention is not in one place. |
| Blank / comment-only lines | 801 | Not a target in itself; the budgets count real statements. |
| Dead state | `coverageRangeState`: 4 of 9 fields write-only; `markCoverageThresholdUserEdit` wired 3× with no reader; `componentBounds` 2 writes / 0 reads; `app.step` 1 write / 1 read on the next line; `orientationMode` never changes; `emptyGridCache` schema never matches its consumer | Comments describe behaviour that does not exist. |
| Toolbox dependency | `prctile` ×1 (5113) — Statistics and Machine Learning Toolbox | M7 does not run on base MATLAB. |

---

## 4. Findings

IDs **F01–F65** are the previous register's labels; **F66–F71** are new in this review. Status: **V** = re-verified defect from the previous draft, **N** = new, **S** = sharpened, **D** = reclassified as a decided convention (no longer a defect).

### 4.1 Previous findings — re-verified

All rows of the previous register were checked against the cited lines. All stand except the two reclassified in §4.4. Notes on the ones that needed a second look:

| ID | St. | Note |
|---|---|---|
| F01 | V | `prctile` at 5113 is a Statistics Toolbox function; M7 therefore carries a toolbox dependency the previous draft called out only as a policy problem. The plan lists it in §11's static checks. |
| F10 | S | The previous draft quoted "260 MB transient". Re-derived: `regionGain > thresholds.'` is a 65,160 × 501 *logical* (32.6 MB), but `regionWeight.' * indicator` (4597) is `mtimes` with a logical operand, which MATLAB promotes to double → 261 MB. The number stands; the mechanism is now stated. |
| F12 | V | Re-traced: `updateViewResults` (2810–2811) passes the **component** peak to `computeMetrics` → `calcMetrics`, which uses `peakInfo.value` as `peakGain` (4615–4617) against the **total-gain** integral (4635–4636). With "Axial Ratio" selected, directivity is `AR_peak_dB − 10·log10(∫G)` and F/B is `AR_peak − G_back`. |
| F44 | S | Confirmed and sharpened: the polar-3D *surface* normalises the radius by its own maximum (1252) while the *overlay* does not (1317), so the overlay radius disagrees with the surface by the factor `max(radius)` — visible whenever the colour range top is above the peak. |
| F58 | V | `cutCols` returns `VariableNames(3)` for gain-only (1329); `cutData` titles with `app.comp()` (1386). No code path passes the component into the cut. |
| F59 | V | `LinearPowerForGain` is used only inside the `else` (scattered) branch (5019); the regular branch (5008) interpolates raw dB. The M7 self-test evaluates native samples only (3753–3755), where any interpolation is exact, so it cannot detect this. |
| F61 | V | `activateSource` (2040) and `selectBlock` write `rawTbl/ffdBlocks/freqs/srcUD/stdTbl` before `refresh` (2053); nothing rolls back on cancel/error. |
| F62 | V | `grep` for `userEdited\|lastPreset\|evaluationBounds\|displayBounds`: one write site each (1589, 1598, 1615), zero reads (the `displayBounds` hits at 1460–1480 are an unrelated local in `plotCut`). |
| F63 | V | `updateCutControl` sets `Limits/Value` from canonical `[0,360)`/table θ (646–655); `cutData`/`plotCut` present angles in the signed/elevation convention (1361–1365, 1427). |
| F64 | V | `normalizePattern` appends a φ = 360 copy unconditionally (4915–4917). |
| C1 (circular sense) | V | `E_R = (Eθ + jEφ)/√2` is the IEEE right-hand *component* under `e^{+jωt}`. M7 4726–4727 correct; the readers' inverse (4083–4084, 4143–4144, 4175–4176) consistent. Nothing to change; one fixture pins it. |

### 4.2 New findings (N)

| ID | St. | M7 lines | Finding |
|---|---|---|---|
| **F66** | N | 4227–4563; consumer at 4337; `freqs = NaN` at 4345 | **The Excel summary parser is functionally dead weight.** `readExcelSummary` (4400–4503) and its five helpers (4505–4563) extract ≈ 25 fields — pattern description, model numbers, band name, valid-frequency range, antenna count, pattern type, template revision, author, S/N, the eight-row angular-step table, the frame-definition block (`+X/+Y/+Z`, motion direction, vehicle string, `(az,el) ⇒ X` expressions), and the antenna-position list. `grep` for every one of those field names outside the reader finds exactly one consumer: `metadata.frequencyMHz → metadata.hasFrequency` (4337). For Excel sources `hasFrequency` is never read (`isDep` is set `false` at 4341–4342; `out.freqs = NaN` at 4345, so the Metadata "Frequencies" row never appears). 164 lines with no observable effect; the one useful cell (frequency) is not even surfaced. The plan replaces the block with one `xl_lookup` and publishes the frequency (A.11). |
| **F67** | N | 1512–1531 ← 1758, 2298 | **A getter with a side effect on the UI.** `covThresholds` rewrites `Cov_Spinner_ThreshMax.Value` (1523) when `tMax ≤ tMin`. It is called not only at compute time (2298) but from `covRebuildTable` (1758), which runs on every checked-nodes change and every selection change — so merely clicking a tree node can move a spinner. Removed by `readCoverageConfig` (reads only) + `applyRange("cov")` (the only writer). |
| **F68** | N | 1656, 2553 (writes) / no reads; 2300, 2359; 1684–1686 | **Dead coverage-node state.** (a) `componentBounds = robustRange(...)` is written at two sites and read nowhere → `robustRange` (5141–5152) is dead code. (b) `orientationMode` is initialised `"Spherical"` (2300), never assigned again, and stored on every job including conical ones (2359) — the field lies for every conical job. (c) `sourceTable` and `viewRevision` are copied into each node and used only to recompute what `Pats(k)` already holds. All gone with the shared registry. |
| **F69** | N | 5198–5199 ← 1936 vs 501–513, 523 | **`emptyGridCache` never produces a valid cache.** It seeds a *flat* struct `{valid, theta, phi, linearIndex, sz, data, geom, viewRevision}` at startup, but `gridComp`/`gridGeom` test `isfield(cache,'topology') && cache.topology.valid`. The seeded shape is therefore always "invalid" and rebuilt on first use; the function and the startup line have no effect. Hygiene, but it is a symptom of the cache layer having two schemas. |
| **F70** | N | 4886–4893, 4913–4914 vs 5070–5076, 4853–4858 | **Non-uniform / irregular grids are accepted silently and then mis-weighted.** `normalizePattern` never checks spacing; a source with an uneven θ axis passes through, `resampleCanonical` falls to `scatteredInterpolant` (5070–5076) only if the user selects 1°, and every ΔΩ from `solidWeights` uses `gridStep` = the *minimum* gap (4853–4858) — so wider cells are under-weighted in Ω, directivity, efficiency and coverage. With the owner's position that antenna patterns are uniform, the correct behaviour is to refuse such a file with a clear message, which also deletes the whole scattered path (§16-1 of the plan). |
| **F71** | N (hygiene) | 202, 331–332 | `app.step` is a private property written in `refresh` and read only on the very next line to build a dropdown label — a local variable declared as application state. Gone with `refresh`. |

### 4.3 Items of the previous draft tightened or corrected in this revision

| Topic | Previous draft | This revision | Why |
|---|---|---|---|
| **Main ↔ Coverage state** | Coverage nodes hold their own `Pattern, Geometry, Base` ("or a Revision reference to the app's") and `Dist`; Main node special-cased | **One registry `app.Pats(k)`** shared by both tabs; the Main tab is an index; nodes store `k`; `Dist` lives in the entry | The draft still had two representations and a special case. One struct array removes `syncCoverageNodeFromView`, `syncCoveragePattern`, `covPatternTarget`, `covFindByPath`, the per-node orientation recomputation (F34) and the "frozen parameters" asymmetry (F33) — ≈ 120 lines. |
| **Resampling** | One `pat_interp(kind)` for regular **and scattered** paths; regularisation of irregular sources inside the hull | Regular path only; `pat_build` asserts uniform, regular axes (`APAT:NonUniformGrid`) | Owner decision 1; also fixes F70. Deletes `interpolateScattered`, `scatteredInterpolant`, the `Extrapolation` option and `Meta.Regularized`. |
| **E/H planes** | Polarisation-tilt rule (`pol_tilt`, `met_planes` with three branches, `Planes.Source`) | **M7 principal-axis rule verbatim** (634–642) as a 4-line `met_planes` | Owner decision 6. The `thetaSpanMode` argument M7 threads into `calcMetrics` still disappears because `Map` applies the display convention. |
| **Signed AR at exactly-linear samples** | `NaN` (white on the signed map) | **M7 floor kept:** `Const.LinearAR_dB = −100`; the same `isLinear` mask now drives PLF's exact `r_a → ∞` limit | Owner decision 2. The tolerance mismatch between M7's AR mask (eps-scaled, 4769) and its PLF mask (`polSense == 0`, 4779) is closed by sharing one mask; numerically both gave the same PLF, so this is hygiene, not a behaviour change. |
| **Polarisation label** | Label from `AR_p` and the tilt angle τ, "vertical/horizontal appended only for an equatorial boresight" | Label from `AR_p` (circular ≤ 3 dB) and the leading member of the θ/φ pair over the main beam — the M7 wording | With tilt gone, the M7 label vocabulary is kept; only the region it is decided on changes (F14). |
| **Excel reader** | "logic is correct; only the five summary helpers collapse to one `xl_lookup`" | Summary parser **deleted**; one lookup for the frequency cell, which is now shown in Metadata | F66: the draft had budgeted for keeping dead output. −150 lines. |
| **FEKO unit** | Open: read `Gain(Total)` for dBi labelling (3 lines) or defer | **No calibration code**; `.ffe` is a raw field (`"dB"`) like the other simulator exports | Owner decision 4 (simplest approach). Zero lines. |
| **Body of revolution** | Open: keep 10°, disclosed | Kept as `Const.RevolutionPhiStep = 10` + one Metadata row | Owner decision 5. |
| **UI handles** | Declared properties recommended; struct held as a "reserve lever" (−165 lines) | Reserve lever **withdrawn**; declared properties are an invariant | Owner decision 7. |
| **Gain-only cut traces** | Recommended selected column only | Fixed: selected column only | Owner decision 8. |
| **Efficiency under loss** | Metadata rows are `Metrics0 + L` (efficiency implicitly at `L = 0`) | Efficiency shown as `η₀·10^{L/10}` | M7 includes the loss in efficiency (4635–4638 on loss-scaled fields); the draft would have changed that silently. Now M7-compatible and still an offset (B.3). |
| **Coverage labels** | Not addressed | One job label + one derived table name | M7 carries five label variants per job (`tag, tagFull, tableTag, displayTag, label`, 2329–2343, 1701–1708). |
| **Coverage thresholds** | "by counting (F11)" | + read without writing any widget (F67) | New finding. |
| **Self-test** | 29 rows | 30 rows: `planes` and `polarisationLabel` rewritten for the principal-axis rule and M7 wording; `plfNaN` → `plfAndLinearAR` (checks the −100 floor and the shared mask); `uniformAxes` now expects the error; `readers` gains the Excel-frequency check; new `registryShared` | Each decision and each new defect gets a row. |
| **Static checks** | 10 patterns | + `scatteredInterpolant`, `-100` outside `Const`, `Cov_Spinner_ThreshMax.Value =` outside `applyRange` | F70, decision 2, F67. |
| **Deleted-name list** | 55 names | 66 names (+ `covPatternTarget`, `covFindByPath`, `robustRange`, `coverageTableTag`, `emptyGridCache`, `readExcelSummary`, `summaryValue`, `summaryRowValue`, `summaryNumeric`, `findSummaryLabel`, `normalizeSummaryLabel`, `interpolateScattered`, `isGainDBColumn`, `validateSourceModel`; − `pol_tilt`, which no longer exists to add) | Follows from the new items. |
| **Size** | Budgets sum 2,630; target ≤ 2,800; ceiling 3,000 | **Budgets sum 2,390; target ≤ 2,600; ceiling 3,000** | See §5.1. |

### 4.4 Reclassified: defects that are now decided conventions

| Previous ID | Was | Now |
|---|---|---|
| F13 | "E/H planes ignore polarisation (a y-polarised antenna gets them swapped)" | Owner decision 6: the principal-axis rule **is** the specification. Kept verbatim; the ID is retired in the plan's register. |
| F15 | "Exactly-linear samples placed at the LHCP end of the signed AR map" | Owner decision 2: the −100 dB floor **is** the specification. Kept as `Const.LinearAR_dB`; the ID is retired. |

### 4.5 Checked and left unchanged

- Excel **matrix** readers (`readExcelMatrix`, `readExcelMatrixSheet`, 4227–4398): logic is correct; only the duplicated `raw`/`block` table construction (4318–4324) collapses to one. No behaviour change.
- `calcHPBW` (4860–4880): correct wrap-aware crossing; kept verbatim as `met_hpbw`.
- `calcOrientation` cone rule (4845–4850): correct once fed physical unit vectors and total gain; kept as `met_orientation`.
- `planeSettings` (634–642): kept verbatim as `met_planes` (owner decision 6).
- `fmtNumber` regexes (704–711): correct for integers, `x.5`, `0`; only `-0` is wrong (F53). The single-regex form in the plan is equivalent.
- `solidWeights` seam zeroing (5173–5174): consistent for the tables M7 builds; becomes unnecessary with a seam-free `Pattern`.
- The `.cut` reader's negative-θ fold and 10° revolution (4130–4137): kept (owner decision 5).
- `writeUANFile` header text (1903–1906): kept; only `maximum_gain` changes (F27).

---

## 5. Why the plan is structured as it is — the five collapsing observations

1. **Loss is an offset.** Every level column in M7 is `20·log10(|E|·10^{L/20}) = X₀ + L`; PLF, AR and phase do not depend on `L`. One base at `L = 0` serves all values; coverage shifts thresholds; efficiency scales by `10^{L/10}`. The reprocess on loss change disappears.
2. **Columns are functions, not tables.** One struct array `Cols` (name, label, kind, unit, `fn`) is both registry and materialiser. A component change materialises exactly one `nθ×nφ` matrix; the eager 17-column table, its hidden-column list, the AR name matcher and the gain-column matcher go with it.
3. **A grid-native pattern on uniform axes makes every consumer indexing.** With `Eth, Eph` as `nθ×nφ` on uniform axes, cuts are slices, the display convention is a column permutation plus labels, ΔΩ is rank-1, the cone mask is one expression, coverage is a weighted sort, resampling is decimation or `interp2`. `physicalTheta`, `gridStep`, `solidWeights`, `gridComp/gridGeom`, `applyAngularSpan`, both cut twins, the seam logic **and the scattered path** vanish, and F02/F28/F29/F35/F63/F64/F70 cannot recur.
4. **One pattern object per file, whichever tab uses it.** The Main tab and the Coverage tab need the same tuple `{Pattern, Geometry, Base, ColCache}`; the Main file is simply the entry the Main tab points at. A struct array `Pats` plus one integer `Main` removes every copy and every synchronisation function.
5. **The UI is declared, not scripted.** A grid child is five facts (constructor, parent, row, column, defaults). `place` states them once; 622 lines become ≤ 320 with the same widgets.

### 5.1 Size arithmetic

| Section | Previous budget | This revision | Δ | Source of the saving |
|---|---|---|---|---|
| A + B | 240 | 230 | −10 | no `Regularized`/`Planes.Source` fields; one registry property instead of four |
| C orchestration | 320 | 300 | −20 | `Pats` commit replaces four sync/lookup functions; `readCoverageConfig` has no clamping branch |
| D renderers | 420 | 400 | −20 | fewer label variants; no `Planes.Source` display |
| E coverage UI | 320 | 280 | −40 | nodes hold `k`; one label; orientation from `Base` |
| F export | 80 | 70 | −10 | |
| G layout | 320 | 320 | 0 | |
| H lifecycle | 60 | 50 | −10 | |
| I self-test | 170 | 150 | −20 | shorter `planes`/`label` rows; no regularisation fixtures |
| readers | 400 | 330 | −70 | Excel summary parser → one lookup (F66); no scattered/regularise path |
| numerical core | 300 | 260 | −40 | no `pol_tilt`, no three-branch `met_planes`, no `interpolateScattered`, no `Extrapolation` |
| **Total** | **2,630 sum; ≤ 2,800 target; 3,000 ceiling** | **2,390 sum; ≤ 2,600 target; 3,000 ceiling** | **−240** | |

The 3,000 ceiling is a gate, not a promise; there are now 400 lines of slack between the budget sum and the target, and 610 to the ceiling. No reserve lever is needed.

---

## 6. The eight open points — how each was closed

| # | Open point (previous draft) | Owner's answer | Applied as |
|---|---|---|---|
| 1 | Non-uniform source axes: error, or regularise once and disclose | "We shouldn't have non-uniform inputs (all antenna patterns are uniform)." | `pat_build` asserts uniform, regular axes → `APAT:NonUniformGrid` naming the axis and worst gap (A.12). Scattered interpolation, regularisation and `Meta.Regularized` deleted. Also closes new F70. |
| 2 | Exactly-linear samples in the signed-AR view: NaN or 0 dB | "Same logic as current APAT: assign a 100 dB AR (bad axial ratio)." | `Const.LinearAR_dB = −100` (M7's value on the signed scale, 4771); PLF for the same mask takes the exact linear limit (B.6). |
| 3 | Peak excess | "Keep 6 dB." | `Const.PeakExcessDB = 6`, applied by the spatial rule. |
| 4 | FEKO `Gain(Total)` column for dBi labelling | "Use the simpler/concise/seamless approach." | No calibration code at all: `Meta.Unit` is static per format; `.ffe` = `"dB"`. |
| 5 | Body-of-revolution φ step for a single `.cut` | "Current implementation is already working." | Kept: 10° copies (`Const.RevolutionPhiStep`), one Metadata row for disclosure. |
| 6 | E/H planes for oblique boresights: principal-axis fallback | "Refer to the current implementation which is working." | M7 `planeSettings` rule kept verbatim as `met_planes` (A.7); the tilt-based logic is removed entirely. Previous F13 retired. |
| 7 | UI handles as a struct | "Keep App Designer style." | Reserve lever withdrawn; declared properties are invariant I11 and gate row 28. |
| 8 | Gain-only cut traces | "Selected column only (matches the title)." | `geo_cut` on `View.Component`; gate row 26. |

---

## 7. Design-axis comparison — previous draft vs this revision

| Axis | Previous draft | **This revision** |
|---|---|---|
| Pattern representation | grid-native `Pattern` + `Map` | same, **uniform axes asserted**; no regularisation |
| Where patterns live | `app.Pattern/Geometry/Base` for Main; copies (or a Revision ref) in coverage nodes | **`app.Pats(k)` registry; Main = index; nodes store `k`** |
| Geometry | separable `wθ·Δφ`, `PhiPeriodic` measured | same |
| Columns | `Cols` struct array with `fn` | same; gain-only cuts/coverage on the selected column |
| Loss | offset at point of use | same, **efficiency scales by `10^{L/10}`** (M7-compatible) |
| Peak | spatial isolation, 6 dB | same |
| Resampling | one `pat_interp(kind)` for regular and scattered paths | **regular path only**: decimate or `interp2` |
| E/H planes | polarisation-tilt rule with principal-axis fallback | **principal-axis rule (M7) only** |
| Signed AR at linear samples | NaN | **−100 dB (M7)**, mask shared with PLF |
| Metrics | total gain | same |
| Coverage | `cov_dist/eval/inverse`, loss by shift | same; **orientation from `Base`, thresholds read without side effects, one label** |
| Readers | `io_fields` + 9-row spec table; Excel summary via `xl_lookup` helpers | same; **Excel summary parser deleted**, frequency published |
| Orchestration | `update(scope)` + `guard` + build-then-commit | same, committing into `Pats(k)` |
| Range UI | descriptor-driven `applyRange` + `Range.Auto` | same |
| Layout | declarative, ≤ 320 lines, inventory-verified | same; **handles stay declared properties (no struct option)** |
| Self-test | 29 rows | 30 rows |
| Size | ≤ 2,800 / 3,000 | **≤ 2,600 / 3,000** |
| Defects catalogued | 65 | 71 (F66–F71 new; F13, F15 retired as conventions) |
| Open decisions | 8 | **0** |

---

## 8. What was considered and not admitted (proportionality)

| Candidate | Reason not admitted |
|---|---|
| Using FEKO's `Gain(Total)` column to calibrate `.ffe` to dBi | Owner chose the simplest approach; static unit per format costs zero lines and matches M7's numbers. |
| Deriving the single-`.cut` revolution step from the header `V_INC` | The header carries the θ step, not a φ step; M7's 10° behaviour is declared working by the owner. |
| Polarisation-ellipse tilt for E/H planes | Owner decision 6; removing it also removes `pol_tilt` and two `met_planes` branches. |
| Regularising non-uniform grids inside the hull | Owner decision 1; the assertion is shorter and more honest. |
| Moving UI handles into `app.UI` | Owner decision 7. |
| A generic "reader DSL" (line grammar, tokenisers) | The formats are five column orders plus three block-structured files; a spec row covers the former, small readers the latter. |
| Keeping the Excel summary metadata "for future use" | Rule (b): it is code with no observable effect today; if a future need arises, `xl_lookup` reads any labelled cell in one line. |
| Caching resampled blocks for all frequencies eagerly | Lazy per `(FreqIndex, step)` is simpler and cheaper. |
| Progressive/async rendering | App Designer callbacks are serialised; the retained-mode design already makes each action sub-100 ms. |
| Removing the Input tab raw table | It is a feature; it is pushed lazily instead. |
| Changing any widget, its arrangement or defaults | Out of scope by rule; parity is enforced by the inventory gate. |

---

## 9. Residual risks specific to the closed decisions

| Decision | Residual risk | Disposition |
|---|---|---|
| 1 (uniform only) | A real file in the owner's archive turns out to have an uneven axis (e.g. a hand-edited CSV) | The error message names the axis and the worst gap; the regression step (plan §12-9) runs every archived format before release. |
| 2 (−100 dB floor) | The signed-AR colour map shows exactly-linear samples at the LHCP end, as M7 does | Accepted by the owner; documented in the Metadata "Conventions" row. |
| 6 (principal-axis planes) | A y-polarised antenna on +Z gets E = φ 0° / H = φ 90° (swapped relative to the physical E-plane) | Accepted by the owner as the working definition; HPBW labels name the cut used. |

---

## 10. Summary

- The previous draft's architecture was sound; its remaining weaknesses were **two representations of the same pattern** (Main vs Coverage), **two open numerical paths** (scattered/regularise, tilt planes) that the owner's decisions make unnecessary, and **≈ 165 lines of Excel metadata code with no consumer**.
- Six new defects (F66–F71) were found and each is closed structurally, not patched.
- All eight open points are closed as decided; the plan carries **no open decisions**.
- The size target moves from ≤ 2,800 to **≤ 2,600** lines (budget sum 2,390; ceiling 3,000) with the same widgets, features and formats — every saving is a removed algorithm, path or copy.
