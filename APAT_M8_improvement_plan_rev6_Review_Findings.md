# APAT M8 — Review Findings & Comparison (rev 6)

**Subject reviewed:** `APAT_v3_M7_110_5.m` — 5,199 lines, one App Designer class, 183 functions (95 methods, 34 file-scope functions, ≈ 680 lines of generated layout at 3013–3693).
**Also reviewed:** the previous improvement-plan draft (rev 5: combined document, Review-Findings part, Plan part) and the owner's comments on it.
**Companion document:** `APAT_M8_Improvement_Plan_rev6.md` — the standalone plan. It does **not** refer to this document or to any earlier draft. This document is the *audit trail*: what was checked, what stands, what was wrong, what was cut, and why.

---

## 1. Method

1. The whole M7 file was read line by line (properties 1–250, orchestration and renderers 252–3011, generated layout 3013–3693, lifecycle and self-test 3695–3875, readers 3877–4563, numerical core 4565–5200). Nothing was sampled.
2. Every call graph that matters was traced by hand: load → `refresh` → `applyStep` → `applyAngularSpan` → `updateViewResults` → renderers; component / cut / range / span callbacks; the coverage tab end to end (node creation, sync, compute, query, table).
3. Hot-spot counts were taken mechanically (`grep`) so that "X is done in N places" is a fact, not an impression.
4. Every physics/convention claim in the previous draft was re-derived from first principles rather than accepted. One of them turned out to be wrong (§4.1) — and its own proposed self-test would have failed.
5. Every proposed mechanism in the previous draft was measured against the owner's proportionality rule (§2). Anything that is not needed to fix a verified defect in a *regular* APAT input, or that adds a capability APAT does not have today, was cut (§4.2).

---

## 2. Owner directions applied in this revision

| # | Direction | How it is applied |
|---|---|---|
| O1 | Uniform angular steps are the contract; irregular grids are regularised once, not tolerated everywhere. | Kept as an invariant in the plan. |
| O2 | Coverage is computed on the canonical grid only. | Kept. |
| O3 | Coverage is the explicit CCDF formula, visible in the code. | Kept; the kernel header is the formula. |
| O4 | No Stokes parameters. | Nothing in the plan uses `I,Q,U,V`. The polarisation tilt is the textbook ellipse-tilt formula written on the complex components. |
| O5 | Review findings and the standalone plan are separate documents; the plan must not refer to earlier revisions. | Two files. The plan is anchored only to M7 line numbers and to its own appendices. |
| **O6** | **No over-engineering.** Examples given: Ludwig-3 handling, FFD "sibling .txt" — neither is part of a regular APAT input. | A proportionality rule now gates every item: *a change is admitted only if it fixes a verified defect for an input APAT already accepts, or removes code, or is required by another admitted item.* The full cut list is §4.2. |
| **O7** | Improve architecture / algorithm / dataflow so the logic is more concise and transparent, and faster/more robust. | The plan's core is three observations that collapse most of M7's machinery (§5). |

---

## 3. M7 anatomy in numbers (measured)

| Fact | Count / lines | Consequence |
|---|---|---|
| Table copies of one sphere per refresh | 6 (`rawTbl, stdTbl, patTbl, viewBaseTbl, viewTbl, uanTbl`, 189–194) + 2 per coverage node (1684–1686) | Every stage re-derives grid structure from a long table. |
| `physicalTheta(...)` call sites | 13 | Display convention (elevation θ) is stored *in the data* (453) and undone downstream — and forgotten in 3 numerical paths (§4-F02). |
| `gridStep(...)` call sites | 17 | Step is re-measured by every consumer. |
| `solidWeights(...)` call sites | 6 | Solid-angle weights recomputed per consumer; one of them from display θ. |
| `resolvePeak(...)` call sites | 10 | A 65k-sample `prctile` (sort) runs on tree clicks, range presets, component changes. |
| `findall` / `findobj` | 11 | Renderers locate their own objects by tag search after creating them. |
| `cla(...)` | 6 | Every full-pattern view is rebuilt from scratch on every change. |
| Widget `.UserData` used as application state | 18 sites | Flags live in `Single_DropDown_step`, `CutFieldBasisDropDown`, `Single_DropDown_output`, `Cov_gridPanel_Parm`, both status labels. |
| Columns computed eagerly per refresh | 17 (8 hidden by default) | EIRP/PFD/E_RMS/phases computed for 65k samples even when never shown. |
| Full-pattern tabs rendered per change | 5 (1 visible) | The dominant cost of a component change. |
| Duplicate algorithms | `cutGeometry` ≡ `calcCutGeometry`; `gainDisplayRange` ≡ `coverageDisplayRange`; `robustRange`; 4 inline circular splits | Any policy change must be made in 2–4 places. |

---

## 4. Findings

Findings carry stable IDs **F01–F57**; the same IDs are used in the plan's defect register so the two documents can be cross-read without either depending on the other. Each row cites M7 lines. Status: **V** = verified defect (also known to the previous draft), **N** = new in this review, **C** = a *correction* of the previous draft.

### 4.1 Corrections to the previous draft (C)

| ID | Previous claim | Verified reality | Effect |
|---|---|---|---|
| **C1 — circular sense** | "M7's `E_R = (Eθ + jEφ)/√2` (4726) is inverted; IEEE RHCP under `e^{+jωt}` is `E_R = (Eθ − jEφ)/√2`; introduce `Const.CircularSign` and flip it." | **M7 is correct.** The draft confused the *basis vector* with the *projection coefficient*. With `(θ̂, φ̂, r̂)` right-handed and `e^{+jωt}`, the IEEE right-hand unit vector along `r̂` is `ê_R = (θ̂ − jφ̂)/√2` (Balanis §2.12). The RHCP **component** of `E = Eθ θ̂ + Eφ φ̂` is the projection on the *conjugate* basis: `E_R = E · ê_R* = (Eθ + jEφ)/√2`, `E_L = (Eθ − jEφ)/√2` — exactly M7's lines 4726–4727. Check with a pure RHCP field `E = ê_R` ⇒ `Eθ = 1/√2, Eφ = −j/√2` ⇒ M7 gives `E_R = 1, E_L = 0` ✓. The draft's own gate row ("`Eθ = 1, Eφ = −j` → RHCP with the flipped sign") evaluates to `E_R = (1 − j·(−j))/√2 = 0` under its formula — it would have **failed its own test**. M7's inverse in the readers (4083–4084, 4143–4144, 4175–4176, Excel) is consistent with its forward split. | The `CircularSign` constant, the flip and the "owner-verify gate" are removed. The plan pins M7's convention in one function with a comment and a fixture (`Eθ = 1, Eφ = −j ⇒ pure RHCP`) so it can never drift. |
| **C2 — E/H planes** | Fix D26 with the polarisation-ellipse *major axis* (`χ = ½·arg(E·E)`, `a = Re(E e^{−jχ})`), great-circle cuts sampled by `interp2`, and a new "arbitrary plane" cut type. | The defect is real (F13) but the fix is disproportionate (O6). All that is needed is the ellipse **tilt angle** at the peak, `τ = ½·atan2(2·Re(Eθ·conj(Eφ)), |Eθ|² − |Eφ|²)` (Balanis eq. 2-xx form written on the components — not a Stokes computation), and a rule that snaps E/H to the **existing grid cuts**: for ±Z boresight `φ_E = φ_peak + sign(cos θ_peak)·τ` (θ-cut), `φ_H = φ_E + 90°`; for equatorial boresight `|τ| < 45°` ⇒ E = vertical θ-cut, H = φ-cut at θ = 90°, else swapped; oblique ⇒ M7's principal-axis rule, disclosed. ~12 lines, no interpolation, no new cut type. | Great-circle sampler, `met_copolAxis`, the "Plane through peak (custom tangent)" UI item are removed. |
| **C3 — calibration** | Parse FEKO gain columns, CST `.ffs` header power, HFSS `.ffd` companion `.txt`, UAN `maximum_gain`; add `io_calibrate` with `Const.Eta0`. | The *disclosure* problem is real (F20): raw far fields from FFE/FFS/FFD/OUT/CUT are labelled "dBi" and an efficiency is printed for them. Parsing sidecar files is outside a regular input (O6). The proportionate fix is a **per-format unit class** (`dBi` for UAN/FZ/Excel/gain-only, `dB (relative field)` for FFE/FFS/FFD/OUT/CUT), used for colorbar/axis/metadata labels, and **efficiency / EIRP / PFD / E_RMS shown only for `dBi` sources**. Zero parsing. | `io_calibrate`, `Const.Eta0`, sidecar reading, header power parsing are removed. (FEKO's own gain column is *already in memory* after `readmatrix`; using it is a 3-line optional item, listed as such — not required.) |
| **C4 — Ludwig-3** | Convert GRASP `.cut` `ICOMP = 3` (Ludwig-3) to θ/φ with a reference-axis option. | Not a regular APAT input (O6). M7's real defect is that *any* `ICOMP ≠ 2` is silently read as θ/φ (F16). The proportionate fix is to **reject** `ICOMP ∉ {1, 2}` with a clear error. | `io_ludwig3ToThetaPhi` removed. |
| **C5 — FFD sidecar** | Read `<name>.txt` next to `.ffd` for accepted power. | Not a regular input (O6). See C3. | Removed. |
| **C6 — resampling diagnostic** | Report a "phase-coherence" figure (`|Z_q|`) in Metadata with a threshold constant. | The magnitude/phase-separable interpolation itself is proportionate (it fixes F04 in five lines). The diagnostic row, its constant and its metadata plumbing are an extra feature. | Interpolation kept; diagnostic dropped. |
| **C7 — `guard` deferred replay** | Busy flag with a pending-scope replay queue. | A busy flag that drops re-entrant `ValueChanging` storms is enough; App Designer callbacks are already serialised, and long operations run behind a cancellable progress dialog. | Replay removed; `guard` = `try/catch` + cancel + one `drawnow`. |
| **C8 — column registry as `cell2table`** | A 16-row `table` in a Constant property driving everything. | The idea (one place for column semantics) is right and admitted. A `table` inside a `Constant` property is heavier than needed and slow to index in hot paths; a struct array with a function handle per column is simpler and doubles as the *materialiser* (§5.2), which the draft kept as two separate stages (`pat_calcBase` + `pat_applyParams`). | Replaced by `Cols` (struct array): name, label, kind, unit, `fn(P, prm)`. |
| **C9 — size claim** | "≈ 3,150 lines (−37 %)". | Not verifiable before the work; the layout block alone is 680 lines and must stay. The plan gives a *budget per section* and a ceiling, not a promise. | Budget in the plan §10. |
| **C10 — decimation rule** | rev 4 said "decimate when the native step is an integer multiple of the target"; rev 5 corrected it to "target/native ∈ ℕ". | rev 5's correction is right and stands. | Kept. |

### 4.2 Over-engineering removed (O6) — summary

Removed from the plan entirely: Ludwig-3 conversion; FFD sidecar `.txt`; CST/FEKO/UAN self-calibration and `Const.Eta0`; `Const.CircularSign` and its flip; polarisation-ellipse major-axis vector and great-circle cut sampler; the "arbitrary plane" cut type; phase-coherence diagnostic; deferred-replay queue; per-format *descriptor dictionary* for readers (the readers are small `switch` cases; a dictionary adds indirection without removing code); "reference power" spinner; new metadata rows for conventions that do not change (time convention, axis triad) — one *"Conventions"* row suffices.

Kept because each fixes a verified defect with less code than M7 has today: grid-native pattern; separable geometry; lazy memoised columns; loss as an offset; spatial peak; sorted-CCDF coverage; exact decimation + power/phasor interpolation; retained-mode graphics; one `update(scope)`; static self-test; unit class per format; header-name axis detection; NaN-safe PLF; ICOMP rejection; FFE block split (FEKO multi-frequency `.ffe` files are a regular input and M7 silently drops all but the first block, F19).

### 4.3 Numerical policy

| ID | St. | M7 lines | Finding |
|---|---|---|---|
| F01 | V | 5085–5139, 5113 | `resolvePeak` uses `prctile` (Statistics Toolbox) and a **grid-independent** policy (P99.99 + 6 dB). On a 65k-sample 1° sphere P99.99 is ≈ the 7th-highest sample; a legitimate pencil beam whose top ~6 samples sit > 6 dB above the 7th is demoted (the reported POB is lowered and the true peak is masked from ∫). On a coarse 7×12 grid the policy can never trigger. A spatial rule (neighbour comparison) is the correct notion of "isolated spike" and needs no toolbox. |
| F02 | V | 2810→4834–4851; 4643; 1683, 2552 | With "−90° to 90°" active, `viewTbl.Theta` holds elevation (453). `calcOrientation` builds `solidWeights` and sample unit vectors from it (4838, 4847–4848); `calcMetrics` treats it as physical (4643, the variable is even *named* `thetaPhysical`); coverage-node boresight detection (2552) inherits the same table. Solid-angle weights collapse to ≈ 0 for the lower hemisphere, boresight and F/B are wrong. |
| F03 | V | 4904–4907 | `normalizePattern` rounds **every numeric column** — including `Re_Eth … Im_Eph` — to 5 decimals. Relative error `1e-5/|E|`: 0.09 dB at `|E| = 1e-3`, 0.8 dB at `1e-4`, total loss below. Raw CST/FEKO fields are O(1e-2) at the peak, so sidelobes from −40 dB down are corrupted before any processing. Only *angles* need snapping. |
| F04 | V | 4920–5041, 5059 | Regular-grid resampling interpolates `Re/Im` linearly. For a phase slope Δψ per sample the midpoint magnitude is `|cos(Δψ/2)|`: −6 dB at 120°, a null at 180°. Any pattern with a displaced phase centre at 2° → 1° shows interpolation dips. |
| F05 | V | 4980–4984, 5061–5066 | Target grid is **always** `0:step:180 × 0:step:360` and missing cells are filled with `'nearest'`. A hemispherical source becomes a full sphere of fabricated data; efficiency, coverage and F/B then include it. |
| F06 | V | 421–424 | "Decimation" keeps integer-degree samples. Exact only when `1/native ∈ ℕ`; a 0.3° source yields a **3°** grid; 0.4° yields 2°. |
| F07 | V | 4630–4641; 5170–5172 | Spike samples are removed from the ∫ numerator (`metricGain(outlier) = NaN`) but their ΔΩ stays in the implicit denominator; efficiency and F/B are printed for partial spheres. |
| F08 | V | 4761–4762, 4778–4779 | Non-finite AR ⇒ `polSense = 0` ⇒ `antennaRatio = 1e12` ⇒ PLF of a *perfectly linear* antenna. NaN fields become a definite PLF. |
| F09 | N | 315, 432 | `refresh` runs `calcPattern` on the native table (→ `patTbl`), then `applyStep` runs it **again** on the resampled table (→ `viewBaseTbl`). With the 1° option active the first result is discarded every time. |
| F10 | V | 4593–4597; 2275–2279 | `coverageCCDF` builds an `N×T` logical matrix and multiplies it (logical → double promotion): 65k × 500 thresholds ≈ 260 MB transient. The cache key includes the threshold vector, so changing thresholds recomputes everything although the underlying distribution is unchanged. |
| F11 | N | 1525 | Threshold vector by colon accumulation (`tMin:step:tMax`) — with 0.1-dB steps the values carry 1e-15 residues; the cache key (`gridStep(thresholds)`) and table matching then depend on rounding luck. Counting (`tMin + (0:n)·step`) is exact. |
| F12 | V | 2810, 569–583 | Orientation, metrics peak and "POB" are computed on the **selected component** (`app.comp()`): choosing "Axial Ratio" moves the boresight axis and reports the most-linear-RHCP-sense sample as "POB … dB". Physical quantities must be defined on total gain. |
| F13 | V | 634–642; 4671–4686 | E/H planes are chosen from the principal axis alone: +Z boresight ⇒ E = θ-cut @ φ = 0, H = θ-cut @ φ = 90. Correct only for x-polarisation; a y-polarised antenna gets E and H **swapped** (HPBW labels wrong). |
| F14 | V | 4743–4757 | "Linear (Vertical/Horizontal)" from sphere-mean `|Eθ|²` vs `|Eφ|²` — basis-dependent, dominated by far sidelobes on a full sphere, not a property of the beam. |
| F15 | N | 4769–4771 | Exactly equal circular components (a perfectly linear sample) are assigned `AR_dB = −100`, i.e. the extreme **LHCP** end of the signed colour scale (deep blue). Linear should sit at the centre of the map or be undefined (NaN/white), not be conflated with a sense. |

### 4.4 Import / physics disclosure

| ID | St. | M7 lines | Finding |
|---|---|---|---|
| F16 | V | 4139–4149 | GRASP `.cut`: only `ICOMP == 2` is special-cased; **every other** `ICOMP` (1 = θ/φ, 3 = Ludwig-3, others) is read as θ/φ silently. Correct action for `ICOMP ∉ {1,2}`: refuse with a message. |
| F17 | V | 4132–4137 | Single-cut `.cut` is expanded into a body of revolution at 10° φ — not recorded anywhere; Metadata then shows "φ step 10°" as if measured. (10° is harmless for a true body of revolution; the *disclosure* is the fix.) |
| F18 | V | 4162–4167 | UAN/FZ header (`begin_<parameters> … end_<parameters>`) is skipped entirely; `magnitude`, `phase`, `polarization`, `pattern` keywords are never checked. A `magnitude linear` or `phase radians` file is misread silently. Proportionate fix: read the header, **assert** the assumed form, error otherwise. |
| F19 | V | 4155–4159, 4185–4190, 4913 | FEKO multi-frequency `.ffe`: `readmatrix` concatenates all blocks; `normalizePattern`'s `unique(…,'first')` keeps block 1 silently. FEKO exports several frequencies routinely — this is a regular input. The FFD block dropdown already exists in the UI and can serve FFE blocks unchanged. |
| F20 | V | 4159–4190; 4638; 1290 | FFE/FFS/FFD/OUT/CUT deliver raw far-field values (V or V/m); M7 labels them "dB"/"dBi" identically to UAN/Excel gain and prints a radiation efficiency for them. Unit class per format + gating of efficiency/EIRP/PFD/E_RMS is the whole fix. |
| F21 | V | 4013 | Generic text: `rmmissing(readtable(...))` deletes any row with a NaN in **any** column — including trailing unused columns. A sparse 7th column silently removes samples and punches holes in the grid. |
| F22 | V | 4035–4041 | Generic gain: θ/φ order decided by value span even when the header **names** the columns (`theta`, `phi`, `az`, `el`); the decision is not disclosed. |
| F23 | V | 4059 | Magnitude/phase column layout decided by "any value > 100": a −110 dB null qualifies a magnitude column as phase; a phase column in [−90, 90] never qualifies. |
| F24 | V | 4021–4023 | Coverage-results detector: any generic file with `textFormat == "gain"` or < 6 columns, a strictly monotonic first column and a second column in [0, 100] is a coverage file. A 2-column gain cut (θ, gain in 0…60 dBi) is captured. |
| F25 | N | 4886–4893 | `normalizePattern` re-interprets *any* table with θ ∈ [−90, 90] containing negatives as **elevation**, for every format. A generic polar file spanning ±90° (or a GRASP-style negative-θ half-cut written as CSV) is silently rotated by 90°. The decision belongs to the reader and must be disclosed. |
| F26 | V | 4713–4715; 5160 | Gain-only sources: loss is added to **every** column from 3 on (AR, phase, whatever the header says); the "gain" column used for peaks/metrics is column 3 whatever it is. |
| F27 | V | 1902 | UAN export writes `maximum_gain = max(E_TH_dB, E_PH_dB)` — the larger component peak, not total gain. |

### 4.5 Dataflow and state

| ID | St. | M7 lines | Finding |
|---|---|---|---|
| F28 | V | 189–194; 439–459; 480–487 | One sphere ⇒ 6 long tables; the display convention (elevation θ, signed φ, seam duplicates) is **written into the data** and undone by `physicalTheta` at 13 sites (and forgotten at 3, F02). `sortrows` on 17 columns per span toggle. |
| F29 | V | 4853; 5164; 499–536 | Grid structure (`unique`, `gridStep`, `ismember`, `sub2ind`) and ΔΩ are rebuilt by every consumer; `gridCache` exists only to hide this. |
| F30 | V | 658–688 ≡ 4812–4832; 865–886 ≡ 1559–1579; 5141–5152; 4083, 4143, 4175, Excel | Duplicate algorithms: cut geometry (method + file function, identical), display range (two copies + `robustRange`), circular↔θφ split (4 inline copies). |
| F31 | V | 18 sites | Application state in widget `UserData` (step "preserve 1°" flag 324/342/2052/2117, basis auto flag 320/2052/2071/2802/2840, output filter mask 602/611/2199, coverage panel mode 1542, status restore text). |
| F32 | V | 282, 1336, 1355 | Readers/getters write widgets: `prepareTextFormat` sets a dropdown value and visibility; `cutCols` renames checkboxes; `cutData` (a *data extractor*) writes a **permanent** status message on every snap. |
| F33 | V | 1684–1686; 2264 vs 297; 2290–2293 | Coverage nodes hold two table copies (`pattern`, `sourceTable`). The Main-file node is re-synced from the live view at compute time (loss, step, span follow the Main tab); nodes loaded on the Coverage tab are frozen with the Main-tab parameters *at load time*. Two curves in one table can carry different loss/step with no label saying so. |
| F34 | V | 1663, 2749 | Every tree click ⇒ `syncCoveragePattern` ⇒ `coverageDisplayRange` ⇒ `resolvePeak` (65k-sample sort). |
| F35 | N | 458 | `viewRevision` increments on display-only toggles (signed φ / elevation) and is part of the coverage cache key (2276) ⇒ toggling a display switch invalidates coverage caches that cannot have changed. |
| F36 | V | 1590, 1596; 914 | Threshold presets, coverage X-range **and** the main range sliders only ever widen (`min/max` against the current value). After a few patterns a 50-dB window is 100+ dB and the threshold vector/table grow silently. |
| F37 | V | 345 vs 653 | Cut-value spinner `Step` set twice with different rules. |
| F38 | V | 837–847 → 893–899 | Selecting the AR component routes `[−30 30]` through scope `"all"`, which also rewrites the **cut** range ⇒ cut plots collapse to ±30 dB. |
| F39 | V | 2000–2010 vs 2119–2126 | Re-selecting the loaded file is refused with a dialog loop, while `Process` happily re-parses generic files — two paths for one intent. |
| F40 | N | 4802–4807; 590–608; 2208 | 17 columns are materialised eagerly (8 hidden by default); the whole 65k×17 table is pushed to the `uitable` and re-sliced on every component change whether or not the Results tab is visible. |

### 4.6 Graphics, UI, hygiene

| ID | St. | M7 lines | Finding |
|---|---|---|---|
| F41 | V | 997–1013; 1015–1023; 1118, 1256, 1279, 2947 | All five full-pattern views are rendered eagerly on **every** change (`cla` + `surf`/`pcolor`), although one tab is visible. This is the dominant cost of a component or parameter change. |
| F42 | N | 1210–1219; 992, 1229, 1233, 2891 | `configurePlotContextMenu` creates a **new** `uicontextmenu` (a figure child) per render and per `format3DAxes` call and never deletes the previous one — the figure accumulates menus for the session. 11 `findall/findobj` searches locate objects the code itself just created. |
| F43 | V | 805; 1297–1308; 1261 | Colorbar recreated on every theme application; 3 `quiver3` + 3 `text` re-created per 3-D render. |
| F44 | V | 1251–1253 vs 1317; 1237 vs 1265 | Polar-3D: surface radius is normalised twice (to the range, then to its own max); the overlay uses the first normalisation only, and receives `slider.Value` in one path and the theme limits in the other ⇒ overlay floats off the surface. |
| F45 | V | 2833–2834; 1396, 1311, 2846 | Gain-only component change plots the cut twice; each cut change calls `cutData` up to three times (2-D cut, and once per 3-D overlay). |
| F46 | V | 1438, 1458 | Cut POB marker and HPBW are computed on the **first checked** trace; with Total unchecked the label still says "HPBW". |
| F47 | V | 1818; 1817 | A new `timer` object per transient status; `statusLabel.UserData = statusLabel.UserData;` is a dead statement in the one status path everything uses. |
| F48 | V | 1928 | `startPerf` does `assignin('base', …)` on every load/process/step/coverage action, unconditionally. |
| F49 | V | 2256 | `Cov_Button_LoadPushed` parses the file **outside** its `try` — a reader error escapes as an uncaught callback error. |
| F50 | V | 2648 | Query projection line starts at hard-coded x = −250 instead of `ax.XLim(1)`. |
| F51 | V | 3715 | `runSelfTest` needs a live app instance (reads `app.PrincipalAxes` etc.); cannot run headless or as a release gate. |
| F52 | V | 785, 1121, 1247, 1283, 2950 | `plotTheme(app, ~)` ignores its argument; four call sites pass a value that is never used. |
| F53 | V | 704–711 | `fmtNumber(-0.001)` prints `-0`. |
| F54 | V | 507 | `[~, pi] = ismember(...)` shadows `pi`. |
| F55 | N | 610–622 | Visibility of the Loss / Rx / Tx / Distance **parameters** is derived from which columns are *checked in the output-table filter*: hide `E_Total_dB` from the table and the loss spinner disappears. Parameter visibility should follow the source kind and the selected component, not a table filter. |
| F56 | N | 947–972, 1026–1084, 2849–2924 | ≈ 250 lines of annotation bookkeeping (`AnnotationSources`, `FullPatternPOBRecords`, `refreshAnnotations`, `clearAnnotations`, `createPOBDataTip`, `ensureFullPatternPOBAnnotations`) manage what is, per view, **one marker and one datatip**. Create-once handles with `Visible` toggles remove the whole layer. |
| F57 | V | 3073 vs 248–249 | Window title says `M7.110`; `ReleaseName` says `7.110_5`. |

Re-confirmed as *not* defects: the `gridCache` schema mismatch between `emptyGridCache` (5199) and `gridComp` (501) is harmless (`isfield(cache,'topology')` is false ⇒ rebuilt); the UAN export's inclusion of the φ = 360 seam column is self-consistent with its `phi_max 360` header.

---

## 5. What is new in the rev 6 design (and why it is simpler, not bigger)

Three observations that the previous draft only partly exploited:

1. **Loss is an offset, not a pipeline stage.** `FieldScale = 10^(L/20)` (387) multiplies both components ⇒ every dB level column shifts by exactly `L`; AR, phases and PLF are unchanged; EIRP shifts by `L`; PFD and E_RMS scale by `10^(L/10)` and `10^(L/20)`. Therefore *nothing* upstream of rendering depends on loss: peaks, boresight, HPBW, directivity, coverage distributions are all computed once at `L = 0`, and `L` is added where a number is displayed, tabulated, exported, or a threshold is compared (`Ω{G+L > T} = Ω{G > T−L}`). The "params" rung of the update ladder shrinks to: recompute PLF when Rx settings change.

2. **Columns are functions, not tables.** One struct array `Cols` (name, label, kind, unit, `fn(P, prm)`) is both the *registry* (dropdown items, table filter defaults, colour theme, cut pairs, coverage component list, parameter-control visibility) and the *materialiser* (memoised per `(Revision, key)`). A component change materialises exactly one `nθ×nφ` matrix. The eager 17-column table and its two-stage base/derived split disappear together.

3. **A grid-native pattern makes every consumer indexing.** With `Eth, Eph` as `nθ×nφ` complex matrices on uniform axes: cuts are row/column slices; the display convention is a column permutation plus axis labels; ΔΩ is a rank-1 outer product `wθ·Δφ`; the cone mask is one matrix expression; coverage is a weighted sort. `physicalTheta`, `gridStep`, `solidWeights`, `gridComp/gridGeom`, `applyAngularSpan`, both `cutGeometry` twins and the seam-duplication logic vanish, and F02/F28/F29/F35 cannot recur.

Everything else in the plan follows from these three: one `update(scope)` ladder, retained-mode graphics that update `CData` in place and render only the visible tab, and a static self-test built on tiny analytic fixtures.

---

## 6. Design-axis comparison — previous draft vs. rev 6

| Axis | Previous draft (rev 5) | **rev 6** |
|---|---|---|
| Circular decomposition | Flip M7's sign via `Const.CircularSign` | **Keep M7 (proven correct)**; pin + fixture |
| E/H planes | Ellipse major-axis vector + great-circle `interp2` cuts + new cut type | Tilt angle at the peak → snap to existing grid cuts (≈ 12 lines) |
| Calibration | Parse FFE columns / FFS header / FFD sidecar / UAN `maximum_gain`; `io_calibrate`; `Const.Eta0` | Static unit class per format; gate efficiency/EIRP/PFD/E_RMS |
| GRASP `.cut ICOMP=3` | Ludwig-3 → θ/φ converter | Reject with message |
| Resampling | Power + unit phasor + coherence diagnostic row | Power + unit phasor only |
| Column semantics | `cell2table` registry + `pat_calcBase` + `pat_applyParams` | `Cols` struct array with `fn` (registry **and** memoised materialiser) |
| Loss handling | "Params-free base", element-wise params layer | **Offset at the point of use**; PLF is the only Rx-dependent recompute |
| Re-entrancy | Busy flag + deferred replay | Busy flag |
| Readers | Descriptor dictionary + parsers | Small `switch` per extension, unit class + block split + header assertions |
| Peak policy | Spatial isolation (4-neighbour, pole ring) | Same |
| Coverage | Ω-histogram + suffix sum + oracle | Same idea, cached **per node/component**, evaluated for any thresholds, loss by shift |
| Self-test | Static, fixture generators | Same, fewer rows, one fixture per convention |
| Size | Promised ≈ 3,150 | Budget per section, ceiling 3,600 including the 680-line layout |
| Defects catalogued | 66 (some overlapping, one wrong) | 57 consolidated (10 new: F09, F11, F15, F25, F35, F40, F42, F55, F56 + C1) |

---

## 7. Decisions still open for the owner

Only items the plan cannot decide by itself; each has a recommendation in the plan §15.

1. **Non-uniform source axes** — error out, or regularise once onto the native minimum step (recommended: regularise once, disclose `Regularized`).
2. **Exactly-linear samples in the signed-AR view** — NaN (white) or 0 dB centre (recommended: NaN, shown white; PLF uses the linear-limit formula).
3. **Peak excess threshold** — keep 6 dB as the spatial-isolation excess (recommended: yes).
4. **FEKO gain column** — optional 3-line use of the in-file `Gain(Total)` column for `dBi` labelling of `.ffe` (recommended: defer to M8.1 unless FEKO is a primary source).
5. **Body-of-revolution φ step for single `.cut`** — keep 10° (recommended: keep, disclose).
