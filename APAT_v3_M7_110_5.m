classdef APAT_v3_M7_110_5 < matlab.apps.AppBase
% APAT v3 M7.110_5 — concise Code Analyzer cleanup and lifecycle sanity pass.

    properties (GetAccess = public, SetAccess = private)
        isClosing logical = false % Read-only lifecycle state; changed internally.
    end

    properties (Access = public)
        UIFigure matlab.ui.Figure
        GridLayout matlab.ui.container.GridLayout
        TabGroup matlab.ui.container.TabGroup
        Tab1_Single matlab.ui.container.Tab
        Single_Grid matlab.ui.container.GridLayout
        Single_panelParam matlab.ui.container.Panel
        Single_gridPanel_Param matlab.ui.container.GridLayout
        Single_DropDown_FFD matlab.ui.control.DropDown
        FFDFreqDropDownLabel matlab.ui.control.Label
        Single_DropDown_TextFormat matlab.ui.control.DropDown
        TextFormatLabel matlab.ui.control.Label
        Single_Export_UAN matlab.ui.control.Button
        Single_Button_ResetParams matlab.ui.control.Button
        Single_Export_Output matlab.ui.control.Button
        Single_Button_Coverage matlab.ui.control.Button
        Single_Button_Process matlab.ui.control.Button
        Single_DropDown_step matlab.ui.control.DropDown
        Single_DropDown_R matlab.ui.control.DropDown
        Single_Spinner_R matlab.ui.control.Spinner
        DistanceLabel matlab.ui.control.Label
        Single_Button_Load matlab.ui.control.Button
        Single_DropDown_Pt matlab.ui.control.DropDown
        Single_Spinner_Pt matlab.ui.control.Spinner
        TransmitPowerLabel matlab.ui.control.Label
        Single_Spinner_Loss matlab.ui.control.Spinner
        LossindBLabel matlab.ui.control.Label
        Single_Spinner_Rw matlab.ui.control.Spinner
        IncidentWaveARRwPLFLabel matlab.ui.control.Label
        Single_DropDown_RxPol matlab.ui.control.DropDown
        RxPolLabel matlab.ui.control.Label
        Single_EditField_Path matlab.ui.control.EditField
        InputPatternLabel matlab.ui.control.Label
        Single_StatusBar matlab.ui.control.Label
        Single_Panel_plotControl matlab.ui.container.Panel
        Single_gridPanel_Ctrl matlab.ui.container.GridLayout
        View3DLabel matlab.ui.control.Label
        Single_DropDown_3DView matlab.ui.control.DropDown
        Singel_CheckBox_overlayCut matlab.ui.control.CheckBox
        Single_CheckBox_POB matlab.ui.control.CheckBox
        Single_CheckBox_HPBWBounds matlab.ui.control.CheckBox
        Single_Switch_EHplane matlab.ui.control.Switch
        Single_Switch_AngularSpan matlab.ui.control.Switch
        Single_Switch_ThetaSpan matlab.ui.control.Switch
        CutvalueSpinnerLabel matlab.ui.control.Label
        Single_Label_Clim matlab.ui.control.Label
        Single_Button_Clim matlab.ui.control.Button
        Single_Plot_Cstep matlab.ui.control.Spinner
        ColorbarstepLabel matlab.ui.control.Label
        Single_Plot_Cmin matlab.ui.control.Spinner
        ColorbarminLabel matlab.ui.control.Label
        Single_Plot_Cmax matlab.ui.control.Spinner
        ColorbarmaxLabel matlab.ui.control.Label
        Single_DropDown_cutValue matlab.ui.control.Spinner
        Single_DropDown_cutType matlab.ui.control.DropDown
        CutFieldBasisDropDown matlab.ui.control.DropDown
        CuttypeDropDownLabel matlab.ui.control.Label
        Single_DropDown_Component matlab.ui.control.DropDown
        ComponentLabel matlab.ui.control.Label
        Single_tabData matlab.ui.container.TabGroup
        Single_tabDataOut matlab.ui.container.Tab
        Single_gridDataOut matlab.ui.container.GridLayout
        Single_Table_DataOut matlab.ui.control.Table
        Single_tabDataIn matlab.ui.container.Tab
        Single_gridDataIn matlab.ui.container.GridLayout
        Single_Table_DataIn matlab.ui.control.Table
        MetadataTab matlab.ui.container.Tab
        Single_gridMetadata matlab.ui.container.GridLayout
        Single_Table_metadata matlab.ui.control.Table
        Single_DropDown_output matlab.ui.control.DropDown
        Single_Panel_Rect matlab.ui.container.Panel
        Single_gridPanel_Cut matlab.ui.container.GridLayout
        Single_tabCut matlab.ui.container.TabGroup
        Single_tabPolarPlot matlab.ui.container.Tab
        Single_Grid_Polar matlab.ui.container.GridLayout
        Single_gridEcut matlab.ui.container.GridLayout
        CheckBox_Et matlab.ui.control.CheckBox
        CheckBox_Er matlab.ui.control.CheckBox
        CheckBox_El matlab.ui.control.CheckBox
        Button_ExportCut matlab.ui.control.Button
        Range_Cut_Max matlab.ui.control.Spinner
        Range_Cut_Min matlab.ui.control.Spinner
        Label_HPBW matlab.ui.control.Label
        Button_HPBW matlab.ui.control.StateButton
        Range_Cut matlab.ui.control.RangeSlider
        Single_tabRectPlot matlab.ui.container.Tab
        Single_gridRect matlab.ui.container.GridLayout
        Single_AxesRect matlab.ui.control.UIAxes
        Single_Panel_fullPattern matlab.ui.container.Panel
        Single_gridPanel_full matlab.ui.container.GridLayout
        Single_tabPlots matlab.ui.container.TabGroup
        Single_tabContour matlab.ui.container.Tab
        Single_gridContour matlab.ui.container.GridLayout
        Range_Ctr_Min matlab.ui.control.Spinner
        Range_Ctr_Max matlab.ui.control.Spinner
        Range_Ctr matlab.ui.control.RangeSlider
        Single_Axes_Ctr matlab.ui.control.UIAxes
        Single_tabCircular matlab.ui.container.Tab
        Single_gridCircular matlab.ui.container.GridLayout
        Range_Cir_Min matlab.ui.control.Spinner
        Range_Cir_Max matlab.ui.control.Spinner
        Range_Cir matlab.ui.control.RangeSlider
        Single_tab3DSpherical matlab.ui.container.Tab
        Single_grid3dSpherical matlab.ui.container.GridLayout
        Range_3dSph_Min matlab.ui.control.Spinner
        Range_3dSph_Max matlab.ui.control.Spinner
        Range_3dSph matlab.ui.control.RangeSlider
        Single_Axes_3dSph matlab.ui.control.UIAxes
        Single_tab3DPolar matlab.ui.container.Tab
        Single_grid3dPolar matlab.ui.container.GridLayout
        Range_3dPol_Min matlab.ui.control.Spinner
        Range_3dPol_Max matlab.ui.control.Spinner
        Range_3dPol matlab.ui.control.RangeSlider
        Single_Axes_3dPol matlab.ui.control.UIAxes
        Single_tab3DRect matlab.ui.container.Tab
        Single_grid3dRect matlab.ui.container.GridLayout
        Range_3dRect_Min matlab.ui.control.Spinner
        Range_3dRect_Max matlab.ui.control.Spinner
        Range_3dRect matlab.ui.control.RangeSlider
        Single_Axes_3dRect matlab.ui.control.UIAxes
        Tab2_Coverage matlab.ui.container.Tab
        Cov_Grid matlab.ui.container.GridLayout
        Cov_Panel_Results matlab.ui.container.Panel
        GridLayout2 matlab.ui.container.GridLayout
        Cov_Spinner_XMin matlab.ui.control.Spinner
        Cov_Spinner_XMax matlab.ui.control.Spinner
        Cov_Spinner_XRange matlab.ui.control.RangeSlider
        Cov_Tabel matlab.ui.control.Table
        Cov_Tree matlab.ui.container.CheckBoxTree
        Cov_TreeNode_Results matlab.ui.container.TreeNode
        Cov_Axes matlab.ui.control.UIAxes
        Cov_StatusBar matlab.ui.control.Label
        Cov_Panel_Param matlab.ui.container.Panel
        Cov_gridPanel_Parm matlab.ui.container.GridLayout
        Cov_DropDown_OrientationLabel matlab.ui.control.Label
        Cov_DropDown_TextFormat matlab.ui.control.DropDown
        Cov_TextFormatLabel matlab.ui.control.Label
        Cov_Button_queryThresh matlab.ui.control.Button
        Cov_Button_queryCov matlab.ui.control.Button
        Cov_DropDown_Component matlab.ui.control.DropDown
        Cov_DropDown_ComponentLabel matlab.ui.control.Label
        Cov_Spinner_queryThresh matlab.ui.control.Spinner
        Cov_QueryThresholdLabel matlab.ui.control.Label
        Cov_Spinner_queryCov matlab.ui.control.Spinner
        Cov_QueryCoverageLabel matlab.ui.control.Label
        Cov_Button_toMain matlab.ui.control.Button
        Cov_Button_Clear matlab.ui.control.Button
        Cov_Spinner_ConeAng matlab.ui.control.Spinner
        ConeAngleLabel matlab.ui.control.Label
        Cov_Spinner_ConePH matlab.ui.control.Spinner
        ConeLabel matlab.ui.control.Label
        Cov_Spinner_ConeTH matlab.ui.control.Spinner
        ConeSpinnerLabel matlab.ui.control.Label
        Cov_Spinner_Step matlab.ui.control.Spinner
        StepdBSpinnerLabel matlab.ui.control.Label
        Cov_Spinner_ThreshMax matlab.ui.control.Spinner
        ThresholdMaxdBSpinnerLabel matlab.ui.control.Label
        Cov_Spinner_ThreshMin matlab.ui.control.Spinner
        ThresholdMindBSpinnerLabel matlab.ui.control.Label
        Cov_Button_Export matlab.ui.control.Button
        Cov_Button_Reset matlab.ui.control.Button
        Cov_Button_computeCov matlab.ui.control.Button
        Cov_Button_Load matlab.ui.control.Button
        Cov_EditField_filePath matlab.ui.control.EditField
        AntennaPatternEditFieldLabel matlab.ui.control.Label
        Cov_DropDown_Orientation matlab.ui.control.DropDown
        Cov_ButtonGroup_CovType matlab.ui.container.ButtonGroup
        Cov_ButtonGroup_Btn_Conical matlab.ui.control.RadioButton
        Cov_ButtonGroup_Btn_Spherical matlab.ui.control.RadioButton

    end


    properties (Access = private)
        % file info
        fileName char = '' % name.ext of loaded file
        filePath char = '' % full path of loaded file
        folderPath char = '' % folder of loaded file
        baseName char = '' % name (no extension)

        % data pipeline
        rawTbl table % original data as found in the file (input format)
        stdTbl table % standardized/normalized standard E-field table / gain table
        patTbl table % processed results (full resolution)
        viewTbl table % Display/export view using selected phi span
        viewBaseTbl table % Canonical 0°...360° processed/resampled view
        uanTbl table % UAN E-fields export table
        ffdBlocks cell = {} % one std table per FFD frequency block
        freqs double = NaN % FFD block frequencies (Hz)
        srcUD struct % source metadata (set by readFile)
        gridCache struct = struct() % Split grid topology + component-data cache
        viewRevision uint64 = uint64(0) % Display/view-state revision

        % metadata
        step double = 1 % native angular step (deg)
        POB double = NaN % peak-of-beam gain (dB)
        POBth double = NaN % POB theta (deg)
        POBph double = NaN % POB phi (deg)
        polLabel char = 'n/a' % dominant polarization
        polPairs struct = struct('Linear', ["E_TH", "E_PH"], 'Circular', ["E_RCP", "E_LCP"]) % computed co/cross ordering
        boresightIndex double = 1 % index into immutable PrincipalAxes
        antennaMetrics struct = struct() % Latest advanced antenna metrics
        defaultParams struct = struct() % Startup parameter defaults

        % plot helpers
        Single_paxCut matlab.graphics.axis.PolarAxes % polar cut axes
        Single_paxPattern matlab.graphics.axis.PolarAxes % polar contour-plot axes
        cutLim double = [-55, 25]; % Range & Min/Max Spinners Limits
        ctrLim double = [-55, 25] % Current full-pattern gain display range
        gainLim double = [-55, 25] % Authoritative non-AR color scale preserved across components

        % coverage state
        covRunID double = 0 % incremental coverage job id
        covJobs cell = {} % Authoritative job-node registry; tree is only the view
        CoverageQueryControls % labels, spinners, and buttons controlled together

        viewSolidAngle double = [] % Cached dOmega vector for boresight and metrics
        rawShown logical = false % Avoid unchanged input-table assignment
        AnnotationSources cell = {} % Source-owned cut/HPBW annotation records
        FullPatternPOBRecords cell = cell(1, 5) % Persistent POB metadata/handles, one record per full-pattern tab.

        operationDialog = [] % Active cancelable operation dialog, when present
        statusTimer = [] % One-shot timer for the currently active transient status
        peakInfo struct = struct() % Last resolved peak policy/result
        coverageRangeState struct = struct('syncing',false,'presetting',false, ...
            'presetKey',"",'presetInitialized',false,'userEdited',false, ...
            'lastPreset',[-40 10],'evaluationBounds',[-40 10], ...
            'displayBounds',[-40 10],'plotInitialized',false) % Single authoritative coverage-range state

        perfTracker = @(~) [] % Lightweight stage recorder; no-op when idle
        OutputFilterStyles cell = cell(0,1) % Instance-owned table filter styles
    end

    properties (Constant, Access = private)
        PrincipalAxes = struct('labels', {{'+Z','-Z','+X','-X','+Y','-Y'}}, 'theta', [0,180,90,90,90,90], 'phi', [0,0,0,180,90,270]) % right-handed [polar theta, phi]
        StandardColumns = {'Theta','Phi','Re_Eth','Im_Eth','Re_Eph','Im_Eph'}
        HiddenOutputColumns = {'E_TH_dB','E_PH_dB','E_TH_Phase','E_PH_Phase','E_RCP_Phase','E_LCP_Phase','EIRP_dBW','PFD_Wm2','E_RMS_Vm'}
        PeakPercentile = 99.99
        PeakMaxExcessDB = 6
        DistanceFloorM = 1e-12
        ReleaseName = 'APAT v3 Milestone 7.110_5'
        ReleaseVersion = '3.0-M7.110_5'
    end

    methods (Access = public)
        function isGeneric = isGenericTextFile(~, filePath)
            [~, ~, extension] = fileparts(filePath); isGeneric = ismember(lower(extension), {'.csv', '.txt', '.dat'});
        end

        function isMatrix = isExcelMatrixFile(~, filePath)
            [~,~,extension] = fileparts(filePath);
            isMatrix = strcmpi(extension,'.xlsx') || strcmpi(extension,'.xls');
        end

        function sourceData = prepareTextFormat(app, filePath, label, dropdown)
            % Generic text files expose the existing format selector. Excel
            % matrix workbooks are self-describing and therefore do not use it.
            if app.isExcelMatrixFile(filePath)
                set([label, dropdown], 'Visible', 'off');
                sourceData = app.readFile(filePath, "excelmatrix");
                return
            end
            if ~app.isGenericTextFile(filePath)
                set([label, dropdown], 'Visible', 'off');
                sourceData = app.readFile(filePath, dropdown.Value);
                return
            end

            sourceData = app.readFile(filePath, "gain");
            if sourceData.userData.isCoverage
                set([label, dropdown], 'Visible', 'off');
                return
            end

            dropdown.Value = 'gain';
            set([label, dropdown], 'Visible', 'on');
        end

        function out = readFile(~, fp, textFormat, tableData)
            % I/O boundary for source parsing.
            if nargin < 4, tableData = table(); end
            out = readPattern(fp, textFormat, tableData);
            out.userData = validateSourceModel(out.userData);
        end

        function [standard, pattern] = buildPatternData(app, sourceData)
            % Build an auxiliary pattern without mutating the active Main view/state.
            standard = normalizePattern(sourceData.blocks{1});
            standard.Properties.UserData = sourceData.userData;
            pattern = calcPattern(standard, app.getParam(), app.PeakPercentile, app.PeakMaxExcessDB);
        end

        function activateSource(app, sourceData)
            [app.rawTbl, app.ffdBlocks, app.freqs, app.srcUD] = deal(sourceData.rawTbl, sourceData.blocks, sourceData.freqs, sourceData.userData);
            app.rawShown = false;
            app.selectBlock(1);
        end

        function selectBlock(app, blockIndex)
            blockTable = app.ffdBlocks{blockIndex};
            if app.srcUD.isDep, app.rawTbl = blockTable; app.rawShown = false; end
            standardTable = normalizePattern(blockTable);
            standardTable.Properties.UserData = app.srcUD;
            app.stdTbl = standardTable;
        end

        function refresh(app)
            [app.patTbl, info] = calcPattern(app.stdTbl, app.getParam(), app.PeakPercentile, app.PeakMaxExcessDB);
            app.perfTracker("Process pattern");
            app.checkCancelled();

            [app.polLabel, app.polPairs] = deal(info.pol, info.pairs);
            if isequal(app.CutFieldBasisDropDown.UserData, true) && ~app.srcUD.isGainOnly
                if ismember(info.pol, {'Linear (Vertical)','Linear (Horizontal)'}), app.CutFieldBasisDropDown.Value = 'Linear'; else, app.CutFieldBasisDropDown.Value = 'Circular'; end
            end

            preserveOneDegree = isequal(app.Single_DropDown_step.UserData, true);

            thetaStep = gridStep(app.patTbl.Theta);
            phiStep = gridStep(mod(app.patTbl.Phi, 360));
            if ~isfinite(thetaStep), thetaStep = 1; end
            if ~isfinite(phiStep), phiStep = thetaStep; end

            app.step = max(thetaStep, phiStep);
            orig = sprintf('STEP: %g%c', app.step, char(176));
            oneDegree = ['STEP: 1' char(176)];
            app.Single_DropDown_step.Items = {orig, oneDegree};
            app.Single_DropDown_step.Value = orig;

            nonCanonical = abs(thetaStep - 1) > 1e-9 || abs(phiStep - 1) > 1e-9;
            if preserveOneDegree && nonCanonical
                app.Single_DropDown_step.Value = oneDegree;
            end

            app.Single_DropDown_step.UserData = false;
            app.Single_DropDown_step.Visible = nonCanonical;
            app.Single_DropDown_step.Enable = nonCanonical;
            app.Single_DropDown_cutValue.Step = max(thetaStep, 1);
            app.applyStep();
            app.updateComponentItems();
            app.perfTracker("Prepare view");
            app.checkCancelled();

            app.updateViewResults(true, [], false, false);
            app.perfTracker("Populate tables and ranges");
            app.checkCancelled();

            app.Single_Switch_EHplaneValueChanged(); % Preserve the fast initial E/H-cut path.
            drawnow limitrate
            app.renderAllFullPatterns();
            app.perfTracker("Build plots");

            set([app.Single_Panel_Rect, app.Single_Export_Output, app.Single_Panel_fullPattern, app.Single_Panel_plotControl], 'Visible', 'on');
            app.Single_Button_Coverage.Visible = 'on';
            app.updateInputVisibility();

            hasEField = ~app.srcUD.isGainOnly;
            app.Single_Export_UAN.Visible = hasEField;
            app.Single_gridEcut.Visible = hasEField;
            app.CheckBox_Et.Visible = hasEField;
            app.CheckBox_Er.Visible = hasEField;
            app.CheckBox_El.Visible = hasEField;
            app.CheckBox_Er.Enable = hasEField;
            app.CheckBox_El.Enable = hasEField;
            app.CutFieldBasisDropDown.Enable = hasEField;
            if app.srcUD.isGainOnly || isempty(strtrim(app.polLabel)) || strcmpi(strtrim(app.polLabel), 'n/a')
                statusText = sprintf( ...
                    'Pattern: <b>%s</b> | POB <b>%s dB</b> (<b>&theta;=%s&deg;, &phi;=%s&deg;</b>)', ...
                    app.fileName, app.fmtNumber(app.POB, 2), app.fmtStatusAngle(app.POBth), app.fmtStatusAngle(app.POBph));
            else
                statusText = sprintf( ...
                    'Pattern: <b>%s</b> | POB <b>%s dB</b> (<b>&theta;=%s&deg;, &phi;=%s&deg;</b>) | Polarization <b>%s</b>', ...
                    app.fileName, app.fmtNumber(app.POB, 2), app.fmtStatusAngle(app.POBth), app.fmtStatusAngle(app.POBph), app.polLabel);
            end
            app.setStatus(app.Single_StatusBar, statusText, false);
        end

        function param = getParam(app)
            param = struct('GainLoss_dB', app.Single_Spinner_Loss.Value, 'RxMode', string(app.Single_DropDown_RxPol.Value), 'RxAR_dB', app.Single_Spinner_Rw.Value);
            param.FieldScale = 10 .^ (param.GainLoss_dB / 20); % Incident wave field scale.

            power = app.Single_Spinner_Pt.Value; powerUnit = app.Single_DropDown_Pt.Value;
            if strcmp(powerUnit, 'dBm'), param.Pt_dBW = power - 30; elseif strcmp(powerUnit, 'Watts'), param.Pt_dBW = 10 * log10(max(power, eps)); else, param.Pt_dBW = power; end % dBW/unknown values are already logarithmic.

            param.R_m = max(app.Single_Spinner_R.Value, app.DistanceFloorM); if strcmp(app.Single_DropDown_R.Value, 'km'), param.R_m = 1000 * param.R_m; end % Distance in meters.
        end

        function [solidAngle, peakInfo, axisIndex] = detectOrientation(app, patternData, solidAngle, requestedColumn)
            % Application-layer wrapper.  The app method always receives APP;
            % the pure numerical service never receives APP.
            if nargin < 3 || isempty(solidAngle)
                solidAngle = [];
            end
            if nargin < 4 || isempty(requestedColumn)
                requestedColumn = "E_Total_dB";
            end
            [solidAngle, peakInfo, axisIndex] = calcOrientation( ...
                patternData, solidAngle, requestedColumn, app.PrincipalAxes, app.PeakPercentile, app.PeakMaxExcessDB);
        end

        function applyStep(app)
            % M6: resample the canonical source representation, then recompute
            % all derived quantities. This prevents interpolation of nonlinear
            % outputs such as gain, AR and PLF.
            sourceTable = app.stdTbl;
            useOneDegree = strcmp(app.Single_DropDown_step.Value, ['STEP: 1' char(176)]);

            thetaStep = gridStep(sourceTable.Theta);
            phiStep = gridStep(mod(sourceTable.Phi, 360));
            needsResample = (~isfinite(thetaStep) || abs(thetaStep - 1) > 1e-9) || ...
                (~isfinite(phiStep) || abs(phiStep - 1) > 1e-9);

            if useOneDegree && needsResample
                if isfinite(thetaStep) && isfinite(phiStep) && thetaStep < 1 && phiStep < 1
                    integerSamples = abs(sourceTable.Theta - round(sourceTable.Theta)) < 1e-9 & ...
                        abs(sourceTable.Phi - round(sourceTable.Phi)) < 1e-9;
                    sourceTable = sourceTable(integerSamples, :);
                else
                    sourceTable = resampleCanonical(sourceTable, 1, 'LinearPowerForGain', true, 'PeriodicPhi', true);
                end
            end

            sourceTable.Properties.UserData = app.stdTbl.Properties.UserData;
            if height(sourceTable) ~= height(app.stdTbl) || ~isequal(sourceTable{:,1:min(width(sourceTable),2)}, app.stdTbl{:,1:min(width(app.stdTbl),2)})
                [app.viewBaseTbl, ~] = calcPattern(sourceTable, app.getParam(), app.PeakPercentile, app.PeakMaxExcessDB);
            else
                app.viewBaseTbl = app.patTbl;
            end
            app.applyAngularSpan();
        end

        function applyAngularSpan(app)
            % Keep one canonical table and materialize only the display convention.
            tableData = app.viewBaseTbl;
            signedPhi = strcmp(app.Single_Switch_AngularSpan.Value, '-180° to 180°');
            elevationTheta = strcmp(app.Single_Switch_ThetaSpan.Value, '-90° to 90°');
            if signedPhi
                tableData(abs(tableData.Phi - 360) <= 1e-9,:) = [];
                mask = tableData.Phi > 180; tableData.Phi(mask) = tableData.Phi(mask) - 360;
                seam = abs(tableData.Phi - 180) < 1e-9;
                if any(seam)
                    duplicate = tableData(seam,:); duplicate.Phi(:) = -180;
                    tableData = [duplicate; tableData];
                end
            end
            if elevationTheta, tableData.Theta = 90 - tableData.Theta; end
            userData = tableData.Properties.UserData; if ~isstruct(userData), userData = struct(); end
            if elevationTheta, userData.thetaMode='elevation'; else, userData.thetaMode='polar'; end; tableData.Properties.UserData=userData;
            if signedPhi || elevationTheta, tableData = sortrows(tableData, {'Phi','Theta'}); end
            app.viewTbl = tableData; app.uanTbl = table(); app.viewSolidAngle = [];
            app.viewRevision = app.viewRevision + 1; app.invalidateDerived();
        end

        function [phiLimits, thetaLimits, thetaDirection] = angularLimits(app)
            % Return display limits and theta-axis direction for active conventions.
            signedPhi = strcmp(app.Single_Switch_AngularSpan.Value, '-180° to 180°');
            elevation = strcmp(app.Single_Switch_ThetaSpan.Value, '-90° to 90°');
            if signedPhi, phiLimits = [-180, 180]; else, phiLimits = [0, 360]; end
            if elevation, thetaLimits = [-90, 90]; thetaDirection = 'normal';
            else, thetaLimits = [0, 180]; thetaDirection = 'reverse'; end
        end

        function formatAngularAxes(app, axesHandle, phiStep, thetaStep)
            % Apply the active phi/theta convention to rectangular angular axes.
            [phiLimits, thetaLimits, thetaDirection] = app.angularLimits();
            xlim(axesHandle, phiLimits);
            ylim(axesHandle, thetaLimits);
            set(axesHandle, 'YDir', thetaDirection, 'Box', 'on', 'Layer', 'top');
            axesHandle.XTick = phiLimits(1):phiStep:phiLimits(2);
            axesHandle.YTick = thetaLimits(1):thetaStep:thetaLimits(2);
        end

        function theta = physicalTheta(~, tableData)
            % Return physical polar theta regardless of the active display convention.
            theta = tableData.Theta;
            userData = tableData.Properties.UserData;
            if isstruct(userData) && isfield(userData, 'thetaMode') && strcmp(userData.thetaMode, 'elevation')
                theta = 90 - theta;
            end
        end

        function setPolarSpanTicks(app, polarAxes)
            % Keep polar geometry physical while reflecting the selected phi labels.
            angles = 0:30:330;
            if strcmp(app.Single_Switch_AngularSpan.Value, '-180° to 180°')
                angles(angles > 180) = angles(angles > 180) - 360;
            end
            polarAxes.ThetaTick = 0:30:330;
            polarAxes.ThetaTickLabel = compose('%d°', angles);
        end

        function [theta, phi, componentGrid] = gridComp(app, tableData, columnName)
            cache = app.gridCache;
            valid = isfield(cache,'topology') && cache.topology.valid && ...
                cache.topology.viewRevision == app.viewRevision && ...
                cache.topology.n == height(tableData);
            if ~valid
                theta = unique(tableData.Theta); phi = unique(tableData.Phi);
                [~, ti] = ismember(tableData.Theta, theta);
                [~, pi] = ismember(tableData.Phi, phi);
                sz = [numel(theta), numel(phi)];
                cache = struct('topology',struct('valid',true,'n',height(tableData), ...
                    'theta',theta,'phi',phi,'linearIndex',sub2ind(sz,ti,pi), ...
                    'sz',sz,'viewRevision',app.viewRevision,'geom',struct()), 'components',struct());
            end
            topology = cache.topology; theta = topology.theta; phi = topology.phi;
            key = matlab.lang.makeValidName(columnName);
            if isfield(cache.components,key), componentGrid = cache.components.(key); return; end
            componentGrid = nan(topology.sz);
            componentGrid(topology.linearIndex) = tableData.(columnName);
            cache.components.(key) = componentGrid; app.gridCache = cache;
        end

        function geometry = gridGeom(app)
            cache = app.gridCache;
            if ~isfield(cache,'topology') || ~cache.topology.valid, geometry = struct(); return; end
            topology = cache.topology;
            isElevation = strcmp(app.Single_Switch_ThetaSpan.Value, '-90° to 90°');
            if ~isfield(topology.geom,'phiGrid')
                [phiGrid, thetaGrid] = meshgrid(topology.phi, topology.theta);
                thetaPolar = thetaGrid; if isElevation, thetaPolar = 90 - thetaGrid; end
                phiRad = deg2rad(phiGrid); sinTheta = sind(thetaPolar);
                topology.geom = struct('phiGrid',phiGrid,'thetaGrid',thetaGrid, ...
                    'thetaPolar',thetaPolar,'phiRad',phiRad, ...
                    'xCoord',sinTheta.*cos(phiRad),'yCoord',sinTheta.*sin(phiRad), 'zCoord',cosd(thetaPolar));
                cache.topology = topology; app.gridCache = cache;
            end
            geometry = topology.geom;
        end

        function invalidateDerived(app)
            app.gridCache = struct(); app.viewSolidAngle = []; app.antennaMetrics = struct();
        end

        function [columns, labels] = componentMap(~, tableData)
            % Return canonical component keys and their user-facing labels.
            available = string(tableData.Properties.VariableNames(3:end));
            if tableData.Properties.UserData.isGainOnly, [columns, labels] = deal(available); return; end

            [columns, labels] = deal(["E_Total_dB", "E_TH_dB", "E_PH_dB", "E_RCP_dB", "E_LCP_dB", "AR_dB", "Gain_PolCorrected_dB"], ...
                ["Total Gain", "Etheta Gain", "Ephi Gain", "RHCP Gain", "LHCP Gain", "Axial Ratio", "Polarized Gain"]);
            present = ismember(columns, available); [columns, labels] = deal(columns(present), labels(present));
        end

        function component = preferredComponent(~, previous, columns)
            if any(columns == string(previous)), component = string(previous); elseif any(columns == "E_Total_dB"), component = "E_Total_dB"; else, component = columns(1); end, component = char(component);
        end
        function updateComponentItems(app)
            [columns, labels] = app.componentMap(app.viewTbl);
            dropdown = app.Single_DropDown_Component;
            previousValue = string(dropdown.Value);

            [dropdown.Items, dropdown.ItemsData] = deal(cellstr(labels), cellstr(columns));
            if isempty(columns), return; end
            dropdown.Value = app.preferredComponent(previousValue, columns);
        end

        function component = comp(app)
            component = app.Single_DropDown_Component.Value; % Main-pattern component only
        end

        function updateSelectedComponentPeak(app, peak)
            if isempty(app.viewTbl) || ~ismember(app.comp(), app.viewTbl.Properties.VariableNames)
                app.peakInfo = struct(); app.POB = NaN; app.POBth = NaN; app.POBph = NaN; return
            end
            if nargin < 2 || isempty(peak)
                peak = resolvePeak(app.viewTbl.(app.comp()), app.PeakPercentile, app.PeakMaxExcessDB, app.viewTbl.Theta, app.viewTbl.Phi);
            end
            app.peakInfo = peak; app.POB = peak.value;
            if isfinite(peak.index) && peak.index >= 1 && peak.index <= height(app.viewTbl)
                app.POBth = app.physicalTheta(app.viewTbl(peak.index,:));
                app.POBph = mod(app.viewTbl.Phi(peak.index),360);
            else
                app.POBth = NaN; app.POBph = NaN;
            end
        end

        function label = compLabel(app)
            dropdown = app.Single_DropDown_Component; index = find(strcmp(dropdown.ItemsData, dropdown.Value), 1);
            if isempty(index), label = strrep(string(dropdown.Value),'_',' '); else, label = string(dropdown.Items{index}); end
        end

        function updateTables(app)
            tableData = app.viewTbl; dropdown = app.Single_DropDown_output;
            newColumns = tableData.Properties.VariableNames; filterColumns = newColumns(3:end);
            schemaChanged = ~isequal(regexprep(dropdown.Items(2:end), '^✓ ?', ''), filterColumns); sourceChanged = ~app.rawShown;

            if ~app.rawShown
                [app.Single_Table_DataIn.Data, app.Single_Table_DataIn.ColumnName, app.Single_Table_DataIn.Visible, app.rawShown] = ...
                    deal(app.rawTbl, app.rawTbl.Properties.VariableNames, 'on', true);
            end

            if schemaChanged
                [dropdown.Items, dropdown.ItemsData] = deal([{'--- column filter ---'}, filterColumns], 0:numel(filterColumns));
                dropdown.UserData = ~ismember(filterColumns, app.HiddenOutputColumns);
                dropdown.Value = 0;
                set([dropdown, app.Single_Table_DataOut, app.Single_tabData], 'Visible', 'on');
            end

            app.filterOutput([], schemaChanged, schemaChanged || sourceChanged);
        end

        function updateInputVisibility(app)
            columns = app.viewTbl.Properties.VariableNames(3:end); selected = string(columns(app.Single_DropDown_output.UserData));
            showRx = any(ismember(selected, ["PLF_dB","Gain_PolCorrected_dB"]));
            showTx = any(ismember(selected, ["EIRP_dBW","PFD_Wm2","E_RMS_Vm"]));
            showDistance = any(ismember(selected, ["PFD_Wm2","E_RMS_Vm"]));
            showLoss = app.srcUD.isGainOnly || any(ismember(selected, ...
                ["E_Total_dB","E_TH_dB","E_PH_dB","E_RCP_dB","E_LCP_dB", "Gain_PolCorrected_dB","EIRP_dBW","PFD_Wm2","E_RMS_Vm"]));

            set([app.RxPolLabel, app.Single_DropDown_RxPol, app.IncidentWaveARRwPLFLabel, app.Single_Spinner_Rw], 'Visible', showRx);
            set([app.TransmitPowerLabel, app.Single_Spinner_Pt, app.Single_DropDown_Pt], 'Visible', showTx);
            set([app.DistanceLabel, app.Single_Spinner_R, app.Single_DropDown_R], 'Visible', showDistance);
            set([app.LossindBLabel, app.Single_Spinner_Loss], 'Visible', showLoss);
        end

        function metrics = computeMetrics(app, peakInfo)
            if isempty(app.viewTbl), metrics = struct(); return; end
            if nargin < 2 || isempty(peakInfo)
                [gainValues, ~] = chooseGain(app.viewTbl, app.comp(), 'E_Total_dB');
                peakInfo = resolvePeak(gainValues, app.PeakPercentile, app.PeakMaxExcessDB);
            end
            principal = app.PrincipalAxes; principal.index = app.boresightIndex;
            metrics = calcMetrics(app.viewTbl, peakInfo, app.viewSolidAngle, principal, app.Single_Switch_ThetaSpan.Value, app.PeakPercentile, app.PeakMaxExcessDB);
        end

        function [cutType, cutValue] = planeSettings(app, isEPlane)
            % Lookup matches the interactive E/H-plane definitions for every principal axis.
            axesDef = app.PrincipalAxes; axisIndex = app.boresightIndex;
            cutType = 'Theta';
            if isEPlane, cutValue = axesDef.phi(axisIndex); return; end
            isTransverse = axesDef.theta(axisIndex) == 90; cutValue = 90;
            if isTransverse, cutType = 'Phi'; end
            if isTransverse && strcmp(app.Single_Switch_ThetaSpan.Value, '-90° to 90°'), cutValue = 0; end % Polar theta=90° is elevation=0°.
        end

        function values = updateCutControl(app)
            % Cut value means fixed theta for Phi and fixed phi for Theta.
            if strcmp(app.Single_DropDown_cutType.Value, 'Phi')
                values = unique(app.viewTbl.Theta);
            else
                values = unique(mod(app.viewTbl.Phi, 360));
            end
            if isempty(values), return; end
            app.Single_DropDown_cutValue.Limits = [min(values), max(values)];
            if numel(values)>1, app.Single_DropDown_cutValue.Step = min(diff(values)); end
            [~, nearest] = min(abs(values-app.Single_DropDown_cutValue.Value));
            app.Single_DropDown_cutValue.Value = values(nearest);
        end

        function [angleDeg, rows, fixedAngle, fixedSymbol, didSnap, requestedAngle] = ...
                cutGeometry(app, tableData, cutType, requestedAngle)
            % Resolve one snapped full-circle cut and its ordered source rows.
            if strcmp(cutType, 'Phi')
                thetaValues = unique(tableData.Theta);
                [snapDistance, snapIndex] = min(abs(thetaValues - requestedAngle));
                fixedAngle = thetaValues(snapIndex);
                rows = find(abs(tableData.Theta - fixedAngle) < 1e-9);
                [angleDeg, order] = sort(tableData.Phi(rows));
                rows = rows(order);
                fixedSymbol = 'θ';
            else
                requestedAngle = mod(requestedAngle, 360);
                phiValues = unique(mod(tableData.Phi, 360));
                [snapDistance, firstIndex] = min(abs(mod(phiValues - requestedAngle + 180, 360) - 180));
                [~, oppositeIndex] = min(abs(mod(phiValues - phiValues(firstIndex), 360) - 180));
                fixedAngle = phiValues(firstIndex);
                wrappedPhi = mod(tableData.Phi, 360);
                physicalTheta = app.physicalTheta(tableData);
                primaryRows = find(abs(wrappedPhi - fixedAngle) < 1e-9);
                oppositeRows = find(abs(wrappedPhi - phiValues(oppositeIndex)) < 1e-9 & abs(physicalTheta - 180) > 1e-9);
                [~, primaryOrder] = sort(physicalTheta(primaryRows));
                [~, oppositeOrder] = sort(physicalTheta(oppositeRows), 'descend');
                primaryRows = primaryRows(primaryOrder);
                oppositeRows = oppositeRows(oppositeOrder);
                rows = [primaryRows; oppositeRows];
                angleDeg = [physicalTheta(primaryRows); 360 - physicalTheta(oppositeRows)];
                fixedSymbol = 'φ';
            end
            didSnap = snapDistance > 0;
        end

        function text = fmtNumber(~, value, precision)
            %FMTNUMBER Format a numeric value with optional decimal precision.
            %   fmtNumber(value) uses compact metadata formatting (up to 2 decimals).
            %   fmtNumber(value,N) uses exactly N decimal places, where N is 0..5.
            compact = (nargin < 3 || isempty(precision));
            if compact
                precision = 2;
            else
                precision = max(0, min(5, round(double(precision))));
            end
            if ~isscalar(value) || ~isnumeric(value) || ~isfinite(value)
                text = 'n/a';
                return
            end
            text = sprintf(sprintf('%%.%df', precision), value);
            if compact && precision > 0
                % Compact mode removes insignificant trailing zeros AND a
                % possible decimal point.  Explicit precision intentionally
                % preserves the requested number of decimal places.
                text = regexprep(text, '([.]\d*?[1-9])0+$', '$1');
                text = regexprep(text, '0+$', '');
                text = regexprep(text, '\.$', '');
            end
        end

        function text = fmtStatusAngle(app, value)
            % Status-bar POB coordinates: compact numeric formatting.
            % Integers are shown without a decimal part; non-integers use
            % the same two-decimal policy as the metadata table.
            if isfinite(value)
                text = app.fmtNumber(value);
            else
                text = 'n/a';
            end
        end

        function updateMetadata(app)
            tableData = app.viewTbl; hasMetrics = isfield(app.antennaMetrics, 'PeakGain_dB');
            [theta, phi] = deal(unique(tableData.Theta), unique(tableData.Phi));
            [thetaStep, phiStep] = deal(NaN); if numel(theta) > 1, thetaStep = min(diff(theta)); end, if numel(phi) > 1, phiStep = min(diff(phi)); end

            [peakGain, peakTheta, peakPhi] = deal(app.POB, app.POBth, app.POBph);
            if hasMetrics, [peakGain, peakTheta, peakPhi] = deal(app.antennaMetrics.PeakGain_dB, app.antennaMetrics.PeakTheta_deg, app.antennaMetrics.PeakPhi_deg); end


            rows = {
                'Source format', app.srcUD.source
                'File', app.fileName
                'Samples', sprintf('%d samples  (θ: %d × φ: %d)', height(tableData), numel(theta), numel(phi))
                'θ range / step', sprintf('[%s°, %s°] / %s°', app.fmtNumber(min(theta)), app.fmtNumber(max(theta)), app.fmtNumber(thetaStep))
                'φ range / step', sprintf('[%s°, %s°] / %s°', app.fmtNumber(min(phi)), app.fmtNumber(max(phi)), app.fmtNumber(phiStep))};

            validFrequency = app.freqs(isfinite(app.freqs));
            if ~isempty(validFrequency)
                rows = [rows; {'Frequencies', strjoin(compose('%.4g GHz', validFrequency/1e9),', ')}];
            end

            if ~app.srcUD.isGainOnly && ~isempty(strtrim(app.polLabel)) && ~strcmpi(strtrim(app.polLabel), 'n/a')
                rows = [rows; {'Polarization', app.polLabel}];
            end

            if ~app.srcUD.isGainOnly
                pair = app.polPairs.(app.CutFieldBasisDropDown.Value);
                rows = [rows; {'Cut Co-pol / Cross-pol', char(strjoin(pair, ' / '))}];
            end

            rows = [rows; {
                'Peak gain (POB)', sprintf('%s dB', app.fmtNumber(peakGain))
                'POB direction [θ, φ]', sprintf('[%s°, %s°]', app.fmtNumber(peakTheta), app.fmtNumber(peakPhi))
                'Boresight axis', app.PrincipalAxes.labels{app.boresightIndex}}];
            if ~isempty(fieldnames(app.peakInfo))
                policy = sprintf('P%.4g, max excess %.4g dB', app.PeakPercentile, app.PeakMaxExcessDB);
                adjusted = app.peakInfo.wasAdjusted;
                rows = [rows; {'Peak policy', policy; 'Peak adjusted', char(string(adjusted))}];
            end
            if hasMetrics
                metrics = app.antennaMetrics;
                metricRows = {
                    'HPBW E-plane', sprintf('%s°', app.fmtNumber(metrics.HPBW_EPlane_deg))
                    'HPBW H-plane', sprintf('%s°', app.fmtNumber(metrics.HPBW_HPlane_deg))
                    'Front-to-back', sprintf('%s dB', app.fmtNumber(metrics.FrontBack_dB))
                    'Peak directivity', sprintf('%s dB', app.fmtNumber(metrics.PeakDirectivity_dB))};
                if isfinite(metrics.Efficiency_pct)
                    metricRows = [metricRows; {'Radiation efficiency', sprintf('%s%%', app.fmtNumber(metrics.Efficiency_pct))}];
                end
                rows = [rows; metricRows];

                if isfinite(metrics.AxialRatioAtPeak_dB)
                    rows = [rows; {'AR at peak', sprintf('%s dB', app.fmtNumber(metrics.AxialRatioAtPeak_dB))}];
                end
            end

            app.Single_Table_metadata.Data = rows;
        end

        function [limits, map] = plotTheme(app, ~)
            %PLOTTHEME Resolve the color scale and colormap for the selected component.
            % Signed axial ratio always uses the dedicated -30/+30 dB display
            % range and blue-white-red thermometer-style map. Gain-like data use
            % the requested range with the standard jet map.
            persistent gainMap arMap

            if isempty(gainMap)
                gainMap = jet(256);
                arMap = app.makeARColormap();
            end

            if app.isARComponent(app.comp()),  limits = [-30, 30];   map = arMap;
            else,                              limits = app.gainLim; map = gainMap;
            end
        end
        
        function applyPlotTheme(app, axesHandle, limits, colorMap)
            clim(axesHandle, limits);
            colormap(axesHandle, colorMap);
            colorbarHandle = colorbar(axesHandle);
            app.applyColorbarTicks(colorbarHandle, limits);
        end

        function ticks = makeAxisTicks(~, limits, step)
            limits = double(limits(:).');
            step = double(step);
            if numel(limits) ~= 2 || any(~isfinite(limits)) || ~isfinite(step) || step <= 0 || limits(1) >= limits(2)
                ticks = [];
                return
            end
            firstTick = ceil(limits(1) / step) * step;
            lastTick = floor(limits(2) / step) * step;
            ticks = firstTick:step:lastTick;
            ticks = unique([limits(1), ticks, limits(2)], 'stable');
            if numel(ticks) > 60, ticks = []; end
        end

        function applyColorbarTicks(app, colorbarHandle, limits)
            if isempty(app.Single_Plot_Cstep) || ~isvalid(app.Single_Plot_Cstep)
                return
            end
            tickStep = double(app.Single_Plot_Cstep.Value);
            if ~isfinite(tickStep) || tickStep <= 0 || diff(limits) <= 0
                return
            end
            ticks = app.makeAxisTicks(limits, tickStep);
            if ~isempty(ticks), colorbarHandle.Ticks = ticks; end
        end

        function initRanges(app)
            % Total Gain owns the non-AR scale; preserve it across component/cut changes.
            if app.isARComponent(app.comp())
                requested = [-30, 30];
            else
                requested = app.gainLim;
                if numel(requested) ~= 2 || any(~isfinite(requested)) || requested(1) >= requested(2)
                    values = app.viewTbl.E_Total_dB;
                    requested = app.gainDisplayRange(values);
                    app.gainLim = requested;
                end
            end
            app.onRangeUIChanged(requested, 0, "all", false);
        end

        function tf = isARComponent(~, component)
            % Resolve AR semantics independently of source column spelling.
            % Examples: AR, AR_dB, AR dB, Axial Ratio, Axial_Ratio.
            key = regexprep(lower(strtrim(string(component))), '[^a-z0-9]', '');
            tf = key == "ar" || startsWith(key, "ardb") || startsWith(key, "axialratio");
        end

        function cmap = makeARColormap(~)
            % Signed AR map exactly: blue -> white -> red, centered at zero.
            cmap = interp1( ...
                [-1, 0, 1], ...
                [0, 0, 1; 1, 1, 1; 1, 0, 0], ...
                linspace(-1, 1, 256));
        end

        function bounds = gainDisplayRange(app, values)
            values = double(values(:));
            values = values(isfinite(values));
            if isempty(values)
                bounds = [-50 0];
                return
            end
            peakData = resolvePeak(values, app.PeakPercentile, app.PeakMaxExcessDB);
            peak = peakData.value;
            if ~isfinite(peak)
                bounds = [-50, 0];
                return
            end

            upper = ceil(peak / 5) * 5;
            bounds = [upper - 50, upper];
            bounds = max(bounds, [-250 -250]);
            bounds = min(bounds, [100 100]);
            if diff(bounds) < 1
                bounds(1) = max(-250, bounds(2)-50);
            end
        end

        function onRangeUIChanged(app, inputValue, mode, scope, applyNow)
            % Synchronize full-pattern or cut ranges from sliders/spinners.
            if nargin < 5, applyNow = true; end
            scope = string(scope);

            if scope == "all"
                requested = app.clampRange(inputValue, [-250 100]);
                [app.Single_Plot_Cmin.Value, app.Single_Plot_Cmax.Value] = deal(requested(1), requested(2));
                app.onRangeUIChanged(requested, 0, "full", applyNow);
                app.onRangeUIChanged(requested, 0, "cut", applyNow);
                return
            end

            if scope == "full"
                specs = app.fullPatternSpecs();
                [sliders,minSpinners,maxSpinners] = deal([specs.range],[specs.minSpinner],[specs.maxSpinner]); current = app.ctrLim;
            else
                sliders = app.Range_Cut; minSpinners = app.Range_Cut_Min; maxSpinners = app.Range_Cut_Max; current = app.cutLim;
            end
            requested = current;
            if isempty(mode) || mode == 0, requested = inputValue; else, requested(mode) = double(inputValue); end
            requested = app.clampRange(requested, [-250 100]);

            bounds = requested;
            if ~isempty(sliders)
                oldBounds = sliders(1).Limits;
                if ~isequal(mode, 0), bounds = [min(oldBounds(1), requested(1)), max(oldBounds(2), requested(2))]; end
                set(sliders, 'Limits', [-250 100], 'Value', requested);
                set(sliders, 'Limits', bounds);
            end
            if ~isempty(minSpinners), set(minSpinners, 'Limits', [-250, requested(2)-1], 'Value', requested(1)); end
            if ~isempty(maxSpinners), set(maxSpinners, 'Limits', [requested(1)+1, 100], 'Value', requested(2)); end

            if scope == "full"
                app.ctrLim = requested;
                if ~app.isARComponent(app.comp()), app.gainLim = requested; end
            else
                app.cutLim = requested;
            end

            if applyNow && ~isempty(app.viewTbl)
                if scope == "full"
                    app.applyFullPatternRange(requested, specs);
                else
                    set(app.Single_paxCut, 'RLim', requested);
                    set(app.Single_AxesRect, 'YLim', requested);
                end
                drawnow limitrate
            end
        end

        function range = clampRange(~, values, bounds)
            % Sort, clamp, and enforce a one-unit minimum range.
            values = sort(double(values(:).'));
            if numel(values) < 2 || any(~isfinite(values(1:2))), range = bounds; return; end
            range = [max(bounds(1), values(1)), min(bounds(2), values(2))];
            if diff(range) < 1, range(2) = min(bounds(2), range(1) + 1); range(1) = max(bounds(1), range(2) - 1); end
        end

        function clearAnnotations(app, scope, specs)
            if scope == "full"
                if nargin < 3, specs = app.fullPatternSpecs(); end
                app.initializeFullPatternPOBRecords(specs);
                for k = 1:numel(app.FullPatternPOBRecords)
                    record = app.FullPatternPOBRecords{k};
                    if any(isgraphics(record.tip(:))), delete(record.tip(isgraphics(record.tip))); end
                    if any(isgraphics(record.marker(:))), delete(record.marker(isgraphics(record.marker))); end
                    record.source = gobjects(0); record.tip = gobjects(0); record.marker = gobjects(0);
                    app.FullPatternPOBRecords{k} = record;
                end
                return
            end
            app.AnnotationSources = app.AnnotationSources(cellfun(@(h) any(isgraphics(h(:))), app.AnnotationSources));
            remove = cellfun(@(source) isstruct(source.UserData) && ...
                ((isfield(source.UserData,'kind') && source.UserData.kind == "hpbw") || ...
                 (isfield(source.UserData,'kind') && source.UserData.kind == "pob" && isempty(source.UserData.tab))), ...
                app.AnnotationSources);
            for index = find(remove(:)).'
                source = app.AnnotationSources{index}; annotation = source.UserData;
                if isfield(annotation,'tip') && any(isgraphics(annotation.tip)), delete(annotation.tip(isgraphics(annotation.tip))); end
                if isfield(annotation,'marker') && any(isgraphics(annotation.marker)), delete(annotation.marker(isgraphics(annotation.marker))); end
                if isfield(annotation,'kind') && annotation.kind == "hpbw" && isgraphics(source), delete(source); end
            end
            app.AnnotationSources = app.AnnotationSources(~remove);
        end
        function specs = fullPatternSpecs(app)
            specs = struct( ...
                'name', {'contour','circular','sphere3D','polar3D','rect3D'}, ...
                'tab', {app.Single_tabContour, app.Single_tabCircular, app.Single_tab3DSpherical, app.Single_tab3DPolar, app.Single_tab3DRect}, ...
                'axes', {app.Single_Axes_Ctr, app.Single_paxPattern, app.Single_Axes_3dSph, app.Single_Axes_3dPol, app.Single_Axes_3dRect}, ...
                'range', {app.Range_Ctr, app.Range_Cir, app.Range_3dSph, app.Range_3dPol, app.Range_3dRect}, ...
                'minSpinner', {app.Range_Ctr_Min, app.Range_Cir_Min, app.Range_3dSph_Min, app.Range_3dPol_Min, app.Range_3dRect_Min}, ...
                'maxSpinner', {app.Range_Ctr_Max, app.Range_Cir_Max, app.Range_3dSph_Max, app.Range_3dPol_Max, app.Range_3dRect_Max}, ...
                'render', {@() app.drawContour(), @() app.drawFisheye(), ...
                @() app.drawPattern3D(app.Single_Axes_3dSph, app.Range_3dSph, 'sphere'), ...
                @() app.drawPattern3D(app.Single_Axes_3dPol, app.Range_3dPol, 'polar'), @() app.drawRect3()});
        end

        function applyFullPatternRange(app, limits, specs)
            if nargin < 3, specs = app.fullPatternSpecs(); end
            for k = 1:numel(specs)
                ax = specs(k).axes;
                if ~isgraphics(ax), continue; end
                clim(ax, limits); if isequal(ax,app.Single_Axes_3dRect), zlim(ax,limits); end
                cb = findall(ancestor(ax,'figure'),'Type','ColorBar','Axes',ax);
                if ~isempty(cb), app.applyColorbarTicks(cb(1), limits); end
            end
        end

        function renderAllFullPatterns(app)
            specs = app.fullPatternSpecs();
            app.clearAnnotations("full", specs);
            for k = 1:numel(specs)
                if app.isClosing, return; end
                app.checkCancelled();
                specs(k).render();
                app.checkCancelled();
            end

            % Surfaces must be materialized before POB DataTips are attached.
            drawnow limitrate;
            if app.Single_CheckBox_POB.Value && ~app.isClosing
                app.ensureFullPatternPOBAnnotations(specs);
                drawnow limitrate nocallbacks
            end
        end

        function fullPatternTabChanged(app, ~)
            % All full-pattern plots are rendered eagerly during load.  Tab
            % changes must only change annotation visibility; they must never
            % trigger plotting or clear annotations belonging to other tabs.
            if app.isClosing
                return
            end
            app.updateFullPatternPOBVisibility();
        end


        function [tip, marker] = createPOBDataTip(app, source, dataIndex, gridSize, tipRows)
            tip = gobjects(0); marker = gobjects(0);
            if ~isgraphics(source) || ~isscalar(dataIndex) || ~isfinite(dataIndex), return; end
            try
                ax = source.Parent; isPolar = isa(ax, 'matlab.graphics.axis.PolarAxes');
                if ~isgraphics(ax), return; end
                if isPolar && isprop(source,'ThetaData') && isprop(source,'RData')
                    xData = source.ThetaData; yData = source.RData; zData = [];
                else
                    xData = source.XData; yData = source.YData; zData = source.ZData;
                end
                if isempty(xData) || isempty(yData), return; end

                % IMPORTANT: dataIndex is a CData/grid linear index, not an
                % index into XData.  Contour surfaces commonly keep XData and
                % YData as coordinate vectors, so clamping dataIndex to
                % numel(XData) maps a valid peak to an unrelated grid point.
                if numel(gridSize) >= 2 && all(gridSize(1:2) > 0)
                    index = min(max(1,round(double(dataIndex))),prod(gridSize(1:2)));
                    [row,col] = ind2sub(gridSize(1:2),index);
                    if isvector(xData) && numel(xData) == gridSize(2), x = xData(col); else, x = xData(min(row,end),min(col,end)); end
                    if isvector(yData) && numel(yData) == gridSize(1), y = yData(row); else, y = yData(min(row,end),min(col,end)); end
                    if isempty(zData), z = 0;
                    elseif isscalar(zData), z = zData;
                    elseif isequal(size(zData),gridSize(1:2)), z = zData(row,col);
                    else, z = zData(min(index,numel(zData)));
                    end
                else
                    index = min(max(1,round(double(dataIndex))),min(numel(xData),numel(yData)));
                    x = xData(index); y = yData(index);
                    if isempty(zData), z = 0; elseif isscalar(zData), z = zData; else, z = zData(min(index,numel(zData))); end
                end
                if ~isscalar(x) || ~isscalar(y) || ~isfinite(double(x)) || ~isfinite(double(y)) || ...
                        (~isPolar && (~isscalar(z) || ~isfinite(double(z)))), return; end

                held = ishold(ax); hold(ax,'on'); cleanup = onCleanup(@()app.restoreHold(ax,held));
                if isPolar
                    marker = polarplot(ax,x,y,'ko','MarkerSize',5,'MarkerFaceColor','k','HandleVisibility','off');
                else
                    marker = plot3(ax,x,y,z,'LineStyle','none','Marker','o','MarkerSize',5, ...
                        'MarkerEdgeColor','k','MarkerFaceColor','k','HandleVisibility','off','Clipping','off');
                end
                marker.Tag = 'APAT_POB'; marker.Visible = app.Single_CheckBox_POB.Value;
                if ~isempty(tipRows), marker.DataTipTemplate.DataTipRows = tipRows; end
                tip = datatip(marker,'DataIndex',1,'HandleVisibility','off','FontSize',9,'Tag','APAT_POB');
                if isequal(ax,app.Single_Axes_Ctr)
                    topY = ax.YLim(2); if strcmp(ax.YDir,'reverse'), topY = ax.YLim(1); end
                    if abs(y-topY) <= max(diff(ax.YLim)/1000,eps(max(abs(ax.YLim))))
                        if x <= mean(ax.XLim), tip.Location = 'southeast'; else, tip.Location = 'southwest'; end
                    end
                end
                tip.Visible = app.Single_CheckBox_POB.Value;
            catch ME
                if isgraphics(tip), delete(tip); end
                if isgraphics(marker), delete(marker); end
                tip = gobjects(0); marker = gobjects(0);
                if ~app.isClosing, warning('APAT:POBAnnotationFailed','Could not create POB annotation: %s',ME.message); end
            end
        end

        function restoreHold(~,ax,held), if isgraphics(ax), if held, hold(ax,'on'); else, hold(ax,'off'); end, end, end

        function setPatternDataTipTemplate(app, surfaceHandle, thetaValues, phiValues, componentGrid, componentLabel)
            % Apply one common angular/component DataTip template.
            % componentLabel is optional so every renderer has one safe call path.
            if ~isgraphics(surfaceHandle), return; end
            if nargin < 6 || isempty(componentLabel), componentLabel = app.compLabel(); end
            componentLabel = replace(string(componentLabel), "_", "\_");
            if isvector(thetaValues), [phiGrid, thetaGrid] = meshgrid(phiValues, thetaValues);
            else, thetaGrid = thetaValues; phiGrid = phiValues;
            end
            if strcmp(app.Single_Switch_ThetaSpan.Value, '-90° to 90°'), thetaLabel = "Elevation"; else, thetaLabel = "Theta"; end
            tipRows = [dataTipTextRow(thetaLabel, thetaGrid, '%.3g°'); ...
                dataTipTextRow("Phi", phiGrid, '%.3g°'); ...
                dataTipTextRow(componentLabel, componentGrid, '%.3g dB')];
            try
                surfaceHandle.DataTipTemplate.DataTipRows = tipRows;
            catch
                try
                    temporaryTip = datatip(surfaceHandle, 'DataIndex', 1);
                    delete(temporaryTip);
                    surfaceHandle.DataTipTemplate.DataTipRows = tipRows;
                catch
                end
            end
        end

        function drawFisheye(app)
            if isempty(app.viewTbl), return; end
            [~, ~, componentGrid] = app.gridComp(app.viewTbl, app.comp());
            geometry = app.gridGeom();
            polarAxes = app.Single_paxPattern;
            cla(polarAxes);
            patternSurface = surface(polarAxes, geometry.phiRad, geometry.thetaPolar, ...
                zeros(size(geometry.thetaPolar)), componentGrid, 'EdgeColor', 'none', 'Tag', 'APAT_PatternSurface');
            [limits, colorMap] = app.plotTheme(app.Range_Cir.Value);
            app.applyPlotTheme(polarAxes, limits, colorMap);
            polarAxes.ThetaZeroLocation = 'top';
            polarAxes.ThetaDir = 'clockwise';
            app.setPolarSpanTicks(polarAxes);
            polarAxes.RLim = [0, 180];
            polarAxes.RTick = 0:30:180;
            radialLabels = 0:30:180; if strcmp(app.Single_Switch_ThetaSpan.Value, '-90° to 90°'), radialLabels = 90 - radialLabels; end
            polarAxes.RTickLabel = compose('%d°', radialLabels);
            titleText = sprintf('%s  |  r=θ, angle=φ', app.compLabel());
            title(polarAxes, titleText,'Interpreter','none','FontSize', 9); % Compact one-line title
            app.setPatternDataTipTemplate(patternSurface, geometry.thetaGrid, geometry.phiGrid, componentGrid, app.compLabel());
        end

        function format3DAxes(app, axesHandle)
            % Reference-style fixed camera box, applied after surface creation.
            set(axesHandle, ...
                'XDir', 'normal', 'YDir', 'normal', 'ZDir', 'normal', ...
                'Projection', 'orthographic', ...
                'XLim', [-1.5, 1.5], 'YLim', [-1.5, 1.5], 'ZLim', [-1.5, 1.5], ...
                'DataAspectRatio', [1, 1, 1], ...
                'PlotBoxAspectRatio', [1, 1, 1]);
            view(axesHandle, 135, 25);
            axis(axesHandle, 'off');
            % Newly rendered 3-D children are created after startup >> refresh their ContextMenu ownership here as well
            app.configurePlotContextMenu(axesHandle);
        end

        function [azimuth, elevation, upVector] = selected3DView(app, defaultView)
            if nargin < 2, defaultView = [135, 25]; end
            viewCode = "iso";
            if ~isempty(app.Single_DropDown_3DView) && isvalid(app.Single_DropDown_3DView)
                viewCode = string(app.Single_DropDown_3DView.Value);
            end

            upVector = [0, 0, 1];
            switch viewCode
                case "top"      % POV +Z
                    [azimuth, elevation, upVector] = deal(0, 90, [0, 1, 0]);
                case "bottom"   % POV -Z
                    [azimuth, elevation, upVector] = deal(0, -90, [0, 1, 0]);
                case "right"    % POV +X
                    [azimuth, elevation] = deal(90, 0);
                case "left"     % POV -X
                    [azimuth, elevation] = deal(-90, 0);
                case "front"    % POV -Y
                    [azimuth, elevation] = deal(0, 0);
                case "back"     % POV +Y
                    [azimuth, elevation] = deal(180, 0);
                otherwise
                    [azimuth, elevation] = deal(defaultView(1), defaultView(2));
            end
        end

        function applySelected3DView(app, axesHandle, defaultView)
            if isempty(axesHandle) || ~isgraphics(axesHandle)
                return
            end
            [azimuth, elevation, upVector] = app.selected3DView(defaultView);
            view(axesHandle, azimuth, elevation);
            try
                camup(axesHandle, upVector);
            catch
            end
        end

        function applyMain3DViews(app)
            app.applySelected3DView(app.Single_Axes_3dSph, [135, 25]);
            app.applySelected3DView(app.Single_Axes_3dPol, [135, 25]);
            app.applySelected3DView(app.Single_Axes_3dRect, [-35, 35]);
        end

        function on3DViewChanged(app)
            if isempty(app.viewTbl)
                return
            end
            app.applyMain3DViews();
            drawnow limitrate
        end

        function setPlotInteraction(app, axesHandle, is3D)
            enableDefaultInteractivity(axesHandle);
            if isa(axesHandle, 'matlab.graphics.axis.PolarAxes'), return, end
            if is3D,  axesHandle.Interactions = [rotateInteraction, dataTipInteraction];
            else,     axesHandle.Interactions = [zoomInteraction, dataTipInteraction];
            end
            app.configurePlotContextMenu(axesHandle);
        end

        function configurePlotContextMenu(app, axesHandle)
            % Keep rotation independent of DataTip mode while providing DataTip actions on every plot, including 3-D surfaces
            menu = uicontextmenu(app.UIFigure,'Tag','APAT_PlotContextMenu');
            uimenu(menu,'Text','Delete DataTips','MenuSelectedFcn',@(~,~)delete(findall(axesHandle,'Type','datatip')));
            axesHandle.ContextMenu = menu;
            graphics = findall(axesHandle,'-property','ContextMenu');
            for h = graphics(:).'
                if ~isequal(h,axesHandle), h.ContextMenu = menu; end
            end
        end

        function drawSpatial3D(app)
            axesList = [app.Single_Axes_3dSph, app.Single_Axes_3dPol];
            kinds = ["sphere", "polar"];
            ranges = [app.Range_3dSph, app.Range_3dPol];
            overlay = app.Singel_CheckBox_overlayCut.Value;

            for k = 1:2
                ax = axesList(k);
                oldOverlay = findall(ax, 'Tag', 'APAT_CutOverlay');
                if ~isempty(oldOverlay), delete(oldOverlay(isgraphics(oldOverlay))); end
                if ~overlay, continue; end

                surfaces = findall(ax, 'Type', 'surface');
                if isempty(surfaces)
                    app.drawPattern3D(ax, ranges(k), kinds(k));
                else
                    app.overlayCut3D(ax, kinds(k), ranges(k).Value);
                end
                app.checkCancelled();
            end
        end

        function drawPattern3D(app, axesHandle, rangeControl, plotKind)
            if isempty(app.viewTbl), return; end
            [~, ~, componentGrid] = app.gridComp(app.viewTbl, app.comp());
            geometry = app.gridGeom();
            [limits, colorMap] = app.plotTheme(rangeControl.Value);

            coordinates = {geometry.xCoord, geometry.yCoord, geometry.zCoord};
            if plotKind == "polar"
                radius = max(componentGrid - limits(1), 0) / max(limits(2) - limits(1), eps);
                radius = radius / max(max(radius, [], 'all', 'omitnan'), eps);
                for axisIndex = 1:3, coordinates{axisIndex} = radius .* coordinates{axisIndex}; end
            end

            cla(axesHandle);
            hold(axesHandle, 'on');
            patternSurface = surf(axesHandle, coordinates{:}, componentGrid, 'EdgeColor', 'none', 'Tag', 'APAT_PatternSurface');
            app.applyPlotTheme(axesHandle, limits, colorMap);
            app.format3DAxes(axesHandle);
            app.drawXYZ(axesHandle);
            app.applySelected3DView(axesHandle, [135, 25]);

            if app.Singel_CheckBox_overlayCut.Value
                app.overlayCut3D(axesHandle, plotKind, limits);
            end
            title(axesHandle, sprintf('%s  |  θ: %s  |  φ: %s', app.compLabel(), app.Single_Switch_ThetaSpan.Value, app.Single_Switch_AngularSpan.Value), 'Interpreter', 'none');
            app.configurePlotContextMenu(axesHandle);
            app.setPatternDataTipTemplate(patternSurface, geometry.thetaGrid, geometry.phiGrid, componentGrid, app.compLabel());
            hold(axesHandle, 'off');
        end

        function drawRect3(app)
            if isempty(app.viewTbl), return; end

            [~, ~, componentGrid] = app.gridComp(app.viewTbl, app.comp());
            geometry = app.gridGeom();
            axesHandle = app.Single_Axes_3dRect;
            cla(axesHandle);
            patternSurface = surf(axesHandle, geometry.phiGrid, geometry.thetaGrid, ...
                componentGrid, 'EdgeColor', 'none', 'Tag', 'APAT_PatternSurface');

            [limits, colorMap] = app.plotTheme(app.Range_3dRect.Value);
            app.applyPlotTheme(axesHandle, limits, colorMap);
            zlim(axesHandle, limits);
            zticks = app.makeAxisTicks(limits, app.Single_Plot_Cstep.Value);
            if ~isempty(zticks), axesHandle.ZTick = zticks; end
            app.formatAngularAxes(axesHandle, 60, 30);
            if strcmp(app.Single_Switch_ThetaSpan.Value, '-90° to 90°'), thetaLabel = "Elevation (degree)"; else, thetaLabel = "Theta (degree)"; end
            xlabel(axesHandle, 'Phi (degree)'); ylabel(axesHandle, thetaLabel); zlabel(axesHandle, app.compLabel() + " (dB)", 'Interpreter', 'none');
            grid(axesHandle, 'on');
            app.applySelected3DView(axesHandle, [-35, 35]); %app.applySelected3DView(axesHandle, [135, 25]);
            title(axesHandle, app.compLabel(), 'Interpreter', 'none');
            app.setPatternDataTipTemplate(patternSurface, geometry.thetaGrid, geometry.phiGrid, componentGrid, app.compLabel());
        end

        function drawXYZ(~, axesHandle)
            % XYZ principal axes (X red, Y green, Z blue) with angle annotations.
            persistent axisColors axisLabels directions
            if isempty(directions), axisColors = {[0.85 0.10 0.10], [0.10 0.60 0.10], [0.10 0.20 0.90]}; axisLabels = {'+X  (θ=90°, φ=0°)', '+Y  (θ=90°, φ=90°)', '+Z  (θ=0°)'}; directions = 1.35 * eye(3); end
            for axisIndex = 1:3
                direction = directions(axisIndex, :);
                quiver3(axesHandle, 0, 0, 0, direction(1), direction(2), direction(3), 0, ...
                    'Color', axisColors{axisIndex}, 'LineWidth', 1.6, 'MaxHeadSize', 0.25);
                text(axesHandle, direction(1) * 1.12, direction(2) * 1.12, direction(3) * 1.12, ...
                    axisLabels{axisIndex}, 'Color', axisColors{axisIndex}, 'FontWeight', 'bold');
            end
        end

        function overlayCut3D(app, axesHandle, plotKind, limits)
            [~, components, ~, ~, geometry] = app.cutData();
            values = components(:, 1);

            if plotKind == "sphere"
                radius = 1.02;
            else
                radius = max(values - limits(1), 0) / max(limits(2) - limits(1), eps) * 1.01;
            end

            plot3(axesHandle, ...
                radius .* sind(geometry.theta) .* cosd(geometry.phi), ...
                radius .* sind(geometry.theta) .* sind(geometry.phi), ...
                radius .* cosd(geometry.theta), 'k', 'LineWidth', 1.6, 'Tag', 'APAT_CutOverlay');
        end

        function [cols, idx] = cutCols(app)
            % Return selected Total plus circular or linear field-pair columns; idx preserves stable colors.

            if app.srcUD.isGainOnly, [cols, idx] = deal(app.viewTbl.Properties.VariableNames(3), 1); return; end

            if strcmp(app.CutFieldBasisDropDown.Value, 'Linear')
                allCuts = ["E_Total_dB","E_TH_dB","E_PH_dB"]; pairLabels = {'E_TH','E_PH'};
            else
                allCuts = ["E_Total_dB","E_RCP_dB","E_LCP_dB"]; pairLabels = {'E_RCP','E_LCP'};
            end
            if ~strcmp(app.CheckBox_Er.Text, pairLabels{1}), [app.CheckBox_Er.Text, app.CheckBox_El.Text] = deal(pairLabels{:}); end
            sel = logical([app.CheckBox_Et.Value, app.CheckBox_Er.Value, app.CheckBox_El.Value]);
            if ~any(sel), sel(1) = true; end % fallback: at least Total
            idx = find(sel);
            cols = allCuts(idx);
        end

        function [angleDeg, componentData, names, titleText, geometry, idx] = cutData(app)
            % Extract the active cut as a full 0..360 circle.
            tableData = app.viewTbl;
            [cols, idx] = app.cutCols();
            cutType = string(app.Single_DropDown_cutType.Value);
            requestedAngle = app.Single_DropDown_cutValue.Value; % requested val

            [angleDeg, rows, fixedAngle, fixedSymbol, didSnap, requestedAngle] = ...
                cutGeometry(app, tableData, cutType, requestedAngle);
            cutTable = tableData(rows, :);

            if didSnap
                app.setStatus(app.Single_StatusBar, sprintf('Requested %s cut @ %s=%g° (snapped to nearest %s=%g°)', cutType, fixedSymbol, requestedAngle, fixedSymbol, fixedAngle), false);
            end

            componentData = cutTable{:, cols};
            geometry = struct('theta', app.physicalTheta(cutTable), 'phi', cutTable.Phi, 'fixedAngle', fixedAngle, 'cutType', cutType);

            signedAngles = strcmp(app.Single_Switch_AngularSpan.Value, '-180° to 180°');
            if signedAngles
                angleDeg(angleDeg > 180) = angleDeg(angleDeg > 180) - 360;
                [angleDeg, order] = sort(angleDeg); componentData = componentData(order, :); geometry.theta = geometry.theta(order); geometry.phi = geometry.phi(order);
            end
            if signedAngles || cutType == "Phi", [angleDeg, uniqueRows] = unique(angleDeg, 'stable'); componentData = componentData(uniqueRows, :); geometry.theta = geometry.theta(uniqueRows); geometry.phi = geometry.phi(uniqueRows); end

            if cutType == "Phi"
                if signedAngles, [seamLower, seamUpper] = deal(-180, 180); else, [seamLower, seamUpper] = deal(0, 360); end
                lowerRow = find(abs(angleDeg - seamLower) < 1e-9, 1); upperRow = find(abs(angleDeg - seamUpper) < 1e-9, 1);
                if isempty(lowerRow) && ~isempty(upperRow)
                    angleDeg = [seamLower; angleDeg]; componentData = [componentData(upperRow, :); componentData]; geometry.theta = [geometry.theta(upperRow); geometry.theta]; geometry.phi = [geometry.phi(upperRow); geometry.phi];
                elseif ~isempty(lowerRow) && isempty(upperRow)
                    angleDeg = [angleDeg; seamUpper]; componentData = [componentData; componentData(lowerRow, :)]; geometry.theta = [geometry.theta; geometry.theta(lowerRow)]; geometry.phi = [geometry.phi; geometry.phi(lowerRow)];
                elseif isempty(lowerRow) && isempty(upperRow)
                    periodicGap = angleDeg(1) - seamLower + seamUpper - angleDeg(end); firstWeight = (seamUpper - angleDeg(end)) / periodicGap;
                    seamData = (1 - firstWeight) * componentData(end, :) + firstWeight * componentData(1, :); seamTheta = (1 - firstWeight) * geometry.theta(end) + firstWeight * geometry.theta(1);
                    angleDeg = [seamLower; angleDeg; seamUpper]; componentData = [seamData; componentData; seamData]; geometry.theta = [seamTheta; geometry.theta; seamTheta]; geometry.phi = [seamLower; geometry.phi; seamUpper];
                end
            end

            names = replace(string(cols),"_","\_");
            if app.srcUD.isGainOnly
                % Gain-only data has no E-field components; the selected
                % source column is therefore the authoritative cut title.
                titleText = char(string(app.comp()));
            else
                titleText = sprintf('%s cut @ %s = %g°', cutType, fixedSymbol, fixedAngle);
            end

        end

        function plotCut(app)
            if isempty(app.viewTbl), return; end

            [angleDeg, componentData, names, titleText, ~, idx] = app.cutData();

            polarAxes = app.Single_paxCut; rectAxes = app.Single_AxesRect;
            app.clearAnnotations("cut");
            cla(polarAxes); cla(rectAxes); hold(polarAxes, 'on'); hold(rectAxes, 'on');

            plotLimits = sort(app.Range_Cut.Value);
            if plotLimits(1) == plotLimits(2), plotLimits(2) = plotLimits(1) + 1; end

            % sanitize polar plot cut data (prevents reflection spikes below inner RLim)
            polarData = max(componentData, plotLimits(1));

            polarLines = polarplot(polarAxes, deg2rad(angleDeg), polarData, 'LineWidth', 1.4);
            rectLines = plot(rectAxes, angleDeg, componentData, 'LineWidth', 1.4);

            colorOrder = app.Single_AxesRect.ColorOrder; % use same palette as rectangular axes
            lineColors = colorOrder(1 + mod(idx-1, size(colorOrder, 1)), :); % stable mapping Total/first pair/second pair

            set(polarLines(:), {'Color'}, num2cell(lineColors, 2));
            set(rectLines(:), {'Color'}, num2cell(lineColors, 2));

            % Datatips: show degrees & true magnitude (raw, not clamped polar display)
            polarLines = polarLines(:).'; rectLines = rectLines(:).';
            for k = 1:numel(polarLines)
                dataTipRows = [dataTipTextRow("Angle", angleDeg, '%.3g°'), dataTipTextRow("Magnitude", componentData(:, k), '%.3g dB')];
                polarLines(k).DataTipTemplate.DataTipRows = dataTipRows;
                rectLines(k).DataTipTemplate.DataTipRows = dataTipRows;
            end

            set(polarAxes, ThetaDir = 'clockwise', ThetaZeroLocation = 'top', RLim = plotLimits, RTick = plotLimits(1):5:plotLimits(2));
            app.setPolarSpanTicks(polarAxes);
            [cutXLimits, ~, ~] = app.angularLimits(); % Both cut types follow the selected angular span.
            set(rectAxes, YLim=plotLimits, XLim=cutXLimits, XTick=cutXLimits(1):30:cutXLimits(2), XGrid='on', YGrid='on', Visible='on');
            if strcmp(app.Single_DropDown_cutType.Value, 'Phi'), angleLabel = 'Phi (degree)'; else, angleLabel = 'Theta (degree)'; end
            xlabel(rectAxes, angleLabel);
            title(polarAxes, titleText, 'Interpreter', 'none');
            title(rectAxes, titleText, 'Interpreter', 'none');

            % POB annotation on a cut is the peak of the displayed cut.
            % Keep this independent of the full-pattern POB coordinates: a cut is
            % a one-dimensional view and its peak must be indexed in the plotted
            % line data itself.
            [cutPeak, cutPeakIndex] = max(componentData(:, 1), [], 'omitnan');
            if isfinite(cutPeak) && cutPeakIndex >= 1
                cutTipRows = [dataTipTextRow("Angle", angleDeg(cutPeakIndex), '%.3g°'); dataTipTextRow("Magnitude", cutPeak, '%.3g dB')];
                polarSource = polarLines(1);
                rectSource = rectLines(1);
                for source = [polarSource, rectSource]
                    source.MarkerIndices = cutPeakIndex;
                    source.Marker = 'none';
                    source.UserData = struct('kind', "pob", 'tab', [], 'dataIndex', cutPeakIndex, ...
                        'gridSize', [], 'tipRows', cutTipRows, 'tip', gobjects(0), 'marker', gobjects(0));
                end
                app.AnnotationSources = [app.AnnotationSources, {polarSource, rectSource}];
                if app.Single_CheckBox_POB.Value
                    app.refreshAnnotations("pob");
                end
            end

            % HPBW (wrap-aware regions and optional interpolated boundary tips).
            app.Label_HPBW.Text = '';
            if app.Button_HPBW.Value
                [beamwidth, lowerAngle, upperAngle] = calcHPBW(angleDeg, componentData(:, 1), cutPeak, angleDeg(cutPeakIndex));
                if isfinite(beamwidth)
                    displayBounds = [lowerAngle, upperAngle];
                    if cutXLimits(1) < 0
                        displayBounds = mod(displayBounds + 180, 360) - 180;
                    else
                        displayBounds = mod(displayBounds, 360);
                    end
                    app.Label_HPBW.Text = sprintf('HPBW\n%.1f°\n(%.1f° to %.1f°)', ...
                        beamwidth, displayBounds(1), displayBounds(2));

                    if displayBounds(1) <= displayBounds(2)
                        regions = displayBounds;
                    else
                        regions = [cutXLimits(1), displayBounds(2); displayBounds(1), cutXLimits(2)];
                    end
                    thetaregion(polarAxes, deg2rad(regions(:, 1)), deg2rad(regions(:, 2)), FaceColor = '#D95319', FaceAlpha = 0.12);
                    xregion(rectAxes, regions(:, 1), regions(:, 2), FaceColor = '#D95319', FaceAlpha = 0.12);

                    if app.Single_CheckBox_HPBWBounds.Value
                        boundVisibility = app.Single_CheckBox_HPBWBounds.Value; halfPowerGain = cutPeak - 3; boundLabels = ["Lower HPBW", "Upper HPBW"];
                        for boundIndex = 1:2
                            boundAngle = displayBounds(boundIndex);
                            try
                                polarMarker = polarplot(polarAxes, deg2rad(boundAngle), ...
                                    halfPowerGain, 'o', 'Color', '#D95319', 'MarkerFaceColor', '#D95319', 'HandleVisibility', 'off');
                                rectMarker = plot(rectAxes, boundAngle, halfPowerGain, 'o', ...
                                    'Color', '#D95319', 'MarkerFaceColor', '#D95319', 'HandleVisibility', 'off');
                                tipRows = [dataTipTextRow(boundLabels(boundIndex), boundAngle, '%.2f°'); dataTipTextRow("Gain", halfPowerGain, '%.2f dB')];
                                polarMarker.DataTipTemplate.DataTipRows = tipRows; rectMarker.DataTipTemplate.DataTipRows = tipRows;
                                polarTip = datatip(polarMarker, 'DataIndex', 1); rectTip = datatip(rectMarker, 'DataIndex', 1);
                                polarMarker.UserData = struct('kind', "hpbw", 'tab', app.Single_tabPolarPlot, 'tip', polarTip, 'marker', gobjects(0)); rectMarker.UserData = struct('kind', "hpbw", 'tab', app.Single_tabRectPlot, 'tip', rectTip, 'marker', gobjects(0));
                                polarMarker.Visible = boundVisibility; rectMarker.Visible = boundVisibility;
                                polarTip.Visible = app.Single_CheckBox_HPBWBounds.Value && app.Single_tabCut.SelectedTab == app.Single_tabPolarPlot; rectTip.Visible = app.Single_CheckBox_HPBWBounds.Value && app.Single_tabCut.SelectedTab == app.Single_tabRectPlot;
                                app.AnnotationSources = [app.AnnotationSources, {polarMarker, rectMarker}];
                            catch
                            end
                        end
                    end
                end
            end
            legend(polarAxes, polarLines, names, 'Location', 'southoutside', 'Orientation', 'horizontal');
            legend(rectAxes, rectLines, names, 'Location', 'best');
            hold(polarAxes, 'off'); hold(rectAxes, 'off');
        end

        function syncCoverageNodeFromView(app, node)
            d = node.NodeData; t = app.physicalTheta(app.viewTbl); p = app.viewTbl.Phi;
            d.pattern = app.viewTbl; d.sourceTable = app.viewTbl;
            d.solidAngle = solidWeights(t,p,gridStep(t),gridStep(mod(p,360)));
            d.viewRevision = app.viewRevision; d.name = app.baseName;
            node.NodeData = d; app.syncCoveragePattern(node);
        end

        function thresholds = covThresholds(app)
            % Read the user's CURRENT threshold controls exactly as entered.
            % The automatic 50-dB peak-referenced range is only a preset made
            % when the active pattern/component/view changes; it must never be
            % reapplied here because that would overwrite user adjustments at
            % Compute Coverage time.
            tMin = double(app.Cov_Spinner_ThreshMin.Value);
            tMax = double(app.Cov_Spinner_ThreshMax.Value);
            thresholdStep = max(double(app.Cov_Spinner_Step.Value), 0.1);
            if tMax <= tMin
                tMax = min(100, tMin + thresholdStep);
                app.Cov_Spinner_ThreshMax.Value = tMax;
            end
            thresholds = (tMin : thresholdStep : tMax)';
            if isempty(thresholds)
                thresholds = [tMin; tMax];
            elseif thresholds(end) < tMax
                thresholds(end+1,1) = tMax;
            end
        end

        function setCoverageUI(app, mode)
            if nargin < 2 || isempty(mode)
                mode="empty";
                if ~isempty(app.covPatternTarget()), mode="pattern";
                elseif ~isempty(app.covJobNodes()),  mode="results";
                end
            elseif mode ~= "empty" && ~isempty(app.covPatternTarget()), mode="pattern";
            end

            changed=~isequal(app.Cov_gridPanel_Parm.UserData,mode); app.Cov_gridPanel_Parm.UserData=mode;
            if changed, controls=app.Cov_gridPanel_Parm.Children; end
            if mode=="pattern"
                if changed, set(controls,'Visible','on','Enable','on'); end
                hasResults=any(arrayfun(@(n)~isempty(n.Children),app.Cov_TreeNode_Results.Children));
                set([app.Cov_Button_Export,app.Cov_Button_Clear,app.CoverageQueryControls],'Enable',hasResults);
                app.Cov_ButtonGroup_CovTypeSelectionChanged(); app.setControls([app.Cov_TextFormatLabel,app.Cov_DropDown_TextFormat],app.isGenericTextFile(app.Cov_EditField_filePath.Value)); return
            end
            if ~changed, return; end
            set(controls,'Visible','off'); app.setControls([app.AntennaPatternEditFieldLabel,app.Cov_EditField_filePath,app.Cov_Button_Load,app.Cov_Button_computeCov],true);
            if mode=="results", app.setControls([app.CoverageQueryControls,app.Cov_Button_Reset,app.Cov_Button_Export,app.Cov_Button_Clear,app.Cov_Button_toMain],true); end
        end

        function setControls(~, controls, isShown)
            set(controls, 'Visible', isShown, 'Enable', isShown);
        end

        function bounds = coverageDisplayRange(app, values)
            % 50-dB coverage threshold window referenced to the effective peak.
            values = double(values(:));
            values = values(isfinite(values));
            if isempty(values)
                bounds = [-40, 10];
                return
            end

            peakData = resolvePeak(values, app.PeakPercentile, app.PeakMaxExcessDB);
            peak = peakData.value;
            if ~isfinite(peak)
                bounds = [-40, 10];
                return
            end

            upper = ceil(peak / 5) * 5;
            bounds = [upper - 50, upper];
            bounds = max(bounds, [-250 -250]); bounds = min(bounds, [100 100]);
            if diff(bounds) < 1, bounds(1) = max(-250,bounds(2)-50); end
        end

        function setCoverageRange(app, bounds, mode, rangeStep)
            if nargin < 4, rangeStep = []; end
            bounds = app.clampRange(bounds,[-250 100]);
            if diff(bounds) < 1, bounds(2) = min(100,bounds(1)+1); end
            state = app.coverageRangeState;
            switch string(mode)
                case "threshold"
                    current = [app.Cov_Spinner_ThreshMin.Value app.Cov_Spinner_ThreshMax.Value];
                    state.presetting = true; state.evaluationBounds = bounds; state.lastPreset = bounds;
                    if state.presetInitialized, bounds = [min(current(1),bounds(1)) max(current(2),bounds(2))]; end
                    app.Cov_Spinner_ThreshMin.Limits = [-250,bounds(2)-.1];
                    app.Cov_Spinner_ThreshMax.Limits = [bounds(1)+.1,100];
                    app.Cov_Spinner_ThreshMin.Value = bounds(1); app.Cov_Spinner_ThreshMax.Value = bounds(2);
                    state.presetInitialized = true; state.presetting = false;
                otherwise
                    if state.plotInitialized, bounds = [min(app.Cov_Axes.XLim(1),bounds(1)) max(app.Cov_Axes.XLim(2),bounds(2))];
                    else, state.plotInitialized = true; end
                    state.displayBounds = bounds; app.Cov_Axes.XLimMode = 'manual'; app.Cov_Axes.XLim = bounds;
                    state.syncing = true; cleanup = onCleanup(@() app.clearCoverageSync());
                    app.Cov_Spinner_XMin.Limits = [-250 100]; app.Cov_Spinner_XMax.Limits = [-250 100];
                    [app.Cov_Spinner_XMin.Value,app.Cov_Spinner_XMax.Value,app.Cov_Spinner_XRange.Limits] = deal(bounds(1),bounds(2),[-250 100]);
                    app.Cov_Spinner_XRange.Value = bounds; app.Cov_Spinner_XRange.Limits = bounds;
                    app.Cov_Spinner_XMin.Limits = [-250,bounds(2)-.1]; app.Cov_Spinner_XMax.Limits = [bounds(1)+.1,100];
            end
            if ~isempty(rangeStep) && isfinite(rangeStep) && rangeStep < app.Cov_Spinner_Step.Value, app.Cov_Spinner_Step.Value = rangeStep; end
            app.coverageRangeState = state;
        end

        function clearCoverageSync(app)
            if ~app.isClosing, app.coverageRangeState.syncing = false; end
        end

        function markCoverageThresholdUserEdit(app, ~)
            if app.isClosing || app.coverageRangeState.presetting, return; end
            app.coverageRangeState.userEdited = true;
        end

        function node = covPatternTarget(app)
            % Resolve the pattern node to compute on: selection (or its ancestor),
            % otherwise the most recently added pattern node.
            node = [];
            sel = app.Cov_Tree.SelectedNodes;
            if ~isempty(sel)
                n = sel(1);
                while ~isempty(n) && ~isempty(n.Parent)
                    if isstruct(n.NodeData) && strcmp(n.NodeData.kind, 'pattern'), node = n; return; end
                    if isa(n.Parent, 'matlab.ui.container.TreeNode'), n = n.Parent; else, break; end
                end
            end
            kids = app.Cov_TreeNode_Results.Children;
            for k = numel(kids):-1:1
                if isstruct(kids(k).NodeData) && strcmp(kids(k).NodeData.kind, 'pattern')
                    node = kids(k); return;
                end
            end
        end

        function node = covFindByPath(app, fp)
            node = [];
            kids = app.Cov_TreeNode_Results.Children;
            for k = 1:numel(kids)
                if isstruct(kids(k).NodeData) && isfield(kids(k).NodeData, 'path') && strcmp(kids(k).NodeData.path, fp)
                    node = kids(k); return;
                end
            end
        end

        function syncCoveragePattern(app, node)
            nodeData = node.NodeData; patternData = nodeData.pattern; [columns, labels] = app.componentMap(patternData);
            if isfield(nodeData, 'orientationComponent'), previous = string(nodeData.orientationComponent); else, previous = string(app.Cov_DropDown_Component.Value); end
            component = app.preferredComponent(previous, columns);
            if ~isequal(string(app.Cov_DropDown_Component.ItemsData), columns), [app.Cov_DropDown_Component.Items, app.Cov_DropDown_Component.ItemsData] = deal(cellstr(labels), cellstr(columns)); end
            if ~strcmp(app.Cov_DropDown_Component.Value, component), app.Cov_DropDown_Component.Value = component; end
            orientationChanged = ~isfield(nodeData, 'orientationComponent') || ~strcmp(nodeData.orientationComponent, component);
            if orientationChanged
                [~, ~, nodeData.boresightIndex] = app.detectOrientation(patternData, nodeData.solidAngle, component); nodeData.orientationComponent = component; nodeData.componentBounds = robustRange(patternData.(component), false); node.NodeData = nodeData;
            end
            % Coverage thresholds use the same 50-dB peak-referenced window
            % as the main gain color scale, but only as an automatic PRESET.
            % Once the user edits the threshold spinners, Compute Coverage must
            % use those values verbatim until the active pattern/component/view
            % actually changes.
            nodeData.coverageBounds = app.coverageDisplayRange(patternData.(component));
            node.NodeData = nodeData;
            presetKey = string(sprintf('%s|%s|%g', ...
                string(nodeData.path), component, double(nodeData.viewRevision)));
            if app.coverageRangeState.presetKey ~= presetKey
                app.setCoverageRange(nodeData.coverageBounds,"threshold");
                app.coverageRangeState.presetKey = presetKey;
            end
            if orientationChanged
                % Initialize the conical orientation from the detected principal axis only
                % when the pattern/component changes.  Thereafter the user's dropdown
                % selection is authoritative and must not be overwritten on recompute.
                if double(app.Cov_DropDown_Orientation.Value) == 0
                    app.Cov_DropDown_OrientationValueChanged();
                end
            end
        end

        function node = covAddPatternNode(app, name, patternData, filePath, sourceTable)
            if nargin < 5 || isempty(sourceTable), sourceTable = table(); end
            node = uitreenode(app.Cov_TreeNode_Results, 'Text', ['📡 ' name]); solidAngle = solidWeights(app.physicalTheta(patternData), patternData.Phi, gridStep(app.physicalTheta(patternData)), gridStep(mod(patternData.Phi,360)));
            node.NodeData = struct('kind', 'pattern', 'pattern', patternData, ...
                'solidAngle', solidAngle, 'sourceTable', sourceTable, ...
                'name', name, 'path', filePath, 'sourceKind', "Main View Table", 'viewRevision', app.viewRevision);
            expand(app.Cov_Tree);
            [app.Cov_Tree.CheckedNodes, app.Cov_Tree.SelectedNodes] = deal([app.Cov_Tree.CheckedNodes; node], node);
            app.syncCoveragePattern(node);
            set([app.Cov_Button_computeCov, app.Cov_Button_Reset, app.Cov_DropDown_Component, app.Cov_DropDown_ComponentLabel], 'Enable', 'on');
            app.setCoverageUI();
            app.setStatus(app.Cov_StatusBar, sprintf('Pattern "<b>%s</b>" added %s ready to compute coverage.', name, char(8212)), false);
        end

        function jobNode = covAddJob(app, parentNode, thresholds, coverage, tag, componentName, finalize, displayTag)
            if nargin < 7, finalize = true; end
            if nargin < 8 || isempty(displayTag), displayTag = tag; end
            app.covRunID = app.covRunID + 1;
            curveIcon = '📉';
            if strcmp(tag, 'Res'), curveIcon = '📈'; end
            label = sprintf('%s R%d %s %s%s%s', curveIcon, app.covRunID, ...
                displayTag, char(183), char(32), componentName);
            curveLine = plot(app.Cov_Axes, thresholds, coverage, 'LineWidth', 1.6, 'DisplayName', label); [inverseCoverage, inverseRows] = unique(coverage, 'last');
            jobNode = uitreenode(parentNode, 'Text', label);
            jobNode.NodeData = struct('kind', 'job', 'id', app.covRunID, 'tag', tag, ...
                'thr', thresholds, 'cov', coverage, 'inverseCov', inverseCoverage, ...
                'inverseThr', thresholds(inverseRows), 'line', curveLine, 'baseLineWidth', 1.6, 'label', label, 'tablePrecision', 2, ...
                'summarySource', 'jobData', 'tableTag', displayTag, 'isConical', false, 'orientationMode', "Spherical", ...
                'orientationLabel', "n/a", 'orientationIndex', NaN, ...
                'thresholdMin', thresholds(1), 'thresholdMax', thresholds(end), ...
                'thresholdStep', gridStep(thresholds));
            app.covJobs{end+1} = jobNode;
            if finalize
                expand(parentNode);
                app.Cov_Tree.CheckedNodes = [app.Cov_Tree.CheckedNodes; jobNode];
                app.finalizeCoverageJobs();
            end
        end

        function finalizeCoverageJobs(app, jobs)
            if nargin < 2, jobs=app.covJobNodes(); end
            expand(app.Cov_TreeNode_Results);
            if ~isempty(jobs), expand(unique([jobs.Parent])); end
            app.covRebuildTable(jobs); app.updateCoverageLegend(jobs); app.setCoverageUI();
        end

        function updateCoverageLegend(app, jobs)
            if nargin < 2, jobs = app.covJobNodes(); end
            jobs = jobs(ismember(jobs, app.Cov_Tree.CheckedNodes));
            lines = gobjects(1,numel(jobs)); labels = cell(1,numel(jobs));
            keep = false(1,numel(jobs));
            for k = 1:numel(jobs)
                d = jobs(k).NodeData;
                if isfield(d,'line') && isgraphics(d.line)
                    lines(k) = d.line; labels{k} = d.label; keep(k) = true;
                end
            end
            if any(keep), legend(app.Cov_Axes, lines(keep), labels(keep), 'Location','southwest','Interpreter','none');
            else, legend(app.Cov_Axes,'off'); end
        end


        function jobs = covJobNodes(app, rootNodes)
            valid = cellfun(@(n) isgraphics(n) && isstruct(n.NodeData) && ...
                isfield(n.NodeData,'kind') && strcmp(n.NodeData.kind,'job'), app.covJobs);
            app.covJobs = app.covJobs(valid);
            jobs = [app.covJobs{:}];
            if nargin >= 2 && ~isempty(rootNodes)
                descendants = findobj(rootNodes);
                jobs = jobs(ismember(jobs, descendants));
            end
            if numel(jobs) > 1, [~,order] = sort(arrayfun(@(n)n.NodeData.id,jobs)); jobs = jobs(order); end
        end

        function covRebuildTable(app, jobs)
            if nargin < 2, jobs = app.covJobNodes(); end
            checkedJobs = jobs(ismember(jobs, app.Cov_Tree.CheckedNodes));
            thresholds = app.covThresholds();
            if ~isempty(checkedJobs)
                thresholdCells = arrayfun(@(node) node.NodeData.thr(:), checkedJobs, 'UniformOutput', false);
                thresholds = unique(vertcat(thresholdCells{:}));
            end
            jobCount = numel(checkedJobs); resultValues = nan(numel(thresholds), jobCount + 1); resultValues(:, 1) = thresholds;
            names = cell(1, jobCount + 1); names{1} = 'Threshold (dB)';
            for jobIndex = 1:jobCount
                jobData = checkedJobs(jobIndex).NodeData;
                resultValues(:, jobIndex + 1) = interp1(jobData.thr, jobData.cov, thresholds, 'linear', NaN);
                if isfield(jobData, 'tableTag') && strlength(string(jobData.tableTag)) > 0
                    tableTag = char(jobData.tableTag);
                else
                    tableTag = char(jobData.tag);
                end
                names{jobIndex + 1} = sprintf('R%d %s %%', jobData.id, tableTag);
            end
            resultsTable = array2table(compose('%.2f', resultValues), 'VariableNames', names);
            app.Cov_Tabel.Data = resultsTable;
        end

        function covLoadResults(app, resultPath, resultData)
            [~, resultName] = fileparts(resultPath);
            node = uitreenode(app.Cov_TreeNode_Results, 'Text', ['📄 ' resultName]);
            node.NodeData = struct('kind', 'results', 'name', resultName, 'path', resultPath);
            app.Cov_Tree.CheckedNodes = [app.Cov_Tree.CheckedNodes; node];
            thresholds = resultData{:, 1}; curveCount = width(resultData) - 1;
            app.setCoverageRange([min(thresholds), max(thresholds)],"plot",gridStep(thresholds));
            jobNodes = cell(curveCount, 1);
            for columnIndex = 2:curveCount + 1
                jobNodes{columnIndex - 1} = app.covAddJob(node, thresholds, ...
                    resultData{:, columnIndex}, 'Res', ...
                    resultData.Properties.VariableNames{columnIndex}, false);
            end
            expand(node); expand(app.Cov_TreeNode_Results);
            app.Cov_Tree.CheckedNodes = [app.Cov_Tree.CheckedNodes; vertcat(jobNodes{:})];
            app.finalizeCoverageJobs();
            app.setCoverageUI();
            app.setStatus(app.Cov_StatusBar, sprintf('Coverage results file "%s" loaded (%d curves).', resultName, curveCount), false);
        end
        function resetParams(app, ~)
            if ~isfield(app.defaultParams, 'GainLoss'), return; end
            params = app.defaultParams;
            [app.Single_Spinner_Loss.Value, app.Single_DropDown_RxPol.Value, app.Single_Spinner_Rw.Value, ...
                app.Single_Spinner_Pt.Value, app.Single_DropDown_Pt.Value, app.Single_Spinner_R.Value, app.Single_DropDown_R.Value] = ...
                deal(params.GainLoss, char(params.RxMode), params.RxAR, params.Power, char(params.PowerUnit), params.Distance, char(params.DistanceUnit));
            if ~isempty(app.stdTbl), app.refresh(); end
        end

        function setStatus(app, statusLabel, message, temporary)
            % Update status safely and manage one transient timer per application.
            if app.isClosing || isempty(statusLabel) || ~isgraphics(statusLabel), return; end
            app.stopStatusTimer();
            message = char(message);
            if ~strcmp(statusLabel.Text, message), statusLabel.Text = message; end
            if ~temporary
                if ~strcmp(statusLabel.UserData, message), statusLabel.UserData = message; end
                return
            end
            statusLabel.UserData = statusLabel.UserData;
            timerObject = timer('ExecutionMode', 'singleShot', 'StartDelay', 3, ...
                'UserData', statusLabel, ...
                'TimerFcn', @(t, ~) app.restoreStatus(t), ...
                'StopFcn', @(t, ~) app.disposeStatusTimer(t));
            app.statusTimer = timerObject;
            start(timerObject);
        end

        function restoreStatus(app, timerObject)
            if app.isClosing, return; end
            target = timerObject.UserData;
            if isgraphics(target)
                target.Text = target.UserData;
            end
        end

        function disposeStatusTimer(app, timerObject)
            if isequal(app.statusTimer, timerObject), app.statusTimer = []; end
            if isvalid(timerObject), delete(timerObject); end
        end

        function stopStatusTimer(app)
            timerObject = app.statusTimer;
            app.statusTimer = [];
            if ~isempty(timerObject) && isvalid(timerObject)
                stop(timerObject);
                delete(timerObject);
            end
        end

        function closeRequestImpl(app, ~)
            if app.isClosing
                return
            end

            app.isClosing = true;
            app.cleanupResources();

            if isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end

        function cleanupResources(app)
            % Centralized shutdown path: stop asynchronous resources first, then
            % release application-owned annotations, dialogs, and temporary state.
            app.stopStatusTimer();
            dlg = app.operationDialog;
            app.operationDialog = [];
            if ~isempty(dlg) && isvalid(dlg), delete(dlg); end
            app.AnnotationSources = app.AnnotationSources(cellfun(@(h) any(isgraphics(h(:))), app.AnnotationSources));
            for k = 1:numel(app.AnnotationSources)
                source = app.AnnotationSources{k};
                if ~isgraphics(source), continue; end
                annotation = source.UserData;
                if ~isstruct(annotation), continue; end
                if isfield(annotation,'tip') && any(isgraphics(annotation.tip)), delete(annotation.tip(isgraphics(annotation.tip))); end
                if isfield(annotation,'marker') && any(isgraphics(annotation.marker)), delete(annotation.marker(isgraphics(annotation.marker))); end
            end
            app.AnnotationSources = {};
            app.OutputFilterStyles = {};
        end

        function showError(app, exception, titleText)
            if app.isClosing || isempty(app.UIFigure) || ~isvalid(app.UIFigure), return; end
            location = '';
            if ~isempty(exception.stack), location = sprintf('\n(%s line %d)', ...
                    exception.stack(1).name, exception.stack(1).line); end
            uialert(app.UIFigure, [exception.message location], titleText, 'Icon', 'error');
        end

        function writeExportTable(~, tableData, filePath)
            % TXT is tab-delimited; CSV/XLSX use writetable's native format.
            if endsWith(filePath, '.txt', 'IgnoreCase', true)
                writetable(tableData, filePath, 'Delimiter', '\t');
            else
                writetable(tableData, filePath);
            end
        end

        function writeUANFile(~, uanData, filePath)
            % Write one canonical XGTD UAN header followed by magnitude/phase rows.
            thetaStep = gridStep(uanData.Theta);
            phiStep = gridStep(mod(uanData.Phi, 360));
            maximumGain = max([max(uanData.E_TH_DB, [], 'omitnan'), max(uanData.E_PH_DB, [], 'omitnan')], [], 'omitnan');
            header = sprintf(['begin_<parameters>\nformat free\nphi_min %g\nphi_max %g\nphi_inc %g\n' ...
                'theta_min %g\ntheta_max %g\ntheta_inc %g\ncomplex\nmag_phase\npattern gain\n' ...
                'magnitude dB\nmaximum_gain %.5f\nphase degrees\ndirection degrees\n' ...
                'polarization theta_phi\nend_<parameters>'], ...
                min(uanData.Phi), max(uanData.Phi), phiStep, ...
                min(uanData.Theta), max(uanData.Theta), thetaStep, maximumGain);
            writelines(header, filePath);
            writetable(uanData, filePath, 'Delimiter', '\t', 'WriteVariableNames', false, 'WriteMode', 'append', 'FileType', 'text');
        end

        function checkCancelled(app)
            % Stop at the next pipeline checkpoint after the user requests cancellation.
            if ~isempty(app.operationDialog) && isvalid(app.operationDialog) && app.operationDialog.CancelRequested
                app.operationDialog.Message = 'Aborting...';
                drawnow limitrate
                error('APAT:Cancelled', 'Operation cancelled by user.');
            end
        end

        function endPerf = startPerf(app, operation)
            stages = cell(0, 2); stageTimer = tic; totalTimer = tic; isSaved = false; app.perfTracker = @track; endPerf = @save;
            function track(stage), stages(end+1, :) = {string(stage), toc(stageTimer)}; stageTimer = tic; end
            function save()
                if isSaved, return; end, isSaved = true; perf = struct('AppVersion', string(class(app)),'Operation', string(operation), ...
                    'Stages', cell2table(stages,'VariableNames', {'Stage','Seconds'}),'TotalSeconds', toc(totalTimer));
                assignin('base', matlab.lang.makeValidName("Perf_"+string(class(app))), perf); app.perfTracker = @(~)[];
            end
        end
   end

    methods (Access = private)

        function startupFcn(app)
            app.gridCache = emptyGridCache();
            app.initializeFullPatternPOBRecords();
            app.Single_paxCut = polaraxes(app.Single_Grid_Polar);
            app.Single_paxCut.Layout.Row = [1 4]; app.Single_paxCut.Layout.Column = 3;
            set(app.Single_paxCut, 'ThetaZeroLocation', 'top', 'ThetaDir', 'clockwise');

            app.Single_paxPattern = polaraxes(app.Single_gridCircular);
            app.Single_paxPattern.Layout.Row = [1 3]; app.Single_paxPattern.Layout.Column = 2;
            set(app.Single_paxPattern, 'ThetaZeroLocation', 'top', 'ThetaDir', 'clockwise');

            % Configure local gestures once; no figure-level mode can move tiled axes.
            app.CoverageQueryControls = [app.Cov_QueryCoverageLabel, ...
                app.Cov_Spinner_queryCov, app.Cov_Button_queryCov, ...
                app.Cov_QueryThresholdLabel, app.Cov_Spinner_queryThresh, ...
                app.Cov_Button_queryThresh];
            fixedAxes = {app.Single_Axes_Ctr, app.Single_AxesRect, ...
                app.Single_paxPattern, app.Single_paxCut, app.Single_Axes_3dSph, ...
                app.Single_Axes_3dPol, app.Single_Axes_3dRect};
            for index = 1:numel(fixedAxes)
                app.setPlotInteraction(fixedAxes{index}, index > 4);
            end

            fullSliders = [app.Range_Ctr app.Range_Cir app.Range_3dSph app.Range_3dPol app.Range_3dRect];
            fullMins = [app.Range_Ctr_Min app.Range_Cir_Min app.Range_3dSph_Min app.Range_3dPol_Min app.Range_3dRect_Min];
            fullMaxs = [app.Range_Ctr_Max app.Range_Cir_Max app.Range_3dSph_Max app.Range_3dPol_Max app.Range_3dRect_Max];

            % Separate selected-range state for cut plots.
            app.cutLim = app.ctrLim;

            set(fullSliders, 'ValueChangedFcn', @(src, ~) app.onRangeUIChanged(src.Value, [], "full", true));
            set(fullMins, 'ValueChangedFcn', @(src, ~) app.onRangeUIChanged(src.Value, 1, "full", true));
            set(fullMaxs, 'ValueChangedFcn', @(src, ~) app.onRangeUIChanged(src.Value, 2, "full", true));
            app.Range_Cut.ValueChangedFcn = @(src, ~) app.onRangeUIChanged(src.Value, [], "cut", true);
            app.Range_Cut_Min.ValueChangedFcn = @(src, ~) app.onRangeUIChanged(src.Value, 1, "cut", true);
            app.Range_Cut_Max.ValueChangedFcn = @(src, ~) app.onRangeUIChanged(src.Value, 2, "cut", true);
            set([app.Single_Plot_Cmin, app.Single_Plot_Cmax], 'ValueChangedFcn', @(~, ~) app.onRangeUIChanged([app.Single_Plot_Cmin.Value, app.Single_Plot_Cmax.Value], 0, "all", true));

            set([app.CheckBox_Et, app.CheckBox_Er, app.CheckBox_El, app.Button_HPBW], 'ValueChangedFcn', createCallbackFcn(app, @onCutChanged, true));

            [app.Single_Plot_Cmax.Value, app.Single_Plot_Cmin.Value, app.Single_Plot_Cstep.Value, app.Single_Spinner_Pt.Value, app.Single_Spinner_R.Value, ...
                app.Single_Spinner_Rw.Value, app.Cov_Spinner_ThreshMin.Value, app.Cov_Spinner_ThreshMax.Value, app.Cov_Spinner_Step.Value, app.Cov_Spinner_ConeAng.Value] = ...
                deal(10, -40, 5, 0, 1, 6, -40, 10, 1, 45);
            app.Single_DropDown_cutValue.Limits = [0, 360];
            hold(app.Cov_Axes, 'on'); grid(app.Cov_Axes, 'on'); ylim(app.Cov_Axes, [0, 100]); set(app.Cov_Axes, 'Box', 'on', 'Layer', 'top');
            set([app.Single_tabData, app.Single_DropDown_output, app.Single_DropDown_step, ...
                app.Single_Panel_Rect, app.Single_Export_Output, app.Single_Export_UAN, app.Single_Button_Coverage, app.Single_Panel_plotControl, app.Single_CheckBox_HPBWBounds, ...
                app.FFDFreqDropDownLabel, app.Single_DropDown_FFD, app.TextFormatLabel, app.Single_DropDown_TextFormat, ...
                app.Cov_TextFormatLabel, app.Cov_DropDown_TextFormat], 'Visible', 'off');
            [app.Single_StatusBar.Text, app.Cov_StatusBar.Text, app.Single_StatusBar.UserData, app.Cov_StatusBar.UserData] = deal('Ready -- load an antenna pattern file to begin 🚀');
            app.defaultParams = struct('GainLoss', app.Single_Spinner_Loss.Value, ...
                'RxMode', string(app.Single_DropDown_RxPol.Value), ...
                'RxAR', app.Single_Spinner_Rw.Value, 'Power', app.Single_Spinner_Pt.Value, ...
                'PowerUnit', string(app.Single_DropDown_Pt.Value), ...
                'Distance', app.Single_Spinner_R.Value, ...
                'DistanceUnit', string(app.Single_DropDown_R.Value));
            app.setCoverageUI();

        end

        function onLoad(app, ~)
            previousMainPath = app.Single_EditField_Path.Value;
            fp = strtrim(previousMainPath);
            if isempty(fp) || ~isfile(fp) || strcmp(fp, app.filePath)
                filters = {'*.uan;*.fz;*.out;*.cut;*.ffd;*.ffe;*.ffs;*.xlsx;*.csv;*.dat;*.txt','Pattern/Gain Files'};
                while true % same file re-selected → force re-browse
                    [f, p] = uigetfile(filters, 'Select an antenna pattern file');
                    if isequal(f, 0), return; end % User cancelled the file browser.
                    fp = fullfile(p, f);
                    if ~strcmp(fp, app.filePath), break; end % different file → proceed

                    choice = uiconfirm(app.UIFigure, sprintf('"<strong>%s</strong>" is already loaded', f), ...
                        'File Already Loaded', 'Options', {'Select Another File', 'Cancel'}, ... % choice: 'Select Another File' → loop back to uigetfile
                        'DefaultOption', 1, 'CancelOption', 2, 'Interpreter', 'html');
                    if strcmp(choice, 'Cancel'), return; end % cancel reading
                end
                app.Single_EditField_Path.Value = fp;
            end

            % Show the loading dialog before any file parsing.  Excel workbooks can
            % spend noticeable time in sheet discovery/metadata reads, so creating
            % the dialog after prepareTextFormat made Excel loading appear frozen.
            dlg = uiprogressdlg(app.UIFigure, 'Title', 'Loading Data', ...
                'Message', 'Reading file...', 'Indeterminate', 'on', 'Cancelable', 'on', 'CancelText', 'Abort');
            app.operationDialog = dlg;
            drawnow;
            cleaner = onCleanup(@() close(dlg));
            endPerf = app.startPerf("Load pattern");

            try
                app.perfTracker("Read file"); app.checkCancelled();
                out = app.prepareTextFormat(fp, app.TextFormatLabel, app.Single_DropDown_TextFormat);
                app.checkCancelled();

                if out.userData.isCoverage % Route coverage without replacing Main state.
                    app.Single_EditField_Path.Value = previousMainPath;
                    set([app.TextFormatLabel, app.Single_DropDown_TextFormat], 'Visible', 'off');
                    endPerf(); delete(cleaner);
                    [app.TabGroup.SelectedTab, app.Cov_EditField_filePath.Value] = deal(app.Tab2_Coverage, fp);
                    app.covLoadResults(fp, out.rawTbl);
                    return
                end

                app.filePath = fp;
                [app.folderPath, app.baseName, ext] = fileparts(fp); app.fileName = [app.baseName, ext];
                app.activateSource(out);

                if out.userData.isDep
                    items = compose('Pattern %d: %.4g GHz', (1:numel(out.blocks))', (out.freqs / 1e9)');
                    missingFrequency = isnan(out.freqs);
                    items(missingFrequency) = compose('Pattern %d', find(missingFrequency));
                    [app.Single_DropDown_FFD.Items, app.Single_DropDown_FFD.Value] = deal(items, items{1}); %[app.Single_DropDown_FFD.Items, app.Single_DropDown_FFD.Value] = deal(cellstr(items), char(items(1)));
                    set([app.Single_DropDown_FFD, app.FFDFreqDropDownLabel], 'Visible', 'on', 'Enable', 'on');
                else
                    set([app.Single_DropDown_FFD, app.FFDFreqDropDownLabel], 'Visible', 'off');
                end

                [app.Single_DropDown_step.UserData, app.CutFieldBasisDropDown.UserData] = deal(false, true);
                app.refresh();
                endPerf();
            catch ME
                endPerf();
                if strcmp(ME.identifier, 'APAT:Cancelled')
                    app.setStatus(app.Single_StatusBar, 'Loading cancelled by user.', true);
                else
                    app.showError(ME, 'Loading Error');
                end
            end

        end

        function onTextFormatChanged(app, ~)
            % Reparse immediately when the changed selector belongs to the active source.
            currentPath = strtrim(app.Single_EditField_Path.Value);
            isActiveGeneric = strcmp(currentPath, app.filePath) && app.isGenericTextFile(currentPath);
            if isActiveGeneric
                app.CutFieldBasisDropDown.UserData = true; app.setStatus(app.Single_StatusBar, 'Generic format changed — reprocessing...', true);
                app.onProcess([]);
            end
        end

        function onCovTextFormatChanged(app, ~)
            % Replace an existing generic coverage-pattern node using the new format.
            coveragePath = strtrim(app.Cov_EditField_filePath.Value);
            if ~isfile(coveragePath) || ~app.isGenericTextFile(coveragePath)
                return
            end
            oldNode = app.covFindByPath(coveragePath);
            if isempty(oldNode), return; end % Initial Load is already in progress.

            try
                sourceTable = table();
                if isfield(oldNode.NodeData, 'sourceTable')
                    sourceTable = oldNode.NodeData.sourceTable;
                end
                out = app.readFile(coveragePath, ...
                    app.Cov_DropDown_TextFormat.Value, sourceTable);
                if out.userData.isCoverage
                    app.setStatus(app.Cov_StatusBar, 'Coverage-result format is detected automatically; no pattern reprocessing required.', true);
                    return
                end
                [~, pattern] = app.buildPatternData(out);
                nodeName = oldNode.NodeData.name;

                for jobNode = oldNode.Children
                    jobData = jobNode.NodeData;
                    if isstruct(jobData) && isfield(jobData,'line') && isgraphics(jobData.line), delete(jobData.line); end
                end
                delete(oldNode);
                app.covAddPatternNode(nodeName, pattern, coveragePath, out.rawTbl);
                app.finalizeCoverageJobs();
                app.setStatus(app.Cov_StatusBar, sprintf('Pattern <b>"%s"</b> reprocessed with the selected format.', nodeName), true);
            catch ME
                app.showError(ME, 'Coverage Format Error');
            end
        end

        function onProcess(app, ~)
            if isempty(app.stdTbl), uialert(app.UIFigure, compose('No file! \nLoad an pattern first.'), 'Warning', 'Icon','warning'); return; end
            dlg = uiprogressdlg(app.UIFigure, 'Title', 'Processing', 'Message', 'Re-processing pattern...', 'Indeterminate', 'on');
            cleaner = onCleanup(@()close(dlg)); endPerf = app.startPerf("Reprocess pattern");
            oneDegree = ['STEP: 1' char(176)];
            app.Single_DropDown_step.UserData = strcmp(app.Single_DropDown_step.Value, oneDegree);
            try
                if app.isGenericTextFile(app.filePath)
                    % Reinterpret the cached generic source; parameter and format
                    % changes do not need another detect/import/readtable cycle.
                    out = app.readFile(app.filePath, app.Single_DropDown_TextFormat.Value, app.rawTbl);
                    assert(~out.userData.isCoverage, 'The selected generic format identifies a coverage-results file.');
                    app.activateSource(out);
                    app.perfTracker("Reinterpret generic source");
                end

                app.refresh(); endPerf();
                app.setStatus(app.Single_StatusBar, ['Re-processed <b>' app.fileName '</b> with current parameters and selected text format ' char(9989)], true);
            catch ME
                endPerf();
                app.showError(ME, 'Processing Error');
            end
        end

        function exportResults(app, ~)
            if isempty(app.viewTbl), return; end
            [exportName, exportFolder] = uiputfile({'*.csv', 'Comma-delimited text (*.csv)'; '*.txt', 'Tab-delimited text (*.txt)'; '*.xlsx', 'Excel (*.xlsx)'}, ...
                'Export Results', fullfile(app.folderPath, [app.baseName '_APAT_results.csv']));
            if isequal(exportName, 0), return; end
            try
                outputPath = fullfile(exportFolder, exportName); app.writeExportTable(app.Single_Table_DataOut.Data, outputPath); % Respect the active column filter.
                app.setStatus(app.Single_StatusBar, ['Results exported to <b>' outputPath '</b>'], true);
            catch ME
                app.showError(ME, 'Export Error');
            end
        end

        function exportUAN(app, ~)
            if app.srcUD.isGainOnly, uialert(app.UIFigure,'No E-field data to export.','Export UAN'); return; end
            if isempty(app.uanTbl)
                viewData = app.viewTbl;
                required = {'E_TH_dB','E_PH_dB','E_TH_Phase','E_PH_Phase'};
                assert(all(ismember(required, viewData.Properties.VariableNames)), 'UAN requires processed E-field columns.');
                app.uanTbl = table(app.physicalTheta(viewData), viewData.Phi, round(viewData.E_TH_dB, 5), ...
                    round(viewData.E_PH_dB, 5), round(viewData.E_TH_Phase, 5), round(viewData.E_PH_Phase, 5), ...
                    'VariableNames', {'Theta','Phi','E_TH_DB','E_PH_DB','E_TH_DG','E_PH_DG'});
                app.uanTbl = sortrows(app.uanTbl, {'Phi','Theta'});
            end
            thetaStep = gridStep(app.uanTbl.Theta);
            if ~isfinite(thetaStep), thetaStep = 1; end, stepStr = num2str(thetaStep); viewMax = max([max(app.uanTbl.E_TH_DB, [], 'omitnan'), max(app.uanTbl.E_PH_DB, [], 'omitnan')], [], 'omitnan');
            [f, p] = uiputfile({'*.uan', 'XGTD user-defined antenna (*.uan)'; '*.csv', 'Comma-delimited text (*.csv)'; '*.txt', 'Tab-delimited text (*.txt)'}, 'Export UAN / E-field data', ...
                fullfile(app.folderPath, [app.baseName '_' num2str(viewMax,'%.5f') '_' stepStr 'deg.uan']));
            if isequal(f, 0), return; end
            dlg = uiprogressdlg(app.UIFigure, 'Title', 'Saving Data', 'Message', 'Writing file...', 'Indeterminate', 'on');
            cleaner = onCleanup(@() close(dlg));
            try
                fpOut = fullfile(p, f);
                if endsWith(fpOut, '.uan', 'IgnoreCase', true)
                    app.writeUANFile(app.uanTbl, fpOut);
                else
                    app.writeExportTable(app.uanTbl, fpOut);
                end
                app.setStatus(app.Single_StatusBar, ['UAN exported to <b>' fpOut '</b>'], true);
            catch ME
                app.showError(ME, 'Export UAN Error');
            end
        end

        function styles = getOutputFilterStyles(app)
            % UI style handles belong to this application instance.
            % uistyle objects are value-like UI style specifications in the
            % supported App Designer workflow; they do not provide the generic
            % isvalid() handle API.  Keep the styles instance-owned and rebuild
            % only when the cache is structurally missing.
            if numel(app.OutputFilterStyles) ~= 2 || any(cellfun(@isempty, app.OutputFilterStyles))
                app.OutputFilterStyles = { ...
                    uistyle('FontWeight','bold','FontColor','black','BackgroundColor',[0.8 1 0.8]), ...
                    uistyle('FontColor',[0.5 0.5 0.5],'BackgroundColor',[0.9 0.9 0.9])};
            end
            styles = app.OutputFilterStyles;
        end

        function filterOutput(app, ~, refreshStyle, refreshVisibility)
            if nargin < 3, refreshStyle = true; end, if nargin < 4, refreshVisibility = true; end, dd = app.Single_DropDown_output;
            styles = cell(0,1);
            if refreshStyle, styles = app.getOutputFilterStyles(); end
            if dd.Value > 0
                dd.UserData(dd.Value) = ~dd.UserData(dd.Value);
                dd.Value = 0;
            end
            if refreshStyle
                dd.Items = regexprep(dd.Items,'^✓ ?','');
                removeStyle(dd); % Prevent accumulated dropdown styles.
                on = find(dd.UserData) + 1; dd.Items(on) = append('✓ ', dd.Items(on));
                addStyle(dd, styles{1}, 'Item', on); addStyle(dd, styles{2}, 'Item', find([true, ~dd.UserData]));
            end
            keep = [true, true, dd.UserData]; app.Single_Table_DataOut.Data = app.viewTbl(:, keep);
            if refreshVisibility, app.updateInputVisibility(); end
        end

        function stepChanged(app, ~)
            endPerf = app.startPerf("Change angular step");
            app.applyStep(); app.updateComponentItems();
            app.updateViewResults(true); endPerf();
        end

        function Single_Button_CoveragePushed(app, ~)
            % Coverage is always fed from the CURRENT Main-tab View Table.
            % This is intentional: loss, resampling/step selection, component
            % derivation and any other view-level transformation already applied
            % by the user must be exactly what Coverage receives.
            if isempty(app.viewTbl) || ~istable(app.viewTbl) || height(app.viewTbl) == 0
                uialert(app.UIFigure, 'No processed View Table is available. Load and process a pattern first.', 'Coverage');
                return
            end
            [app.TabGroup.SelectedTab, app.Cov_EditField_filePath.Value] = deal(app.Tab2_Coverage, app.filePath);
            node = app.covFindByPath(app.filePath);
            if isempty(node)
                app.covAddPatternNode(app.baseName, app.viewTbl, app.filePath, app.viewTbl);
            else
                app.syncCoverageNodeFromView(node);
                app.Cov_Tree.SelectedNodes = node; app.setCoverageUI();
            end
            app.setStatus(app.Cov_StatusBar, 'Coverage source synchronized from the current Main-tab View Table.', false);
        end

        function Cov_Button_LoadPushed(app, ~)
            fp = strtrim(app.Cov_EditField_filePath.Value);
            if isempty(fp) || ~isfile(fp) || ~isempty(app.covFindByPath(fp))
                filters = {'*.uan;*.fz;*.out;*.ffd;*.ffe;*.ffs;*.cut;*.xlsx;*.csv;*.dat;*.txt', 'Pattern / coverage data'; '*.*', 'All files'};
                [f, p] = uigetfile(filters, 'Select a pattern or coverage results file');
                if isequal(f, 0), return; end
                fp = fullfile(p, f);
            end
            existing = app.covFindByPath(fp);
            if ~isempty(existing)
                app.Cov_Tree.SelectedNodes = existing; app.Cov_TreeSelectionChanged([]);
                patternNode = app.covPatternTarget();
                if ~isempty(patternNode), fp = patternNode.NodeData.path; end
                app.Cov_EditField_filePath.Value = fp; app.setCoverageUI();
                app.setStatus(app.Cov_StatusBar, 'File already loaded -- node selected. Add another job or load a different file.', true);
                return;
            end
            app.Cov_EditField_filePath.Value = fp;
            out = app.prepareTextFormat(fp, app.Cov_TextFormatLabel, app.Cov_DropDown_TextFormat);

            try
                if out.userData.isCoverage
                    set([app.Cov_TextFormatLabel, app.Cov_DropDown_TextFormat], 'Visible', 'off');
                    patternNode = app.covPatternTarget(); if ~isempty(patternNode), app.Cov_EditField_filePath.Value = patternNode.NodeData.path; end
                    app.covLoadResults(fp, out.rawTbl);
                else
                    [~, pattern] = app.buildPatternData(out); % Multi-frequency FFD uses block 1.
                    [~, name] = fileparts(fp);
                    app.covAddPatternNode(name, pattern, fp, out.rawTbl);

                end
                app.Cov_Panel_Results.Visible = 'on';
            catch ME
                app.showError(ME, 'Coverage Load Error');
            end
        end

        function key = coverageCacheKey(~, node, component, thresholds, tag)
            revision = 0; if isfield(node.NodeData,'viewRevision'), revision = node.NodeData.viewRevision; end
            key = matlab.lang.makeValidName(sprintf('%s_%g_%s_%g_%g_%g_%d', ...
                component,revision,tag,thresholds(1),thresholds(end),gridStep(thresholds),numel(thresholds)));
        end

        function Cov_Button_computeCovPushed(app, ~)
            node = app.covPatternTarget();
            if isempty(node) || isempty(node.NodeData.pattern)
                uialert(app.UIFigure, 'Load (or select) an antenna pattern node first.', 'Compute Coverage');
                return
            end
            % Main-tab patterns are always computed from the currently displayed
            % View Table.  This keeps Coverage tied to the exact user-visible
            % processed data after step/resampling/angular-span changes.
            if ~isempty(app.viewTbl) && istable(app.viewTbl) && height(app.viewTbl) > 0 && ...
                    isfield(node.NodeData, 'path') && strcmp(node.NodeData.path, app.filePath)
                app.syncCoverageNodeFromView(node);
            end
            patternData = node.NodeData.pattern;
            endPerf = app.startPerf("Compute coverage");
            try
                compName = app.Cov_DropDown_Component.Value;
                thresholds = app.covThresholds();

                orientationMode = "Spherical";
                orientationLabel = "n/a";
                orientationIndex = NaN;
                centerLabel = "";
                coneAngle = NaN;
                if app.Cov_ButtonGroup_Btn_Conical.Value
                    selectedOrientation = double(app.Cov_DropDown_Orientation.Value);
                    if selectedOrientation == 0
                                    orientationIndex = double(node.NodeData.boresightIndex);
                        orientationLabel = string(app.PrincipalAxes.labels{orientationIndex});
                    else
                                    orientationIndex = selectedOrientation;
                        orientationLabel = string(app.PrincipalAxes.labels{orientationIndex});
                    end
                    coneTheta = double(app.Cov_Spinner_ConeTH.Value);
                    conePhi = mod(double(app.Cov_Spinner_ConePH.Value), 360);
                    coneAngle = double(app.Cov_Spinner_ConeAng.Value);
                    thetaPhysical = app.physicalTheta(patternData);
                    cosDistance = cosd(thetaPhysical) .* cosd(coneTheta) + ...
                        sind(thetaPhysical) .* sind(coneTheta) .* cosd(patternData.Phi - conePhi);
                    regionMask = cosDistance >= cosd(coneAngle);
                    % The cone center coordinates are the actual geometric
                    % definition of the region and therefore take precedence in
                    % the result label.  The Orientation control remains provenance
                    % metadata (Auto/explicit), not a substitute for user-edited
                    % center coordinates.
                    centerLabel = app.coneCenterLabel(coneTheta, conePhi);
                    % Keep an ASCII-safe internal tag for table/cache identifiers,
                    % but keep the human-readable θ/φ text for the Coverage node.
                    tag = sprintf('Con_%.15g_%.15g_%.15g', coneTheta, conePhi, coneAngle);
                    tagFull = sprintf('Conical coverage (%s) α=%s°', centerLabel, app.fmtNumber(coneAngle));
                else
                    regionMask = true(height(patternData), 1);
                    tag = 'Sph';
                    tagFull = 'Sph coverage';
                end
                % Resolve the table label here as part of the run metadata.  This
                % keeps Spherical and Conical jobs on one naming path and guarantees
                % all variables are initialized before cache evaluation.
                if app.Cov_ButtonGroup_Btn_Conical.Value
                    tableTag = app.coverageTableTag(centerLabel, coneAngle, true);
                else
                    tableTag = app.coverageTableTag("", NaN, false);
                end
                cacheKey = app.coverageCacheKey(node, compName, thresholds, tag);
                nodeData = node.NodeData;
                if ~isfield(nodeData,'coverageCache') || ~isstruct(nodeData.coverageCache), nodeData.coverageCache = struct(); end
                cacheHit = isfield(nodeData.coverageCache,cacheKey);
                if cacheHit
                    cached = nodeData.coverageCache.(cacheKey); coverage = cached.coverage;
                else
                    coverage = coverageCCDF(patternData.(compName), regionMask, thresholds, nodeData.solidAngle);
                    nodeData.coverageCache.(cacheKey) = struct('thresholds',thresholds,'coverage',coverage);
                    node.NodeData = nodeData;
                end
                jobNode = app.covAddJob(node, thresholds, coverage, tag, compName, false, tagFull);
                jobData = jobNode.NodeData;
                jobData.tableTag = tableTag;
                jobData.isConical = app.Cov_ButtonGroup_Btn_Conical.Value;
                jobData.orientationMode = orientationMode;
                jobData.orientationLabel = orientationLabel;
                jobData.orientationIndex = orientationIndex;
                jobData.thresholdMin = thresholds(1);
                jobData.thresholdMax = thresholds(end);
                jobData.thresholdStep = gridStep(thresholds);
                jobData.coneTheta = app.Cov_Spinner_ConeTH.Value;
                jobData.conePhi = app.Cov_Spinner_ConePH.Value;
                jobData.coneAngle = app.Cov_Spinner_ConeAng.Value;
                jobNode.NodeData = jobData;
                app.finalizeCoverageJobs();
                % The first plotted result establishes the Coverage X-axis baseline;
                % later results may only expand that baseline automatically.
                app.setCoverageRange([thresholds(1), thresholds(end)],"plot");
                app.Cov_Panel_Results.Visible = 'on';
                endPerf();
                if cacheHit, actionText = 'reused cached CCDF'; else, actionText = 'computed'; end
                statusText = sprintf('Run-<b>%d</b> %s: <b>%s</b> on <b>"%s"</b> (%s, %d thresholds).', ...
                    app.covRunID, actionText, tagFull, node.NodeData.name, compName, numel(thresholds));
                % Orientation provenance is reported only for conical Coverage.
                % Auto and explicit selections both report the actual orientation used.
                if app.Cov_ButtonGroup_Btn_Conical.Value
                    statusText = sprintf('%s | Orientation <b>%s</b>', statusText, orientationLabel);
                end
                app.setStatus(app.Cov_StatusBar, statusText, false);
            catch ME
                endPerf();
                app.showError(ME, 'Coverage Error');
            end
        end

function Cov_Button_ResetPushed(app, ~)
    jobs = app.covJobNodes();
    for k = 1:numel(jobs)
        d = jobs(k).NodeData;
        if isfield(d,'line') && isgraphics(d.line)
            for mode = ["cov","thr"], delete(app.coverageArtifacts(d.line,sprintf('CovQ_%s_%d',mode,d.id))); end
        end
    end
    delete(app.Cov_TreeNode_Results.Children);
    tips = findall(app.Cov_Axes,'Type','datatip'); if ~isempty(tips), delete(tips(isgraphics(tips))); end
    cla(app.Cov_Axes); legend(app.Cov_Axes,'off'); hold(app.Cov_Axes,'on'); grid(app.Cov_Axes,'on');
    ylim(app.Cov_Axes,[0 100]); set(app.Cov_Axes,'Box','on','Layer','top');
    app.Cov_Tabel.Data = table(); app.covRunID = 0; app.covJobs = {};
    controls = [app.Cov_Button_computeCov, app.Cov_Button_Export, ...
        app.Cov_Button_Clear, app.Cov_Button_queryCov, ...
        app.Cov_Button_queryThresh, app.Cov_Button_Reset];
    set(controls, 'Enable', 'off');
    app.setCoverageUI();
    app.Cov_Panel_Results.Visible = 'off';
    app.coverageRangeState = struct('syncing',false,'presetting',false, ...
        'presetKey',"",'presetInitialized',false,'userEdited',false, ...
        'lastPreset',[-40 10],'evaluationBounds',[-40 10], ...
        'displayBounds',[-40 10],'plotInitialized',false);
    app.Cov_Axes.XLimMode = 'auto';

    % Do not impose a Coverage plot X-axis baseline during reset.  The first
    % loaded/computed result establishes it.
    app.Cov_Spinner_XRange.Limits = [-250 100];
    app.Cov_Spinner_XRange.Value = [-40 10];
    app.Cov_Spinner_XMin.Limits = [-250 100];
    app.Cov_Spinner_XMax.Limits = [-250 100];
    app.Cov_Spinner_XMin.Value = -40;
    app.Cov_Spinner_XMax.Value = 10;

    app.setStatus(app.Cov_StatusBar, 'Coverage workspace reset 🔄', true);
end

function Cov_Button_ClearPushed(app, ~)
    % Clear Coverage DataTips/query markers for selected node/subtree only: Node-aware datatip cleaning (selected subtree, or everything)

    sel = app.Cov_Tree.SelectedNodes;
    if isempty(sel)
        app.setStatus(app.Cov_StatusBar, 'Select a node to clear.', true);
        return
    end

    % Clear selected subtree (leaf-only or parent->children). Ignore checked state here
    % so you can clear hidden artifacts too, if any exist.
    targets = app.covJobNodes(sel);
    if isempty(targets)
        app.setStatus(app.Cov_StatusBar, 'No coverage results under selected node.', true);
        return
    end

    for targetIndex = 1:numel(targets)
        jobData = targets(targetIndex).NodeData;
        if ~isfield(jobData, 'line') || ~isgraphics(jobData.line), continue; end

        for mode = ["cov", "thr"]
            queryTag = sprintf('CovQ_%s_%d', mode, jobData.id);
            delete(app.coverageArtifacts(jobData.line, queryTag));
        end
        delete(findall(jobData.line, 'Type', 'datatip'));
    end


    app.setStatus(app.Cov_StatusBar, 'Selected DataTips and query markers cleared.', true);
end

        function Cov_Button_ExportPushed(app, ~)
            if isempty(app.Cov_Tabel.Data), return; end
            [f, p] = uiputfile({ ...
                '*.csv', 'Comma-delimited text (*.csv)'; ...
                '*.txt', 'Tab-delimited text (*.txt)'; ...
                '*.xlsx', 'Excel (*.xlsx)'}, ...
                'Export Coverage Results', fullfile(app.folderPath, 'coverage_results.csv'));
            if isequal(f, 0), return; end
            try
                outputPath = fullfile(p, f); app.writeExportTable(app.Cov_Tabel.Data, outputPath);
                app.setStatus(app.Cov_StatusBar, ['Coverage results exported to ' outputPath], true);
            catch ME
                app.showError(ME, 'Export Error');
            end
        end

        function Cov_ButtonGroup_CovTypeSelectionChanged(app, ~)
            state = app.Cov_ButtonGroup_Btn_Conical.Value;
            set([app.Cov_Spinner_ConeTH, app.Cov_Spinner_ConePH, ...
                app.Cov_Spinner_ConeAng, app.ConeSpinnerLabel, app.ConeLabel, ...
                app.ConeAngleLabel, app.Cov_DropDown_Orientation, ...
                app.Cov_DropDown_OrientationLabel], 'Enable', state, 'Visible', state);
            if state
                node = app.covPatternTarget();
                if ~isempty(node)
                    app.syncCoveragePattern(node);
                end
                % Report immediately on entering Conical mode; do not wait for
                % a subsequent Orientation dropdown change or Compute action.
                app.reportCoverageOrientationStatus();
            else
                % Remove stale Conical provenance when returning to Spherical mode.
                currentStatus = char(app.Cov_StatusBar.Text);
                currentStatus = regexprep(currentStatus, '\s*\|\s*Orientation <b>.*?</b>', '');
                app.Cov_StatusBar.Text = currentStatus;
            end
        end

        function reportCoverageOrientationStatus(app)
            % Append the currently selected/detected conical orientation to the
            % existing Coverage status without changing the cone-center spinners.
            if ~app.Cov_ButtonGroup_Btn_Conical.Value, return; end
            selected = double(app.Cov_DropDown_Orientation.Value);
            if selected == 0
                    node = app.covPatternTarget();
                if isempty(node) || ~isstruct(node.NodeData) || ~isfield(node.NodeData, 'boresightIndex')
                    return
                end
                index = double(node.NodeData.boresightIndex);
            else
                index = selected;
            end
            if index < 1 || index > numel(app.PrincipalAxes.labels), return; end
            orientationLabel = string(app.PrincipalAxes.labels{index});
            currentStatus = char(app.Cov_StatusBar.Text);
            currentStatus = regexprep(currentStatus, ...
                '\s*\|\s*(Detected|Selected|Resolved)?\s*Orientation <b>.*?</b>$', '');
            message = sprintf('%s | Orientation <b>%s</b>', currentStatus, orientationLabel);
            app.setStatus(app.Cov_StatusBar, message, false);
            app.Cov_StatusBar.UserData = message;
            % orientationMode
        end

        function Cov_DropDown_OrientationValueChanged(app, ~)
            % Auto resolves the detected orientation; any explicit selection is
            % authoritative and must never be replaced during Coverage compute.
            index = double(app.Cov_DropDown_Orientation.Value);
            if index == 0
                node = app.covPatternTarget();
                if ~isempty(node) && isstruct(node.NodeData) && isfield(node.NodeData,'boresightIndex')
                    index = double(node.NodeData.boresightIndex);
                else
                    return
                end
            end
            axesDef = app.PrincipalAxes;
            if index >= 1 && index <= numel(axesDef.theta)
                [app.Cov_Spinner_ConeTH.Value, app.Cov_Spinner_ConePH.Value] = deal(axesDef.theta(index), axesDef.phi(index));
            end
            app.reportCoverageOrientationStatus();
        end

        function Cov_DropDown_ComponentValueChanged(app, ~)
            % User selection is authoritative.  Do not call syncCoveragePattern here:
            % that routine intentionally restores the node's previous component when
            % a pattern node is entered, which would immediately undo this edit.
            node = app.covPatternTarget();
            if isempty(node) || ~isstruct(node.NodeData) || ~isfield(node.NodeData, 'pattern'), return; end
            component = string(app.Cov_DropDown_Component.Value);
            patternData = node.NodeData.pattern;
            if ~ismember(component, string(patternData.Properties.VariableNames)), return; end
            nodeData = node.NodeData;
            nodeData.orientationComponent = component;
            [~, ~, nodeData.boresightIndex] = app.detectOrientation(patternData, nodeData.solidAngle, component);
            nodeData.componentBounds = robustRange(patternData.(component), false);
            node.NodeData = nodeData;
            app.reportCoverageOrientationStatus();
        end

        function label = coverageTableTag(app, centerLabel, coneAngle, isConical)
            if isConical
                % Keep the displayed cone-center text (θ=..., φ=...) intact,
                % but omit '=' only from the compact table VariableName label.
                compactCenter = erase(centerLabel, ["=", ","]);
                label = sprintf('Con %s α%s°', compactCenter, app.fmtNumber(coneAngle));
            else
                label = 'Sph';
            end
        end

        function label = coneCenterLabel(app, theta, phi)
            % Represent a cone center by a principal-axis name when it exactly
            % matches one of the canonical ±X/±Y/±Z directions; otherwise retain
            % the actual user-entered spherical coordinates.
            theta = double(theta);
            phi = mod(double(phi), 360);
            axesDef = app.PrincipalAxes;
            centerVector = [sind(theta) * cosd(phi), sind(theta) * sind(phi), cosd(theta)];
            axisVectors = [sind(axesDef.theta(:)) .* cosd(axesDef.phi(:)), ...
                sind(axesDef.theta(:)) .* sind(axesDef.phi(:)), cosd(axesDef.theta(:))];
            alignment = axisVectors * centerVector(:);
            match = find(alignment >= 1 - 1e-9, 1, 'first');
            if ~isempty(match)
                label = string(axesDef.labels{match});
            else
                label = sprintf('θ=%s°, φ=%s°', app.fmtNumber(theta), app.fmtNumber(phi));
            end
        end

        function objects = coverageArtifacts(app, curveLine, tag)
            % Query projections belong to the Coverage axes; DataTips belong to the curve.
            objects = [findall(app.Cov_Axes, 'Tag', tag); findall(curveLine, 'Tag', tag)];
        end

        function [threshold, coverage] = coverageQueryPoint(~, jobData, mode, request)
            if mode == "cov", [threshold, coverage] = deal(request, interp1(jobData.thr, jobData.cov, request, 'linear', NaN));
            else, [threshold, coverage] = deal(interp1(jobData.inverseCov, jobData.inverseThr, request, 'linear', NaN), request); end
        end

        function [dataIndex, interpolationFactor] = coverageInterpolationLocation(~, jobData, x)
            % Return a Line DataIndex and segment interpolation factor for an exact threshold coordinate.
            % Thresholds are normally ascending, but this helper handles either monotonic direction.
            dataIndex = NaN; interpolationFactor = 0; thr = double(jobData.thr(:));
            if isempty(thr) || ~isfinite(x), return; end
            if x <= min(thr), dataIndex = find(thr == min(thr), 1, 'first'); return; end
            if x >= max(thr), dataIndex = find(thr == max(thr), 1, 'first'); return; end
            ascending = thr(end) >= thr(1);
            if ascending, i = find(thr <= x, 1, 'last');
            else,         i = find(thr >= x, 1, 'last');
            end
            if isempty(i) || i >= numel(thr), dataIndex = NaN; return; end
            denominator = thr(i+1) - thr(i);
            dataIndex = i; interpolationFactor = 0;
            if abs(denominator) > eps,  interpolationFactor = max(0, min(1, (x - thr(i)) / denominator)); end
        end

function covRunQuery(app, mode)
    ax = app.Cov_Axes;
    isCov = mode == "cov";
    if isCov
        q = app.Cov_Spinner_queryCov.Value; % threshold query value (x)
    else
        q = app.Cov_Spinner_queryThresh.Value; % coverage query value (y)
    end
    sel = app.Cov_Tree.SelectedNodes;
    if isempty(sel), app.setStatus(app.Cov_StatusBar, 'Select a node to query.', true); return; end
    jobs = app.covJobNodes(sel); jobs = jobs(ismember(jobs, app.Cov_Tree.CheckedNodes));
    if isempty(jobs), app.setStatus(app.Cov_StatusBar, 'No checked results under selected node.', true); return; end
    fmtDB = @(v) sprintf('%s dB', app.fmtNumber(v));
    fmtPct = @(v) sprintf('%s%%', app.fmtNumber(v));
    dtRows = [ ...
        dataTipTextRow("Threshold", @(x, ~) arrayfun(@(v) fmtDB(v), x, 'UniformOutput', false)); ...
        dataTipTextRow("Coverage", @(~, y) arrayfun(@(v) fmtPct(v), y, 'UniformOutput', false)) ...
    ];
    hit = false;
    for jobIndex = 1:numel(jobs)
        jobData = jobs(jobIndex).NodeData;
        if ~isfield(jobData, 'line') || ~isgraphics(jobData.line), continue; end
        tag = sprintf('CovQ_%s_%d', mode, jobData.id);
        delete(app.coverageArtifacts(jobData.line, tag));
        try
            jobData.line.DataTipTemplate.DataTipRows = dtRows;
        catch
        end
        [x, y] = app.coverageQueryPoint(jobData, mode, q);
        if ~isfinite(x) || ~isfinite(y), continue; end
        col = double(jobData.line.Color);
        % Draw finite, unlabeled projections from the axes origins to the query point.
        line(ax, [x, x], [ax.YLim(1), y], 'Color', col, 'LineStyle', ':', 'HandleVisibility', 'off', 'Tag', tag);
        line(ax, [-250, x], [y, y], 'Color', col, 'LineStyle', ':', 'HandleVisibility', 'off', 'Tag', tag);
        % Create the query tip at the exact interpolated position.  The coordinate
        % form with SnapToDataVertex='off' is authoritative: it prevents MATLAB
        % from resolving the requested query back to the nearest CCDF sample.
        % DataIndex + InterpolationFactor is retained as an explicit line-level
        % interpolation record/fallback for releases that support that property.
        [dataIndex, interpolationFactor] = app.coverageInterpolationLocation(jobData, x);
        if isfinite(dataIndex)
            try
                queryTip = datatip(jobData.line, 'DataIndex', dataIndex, 'InterpolationFactor', interpolationFactor, 'SnapToDataVertex', 'off', 'HandleVisibility', 'off', 'FontSize', 9, 'Tag', tag);
            catch
                % Older releases may not accept InterpolationFactor in the constructor; create at the exact interpolated coordinates.
                queryTip = datatip(jobData.line, x, y, ...
                    'SnapToDataVertex', 'off', 'HandleVisibility', 'off', 'FontSize', 9, 'Tag', tag);
                try
                    queryTip.DataIndex = dataIndex;
                    queryTip.InterpolationFactor = interpolationFactor;
                    queryTip.SnapToDataVertex = 'off';
                catch
                end
            end
        else
            queryTip = datatip(jobData.line, x, y, 'SnapToDataVertex', 'off', 'HandleVisibility', 'off', 'FontSize', 9, 'Tag', tag);
        end
        queryTip.Tag = tag;
        hit = true;
    end
    if hit
        if isCov
            app.setStatus(app.Cov_StatusBar, sprintf('Coverage queried at %s.', fmtDB(q)), false);
        else
            app.setStatus(app.Cov_StatusBar, sprintf('Threshold queried at %s coverage.', fmtPct(q)), false);
        end
    else
        app.setStatus(app.Cov_StatusBar, 'Query value is outside selected checked range.', true);
    end
end

        function Cov_TreeCheckedNodesChanged(app, ~)
            checked = app.Cov_Tree.CheckedNodes;
            jobs = app.covJobNodes();

            for jobIndex = 1:numel(jobs)
                jobData = jobs(jobIndex).NodeData;
                visibility = ismember(jobs(jobIndex), checked);
                jobData.line.Visible = visibility;

                for mode = ["cov", "thr"]
                    queryTag = sprintf('CovQ_%s_%d', mode, jobData.id);
                    set(app.coverageArtifacts(jobData.line, queryTag), 'Visible', visibility);
                end
                set(findall(jobData.line, 'Type', 'datatip'), 'Visible', visibility);
            end

            app.finalizeCoverageJobs(jobs);
        end

        function [maximumCoverage, maximumIndex] = coverageSummaryMaximum(~, thresholds, coverage)
            %COVERAGESUMMARYMAXIMUM Resolve the displayed Coverage maximum.
            % The table uses two decimal places; use the same representation for
            % summary selection.  Descending CCDF curves use the last tied row.
            finite = isfinite(thresholds) & isfinite(coverage);
            idx = find(finite);
            if isempty(idx)
                maximumCoverage = NaN; maximumIndex = NaN; return
            end
            shown = round(coverage(idx), 2);
            maximumCoverage = max(shown);
            k = find(shown == maximumCoverage, 1, 'last');
            maximumIndex = idx(k);
        end

        function updateCoverageSelectionHighlight(app, selectedNode)
            % Highlight the plot line belonging to the selected Coverage job.
            % Selection is visual emphasis only; checked/unchecked state still
            % controls visibility and legend membership.
            jobs = app.covJobNodes();
            for jobIndex = 1:numel(jobs)
                d = jobs(jobIndex).NodeData;
                if ~isfield(d, 'line') || ~isgraphics(d.line), continue; end
                baseWidth = 1.6;
                if isfield(d, 'baseLineWidth') && isfinite(d.baseLineWidth)
                    baseWidth = double(d.baseLineWidth);
                end
                if ~isempty(selectedNode) && isequal(jobs(jobIndex), selectedNode)
                    d.line.LineWidth = max(baseWidth, 2.6);
                else
                    d.line.LineWidth = baseWidth;
                end
            end
        end

        function Cov_TreeSelectionChanged(app, ~)
            sel = app.Cov_Tree.SelectedNodes;
            if isempty(sel) || ~isstruct(sel(1).NodeData)
                app.updateCoverageSelectionHighlight([]);
                app.setStatus(app.Cov_StatusBar, 'Ready.', false); return
            end
            d = sel(1).NodeData;
            app.updateCoverageSelectionHighlight(sel(1));
            patternNode = app.covPatternTarget();
            if ~isempty(patternNode), app.syncCoveragePattern(patternNode); end
            if ~strcmp(d.kind, 'job')
                jobCount = numel(sel(1).Children); suffix = ''; if jobCount ~= 1, suffix = 's'; end
                if strcmp(d.kind, 'results'), nodeType = 'Results'; else, nodeType = 'Pattern'; end
                app.setStatus(app.Cov_StatusBar, sprintf('%s <b>"%s"</b> -- <b>%d</b> coverage job%s.', nodeType, d.name, jobCount, suffix), false);
                % A Pattern node can be prepared for Conical Coverage; report the
                % current resolved/selected orientation only when Conical mode is active.
                if strcmp(d.kind, 'pattern') && app.Cov_ButtonGroup_Btn_Conical.Value
                    app.reportCoverageOrientationStatus();
                end
                return
            end
            [threshold50, coverage50] = app.coverageQueryPoint(d, "thr", 50);
            finiteCov = isfinite(d.cov) & isfinite(d.thr);
            if any(finiteCov)
                [maximumCoverage, maximumIndex] = app.coverageSummaryMaximum(d.thr, d.cov);
                maxText = sprintf('max <b>%s%%</b> @ <b>%s dB</b>', app.fmtNumber(maximumCoverage), app.fmtNumber(d.thr(maximumIndex)));
            else
                maxText = 'max <b>n/a</b>';
            end
            parts = {char(d.label)};
            % Orientation provenance belongs only to conical Coverage results.
            % Spherical jobs must never inherit/report the current Orientation UI
            % selection, and an Auto result is reported simply by the resolved axis.
            if isfield(d,'isConical') && d.isConical && ...
                    isfield(d,'orientationLabel') && string(d.orientationLabel) ~= "n/a"
                parts{end+1} = sprintf('Orientation <b>%s</b>', d.orientationLabel);
            end
            if isfield(d,'thresholdMin') && isfield(d,'thresholdMax')
                parts{end+1} = sprintf('Threshold [%s, %s] dB', app.fmtNumber(d.thresholdMin), app.fmtNumber(d.thresholdMax));
            end
            if isfield(d,'thresholdStep')
                parts{end+1} = sprintf('Step %s dB', app.fmtNumber(d.thresholdStep));
            end
            base = strjoin(parts, ' | ');
            if isfinite(threshold50)
                app.setStatus(app.Cov_StatusBar, sprintf('%s | <b>%s%%</b>-coverage threshold <b>%s dB</b> | %s', base, app.fmtNumber(coverage50), app.fmtNumber(threshold50), maxText), false);
            else
                app.setStatus(app.Cov_StatusBar, sprintf('%s | <b>50%%-coverage unavailable</b> | %s', base, maxText), false);
            end
        end

        function Single_Switch_EHplaneValueChanged(app, ~)
            isEPlane = startsWith(app.Single_Switch_EHplane.Value,'E');
            [cutType, cutValue] = app.planeSettings(isEPlane);
            app.Single_DropDown_cutType.Value = cutType;
            values = app.updateCutControl();
            [~, nearest] = min(abs(values-cutValue)); app.Single_DropDown_cutValue.Value = values(nearest);
            app.onCutChanged();
        end

        function onFFDChanged(app, ~)
            endPerf = app.startPerf("Switch FFD block");
            k = find(strcmp(app.Single_DropDown_FFD.Items, app.Single_DropDown_FFD.Value), 1); app.CutFieldBasisDropDown.UserData = true;
            app.selectBlock(k); app.refresh(); endPerf();
            app.setStatus(app.Single_StatusBar, sprintf('Switched to FFD block %d (%s).', k, app.Single_DropDown_FFD.Value), true);
        end

        function updateViewResults(app, refreshRanges, solidAngle, renderFull, updateCut)
            if nargin < 2, refreshRanges=false; end; if nargin < 3, solidAngle=[]; end
            if nargin < 4, renderFull=true; end; if nargin < 5, updateCut=true; end
            [app.viewSolidAngle, peak, app.boresightIndex] = app.detectOrientation(app.viewTbl, solidAngle, app.comp());
            app.updateSelectedComponentPeak(peak); app.antennaMetrics = app.computeMetrics(peak);
            if refreshRanges
                if ~app.isARComponent(app.comp()) && ismember("E_Total_dB",string(app.viewTbl.Properties.VariableNames)), app.gainLim=app.gainDisplayRange(app.viewTbl.E_Total_dB); end
                app.initRanges();
            end
            app.updateTables(); app.updateMetadata();
            if updateCut, app.updateCutControl(); app.plotCut(); end
            if renderFull, app.renderAllFullPatterns(); end
        end

        function refreshAngularView(app, operation)
            if isempty(app.viewBaseTbl), return; end
            endPerf = app.startPerf(operation);
            app.applyAngularSpan(); app.updateViewResults(); endPerf();
        end

        function onComponentChanged(app, ~)
            hasEField = ~app.srcUD.isGainOnly;
            if ~isempty(app.Single_gridEcut) && isvalid(app.Single_gridEcut)
                app.Single_gridEcut.Visible = hasEField;
                set([app.CheckBox_Et, app.CheckBox_Er, app.CheckBox_El], 'Visible', hasEField);
            end
            if app.srcUD.isGainOnly, app.Single_Switch_EHplaneValueChanged([]); end
            app.updateViewResults(true, app.viewSolidAngle);
        end

        function onCutChanged(app, event)
            if nargin > 1 && ~isempty(event)
                if event.Source == app.Single_DropDown_cutType, app.updateCutControl();
                elseif event.Source == app.CutFieldBasisDropDown, app.CutFieldBasisDropDown.UserData = false; app.updateMetadata(); end
            end
            showBounds = app.Button_HPBW.Value;
            if app.Single_CheckBox_HPBWBounds.Visible ~= showBounds, app.Single_CheckBox_HPBWBounds.Visible = showBounds; end
            if ~showBounds && app.Single_CheckBox_HPBWBounds.Value, app.Single_CheckBox_HPBWBounds.Value = false; end
            app.plotCut();
            if app.Singel_CheckBox_overlayCut.Value, app.drawSpatial3D(); end
        end

        function updateFullPatternPOBVisibility(app)
            % POB visibility is controlled only through the authoritative records.
            app.initializeFullPatternPOBRecords();
            visibleNow = app.Single_CheckBox_POB.Value;
            for k = 1:numel(app.FullPatternPOBRecords)
                record = app.FullPatternPOBRecords{k};
                if isempty(record) || ~isstruct(record), continue; end
                if isfield(record,'tip') && any(isgraphics(record.tip)), record.tip.Visible = visibleNow; end
                if isfield(record,'marker') && any(isgraphics(record.marker)), record.marker.Visible = visibleNow; end
            end
        end

        function ensureFullPatternPOBAnnotations(app, specs)
            if ~app.Single_CheckBox_POB.Value || ~isfinite(app.POBth) || ~isfinite(app.POBph), return; end
            if nargin < 2, specs = app.fullPatternSpecs(); end
            geometry = app.gridGeom(); app.initializeFullPatternPOBRecords(specs);
            theta = app.POBth; phi = mod(app.POBph,360);
            if strcmp(app.Single_Switch_ThetaSpan.Value,'-90° to 90°'), theta = 90-theta; end
            if strcmp(app.Single_Switch_AngularSpan.Value,'-180° to 180°') && phi>180, phi = phi-360; end
            [~,row] = min(abs(geometry.thetaGrid(:,1)-theta));
            [~,col] = min(abs(geometry.phiGrid(1,:)-phi));
            for k = 1:numel(specs)
                source = app.findRenderedPatternSurface(specs(k).axes); if isempty(source), continue; end
                grid = source.CData; if isempty(grid), grid = source.ZData; end; if isempty(grid), continue; end
                index = sub2ind(size(grid),min(row,size(grid,1)),min(col,size(grid,2))); record = app.FullPatternPOBRecords{k};
                healthy = isstruct(record)&&isscalar(record.source)&&isgraphics(record.source)&&isequal(record.source,source)&&isscalar(record.marker)&&isgraphics(record.marker)&&isscalar(record.tip)&&isgraphics(record.tip);
                if healthy, record.marker.Visible = true; record.tip.Visible = true; app.FullPatternPOBRecords{k} = record; continue; end
                if isstruct(record), if any(isgraphics(record.tip(:))), delete(record.tip(isgraphics(record.tip))); end; if any(isgraphics(record.marker(:))), delete(record.marker(isgraphics(record.marker))); end; end
                thetaLabel = 'Theta'; if strcmp(app.Single_Switch_ThetaSpan.Value,'-90° to 90°'), thetaLabel = 'Elevation'; end
                rows = [dataTipTextRow(thetaLabel,geometry.thetaGrid(index),'%.3g°'); dataTipTextRow('Phi',geometry.phiGrid(index),'%.3g°'); dataTipTextRow(app.compLabel(),grid(index),'%.3g dB')];
                record = struct('name',specs(k).name,'source',source,'tip',gobjects(0),'marker',gobjects(0),'dataIndex',index,'gridSize',size(grid));
                [record.tip, record.marker] = app.createPOBDataTip(source,index,record.gridSize,rows); app.FullPatternPOBRecords{k} = record;
            end
        end

        function initializeFullPatternPOBRecords(app, specs)
            if nargin < 2, specs = app.fullPatternSpecs(); end
            if numel(app.FullPatternPOBRecords) ~= numel(specs), app.FullPatternPOBRecords = cell(1,numel(specs)); end
            for k=1:numel(specs), if isempty(app.FullPatternPOBRecords{k})||~isstruct(app.FullPatternPOBRecords{k}), app.FullPatternPOBRecords{k}=struct('name',specs(k).name,'source',gobjects(0),'tip',gobjects(0),'marker',gobjects(0),'dataIndex',NaN,'gridSize',[]); end, end
        end

        function source=findRenderedPatternSurface(~,ax)
            source=findobj(ax,'Type','surface','Tag','APAT_PatternSurface'); if ~isempty(source), source=source(1); end
        end

        function onPOBToggled(app)
            app.updateFullPatternPOBVisibility;
            if app.Single_CheckBox_POB.Value && ~isempty(app.viewTbl)
                app.ensureFullPatternPOBAnnotations();
                app.refreshAnnotations("pob");
                drawnow limitrate nocallbacks
            else
                app.refreshAnnotations("pob");
            end
        end

        function refreshAnnotations(app, mode)
            valid=cellfun(@(h)any(isgraphics(h(:))),app.AnnotationSources); app.AnnotationSources=app.AnnotationSources(valid);
            enabled=mode=="pob"&&app.Single_CheckBox_POB.Value || mode=="hpbw"&&app.Single_CheckBox_HPBWBounds.Value;
            selected=[]; if mode=="hpbw", selected=app.Single_tabCut.SelectedTab; end
            for k=1:numel(app.AnnotationSources)
                source=app.AnnotationSources{k}; annotation=source.UserData; if ~isstruct(annotation)||~isfield(annotation,'kind')||annotation.kind~=mode, continue; end
                if mode=="hpbw"
                    source.Visible=enabled; if isfield(annotation,'tip')&&any(isgraphics(annotation.tip)), annotation.tip.Visible=enabled&&isequal(annotation.tab,selected); end
                    continue
                end
                if enabled&&(~isfield(annotation,'tip')||~any(isgraphics(annotation.tip))||~isfield(annotation,'marker')||~any(isgraphics(annotation.marker)))
                    if isfield(annotation,'tip')&&any(isgraphics(annotation.tip)), delete(annotation.tip(isgraphics(annotation.tip))); end
                    if isfield(annotation,'marker')&&any(isgraphics(annotation.marker)), delete(annotation.marker(isgraphics(annotation.marker))); end
                    rows=[]; if isfield(annotation,'tipRows'), rows=annotation.tipRows; end
                    [annotation.tip,annotation.marker]=app.createPOBDataTip(source,annotation.dataIndex,annotation.gridSize,rows); source.UserData=annotation;
                end
                if isfield(annotation,'tip')&&any(isgraphics(annotation.tip)), annotation.tip.Visible=enabled; end
                if isfield(annotation,'marker')&&any(isgraphics(annotation.marker)), annotation.marker.Visible=enabled; end
            end
        end

        function exportCut(app, ~)
            if isempty(app.viewTbl), return; end
            [angleDeg, componentData, ~, titleText] = app.cutData();
            cutTable = array2table([angleDeg, componentData], 'VariableNames', [{'Angle_deg'}, app.cutCols()]);
            [exportName, exportFolder] = uiputfile({ ...
                '*.csv', 'Comma-delimited text (*.csv)'; ...
                '*.txt', 'Tab-delimited text (*.txt)'}, ...
                'Export Cut', fullfile(app.folderPath, [app.baseName '_cut.csv']));
            if isequal(exportName, 0), return; end
            try
                outputPath = fullfile(exportFolder, exportName); app.writeExportTable(cutTable, outputPath);
                app.setStatus(app.Single_StatusBar, ['Cut (' titleText ') exported to <b>' outputPath '</b>'], true);
            catch ME
                app.showError(ME, 'Export Cut Error');
            end
        end

        function drawContour(app)
            if isempty(app.viewTbl), return; end
            [theta, phi, componentGrid] = app.gridComp(app.viewTbl, app.comp());
            axesHandle = app.Single_Axes_Ctr; geometry = app.gridGeom();
            cla(axesHandle);
            patternSurface = pcolor(axesHandle, phi, theta, componentGrid, ...
                'FaceColor', 'interp', 'LineStyle', 'none', 'Tag', 'APAT_PatternSurface');
            [limits, colorMap] = app.plotTheme(app.Range_Ctr.Value);
            app.applyPlotTheme(axesHandle, limits, colorMap);
            app.formatAngularAxes(axesHandle, 30, 15);
            daspect(axesHandle, [1 1 1]); % Equal angular scale on theta and phi axes
            title(axesHandle, app.compLabel(), 'Interpreter', 'none');
            app.setPatternDataTipTemplate(patternSurface, geometry.thetaGrid, geometry.phiGrid, componentGrid, app.compLabel());
        end

        function syncCoverageXRange(app, event)
            % Coverage Plot Min/Max spinners are the MASTER controls.
            % Their values define the RangeSlider Limits. The RangeSlider is
            % subordinate: dragging it may change the selected XLim and mirror
            % the spinner values, but it must NEVER rewrite/shrink its Limits.
            slider = app.Cov_Spinner_XRange;
            minSpin = app.Cov_Spinner_XMin;
            maxSpin = app.Cov_Spinner_XMax;
            if isempty(slider) || ~isvalid(slider) || app.isClosing || app.coverageRangeState.syncing
                return
            end

            isSliderEvent = isequal(event.Source, slider);
            if isSliderEvent
                selected = sort(double(event.Value));
                selected = max(-250, min(100, selected));
                if diff(selected) <= 0
                    return
                end
                % Subordinate slider movement: keep Limits unchanged.
                minSpin.Value = selected(1);
                maxSpin.Value = selected(2);
                if ~isempty(app.Cov_Axes) && isvalid(app.Cov_Axes)
                    app.Cov_Axes.XLimMode = 'manual';
                    app.Cov_Axes.XLim = selected;
                end
                return
            end

            bounds = sort([double(minSpin.Value), double(maxSpin.Value)]);
            bounds = max(-250, min(100, bounds));
            if diff(bounds) <= 0
                % Preserve the edited spinner endpoint and move only the other
                % endpoint enough to satisfy the RangeSlider invariant.
                minGap = max(slider.Step, eps);
                if isequal(event.Source, minSpin)
                    bounds(2) = min(100, bounds(1) + minGap);
                else
                    bounds(1) = max(-250, bounds(2) - minGap);
                end
            end

            app.coverageRangeState.syncing = true;
            cleanup = onCleanup(@() app.clearCoverageSync());
            % MASTER operation: the two spinners define the actual RangeSlider
            % travel limits. Widen first so Value is never clamped mid-update.
            slider.Limits = [-250 100]; slider.Value = bounds; slider.Limits = bounds;
            minSpin.Value = bounds(1); maxSpin.Value = bounds(2);
            minSpin.Limits = [-250, bounds(2) - 0.1]; maxSpin.Limits = [bounds(1) + 0.1, 100];
            if ~isempty(app.Cov_Axes) && isvalid(app.Cov_Axes)
                app.Cov_Axes.XLimMode = 'manual'; app.Cov_Axes.XLim = bounds;
            end
        end
    end

    methods (Access = private)

        function label = createRightLabel(~, parent, textValue, row, column, varargin)
            label = uilabel(parent, 'Text', textValue, 'HorizontalAlignment', 'right', varargin{:});
            label.Layout.Row = row; label.Layout.Column = column;
        end

        function dropdown = createTextFormatDropdown(~, parent)
            dropdown = uidropdown(parent, ...
                'Items', {'1: Gain Pattern', ...
                '2: Etheta/Ephi — dB magnitude, phase', ...
                '3: Etheta/Ephi — real, imaginary', ...
                '4: POL1=RCP, POL2=LCP — dB magnitude, phase', ...
                '5: POL1=LCP, POL2=RCP — dB magnitude, phase', ...
                '6: POL1=RCP, POL2=LCP — real, imaginary', ...
                '7: POL1=LCP, POL2=RCP — real, imaginary'}, ...
                'ItemsData', {'gain', 'linear_magphase', 'linear_reim', ...
                'rcp_lcp_magphase', 'lcp_rcp_magphase', ...
                'rcp_lcp_reim', 'lcp_rcp_reim'}, ...
                'Value', 'gain', ...
                'Tooltip', 'Interpretation used for CSV/TXT/DAT pattern files.');
        end

        function [tab, gridLayout, axesHandle, rangeSlider, minSpinner, maxSpinner] = ...
                createPatternTab(~, tabGroup, tabTitle, axesTitle, needsAxes)
            tab = uitab(tabGroup, 'Title', tabTitle);
            gridLayout = uigridlayout(tab, 'ColumnWidth', {'fit', '1x'}, 'RowHeight', {'fit', '1x', 'fit'});

            axesHandle = [];
            if needsAxes
                axesHandle = uiaxes(gridLayout);
                title(axesHandle, axesTitle);
                xlabel(axesHandle, 'Phi (degree)');
                ylabel(axesHandle, 'Theta (degree)');
                zlabel(axesHandle, 'Z');
                axesHandle.XLim = [0, 360];
                axesHandle.YLim = [0, 180];
                axesHandle.YDir = 'reverse';
                axesHandle.XTick = 0:30:360;
                axesHandle.YTick = 0:15:180;
                axesHandle.Box = 'on';
                axesHandle.Layout.Row = [1, 3];
                axesHandle.Layout.Column = 2;
                colormap(axesHandle, 'jet');
            end

            rangeSlider = uislider(gridLayout, 'range', 'Limits',[-250, 100], 'Value',[-250, 100], 'Orientation','vertical', 'Step',1);
            rangeSlider.Layout.Row = 2;
            rangeSlider.Layout.Column = 1;

            maxSpinner = uispinner(gridLayout, 'Limits', [-250, 100], 'Value', 100, 'Step', 5);
            maxSpinner.Layout.Row = 1;
            maxSpinner.Layout.Column = 1;

            minSpinner = uispinner(gridLayout, 'Limits', [-250, 100], 'Value', -250, 'Step', 5);
            minSpinner.Layout.Row = 3;
            minSpinner.Layout.Column = 1;
        end

        function createComponents(app)
            app.UIFigure = uifigure(Name = 'Antenna Pattern Analyzer Tool — APAT v3 M7.110', Visible = 'off', Position = [100 100 1136 739], WindowState = 'maximized');
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @closeRequest, true);
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;
            app.Tab1_Single = uitab(app.TabGroup);
            app.Tab1_Single.Title = 'Process Pattern 📡';
            app.Single_Grid = uigridlayout(app.Tab1_Single);
            app.Single_Grid.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.Single_Grid.RowHeight = {'fit', '2x', 'fit', '1x', 'fit'};
            app.Single_Panel_fullPattern = uipanel(app.Single_Grid);
            app.Single_Panel_fullPattern.TitlePosition = 'centertop';
            app.Single_Panel_fullPattern.Title = 'Full Antenna Pattern';
            app.Single_Panel_fullPattern.Visible = 'off';
            app.Single_Panel_fullPattern.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Single_Panel_fullPattern.Layout.Row = [2 3];
            app.Single_Panel_fullPattern.Layout.Column = [1 6];
            app.Single_Panel_fullPattern.FontWeight = 'bold';
            app.Single_gridPanel_full = uigridlayout(app.Single_Panel_fullPattern);
            app.Single_gridPanel_full.ColumnWidth = {'1x'};
            app.Single_gridPanel_full.RowHeight = {'1x'};
            app.Single_tabPlots = uitabgroup(app.Single_gridPanel_full);
            app.Single_tabPlots.SelectionChangedFcn = createCallbackFcn(app, @fullPatternTabChanged, true);
            app.Single_tabPlots.Layout.Row = 1;
            app.Single_tabPlots.Layout.Column = 1;
            [app.Single_tabContour, app.Single_gridContour, app.Single_Axes_Ctr, ...
                app.Range_Ctr, app.Range_Ctr_Min, app.Range_Ctr_Max] = ...
                app.createPatternTab(app.Single_tabPlots, 'Contour Plot', 'Antenna Gain Pattern', true);
            [app.Single_tabCircular, app.Single_gridCircular, ~, ...
                app.Range_Cir, app.Range_Cir_Min, app.Range_Cir_Max] = ...
                app.createPatternTab(app.Single_tabPlots, 'Circular Contour Plot', '', false);
            [app.Single_tab3DSpherical, app.Single_grid3dSpherical, app.Single_Axes_3dSph, ...
                app.Range_3dSph, app.Range_3dSph_Min, app.Range_3dSph_Max] = ...
                app.createPatternTab(app.Single_tabPlots, '3D Spherical Plot', '3D Spherical Plot', true);
            [app.Single_tab3DPolar, app.Single_grid3dPolar, app.Single_Axes_3dPol, ...
                app.Range_3dPol, app.Range_3dPol_Min, app.Range_3dPol_Max] = ...
                app.createPatternTab(app.Single_tabPlots, '3D Polar Plot', '3D Polar Plot', true);
            [app.Single_tab3DRect, app.Single_grid3dRect, app.Single_Axes_3dRect, ...
                app.Range_3dRect, app.Range_3dRect_Min, app.Range_3dRect_Max] = ...
                app.createPatternTab(app.Single_tabPlots, '3D Surface Plot', '3D Surface (Rectangular) Plot', true);
            app.Single_Panel_Rect = uipanel(app.Single_Grid);
            app.Single_Panel_Rect.TitlePosition = 'centertop';
            app.Single_Panel_Rect.Title = 'Antenna Pattern Cut';
            app.Single_Panel_Rect.Visible = 'off';
            app.Single_Panel_Rect.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Single_Panel_Rect.Layout.Row = [2 3];
            app.Single_Panel_Rect.Layout.Column = [7 12];
            app.Single_Panel_Rect.FontWeight = 'bold';
            app.Single_gridPanel_Cut = uigridlayout(app.Single_Panel_Rect);
            app.Single_gridPanel_Cut.ColumnWidth = {'1x'};
            app.Single_gridPanel_Cut.RowHeight = {'1x'};
            app.Single_tabCut = uitabgroup(app.Single_gridPanel_Cut);
            app.Single_tabCut.SelectionChangedFcn = @(~, ~) app.refreshAnnotations("hpbw");
            app.Single_tabCut.Layout.Row = 1;
            app.Single_tabCut.Layout.Column = 1;
            app.Single_tabPolarPlot = uitab(app.Single_tabCut);
            app.Single_tabPolarPlot.Title = 'Polar Cut Plot';
            app.Single_Grid_Polar = uigridlayout(app.Single_tabPolarPlot);
            app.Single_Grid_Polar.ColumnWidth = {'fit', '0.26x', '1x', '0.23x'};
            app.Single_Grid_Polar.RowHeight = {'fit', '0.25x', '1x', 'fit'};
            app.Range_Cut = uislider(app.Single_Grid_Polar, 'range');
            app.Range_Cut.Limits = [-250 100];
            app.Range_Cut.Orientation = 'vertical';
            app.Range_Cut.Step = 1;
            app.Range_Cut.Layout.Row = [2 3];
            app.Range_Cut.Layout.Column = 1;
            app.Range_Cut.Value = [-250 100];
            app.Button_HPBW = uibutton(app.Single_Grid_Polar, 'state');
            app.Button_HPBW.Visible = 'on';
            app.Button_HPBW.Enable = 'on';
            app.Button_HPBW.IconAlignment = 'center';
            app.Button_HPBW.Text = 'HPBW';
            app.Button_HPBW.FontWeight = 'bold';
            app.Button_HPBW.Layout.Row = 1;
            app.Button_HPBW.Layout.Column = 4;
            app.Label_HPBW = uilabel(app.Single_Grid_Polar);
            app.Label_HPBW.HorizontalAlignment = 'center';
            app.Label_HPBW.FontWeight = 'bold';
            app.Label_HPBW.Layout.Row = 2;
            app.Label_HPBW.Layout.Column = 4;
            app.Label_HPBW.Text = '';
            app.Range_Cut_Min = uispinner(app.Single_Grid_Polar);
            app.Range_Cut_Min.Step = 5;
            app.Range_Cut_Min.Limits = [-250 100];
            app.Range_Cut_Min.Layout.Row = 4;
            app.Range_Cut_Min.Layout.Column = 1;
            app.Range_Cut_Min.Value = -250;
            app.Range_Cut_Max = uispinner(app.Single_Grid_Polar);
            app.Range_Cut_Max.Step = 5;
            app.Range_Cut_Max.Limits = [-250 100];
            app.Range_Cut_Max.Layout.Row = 1;
            app.Range_Cut_Max.Layout.Column = 1;
            app.Range_Cut_Max.Value = 100;
            app.Button_ExportCut = uibutton(app.Single_Grid_Polar, 'push');
            app.Button_ExportCut.ButtonPushedFcn = createCallbackFcn(app, @exportCut, true);
            app.Button_ExportCut.FontWeight = 'bold';
            app.Button_ExportCut.Layout.Row = 4;
            app.Button_ExportCut.Layout.Column = 4;
            app.Button_ExportCut.Text = 'Export Cut';
            app.Single_gridEcut = uigridlayout(app.Single_Grid_Polar);
            app.Single_gridEcut.ColumnWidth = {'1x'};
            app.Single_gridEcut.RowHeight = {'1x', '1x', '1x'};
            app.Single_gridEcut.Layout.Row = 3;
            app.Single_gridEcut.Layout.Column = 4;
            app.CheckBox_El = uicheckbox(app.Single_gridEcut);
            app.CheckBox_El.Text = 'E_LCP';
            app.CheckBox_El.Layout.Row = 3;
            app.CheckBox_El.Layout.Column = 1;
            app.CheckBox_El.Value = true;
            app.CheckBox_Er = uicheckbox(app.Single_gridEcut);
            app.CheckBox_Er.Text = 'E_RCP';
            app.CheckBox_Er.Layout.Row = 2;
            app.CheckBox_Er.Layout.Column = 1;
            app.CheckBox_Er.Value = true;
            app.CheckBox_Et = uicheckbox(app.Single_gridEcut);
            app.CheckBox_Et.Text = 'E_Total';
            app.CheckBox_Et.Layout.Row = 1;
            app.CheckBox_Et.Layout.Column = 1;
            app.CheckBox_Et.Value = true;
            app.Single_tabRectPlot = uitab(app.Single_tabCut);
            app.Single_tabRectPlot.Title = 'Rectangular Cut Plot';
            app.Single_gridRect = uigridlayout(app.Single_tabRectPlot);
            app.Single_AxesRect = uiaxes(app.Single_gridRect);
            xlabel(app.Single_AxesRect, 'Theta (degree)')
            ylabel(app.Single_AxesRect, 'Magnitude (dB)')
            zlabel(app.Single_AxesRect, 'Z')
            app.Single_AxesRect.XLim = [0 180];
            app.Single_AxesRect.XTick = [0 15 30 45 60 75 90 105 120 135 150 165 180];
            app.Single_AxesRect.Box = 'on';
            app.Single_AxesRect.Layout.Row = [1 2];
            app.Single_AxesRect.Layout.Column = [1 2];
            app.Single_DropDown_output = uidropdown(app.Single_Grid);
            app.Single_DropDown_output.Items = {'Select Output:'};
            app.Single_DropDown_output.ValueChangedFcn = createCallbackFcn(app, @filterOutput, true);
            app.Single_DropDown_output.Visible = 'off';
            app.Single_DropDown_output.Layout.Row = 3;
            app.Single_DropDown_output.Layout.Column = [13 14];
            app.Single_DropDown_output.Value = 'Select Output:';
            app.Single_tabData = uitabgroup(app.Single_Grid);
            app.Single_tabData.Visible = 'off';
            app.Single_tabData.Layout.Row = 4;
            app.Single_tabData.Layout.Column = [1 14];
            app.Single_tabDataOut = uitab(app.Single_tabData);
            app.Single_tabDataOut.Title = 'Results 📤';
            app.Single_tabDataOut.ButtonDownFcn = @(~, ~) set(app.Single_DropDown_output, 'Visible', 'on');
            app.Single_gridDataOut = uigridlayout(app.Single_tabDataOut);
            app.Single_gridDataOut.ColumnWidth = {'1x'};
            app.Single_gridDataOut.RowHeight = {'1x'};
            app.Single_Table_DataOut = uitable(app.Single_gridDataOut);
            app.Single_Table_DataOut.BackgroundColor = [1 1 1];
            app.Single_Table_DataOut.ColumnWidth = '1x';
            app.Single_Table_DataOut.ColumnRearrangeable = 'on';
            app.Single_Table_DataOut.RowName = 'numbered';
            app.Single_Table_DataOut.ColumnSortable = true;
            app.Single_Table_DataOut.Visible = 'off';
            app.Single_Table_DataOut.Layout.Row = 1;
            app.Single_Table_DataOut.Layout.Column = 1;
            app.Single_tabDataIn = uitab(app.Single_tabData);
            app.Single_tabDataIn.Title = 'Input 📥';
            app.Single_gridDataIn = uigridlayout(app.Single_tabDataIn);
            app.Single_gridDataIn.ColumnWidth = {'1x'};
            app.Single_gridDataIn.RowHeight = {'1x'};
            app.Single_Table_DataIn = uitable(app.Single_gridDataIn);
            app.Single_Table_DataIn.BackgroundColor = [1 1 1];
            app.Single_Table_DataIn.ColumnName = {'Theta'; 'Phi'; 'E-TH-DB'; 'E-PH-DB'; 'E-TH-DG'; 'E-PH-DG'};
            app.Single_Table_DataIn.ColumnRearrangeable = 'on';
            app.Single_Table_DataIn.RowName = 'numbered';
            app.Single_Table_DataIn.ColumnSortable = true;
            app.Single_Table_DataIn.Visible = 'off';
            app.Single_Table_DataIn.Layout.Row = 1;
            app.Single_Table_DataIn.Layout.Column = 1;
            app.MetadataTab = uitab(app.Single_tabData);
            app.MetadataTab.Title = 'Metadata 📋';
            app.Single_gridMetadata = uigridlayout(app.MetadataTab);
            app.Single_gridMetadata.ColumnWidth = {'1x'};
            app.Single_gridMetadata.RowHeight = {'1x'};
            app.Single_Table_metadata = uitable(app.Single_gridMetadata);
            app.Single_Table_metadata.ColumnName = {'Property','Value'}; app.Single_Table_metadata.ColumnWidth = {200,'auto'}; app.Single_Table_metadata.RowName = {};
            app.Single_Table_metadata.Layout.Row = 1;
            app.Single_Table_metadata.Layout.Column = 1;
            app.Single_Panel_plotControl = uipanel(app.Single_Grid);
            app.Single_Panel_plotControl.Title = 'Plot Control 🎨';
            app.Single_Panel_plotControl.Visible = 'off';
            app.Single_Panel_plotControl.Layout.Row = 2;
            app.Single_Panel_plotControl.Layout.Column = [13 14];
            app.Single_gridPanel_Ctrl = uigridlayout(app.Single_Panel_plotControl);
            app.Single_gridPanel_Ctrl.RowHeight = repmat({'fit'}, 1, 15);
            app.ComponentLabel = app.createRightLabel(app.Single_gridPanel_Ctrl, 'Component', 1, 1);
            app.Single_DropDown_Component = uidropdown(app.Single_gridPanel_Ctrl);
            app.Single_DropDown_Component.Items = {'Total Gain', 'Etheta Gain', 'Ephi  Gain', 'RHCP Gain', 'LHCP  Gain', 'Axial Ratio', 'Polarized Gain'};
            app.Single_DropDown_Component.ItemsData = {'E_Total_dB', 'E_TH_dB', 'E_PH_dB', 'E_RCP_dB', 'E_LCP_dB', 'AR_dB', 'Gain_Polarized_dB'};
            app.Single_DropDown_Component.ValueChangedFcn = createCallbackFcn(app, @onComponentChanged, true);
            app.Single_DropDown_Component.Layout.Row = 1;
            app.Single_DropDown_Component.Layout.Column = 2;
            app.Single_DropDown_Component.Value = 'E_Total_dB';
            app.CuttypeDropDownLabel = app.createRightLabel(app.Single_gridPanel_Ctrl, 'Cut type', 2, 1);
            app.Single_DropDown_cutType = uidropdown(app.Single_gridPanel_Ctrl);
            app.Single_DropDown_cutType.Items = {'Phi', 'Theta'};
            app.Single_DropDown_cutType.ValueChangedFcn = createCallbackFcn(app, @onCutChanged, true);
            app.Single_DropDown_cutType.Layout.Row = 2;
            app.Single_DropDown_cutType.Layout.Column = 2;
            app.Single_DropDown_cutType.Value = 'Phi';
            app.Single_DropDown_cutValue = uispinner(app.Single_gridPanel_Ctrl);
            app.Single_DropDown_cutValue.Limits = [0 360];
            app.Single_DropDown_cutValue.Value = 0;
            app.Single_DropDown_cutValue.ValueChangedFcn = createCallbackFcn(app, @onCutChanged, true);
            app.Single_DropDown_cutValue.Layout.Row = 3;
            app.Single_DropDown_cutValue.Layout.Column = 2;
            app.ColorbarmaxLabel = app.createRightLabel(app.Single_gridPanel_Ctrl, 'Colorbar max', 5, 1);
            app.Single_Plot_Cmax = uispinner(app.Single_gridPanel_Ctrl);
            app.Single_Plot_Cmax.Limits = [-250 100];
            app.Single_Plot_Cmax.ValueChangedFcn = createCallbackFcn(app, @onRangeUIChanged, true);
            app.Single_Plot_Cmax.Layout.Row = 5;
            app.Single_Plot_Cmax.Layout.Column = 2;
            app.Single_Plot_Cmax.Value = 100;
            app.ColorbarminLabel = app.createRightLabel(app.Single_gridPanel_Ctrl, 'Colorbar min', 6, 1);
            app.Single_Plot_Cmin = uispinner(app.Single_gridPanel_Ctrl);
            app.Single_Plot_Cmin.Limits = [-250 100];
            app.Single_Plot_Cmin.ValueChangedFcn = createCallbackFcn(app, @onRangeUIChanged, true); % onRangeSpinner
            app.Single_Plot_Cmin.Layout.Row = 6;
            app.Single_Plot_Cmin.Layout.Column = 2;
            app.Single_Plot_Cmin.Value = -250;
            app.ColorbarstepLabel = app.createRightLabel(app.Single_gridPanel_Ctrl, 'Colorbar step', 7, 1);
            app.Single_Plot_Cstep = uispinner(app.Single_gridPanel_Ctrl);
            app.Single_Plot_Cstep.Limits = [0.1, 100];
            app.Single_Plot_Cstep.ValueChangedFcn = @(~, ~) app.applyFullPatternRange(app.ctrLim);
            app.Single_Plot_Cstep.Layout.Row = 7;
            app.Single_Plot_Cstep.Layout.Column = 2;
            app.Single_Label_Clim = app.createRightLabel(app.Single_gridPanel_Ctrl, 'Adjust Colorbar', 8, 1);
            app.Single_Button_Clim = uibutton(app.Single_gridPanel_Ctrl, 'push');
            app.Single_Button_Clim.ButtonPushedFcn = @(~, ~) app.onRangeUIChanged( ...
                [app.Single_Plot_Cmin.Value, app.Single_Plot_Cmax.Value], 0, "all", true);
            app.Single_Button_Clim.Layout.Row = 8;
            app.Single_Button_Clim.Layout.Column = 2;
            app.Single_Button_Clim.Text = 'Apply';
            app.Single_Button_Clim.Tooltip = 'Apply to full-pattern plots; gain-cut limits remain independent for AR.';
            app.View3DLabel = app.createRightLabel(app.Single_gridPanel_Ctrl, '3D view', 9, 1);
            app.Single_DropDown_3DView = uidropdown(app.Single_gridPanel_Ctrl, ...
                'Items', {'Isometric', 'Top (+Z)', 'Bottom (-Z)', ...
                'Right (+X)', 'Left (-X)', 'Front (-Y)', 'Back (+Y)'}, ...
                'ItemsData', {'iso', 'top', 'bottom', 'right', 'left', 'front', 'back'}, ...
                'Value', 'iso', ...
                'ValueChangedFcn', @(~, ~) app.on3DViewChanged(), ...
                'Tooltip', 'Camera direction for the 3D pattern tabs.');
            app.Single_DropDown_3DView.Layout.Row = 9;
            app.Single_DropDown_3DView.Layout.Column = 2;
            app.CutvalueSpinnerLabel = app.createRightLabel(app.Single_gridPanel_Ctrl, 'Cut value', 3, 1);
            app.Single_Switch_EHplane = uiswitch(app.Single_gridPanel_Ctrl, 'slider');
            ePlanePad = repmat(char(160), 1, 8); % Nonbreaking padding centers the switch body.
            app.Single_Switch_EHplane.Items = {[ePlanePad 'E-Plane cut'], 'H-Plane cut'};
            app.Single_Switch_EHplane.ItemsData = {'E-Plane cut', 'H-Plane cut'};
            app.Single_Switch_EHplane.Value = 'E-Plane cut';
            app.Single_Switch_EHplane.ValueChangedFcn = createCallbackFcn(app, @Single_Switch_EHplaneValueChanged, true);
            app.Single_Switch_EHplane.Layout.Row = 12;
            app.Single_Switch_EHplane.Layout.Column = [1 2];
            app.Singel_CheckBox_overlayCut = uicheckbox(app.Single_gridPanel_Ctrl);
            app.Singel_CheckBox_overlayCut.ValueChangedFcn = @(~, ~) app.drawSpatial3D();
            app.Singel_CheckBox_overlayCut.Text = 'Overlay Cut on 3D Plot';
            app.Singel_CheckBox_overlayCut.Layout.Row = 13;
            app.Singel_CheckBox_overlayCut.Layout.Column = [1 2];
            app.Single_CheckBox_POB = uicheckbox(app.Single_gridPanel_Ctrl);
            app.Single_CheckBox_POB.Text = 'Annotate POB';
            app.Single_CheckBox_POB.ValueChangedFcn = @(~, ~) app.onPOBToggled;
            app.Single_CheckBox_POB.Layout.Row = 14;
            app.Single_CheckBox_POB.Layout.Column = [1 2];
            app.Single_CheckBox_HPBWBounds = uicheckbox(app.Single_gridPanel_Ctrl);
            app.Single_CheckBox_HPBWBounds.Text = 'Annotate HPBW Bounds';
            app.Single_CheckBox_HPBWBounds.ValueChangedFcn = @(~, ~) app.refreshAnnotations("hpbw");
            app.Single_CheckBox_HPBWBounds.Layout.Row = 15;
            app.Single_CheckBox_HPBWBounds.Layout.Column = [1 2];
            app.createRightLabel(app.Single_gridPanel_Ctrl, 'Cut fields', 4, 1);
            app.CutFieldBasisDropDown = uidropdown(app.Single_gridPanel_Ctrl, 'Items', {'Circular: RCP/LCP','Linear: Etheta/Ephi'}, 'ItemsData', {'Circular','Linear'}, 'Value', 'Circular', 'Enable', 'off', 'UserData', true, 'ValueChangedFcn', createCallbackFcn(app, @onCutChanged, true));
            app.CutFieldBasisDropDown.Layout.Row = 4; app.CutFieldBasisDropDown.Layout.Column = 2;
            app.Single_Switch_AngularSpan = uiswitch(app.Single_gridPanel_Ctrl, 'slider');
            phiPad = repmat(char(160), 1, 3); % Balance captions without changing values.
            app.Single_Switch_AngularSpan.Items = {['φ span: 0° to 360°' phiPad], '−180° to 180°'};
            app.Single_Switch_AngularSpan.ItemsData = {'0° to 360°', '-180° to 180°'};
            app.Single_Switch_AngularSpan.Value = '0° to 360°';
            app.Single_Switch_AngularSpan.ValueChangedFcn = @(~, ~) app.refreshAngularView("Change angular span");
            app.Single_Switch_AngularSpan.Layout.Row = 10;
            app.Single_Switch_AngularSpan.Layout.Column = [1 2];
            app.Single_Switch_ThetaSpan = uiswitch(app.Single_gridPanel_Ctrl, 'slider');
            thetaPad = repmat(char(160), 1, 2); % Balance captions without changing values.
            app.Single_Switch_ThetaSpan.Items = {'θ span: 0° to 180°', ['−90° to 90°' thetaPad]};
            app.Single_Switch_ThetaSpan.ItemsData = {'0° to 180°', '-90° to 90°'};
            app.Single_Switch_ThetaSpan.Value = '0° to 180°';
            app.Single_Switch_ThetaSpan.ValueChangedFcn = @(~, ~) app.refreshAngularView("Change angular span");
            app.Single_Switch_ThetaSpan.Layout.Row = 11;
            app.Single_Switch_ThetaSpan.Layout.Column = [1 2];
            app.Single_StatusBar = uilabel(app.Single_Grid);
            app.Single_StatusBar.Layout.Row = 5;
            app.Single_StatusBar.Layout.Column = [1 14];
            app.Single_StatusBar.Interpreter = 'html';
            app.Single_StatusBar.Text = 'Ready 🚀';
            app.Single_panelParam = uipanel(app.Single_Grid);
            app.Single_panelParam.Title = 'Inputs & Parameters 🎛️';
            app.Single_panelParam.Layout.Row = 1;
            app.Single_panelParam.Layout.Column = [1 14];
            app.Single_gridPanel_Param = uigridlayout(app.Single_panelParam);
            app.Single_gridPanel_Param.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.Single_gridPanel_Param.RowHeight = {'1x', '1x', '1x'};
            app.InputPatternLabel = app.createRightLabel(app.Single_gridPanel_Param, 'Input Pattern:', 1, 1);
            app.Single_EditField_Path = uieditfield(app.Single_gridPanel_Param, 'text');
            app.Single_EditField_Path.Layout.Row = 1;
            app.Single_EditField_Path.Layout.Column = [2 8];
            app.RxPolLabel = app.createRightLabel(app.Single_gridPanel_Param, 'Rw Sense', 3, 1, 'Visible', 'off');
            app.Single_DropDown_RxPol = uidropdown(app.Single_gridPanel_Param);
            app.Single_DropDown_RxPol.Items = {'Auto', 'RHCP', 'LHCP'};
            app.Single_DropDown_RxPol.Editable = 'on';
            app.Single_DropDown_RxPol.Visible = 'off';
            app.Single_DropDown_RxPol.Layout.Row = 3;
            app.Single_DropDown_RxPol.Layout.Column = 2;
            app.Single_DropDown_RxPol.Value = 'Auto';
            app.IncidentWaveARRwPLFLabel = app.createRightLabel(app.Single_gridPanel_Param, 'Rw (dB)', 3, 3, 'Visible', 'off');
            app.Single_Spinner_Rw = uispinner(app.Single_gridPanel_Param);
            app.Single_Spinner_Rw.Visible = 'off';
            app.Single_Spinner_Rw.Layout.Row = 3;
            app.Single_Spinner_Rw.Layout.Column = 4;
            app.Single_Spinner_Rw.Value = 6;
            app.LossindBLabel = app.createRightLabel(app.Single_gridPanel_Param, 'Loss (−) / Gain (+) dB', 3, 5, 'Visible', 'off');
            app.Single_Spinner_Loss = uispinner(app.Single_gridPanel_Param);
            app.Single_Spinner_Loss.Step = 0.1;
            app.Single_Spinner_Loss.Visible = 'off';
            app.Single_Spinner_Loss.Layout.Row = 3;
            app.Single_Spinner_Loss.Layout.Column = 6;
            app.TransmitPowerLabel = app.createRightLabel(app.Single_gridPanel_Param, 'Tx Pwr (Pt)', 3, 7, 'Visible', 'off');
            app.Single_Spinner_Pt = uispinner(app.Single_gridPanel_Param);
            app.Single_Spinner_Pt.Visible = 'off';
            app.Single_Spinner_Pt.Layout.Row = 3;
            app.Single_Spinner_Pt.Layout.Column = 8;
            app.Single_DropDown_Pt = uidropdown(app.Single_gridPanel_Param);
            app.Single_DropDown_Pt.Items = {'dBW','dBm','Watts'};
            app.Single_DropDown_Pt.Visible = 'off';
            app.Single_DropDown_Pt.Layout.Row = 3;
            app.Single_DropDown_Pt.Layout.Column = 9;
            app.Single_DropDown_Pt.Value = 'dBW';
            app.Single_Button_Load = uibutton(app.Single_gridPanel_Param, 'push');
            app.Single_Button_Load.ButtonPushedFcn = createCallbackFcn(app, @onLoad, true);
            app.Single_Button_Load.FontSize = 14;
            app.Single_Button_Load.FontWeight = 'bold';
            app.Single_Button_Load.Layout.Row = 1;
            app.Single_Button_Load.Layout.Column = [11 12];
            app.Single_Button_Load.Text = '📂 Load File';
            app.DistanceLabel = app.createRightLabel(app.Single_gridPanel_Param, 'Distance', 3, 10, 'Visible', 'off');
            app.Single_Spinner_R = uispinner(app.Single_gridPanel_Param);
            app.Single_Spinner_R.Visible = 'off';
            app.Single_Spinner_R.Layout.Row = 3;
            app.Single_Spinner_R.Layout.Column = 11;
            app.Single_Spinner_R.Value = 1;
            app.Single_DropDown_R = uidropdown(app.Single_gridPanel_Param);
            app.Single_DropDown_R.Items = {'m', 'km'};
            app.Single_DropDown_R.Visible = 'off';
            app.Single_DropDown_R.Layout.Row = 3;
            app.Single_DropDown_R.Layout.Column = 12;
            app.Single_DropDown_R.Value = 'm';
            app.Single_DropDown_step = uidropdown(app.Single_gridPanel_Param);
            app.Single_DropDown_step.Items = {'STEP', 'STEP: 1'};
            app.Single_DropDown_step.ValueChangedFcn = createCallbackFcn(app, @stepChanged, true);
            app.Single_DropDown_step.Enable = 'off';
            app.Single_DropDown_step.Visible = 'off';
            app.Single_DropDown_step.Placeholder = 'STEP';
            app.Single_DropDown_step.Layout.Row = 2;
            app.Single_DropDown_step.Layout.Column = [9 10];
            app.Single_DropDown_step.Value = 'STEP';
            app.Single_Button_Process = uibutton(app.Single_gridPanel_Param, 'push');
            app.Single_Button_Process.ButtonPushedFcn = createCallbackFcn(app, @onProcess, true);
            app.Single_Button_Process.Layout.Row = 1;
            app.Single_Button_Process.Layout.Column = [13 14];
            app.Single_Button_Process.Text = '⚙️ Process';
            app.Single_Button_Coverage = uibutton(app.Single_gridPanel_Param, 'push');
            app.Single_Button_Coverage.ButtonPushedFcn = createCallbackFcn(app, @Single_Button_CoveragePushed, true);
            app.Single_Button_Coverage.FontWeight = 'bold';
            app.Single_Button_Coverage.Visible = 'off';
            app.Single_Button_Coverage.Layout.Row = 3;
            app.Single_Button_Coverage.Layout.Column = [13 14];
            app.Single_Button_Coverage.Text = '📉 Coverage ▶';
            app.Single_Export_Output = uibutton(app.Single_gridPanel_Param, 'push');
            app.Single_Export_Output.ButtonPushedFcn = createCallbackFcn(app, @exportResults, true);
            app.Single_Export_Output.FontWeight = 'bold';
            app.Single_Export_Output.Visible = 'off';
            app.Single_Export_Output.Layout.Row = 2;
            app.Single_Export_Output.Layout.Column = [11 12];
            app.Single_Export_Output.Text = '💾 Export Results';
            app.Single_Export_UAN = uibutton(app.Single_gridPanel_Param, 'push');
            app.Single_Export_UAN.ButtonPushedFcn = createCallbackFcn(app, @exportUAN, true);
            app.Single_Export_UAN.FontWeight = 'bold';
            app.Single_Export_UAN.Visible = 'off';
            app.Single_Export_UAN.Layout.Row = 2;
            app.Single_Export_UAN.Layout.Column = [13 14];
            app.Single_Export_UAN.Text = '💾 Export UAN';
            app.Single_Button_ResetParams = uibutton(app.Single_gridPanel_Param,'push','Text','Reset Params', ...
                'ButtonPushedFcn', createCallbackFcn(app, @resetParams, true));
            app.Single_Button_ResetParams.Layout.Row = 2; app.Single_Button_ResetParams.Layout.Column = [1 3];
            app.TextFormatLabel = app.createRightLabel(app.Single_gridPanel_Param, 'Format:', 2, [4 5]);
            app.Single_DropDown_TextFormat = app.createTextFormatDropdown(app.Single_gridPanel_Param);
            app.Single_DropDown_TextFormat.ValueChangedFcn = createCallbackFcn(app, @onTextFormatChanged, true);
            app.Single_DropDown_TextFormat.Layout.Row = 2;
            app.Single_DropDown_TextFormat.Layout.Column = [6 8];
            app.FFDFreqDropDownLabel = uilabel(app.Single_gridPanel_Param);
            app.FFDFreqDropDownLabel.HorizontalAlignment = 'right';
            app.FFDFreqDropDownLabel.Enable = 'off';
            app.FFDFreqDropDownLabel.Layout.Row = 1;
            app.FFDFreqDropDownLabel.Layout.Column = 9;
            app.FFDFreqDropDownLabel.Text = 'FFD Freq:';
            app.Single_DropDown_FFD = uidropdown(app.Single_gridPanel_Param);
            app.Single_DropDown_FFD.Items = {'Frequencies'};
            app.Single_DropDown_FFD.ValueChangedFcn = createCallbackFcn(app, @onFFDChanged, true);
            app.Single_DropDown_FFD.Enable = 'off';
            app.Single_DropDown_FFD.Layout.Row = 1;
            app.Single_DropDown_FFD.Layout.Column = 10;
            app.Single_DropDown_FFD.Value = 'Frequencies';
            app.Tab2_Coverage = uitab(app.TabGroup);
            app.Tab2_Coverage.Title = 'Compute Coverage 📈';
            app.Cov_Grid = uigridlayout(app.Tab2_Coverage);
            app.Cov_Grid.ColumnWidth = {'0.75x', 'fit', '1x', 'fit', '1x'};
            app.Cov_Grid.RowHeight = {'0.25x', '1x', 'fit'};
            app.Cov_Panel_Param = uipanel(app.Cov_Grid);
            app.Cov_Panel_Param.Title = 'Inputs & Parameters 🎛️';
            app.Cov_Panel_Param.Layout.Row = 1;
            app.Cov_Panel_Param.Layout.Column = [1 5];
            app.Cov_gridPanel_Parm = uigridlayout(app.Cov_Panel_Param);
            app.Cov_gridPanel_Parm.ColumnWidth = {'fit', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.Cov_gridPanel_Parm.RowHeight = {'1x', 'fit', 'fit', 'fit'};
            app.Cov_ButtonGroup_CovType = uibuttongroup(app.Cov_gridPanel_Parm);
            app.Cov_ButtonGroup_CovType.SelectionChangedFcn = createCallbackFcn(app, @Cov_ButtonGroup_CovTypeSelectionChanged, true);
            app.Cov_ButtonGroup_CovType.Title = 'Coverage Type';
            app.Cov_ButtonGroup_CovType.Layout.Row = [1 2];
            app.Cov_ButtonGroup_CovType.Layout.Column = [1 2];
            app.Cov_ButtonGroup_Btn_Spherical = uiradiobutton(app.Cov_ButtonGroup_CovType);
            app.Cov_ButtonGroup_Btn_Spherical.Text = 'Spherical 🌐';
            app.Cov_ButtonGroup_Btn_Spherical.Position = [11 63 91 22];
            app.Cov_ButtonGroup_Btn_Spherical.Value = true;
            app.Cov_ButtonGroup_Btn_Conical = uiradiobutton(app.Cov_ButtonGroup_CovType);
            app.Cov_ButtonGroup_Btn_Conical.Text = 'Conical 🔻';
            app.Cov_ButtonGroup_Btn_Conical.Position = [11 41 82 22];
            app.Cov_DropDown_Orientation = uidropdown(app.Cov_gridPanel_Parm);
            app.Cov_DropDown_Orientation.Items = [{'Auto'}, app.PrincipalAxes.labels];
            app.Cov_DropDown_Orientation.ItemsData = [0, 1:numel(app.PrincipalAxes.labels)];
            app.Cov_DropDown_Orientation.ValueChangedFcn = createCallbackFcn(app, @Cov_DropDown_OrientationValueChanged, true);
            app.Cov_DropDown_Orientation.Enable = 'off';
            app.Cov_DropDown_Orientation.Layout.Row = 3;
            app.Cov_DropDown_Orientation.Layout.Column = 2;
            app.Cov_DropDown_Orientation.Value = 0;
            app.AntennaPatternEditFieldLabel = app.createRightLabel(app.Cov_gridPanel_Parm, 'Antenna Pattern:', 1, 3);
            app.Cov_EditField_filePath = uieditfield(app.Cov_gridPanel_Parm, 'text');
            app.Cov_EditField_filePath.Layout.Row = 1;
            app.Cov_EditField_filePath.Layout.Column = [4 8];
            app.Cov_Button_Load = uibutton(app.Cov_gridPanel_Parm, 'push');
            app.Cov_Button_Load.ButtonPushedFcn = createCallbackFcn(app, @Cov_Button_LoadPushed, true);
            app.Cov_Button_Load.Layout.Row = 1;
            app.Cov_Button_Load.Layout.Column = 9;
            app.Cov_Button_Load.Text = '📂 Load File';
            app.Cov_Button_computeCov = uibutton(app.Cov_gridPanel_Parm, 'push');
            app.Cov_Button_computeCov.ButtonPushedFcn = createCallbackFcn(app, @Cov_Button_computeCovPushed, true);
            app.Cov_Button_computeCov.FontWeight = 'bold';
            app.Cov_Button_computeCov.Enable = 'off';
            app.Cov_Button_computeCov.Layout.Row = 1;
            app.Cov_Button_computeCov.Layout.Column = 10;
            app.Cov_Button_computeCov.Text = '⚙️ Compute Coverage';
            app.Cov_Button_Reset = uibutton(app.Cov_gridPanel_Parm, 'push');
            app.Cov_Button_Reset.ButtonPushedFcn = createCallbackFcn(app, @Cov_Button_ResetPushed, true);
            app.Cov_Button_Reset.Enable = 'off';
            app.Cov_Button_Reset.Layout.Row = 2;
            app.Cov_Button_Reset.Layout.Column = 9;
            app.Cov_Button_Reset.Text = '🔄 Reset';
            app.Cov_Button_Export = uibutton(app.Cov_gridPanel_Parm, 'push');
            app.Cov_Button_Export.ButtonPushedFcn = createCallbackFcn(app, @Cov_Button_ExportPushed, true);
            app.Cov_Button_Export.Enable = 'off';
            app.Cov_Button_Export.Layout.Row = 2;
            app.Cov_Button_Export.Layout.Column = 10;
            app.Cov_Button_Export.Text = '💾 Export Results';
            app.ThresholdMindBSpinnerLabel = app.createRightLabel(app.Cov_gridPanel_Parm, 'Threshold  Min (dB):', 2, 3);
            app.Cov_Spinner_ThreshMin = uispinner(app.Cov_gridPanel_Parm);
            app.Cov_Spinner_ThreshMin.Layout.Row = 2;
            app.Cov_Spinner_ThreshMin.Layout.Column = 4;
            app.Cov_Spinner_ThreshMin.Value = -40;
            app.Cov_Spinner_ThreshMin.ValueChangedFcn = createCallbackFcn(app, @markCoverageThresholdUserEdit, true);
            app.ThresholdMaxdBSpinnerLabel = app.createRightLabel(app.Cov_gridPanel_Parm, 'Threshold  Max (dB):', 2, 5);
            app.Cov_Spinner_ThreshMax = uispinner(app.Cov_gridPanel_Parm);
            app.Cov_Spinner_ThreshMax.Layout.Row = 2;
            app.Cov_Spinner_ThreshMax.Layout.Column = 6;
            app.Cov_Spinner_ThreshMax.Value = 10;
            app.Cov_Spinner_ThreshMax.ValueChangedFcn = createCallbackFcn(app, @markCoverageThresholdUserEdit, true);
            app.StepdBSpinnerLabel = app.createRightLabel(app.Cov_gridPanel_Parm, 'Step (dB):', 2, 7);
            app.Cov_Spinner_Step = uispinner(app.Cov_gridPanel_Parm);
            app.Cov_Spinner_Step.Layout.Row = 2;
            app.Cov_Spinner_Step.Layout.Column = 8;
            app.Cov_Spinner_Step.Value = 1;
            app.Cov_Spinner_Step.ValueChangedFcn = createCallbackFcn(app, @markCoverageThresholdUserEdit, true);
            app.ConeSpinnerLabel = app.createRightLabel(app.Cov_gridPanel_Parm, 'Cone θ₀ (°):', 3, 3, 'Enable', 'off');
            app.Cov_Spinner_ConeTH = uispinner(app.Cov_gridPanel_Parm);
            app.Cov_Spinner_ConeTH.Limits = [0 180];
            app.Cov_Spinner_ConeTH.Enable = 'off';
            app.Cov_Spinner_ConeTH.Layout.Row = 3;
            app.Cov_Spinner_ConeTH.Layout.Column = 4;
            app.ConeLabel = app.createRightLabel(app.Cov_gridPanel_Parm, 'Cone φ₀ (°):', 3, 5, 'Enable', 'off');
            app.Cov_Spinner_ConePH = uispinner(app.Cov_gridPanel_Parm);
            app.Cov_Spinner_ConePH.Limits = [0 360];
            app.Cov_Spinner_ConePH.Enable = 'off';
            app.Cov_Spinner_ConePH.Layout.Row = 3;
            app.Cov_Spinner_ConePH.Layout.Column = 6;
            app.ConeAngleLabel = app.createRightLabel(app.Cov_gridPanel_Parm, 'Cone Angle α (°):', 3, 7, 'Enable', 'off');
            app.Cov_Spinner_ConeAng = uispinner(app.Cov_gridPanel_Parm);
            app.Cov_Spinner_ConeAng.Limits = [0 180];
            app.Cov_Spinner_ConeAng.Enable = 'off';
            app.Cov_Spinner_ConeAng.Layout.Row = 3;
            app.Cov_Spinner_ConeAng.Layout.Column = 8;
            app.Cov_Spinner_ConeAng.Value = 45;
            app.Cov_Button_Clear = uibutton(app.Cov_gridPanel_Parm, 'push');
            app.Cov_Button_Clear.ButtonPushedFcn = createCallbackFcn(app, @Cov_Button_ClearPushed, true);
            app.Cov_Button_Clear.Enable = 'off';
            app.Cov_Button_Clear.Layout.Row = 3;
            app.Cov_Button_Clear.Layout.Column = 9;
            app.Cov_Button_Clear.Text = '🧹 Clear DataTips';
            app.Cov_Button_toMain = uibutton(app.Cov_gridPanel_Parm, 'push');
            app.Cov_Button_toMain.ButtonPushedFcn = @(~, ~) set(app.TabGroup, 'SelectedTab', app.Tab1_Single);
            app.Cov_Button_toMain.Layout.Row = 3;
            app.Cov_Button_toMain.Layout.Column = 10;
            app.Cov_Button_toMain.Text = '📊 To Main ◀ ';
            app.Cov_QueryCoverageLabel = app.createRightLabel(app.Cov_gridPanel_Parm, 'Coverage @ dB:', 4, 3, 'Visible', 'off');
            app.Cov_Spinner_queryCov = uispinner(app.Cov_gridPanel_Parm);
            app.Cov_Spinner_queryCov.ValueDisplayFormat = '%g dB';
            app.Cov_Spinner_queryCov.Visible = 'off';
            app.Cov_Spinner_queryCov.Layout.Row = 4;
            app.Cov_Spinner_queryCov.Layout.Column = 4;
            app.Cov_QueryThresholdLabel = app.createRightLabel(app.Cov_gridPanel_Parm, 'Threshold @ %:', 4, 6, 'Visible', 'off');
            app.Cov_Spinner_queryThresh = uispinner(app.Cov_gridPanel_Parm);
            app.Cov_Spinner_queryThresh.ValueDisplayFormat = '%g%%';
            app.Cov_Spinner_queryThresh.Visible = 'off';
            app.Cov_Spinner_queryThresh.Layout.Row = 4;
            app.Cov_Spinner_queryThresh.Layout.Column = 7;
            app.Cov_Spinner_queryThresh.Value = 50;
            app.Cov_DropDown_ComponentLabel = app.createRightLabel(app.Cov_gridPanel_Parm, 'Component:', 4, 1, 'Enable', 'off');
            app.Cov_DropDown_Component = uidropdown(app.Cov_gridPanel_Parm);
            app.Cov_DropDown_Component.Items = {'E_Total_dB'};
            app.Cov_DropDown_Component.ValueChangedFcn = createCallbackFcn(app, @Cov_DropDown_ComponentValueChanged, true);
            app.Cov_DropDown_Component.Enable = 'off';
            app.Cov_DropDown_Component.Layout.Row = 4;
            app.Cov_DropDown_Component.Layout.Column = 2;
            app.Cov_DropDown_Component.Value = 'E_Total_dB';
            app.Cov_Button_queryCov = uibutton(app.Cov_gridPanel_Parm, 'push');
            app.Cov_Button_queryCov.ButtonPushedFcn = @(~, ~) app.covRunQuery("cov");
            app.Cov_Button_queryCov.Enable = 'off';
            app.Cov_Button_queryCov.Visible = 'off';
            app.Cov_Button_queryCov.Layout.Row = 4;
            app.Cov_Button_queryCov.Layout.Column = 5;
            app.Cov_Button_queryCov.Text = '⯐ Query Coverage';
            app.Cov_Button_queryThresh = uibutton(app.Cov_gridPanel_Parm, 'push');
            app.Cov_Button_queryThresh.ButtonPushedFcn = @(~, ~) app.covRunQuery("thr");
            app.Cov_Button_queryThresh.Enable = 'off';
            app.Cov_Button_queryThresh.Visible = 'off';
            app.Cov_Button_queryThresh.Layout.Row = 4;
            app.Cov_Button_queryThresh.Layout.Column = 8;
            app.Cov_Button_queryThresh.Text = '🔍︎ Query Threshold';
            app.Cov_TextFormatLabel = app.createRightLabel(app.Cov_gridPanel_Parm, 'Format:', 4, 9);
            app.Cov_DropDown_TextFormat = app.createTextFormatDropdown(app.Cov_gridPanel_Parm);
            app.Cov_DropDown_TextFormat.ValueChangedFcn = createCallbackFcn(app, @onCovTextFormatChanged, true);
            app.Cov_DropDown_TextFormat.Layout.Row = 4;
            app.Cov_DropDown_TextFormat.Layout.Column = 10;
            app.Cov_DropDown_OrientationLabel = app.createRightLabel(app.Cov_gridPanel_Parm, 'Orientation 🧭:', 3, 1, 'Enable', 'off');
            app.Cov_StatusBar = uilabel(app.Cov_Grid);
            app.Cov_StatusBar.Layout.Row = 3;
            app.Cov_StatusBar.Layout.Column = [1 5];
            app.Cov_StatusBar.Interpreter = 'html';
            app.Cov_StatusBar.Text = 'Ready 🚀';
            app.Cov_Panel_Results = uipanel(app.Cov_Grid);
            app.Cov_Panel_Results.Title = 'Results';
            app.Cov_Panel_Results.Visible = 'off';
            app.Cov_Panel_Results.Layout.Row = 2;
            app.Cov_Panel_Results.Layout.Column = [1 5];
            app.GridLayout2 = uigridlayout(app.Cov_Panel_Results);
            app.GridLayout2.ColumnWidth = {'1x', 'fit', '1x', 'fit', '1x'};
            app.GridLayout2.RowHeight = {'1x', 'fit'};
            app.Cov_Axes = uiaxes(app.GridLayout2);
            title(app.Cov_Axes, 'Coverage vs Threshold')
            xlabel(app.Cov_Axes, 'Threshold (dB)')
            ylabel(app.Cov_Axes, 'Coverage (%)')
            zlabel(app.Cov_Axes, 'Z')
            app.Cov_Axes.XLimMode = 'auto';
            % Coverage axes are display-only: no pan/zoom/drag interaction.
            app.Cov_Axes.Interactions = dataTipInteraction;
            app.Cov_Axes.Layout.Row = 1;
            app.Cov_Axes.Layout.Column = [2 4];
            app.Cov_Tree = uitree(app.GridLayout2, 'checkbox');
            app.Cov_Tree.SelectionChangedFcn = createCallbackFcn(app, @Cov_TreeSelectionChanged, true);
            app.Cov_Tree.Layout.Row = [1 2];
            app.Cov_Tree.Layout.Column = 1;
            app.Cov_TreeNode_Results = uitreenode(app.Cov_Tree);
            app.Cov_TreeNode_Results.Text = 'Coverage Results';
            app.Cov_Tree.CheckedNodesChangedFcn = createCallbackFcn(app, @Cov_TreeCheckedNodesChanged, true);
            app.Cov_Tabel = uitable(app.GridLayout2);
            app.Cov_Tabel.ColumnWidth = '1x';
            app.Cov_Tabel.RowName = {};
            app.Cov_Tabel.Layout.Row = [1 2];
            app.Cov_Tabel.Layout.Column = 5;
            app.Cov_Spinner_XRange = uislider(app.GridLayout2, 'range');
            app.Cov_Spinner_XRange.Limits = [-250 100];
            app.Cov_Spinner_XRange.ValueChangedFcn = createCallbackFcn(app, @syncCoverageXRange, true);
            app.Cov_Spinner_XRange.ValueChangingFcn = createCallbackFcn(app, @syncCoverageXRange, true);
            app.Cov_Spinner_XRange.Layout.Row = 2;
            app.Cov_Spinner_XRange.Layout.Column = 3;
            app.Cov_Spinner_XRange.Value = [-40 10];
            app.Cov_Spinner_XMax = uispinner(app.GridLayout2);
            app.Cov_Spinner_XMax.ValueChangedFcn = createCallbackFcn(app, @syncCoverageXRange, true);
            app.Cov_Spinner_XMax.Editable = 'on';
            app.Cov_Spinner_XMax.Limits = [-250 100];
            app.Cov_Spinner_XMax.Layout.Row = 2;
            app.Cov_Spinner_XMax.Layout.Column = 4;
            app.Cov_Spinner_XMax.Value = 10;
            app.Cov_Spinner_XMin = uispinner(app.GridLayout2);
            app.Cov_Spinner_XMin.ValueChangedFcn = createCallbackFcn(app, @syncCoverageXRange, true);
            app.Cov_Spinner_XMin.Editable = 'on';
            app.Cov_Spinner_XMin.Limits = [-250 100];
            app.Cov_Spinner_XMin.Layout.Row = 2;
            app.Cov_Spinner_XMin.Layout.Column = 2;
            app.Cov_Spinner_XMin.Value = -40;
            app.UIFigure.Visible = 'on';
        end
    end
    methods (Access = public)

        function closeRequest(app, event)
            %CLOSEREQUEST Public lifecycle entry point for figure callbacks and tests.
            app.closeRequestImpl(event);
        end

        function app = APAT_v3_M7_110_5

            createComponents(app)

            registerApp(app, app.UIFigure)

            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        function report = runSelfTest(app)
            %RUNSELFTEST Deterministic numerical and visual-policy smoke checks.
            theta = (0:30:180).';
            phi = (0:30:330).';
            [phiGrid, thetaGrid] = meshgrid(phi, theta);

            T = table(thetaGrid(:), phiGrid(:), 10 * cosd(thetaGrid(:)).^2, 'VariableNames', {'Theta', 'Phi', 'E_Total_dB'});

            weights = solidWeights(T.Theta, T.Phi);
            omegaError = abs(sum(weights) - 4 * pi);

            [~, resolvedOrientationPeak, axisIndex] = calcOrientation( ...
                T, weights, 'E_Total_dB', app.PrincipalAxes, app.PeakPercentile, app.PeakMaxExcessDB);

            patternOK = all(isfinite(T.Theta)) && all(isfinite(T.Phi)) && ...
                all(T.Theta >= 0 & T.Theta <= 180) && numel(unique(T.Theta)) * numel(unique(T.Phi)) == height(T);
            viewOK = isequal(height(T), numel(T.Theta)) && all(mod(T.Phi,360) >= 0 & mod(T.Phi,360) < 360);

            % Non-canonical regular-grid resampling.
            theta2 = (0:2:180).';
            phi2 = (0:2:358).';
            [p2, t2] = meshgrid(phi2, theta2);
            T2 = table(t2(:), p2(:), 10 * cosd(t2(:)).^2, 'VariableNames', {'Theta', 'Phi', 'E_Total_dB'});

            [R2, ~] = resampleCanonical(T2, 1, 'PeriodicPhi', true, 'LinearPowerForGain', true);

            resampleOK = height(R2) == 181 * 361 && all(isfinite(R2.Theta)) && all(isfinite(R2.Phi));

            range2 = app.coverageDisplayRange([3.2; -100]);
            rangeOK = isequal(range2, [-45, 5]);

            % Numerical equivalence on native samples.
            analytic = 12 * cosd(t2).^2 - 0.5 * sind(p2).^2;
            Ta = table(t2(:), p2(:), analytic(:), 'VariableNames', {'Theta', 'Phi', 'E_Total_dB'});

            [Ra, ~] = resampleCanonical(Ta, 1, 'PeriodicPhi', true, 'LinearPowerForGain', false);

            expected = 12 * cosd(Ra.Theta).^2 - 0.5 * sind(Ra.Phi).^2;
            nativeMask = mod(round(Ra.Theta), 2) == 0 & mod(round(Ra.Phi), 2) == 0 & Ra.Phi < 360;

            numericalError = max(abs(Ra.E_Total_dB(nativeMask) - expected(nativeMask)), [], 'omitnan');
            numericalEquivalent = isfinite(numericalError) && numericalError < 1e-10;

            visualRange = app.gainDisplayRange([3.2; -250; -17]);
            visualRangeOK = isequal(visualRange, [-45, 5]);

            % FFD reader contract: two numeric axis triples plus optional
            % frequency declaration must be recognized as an HFSS FFD header.
            ffdFile = [tempname, '.ffd'];
            ffdID = fopen(ffdFile, 'w');
            if ffdID < 0
                ffdOK = false;
            else
                cleanupFFD = onCleanup(@() delete(ffdFile)); 
                fprintf(ffdID, '0 180 3\n');
                fprintf(ffdID, '-180 180 3\n');
                fprintf(ffdID, '1 0 0 1\n');
                fprintf(ffdID, '2 0 0 1\n');
                fprintf(ffdID, '3 0 0 1\n');
                fprintf(ffdID, '4 0 0 1\n');
                fprintf(ffdID, '5 0 0 1\n');
                fprintf(ffdID, '6 0 0 1\n');
                fprintf(ffdID, '7 0 0 1\n');
                fprintf(ffdID, '8 0 0 1\n');
                fprintf(ffdID, '9 0 0 1\n');
                fclose(ffdID);
                ffdData = readPattern(ffdFile, 'ffd', table());
                ffdOK = ffdData.userData.source == "HFSS FFD" && isscalar(ffdData.blocks) && height(ffdData.blocks{1}) == 9;
            end

            % Exact v2-style isolated-spike regression. Use enough samples
            % for P99.99 to lie below a single isolated spike, as it does in
            % a real full-sphere pattern.
            spikeCount = 100000;
            baselinePeak = 0.02;
            spikeGain = repmat(baselinePeak, spikeCount, 1);
            baselineIndex = 1;
            spikeGain(baselineIndex) = baselinePeak + 10;

            spikePeak = resolvePeak(spikeGain, app.PeakPercentile, app.PeakMaxExcessDB);

            % With repeated baseline samples, the resolved index is not uniquely
            % defined; validate the authoritative peak value/policy instead.
            spikeOK = spikePeak.wasAdjusted && abs(spikePeak.value - baselinePeak) < 1e-12 && spikePeak.rawIndex == baselineIndex;

            spikeGainForRange = repmat(baselinePeak, spikeCount, 1);
            spikeGainForRange(1) = spikeGainForRange(1) + 10;
            spikeDisplayRange = app.gainDisplayRange(spikeGainForRange);
            spikeCoverageRange = app.coverageDisplayRange(spikeGainForRange);
            peakAwareRangeOK = isequal(spikeDisplayRange, [-45, 5]) && isequal(spikeCoverageRange, [-45, 5]);

            report = struct();
            report.passSolidAngle = omegaError < 1e-9;
            report.passOrientation = isfinite(resolvedOrientationPeak.gain) && ...
                axisIndex >= 1 && axisIndex <= numel(app.PrincipalAxes.labels);
            report.passPatternModel = patternOK;
            report.passViewModel = viewOK;
            report.passResampling = resampleOK;
            report.passCoverageRange = rangeOK;
            report.passNumericalEquivalence = numericalEquivalent;
            report.passVisualRange = visualRangeOK;
            report.passPeakAwareRange = peakAwareRangeOK;
            report.passFFDReader = ffdOK;
            report.passARThemeSemantic = app.isARComponent('AR') && ...
                app.isARComponent('AR_dB') && ...
                app.isARComponent('AR dB') && ...
                app.isARComponent('Axial Ratio') && ...
                app.isARComponent('Axial_Ratio');
            report.passIsolatedSpike = spikeOK;

            report.numericalError = numericalError;
            report.visualRange = visualRange;
            report.solidAngleError = omegaError;
            report.orientationIndex = axisIndex;
            report.isolatedSpikeIndex = baselineIndex;
            report.isolatedSpikeResolvedIndex = spikePeak.index;

            report.pass = all([ ...
                report.passSolidAngle, ...
                report.passOrientation, ...
                report.passPatternModel, ...
                report.passViewModel, ...
                report.passResampling, ...
                report.passCoverageRange, ...
                report.passNumericalEquivalence, ...
                report.passVisualRange, ...
                report.passPeakAwareRange, ...
                report.passFFDReader, ...
                report.passARThemeSemantic, ...
                report.passIsolatedSpike]);

            if ~report.pass
                failedChecks = strings(0, 1);
                fields = fieldnames(report);
                for k = 1:numel(fields)
                    if startsWith(fields{k}, 'pass') && islogical(report.(fields{k})) && ~report.(fields{k})
                        failedChecks(end + 1, 1) = string(fields{k}); %#ok<AGROW>
                    end
                end

                error('apat:test:SelfTestFailed', 'Standalone numerical self-test failed: %s. Solid-angle error = %.3g.', ...
                    strjoin(failedChecks, ', '), omegaError);
            end
        end

    end

    methods (Access = public)
        function delete(app)
            % Public destructor: App Designer/graphics callbacks may invoke
            % delete(app) outside the class access scope during window close.
            if app.isClosing, return; end
            app.isClosing = true;
            app.cleanupResources();
            fig = app.UIFigure;
            if ~isempty(fig) && isgraphics(fig)
                delete(fig);
            end
        end
    end
end

function [nHdr, ffdParams] = findHeaderLines(fp)
%FINDHEADERLINES Detect text headers and parse optional HFSS FFD metadata.
% The HFSS FFD header is two numeric triples followed optionally by a
% Frequencies declaration.  Parse the first two non-empty lines explicitly,
% matching the proven APAT v2 reader semantics, while tolerating blank lines
% and both Frequency/Frequencies spellings.

fid = fopen(fp, 'r');
if fid < 0
    error('apat:io:OpenFailed', 'Cannot open file: %s', fp);
end
cleanup = onCleanup(@() fclose(fid));

nHdr = 0;
ffdParams = struct('theta', [], 'phi', [], 'freq', [], 'isFFD', false);

% Read the first two non-empty header lines.  fscanf is deliberately not
% used here because the optional text line after the two triples must remain
% distinguishable when determining NumHeaderLines for readmatrix.
headerTriples = zeros(0, 3);
headerLines = strings(0, 1);

while size(headerTriples, 1) < 2
    line = fgetl(fid);
    if ~ischar(line)
        break
    end

    nHdr = nHdr + 1;
    trimmed = strtrim(line);
    if isempty(trimmed)
        continue
    end

    numericValues = sscanf(trimmed, '%f').';
    if numel(numericValues) == 3
        headerTriples(end + 1, :) = numericValues; %#ok<AGROW>
        headerLines(end + 1, 1) = string(trimmed); %#ok<AGROW>
    else
        % A non-numeric line before the two FFD triples means this is not an
        % HFSS FFD header.  Keep scanning so generic readers still work.
        if isempty(headerTriples)
            break
        end
    end
end

if size(headerTriples, 1) == 2
    ffdParams.theta = struct('start', headerTriples(1, 1), 'stop', headerTriples(1, 2), 'count', round(headerTriples(1, 3)));
    ffdParams.phi = struct('start', headerTriples(2, 1), 'stop', headerTriples(2, 2), 'count', round(headerTriples(2, 3)));

    % The third non-empty header line may declare the frequency count.
    line3 = fgetl(fid);
    while ischar(line3) && isempty(strtrim(line3))
        nHdr = nHdr + 1;
        line3 = fgetl(fid);
    end

    if ischar(line3)
        nHdr = nHdr + 1;
        tokens = regexp(strtrim(line3), '^frequencies?\s+(.+)$', 'tokens', 'once', 'ignorecase');
        if ~isempty(tokens)
            frequencyValues = sscanf(tokens{1}, '%f').';
            if isscalar(frequencyValues)
                % Some HFSS files use "Frequencies N" while the actual
                % frequencies occur on separator rows in the data section.
                % Preserve the count only as metadata; separator rows remain
                % the authoritative frequency values below.
                ffdParams.freq = [];
            else
                ffdParams.freq = frequencyValues(:);
            end
        else
            % The line belongs to the data section.  Rewind to its beginning
            % so readmatrix can consume it when NumHeaderLines is determined.
            nHdr = nHdr - 1;
        end
    end

    ffdParams.isFFD = all(isfinite([ ...
        ffdParams.theta.start, ffdParams.theta.stop, ffdParams.theta.count, ...
        ffdParams.phi.start, ffdParams.phi.stop, ffdParams.phi.count])) && ...
        ffdParams.theta.count >= 1 && ffdParams.phi.count >= 1;
end

if ~ffdParams.isFFD
    % Generic readers still need the number of leading non-data lines.  Find
    % the first line that contains at least four numeric fields.
    frewind(fid);
    nHdr = 0;
    dataPattern = ['^\s*[+-]?(?:\d+\.?\d*|\.\d+)(?:[eEdD][+-]?\d+)?' ...
        '(?:[\s,;]+[+-]?(?:\d+\.?\d*|\.\d+)(?:[eEdD][+-]?\d+)?){3,}\s*$'];
    while true
        pos = ftell(fid); %#ok<NASGU>
        line = fgetl(fid);
        if ~ischar(line)
            break
        end
        if ~isempty(regexp(line, dataPattern, 'once'))
            break
        end
        nHdr = nHdr + 1;
    end
end
end

function out = readPattern(fp, textFormat, tableData)
%APAT.IO.READPATTERN Read APAT-supported pattern/coverage source files.
%   Returns a source adapter struct with rawTbl, blocks, freqs, and userData.
%   This function is UI-independent and intentionally preserves the M2
%   reader semantics while establishing the M3 I/O boundary.

if nargin < 3 || isempty(tableData)
    tableData = table();
end
textFormat = string(textFormat);

    % Universal loader → standardized table {Theta,Phi,Re_Eth,Im_Eth,Re_Eph,Im_Eph} (or gain/coverage table) + raw data + info
    [~, ~, ext] = fileparts(fp);
    ext = upper(erase(ext, '.'));
    out = struct('rawTbl', table(), 'blocks', {{}}, 'freqs', NaN, 'userData', struct('source', ext, 'isGainOnly', false, 'isCoverage', false, 'isDep', false,'isMultiBlock', false,'hasFrequency', false));

    % ---- Excel matrix antenna-pattern workbooks
    if ismember(ext, {'XLSX','XLS'})
        out = readExcelMatrix(fp);
        out.userData = validateSourceModel(out.userData);
        return
    end

    % ---- Generic text tables: gain-only pattern OR coverage results
    if ismember(ext, {'CSV','TXT','DAT'})
        if isempty(tableData)
            opts = detectImportOptions(fp, FileType = 'text', Delimiter = {' ','\t',',',';'}, ConsecutiveDelimitersRule = 'join', LeadingDelimitersRule = 'ignore');
            opts = setvartype(opts, 'double');
            opts = setvaropts(opts, 'TrimNonNumeric', true);
            opts.VariableNamingRule = 'preserve';
            tableData = rmmissing(readtable(fp, opts));
        end
        columnCount = width(tableData); assert(columnCount >= 2 && ~isempty(tableData), ...
            'readFile:InvalidFormat', 'File needs at least two numeric columns.');
        originalTable = tableData; variableNames = string(tableData.Properties.VariableNames); lowerNames = lower(variableNames); hasHeaders = ~all(startsWith(variableNames, "Var"));

        % Detect coverage before applying any selected pattern interpretation.
        firstColumn = tableData{:, 1}; secondColumn = tableData{:, 2};
        coverageHeader = contains(lowerNames(1), "threshold") || any(contains(lowerNames(2:end), "coverage"));
        canBeCoverage = textFormat == "gain" || columnCount < 6 || coverageHeader;
        isCoverage = canBeCoverage && all(isfinite(secondColumn)) && all(secondColumn >= 0 & secondColumn <= 100) && issorted(firstColumn, 'strictmonotonic');
        if isCoverage
            if ~hasHeaders
                tableData.Properties.VariableNames = [{'Threshold_dB'}, cellstr(compose('Coverage_%d', 1:columnCount - 1))];
            end
            out.rawTbl = tableData;
            out.userData.isCoverage = true;
            return
        end

        if textFormat == "gain"
            % Gain-only pattern: infer which of the first two columns spans phi.
            firstSpan = max(firstColumn) - min(firstColumn);
            secondSpan = max(secondColumn) - min(secondColumn);
            if firstSpan > secondSpan
                tableData.Properties.VariableNames(1:2) = {'Phi', 'Theta'};
            else
                tableData.Properties.VariableNames(1:2) = {'Theta', 'Phi'};
            end
            tableData = movevars(tableData, 'Theta', 'Before', 1);
            if ~hasHeaders, originalTable = tableData; end
            out.rawTbl = originalTable;
            out.blocks = {tableData};
            out.userData.isGainOnly = true;
            return
        end

        assert(columnCount >= 6, 'readFile:TextEFieldColumns', 'The selected generic E-field format requires six numeric columns.');
        values = tableData{:, 1:6};
        thetaData = values(:, 1);
        phiData = values(:, 2);
        fieldValues = values(:, 3:6);
        isMagnitudePhase = endsWith(textFormat, "magphase");
        isLinear = startsWith(textFormat, "linear");
        detectedLayout = "not applicable";
        if isMagnitudePhase
            phaseCandidate = max(abs(fieldValues), [], 1, 'omitnan') > 100;
            if phaseCandidate(2) && ~phaseCandidate(3)
                magnitudeColumns = [1, 3]; phaseColumns = [2, 4];
                detectedLayout = "interleaved";
            else
                magnitudeColumns = [1, 2]; phaseColumns = [3, 4];
                detectedLayout = "grouped";
            end
            magnitude = fieldValues(:, magnitudeColumns);
            phase = fieldValues(:, phaseColumns);
            component1 = 10.^(magnitude(:, 1) / 20) .* exp(1i * deg2rad(phase(:, 1)));
            component2 = 10.^(magnitude(:, 2) / 20) .* exp(1i * deg2rad(phase(:, 2)));
        else
            component1 = complex(fieldValues(:, 1), fieldValues(:, 2));
            component2 = complex(fieldValues(:, 3), fieldValues(:, 4));
        end

        if isLinear
            [Etheta, Ephi] = deal(component1, component2);
            [componentNames, rectangularNames] = deal(["E_TH", "E_PH"], ["Re_Eth", "Im_Eth", "Re_Eph", "Im_Eph"]);
        else
            if startsWith(textFormat, "rcp"), [Ercp, Elcp] = deal(component1, component2);
            else, [Elcp, Ercp] = deal(component1, component2);
            end
            Etheta = (Ercp + Elcp) / sqrt(2);
            Ephi = (Ercp - Elcp) / (1i * sqrt(2));
            [componentNames, rectangularNames] = deal(["POL1", "POL2"], ["POL1_real", "POL1_imag", "POL2_real", "POL2_imag"]);
        end

        if isMagnitudePhase
            fieldNames = [componentNames + "_dB", componentNames + "_deg"];
            if detectedLayout == "interleaved", fieldNames = fieldNames([1, 3, 2, 4]); end
        else
            fieldNames = rectangularNames;
        end
        generatedNames = cellstr(["Theta", "Phi", fieldNames]);
        if ~hasHeaders
            originalTable.Properties.VariableNames(1:6) = generatedNames;
        end

        out.userData.source = sprintf('Generic text (%s, %s)', textFormat, detectedLayout);
        out.rawTbl = originalTable;
        out.blocks = {table(thetaData, phiData, real(Etheta), imag(Etheta), real(Ephi), imag(Ephi), ...
            'VariableNames', {'Theta','Phi','Re_Eth','Im_Eth','Re_Eph','Im_Eph'})};
        return
    end

    % ---- TICRA/GRASP cuts (block structured, parsed line-by-line)
    if strcmp(ext, 'CUT') % GRASP *.cut: repeated blocks of [title; V_INI V_INC V_NUM C ICOMP ICUT NCOMP; data]
        % First two cols = V‑Nr, H‑Nr ⟶ skip, next two = re/im pairs
        % Standard GRASP .cut: theta  Re(Eco) Im(Eco) Re(Ecx) Im(Ecx) | The Phi value is in the header; each block = one phi.
        out.userData.source = 'TICRA/GRASP CUT';

        lines = readlines(fp); lines(strlength(strtrim(lines)) == 0) = [];
        thetaBlocks = {}; phiBlocks = {}; dataBlocks = {};
        componentCode = 1; cutCode = 1; lineIndex = 1;
        while lineIndex < numel(lines)
            cutParams = sscanf(lines(lineIndex + 1), '%f');
            assert(numel(cutParams) >= 7, 'parseCutFile:bad', 'Could not parse cut parameter line.');
            angleCount = cutParams(3); componentCode = cutParams(5); cutCode = cutParams(6);
            valuesPerLine = 2 * cutParams(7);
            blockData = reshape(sscanf(strjoin( lines(lineIndex + 2:lineIndex + 1 + angleCount), ' '), '%f'), valuesPerLine, []).';
            thetaBlocks{end + 1, 1} = cutParams(1) + (0:angleCount - 1)' * cutParams(2); %#ok<AGROW>
            phiBlocks{end + 1, 1} = repmat(cutParams(4), angleCount, 1); %#ok<AGROW>
            dataBlocks{end + 1, 1} = blockData(:, 1:4); %#ok<AGROW>
            lineIndex = lineIndex + 2 + angleCount;
        end
        thetaData = vertcat(thetaBlocks{:});
        phiData = vertcat(phiBlocks{:});
        numericData = vertcat(dataBlocks{:});
        if cutCode == 2, [thetaData, phiData] = deal(phiData, thetaData); end % ICUT=2: phi swept, theta constant
        negativeTheta = thetaData < 0; % fold negative theta onto opposite phi
        phiData(negativeTheta) = phiData(negativeTheta) + 180; thetaData(negativeTheta) = -thetaData(negativeTheta);
        if isscalar(unique(phiData)) % single cut → body of revolution
            phiCopies = (0:10:350)'; sampleCount = numel(thetaData);
            thetaData = repmat(thetaData, numel(phiCopies), 1);
            phiData = repelem(phiCopies, sampleCount);
            numericData = repmat(numericData, numel(phiCopies), 1);
        end

        if componentCode == 2 % circular RHCP/LHCP
            out.rawTbl = table(thetaData, phiData, numericData(:, 1), numericData(:, 2), numericData(:, 3), numericData(:, 4), 'VariableNames', {'Theta','Phi','Re_RHCP','Im_RHCP','Re_LHCP','Im_LHCP'});
            Ercp = complex(numericData(:, 1), numericData(:, 2));
            Elcp = complex(numericData(:, 3), numericData(:, 4));
            Eth = (Ercp + Elcp) ./ sqrt(2);
            Eph = (Ercp - Elcp) ./ (1i*sqrt(2));
        else % linear co/cx -> Etheta/Ephi
            out.rawTbl = table(thetaData, phiData, numericData(:, 1), numericData(:, 2), numericData(:, 3), numericData(:, 4), 'VariableNames', {'Theta','Phi','Re_Eth','Im_Eth','Re_Eph','Im_Eph'});
            Eth = complex(numericData(:, 1), numericData(:, 2));
            Eph = complex(numericData(:, 3), numericData(:, 4));
        end
        out.blocks = {table(thetaData(:), phiData(:), real(Eth(:)), imag(Eth(:)), real(Eph(:)), imag(Eph(:)), 'VariableNames', {'Theta','Phi','Re_Eth','Im_Eth','Re_Eph','Im_Eph'})};
        return;
    end

    % ---- E-field far-field files
    [nHdr, ffdParams] = findHeaderLines(fp);
    opts = detectImportOptions(fp, FileType = 'text', NumHeaderLines = nHdr, Delimiter = {' ', '\t', ',', ';'}, ConsecutiveDelimitersRule = 'join', LeadingDelimitersRule = 'ignore');
    opts = setvartype(opts, opts.VariableNames, 'double');
    numericData = readmatrix(fp, opts);
    numericData = numericData(~all(isnan(numericData), 2), :); numericData = numericData(:, 1:min(size(numericData, 2), 6));

    switch ext
        case {'FZ','UAN'} % XGTD *.uan/*.fz | Format: Theta	Phi	E_TH_dB	E_PH_dB	E_TH_deg	E_PH_deg
            out.userData.source = sprintf('XGTD %s', ext);
            out.rawTbl = array2table(numericData(:, 1:6), 'VariableNames', {'Theta','Phi','E_TH_dB','E_PH_dB','E_TH_deg','E_PH_deg'});
            thetaData = numericData(:, 1); phiData = numericData(:, 2);
            Eth = 10 .^ (numericData(:, 3) ./ 20) .* exp(1i*deg2rad(numericData(:, 5))); % E_TH_mag = 10^(E_TH_dB/20)
            Eph = 10 .^ (numericData(:, 4) ./ 20) .* exp(1i*deg2rad(numericData(:, 6))); % E_PH_mag = 10^(E_PH_dB/20)

        case 'OUT' % TICRA/GRAP *.out | Format: THETA	PHI	POL-1,real	POL-1,imag	POL-2,real	POL-2,imag (default POL-1/POL-2 are RHCP/LHCP)
            out.userData.source = 'TICRA/GRASP OUT';
            out.rawTbl = array2table(numericData(:, 1:6), 'VariableNames', {'Theta','Phi','Re_RHCP','Im_RHCP','Re_LHCP','Im_LHCP'});
            thetaData = numericData(:, 1); phiData = numericData(:, 2);
            Ercp = complex(numericData(:, 3), numericData(:, 4));
            Elcp = complex(numericData(:, 5), numericData(:, 6));
            Eth = (Ercp + Elcp) ./ sqrt(2);
            Eph = (Ercp - Elcp) ./ (1i * sqrt(2));

        case 'FFS' % CST *.ffs | Format: Phi	Theta	Re(E-TH)	Im(E-TH)	Re(E-PH)	Im(E-PH)
            out.userData.source = 'CST FFS';
            out.rawTbl = array2table(numericData(:, 1:6), 'VariableNames', {'Phi','Theta','Re_Eth','Im_Eth','Re_Eph','Im_Eph'});
            phiData = numericData(:, 1); thetaData = numericData(:, 2);
            Eth = complex(numericData(:, 3), numericData(:, 4));
            Eph = complex(numericData(:, 5), numericData(:, 6));

        case 'FFE' % Feko *.out | Format: Theta	Phi	Re(E-TH)	Im(E-TH)	Re(E-PH)	Im(E-PH)  | Additional columns to be ignored
            out.userData.source = 'FEKO FFE';
            out.rawTbl = array2table(numericData(:, 1:6),'VariableNames', {'Theta','Phi','Re_Eth','Im_Eth','Re_Eph','Im_Eph'});
            thetaData = numericData(:, 1); phiData = numericData(:, 2);
            Eth = complex(numericData(:, 3), numericData(:, 4));
            Eph = complex(numericData(:, 5), numericData(:, 6));

        case 'FFD' % HFSS *.FFD | Format: Re(E-TH)	Im(E-TH)	Re(E-PH)	Im(E-PH)
            out.userData.source = 'HFSS FFD';
            assert(ffdParams.isFFD, 'readFile:ffd', 'FFD header (theta/phi ranges) not found.');
            thetaAxis = linspace(ffdParams.theta.start, ffdParams.theta.stop, ffdParams.theta.count).';
            phiAxis = linspace(ffdParams.phi.start, ffdParams.phi.stop, ffdParams.phi.count).';
            thetaData = repelem(thetaAxis, numel(phiAxis)); phiData = repmat(phiAxis, numel(thetaAxis), 1);

            sepMask = isnan(numericData(:, 1)); % "Frequency <f>" separator rows
            separatorFreqs = numericData(sepMask, 2);
            freqs = [ffdParams.freq; separatorFreqs(~isnan(separatorFreqs))].';
            fieldRows = numericData(~sepMask, 1:4);

            pointsPerBlock = numel(thetaAxis) * numel(phiAxis);
            assert(mod(size(fieldRows, 1), pointsPerBlock) == 0, 'FFD mismatch: row count does not match theta/phi grid');
            blockCount = size(fieldRows, 1)/pointsPerBlock;
            out.userData.isMultiBlock = blockCount>1;
            out.userData.hasFrequency = ~isempty(freqs) && any(isfinite(freqs));
            out.userData.isDep = out.userData.isMultiBlock || out.userData.hasFrequency;

            % Check if Frequency Dependent FFD (if file specify frequency(ies) or not)
            if isempty(freqs), freqs = NaN(1, blockCount); end
            freqs(end+1:blockCount) = NaN; freqs = freqs(1:blockCount); % Align frequency metadata to blocks

            blocks = mat2cell(fieldRows, repmat(pointsPerBlock, blockCount, 1), 4);
            out.blocks = cellfun(@(blockValues) table(thetaData, phiData, blockValues(:, 1), blockValues(:, 2), blockValues(:, 3), blockValues(:, 4), 'VariableNames', {'Theta','Phi','Re_Eth','Im_Eth','Re_Eph','Im_Eph'}), blocks, 'UniformOutput', false);
            out.freqs = freqs;
            out.rawTbl = out.blocks{1};
            return;

        otherwise, error('readFile:unsupported','Unsupported format: %s', ext);
    end
    out.blocks = {table(thetaData(:), phiData(:), real(Eth(:)), imag(Eth(:)), real(Eph(:)), imag(Eph(:)), 'VariableNames', {'Theta','Phi','Re_Eth','Im_Eth','Re_Eph','Im_Eph'})};
end

% Excel Matrix reader.
function out = readExcelMatrix(fp)
%APAT_IO_READEXCELMATRIX Read the supplied antenna-pattern Excel matrix formats.
%   Supported workbook families:
%     Format 1 / linear Eth/Eph sheets: Etheta/Ephi gain+phase matrices.
%     Format 2 / circular RHCP/LHCP sheets: RHCP/LHCP gain+phase matrices.
%     Format 3 / both component-sheet families: both circular and linear matrices.
%
%   Matrix convention in the supplied templates:
%     row 2, columns C onward = phi [deg]
%     column B, rows 3 onward = theta [deg]
%     C3 = first data sample.
%
%   The reader converts every supported source to APAT's canonical complex
%   Etheta/Ephi representation.  The original matrix values are retained in
%   rawTbl as a long table, while workbook metadata is retained in userData.

    if ~(isfile(fp))
        error('readFile:ExcelNotFound','Excel matrix file does not exist: %s',fp);
    end

    try
        sheets = string(sheetnames(fp));
    catch ME
        error('readFile:ExcelSheets','Unable to inspect Excel workbook "%s": %s',fp,ME.message);
    end

    % The first worksheet is the workbook summary; its display name is not part
    % of the format contract.  Only the component worksheet names are fixed.
    summarySheet = sheets(1);
    circular = ["RHCP_Gain_dBi","RHCP_Phase_degrees", "LHCP_Gain_dBi","LHCP_Phase_degrees"];
    linear = ["Etheta_Gain_dBi","Etheta_Phase_degrees", "Ephi_Gain_dBi","Ephi_Phase_degrees"];
    hasCircular = all(ismember(lower(circular), lower(sheets)));
    hasLinear = all(ismember(lower(linear), lower(sheets)));
    if hasLinear && hasCircular
        formatName = "Excel Matrix Format 3 (Ercp/Elcp + Eth/Eph)";
        required = [circular linear];
    elseif hasLinear
        formatName = "Excel Matrix Format 1 (Eth/Eph)";
        required = linear;
    elseif hasCircular
        formatName = "Excel Matrix Format 2 (Ercp/Elcp)";
        required = circular;
    else
        error('readFile:ExcelMatrixFormat', ...
            ['Unsupported Excel workbook. The first worksheet is treated as the ', ...
             'summary; the remaining worksheets must contain the fixed Eth/Eph ', ...
             'and/or RHCP/LHCP component sheets.']);
    end

    optional = string.empty;

    % Read each component matrix.  The helper trims the template's protected/
    % formatted area and validates that all sheets share exactly the same grid.
    matrices = struct();
    thetaRef = [];
    phiRef = [];
    for k = 1:numel(required)
        sheet = sheets(find(strcmpi(sheets,required(k)),1));
        [theta,phi,data] = readExcelMatrixSheet(fp,sheet);
        if isempty(thetaRef)
            thetaRef = theta;
            phiRef = phi;
        else
            if numel(theta) ~= numel(thetaRef) || numel(phi) ~= numel(phiRef) || ...
                    any(abs(theta(:)-thetaRef(:)) > 1e-9) || any(abs(phi(:)-phiRef(:)) > 1e-9)
                error('readFile:ExcelMatrixGrid', 'All Excel Matrix component sheets must use the same theta/phi grid.');
            end
        end
        matrices.(matlab.lang.makeValidName(required(k))) = data;
    end

    % Reconstruct complex field components.  The workbook quantities are dBi
    % magnitude and degrees phase, as specified by the supplied templates.
    if hasLinear
        Eth = 10.^(matrices.Etheta_Gain_dBi/20) .* exp(1i*deg2rad(matrices.Etheta_Phase_degrees));
        Eph = 10.^(matrices.Ephi_Gain_dBi/20) .* exp(1i*deg2rad(matrices.Ephi_Phase_degrees));
        suppliedBasis = "theta-phi";
        formatCode = "Format1";
        if hasCircular, suppliedBasis = "theta-phi + RHCP/LHCP"; formatCode = "Format3"; end
    else
        Ercp = 10.^(matrices.RHCP_Gain_dBi/20) .* exp(1i*deg2rad(matrices.RHCP_Phase_degrees));
        Elcp = 10.^(matrices.LHCP_Gain_dBi/20) .* exp(1i*deg2rad(matrices.LHCP_Phase_degrees));
        Eth = (Ercp + Elcp) ./ sqrt(2);
        Eph = (Ercp - Elcp) ./ (1i*sqrt(2));
        suppliedBasis = "RHCP/LHCP";
        formatCode = "Format2";
    end

    % Build a long raw table with the actual workbook quantities.  This keeps
    % Input/Data inspection useful without exposing the Excel sheet layout to
    % the rest of APAT.
    thetaGrid = repmat(thetaRef(:),1,numel(phiRef));
    phiGrid = repmat(phiRef(:).',numel(thetaRef),1);
    raw = table(thetaGrid(:),phiGrid(:),real(Eth(:)),imag(Eth(:)),real(Eph(:)),imag(Eph(:)), ...
        'VariableNames',{'Theta','Phi','Re_Eth','Im_Eth','Re_Eph','Im_Eph'});

    for k = 1:numel(required), raw.(matlab.lang.makeValidName(required(k))) = matrices.(matlab.lang.makeValidName(required(k)))(:); end

    block = table(thetaGrid(:),phiGrid(:),real(Eth(:)),imag(Eth(:)),real(Eph(:)),imag(Eph(:)), ...
        'VariableNames',{'Theta','Phi','Re_Eth','Im_Eth','Re_Eph','Im_Eph'});

    metadata = readExcelSummary(fp,summarySheet);
    metadata.source = char(formatName);
    metadata.format = formatCode;
    metadata.file = fp;
    metadata.summarySheet = char(summarySheet);
    metadata.isGainOnly = false;
    metadata.isCoverage = false;
    metadata.isDep = false;
    metadata.isMultiBlock = false;
    metadata.hasFrequency = isfield(metadata,'frequencyMHz') && isfinite(metadata.frequencyMHz);
    metadata.quantityType = "complex-electric-field";
    metadata.absoluteCalibration = true;
    metadata.polarizationBasis = suppliedBasis;
    metadata.matrixGrid = struct('thetaDeg',thetaRef(:),'phiDeg',phiRef(:), 'thetaStepDeg',gridStep(thetaRef),'phiStepDeg',gridStep(phiRef));
    metadata.componentSheets = cellstr(required);
    metadata.optionalComponentSheets = cellstr(optional);

    out = struct('rawTbl',raw,'blocks',{{block}},'freqs',NaN,'userData',metadata);
end

function [theta,phi,data] = readExcelMatrixSheet(fp,sheet)
%APAT_IO_READEXCELMATRIXSHEET Read one C3-origin matrix and trim template area.
    % readcell is deliberate here: readmatrix may auto-detect/trim the
    % spreadsheet data region, which would destroy the template's C3-origin
    % coordinate convention.  readcell preserves the worksheet coordinates.
    try
        C = readcell(fp,'Sheet',char(sheet));
    catch ME
        error('readFile:ExcelMatrixRead','Unable to read Excel matrix sheet "%s": %s',sheet,ME.message);
    end
    if size(C,1) < 3 || size(C,2) < 3
        error('readFile:ExcelMatrixSheet','Sheet "%s" does not contain a C3-origin matrix.',sheet);
    end

    phiCells = C(2,3:end);
    thetaCells = C(3:end,2);
    phiMask = cellfun(@(x) isnumeric(x) && isscalar(x) && isfinite(x),phiCells);
    thetaMask = cellfun(@(x) isnumeric(x) && isscalar(x) && isfinite(x),thetaCells);
    phi = cellfun(@double,phiCells(phiMask));
    theta = cellfun(@double,thetaCells(thetaMask));
    if isempty(theta) || isempty(phi)
        error('readFile:ExcelMatrixSheet','Sheet "%s" has no numeric theta/phi axes.',sheet);
    end

    % The templates require contiguous axes.  Reject a hole rather than
    % silently compressing the grid and shifting matrix samples.
    firstGap = find(~phiMask,1,'first');
    if ~isempty(firstGap) && any(phiMask(firstGap+1:end))
        error('readFile:ExcelMatrixAxis','Sheet "%s" has a gap in the phi axis.',sheet);
    end
    firstGap = find(~thetaMask,1,'first');
    if ~isempty(firstGap) && any(thetaMask(firstGap+1:end))
        error('readFile:ExcelMatrixAxis','Sheet "%s" has a gap in the theta axis.',sheet);
    end

    nTheta = numel(theta);
    nPhi = numel(phi);
    dataCells = C(3:2+nTheta,3:2+nPhi);
    dataNumericMask = cellfun(@(x) isnumeric(x) && isscalar(x) && isfinite(x),dataCells);
    if ~all(dataNumericMask(:))
        error('readFile:ExcelMatrixSheet','Sheet "%s" contains nonnumeric/missing matrix samples.',sheet);
    end
    data = cellfun(@double,dataCells);

    if any(diff(theta) <= 0) || any(diff(phi) <= 0)
        error('readFile:ExcelMatrixAxis','Sheet "%s" must have strictly increasing theta/phi axes.',sheet);
    end
    if theta(1) < -1e-9 || theta(end) > 180+1e-9 || phi(1) < -1e-9 || phi(end) >= 360+1e-9
        error('readFile:ExcelMatrixAxis','Sheet "%s" has angles outside the required [theta 0..180, phi 0..360) domain.',sheet);
    end
end

function metadata = readExcelSummary(fp,sheet)
%APAT_IO_READEXCELSUMMARY Read the supplied Matrix-template summary sheet.
%   The templates intentionally use a fixed summary layout.  Use an explicit
%   worksheet range so readcell cannot collapse trailing columns that contain
%   labels/values only in later rows (notably the Frame Definition H column).
%   All matching is whitespace/case tolerant and Unicode punctuation tolerant.
    metadata = struct();
    try
        % The summary metadata used by APAT is contained in columns A:H.
        % Reading an explicit range is important: readcell may otherwise return
        % a 7-column cell array when the last populated column is sparse.
        C = readcell(fp,'Sheet',char(sheet),'Range','A1:H70');
    catch ME
        error('readFile:ExcelSummary','Unable to read Excel summary sheet "%s": %s',sheet,ME.message);
    end

    % General B-column labels with their value in C/D/E when present.
    for r = 1:size(C,1)
        label = C{r,2};
        if ~(ischar(label) || isstring(label)), continue; end
        label = strtrim(string(label));
        if strlength(label) == 0, continue; end
        value = summaryRowValue(C,r);
        if isempty(value), continue; end
        key = lower(regexprep(label,'[^a-zA-Z0-9]+','_'));
        key = matlab.lang.makeValidName(key);
        if strlength(key)>0
            metadata.(key) = value;
        end
    end

    % Stable, normalized fields used by APAT and useful to callers.
    metadata.patternDescription = summaryValue(C,'Pattern Description:');
    metadata.elementModelNumber = summaryValue(C,'Element Model Number:');
    metadata.elementModelName = summaryValue(C,'Element Model Name:');
    metadata.elementPolarization = summaryValue(C,'Element Polarization:');
    metadata.bandName = summaryValue(C,'Pattern Simulation Band name:');
    metadata.frequencyMHz = summaryNumeric(C,'Pattern Simulation Freq (MHz):');
    metadata.validFrequencyMinMHz = summaryNumeric(C,'Lowest Frequency at which the pattern data in this Excel can be deemed valid (MHz):');
    metadata.validFrequencyMaxMHz = summaryNumeric(C,'Highest Frequency at which the pattern data in this Excel can be deemed valid (MHz):');
    metadata.numberOfAntennas = summaryNumeric(C,'Number of Antennas (1 for single, 2 for pair, …):');
    metadata.patternType = summaryValue(C,'Pattern Type : Receive (Rx), Transmit (Tx), Transmit/Receive (TRx)');
    metadata.templateRevision = summaryValue(C,'Template Revision:');
    metadata.author = summaryValue(C,'Author:');
    metadata.revision = summaryValue(C,'Revision:');
    metadata.serialNumber = summaryValue(C,'S/N:');

    % Angular-step table.  The component rows use columns C/D for theta/phi.
    stepRows = { ...
        'RHCP_Gain_dBi:', 'RHCP_Phase_degrees:', 'LHCP_Gain_dBi:', 'LHCP_Phase_degrees:', ...
        'Etheta_Gain_dBi:', 'Etheta_Phase_degrees:', 'Ephi_Gain_dBi:', 'Ephi_Phase_degrees:'};
    steps = NaN(numel(stepRows),2);
    for k = 1:numel(stepRows)
        idx = findSummaryLabel(C,stepRows{k});
        if ~isempty(idx)
            steps(k,1) = toDouble(C{idx,3});
            steps(k,2) = toDouble(C{idx,4});
        end
    end
    metadata.componentStepRows = steps;

    % Frame-definition block: F=label, G=Az/expression, H=El/handedness.
    % Do NOT assume H exists in the automatically detected readcell extent.
    frame = struct();
    frame.azEl = NaN(3,2);
    frame.names = ["+X direction" "+Y direction" "+Z direction"];
    for k = 1:3
        idx = findSummaryLabel(C,frame.names(k));
        if ~isempty(idx)
            frame.azEl(k,1) = toDouble(C{idx,7});
            frame.azEl(k,2) = toDouble(C{idx,8});
        end
    end
    motionIdx = findSummaryLabel(C,'Motion direction');
    if ~isempty(motionIdx), frame.motionDirection = C{motionIdx,7}; else, frame.motionDirection = []; end
    vehicleIdx = findSummaryLabel(C,'Vehicle String');
    if ~isempty(vehicleIdx), frame.vehicleString = C{vehicleIdx,7}; else, frame.vehicleString = []; end
    handIdx = findSummaryLabel(C,'(az, el) => X conversion');
    if ~isempty(handIdx)
        frame.XExpression = C{handIdx,7};
        if handIdx+1 <= size(C,1), frame.YExpression = C{handIdx+1,7}; end
        if handIdx+2 <= size(C,1), frame.ZExpression = C{handIdx+2,7}; end
        frame.handedness = C{handIdx,8};
    end
    metadata.frameDefinition = frame;

    % Antenna positions: C/D/E on rows beginning at the location label.
    nAnt = metadata.numberOfAntennas;
    if isfinite(nAnt) && nAnt >= 1
        positions = NaN(round(nAnt),3);
        startRow = findSummaryLabel(C,'Antenna locations as list of (X, Y, Z) [Inches]:');
        if ~isempty(startRow)
            for k = 1:size(positions,1)
                rr = startRow + k - 1;
                if rr <= size(C,1)
                    positions(k,:) = [toDouble(C{rr,3}),toDouble(C{rr,4}),toDouble(C{rr,5})];
                end
            end
        end
        metadata.antennaPositionsInches = positions;
    else
        metadata.antennaPositionsInches = zeros(0,3);
    end
end

function value = summaryValue(C,label)
    idx = findSummaryLabel(C,label);
    if isempty(idx), value = []; return; end
    value = summaryRowValue(C,idx);
end

function value = summaryRowValue(C,row)
% Return the first meaningful value after the label cell in a summary row.
% For ordinary B-column fields this is C/D/E; for frame rows the caller reads
% G/H explicitly because those columns have semantic meaning.
    value = [];
    for c = 3:min(size(C,2),5)
        if ~isempty(C{row,c})
            value = C{row,c};
            return
        end
    end
end

function value = summaryNumeric(C,label)
    value = toDouble(summaryValue(C,label));
end

function idx = findSummaryLabel(C,label)
    idx = [];
    target = normalizeSummaryLabel(label);
    for r = 1:size(C,1)
        for c = 1:min(size(C,2),8)
            v = C{r,c};
            if ischar(v) || isstring(v)
                if normalizeSummaryLabel(v) == target
                    idx = r;
                    return
                end
            end
        end
    end
end

function value = normalizeSummaryLabel(value)
% Normalize labels without changing their meaning.  This handles Excel's
% non-breaking spaces, typographic punctuation and harmless whitespace.
    value = lower(strtrim(string(value)));
    value = replace(value,char(160),' ');
    value = replace(value,[char(8211),char(8212),char(8722)],'-');
    value = replace(value,char(8230),'...');
    value = regexprep(value,'\s+',' ');
    value = regexprep(value,'\s*:\s*$',':');
end

function value = toDouble(value)
    if isnumeric(value)
        if isempty(value), value = NaN; else, value = double(value(1)); end
    elseif ischar(value) || isstring(value)
        value = str2double(strtrim(string(value)));
    else
        value = NaN;
    end
end

function coverage = coverageCCDF(gain, regionMask, thresholds, solidAngle)
%APAT_MATH_CCDF Weighted CCDF / coverage using the reference equation.
%
%   CCDF(T) = sum(I(G_i > T) * Omega_i) / Omega_region
%   Coverage(T) [%] = 100 * CCDF(T)
%
% Every threshold is evaluated simultaneously.  The logical indicator
% matrix is the vectorized form of I(G_i > T), so the implementation
% remains directly traceable to the mathematical definition.

    gain = double(gain(:));
    regionMask = logical(regionMask(:));
    solidAngle = double(solidAngle(:));
    thresholds = double(thresholds(:));
    
    valid = regionMask & isfinite(gain) & isfinite(solidAngle) & (solidAngle >= 0);
    
    regionGain = gain(valid);
    regionWeight = solidAngle(valid);
    totalRegionSolidAngle = sum(regionWeight);
    
    coverage = zeros(size(thresholds));
    
    if isempty(regionGain) || totalRegionSolidAngle <= 0
        return
    end
    
    % I(G_i > T_k): one column for every requested threshold.
    indicator = regionGain > thresholds.';
    
    % Direct vectorized form of:
    %   Coverage(T_k) = 100 * sum(I(G_i > T_k) * Omega_i) / Omega_region
    coverage = 100 * (regionWeight.' * indicator).' / totalRegionSolidAngle;
end

function metrics = calcMetrics( ...
    tableData, peakInfo, solidAngle, principalAxes, thetaSpanMode, peakPercentile, peakMaxExcessDB)
%APAT_MATH_COMPUTEMETRICS Calculate scalar antenna metrics.

if isempty(tableData)
    metrics = struct();
    return
end

[gain, ~] = chooseGain(tableData, 'E_Total_dB', 'E_Total_dB');

if nargin < 2 || isempty(peakInfo)
    peakInfo = resolvePeak(gain, peakPercentile, peakMaxExcessDB, tableData.Theta, tableData.Phi);
end

if isfield(peakInfo, 'value')
    peakGain = peakInfo.value;
    peakIndex = peakInfo.index;
else
    peakGain = peakInfo.gain;
    peakIndex = peakInfo.index;
end

peakTheta = tableData.Theta(peakIndex);
peakPhi = tableData.Phi(peakIndex);

if nargin < 3 || isempty(solidAngle) || numel(solidAngle) ~= height(tableData)
    solidAngle = solidWeights(tableData.Theta, tableData.Phi);
end

metricGain = gain;
if isfield(peakInfo, 'wasAdjusted') && peakInfo.wasAdjusted
    metricGain(peakInfo.outlierMask) = NaN;
end

integratedGain = sum(10.^(metricGain / 10) .* solidAngle, 'omitnan');
peakDirectivity = 10 * log10(max(4 * pi * 10^(peakGain / 10) / max(integratedGain, eps), eps));

efficiencyPct = 100 * integratedGain / (4 * pi);
if efficiencyPct < 0 || efficiencyPct > 100
    efficiencyPct = NaN;
end

thetaPhysical = tableData.Theta;
peakThetaPhysical = thetaPhysical(peakIndex);

angularSimilarity = ...
    cosd(thetaPhysical) .* cosd(peakThetaPhysical) + ...
    sind(thetaPhysical) .* sind(peakThetaPhysical) .* ...
    cosd(tableData.Phi - peakPhi);

[~, backIndex] = min(angularSimilarity);

axialRatio = NaN;
if ismember('AR_dB', tableData.Properties.VariableNames)
    axialRatio = tableData.AR_dB(peakIndex);
end

axisIndex = 1;
if isfield(principalAxes, 'index')
    axisIndex = principalAxes.index;
end

if isfield(principalAxes, 'theta')
    axisTheta = principalAxes.theta(axisIndex);
    axisPhi = principalAxes.phi(axisIndex);
else
    axisTheta = peakTheta;
    axisPhi = peakPhi;
end

if axisTheta == 90
    hType = 'Phi';
    hValue = 90;
    if strcmp(thetaSpanMode, '-90° to 90°')
        hValue = 0;
    end
else
    hType = 'Theta';
    hValue = 90;
end

eType = 'Theta';
eValue = axisPhi;

[eAngle, eRows] = calcCutGeometry(tableData, eType, eValue, thetaPhysical);
[hAngle, hRows] = calcCutGeometry(tableData, hType, hValue, thetaPhysical);

ePlaneHPBW = calcHPBW(eAngle, gain(eRows));
hPlaneHPBW = calcHPBW(hAngle, gain(hRows));

metrics = struct( ...
    'PeakGain_dB', peakGain, ...
    'PeakTheta_deg', peakTheta, ...
    'PeakPhi_deg', peakPhi, ...
    'HPBW_EPlane_deg', ePlaneHPBW, ...
    'HPBW_HPlane_deg', hPlaneHPBW, ...
    'FrontBack_dB', peakGain - gain(backIndex), ...
    'PeakDirectivity_dB', peakDirectivity, ...
    'Efficiency_pct', efficiencyPct, ...
    'AxialRatioAtPeak_dB', axialRatio);
end

function [pattern,info] = calcPattern(standard,param,peakPercentile,peakMaxExcessDB)
%APAT_MATH_COMPUTEPATTERN Convert canonical source fields into processed data.
% Keep this hot path allocation-light: avoid temporary Nx4 matrices/structs and
% compute each primitive quantity once before constructing the UI/export table.
info = struct('POB',NaN,'POBth',NaN,'POBph',NaN,'pol','n/a',...
    'pairs',struct('Linear',["E_TH","E_PH"],'Circular',["E_RCP","E_LCP"]));
userData = standard.Properties.UserData;

if isfield(userData,'isGainOnly') && userData.isGainOnly
    pattern = standard;
    if width(pattern)>2
        pattern{:,3:end} = pattern{:,3:end}+param.GainLoss_dB;
    end
    peakInfo = resolvePeak(pattern{:,3},peakPercentile,peakMaxExcessDB,pattern.Theta,pattern.Phi);
    [info.POB,index] = deal(peakInfo.value,peakInfo.index);
    [info.POBth,info.POBph] = deal(pattern.Theta(index),pattern.Phi(index));
    info.peak = peakInfo;
    return
end

Etheta = complex(standard.Re_Eth,standard.Im_Eth).*param.FieldScale;
Ephi = complex(standard.Re_Eph,standard.Im_Eph).*param.FieldScale;
sqrt2 = sqrt(2);
Ercp = (Etheta+1i*Ephi)/sqrt2;
Elcp = (Etheta-1i*Ephi)/sqrt2;

magTheta = abs(Etheta);
magPhi = abs(Ephi);
magRcp = abs(Ercp);
magLcp = abs(Elcp);
totalGain = 10*log10(max(magTheta.^2+magPhi.^2,eps));

peakInfo = resolvePeak(totalGain,peakPercentile,peakMaxExcessDB,standard.Theta,standard.Phi);
[info.POB,index] = deal(peakInfo.value,peakInfo.index);
info.peak = peakInfo;
info.POBth = standard.Theta(index);
info.POBph = standard.Phi(index);

% Keep the four component summaries explicit: the same classification
% drives cut co/cross ordering, displayed polarization, and Auto-Rx sense.
meanPower = struct('E_TH',  mean(magTheta.^2, 'omitnan'), 'E_PH',  mean(magPhi.^2,   'omitnan'), ...
                   'E_RCP', mean(magRcp.^2,   'omitnan'), 'E_LCP', mean(magLcp.^2,   'omitnan'));

if meanPower.E_PH > meanPower.E_TH,    info.pairs.Linear = fliplr(info.pairs.Linear);     end
if meanPower.E_LCP > meanPower.E_RCP,  info.pairs.Circular = fliplr(info.pairs.Circular); end

linearPeakPower = max(meanPower.E_TH, meanPower.E_PH);
circularPeakPower = max(meanPower.E_RCP, meanPower.E_LCP);
if circularPeakPower > linearPeakPower
    info.pol = sprintf('Circular (%s)', replace(info.pairs.Circular(1), ["E_RCP", "E_LCP"], ["RHCP", "LHCP"]));
elseif meanPower.E_TH >= meanPower.E_PH
    info.pol = 'Linear (Vertical)';
else
    info.pol = 'Linear (Horizontal)';
end

% Polarization sense and signed axial ratio.
delta = magRcp - magLcp;
polSense = sign(delta);
polSense(~isfinite(delta)) = 0;
axialRatio = (magRcp + magLcp) ./ max(abs(delta), eps);

% Equal circular components have no handedness.  Treat numerical round-off
% at the scale of the two components as equal without introducing a custom
% tolerance parameter.  Equal components are the linear-polarization limit
% for the signed display, so use the APAT -100 dB floor instead of 0 dB.
equalComponents = isfinite(delta) & abs(delta) <= eps .* max(magRcp + magLcp, 1);
signedAR = min(20*log10(axialRatio), 250) .* polSense;
signedAR(equalComponents) = -100;

if param.RxMode == "Auto",     waveSense = 2*(info.pairs.Circular(1) == "E_RCP") - 1;
elseif param.RxMode == "RHCP", waveSense = 1;
else,                          waveSense = -1;
end

antennaRatio = axialRatio.*polSense;
antennaRatio(polSense==0) = 1e12;
waveRatio = waveSense*10.^(param.RxAR_dB/20);
waveRatio2 = waveRatio^2;
antennaRatio2 = antennaRatio.^2;
plfLinear = 0.5+(4*antennaRatio.*waveRatio+(antennaRatio2-1).*(waveRatio2-1).*cosd(180))./(2*(antennaRatio2+1).*(waveRatio2+1));
plfLinear = min(max(plfLinear,eps),1);
plfDB = 10*log10(plfLinear);

eirpDB = param.Pt_dBW+totalGain;
eirpW = 10.^(eirpDB/10);
pfd = eirpW./(4*pi*param.R_m^2);
electricFieldRMS = sqrt(30*eirpW)./param.R_m;

% Construct output only once all hot-path intermediates are finalized.
ErcpDB = 20*log10(max(magRcp,eps));
ElcpDB = 20*log10(max(magLcp,eps));
EthDB = 20*log10(max(magTheta,eps));
EphDB = 20*log10(max(magPhi,eps));
EthPhase = rad2deg(angle(Etheta));
EphPhase = rad2deg(angle(Ephi));
ErcpPhase = rad2deg(angle(Ercp));
ElcpPhase = rad2deg(angle(Elcp));

pattern = table(standard.Theta,standard.Phi,totalGain,signedAR,ErcpDB,ElcpDB,plfDB,...
    totalGain+plfDB,EthDB,EphDB,EthPhase,EphPhase,ErcpPhase,ElcpPhase,...
    eirpDB,pfd,electricFieldRMS,'VariableNames',...
    {'Theta','Phi','E_Total_dB','AR_dB','E_RCP_dB','E_LCP_dB','PLF_dB',...
     'Gain_PolCorrected_dB','E_TH_dB','E_PH_dB','E_TH_Phase','E_PH_Phase',...
     'E_RCP_Phase','E_LCP_Phase','EIRP_dBW','PFD_Wm2','E_RMS_Vm'});
pattern.Properties.UserData = userData;

end

function [angleDeg,rows,fixedAngle,fixedSymbol,didSnap,requestedAngle] = calcCutGeometry(tableData,cutType,requestedAngle,physicalTheta)
%calcCutGeometry Resolve a snapped full-circle cut.
if nargin<4, physicalTheta = tableData.Theta; end
if strcmp(cutType,'Phi')
    thetaValues = unique(tableData.Theta);
    [snapDistance,snapIndex] = min(abs(thetaValues-requestedAngle));
    fixedAngle = thetaValues(snapIndex); rows = find(abs(tableData.Theta-fixedAngle)<1e-9);
    [angleDeg,order] = sort(tableData.Phi(rows)); rows = rows(order); fixedSymbol = 'θ';
else
    requestedAngle = mod(requestedAngle,360); phiValues = unique(mod(tableData.Phi,360));
    [snapDistance,firstIndex] = min(abs(mod(phiValues-requestedAngle+180,360)-180));
    [~,oppositeIndex] = min(abs(mod(phiValues-phiValues(firstIndex),360)-180));
    fixedAngle = phiValues(firstIndex); wrappedPhi = mod(tableData.Phi,360);
    primaryRows = find(abs(wrappedPhi-fixedAngle)<1e-9);
    oppositeRows = find(abs(wrappedPhi-phiValues(oppositeIndex))<1e-9 & abs(physicalTheta-180)>1e-9);
    [~,primaryOrder] = sort(physicalTheta(primaryRows)); [~,oppositeOrder] = sort(physicalTheta(oppositeRows),'descend');
    primaryRows = primaryRows(primaryOrder); oppositeRows = oppositeRows(oppositeOrder);
    rows = [primaryRows;oppositeRows]; angleDeg = [physicalTheta(primaryRows);360-physicalTheta(oppositeRows)]; fixedSymbol = 'φ';
end
didSnap = snapDistance>0;
end

function [solidAngle, peakInfo, axisIndex] = calcOrientation(patternData, solidAngle, requestedColumn, principalAxes, peakPercentile, peakMaxExcessDB)
%calcOrientation Determine principal-axis cone with maximum weighted energy.
if nargin<3 || isempty(requestedColumn), requestedColumn = "E_Total_dB"; end
if nargin<2 || isempty(solidAngle) || numel(solidAngle)~=height(patternData)
    solidAngle = solidWeights(patternData.Theta,patternData.Phi);
end
[gainDB,~] = chooseGain(patternData,requestedColumn,"E_Total_dB");
peakInfo = resolvePeak(gainDB,peakPercentile,peakMaxExcessDB);
peakInfo.gain = peakInfo.value;
peakInfo.rawGain = peakInfo.rawValue;
if peakInfo.wasAdjusted, gainDB(peakInfo.outlierMask) = NaN; end
sampleWeight = 10.^((gainDB-peakInfo.value)/10).*solidAngle; sampleWeight(~isfinite(sampleWeight)) = 0;
axisVectors = [sind(principalAxes.theta(:)).*cosd(principalAxes.phi(:)),sind(principalAxes.theta(:)).*sind(principalAxes.phi(:)),cosd(principalAxes.theta(:))];
sinTheta = sind(patternData.Theta); phiRad = deg2rad(patternData.Phi);
sampleVectors = [sinTheta.*cos(phiRad),sinTheta.*sin(phiRad),cosd(patternData.Theta)];
coneEnergy = sampleWeight.'*double(sampleVectors*axisVectors.' >= cosd(45));
[~,axisIndex] = max(coneEnergy);
end

function step = gridStep(values)
%gridStep Smallest positive angular/sample spacing.
values = unique(values(isfinite(values)));
d = diff(values); d = d(d>1e-9);
if isempty(d), step = NaN; else, step = min(d); end
end

function [beamwidth, lowerAngle, upperAngle] = calcHPBW(angleDeg,gainDB,peakGain,peakAngle)
%calcHPBW Half-power beamwidth from a circular cut.
[beamwidth,lowerAngle,upperAngle] = deal(NaN);
valid = isfinite(angleDeg)&isfinite(gainDB); angleDeg = angleDeg(valid); gainDB = gainDB(valid);
if numel(gainDB)<3, return; end
if nargin<3 || isempty(peakGain), [peakGain,idx] = max(gainDB); peakAngle = angleDeg(idx); end
if nargin<4 || isempty(peakAngle), [~,idx] = max(gainDB); peakAngle = angleDeg(idx); end
halfPower = peakGain-3;
[relativeAngle,order] = sort(mod(angleDeg-peakAngle+180,360)-180);
relativeGain = gainDB(order);
leftOutside = find(relativeAngle<0 & relativeGain<=halfPower,1,'last');
rightOutside = find(relativeAngle>0 & relativeGain<=halfPower,1,'first');
if isempty(leftOutside)||isempty(rightOutside), return; end
leftIdx = [leftOutside,leftOutside+1]; rightIdx = [rightOutside,rightOutside-1];
if leftIdx(2)>numel(relativeGain)||rightIdx(2)>numel(relativeGain), return; end
leftGain = relativeGain(leftIdx); rightGain = relativeGain(rightIdx);
if diff(leftGain)==0 || diff(rightGain)==0, return; end
leftCross = relativeAngle(leftIdx(1))+diff(relativeAngle(leftIdx))*(halfPower-leftGain(1))/diff(leftGain);
rightCross = relativeAngle(rightIdx(1))+diff(relativeAngle(rightIdx))*(halfPower-rightGain(1))/diff(rightGain);
lowerAngle = peakAngle+leftCross; upperAngle = peakAngle+rightCross; beamwidth = rightCross-leftCross;
end

function tableData = normalizePattern(tableData)
%normalizePattern Map angular coordinates to canonical sphere.
% Canonical convention: Theta [0,180], Phi [0,360], closed Phi seam.
theta = tableData.Theta;
if any(theta < 0)
    if min(theta,[],'omitnan') >= -90 && max(theta,[],'omitnan') <= 90
        tableData.Theta = 90 - theta;
    else
        mask = theta < 0;
        tableData.Theta(mask) = -theta(mask);
        tableData.Phi(mask) = tableData.Phi(mask) + 180;
    end
end
tableData.Theta = mod(tableData.Theta,360);
overPole = tableData.Theta > 180;
tableData.Theta(overPole) = 360-tableData.Theta(overPole);
tableData.Phi(overPole) = tableData.Phi(overPole)+180;
% Normalize all numeric pattern values to a deterministic 5-decimal grid.
% This removes harmless floating-point seam artifacts (e.g. 0 vs 360°
% samples differing only in the 15th decimal) before duplicate-direction
% removal and peak selection.  The policy is applied once at the canonical
% standardization boundary, not repeatedly in the renderers.
numericVars = varfun(@isnumeric, tableData, 'OutputFormat', 'uniform');
if any(numericVars)
    tableData{:, numericVars} = round(tableData{:, numericVars}, 5);
end
tableData.Theta = mod(tableData.Theta, 360);
tableData.Theta(tableData.Theta > 180) = 360 - tableData.Theta(tableData.Theta > 180);
tableData.Phi = mod(tableData.Phi, 360);
tableData.Theta(abs(tableData.Theta) < 1e-12) = 0;
tableData.Phi(abs(tableData.Phi) < 1e-12) = 0;
[~,uniqueRows] = unique(tableData{:,{'Phi','Theta'}},'rows','first');
tableData = tableData(uniqueRows,:);
seam = tableData(abs(tableData.Phi)<1e-10,:);
seam.Phi(:) = 360;
tableData = [tableData; seam];
end

function [result, info] = resampleCanonical(sourceTable, stepDeg, options)
%APAT.MATH.RESAMPLECANONICAL Resample primitive canonical pattern data.
%   E-field sources: interpolate Re/Im field components independently.
%   Gain-only sources: interpolate linear power, then convert back to dB.
%   Complete rectangular grids use the fast regular-grid path; irregular
%   sources use one scattered interpolant per requested quantity.

arguments
    sourceTable table
    stepDeg (1,1) double {mustBePositive} = 1
    options.OutputColumns string = string.empty
    options.PeriodicPhi (1,1) logical = true
    options.LinearPowerForGain (1,1) logical = true
    options.Extrapolation char {mustBeMember(options.Extrapolation,{'nearest','none'})} = 'nearest'
end

names = string(sourceTable.Properties.VariableNames);
if ~all(ismember(["Theta","Phi"], names))
    error('apat:math:InvalidPattern','Source table must contain Theta and Phi.');
end
if isempty(sourceTable)
    error('apat:math:EmptyPattern','Cannot resample an empty pattern.');
end

if isempty(options.OutputColumns)
    outputNames = names(3:end);
else
    outputNames = options.OutputColumns;
end
if isempty(outputNames) || ~all(ismember(outputNames,names))
    missing = outputNames(~ismember(outputNames,names));
    error('apat:math:InvalidColumns','Missing source columns: %s',strjoin(missing,', '));
end

% Preserve the source rows while normalizing angles.  In particular, do not
% normalize phi and then filter the source table using a mask of a different
% length: that can misalign field values at the closing seam.
theta = double(sourceTable.Theta(:));
phiRaw = double(sourceTable.Phi(:));
valid = isfinite(theta) & isfinite(phiRaw) & theta >= -1e-9 & theta <= 180+1e-9;
source = sourceTable(valid,:);
theta = theta(valid);
phiRaw = phiRaw(valid);
phi = mod(phiRaw,360);

% Keep the authoritative phi=0 sample when both 0 and 360 are supplied.
closing = abs(phiRaw-360) <= 1e-9;
keep = ~closing;
source = source(keep,:);
theta = theta(keep);
phi = phi(keep);

% Resolve any remaining duplicate physical directions deterministically.
% This also handles repeated rows generated by source readers.
[~,uniqueIndex] = unique([theta,phi],'rows','stable');
source = source(uniqueIndex,:);
theta = theta(uniqueIndex);
phi = phi(uniqueIndex);

% Canonical target includes the closing 360-degree seam exactly once.
targetTheta = (0:stepDeg:180)';
targetPhi = (0:stepDeg:360)';
if targetPhi(end) ~= 360
    targetPhi(end+1) = 360;
end
[queryPhi,queryTheta] = meshgrid(targetPhi,targetTheta);
result = table(queryTheta(:),queryPhi(:),'VariableNames',{'Theta','Phi'});

sourceTheta = unique(theta,'sorted');
sourcePhi = unique(phi,'sorted');
regular = numel(sourceTheta)*numel(sourcePhi) == numel(theta);
if regular
    [phiGrid,thetaGrid] = meshgrid(sourcePhi,sourceTheta);
    [~,it] = ismember(theta,sourceTheta);
    [~,ip] = ismember(phi,sourcePhi);
    regularIndex = sub2ind(size(phiGrid),it,ip);
    regular = numel(unique(regularIndex)) == numel(regularIndex);
end

fieldColumns = ["Re_Eth","Im_Eth","Re_Eph","Im_Eph"];
isPrimitiveFieldSet = all(ismember(fieldColumns,outputNames));

if regular
    for k = 1:numel(outputNames)
        name = outputNames(k);
        values = source.(char(name));
        gridValues = nan(size(phiGrid),'like',values);
        gridValues(regularIndex) = values;
        queryValues = interpolateRegular(phiGrid,thetaGrid,gridValues, ...
            queryPhi,queryTheta,options.PeriodicPhi,options.Extrapolation);
        result.(char(name)) = queryValues(:);
    end
    method = 'regular-gridded';
else
    samplePhi = phi;
    sampleTheta = theta;
    for k = 1:numel(outputNames)
        name = outputNames(k);
        values = source.(char(name));
        if options.LinearPowerForGain && isGainDBColumn(name) && ~isPrimitiveFieldSet
            values = 10.^(double(values)/10);
            queryLinear = interpolateScattered(samplePhi,sampleTheta,values, queryPhi,queryTheta,options.Extrapolation);
            queryValues = 10*log10(max(queryLinear,realmin('double')));
        else
            queryValues = interpolateScattered(samplePhi,sampleTheta,values, queryPhi,queryTheta,options.Extrapolation);
        end
        result.(char(name)) = queryValues(:);
    end
    method = 'irregular-scattered';
end

if ~isempty(sourceTable.Properties.UserData)
    result.Properties.UserData = sourceTable.Properties.UserData;
end
info = struct( ...
    'method',method, ...
    'stepDeg',stepDeg, ...
    'targetSize',[numel(targetTheta),numel(targetPhi)], ...
    'isRegularSource',regular, ...
    'periodicPhi',options.PeriodicPhi, ...
    'primitiveFieldMode',isPrimitiveFieldSet);
end

function queryValues = interpolateRegular( ...
    phiGrid, thetaGrid, gridValues, queryPhi, queryTheta, periodicPhi, extrapolation)
%INTERPOLATEREGULAR Interpolate a canonical rectangular angular grid.

if periodicPhi
    phiAxis = phiGrid(1, :);
    seamPhi = phiAxis(1) + 360;
    if phiAxis(end) < seamPhi - eps(max(1, abs(seamPhi)))
        % Append one full grid column.  Do not concatenate the scalar seam
        % coordinate with the 2-D Phi grid; that causes a dimension mismatch.
        phiGrid(:, end + 1) = phiGrid(:, 1) + 360;
        thetaGrid(:, end + 1) = thetaGrid(:, 1);
        gridValues(:, end + 1) = gridValues(:, 1);
    end
end

queryValues = interp2(phiGrid, thetaGrid, gridValues, queryPhi, queryTheta, 'linear', NaN);

if strcmp(extrapolation, 'nearest')
    missing = ~isfinite(queryValues);
    if any(missing(:))
        nearestValues = interp2(phiGrid, thetaGrid, gridValues, queryPhi, queryTheta, 'nearest', NaN);
        queryValues(missing) = nearestValues(missing);
    end
end
end

function queryValues = interpolateScattered(samplePhi, sampleTheta, values, queryPhi, queryTheta, extrapolation)
%INTERPOLATESCATTERED Interpolate irregular angular samples.

F = scatteredInterpolant(double(samplePhi(:)), double(sampleTheta(:)), double(values(:)), 'linear', extrapolation);

queryValues = F(queryPhi, queryTheta);
end

function tf = isGainDBColumn(name)
%ISGAINDBCOLUMN Identify gain-like dB quantities for linear-power interpolation.

    key = regexprep(lower(strtrim(string(name))), '[^a-z0-9]', '');
    tf = contains(key, 'gain') || contains(key, 'directivity') || contains(key, 'eirp') || endsWith(key, 'db');
end

function info = resolvePeak(values, percentile, maximumExcessDB, ~, ~)
%resolvePeak Resolve the authoritative APAT peak using the v2 policy.
% A raw peak is accepted unless it exceeds the P99.99 percentile by more than
% maximumExcessDB. If it is an outlier, the highest sample at or below the
% percentile becomes the effective peak. Angular coordinates are accepted for
% API compatibility but do not participate in peak selection.

validateattributes(values, {'numeric'}, {'vector'});

finiteMask = isfinite(values);
finiteValues = values(finiteMask);

info = struct( ...
    'value', NaN, ...
    'index', 1, ...
    'rawValue', NaN, ...
    'rawIndex', 1, ...
    'outlierMask', false(size(values)), ...
    'wasAdjusted', false, ...
    'method', 'P99.99-plus-maximum-excess', ...
    'percentile', percentile, ...
    'maximumExcessDB', maximumExcessDB);

if isempty(finiteValues)
    return
end

[rawValue, rawIndex] = max(values, [], 'omitnan');
percentileValue = prctile(finiteValues, percentile);

info.rawValue = rawValue;
info.rawIndex = rawIndex;

if rawValue <= percentileValue + maximumExcessDB
    info.value = rawValue;
    info.index = rawIndex;
    return
end

outlierMask = finiteMask & values > percentileValue;
candidateMask = finiteMask & ~outlierMask;

if any(candidateMask)
    candidateValues = values;
    candidateValues(~candidateMask) = -Inf;
    [info.value, info.index] = max(candidateValues);
    info.outlierMask = outlierMask;
    info.wasAdjusted = true;
else
    % Defensive fallback for a degenerate one-sample pattern.
    info.value = rawValue;
    info.index = rawIndex;
end

end

function bounds = robustRange(values,roundToFive)
%robustRange Robust display range.
finiteValues = values(isfinite(values));
if isempty(finiteValues), bounds = [-40 0]; return; end
low = min(finiteValues); high = max(finiteValues); spread = high-low;
if spread<1e-9, spread = max(5,abs(high)*0.05); end
lo = low-0.05*spread; hi = high+0.05*spread;
if nargin>=2 && roundToFive
    lo = 5*floor(lo/5); hi = 5*ceil(hi/5);
end
bounds = [lo hi];
end

function [gain,column] = chooseGain(tableData,requestedColumn,defaultColumn)
%chooseGain Resolve requested/total/first gain column.
vars = tableData.Properties.VariableNames;
if nargin<2 || isempty(requestedColumn), requestedColumn = defaultColumn; end
candidates = [string(requestedColumn),"E_Total_dB"];
idx = find(ismember(candidates,string(vars)),1);
if isempty(idx), column = vars{3}; else, column = char(candidates(idx)); end
gain = tableData.(column);
end

function deltaOmega = solidWeights(theta, phi, thetaStep, phiStep)
%solidWeights Exact uniform-cell solid-angle weights.
if nargin < 3 || ~isfinite(thetaStep), thetaStep = gridStep(theta); end
if nargin < 4 || ~isfinite(phiStep), phiStep = gridStep(mod(phi,360)); end
if ~isfinite(thetaStep), thetaStep = 180; end
if ~isfinite(phiStep), phiStep = 360; end
thetaLower = max(theta-thetaStep/2,0);
thetaUpper = min(theta+thetaStep/2,180);
deltaOmega = (cosd(thetaLower)-cosd(thetaUpper))*deg2rad(phiStep);
seamAngle = 180*any(phi<0)+360*~any(phi<0);
deltaOmega(abs(phi-seamAngle)<1e-9) = 0;
end

function metadata = validateSourceModel(metadata)
%APAT.MODEL.VALIDATESOURCE Normalize source metadata semantics.
if nargin == 0 || isempty(metadata), metadata = struct(); end
fields = {'source','isGainOnly','isCoverage','isDep','isMultiBlock','hasFrequency'};
defaults = {'unknown',false,false,false,false,false};
for k = 1:numel(fields)
    if ~isfield(metadata,fields{k}) || isempty(metadata.(fields{k}))
        metadata.(fields{k}) = defaults{k};
    end
end
if ~isfield(metadata,'quantityType') || isempty(metadata.quantityType)
    if metadata.isGainOnly
        metadata.quantityType = "gain-like";
    else
        metadata.quantityType = "complex-electric-field";
    end
end
if ~isfield(metadata,'absoluteCalibration'), metadata.absoluteCalibration = ~metadata.isGainOnly; end
if ~isfield(metadata,'polarizationBasis'), metadata.polarizationBasis = "theta-phi"; end
end

function cache = emptyGridCache()
cache = struct('valid',false,'theta',[],'phi',[],'linearIndex',[],'sz',[],'data',struct(),'geom',struct(),'viewRevision',uint64(0));
end