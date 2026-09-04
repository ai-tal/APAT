# APAT M8 — Architecture & Improvement Plan

**From:** `APAT_v3_M7_110_5.m` — 5,199 lines, one App Designer-style class, 183 functions (95 methods, 34 file-scope functions, 680 lines of hand-written layout at 3013–3694).
**To:** `APAT_v3_M8.m` — the **same one file**, the **same widgets, feature set and input formats**, rebuilt around one dataflow, one pattern registry shared by both tabs, and one declarative layout. Base MATLAB (R2023b baseline), **no toolboxes**.
**Size target:** **≤ 2,600 lines** (hard ceiling 3,000), budgeted per section in §11.
**Delivery:** one drop. The numerical core is written and self-tested first; the UI is then pointed at it; every M7 name the core replaces is deleted in the same edit. No dual paths, no compatibility shims.

All **line numbers** in this document refer to `APAT_v3_M7_110_5.m`. Defect IDs (**F01–F71**) are labels local to this plan (register in §10).

---

## 0. Proportionality rule (governs every item below)

> A change is admitted only if it (a) fixes a verified defect for an input APAT already accepts, or (b) removes code, or (c) is required by another admitted item.

Direct consequences, **out of scope**: new file formats or format variants, new plot/cut types, new metrics, Stokes-parameter formulations, toolbox dependencies, calibration from anything but the pattern file's own value columns, changes to the set of widgets or their arrangement, moving UI handles out of declared App Designer-style properties.

---

## 1. Executive summary

M7 is feature-complete and careful in places, but long and slow for five structural reasons:

1. **The same sphere is re-interpreted by every consumer.** One pattern is materialised as six long tables per refresh (189–194) plus two per coverage node (1684–1686). The *display* convention (elevation θ, signed φ) is written into the data (439–459) and undone by `physicalTheta` at 13 sites — and forgotten at three, so solid-angle weights, boresight and F/B are wrong whenever the elevation view is active (F02). Grid structure is re-derived everywhere (`gridStep` ×17, `solidWeights` ×6, `unique/ismember/sub2ind` in `gridComp`).
2. **UI callbacks own algorithms.** A component change re-runs orientation and metrics, rebuilds all five full-pattern views with `cla`+`surf` (one is visible), creates new context menus and colorbars, and pushes a 65k×17 table to a `uitable`. State lives in 14 widget `UserData` slots and 48 `NodeData` touches.
3. **Main and Coverage keep two copies of the same idea.** The Main tab holds a pattern in `viewTbl`; the Coverage tab copies it into a tree node (`pattern`, `sourceTable`, `solidAngle`, `boresightIndex`, …) and three functions exist only to keep the copies in step (`syncCoverageNodeFromView`, `syncCoveragePattern`, `covPatternTarget`). Every tree click re-runs a 65k-sample percentile (F34).
4. **Several numerical policies are silently wrong for legitimate inputs:** fields rounded to 5 decimals (F03), `Re/Im` interpolation under phase slope (F04), gain-only dB interpolated linearly on regular grids despite the option that claims otherwise (F59), hemispheres extrapolated to full spheres (F05), a *toolbox* percentile peak policy that can demote a real pencil beam (F01), NaN fields turned into a definite PLF (F08), raw far fields labelled dBi with an efficiency (F20), metrics computed from whichever component is selected (F12), a gain-only cut that always plots column 3 whatever the user selected (F58).
5. **The layout is scripted, not declared, and the readers carry dead weight.** 622 lines build 118 widgets with 190 separate `Layout.Row/Column` statements; the Excel summary reader spends 164 lines (4400–4563) extracting metadata that nothing in APAT ever displays (F66).

M8 keeps the UI and changes the program underneath it:

> **One grid-native pattern on uniform axes. One separable geometry. One column table that is also the materialiser. Loss is an offset. One pattern registry serving Main and Coverage. One `update(scope)` with build-then-commit. One config reader. Retained graphics that render only what is visible. One declarative `place()` for the layout. One place per convention, shown in Metadata. A static self-test as the release gate.**

Expected outcome (§17): ≤ 2,600 lines with every widget preserved; zero duplicate algorithms; zero toolbox calls; component change ≈ one `CData` assignment; loss change ≈ zero recomputation; coverage cost independent of the threshold count; 71 catalogued defects closed, each with a self-test row or a static check.

---

## 2. Goals and non-goals

**Goals**
1. Correct physics for every supported input: solid angle, peak, resampling, polarisation sense, principal planes, unit disclosure.
2. One implementation per concept; one declaration per widget; one pattern object per loaded file, whichever tab uses it.
3. Every user action recomputes only its invalidation radius and touches only the graphics it changes.
4. Everything numerical is testable without a UI — and tested.
5. Every convention is pinned in one place and visible to the user.
6. Same file, same widgets, same features, same or better output on all existing inputs (deliberate deltas listed in §10 and §16).
7. **≤ 2,600 lines**, ceiling 3,000.

**Non-goals:** new formats/variants, new plots/cuts/metrics, external calibration, a PLF tilt selector, polarisation-tilt-based E/H plane selection, non-uniform (irregular) source grids, a UI-handle struct.

---

## 3. Governing rule and invariants

### 3.1 The rule

```matlab
cfg    = app.readConfig();          % the ONLY place widget .Value is read
result = f(data, cfg);              % app-free, alert-free, widget-free
app.apply*(result);                 % the ONLY places Items/Limits/Text/Visible/CData are written
```

Every callback is one expression in the layout: `'ValueChangedFcn', @(~,~) app.on("cut")`. `on(scope)` owns `try/catch`, cancellation, the busy flag, build-then-commit and the single `drawnow`.

### 3.2 Invariants (the drop is invalid if any of these move)

| # | Invariant |
|---|---|
| I1 | **Canonical pattern:** polar θ ascending in [0,180], φ ascending in [0,360), **uniform steps asserted once** (`APAT:NonUniformGrid` otherwise — antenna patterns are uniform by definition, §16-1), grid-native `nθ×nφ`, no seam column. `PhiPeriodic` is a *fact* of the source, never assumed (F64). Angles snapped to 5 decimals; **field values never rounded**. |
| I2 | **Separable geometry:** `ΔΩ(i,j) = wθ(i)·Δφ`; `Σ ΔΩ = 4π` exactly on a full sphere (telescoping, B.1). Nothing else measures a step or computes a weight. |
| I3 | **Loss is an offset.** Level columns are computed at `L = 0`; `L` is added at display/table/export and by threshold shift in coverage. Peak index, boresight, HPBW, directivity, F/B are loss-independent by construction; efficiency scales by `10^(L/10)` (M7-compatible). |
| I4 | **Physical quantities are defined on total gain** (or the first `gain`-kind column). Component selection changes plots, tables, cuts and the POB marker only. |
| I5 | **Peak policy = spatial isolation.** A sample is a spike iff it exceeds every grid neighbour (4-neighbours, φ-wrap, adjacent ring for pole rows) by more than `Const.PeakExcessDB = 6` (§16-3). Effective peak = highest non-spike sample. Raw and effective peaks both reported. No percentile, no toolbox. |
| I6 | **Resampling never interpolates dB, AR or PLF.** Exact decimation when `native/target ∈ ℕ`; otherwise bilinear on the φ-closed grid: E-field per component as linear power + unit phasor, gain-kind columns as linear power, other kinds linear (F04, F59). Target axes never leave the source domain (F05). Columns are computed **after** resampling. |
| I7 | **Coverage:** `Coverage(T) = 100·Ω{G > T}/Ω_R`, strict `>`, ties exact, canonical grid only, cone membership by unit-vector dot product with `−1e-12` tolerance. Query and table values come from the distribution, never from a drawn polyline or `interp1`. |
| I8 | **Display invariance:** toggling elevation θ / signed φ changes zero numbers in `Pattern, Geometry, Cols, Base, Coverage`; cut-value controls follow the display convention (F63). |
| I9 | **Partial-sphere and unit honesty:** efficiency and F/B are `n/a` unless `Geometry.IsFullSphere`; efficiency, EIRP, PFD, E_RMS exist only for `Meta.Unit == "dBi"`; every level label carries `Meta.UnitLabel`. `Meta.Unit` is a static property of the format (§16-4). |
| I10 | **Circular decomposition** lives in one function (`pol_circular`, A.4) with `E_R = (Eθ + jEφ)/√2`, `E_L = (Eθ − jEφ)/√2` — the IEEE right-hand component under `e^{+jωt}` (B.5) — and one fixture that fails if it drifts. |
| I11 | **Widgets:** read only in `readConfig`/`readCoverageConfig`; written only in `apply*`/renderers. No `.UserData` on widgets. No `findall/findobj`. UI handles stay declared properties (App Designer style, §16-7). |
| I12 | **Graphics are retained:** each view owns its handles in `Gfx`; `cla` only when grid size changes; render only the visible full-pattern tab. |
| I13 | **Build-then-commit:** every `update` stage computes into locals and assigns the registry entry in one final step; cancel or error leaves the previous state fully intact (F61). |
| I14 | **One pattern registry.** `app.Pats(k)` holds `{Key, Name, Path, Source, Pattern, Geometry, Base, Dist}`; the Main tab is `app.Pats(app.Main)`; coverage tree nodes store `k`. No second copy, no sync function. |
| I15 | **One file, no toolboxes**, R2023b baseline; every widget of M7 exists with the same property name, parent, row/column and defaults (verified by the `uiInventory` gate row). |

---

## 4. Architecture

### 4.1 M7 dataflow today — hazards marked

```
FILE → readPattern    ICOMP≠2 read as θ/φ ⚠F16 · UAN header ignored ⚠F18 · FFE blocks merged ⚠F19
       │              raw fields as dBi ⚠F20 · rmmissing ⚠F21 · span/">100" heuristics ⚠F22 F23 · cov detector ⚠F24
       │              Excel summary: 164 lines → one unused flag ⚠F66
       → rawTbl + blocks{} → normalizePattern (rounds FIELDS ⚠F03 · elevation heuristic ⚠F25 · seam always ⚠F64) → stdTbl
       └─ refresh
          ├─ calcPattern(stdTbl) → patTbl (discarded when 1° follows ⚠F09)
          ├─ applyStep → integer filter ⚠F06 | resample Re/Im 'nearest' to full sphere ⚠F04 F05 | dB linear on regular grids ⚠F59 → calcPattern → viewBaseTbl
          └─ applyAngularSpan → copy 17 cols, rewrite θ/φ, sortrows → viewTbl (+viewRevision ⚠F35)
             ├─ detectOrientation(viewTbl, comp ⚠F12) → solidWeights(display θ ⚠F02) → viewSolidAngle
             ├─ resolvePeak(prctile ⚠F01) → POB; calcMetrics(component peak ⚠F12, display θ ⚠F02, spikes ∫-only ⚠F07)
             ├─ PLF: NaN → linear ⚠F08 · pol label sphere-mean ⚠F14
             ├─ 5× cla+surf ⚠F41 · new menus ⚠F42 · colorbar/triad ⚠F43 · uitable ← 65k×17 ⚠F40 · cutData ×3 ⚠F45
             ├─ EHplane → onCutChanged → drawSpatial3D → drawPattern3D ×2, then renderAllFullPatterns ×5 ⚠F60
             ├─ gain-only cut = column 3 regardless of component ⚠F58
             └─ Coverage: node ← viewTbl ×2 ⚠F33 · N×T logical→double 261 MB ⚠F10 · key includes thresholds ⚠F10
                          presets widen ⚠F36 · dead range state ⚠F62 · getter writes a spinner ⚠F67 · dead node fields ⚠F68
```

### 4.2 M8 dataflow — destination

```
FILE ─► io_read(path, fmt) ─► Source { Raw(table, Input tab), Blocks{f} (nθ×nφ×4 | nθ×nφ×nC), Theta, Phi, Freqs,
                                       Meta{Format, Unit, UnitLabel, ThetaConvention(+how), AxisOrder(+how), IsGainOnly,
                                            ColNames, SynthesizedRevolution, PhiClosedInSource, Notes} }
        ▼
pat_build(Source, f)        ─► Pattern { Theta[nθ], Phi[nφ], dTheta, dPhi, Eth, Eph (complex nθ×nφ) | G.(name) (nθ×nφ),
        │                                IsGainOnly, Freq, Revision, Meta }          asserts I1 once (uniform, regular)
        ▼  optional pat_resample(Pattern, step) → Revision++ (I6)
geo_build(Pattern)          ─► Geometry { wTheta[nθ], dPhi, sinT, cosT, cosP, sinP, PhiPeriodic, IsFullSphere, Omega }
        ▼
Cols (struct array, Const)  ─► col(app, k, name)  memoised nθ×nφ per (Revision, key(name))   (I3: computed at L = 0)
        │                      Base facts once per Revision: Peak (total), Pol{pairs,label}, Boresight, Planes{E,H}, Metrics0
        ▼
app.Pats(k) = { Key, Name, Path, Source, Pattern, Geometry, Base, Dist }      ◄── ONE entry per loaded file (I14)
        │        Main tab reads Pats(app.Main); a coverage tree node stores k
        ▼
View = readConfig()   component, cut, span, ranges, params{L, Rx, Pt, R}, freqIndex, stepChoice, traces — never copies Pattern
Map  = geo_displayMap(Geometry, View)  { ColIdx, ThetaAxis, PhiAxis, ThetaDir, labels, ticks }
        ┌──────────┬───────────┬───────────┬──────────────┬───────────┬───────────┐
        ▼          ▼           ▼           ▼              ▼           ▼           ▼
      PLOTS      CUTS       METRICS     COVERAGE        TABLES     EXPORT     METADATA
   col+L       slices      Metrics0+L  cov_dist(col)   lazy, mask  lazy       conventions,
   (:,ColIdx)  +L                      eval(T−L)                              unit, decisions
```

**Dependency graph** (kept as the comment block above `update`):

```
SOURCE ─► PATTERN(Rev) ─► GEOMETRY ─► COLS(Rev, name) ─► BASE(Rev)          all stored in Pats(k)
                                          │                 │
                                    COV DIST(Rev,name)   METRICS(+L)     PLOTS/CUTS/TABLES (+L, Map)
VIEW ─► MAP ─► ColIdx / axes / ticks / labels / cut-value domain        (touches nothing above)
PARAMS ─► L (offset), Rx (PLF column only), Pt/R (link columns only)
```

If a function needs something not on a path from its inputs, it is reaching into the app; that line does not belong in M8.

### 4.3 Layer contracts

| Layer | Object | Writer | Readers | Forbidden |
|---|---|---|---|---|
| Source | `Pats(k).Source` | `io_read` | `update("source")`, Input tab | math, renderers |
| Pattern | `Pats(k).Pattern` | `pat_build`, `pat_resample` (committed by `update`) | all below | widget values, `cla` |
| Geometry | `Pats(k).Geometry` | `geo_build` (on Revision change) | cols, metrics, coverage, plots | storing an `nθ×nφ` ΔΩ matrix |
| Cols | `Pats(k).ColCache` | `col(app,k,name)` | plots, cuts, tables, export, coverage | any parameter other than Rx for `plf`, Pt/R for `link` |
| Base | `Pats(k).Base` | `pat_baseFacts` (once per Revision) | metrics, planes, status, coverage orientation | loss, component |
| Dist | `Pats(k).Dist.(col).(region)` | `cov_dist` | coverage compute/query/table | thresholds, loss |
| View / Map | `app.View`, `app.Map` | `readConfig`, `geo_displayMap` | orchestration, renderers | math kernels |
| Conventions | `Const.*`, `Meta.*` | file section B / readers | everything | literals `sqrt(2)`, `1i*`, `cosd(180)`, `"dBi"`, `-100` anywhere else |
| Coverage node | `NodeData` | coverage `apply*` | tree, curves | pattern copies; a pattern node holds only `k`; a job holds `{id, k, col, region, T, L, line}` |
| Graphics | `app.Gfx` | renderers | renderers | `findall`/`findobj`/Tag search |
| Layout | `createComponents` | `place`, `labelled`, `patternTab` | — | `Layout.Row =` outside `place` |

Validity is one comparison per layer (`Revision`, `key`, `Key`). No flag families, no widget `UserData`.

### 4.4 Why this is shorter

| Concept | M7 | M8 | What vanishes |
|---|---|---|---|
| Physical vs display angles | `viewTbl` + `physicalTheta` ×13 | `Pattern` is polar; `Map` is a permutation + labels | `applyAngularSpan`, `physicalTheta`, seam duplication, F02/F35/F63 |
| Pattern identity | 6 tables (+2 per node) | `Pats(k)` + memoised `Cols` | five properties and every assignment to them |
| Main ↔ Coverage | node copies + `syncCoverageNodeFromView`, `syncCoveragePattern`, `covPatternTarget`, `covFindByPath` | node stores `k`; `Pats` is the single source | four functions, `orientationComponent`, `componentBounds`, `sourceTable`, `viewRevision` on nodes (F33, F34, F68) |
| Step / seam / ΔΩ | `gridStep` ×17, `solidWeights` ×6, `gridCache` | `Pattern.dTheta/dPhi`, `Geometry.wTheta/dPhi` | all of them, plus `emptyGridCache` (F69) |
| Processing | `calcPattern` (17 eager columns) + `resolvePeak` ×10 | `Cols(k).fn` on demand + `Base` once | `calcPattern`, `chooseGain`, `componentMap`, `isARComponent`, `isGainDBColumn`, `HiddenOutputColumns`, `robustRange`, constant threading (F65) |
| Loss | `FieldScale` through the whole pipeline | `+L` at point of use | the reprocess on loss change |
| Cut geometry | `cutGeometry` ≡ `calcCutGeometry`; `cutData` ×3 per change; `cutCols` | `geo_cut` (slices) once per change | one twin, the status side effect, two extractions, F58 |
| Coverage | `coverageCCDF` N×T + key with thresholds + `interp1` table + 2 query interpolations | `cov_dist` (once) + `cov_eval` + `cov_inverse` | 5 helpers, 261 MB transient, plateau ambiguity |
| Circular split | 4 inline copies | `pol_circular` (+ inverse) | 3 copies |
| Resampling | regular + scattered paths, `'nearest'` extrapolation, integer filter | decimate-or-bilinear on the uniform grid | `interpolateScattered`, `scatteredInterpolant`, `Extrapolation` option, the 0.3° trap (F06) |
| Readers | 5 near-identical six-column cases + 6 generic variants; 164-line Excel summary | one `io_fields(M, spec)` + a 9-row spec table; one `xl_lookup` for the frequency cell | ≈ 120 + ≈ 150 lines (F66) |
| Range UI | `onRangeUIChanged` scopes + coverage twins + startup arrays + 9-field state (4 dead) | one descriptor-driven `applyRange(group, limits)` + `Range.Auto` per group | `syncCoverageXRange`, `setCoverageRange`, `coverageRangeState`, `markCoverageThresholdUserEdit` (F62) |
| Annotations | ≈ 250 lines over 6 functions | handles created once, `Visible` toggled | the whole layer |
| Orchestration | 14 functions (`refresh … syncCoverageNodeFromView`) | `update(scope)` | ≈ 500 lines of bodies |
| Layout | 622 lines, 190 `Layout.*` statements | `place()` — one line per widget | ≈ 320 lines |

---

## 5. Data model

### 5.1 Schemas (factory functions in file section B)

```matlab
Source   = struct('Raw',table,'Blocks',{{}},'Theta',[],'Phi',[],'Freqs',NaN,'Meta',meta)
Meta     = struct('Format',"",'Unit',"dBi"|"dB",'UnitLabel',"dBi"|"dB (rel. field)",'ThetaConvention',"polar"|"elevation", ...
                  'ThetaDecidedBy',"format"|"header"|"range",'AxisOrder',"theta-phi"|"phi-theta",'AxisDecidedBy',"format"|"header"|"span", ...
                  'IsGainOnly',false,'ColNames',strings(0),'SynthesizedRevolution',false,'PhiClosedInSource',false,'Notes',strings(0))
Pattern  = struct('Theta',[],'Phi',[],'dTheta',NaN,'dPhi',NaN,'Eth',[],'Eph',[],'G',struct(),'IsGainOnly',false, ...
                  'Freq',NaN,'Revision',uint64(0),'Meta',meta)
Geometry = struct('wTheta',[],'dPhi',NaN,'sinT',[],'cosT',[],'cosP',[],'sinP',[],'PhiPeriodic',false,'IsFullSphere',false,'Omega',NaN)
Base     = struct('Peak',peak,'Pol',struct('Label',"",'Pairs',pairs,'ARatPeak_dB',NaN),'Boresight',1, ...
                  'Planes',struct('E',cutSpec,'H',cutSpec),'Metrics0',struct(),'Revision',uint64(0))
PatEntry = struct('Key',"",'Name',"",'Path',"",'Source',src,'Pattern',pat,'Geometry',geo,'Base',base, ...
                  'ColCache',struct(),'Dist',struct())                      % app.Pats(k); app.Main = index of the Main-tab entry
View     = struct('Component',"",'CutType',"Theta"|"Phi",'CutValue',0,'Basis',"Linear"|"Circular",'Traces',[t r l], ...
                  'SignedPhi',false,'Elevation',false,'CStep',5,'Params',struct('L',0,'RxMode',"Auto",'RxAR_dB',6,'Pt_dBW',0,'R_m',1), ...
                  'FreqIndex',1,'StepChoice',"native"|"1deg",'Filter',logical(0),'BasisAuto',true)
Map      = struct('ColIdx',[],'ThetaAxis',[],'PhiAxis',[],'ThetaDir',"reverse"|"normal",'ThetaLabel',"",'PhiTicks',[],'Key',"")
Range    = struct('full',[lo hi],'cut',[lo hi],'cov',[lo hi],'covX',[lo hi],'Auto',struct('full',true,'cut',true,'cov',true,'covX',true))
Gfx      = struct('Full',struct('Axes',{},'Surface',{},'Colorbar',{},'Triad',{},'Overlay',{},'Marker',{},'Tip',{},'Key',{}), ...
                  'Cut',struct('Polar',[],'Rect',[],'Regions',[],'Bounds',[],'Key',""),'Menu',gobjects(0),'Timer',[])
NodeData = struct('kind',"pattern"|"results"|"job", ...)
           pattern: k (index into Pats), Name
           results: Name, Path, T (thresholds), Curves (matrix)         % loaded CSV; no Pattern
           job:     id, k | results ref, col, region{tag, thC, phC, alpha}, T, L, line
```

### 5.2 Column table — `Const.Cols` (registry **and** materialiser)

```matlab
%  name                   label            kind    unit     lossAdd hidden  fn(P, G, prm) → nθ×nφ (levels at L = 0)
Cols = colDefs({ ...
 'E_Total_dB'            'Total Gain'     'gain'  'level'  true   false  @(P,~,~)   db10(abs(P.Eth).^2 + abs(P.Eph).^2)
 'E_TH_dB'               'Etheta Gain'    'gain'  'level'  true   true   @(P,~,~)   db20(abs(P.Eth))
 'E_PH_dB'               'Ephi Gain'      'gain'  'level'  true   true   @(P,~,~)   db20(abs(P.Eph))
 'E_RCP_dB'              'RHCP Gain'      'gain'  'level'  true   false  @(P,~,~)   db20(abs(pol_circular(P.Eth,P.Eph,1)))
 'E_LCP_dB'              'LHCP Gain'      'gain'  'level'  true   false  @(P,~,~)   db20(abs(pol_circular(P.Eth,P.Eph,2)))
 'AR_dB'                 'Axial Ratio'    'ar'    'dB'     false  false  @(P,~,~)   pol_signedAR(P.Eth,P.Eph)
 'PLF_dB'                'PLF'            'plf'   'dB'     false  false  @(P,G,prm) pol_plf(colAR(P), prm.RxMode, prm.RxAR_dB, pairs(P))
 'Gain_PolCorrected_dB'  'Polarized Gain' 'gain'  'level'  true   false  @(P,G,prm) colTotal(P) + colPLF(P,prm)
 'E_TH_Phase'            'Etheta Phase'   'phase' 'deg'    false  true   @(P,~,~)   rad2deg(angle(P.Eth))
 'E_PH_Phase'            'Ephi Phase'     'phase' 'deg'    false  true   @(P,~,~)   rad2deg(angle(P.Eph))
 'E_RCP_Phase'           'RHCP Phase'     'phase' 'deg'    false  true   @(P,~,~)   rad2deg(angle(pol_circular(P.Eth,P.Eph,1)))
 'E_LCP_Phase'           'LHCP Phase'     'phase' 'deg'    false  true   @(P,~,~)   rad2deg(angle(pol_circular(P.Eth,P.Eph,2)))
 'EIRP_dBW'              'EIRP'           'link'  'dBW'    true   true   @(P,G,prm) prm.Pt_dBW + colTotal(P)
 'PFD_Wm2'               'PFD'            'link'  'W/m^2'  false  true   @(P,G,prm) 10.^((prm.Pt_dBW + colTotal(P) + prm.L)/10) ./ (4*pi*prm.R_m^2)
 'E_RMS_Vm'              'E_RMS'          'link'  'V/m'    false  true   @(P,G,prm) sqrt(30*10.^((prm.Pt_dBW + colTotal(P) + prm.L)/10)) ./ prm.R_m
});
```

- **Memo key** per column: `gain/ar/phase` → `Revision`; `plf`, `Gain_PolCorrected_dB` → `Revision|RxMode|RxAR`; `link` → `Revision|Pt|R|L`. `col(app,k,name)` returns the cached matrix or evaluates `fn` once.
- **Loss** (`lossAdd`): `+L` applied by the consumer. `PFD`/`E_RMS` take `L` inside `fn` because they are non-linear in it.
- **Gain-only sources:** rows are synthesised from `Meta.ColNames` with `kind = util_colKind(name)` (`gain|directivity|eirp|…db` → `gain`, `ar|axial` → `ar`, `phase|deg` → `phase`, else `other`; `other` never receives loss and is never the peak column). The peak column is the first `gain` row (F26). **Cuts and coverage use the selected column** (F58, §16-8).
- One array drives: component dropdown items (`kind ∈ {gain, ar, plf}` ∩ available), Results-filter defaults (`hidden`), colour theme (`kind == "ar"` → signed map, `Const.ARLimits = [−30 30]`), cut trace pairs, coverage component list, parameter-control visibility (`plf` → Rx controls, `link` → Pt/R controls, `lossAdd` present → Loss), unit labels, and the resampling domain (`gain` → linear power).

### 5.3 View table — `Const.Views` (five full-pattern tabs behind one renderer)

```matlab
%  name        axesProp             rangeProp       kind        camera
Views = {'contour'  'Single_Axes_Ctr'   'Range_Ctr'    'pcolor'    []
         'circular' 'Single_paxPattern' 'Range_Cir'    'fisheye'   []
         'sphere3D' 'Single_Axes_3dSph' 'Range_3dSph'  'sphere'    [135 25]
         'polar3D'  'Single_Axes_3dPol' 'Range_3dPol'  'polar'     [135 25]
         'rect3D'   'Single_Axes_3dRect' 'Range_3dRect' 'rect'     [-35 35]};
```

`renderFull(k)` reads this row; the only per-kind code is the coordinate expression (§8).

### 5.4 Range groups — `Const.RangeGroups`

```matlab
%  group   sliders (props)                                   minSpinners…  maxSpinners…      hard      minGap
   full    {Range_Ctr Range_Cir Range_3dSph Range_3dPol Range_3dRect}  (5)  (5)   [-250 100]  1
   cut     {Range_Cut}                                         {Range_Cut_Min} {Range_Cut_Max}  [-250 100]  1
   cov     {}                                                  {Cov_Spinner_ThreshMin} {Cov_Spinner_ThreshMax} [-250 100] 0.1
   covX    {Cov_Spinner_XRange}                                {Cov_Spinner_XMin} {Cov_Spinner_XMax} [-250 100] 0.1
```

`applyRange(group, limits)` is the only writer of these widgets (§7.4).

### 5.5 Pattern registry — `app.Pats`

- `patKey(path, stepChoice, freqIndex)` identifies an entry; `update("source")` replaces the entry with the same `Path` (build-then-commit, I13) and sets `app.Main`.
- The Coverage "Main → Coverage" button adds a tree node with `k = app.Main` (or selects the existing one). A file loaded on the Coverage tab creates an entry with `Pats(k).Source` and the same `pat_build → geo_build → pat_baseFacts` chain — **one code path for both tabs**, no frozen parameters (F33).
- A `step`/`freq` change on the Main tab rewrites `Pats(app.Main)` in place; coverage nodes that reference it follow automatically; their `Dist` cache is keyed by `Revision`, so stale distributions are simply missed and recomputed on the next run.
- `Cov_Button_Reset` deletes coverage nodes and every `Pats` entry not referenced by the Main tab.

---

## 6. Pipelines

### 6.1 Import — `io_read(path, textFormat)`

A `switch` on extension dispatches to small readers. The five six-column formats and the six generic E-field variants share one converter, `io_fields(M, spec)` (A.10), driven by a spec row `{thetaCol, phiCol, encoding ∈ reim|magphase, basis ∈ linear|circular, order ∈ [1 2]|[2 1]}`. Every reader returns `Source`; every decision it makes is recorded in `Meta` and shown in Metadata.

| Format | Spec / convention (unchanged) | Unit | Corrections |
|---|---|---|---|
| UAN / FZ (XGTD) | `θ φ \| magphase linear`, cols `[3 5 4 6]` | `dBi` | Read the `begin_<parameters> … end_<parameters>` block. **Assert** `magnitude dB`, `phase degrees`, `polarization theta_phi` when present; otherwise `APAT:UnsupportedUAN` naming the keyword (F18). Export writes `maximum_gain` = peak of **total** gain + L (F27). |
| OUT (GRASP) | `θ φ \| reim circular` | `dB` | θ/φ from `pol_fromCircular` (one place). |
| CUT (GRASP) | blocks; `ICUT`, `ICOMP` | `dB` | `ICOMP == 1` → θ/φ; `ICOMP == 2` → circular via inverse; **any other `ICOMP` → `APAT:UnsupportedICOMP`** (F16). Single cut → body of revolution at the M7 10° φ step, `Meta.SynthesizedRevolution = true`, one Metadata row (F17, §16-5). Negative-θ fold stays in this reader. |
| FFS (CST) | `φ θ \| reim linear` | `dB` | none |
| FFE (FEKO) | `θ φ \| reim linear` (+ ignored columns) | `dB` | **Split blocks** on `#Frequency:` lines; one `Blocks{f}` per frequency; block dropdown reused (F19). Extra FEKO gain columns stay ignored (§16-4). |
| FFD (HFSS) | header triples; `reim linear` | `dB` | unchanged; blocks per separator row. |
| Excel 1/2/3 | fixed component sheets | `dBi` | matrix logic unchanged; the summary sheet is read for **one cell only** — `Pattern Simulation Freq (MHz)` → `Source.Freqs` (shown in Metadata, which M7 never did) via `xl_lookup(C, label, col)`; the 164-line summary parser is deleted (F66). |
| Generic text | header names first (`theta\|th\|el\|elev`, `phi\|ph\|az`), else span rule, `AxisDecidedBy` recorded (F22); mag/phase layout by header names, else the range rule **with agreement of both columns**, else error (F23); coverage only by keyword or by the strict no-header rule (F24); `rmmissing` only on θ/φ and the used value columns (F21); header `el/elev` → elevation with `ThetaDecidedBy = "header"` (F25). | `dBi` (gain), `dB` (fields) | |

`Meta.Unit` is a static property of the format (a raw far field is never called dBi); efficiency, EIRP, PFD, E_RMS are gated on it (F20, I9).

### 6.2 Canonicalise — `pat_build(Source, f)`

1. θ-convention: if `Meta.ThetaConvention == "elevation"`, `θ = 90 − el`. Fold `θ < 0 → (−θ, φ+180)`; `θ > 180 → (360−θ, φ+180)`. Once.
2. `φ = mod(φ, 360)`; snap θ, φ to `Const.AngleDecimals = 5` (**angles only**, F03).
3. Dedupe directions (`unique([φ θ],'rows','first')`); a supplied φ = 360 column folds into φ = 0 with `PhiClosedInSource = true`.
4. Axes: `Theta = unique(θ)`, `Phi = unique(φ)`. **Uniformity (I1):** `dTheta = (Theta(end)−Theta(1))/(nθ−1)`, assert `max|diff(Theta) − dTheta| ≤ Const.UniformTolDeg = 1e-6`; likewise φ. **Regularity:** `nθ·nφ == N`. Either failure → `APAT:NonUniformGrid` with the offending axis and gap in the message (§16-1). No regularisation path exists.
5. `PhiPeriodic = |nφ·dPhi − 360| < 1e-9` — a fact, not an assumption (F64).
6. Reshape grid-major: `Eth = reshape(…, nθ, nφ)` — or `G.(name)` for gain-only. **No seam column.**

### 6.3 Resample — `pat_resample(Pattern, stepDeg)`

**Domain:** `θq = Theta(1):step:Theta(end)`, `φq = Phi(1):step:Phi(end)` (closure through `[Phi, Phi(1)+360]` when periodic). Never outside the source hull (F05).

**Decimation** (I6): per axis, `k = step/native`; if `|k − round(k)| < 1e-9` select every `k`-th sample — bit-exact (F06). Both axes exact ⇒ no interpolation at all.

**Interpolation — one kernel, bilinear on the φ-closed uniform grid (F04, F59):**

```matlab
function Xq = pat_interp(X, kind, interp)        % interp = @(A) interp2(phiC, theta, A, phiQ, thetaQ, 'linear')
switch kind
  case "field",  mag = abs(X); z = X ./ max(mag, realmin);            % complex component
                 Xq = sqrt(max(interp(mag.^2),0)) .* unit(interp(z));  % linear POWER + circular-mean phase (B.4)
  case "gain",   Xq = db10(max(interp(10.^(X/10)), realmin));         % linear power in, dB out
  otherwise,     Xq = interp(X);                                       % phase/other: linear
end
```

`Revision++`; blocks are resampled lazily per `(FreqIndex, step)`. There is no scattered path and no extrapolation option.

### 6.4 Geometry — `geo_build(Pattern)` (A.2)

`wTheta(i) = cos θᵢ⁻ − cos θᵢ⁺`, `θᵢ∓ = clamp(θᵢ ∓ dθ/2, 0, 180)`; `dPhi = deg2rad(P.dPhi)`; `Omega = Σ wTheta · nφ · dPhi`; `IsFullSphere = PhiPeriodic && θ₁⁻ == 0 && θₙ⁺ == 180`. Integrals everywhere: `geo_integrate(G, X) = G.dPhi * (G.wTheta.' * sum(X, 2, 'omitnan'))`. Unit vectors formed on demand, never stored. Hemisphere: Metadata shows "Sampled solid angle: 2.01π sr (50.2 %)"; efficiency and F/B `n/a` (I9).

### 6.5 Base facts — `pat_baseFacts(P, G)` (once per Revision, at L = 0)

- `Peak = met_peak(colTotal)` (I5, A.3).
- `Pol`: `AR_p = AR_dB(peak)`. **Pairs** (co/cross order and Auto-Rx sense) from Ω-weighted mean power of each component over the **main-beam region** `colTotal ≥ Peak − 10 dB` (F14) — three lines with `geo_integrate`. **Label:** `|AR_p| ≤ Const.CircularAR_dB = 3` → `"Circular (RHCP|LHCP)"` by sign of `AR_p`; else `"Linear (Vertical)"` if the θ-component leads the pair, `"Linear (Horizontal)"` otherwise — the M7 wording, decided on the main beam instead of the whole sphere.
- `Boresight = met_orientation(colTotal, G)`: principal axis whose 45° cone holds the most Ω-weighted power — from **physical** unit vectors (F02), on **total gain** (F12).
- `Planes` (§16-6, A.7): the **principal-axis rule of M7** (634–642), unchanged: E = θ-cut at the boresight axis φ; H = θ-cut at 90° for a ±Z boresight, φ-cut at θ = 90° for an equatorial boresight. Expressed in canonical angles; the display convention is applied by `Map` when the E/H switch sets the cut controls (this removes the `thetaSpanMode` argument M7 threads into `calcMetrics`).
- `Metrics0 = met_metrics(P, G, Peak, Planes)` at L = 0 (§6.7).

### 6.6 Parameters

`View.Params = {L, RxMode, RxAR_dB, Pt_dBW, R_m}` from `readConfig`. **No pipeline stage.** `L` is added by consumers (I3); Rx settings invalidate only the `plf` memo key; Pt/R only the `link` keys. Metadata's peak/EIRP rows are `Metrics0.* + L`; efficiency is `Metrics0.Eta0 · 10^(L/10)`.

### 6.7 Metrics — `met_*`

- **`met_peak`** (A.3): 4-neighbour maximum with φ-wrap; pole rows compare against the adjacent ring. Returns `mask, value, index, rawValue, rawIndex, wasAdjusted, spikeCount`.
- **`met_hpbw`**: M7's `calcHPBW` (wrap-aware linear crossing), unchanged, on any cut struct.
- **`met_metrics`** (F07, F12, I9): always on **total gain**, never on the selected component.

```matlab
keep = ~Peak.mask & isfinite(Gt);                                   % spikes removed from BOTH numerator and Ω
IG   = geo_integrate(G, 10.^(Gt/10) .* keep);  Ok = geo_integrate(G, double(keep));
D_peak_dB = 10*log10( 10^(Peak.value/10) * Ok / IG );               % scale-free (valid for dBi and relative field)
Eta0_pct  = 100 * IG / Ok;                                          % only if IsFullSphere && Unit == "dBi", else NaN; shown ×10^(L/10)
FB_dB     = Peak.value - Gt(antipodeIndex);                         % only if IsFullSphere; nearest grid sample to −r̂_peak
HPBW_E/H  = met_hpbw(geo_cut(Planes.E)), met_hpbw(geo_cut(Planes.H))
```

- **`pol_signedAR`** (A.5): `AR_dB = min(20·log10 AR, 250)·sign(|E_R|−|E_L|)`; **exactly equal circular components → `Const.LinearAR_dB = −100`**, the M7 floor (4769–4771, §16-2). One mask `isLinear = |d| ≤ eps(r+l)` is shared with PLF.
- **`pol_plf`** (A.6): finite-AR samples only; `isLinear` samples take the explicit `r_a → ∞` limit (M7's `1e12` branch, made exact); `PLF_dB(NaN field) = NaN` (F08). `Const.PLFTiltCos = −1` documented in one Metadata "Conventions" row.

### 6.8 Cuts — `geo_cut(P, colName, type, value)`

Grid-native slices, exact, zero arithmetic:
- **φ-cut** (fixed θ): `i = nearest(Theta, v)`; `angle = Phi`; `data = C(i,:).'`; closed for display by `Map.ColIdx`.
- **θ-cut** (fixed φ): `j = nearest(Phi, mod(v,360))`, `j2 = nearest(Phi, mod(Phi(j)+180, 360))`; `angle = [Theta; 360 − Theta(end−1:−1:1)]`; `data = [C(:,j); C(end−1:−1:1, j2)]`.

Returns `struct(angle, thetaDeg, phiDeg, data.(c), fixedAngle, symbol, snapped)`; pure; cached per `(Revision, type, value, cols)`. **One extract** feeds the polar cut, the rectangular cut and both 3-D overlays (F45). The trace list is `Total + pair(Basis)` for fields and **`View.Component` only** for gain-only (F58, §16-8). Snapping is reported as a *transient* status (F32). Cut-value `Limits/Step/Value` are set once from `Pattern` in `applyChoices` and expressed in the **display** convention via `Map` (F37, F63). `+L` applied at render.

### 6.9 Coverage — `cov_*` (I7, A.1)

**Definition (in the kernel header):** `Coverage(T) = 100 · Ω{G > T} / Ω_R,  Ω{G > T} = Σ_{(i,j)∈R, G(i,j)>T} wθ(i)·Δφ,  Ω_R = Σ_{(i,j)∈R, G finite} wθ(i)·Δφ`.

- **Distribution once, evaluate anywhere:** `d = cov_dist(C, G, mask)` sorts the region's finite gains with weights and stores `(g_k ascending, ω_k, S_k = Σ_{m≥k} ω_m, Ω_R)`. `cov_eval(d, T) = 100·S(k_T)/Ω_R`, `k_T = first k : g_k > T`. `cov_inverse(d, c)` = the exact level `sup{T : Coverage(T) ≥ c}`. Memory `O(N)`; one sort per (entry, column, region). The literal `N×T` form is kept as `cov_eval_reference` for the self-test only.
- **Cache:** `Pats(k).Dist.(col).(regionTag)` with `Revision` — thresholds are **not** in the key (F10). Loss by shift: `cov_eval(d, T − L)`; non-additive columns include the Rx key.
- **Region:** `cov_coneMask(G, θc, φc, α)`; spherical = all. Empty region → `Coverage ≡ 0`, status says so.
- **Orientation for conical jobs:** `Auto` resolves to `Pats(k).Base.Boresight` (total gain, once per Revision — no per-click recomputation, F34); explicit selections are used as entered. The job records the actual cone centre; the never-updated `orientationMode` field of M7 (2300, 2359) is gone (F68).
- **Thresholds:** `T = tMin + (0:n).'·step` by counting (F11), read by `readCoverageConfig` **without writing any widget** (F67).
- **Presets:** threshold window and X-range set from `Pats(k).Base.Peak` of the selected column when `Range.Auto.cov/covX`; never widen on their own; user edit clears `Auto` (F36, F62).
- **Table:** union of checked jobs' thresholds, each column `cov_eval(d_j, T_union − L_j)` — exact, no `interp1`. Loaded-results jobs (CSV) are evaluated by nearest-lower sample of their own curve, which is exact on their own grid.
- **Queries:** value from `cov_eval`/`cov_inverse`; datatip at the exact coordinate; projection lines from `ax.XLim(1)`/`ax.YLim(1)` (F50).
- **Labels:** one job label (`R<id> <region> · <column> · L=<L> dB`) and one table column name derived from it — replacing M7's five label variants (`tag, tagFull, tableTag, displayTag, label`).

### 6.10 Export — lazy, canonical

- **Results:** built on demand from `Cols` (checked columns, `+L` where `lossAdd`), angles in the *display* convention via `Map` — from data, not from the `uitable` (2142).
- **Cut:** the current `geo_cut` struct.
- **UAN:** from `Pattern` at `L` (fields scaled by `10^(L/20)`), canonical φ ∈ [0,360) + closing column as XGTD expects, `maximum_gain` = total-gain peak + L (F27).

---

## 7. Orchestration

### 7.1 `readConfig` / `readCoverageConfig`

The only functions that read widget values. They return `View` (§5.1) and a coverage counterpart (`component, thresholds, region, query`). Step choice, cut-basis auto-selection (`BasisAuto`) and the output-filter mask live in `View` (F31), initialised from the source on `update("source")`. Neither function writes a widget (F67).

### 7.2 `update(app, scope)` — the dispatcher

| User action | scope | Recompute | Render |
|---|---|---|---|
| Load / Process / text format | `source` | `io_read → pat_build → (resample if 1°) → geo_build → pat_baseFacts` → **commit `Pats(k)`** | `applyChoices`, `applyVisibility`, metadata, presets (if `Auto`), visible full tab, cuts, tables if visible |
| Frequency block (FFD/FFE) | `freq` | `pat_build(block) → geo_build (if axes changed) → baseFacts` → commit | as `source` minus choices |
| Native ↔ 1° | `step` | `pat_resample → geo_build → baseFacts` → commit | as `freq` |
| Loss | `loss` | **nothing** | `CData = col + L` on visible tab, cut `YData`, metadata rows, tables if visible |
| Rx / Pt / R | `params` | `plf`/`link` memo keys only | as `loss` if the visible component depends on them |
| Component | `component` | `col(name)` (memoised) | `CData` visible tab (+ radius on polar-3D, `ZData` rect-3D), cut traces for gain-only, POB, titles, colorbar theme |
| Elevation / signed φ | `span` | **nothing numeric**; `geo_displayMap` | `CData(:,ColIdx)`, axes vectors, ticks, labels, cut `XData` remap, cut-value domain, POB re-index |
| Cut controls / E-H / basis / traces | `cut` | `geo_cut` (cached) | cut lines + both overlays from one extract, HPBW |
| Ranges / colour step | `range` | nothing | `clim/zlim/RLim` + ticks of the visible tab; other tabs dirty |
| POB / HPBW toggles / tab change | `annot` | nothing | `Visible` of registry handles; **stale tab → render on selection** |
| 3-D view | `camera` | nothing | `view/camup` |
| Coverage load / Main→Coverage | `covSource` | `io_read → … → baseFacts` into a new `Pats` entry (or select existing) | tree node, presets |
| Coverage compute | `covRun` | `cov_dist` (if key miss) → `cov_eval(T − L)` | curve, table, legend, status |
| Coverage thresholds / query / check / select | `covQuery` | `cov_eval` / `cov_inverse` | line `YData`/`Visible`, table, query tips, highlight |

Ladder: `source ⊃ freq ⊃ step ⊃ {loss, params, component} ⊃ {span, cut, range, annot, camera}`. `update` runs the stages at or below the requested rung, marks non-visible full-pattern tabs dirty, renders the visible one, then **one** `drawnow limitrate`. Overlays are drawn by `renderFull` only (F60).

Deleted as bodies: `refresh`, `updateViewResults`, `refreshAngularView`, `applyStep`, `applyAngularSpan`, `stepChanged`, `onComponentChanged`, `renderAllFullPatterns`, `drawSpatial3D`, `initRanges`, `selectBlock`, `activateSource`, `buildPatternData`, `syncCoveragePattern`, `syncCoverageNodeFromView`, `covPatternTarget`, `covFindByPath`, `gridComp`, `gridGeom`, `invalidateDerived`, `emptyGridCache`, `physicalTheta`, `cutGeometry`, `cutData`, `cutCols`, `componentMap`, `preferredComponent`, `updateComponentItems`, `updateSelectedComponentPeak`, `computeMetrics`, `planeSettings`, `updateCutControl`, `gainDisplayRange`, `coverageDisplayRange`, `robustRange`, `onRangeUIChanged`, `setCoverageRange`, `syncCoverageXRange`, `markCoverageThresholdUserEdit`, `clearCoverageSync`, `coverageCacheKey`, `covThresholds`, `coverageInterpolationLocation`, `coverageQueryPoint`, `coverageSummaryMaximum`, `coverageTableTag`, `clearAnnotations`, `refreshAnnotations`, `createPOBDataTip`, `ensureFullPatternPOBAnnotations`, `initializeFullPatternPOBRecords`, `updateFullPatternPOBVisibility`, `findRenderedPatternSurface`, `configurePlotContextMenu`, `startPerf`, `detectOrientation`, `getParam`, `readExcelSummary`, `summaryValue`, `summaryRowValue`, `summaryNumeric`, `findSummaryLabel`, `normalizeSummaryLabel`, `interpolateScattered`, `isGainDBColumn`, `validateSourceModel`.

### 7.3 `on` — guard: try/catch, cancel, busy, build-then-commit

```matlab
function on(app, scope, title)
if app.Busy, return; end                              % drops re-entrant slider storms
app.Busy = true; c = onCleanup(@() app.setBusy(false));
try
    app.update(scope); drawnow limitrate
catch err
    if err.identifier == "APAT:Cancelled", app.setStatus(app.Single_StatusBar, 'Cancelled.', true);
    else, app.showError(err, title); end               % state untouched: update commits only at its end (I13)
end
end
```

Long stages (`source`, `step`, `covSource`, `covRun`) run behind the existing cancellable `uiprogressdlg`; `checkCancelled` sits between stages, not inside kernels. Coverage load parses **inside** the guard (F49). Same-file reselect = reload (F39).

### 7.4 `applyChoices`, `applyVisibility`, `applyRange`, status, lifecycle

- `applyChoices` — the only writer of data-derived `Items/ItemsData/Limits/Step/Text`: component items (Main and Coverage) from `Cols ∩ available`, cut-value limits/step from `Pattern` via `Map` (once, F37/F63), step dropdown items, block items, trace checkbox labels.
- `applyVisibility` — the only writer of `Visible/Enable`, computed from `Meta`, `View.Component` kind and coverage state; parameter controls follow the **selected component and source kind**, not the table filter (F55).
- `applyRange(group, limits)` — one descriptor-driven controller for the four groups of §5.4: widen-then-set slider limits, spinner limits `[hard(1), hi−gap]`/`[lo+gap, hard(2)]`, then the axes (`clim/zlim/RLim/XLim`). The AR theme sets **only** `full` to `Const.ARLimits` (F38). `Range.Auto.(group)` becomes false on the first user edit; presets re-apply on `source/freq/step` only and never widen by themselves (F36).
- Status: one reusable `timer` created in `startupFcn` (F47); `setStatus(label, msg, transient)`; persistent message stored in `app.Status.(label)`, not in widget `UserData`. Status names the component ("Peak of *Axial Ratio*") and reserves "POB" for total gain (F12).
- Window title from `Const.ReleaseName` (F57). Profiling into `app.Perf` only when `getenv("APAT_PROFILE")` is set; no `assignin` (F48).
- Lifecycle: `shutdown` stops the timer, deletes the dialog and the context menu, clears `Gfx`; `delete`/`closeRequest` call it once.

---

## 8. Rendering — retained mode (I12)

```matlab
function renderFull(app, k)                                  % k = visible tab index (Const.Views row)
v = app.Const.Views(k,:); s = app.Gfx.Full(k); key = app.fullKey(k); if s.Key == key, return; end
C = app.col(app.Main, app.View.Component) + app.View.Params.L * app.colLossAdd(app.View.Component);
C = C(:, app.Map.ColIdx);
[X, Y, Z] = app.viewCoords(v.kind, C);                       % the only per-kind code: 5 short cases
if isgraphics(s.Surface) && isequal(size(s.Surface.CData), size(C))
    set(s.Surface, 'XData', X, 'YData', Y, 'ZData', Z, 'CData', C);      % in-place
else
    cla(s.Axes); s.Surface = app.newSurface(v.kind, s.Axes, X, Y, Z, C); s.Surface.ContextMenu = app.Gfx.Menu; % triad once
end
app.applyTheme(s, k); app.placeMarker(s, app.Pats(app.Main).Base.Peak.index); app.renderOverlay(s, v.kind); app.Gfx.Full(k).Key = key;
end
```

- `fullKey = strjoin([Revision, Component, L*lossAdd, RxKey (if plf), Map.Key, RangeKey, OverlayKey], "|")`.
- `update` renders only the **visible** full-pattern tab; the tab-change callback renders a stale tab on selection (F41).
- One `uicontextmenu` created at startup and assigned to every axes/surface (F42); one colorbar and one triad per axes, created with the axes (F43); POB marker + datatip per view created once and re-indexed (F56).
- **Polar-3D radius** is one function `util_polarRadius(values, limits)` used by the surface and the overlay (F44).
- **Display map** (A.8) is an exact permutation: signed φ → `perm = [j0:nφ, 1:j0−1]`, `ColIdx = [perm perm(1)]` when periodic (closing column for display only), `PhiAxis` relabelled; elevation → `ThetaAxis = 90 − Theta`, `YDir = 'normal'`. Fisheye / 3-D geometry stays physical; only tick labels change.
- **Cuts:** three lines per axes created once (`Visible` toggles), HPBW regions and bound markers reused, legends created once and relabelled; the HPBW/POB trace is named in the label when it is not Total (F46). The unreachable seam-interpolation branch of M7 (1375–1379) does not exist: the closing column comes from `Map`.
- **Tables:** pushed only when the Results tab is visible and the key changed; numeric matrix + `ColumnName` (F40).
- Every colorbar label, axis label and datatip unit is `Meta.UnitLabel` (I9). The coverage axes title shows the region and the formula.

---

## 9. Layout — declarative construction

The M7 layout is hand-written MATLAB, not App Designer output (helpers at 3015–3070 prove it). The **widget set, names, parents, rows/columns and defaults are frozen**; only the *statements* that build them change. Three helpers replace 190 `Layout.*` lines and 118 constructor blocks:

```matlab
function h = place(~, ctor, parent, row, col, varargin)          % one line per widget
h = ctor(parent, varargin{:}); h.Layout.Row = row; h.Layout.Column = col;
end
function [lbl, h] = labelled(app, parent, text, row, col, ctor, varargin)   % right-aligned label + control
lbl = app.place(@uilabel, parent, row, col, 'Text', text, 'HorizontalAlignment', 'right');
h   = app.place(ctor, parent, row, col+1, varargin{:});
end
function [tab, g, ax, sl, mn, mx] = patternTab(app, group, title, axesTitle, needsAxes)   % as M7 createPatternTab
```

Example (M7 3548–3553 → one line):

```matlab
[app.ThresholdMindBSpinnerLabel, app.Cov_Spinner_ThreshMin] = app.labelled(g, 'Threshold  Min (dB):', 2, 3, @uispinner, ...
    'Value', -40, 'ValueChangedFcn', @(~,~) app.on("covRange"));
```

Rules: grids declared with their `RowHeight/ColumnWidth` inline; callbacks are `@(~,~) app.on("scope")`; no `Layout.Row =` outside `place`; property names unchanged and **kept as declared properties** (≈ 170 handle declarations in section A stay — App Designer style, §16-7). Budget: **≤ 320 lines** for the same 118 widgets. The `uiInventory` gate row (§13-28) asserts parity with M7: same handle names, same class per handle, same parent, same `Layout.Row/Column`, same `Items/Limits/Value/Text` defaults.

---

## 10. Defect register — why M8 cannot contain them

Each row: M7 lines → defect → M8 mechanism. Every row has a self-test row (§13) or a static check (§11).

### 10.1 Numerical policy

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| F01 | 5085–5139 | `prctile` (Statistics Toolbox) + grid-independent percentile peak policy can demote a real pencil beam | `met_peak` spatial isolation (I5) |
| F02 | 2810→4834–4851, 4643, 2552 | Display (elevation) θ used for ΔΩ, unit vectors, F/B, coverage-node boresight | `Pattern` is always polar; display is `Map` (I8) |
| F03 | 4904–4907 | Field values rounded to 5 decimals | angles-only snap (I1) |
| F04 | 4920–5041, 5059 | `Re/Im` interpolation loses magnitude under phase slope | power + unit-phasor per component (§6.3) |
| F05 | 4980–4984, 5061–5066 | Target always full sphere; `'nearest'` fabricates data outside the source | target axes within the source domain; no extrapolation |
| F06 | 421–424 | Integer-degree filter yields a 3° grid from 0.3° | exact decimation iff `k ∈ ℕ`, else interpolation |
| F07 | 4630–4641, 5170–5172 | Spikes removed from ∫ only; efficiency/F-B on partial spheres | `keep` mask in numerator **and** Ω; `IsFullSphere` gate (I9) |
| F08 | 4761–4779 | NaN AR → PLF of a perfectly linear antenna | `pol_plf` NaN-safe; one `isLinear` mask shared with AR |
| F09 | 315, 432 | `calcPattern` twice per refresh when 1° is active | columns computed after resampling, on demand |
| F10 | 4593–4597, 2275–2279 | `N×T` logical promoted to double in `mtimes` (261 MB at 65k×501); cache keyed by thresholds | `cov_dist` once, `cov_eval` any `T` |
| F11 | 1525 | Threshold vector by colon accumulation | counting |
| F12 | 2810–2811, 569–583, 4615–4636 | Orientation, POB **and `calcMetrics`' `peakGain`** come from the selected component: with AR/PLF selected the directivity is `AR_peak` over the total-gain integral, F/B is `AR_peak − G_back` | I4; metrics only on total gain; status names the component |
| F14 | 4743–4757 | Polarisation label from sphere-mean powers | main-beam Ω-weighted pairs; label from `AR_p` and the leading pair member |
| F26 | 4713–4715, 5160 | Gain-only: loss on all columns (incl. AR); peak column = column 3 | `Cols` kinds via `util_colKind` |
| F58 | 1329 vs 1386, 2833 | Gain-only cut always plots column 3 (`VariableNames(3)`), while the title and component dropdown name the selected column | `geo_cut` on `View.Component` (§16-8) |
| F59 | 5002–5012 vs 5019–5022, 4922–4923 | `LinearPowerForGain` honoured only on the scattered path; the regular-grid path interpolates gain-only dB linearly | one `pat_interp(X, kind)`; gate row 25 checks midpoints |
| F64 | 4915–4917 | `normalizePattern` always appends a φ = 360 copy even for non-periodic sources | `PhiPeriodic` measured (§6.2); closing column only in `Map` |

### 10.2 Import and disclosure

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| F16 | 4139–4149 | `.cut` `ICOMP ∉ {1,2}` read as θ/φ | `APAT:UnsupportedICOMP` |
| F17 | 4132–4137 | Body of revolution synthesised silently | `Meta.SynthesizedRevolution`, one Metadata row (§16-5) |
| F18 | 4162–4167 | UAN header not validated | header assertions; `APAT:UnsupportedUAN` |
| F19 | 4155–4159, 4185–4190, 4913 | FEKO multi-frequency blocks merged; first kept silently | block split on `#Frequency:`; frequency dropdown |
| F20 | 4159–4190, 4638, 1290 | Raw fields labelled dBi; efficiency printed | `Meta.Unit/UnitLabel` per format; I9 gating (§16-4) |
| F21 | 4013 | `rmmissing` drops rows with NaN in unused columns | drop only on θ/φ/used-column NaN |
| F22 | 4035–4041 | Axis order by span even with headers; undisclosed | header names first; `AxisDecidedBy` |
| F23 | 4059 | Mag/phase layout by `> 100` | header names; range rule with agreement; else error |
| F24 | 4021–4023 | 2-column gain cut detected as coverage | keyword **or** strict no-header rule |
| F25 | 4886–4893 | Elevation heuristic applied to every format | decision per reader; `ThetaDecidedBy` |
| F27 | 1902 | UAN `maximum_gain` = component max | total-gain peak + L |
| **F66** | **4227–4563 (4400–4563)** | **164-line Excel summary parser** (`readExcelSummary` + 5 helpers: general labels, valid-frequency range, antenna count, frame definition, antenna positions, component step table) feeds **one** field, `frequencyMHz → hasFrequency`, which is never read for Excel sources (`freqs = NaN` at 4345; Metadata shows nothing) | one `xl_lookup` for the frequency cell → `Source.Freqs`; the rest deleted |
| **F70** | **4886–4893 vs 4130–4131** | Non-uniform / irregular grids are accepted silently: `normalizePattern` never checks spacing; `resampleCanonical` falls to `scatteredInterpolant` (5070–5076) and every ΔΩ from `gridStep` (the *minimum* gap) is then wrong for the wider cells | `pat_build` asserts uniform, regular axes once → `APAT:NonUniformGrid` (§16-1); scattered path deleted |

### 10.3 Dataflow and state

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| F28 | 189–194, 439–459, 480–487 | Six tables; display convention in data; `physicalTheta` ×13 | grid-native `Pattern` + `Map` |
| F29 | 4853, 5164, 499–536 | Step/ΔΩ/grid rebuilt per consumer | `Pattern.d*`, `Geometry` |
| F30 | 658–688 ≡ 4812–4832; 865–886 ≡ 1559–1579; 4 circular splits; 5 six-column reader cases; two identical table constructions 4318–4324 | Duplicate algorithms | `geo_cut`, `util_presetRange`, `pol_circular`, `io_fields` |
| F31 | 14 widget `UserData` sites | State in widget `UserData` | `View`, `Range`, `Status` (I11) |
| F32 | 282, 1336, 1355 | Readers/getters write widgets; extractor writes status | `readConfig` reads; `apply*` write; transient snap status |
| F33 | 1684–1686, 2264 vs 297, 2290–2293 | Node table copies; Main node live, foreign nodes frozen params | `Pats(k)` registry (I14); `L` at compute; labelled |
| F34 | 1663, 2749 | 65k `prctile` on every tree click | `Base.Peak` cached per entry |
| F35 | 458 | Display toggles invalidate coverage keys | keys use `Revision` only |
| F36 | 1590, 1596, 914 | Presets and sliders only widen | `applyRange` with `Range.Auto` |
| F37 | 345 vs 653 | Cut-value `Step` set twice | `applyChoices` once |
| F38 | 837–847 → 893–899 | AR theme collapses the cut range | AR theme touches `full` only |
| F39 | 2000–2010 vs 2119–2126 | Same-file reselect refused; Process re-parses | reselect = reload, one `update("source")` |
| F40 | 4802–4807, 590–608, 2208 | 17 eager columns; 65k×17 `uitable` push per change | memoised `Cols`; tables lazy |
| F61 | 2040 → 2053, 2024–2062 | `activateSource` commits `rawTbl/ffdBlocks/srcUD/stdTbl` before `refresh`; cancel/error leaves new metadata with old view | build-then-commit (I13) |
| F62 | 232–235, 1589, 1598, 1613–1616, 2409–2412 | Four write-only fields (`userEdited`, `lastPreset`, `evaluationBounds`, `displayBounds`) and a three-wire callback (`markCoverageThresholdUserEdit`) whose only effect is never read | `Range.Auto.cov/covX` cleared by the range callback itself |
| F63 | 644–656 vs 1361–1365, 1427 | Cut-value spinner domain is canonical while plots/HPBW label use the signed/elevation convention | cut-value domain through `Map` in `applyChoices` (I8) |
| F65 | 13 sites (297, 315, 405, 432, 574, 628, 631, 872, 1568, 3727, 3794, 4612, …) | `PeakPercentile`/`PeakMaxExcessDB` threaded through six signatures | `Const.PeakExcessDB` read by `met_peak` only |
| **F67** | **1512–1531 ← 1758, 2298** | **`covThresholds` is a getter with a side effect:** it rewrites `Cov_Spinner_ThreshMax.Value` (1523) and is called from `covRebuildTable` on every check/uncheck and selection change | `readCoverageConfig` reads only; clamping is `applyRange("cov")` |
| **F68** | **1656, 2553 (write) / no read; 2300, 2359; 1684–1686** | **Dead node state:** `componentBounds` (written twice via `robustRange`, never read — `robustRange` itself is therefore dead), `orientationMode` (initialised `"Spherical"` and stored on conical jobs too), `sourceTable`/`viewRevision` copies per node | nodes hold `k` or `{id,k,col,region,T,L,line}` only |
| **F69** | **5198–5199 ← 1936 vs 501–513** | **`emptyGridCache` schema never matches its consumer:** it seeds `{valid,theta,…}` (flat) while `gridComp/gridGeom` test `cache.topology.*`; the seeded cache is always treated as invalid | `Geometry` + memoised `Cols`; both gone |
| **F71** | **202, 331–332** | **`app.step` property written and read only on the next line** — a local variable declared as state | gone with `refresh` |

### 10.4 Graphics, UI, hygiene

| # | Lines | Defect | M8 mechanism |
|---|---|---|---|
| F41 | 997–1013, 1015–1023 | All 5 views rendered per change | visible tab only; dirty keys |
| F42 | 1210–1219; 992, 1229, 1233, 2891 | New context menu per render; 11 `findall/findobj` | one menu at startup; registry |
| F43 | 805, 1297–1308, 1261 | Colorbar/triad recreated | created with the axes |
| F44 | 1251–1253 vs 1317; 1237 vs 1265 | Polar-3D overlay radius mismatch (surface renormalises by its own max, overlay does not) | `util_polarRadius` |
| F45 | 2833–2834; 1396, 1311, 2846 | Cut plotted twice; `cutData` ×3 | one `geo_cut` per change |
| F46 | 1438, 1458 | Cut POB/HPBW on first checked trace | named in label |
| F47 | 1818, 1817 | Timer per status; dead statement `UserData = UserData` | one timer; gone |
| F48 | 1928 | `assignin('base')` | env-gated `app.Perf` |
| F49 | 2256 | Parse outside `try` | `on` guard |
| F50 | 2648 | Hard-coded −250 | `ax.XLim(1)` |
| F51 | 3715 | Self-test needs a live app | `static selfTest()` |
| F52 | 785 | `plotTheme` ignores its argument | `util_theme(kind, limits)` |
| F53 | 704–711 | `-0` | `util_fmtNumber` |
| F54 | 507 | `pi` shadowed | gone with `gridComp` |
| F55 | 610–622 | Parameter visibility follows table filter | follows component kind |
| F56 | 947–972, 1026–1084, 2849–2924 | 250 lines of annotation bookkeeping | create-once handles |
| F57 | 3073 vs 248 | Title/version mismatch | title from `Const.ReleaseName` |
| F60 | 355 → 2797 → 2846 → 1231–1238, then 357 | With "overlay cut" checked, load renders both 3-D surfaces in `drawSpatial3D` and again in `renderAllFullPatterns` | overlays drawn only inside `renderFull` of the visible tab (§7.2) |

(IDs F13, F15 are intentionally unused: the underlying behaviours — principal-axis E/H planes and the −100 dB linear-AR floor — are **decided conventions**, §16-6 and §16-2, not defects.)

---

## 11. Destination file layout and size budget

```
classdef APAT_v3_M8 < matlab.apps.AppBase
  A  properties: UI handles (unchanged names, ≈ 170, App Designer style) · Pats Main View Map Range Gfx Status Busy Perf
  B  Constant: Const (ReleaseName, PeakExcessDB=6, CircularAR_dB=3, LinearAR_dB=-100, ARLimits=[-30 30], AngleDecimals=5,
               UniformTolDeg=1e-6, PLFTiltCos=-1, RangeHard=[-250 100], RevolutionPhiStep=10, PrincipalAxes, Cols, Views, RangeGroups, ReaderSpecs)
  C  orchestration: readConfig readCoverageConfig update on col applyChoices applyVisibility applyRange setStatus
  D  renderers: renderFull(k) viewCoords newSurface renderCut renderCoverage geo_displayMap util_theme util_polarRadius markers
  E  coverage UI: node add/select/check, compute, query, table, export
  F  export: results, cut, UAN
  G  layout: place labelled patternTab createComponents
  H  lifecycle: constructor, startupFcn (menu, timer, Gfx), shutdown, delete, closeRequest
  I  static selfTest + fixture generators fx_*
end
% ---- file-scope, app-free ----
io_read io_fields io_uanHeader io_cut io_ffd io_ffe io_excel xl_lookup io_text util_colKind
pat_build pat_resample pat_interp geo_build geo_integrate geo_cut
pat_baseFacts met_peak met_orientation met_planes met_hpbw met_metrics
pol_circular pol_fromCircular pol_signedAR pol_plf
cov_dist cov_eval cov_inverse cov_coneMask cov_thresholds cov_eval_reference
util_fmtNumber util_presetRange util_nearest
```

| Section | Budget (lines) | M7 equivalent |
|---|---|---|
| A + B (properties, constants, `Cols`, `Views`, `RangeGroups`, `ReaderSpecs`) | ≤ 230 | 251 |
| C (orchestration) | ≤ 300 | ≈ 700 |
| D (renderers) | ≤ 400 | ≈ 900 |
| E (coverage UI) | ≤ 280 | ≈ 780 |
| F (export) | ≤ 70 | ≈ 110 |
| G (layout, declarative) | ≤ 320 | 680 |
| H (lifecycle) | ≤ 50 | ≈ 100 |
| I (self-test + fixtures) | ≤ 150 | 145 |
| readers (all formats) | ≤ 330 | 687 |
| numerical core | ≤ 260 | 636 |
| **Total** | **≤ 2,390 sum of budgets; target ≤ 2,600; ceiling 3,000** | 5,199 |

**Static checks at the gate** (each must return 0): `physicalTheta|gridStep|solidWeights|findall|findobj|assignin|prctile|scatteredInterpolant|interp1(` ; `.UserData` on any widget name; `sqrt(2)`/`1i*` outside `pol_circular`/`pol_fromCircular`; `cosd(180)`/`-100` outside `Const`; `"dBi"` outside `Meta`/`Const`; `Layout.Row =` outside `place`; `cla(` outside the `renderFull` topology branch; `drawnow` outside `on`, the progress dialog and startup; `PeakExcessDB` outside `Const` and `met_peak`; `Cov_Spinner_ThreshMax.Value =` outside `applyRange`. Line count ≤ 3,000.

---

## 12. Work order — one drop, core first

1. **Core (file-scope, no UI):** `pat_build` (uniformity assertion), `pat_resample/pat_interp`, `geo_*`, `pol_*`, `met_*`, `cov_*`, `geo_cut`, readers with `Meta`, `io_fields` and `xl_lookup`. Write `selfTest` alongside; run it green before touching the class.
2. **Class state:** replace the six table properties and the flag families with `Pats/Main/View/Map/Range/Gfx/Status`. Add `Const.Cols/Views/RangeGroups/ReaderSpecs`, `col()`.
3. **Orchestration:** `readConfig`, `readCoverageConfig`, `update(scope)` with build-then-commit into `Pats`, `on`, `applyChoices`, `applyVisibility`, `applyRange`, `setStatus` with one timer.
4. **Renderers:** `renderFull` (five kinds behind `Const.Views` + `viewCoords`), `renderCut`, display map, create-once annotations, one context menu.
5. **Coverage tab:** nodes referencing `Pats(k)`, compute via `cov_dist/eval`, exact table, queries, presets under `Range.Auto`, one job label.
6. **Export** from data, UAN header from total-gain peak.
7. **Layout:** rewrite `createComponents` with `place/labelled/patternTab`, callbacks as `@(~,~) app.on("scope")`. Run `uiInventory` against the M7 inventory file (captured once from M7 with a 10-line script: handle name, class, parent name, row, column, key defaults).
8. **Delete** every replaced M7 name (list §7.2). Run the static checks and the line count.
9. **Regression on real files:** one of each format (UAN, FZ, OUT, CUT single + multi, FFS, FFE single + multi-frequency, FFD single + multi, Excel 1/2/3, generic gain single- and multi-column, generic E-field ×6, a coverage-results CSV). Compare total-gain peak/POB, HPBW, directivity, coverage at three thresholds against M7 at `L = 0` on **polar** display; every delta must be one listed in §10 or §16 (e.g. F01, F03, F05, F07, F58, F59, F70) and explained in the release notes.

---

## 13. Release gate — `APAT_v3_M8.selfTest()` (static, no UI except row 28)

Fixture generators (`fx_*`, analytic, tiny): `fx_isotropic(dθ,dφ)`, `fx_dipole(axis)`, `fx_cp(sense)`, `fx_gauss(θ0,φ0,hpbw)`, `fx_hemisphere`, `fx_halfPlane` (φ 0…180), `fx_spike(base, at)`, `fx_phaseSlope(kλ)`, `fx_gainOnly(cols)`.

| # | Row | Assertion |
|---|---|---|
| 1 | `geometryFullSphere` | `Geometry.Omega == 4π` to 1e-12 for 1°, 2°, 5°, 0.5° grids and for pole-free `0.5:1:179.5` |
| 2 | `geometryPartial` | `fx_hemisphere`: closed-form Ω, `IsFullSphere == false`; `fx_halfPlane`: `PhiPeriodic == false`, no closing column in `Pattern`, one in `Map` only when periodic (F64) |
| 3 | `integrate` | `geo_integrate(X) ≡ sum(X(:).*ΔΩ(:))` (dense) to 1e-12 on random `X` |
| 4 | `coverageOracle` | `cov_eval(d, T) ≡ cov_eval_reference(G, mask, T, ΔΩ)` to 1e-12 on 200 random `T`, including ties; `C(−Inf) = 100`, `C(+Inf) = 0`, strict `>` at a tie |
| 5 | `coverageInverse` | 50 random `c`: `cov_eval(d, T⁻) ≥ c` and `cov_eval(d, T) < c` just above; `c > 100 → NaN` |
| 6 | `coverageLossShift` | `cov_eval(d(G), T − L) ≡ cov_eval(d(G + L), T)` |
| 7 | `coneMask` | dot-product mask ≡ angular-distance mask on 20 random cones; boundary sample inside |
| 8 | `normalizePrecision` | fields bit-identical through `pat_build`; angles snapped; θ > 180 folded once; φ = 360 column folded with `PhiClosedInSource` |
| 9 | `resampleDecimate` | 0.5° → 1°, 0.25° → 1°, θ 0.5°/φ 1° → 1°: bit-exact selections; 0.3° → 1° yields a 1° grid by interpolation |
| 10 | `resamplePower` | `fx_phaseSlope(10λ)` 2° → 1°: total-gain error at native samples 0, at midpoints < 0.05 dB |
| 11 | `resampleDomain` | `fx_hemisphere` 2° → 1°: no sample with θ > 90 |
| 12 | `peakSpike` | `fx_spike`: `wasAdjusted`, `value == base`, `spikeCount == 1`; pole-row spike detected; `fx_gauss(hpbw = 2°)` at 1°: **not** adjusted |
| 13 | `lossOffset` | for every `lossAdd` column: `col(P_L) == col(P_0) + L`; peak index, boresight, HPBW, directivity identical; efficiency scales by `10^(L/10)` |
| 14 | `displayInvariance` | `Map` permutation is a bijection; `CData(:,ColIdx)` reproduces the physical grid under inverse permutation; metrics identical across the four span/elevation combinations; cut-value domain equals `Map.ThetaAxis`/`Map.PhiAxis` range (F63) |
| 15 | `circularSense` | `fx_cp("RHCP")` (`Eθ = 1, Eφ = −j`): `E_RCP_dB − E_LCP_dB > 60 dB`; `"LHCP"` symmetric; inverse∘forward = identity |
| 16 | `planes` | principal-axis rule: `fx_gauss` on +Z → E = θ-cut @ φ = 0, H = θ-cut @ 90; on +X → E = θ-cut @ 0, H = φ-cut @ θ = 90; on −Y → E = θ-cut @ 270, H = φ-cut @ 90 |
| 17 | `polarisationLabel` | `fx_dipole("x")` → "Linear (Vertical)"; `fx_dipole("y")` → "Linear (Horizontal)"; `fx_cp("LHCP")` → "Circular (LHCP)"; label unchanged when 20 dB of far sidelobes are added |
| 18 | `plfAndLinearAR` | `PLF_dB(NaN field) == NaN`; RHCP wave on RHCP antenna `AR = 0` → 0 dB; on LHCP → ≤ −30 dB; exactly-linear sample: `AR_dB == −100` **and** PLF equals the `r_a → ∞` limit |
| 19 | `metricsIsotropic` | `fx_isotropic`: directivity 0 dB, efficiency 100 %, F/B 0 dB; `fx_hemisphere`: efficiency/F-B NaN |
| 20 | `metricsOnTotal` | `fx_dipole` with `View.Component = "AR_dB"`: `Base.Metrics0`, boresight and peak index identical to `Component = "E_Total_dB"` (F12) |
| 21 | `hpbwGauss` | `fx_gauss(hpbw = 20°)`: `met_hpbw` = 20° ± 0.1° on both planes |
| 22 | `readers` | each format fixture → canonical `Pattern`; `.cut ICOMP = 3` → `APAT:UnsupportedICOMP`; UAN `magnitude linear` → `APAT:UnsupportedUAN`; FFE 2-frequency fixture → 2 blocks; generic file with a sparse 7th column keeps all rows; headed 2-column gain cut is a pattern; header `el` → elevation with `ThetaDecidedBy == "header"`; every `ReaderSpecs` row round-trips a synthetic six-column file; Excel fixture → `Source.Freqs` from the summary cell |
| 23 | `uniformAxes` | 1° passes; one 0.999° gap → `APAT:NonUniformGrid` naming the axis; a missing sample (irregular) → `APAT:NonUniformGrid` (F70) |
| 24 | `fmtNumber` | `-0.001 → "0"`, `12.50 → "12.5"`, `100 → "100"`, fixed precision preserved |
| 25 | `resampleGainOnly` | `fx_gauss` as a **gain-only** 2° grid → 1°: midpoint error vs analytic < 0.05 dB (linear-dB interpolation gives > 0.3 dB on a 20° beam); `phase`-kind column interpolated linearly (F59) |
| 26 | `cutComponent` | `fx_gainOnly(["Gain","AR"])`: `geo_cut(P, "AR", …)` returns the AR column; trace list for gain-only equals `View.Component` (F58) |
| 27 | `thresholds` | `cov_thresholds(-40, 10, 0.1)` has 501 exact elements |
| 28 | `uiInventory` | headless `createComponents` (figure `Visible off`): every handle in the M7 inventory exists with the same class, parent, row/column and defaults; no extra handles; 118 widgets (I15) |
| 29 | `commitAtomic` | `update("source")` with a fixture that errors in `geo_build`: `Pats(Main).Pattern.Revision`, `Pats(Main).Source.Meta.Format` unchanged (F61) |
| 30 | `registryShared` | load a fixture on Main, add it to Coverage, switch Main to 1°: the coverage node's `k` resolves to the resampled `Pattern` (same `Revision`), its `Dist` cache misses and recomputes; no second `Pattern` object exists (I14) |

The gate passes only when all rows pass **and** the static checks of §11 return zero **and** the file has ≤ 3,000 lines.

---

## 14. Performance targets and measurement

Measured with `APAT_PROFILE=1` on a 1°×1° full sphere (181 × 360 = 65,160 samples), after warm-up:

| Action | M7 (typical, same machine) | M8 target |
|---|---|---|
| Load UAN → first plot visible | 5–7 renders (F60) + tables | ≤ 40 % of M7 (one render, lazy tables) |
| Component change | orientation + metrics + 5 renders + table push | ≤ 120 ms (one memoised column + one `CData`) |
| Loss change | full reprocess + 5 renders | ≤ 30 ms (offset + `CData`) |
| Span/elevation toggle | `sortrows` 17 cols + 5 renders | ≤ 60 ms (permutation) |
| Cut change | `cutData` ×3 + 3 redraws + 2 legends | ≤ 40 ms |
| Coverage compute (500 thresholds) | 261 MB transient, `N×T` | ≤ 1 MB, one sort; thresholds change ≈ 5 ms |
| Tree click | 65k `prctile` + preset rewrite | ≈ 0 |
| Startup (`createComponents`) | 622 statements | same or faster (fewer property round-trips) |

---

## 15. Risks and platform baseline

| Risk | Mitigation |
|---|---|
| A real-file delta against M7 not in §10/§16 | Step 9 of the work order blocks release until it is explained or fixed |
| A real source file turns out non-uniform | `APAT:NonUniformGrid` names the axis and gap; the owner's position is that antenna patterns are uniform (§16-1) — such a file is a data error, not an APAT feature |
| `pcolor`/`surf` `CData` in-place semantics differ across releases | R2023b baseline; the topology branch (`cla` + recreate) is the fallback, exercised by the size-change path |
| Datatip API differences | only `datatip(h, x, y)`/`DataIndex` are used; no `InterpolationFactor` |
| Declarative layout drifts from M7 appearance | `uiInventory` gate row compares against a captured M7 inventory; any mismatch fails the gate |
| One-file constraint limits unit-test tooling | static `selfTest` + fixtures in the file; CI calls `APAT_v3_M8.selfTest()` |
| Line budget missed | §11 budgets are per section; the ceiling (3,000) is a gate; 400 lines of slack exist between the budget sum and the target |

---

## 16. Decided conventions (closed; each is one constant or one line of behaviour)

| # | Topic | Decision | Where it lives |
|---|---|---|---|
| 1 | Non-uniform source axes | **Reject.** Antenna patterns are uniform; `pat_build` asserts uniform, regular axes and raises `APAT:NonUniformGrid`. No regularisation, no scattered interpolation. | §6.2 step 4; `Const.UniformTolDeg`; gate row 23 |
| 2 | Exactly-linear samples in the signed-AR view | **Keep the M7 rule:** equal circular components → `AR_dB = −100` (|AR| = 100 dB, the "bad axial ratio" floor). PLF for the same samples takes the exact `r_a → ∞` limit. | `Const.LinearAR_dB`; A.5, A.6; gate row 18 |
| 3 | Peak excess | **Keep 6 dB**, now applied as a spatial (grid-neighbour) rule. | `Const.PeakExcessDB`; A.3 |
| 4 | FEKO `Gain(Total)` column for `dBi` labelling | **Simplest approach:** no calibration code. `Meta.Unit` is static per format; `.ffe` is a raw far field (`"dB"`, like OUT/CUT/FFS/FFD). Extra FEKO columns stay ignored as in M7. | §6.1 table; I9 |
| 5 | Body-of-revolution φ step for a single `.cut` | **Keep M7 behaviour** (10° copies); disclose with one Metadata row. | `Const.RevolutionPhiStep = 10`; `Meta.SynthesizedRevolution` |
| 6 | E/H planes | **Keep the M7 principal-axis rule** (634–642): E = θ-cut at the boresight axis φ; H = θ-cut @ 90° (±Z) or φ-cut @ θ = 90° (equatorial). No polarisation-tilt logic. | `met_planes`, A.7; gate row 16 |
| 7 | UI handles | **Keep App Designer style:** every handle is a declared property with its M7 name. | Section A; gate row 28 |
| 8 | Gain-only cut traces | **Selected column only** (matches the title). | §6.8; gate row 26 |

---

## 17. Outcome

- **One dataflow**: `Source → Pattern → Geometry → Cols/Base → Pats(k) → (View, Map) → renderers`, with loss as an offset and build-then-commit.
- **One pattern registry** serving the Main and Coverage tabs; no copies, no synchronisation code.
- **≤ 2,600 lines** (ceiling 3,000) with every widget preserved and verified by inventory.
- **Zero** duplicate algorithms, toolbox calls, `findall/findobj`, widget `UserData`, `assignin`, `interp1` on coverage data, `scatteredInterpolant`, dead state.
- **Correct physics** for every accepted input: polar geometry always, no field rounding, no fabricated samples or seams, grid-aware peak, power-domain resampling for fields *and* gain, metrics on total gain, honest units, the selected component in every cut, uniform grids guaranteed.
- **Speed**: component/loss/span changes are index and offset operations; coverage cost is independent of the threshold count; load renders once; tree clicks cost nothing.
- **Every convention** (circular sense, PLF tilt, peak excess, AR limits and linear floor, unit class, θ/axis decisions, revolution step, E/H rule) is one constant or `Meta` field and appears in Metadata.
- **71 defects** closed, each traceable to a self-test row or a static check.

---

## Appendix A — Reference kernels (MATLAB, base only)

### A.1 Coverage family

```matlab
function d = cov_dist(C, G, mask)
%COV_DIST Ω-weighted distribution of the level grid C over a region.
%  Coverage(T) = 100·Ω{C > T}/Ω_R,  Ω{C > T} = Σ_{(i,j)∈R, C(i,j)>T} wθ(i)·dφ  (canonical grid only).
%  Sorting the region's values gives levels g_1 ≤ … ≤ g_n with weights ω_k; S(k) = Σ_{m≥k} ω_m,
%  so Ω{C > T} = S(k_T), k_T = first k with g_k > T.   Reference: cov_eval_reference (self-test).
v = mask & isfinite(C);
w = (G.wTheta .* G.dPhi) .* ones(1, size(C, 2));           % ΔΩ(i,j), local temporary
[g, ~, bin] = unique(C(v));                                % distinct levels ascending
d.g = g; d.w = accumarray(bin, w(v)); d.S = flipud(cumsum(flipud(d.w))); d.Omega = sum(d.w);
end
function cov = cov_eval(d, T)
% Coverage(T) = 100·S(k_T)/Ω_R; k_T = first level > T (bin edge search; exact at ties).
cov = zeros(size(T)); if isempty(d.g) || d.Omega <= 0, return; end
k = discretize(T, [-Inf; d.g; Inf]);                       % T in [g_{k-1}, g_k)  ⇒ first level > T is k
S = [d.S; 0]; cov = 100 * S(k) / d.Omega;
end
function T = cov_inverse(d, c)
% sup{ T : Coverage(T) ≥ c }: level g_k* where k* is the last level with S(k*) ≥ c·Ω/100 (NaN if none / c > 100).
T = nan(size(c)); if isempty(d.g), return; end
for q = 1:numel(c), k = nnz(d.S >= c(q) * d.Omega / 100); if k >= 1, T(q) = d.g(k); end, end
end
function m = cov_coneMask(G, thC, phC, alphaDeg)
cx = sind(thC)*cosd(phC); cy = sind(thC)*sind(phC); cz = cosd(thC);
m = (G.sinT*G.cosP)*cx + (G.sinT*G.sinP)*cy + (G.cosT*ones(1,numel(G.cosP)))*cz >= cosd(alphaDeg) - 1e-12;
end
function T = cov_thresholds(tMin, tMax, step)              % counting, not accumulation
n = round((tMax - tMin)/step); T = tMin + (0:n).'*step; if T(end) < tMax - 1e-9, T(end+1) = tMax; end
end
function cov = cov_eval_reference(C, mask, T, dOmega)      % literal N×T form, self-test only
v = mask(:) & isfinite(C(:)); g = C(v); w = dOmega(v); cov = zeros(size(T));
for k = 1:numel(T), cov(k) = 100 * sum(w .* (g > T(k))) / sum(w); end
end
```

### A.2 Geometry and separable integral

```matlab
function G = geo_build(P)
%GEO_BUILD Separable solid-angle weights for a uniform θ×φ grid (I2).
%  ΔΩ(i,j) = wTheta(i)·dPhi, wTheta(i) = cos θᵢ⁻ − cos θᵢ⁺, θᵢ∓ = clamp(θᵢ ∓ dθ/2, 0, 180).
%  Σ wTheta telescopes to cos θ₁⁻ − cos θₙ⁺ (= 2 when the end cells reach both poles); Σ dPhi = nφ·dφ (= 2π when periodic).
th = P.Theta(:); ph = P.Phi(:);
lo = max(th - P.dTheta/2, 0); hi = min(th + P.dTheta/2, 180);
G.wTheta = cosd(lo) - cosd(hi); G.dPhi = deg2rad(P.dPhi);
G.PhiPeriodic = abs(numel(ph)*P.dPhi - 360) < 1e-9;
G.Omega = sum(G.wTheta) * numel(ph) * G.dPhi;
G.IsFullSphere = G.PhiPeriodic && lo(1) == 0 && hi(end) == 180;
G.sinT = sind(th); G.cosT = cosd(th); G.cosP = cosd(ph).'; G.sinP = sind(ph).';
end
function I = geo_integrate(G, X)                           % ∫ X dΩ over the sampled grid, NaN-safe
I = G.dPhi * (G.wTheta.' * sum(X, 2, 'omitnan'));
end
```

### A.3 Spatial peak

```matlab
function P = met_peak(C, periodicPhi, excessDB)
%MET_PEAK A sample is an isolated spike iff it exceeds ALL its grid neighbours by more than excessDB.
%  Neighbours: θ±1 (rows), φ±1 (columns, wrapped when periodic). Pole rows compare against the adjacent ring's
%  maximum because every φ sample on a pole row is the same physical direction.
[n, m] = size(C);
up = [C(1,:); C(1:n-1,:)]; dn = [C(2:n,:); C(n,:)];
if periodicPhi, lf = C(:,[m 1:m-1]); rt = C(:,[2:m 1]); else, lf = [C(:,1) C(:,1:m-1)]; rt = [C(:,2:m) C(:,m)]; end
nb = max(max(up, dn), max(lf, rt));
if n > 1, nb(1,:) = max(C(2,:)); nb(n,:) = max(C(n-1,:)); end
P.mask = isfinite(C) & (C - nb > excessDB);
[P.rawValue, P.rawIndex] = max(C(:), [], 'omitnan');
cand = C; cand(P.mask) = -Inf; [P.value, P.index] = max(cand(:));
P.wasAdjusted = P.mask(P.rawIndex); P.spikeCount = nnz(P.mask);
end
```

### A.4 Circular decomposition — one place (I10)

```matlab
function E = pol_circular(Eth, Eph, which)
%POL_CIRCULAR RHCP (which = 1) / LHCP (which = 2) components of E = Eθ θ̂ + Eφ φ̂.
%  Convention: e^{+jωt}, (θ̂, φ̂, r̂) right-handed. IEEE right-hand unit vector ê_R = (θ̂ − jφ̂)/√2; the RHCP
%  component is the projection on the conjugate basis, E_R = E·ê_R* = (Eθ + jEφ)/√2; E_L = (Eθ − jEφ)/√2.
%  Check: E = ê_R ⇒ Eθ = 1/√2, Eφ = −j/√2 ⇒ E_R = 1, E_L = 0. (B.5)
if which == 1, E = (Eth + 1i*Eph)/sqrt(2); else, E = (Eth - 1i*Eph)/sqrt(2); end
end
function [Eth, Eph] = pol_fromCircular(Er, El)             % inverse: OUT / CUT ICOMP=2 / Excel format 2 / generic rcp/lcp
Eth = (Er + El)/sqrt(2); Eph = (Er - El)/(1i*sqrt(2));
end
```

### A.5 Signed axial ratio (M7 floor kept) and the shared linear mask

```matlab
function [AR, isLinear] = pol_signedAR(Eth, Eph)
r = abs(pol_circular(Eth, Eph, 1)); l = abs(pol_circular(Eth, Eph, 2)); d = r - l;
isLinear = isfinite(d) & abs(d) <= eps(r + l);              % equal circular components: no handedness
AR = min(20*log10((r + l) ./ max(abs(d), realmin)), 250) .* sign(d);
AR(isLinear) = Const.LinearAR_dB;                            % −100 dB: the M7 "bad axial ratio" floor (§16-2)
end
```

### A.6 PLF, NaN-safe, linear limit shared with A.5

```matlab
function plf = pol_plf(AR_dB, isLinear, rxMode, rxAR_dB, pairs)
% Worst-case-tilt polarisation loss factor between an elliptical wave and an elliptical antenna (M7 formula, cos Δτ = −1).
if rxMode == "Auto", s = 2*(pairs.Circular(1) == "E_RCP") - 1; elseif rxMode == "RHCP", s = 1; else, s = -1; end
rw = s * 10^(rxAR_dB/20); ra = sign(AR_dB) .* 10.^(abs(AR_dB)/20);           % signed axial ratios
plfLin = 0.5 + (4*ra.*rw + (ra.^2 - 1).*(rw^2 - 1)*Const.PLFTiltCos) ./ (2*(ra.^2 + 1).*(rw^2 + 1));
plfLin(isLinear) = 0.5 + (rw^2 - 1)*Const.PLFTiltCos ./ (2*(rw^2 + 1));       % exact r_a → ∞ limit (M7's 1e12 branch)
plf = 10*log10(min(max(plfLin, eps), 1)); plf(~isfinite(AR_dB)) = NaN;       % NaN field stays NaN (F08)
end
```

### A.7 E/H plane selection — principal-axis rule (M7 634–642, §16-6)

```matlab
function planes = met_planes(boresight, axes)
cut = @(t, v) struct('Type', t, 'Value', v);                % canonical angles; Map applies the display convention
axTh = axes.theta(boresight); axPh = axes.phi(boresight);
if axTh == 90, planes = struct('E', cut("Theta", axPh), 'H', cut("Phi", 90));       % equatorial boresight (±X, ±Y)
else,          planes = struct('E', cut("Theta", axPh), 'H', cut("Theta", 90)); end % ±Z boresight
end
```

### A.8 Display map (permutation, no copy)

```matlab
function M = geo_displayMap(P, G, view)
n = numel(P.Phi); j0 = find(P.Phi >= 180, 1); perm = 1:n;
if view.SignedPhi && ~isempty(j0), perm = [j0:n, 1:j0-1]; end
M.ColIdx = perm; if G.PhiPeriodic, M.ColIdx(end+1) = perm(1); end          % closing column for display only
M.PhiAxis = P.Phi(perm); if view.SignedPhi, M.PhiAxis(M.PhiAxis >= 180) = M.PhiAxis(M.PhiAxis >= 180) - 360; end
if G.PhiPeriodic, M.PhiAxis(end+1) = M.PhiAxis(1) + 360; end
if view.Elevation, M.ThetaAxis = 90 - P.Theta; M.ThetaDir = "normal";  M.ThetaLabel = "Elevation";
else,              M.ThetaAxis = P.Theta;      M.ThetaDir = "reverse"; M.ThetaLabel = "Theta"; end
M.Key = sprintf('%d|%d', view.SignedPhi, view.Elevation);
end
```

### A.9 Number formatting and preset range

```matlab
function s = util_fmtNumber(v, prec)                       % compact (≤ 2 dp, no trailing zeros, never "-0") or fixed
if ~(isscalar(v) && isnumeric(v) && isfinite(v)), s = 'n/a'; return; end
if nargin < 2 || isempty(prec), s = sprintf('%.2f', v); s = regexprep(s, '\.?0+$', ''); if s == "-0", s = '0'; end
else, s = sprintf('%.*f', max(0, min(5, round(prec))), v); end
end
function b = util_presetRange(peak)                        % 50-dB window under the next multiple of 5, clamped (M7 865–886 ≡ 1559–1579)
if ~isfinite(peak), b = [-50 0]; return; end
hi = ceil(peak/5)*5; b = min(max([hi-50, hi], -250), 100); if diff(b) < 1, b(1) = max(-250, b(2)-50); end
end
```

### A.10 Six-column field reader — one converter, nine specs

```matlab
% Const.ReaderSpecs:  ext(s)          source            th ph  a b c d   enc        basis      unit
%   {"UAN","FZ"}   "XGTD %s"          1  2  3 5 4 6   "magphase"  "linear"   "dBi"     (+ header assertions)
%   {"OUT"}        "TICRA/GRASP OUT"  1  2  3 4 5 6   "reim"      "circular" "dB"
%   {"FFS"}        "CST FFS"          2  1  3 4 5 6   "reim"      "linear"   "dB"
%   {"FFE"}        "FEKO FFE"         1  2  3 4 5 6   "reim"      "linear"   "dB"      (+ block split)
%   generic ×6     "Generic text (%s)" 1 2  (layout by header/range rule) enc/basis/order from the dropdown value
function [Eth, Eph, th, ph] = io_fields(M, s)
%IO_FIELDS Columns → complex θ/φ fields. a,b = component-1 (re,im | mag_dB,phase_deg); c,d = component-2.
th = M(:, s.th); ph = M(:, s.ph);
if s.enc == "magphase", c1 = 10.^(M(:,s.a)/20) .* exp(1i*deg2rad(M(:,s.b))); c2 = 10.^(M(:,s.c)/20) .* exp(1i*deg2rad(M(:,s.d)));
else,                   c1 = complex(M(:,s.a), M(:,s.b));                     c2 = complex(M(:,s.c), M(:,s.d)); end
if s.basis == "circular", if s.order(1) == 2, [c1, c2] = deal(c2, c1); end, [Eth, Eph] = pol_fromCircular(c1, c2);
else,                     [Eth, Eph] = deal(c1, c2); end
end
```

### A.11 Excel summary — one lookup instead of a parser

```matlab
function v = xl_lookup(C, label, col)                     % first row whose column-B text matches label (case/space tolerant)
key = lower(regexprep(string(label), '\s+', ''));
txt = lower(regexprep(string(C(:, 2)), '\s+', '')); r = find(txt == key, 1);
if isempty(r) || ~isnumeric(C{r, col}), v = NaN; else, v = double(C{r, col}); end
end
% io_excel: freqHz = 1e6 * xl_lookup(readcell(fp, 'Sheet', sheets(1), 'Range', 'A1:H70'), 'Pattern Simulation Freq (MHz):', 3);
```

### A.12 Uniformity assertion (I1, §16-1)

```matlab
function [ax, d] = pat_axis(v, name)                       % v = unique sorted angles of one axis
n = numel(v); if n < 2, ax = v; d = NaN; return; end
d = (v(end) - v(1)) / (n - 1); gap = max(abs(diff(v) - d));
assert(gap <= Const.UniformTolDeg, 'APAT:NonUniformGrid', ...
    '%s axis is not uniform: nominal step %.6g°, worst deviation %.3g°. APAT requires uniformly sampled patterns.', name, d, gap);
ax = v;
end
% pat_build: [P.Theta, P.dTheta] = pat_axis(unique(th), 'Theta'); [P.Phi, P.dPhi] = pat_axis(unique(ph), 'Phi');
%            assert(numel(P.Theta)*numel(P.Phi) == numel(th), 'APAT:NonUniformGrid', 'Pattern is not a complete θ×φ grid (%d of %d samples).', numel(th), numel(P.Theta)*numel(P.Phi));
```

### A.13 Declarative layout helpers

```matlab
function h = place(~, ctor, parent, row, col, varargin)
h = ctor(parent, varargin{:}); h.Layout.Row = row; h.Layout.Column = col;
end
function [lbl, h] = labelled(app, parent, text, row, col, ctor, varargin)
lbl = app.place(@uilabel, parent, row, col, 'Text', text, 'HorizontalAlignment', 'right');
h   = app.place(ctor, parent, row, col + 1, varargin{:});
end
```

---

## Appendix B — Derivations

**B.1 Exact solid angle.** With `θᵢ⁻ = max(θᵢ − dθ/2, 0)`, `θᵢ⁺ = min(θᵢ + dθ/2, 180)`, `Σᵢ (cos θᵢ⁻ − cos θᵢ⁺)` telescopes because `θᵢ⁺ = θᵢ₊₁⁻` on a uniform grid, giving `cos θ₁⁻ − cos θₙ⁺ = 2` when both poles are reached. With `Σⱼ dφ = 2π` on a periodic φ axis, `Σ ΔΩ = 4π` exactly, independent of step. Pole rows carry a half cell each, so no explicit pole special case is needed. This is the reason uniformity must be asserted (I1): on a non-uniform axis the telescoping breaks and any single "step" is wrong for some cells.

**B.2 Sorted CCDF.** For distinct levels `g_1 < … < g_n` with aggregated weights `ω_k`, `Ω{G > T} = Σ_{k : g_k > T} ω_k = Σ_{k ≥ k_T} ω_k = S(k_T)`, `k_T = min{k : g_k > T}` (empty ⇒ `S = 0`). `discretize(T, [−∞; g; ∞])` returns the bin with `g_{k−1} ≤ T < g_k`, so `k` is exactly `k_T` and exact ties follow the strict inequality.

**B.3 Loss shift.** For a level column `X = X₀ + L`, `Ω{X > T} = Ω{X₀ > T − L}`; one distribution at `L = 0` serves every loss value. Not valid for `AR_dB` (L-independent), `PLF_dB` (Rx-dependent) or `Gain_PolCorrected_dB` when Rx settings change — hence the Rx key for those columns. Efficiency: `η(L) = ∫10^{(G₀+L)/10}dΩ / Ω = η₀·10^{L/10}`.

**B.4 Power + unit-phasor interpolation.** Adjacent samples `E₁ = A e^{jψ₁}`, `E₂ = A e^{jψ₂}`, `Δ = ψ₂ − ψ₁`. Linear `Re/Im` gives a midpoint magnitude `A|cos(Δ/2)|` (−6 dB at 120°, 0 at 180°); power interpolation gives `A²` exactly. The unit-phasor midpoint `(e^{jψ₁} + e^{jψ₂})/2 = e^{j(ψ₁+ψ₂)/2}·cos(Δ/2)` has the circular-mean angle for every `|Δ| < 180°`; where `|E| → 0` the phasor is arbitrary but multiplies `√P → 0`. The same power rule applies to gain-only dB columns: linear interpolation of dB is a geometric mean of power and under-estimates the beam between samples (0.3 dB at the half-power points of a 20° beam sampled at 2°).

**B.5 Circular sense.** For propagation along `+r̂` with `(θ̂, φ̂, r̂)` right-handed and `e^{+jωt}`, the IEEE right-hand unit vector is `ê_R = (θ̂ − jφ̂)/√2`. Writing `E = E_R ê_R + E_L ê_L` and solving: `Eθ = (E_R + E_L)/√2`, `Eφ = −j(E_R − E_L)/√2` ⇒ `E_R = (Eθ + jEφ)/√2`, `E_L = (Eθ − jEφ)/√2`, i.e. `E_R = E·ê_R*`. Fixture: `Eθ = 1, Eφ = −j` ⇒ `E_R = √2, E_L = 0`.

**B.6 Linear-limit PLF.** With `r_a → ∞` in the M7 formula, `PLF = ½ + (r_w² − 1)·cosΔτ / (2(r_w² + 1))` — the value M7 approximates with `r_a = 10¹²`. Using the closed form for the `isLinear` mask removes the magic number and makes AR and PLF agree on which samples are linear.

**B.7 Why the layout compresses without changing the UI.** A `uigridlayout` child is fully specified by (constructor, parent, `Layout.Row`, `Layout.Column`, name/value defaults). M7 spends 3–7 statements per widget on exactly these five facts; `place` states them once. Because every widget keeps its property name, parent, row, column and defaults, the rendered figure is identical and the inventory row (§13-28) can verify it mechanically.

**B.8 Why one registry is enough.** The Main tab needs `{Pattern, Geometry, Base, ColCache}` for one file; the Coverage tab needs the same tuple for one or more files plus a `Dist` per (column, region). The Main file is just the entry the Main tab currently points at. Storing it once and indexing it from both tabs removes the copy, the three synchronisation functions, the per-node orientation recomputation, and the "frozen parameters" asymmetry — and it costs one integer property, `app.Main`.
