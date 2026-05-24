(function () {
    const JOB_MAP_IMAGE_PATH = 'images/gta-map.jpg';
    const DEFAULT_IMAGE_WIDTH = 4096;
    const DEFAULT_IMAGE_HEIGHT = 4096;
    const DEFAULT_IMAGE_RECT = {
        minX: 688,
        maxX: 3828,
        minY: 112,
        maxY: 4012
    };
    const DEFAULT_INVERT_Y = true;
    const DEFAULT_MAX_RENDER_MARKERS = 850;
    const DEFAULT_PROJECTION_CORRECTION = {
        topOffsetX: 0,
        topOffsetY: 0,
        bottomOffsetX: 0,
        bottomOffsetY: 0,
        curveX: 0,
        curveY: 0,
        warpYPower: 1,
        mapOffsetX: 0,
        mapOffsetY: 0,
        rotationDeg: 0,
        scaleX: 1,
        scaleY: 1,
        anchorX: 0.5,
        anchorY: 0.5,
        affineA: 0.9127,
        affineB: 0.0001,
        affineC: 0.0011,
        affineD: 1.0727,
        affineTX: 170.9418,
        affineTY: -224.5448
    };
    const DEFAULT_BOUNDS = {
        minX: -3275.0,
        maxX: 5425.0,
        minY: -4000.0,
        maxY: 8700.0
    };
    const DEFAULT_TRANSFORM = {
        centerX: 117.3,
        centerY: 172.8,
        scaleX: 0.02072,
        scaleY: 0.0205
    };

    const STATUS_COLORS = {
        vacant: '#7be495',
        agency: '#7ab8ff',
        sold: '#d8dbe2',
        pap: '#ffd089'
    };

    function buildDefaultCalibrationRefs() {
        return {
            ref1: { worldX: null, worldY: null, targetX: null, targetY: null },
            ref2: { worldX: null, worldY: null, targetX: null, targetY: null },
            ref3: { worldX: null, worldY: null, targetX: null, targetY: null },
            ref4: { worldX: null, worldY: null, targetX: null, targetY: null }
        };
    }

    const mapState = {
        available: false,
        enabled: false,
        canAccess: false,
        resource: 'next_housing_extended',
        maxPoints: 2000,
        maxRenderMarkers: DEFAULT_MAX_RENDER_MARKERS,
        bounds: Object.assign({}, DEFAULT_BOUNDS),
        imageWidth: DEFAULT_IMAGE_WIDTH,
        imageHeight: DEFAULT_IMAGE_HEIGHT,
        imageRect: Object.assign({}, DEFAULT_IMAGE_RECT),
        invertY: DEFAULT_INVERT_Y,
        projectionCorrection: Object.assign({}, DEFAULT_PROJECTION_CORRECTION),
        transform: Object.assign({}, DEFAULT_TRANSFORM),
        loadedOnce: false,
        loading: false,
        houses: [],
        filteredHouses: [],
        housesById: {},
        selectedHouseId: null,
        filterStatus: 'all',
        filterSearch: '',
        onlyAgency: false,
        map: null,
        mapLayer: null,
        calibrationRefLayer: null,
        mapMarkersById: {},
        mapOverlay: null,
        mapSignature: '',
        calibrationMode: true,
        calibrationBaseline: null,
        calibrationRefs: buildDefaultCalibrationRefs(),
        calibrationCaptureRefId: null,
        calibrationStatusMessage: '',
        calibrationStatusError: false,
        calibrationAdvancedMode: false,
        bindDone: false
    };
    let mapSearchDebounceTimer = null;
    let calibrationApplyDebounceTimer = null;
    let calibrationCopyFeedbackTimer = null;

    function resolveNuiResourceName() {
        if (typeof window.jobGetResourceName === 'function') {
            return window.jobGetResourceName();
        }

        if (typeof window.nhResolveResourceName === 'function') {
            return window.nhResolveResourceName();
        }

        try {
            if (typeof window.GetParentResourceName === 'function') {
                const nativeName = String(window.GetParentResourceName() || '').trim();
                if (nativeName) {
                    return nativeName;
                }
            }
        } catch (_) {
        }

        return 'next_housing';
    }

    function getTranslation(key, fallback) {
        if (window.translations && window.translations[key]) {
            return String(window.translations[key]);
        }
        return fallback;
    }

    function escapeHtml(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function normalizeNumber(value, fallback, minValue, maxValue) {
        let parsed = Number(value);
        if (!Number.isFinite(parsed)) {
            parsed = fallback;
        }
        if (typeof minValue === 'number' && parsed < minValue) {
            parsed = minValue;
        }
        if (typeof maxValue === 'number' && parsed > maxValue) {
            parsed = maxValue;
        }
        return parsed;
    }

    function normalizeBounds(raw) {
        const source = raw && typeof raw === 'object' ? raw : {};
        const bounds = {
            minX: normalizeNumber(source.minX, DEFAULT_BOUNDS.minX),
            maxX: normalizeNumber(source.maxX, DEFAULT_BOUNDS.maxX),
            minY: normalizeNumber(source.minY, DEFAULT_BOUNDS.minY),
            maxY: normalizeNumber(source.maxY, DEFAULT_BOUNDS.maxY)
        };
        if (bounds.maxX <= bounds.minX) {
            bounds.maxX = bounds.minX + 1.0;
        }
        if (bounds.maxY <= bounds.minY) {
            bounds.maxY = bounds.minY + 1.0;
        }
        return bounds;
    }

    function normalizeTransform(raw) {
        const source = raw && typeof raw === 'object' ? raw : {};
        return {
            centerX: normalizeNumber(source.centerX, DEFAULT_TRANSFORM.centerX),
            centerY: normalizeNumber(source.centerY, DEFAULT_TRANSFORM.centerY),
            scaleX: normalizeNumber(source.scaleX, DEFAULT_TRANSFORM.scaleX),
            scaleY: normalizeNumber(source.scaleY, DEFAULT_TRANSFORM.scaleY)
        };
    }

    function normalizeInteger(value, fallback, minValue, maxValue) {
        return Math.floor(normalizeNumber(value, fallback, minValue, maxValue));
    }

    function normalizeBoolean(value, fallback) {
        if (value === true || value === false) {
            return value;
        }
        if (typeof value === 'string') {
            const lowered = value.trim().toLowerCase();
            if (lowered === '1' || lowered === 'true' || lowered === 'yes' || lowered === 'on') {
                return true;
            }
            if (lowered === '0' || lowered === 'false' || lowered === 'no' || lowered === 'off') {
                return false;
            }
        }
        if (typeof value === 'number') {
            return value === 1;
        }
        return fallback === true;
    }

    function normalizeImageRect(raw, imageWidth, imageHeight) {
        const source = raw && typeof raw === 'object' ? raw : {};
        const rect = {
            minX: normalizeNumber(source.minX, DEFAULT_IMAGE_RECT.minX, 0, imageWidth),
            maxX: normalizeNumber(source.maxX, DEFAULT_IMAGE_RECT.maxX, 0, imageWidth),
            minY: normalizeNumber(source.minY, DEFAULT_IMAGE_RECT.minY, 0, imageHeight),
            maxY: normalizeNumber(source.maxY, DEFAULT_IMAGE_RECT.maxY, 0, imageHeight)
        };

        if (rect.maxX <= rect.minX) {
            rect.maxX = Math.min(imageWidth, rect.minX + 1);
        }
        if (rect.maxY <= rect.minY) {
            rect.maxY = Math.min(imageHeight, rect.minY + 1);
        }

        return rect;
    }

    function normalizeProjectionCorrection(raw) {
        const source = raw && typeof raw === 'object' ? raw : {};
        const pickValue = function (camelKey, pascalKey) {
            if (source[camelKey] !== undefined && source[camelKey] !== null) {
                return source[camelKey];
            }
            return source[pascalKey];
        };
        return {
            topOffsetX: normalizeNumber(pickValue('topOffsetX', 'TopOffsetX'), DEFAULT_PROJECTION_CORRECTION.topOffsetX, -1024, 1024),
            topOffsetY: normalizeNumber(pickValue('topOffsetY', 'TopOffsetY'), DEFAULT_PROJECTION_CORRECTION.topOffsetY, -1024, 1024),
            bottomOffsetX: normalizeNumber(
                pickValue('bottomOffsetX', 'BottomOffsetX'),
                DEFAULT_PROJECTION_CORRECTION.bottomOffsetX,
                -1024,
                1024
            ),
            bottomOffsetY: normalizeNumber(
                pickValue('bottomOffsetY', 'BottomOffsetY'),
                DEFAULT_PROJECTION_CORRECTION.bottomOffsetY,
                -1024,
                1024
            ),
            curveX: normalizeNumber(
                pickValue('curveX', 'CurveX'),
                DEFAULT_PROJECTION_CORRECTION.curveX,
                -4096,
                4096
            ),
            curveY: normalizeNumber(
                pickValue('curveY', 'CurveY'),
                DEFAULT_PROJECTION_CORRECTION.curveY,
                -4096,
                4096
            ),
            warpYPower: normalizeNumber(
                pickValue('warpYPower', 'WarpYPower'),
                DEFAULT_PROJECTION_CORRECTION.warpYPower,
                0.5,
                2.5
            ),
            mapOffsetX: normalizeNumber(
                pickValue('mapOffsetX', 'MapOffsetX'),
                DEFAULT_PROJECTION_CORRECTION.mapOffsetX,
                -2048,
                2048
            ),
            mapOffsetY: normalizeNumber(
                pickValue('mapOffsetY', 'MapOffsetY'),
                DEFAULT_PROJECTION_CORRECTION.mapOffsetY,
                -2048,
                2048
            ),
            rotationDeg: normalizeNumber(
                pickValue('rotationDeg', 'RotationDeg'),
                DEFAULT_PROJECTION_CORRECTION.rotationDeg,
                -45,
                45
            ),
            scaleX: normalizeNumber(
                pickValue('scaleX', 'ScaleX'),
                DEFAULT_PROJECTION_CORRECTION.scaleX,
                0.5,
                1.5
            ),
            scaleY: normalizeNumber(
                pickValue('scaleY', 'ScaleY'),
                DEFAULT_PROJECTION_CORRECTION.scaleY,
                0.5,
                1.5
            ),
            anchorX: normalizeNumber(
                pickValue('anchorX', 'AnchorX'),
                DEFAULT_PROJECTION_CORRECTION.anchorX,
                0,
                1
            ),
            anchorY: normalizeNumber(
                pickValue('anchorY', 'AnchorY'),
                DEFAULT_PROJECTION_CORRECTION.anchorY,
                0,
                1
            ),
            affineA: normalizeNumber(
                pickValue('affineA', 'AffineA'),
                DEFAULT_PROJECTION_CORRECTION.affineA,
                -5,
                5
            ),
            affineB: normalizeNumber(
                pickValue('affineB', 'AffineB'),
                DEFAULT_PROJECTION_CORRECTION.affineB,
                -5,
                5
            ),
            affineC: normalizeNumber(
                pickValue('affineC', 'AffineC'),
                DEFAULT_PROJECTION_CORRECTION.affineC,
                -5,
                5
            ),
            affineD: normalizeNumber(
                pickValue('affineD', 'AffineD'),
                DEFAULT_PROJECTION_CORRECTION.affineD,
                -5,
                5
            ),
            affineTX: normalizeNumber(
                pickValue('affineTX', 'AffineTX'),
                DEFAULT_PROJECTION_CORRECTION.affineTX,
                -4096,
                4096
            ),
            affineTY: normalizeNumber(
                pickValue('affineTY', 'AffineTY'),
                DEFAULT_PROJECTION_CORRECTION.affineTY,
                -4096,
                4096
            )
        };
    }

    function projectWorldCoordsToImagePixel(rawCoords, options) {
        const coords = rawCoords && typeof rawCoords === 'object' ? rawCoords : {};
        const opts = options && typeof options === 'object' ? options : {};
        const x = Number(coords.x);
        const y = Number(coords.y);
        if (!Number.isFinite(x) || !Number.isFinite(y)) {
            return null;
        }

        const rangeX = Math.max(1, mapState.bounds.maxX - mapState.bounds.minX);
        const rangeY = Math.max(1, mapState.bounds.maxY - mapState.bounds.minY);
        const nx = (x - mapState.bounds.minX) / rangeX;
        const ny = (y - mapState.bounds.minY) / rangeY;

        // Reject extreme out-of-bounds coordinates to avoid fake markers clamped on the map.
        if (nx < -0.35 || nx > 1.35 || ny < -0.35 || ny > 1.35) {
            return null;
        }

        const rectSpanX = mapState.imageRect.maxX - mapState.imageRect.minX;
        const rectSpanY = mapState.imageRect.maxY - mapState.imageRect.minY;
        const projectedX = mapState.imageRect.minX + (nx * rectSpanX);
        const correction = mapState.projectionCorrection || DEFAULT_PROJECTION_CORRECTION;
        const yPower = normalizeNumber(correction.warpYPower, DEFAULT_PROJECTION_CORRECTION.warpYPower, 0.5, 2.5);
        const warpedNy = Math.pow(Math.min(1, Math.max(0, ny)), yPower);
        const mappedYRatio = mapState.invertY ? (1 - warpedNy) : warpedNy;
        const projectedY = mapState.imageRect.minY + (mappedYRatio * rectSpanY);

        const imageHeightSpan = Math.max(1, rectSpanY);
        const verticalRatio = Math.min(1, Math.max(0, (projectedY - mapState.imageRect.minY) / imageHeightSpan));
        const correctionX = correction.topOffsetX + ((correction.bottomOffsetX - correction.topOffsetX) * verticalRatio);
        const correctionY = correction.topOffsetY + ((correction.bottomOffsetY - correction.topOffsetY) * verticalRatio);
        const curveFactor = verticalRatio * verticalRatio * (1 - verticalRatio);
        const curvedCorrectionX = correctionX + ((correction.curveX || 0) * curveFactor);
        const curvedCorrectionY = correctionY + ((correction.curveY || 0) * curveFactor);

        const correctedX = projectedX + curvedCorrectionX;
        const correctedY = projectedY + curvedCorrectionY;

        const anchorXRatio = normalizeNumber(correction.anchorX, DEFAULT_PROJECTION_CORRECTION.anchorX, 0, 1);
        const anchorYRatio = normalizeNumber(correction.anchorY, DEFAULT_PROJECTION_CORRECTION.anchorY, 0, 1);
        const anchorX = mapState.imageRect.minX + (rectSpanX * anchorXRatio);
        const anchorY = mapState.imageRect.minY + (rectSpanY * anchorYRatio);

        const scaleX = normalizeNumber(correction.scaleX, DEFAULT_PROJECTION_CORRECTION.scaleX, 0.5, 1.5);
        const scaleY = normalizeNumber(correction.scaleY, DEFAULT_PROJECTION_CORRECTION.scaleY, 0.5, 1.5);
        const rotationDeg = normalizeNumber(correction.rotationDeg, DEFAULT_PROJECTION_CORRECTION.rotationDeg, -45, 45);
        const rotationRad = rotationDeg * (Math.PI / 180);
        const cosR = Math.cos(rotationRad);
        const sinR = Math.sin(rotationRad);

        const offsetX = normalizeNumber(correction.mapOffsetX, DEFAULT_PROJECTION_CORRECTION.mapOffsetX, -2048, 2048);
        const offsetY = normalizeNumber(correction.mapOffsetY, DEFAULT_PROJECTION_CORRECTION.mapOffsetY, -2048, 2048);

        const dx = (correctedX - anchorX) * scaleX;
        const dy = (correctedY - anchorY) * scaleY;
        const rotatedX = (dx * cosR) - (dy * sinR);
        const rotatedY = (dx * sinR) + (dy * cosR);
        const transformedX = anchorX + rotatedX + offsetX;
        const transformedY = anchorY + rotatedY + offsetY;

        const applyAffine = opts.applyAffine !== false;
        const affineA = normalizeNumber(correction.affineA, DEFAULT_PROJECTION_CORRECTION.affineA, -5, 5);
        const affineB = normalizeNumber(correction.affineB, DEFAULT_PROJECTION_CORRECTION.affineB, -5, 5);
        const affineC = normalizeNumber(correction.affineC, DEFAULT_PROJECTION_CORRECTION.affineC, -5, 5);
        const affineD = normalizeNumber(correction.affineD, DEFAULT_PROJECTION_CORRECTION.affineD, -5, 5);
        const affineTX = normalizeNumber(correction.affineTX, DEFAULT_PROJECTION_CORRECTION.affineTX, -4096, 4096);
        const affineTY = normalizeNumber(correction.affineTY, DEFAULT_PROJECTION_CORRECTION.affineTY, -4096, 4096);

        const affinedX = applyAffine
            ? ((transformedX * affineA) + (transformedY * affineB) + affineTX)
            : transformedX;
        const affinedY = applyAffine
            ? ((transformedX * affineC) + (transformedY * affineD) + affineTY)
            : transformedY;

        const finalX = affinedX;
        const finalY = affinedY;

        if (
            finalX < -512 ||
            finalX > (mapState.imageWidth + 512) ||
            finalY < -512 ||
            finalY > (mapState.imageHeight + 512)
        ) {
            return null;
        }

        return {
            x: finalX,
            y: finalY
        };
    }

    function projectImagePixelToMapLatLng(imagePixel) {
        if (!imagePixel || typeof imagePixel !== 'object') {
            return null;
        }

        const x = Number(imagePixel.x);
        const y = Number(imagePixel.y);
        if (!Number.isFinite(x) || !Number.isFinite(y)) {
            return null;
        }

        // Leaflet CRS.Simple with bounds [[0,0],[H,W]] uses latitude increasing toward north,
        // so image Y (top->bottom) must be flipped when converted to map latitude.
        const leafletLat = mapState.imageHeight - y;
        return [leafletLat, x];
    }

    function projectMapLatLngToImagePixel(latLng) {
        if (!latLng || typeof latLng !== 'object') {
            return null;
        }
        const lng = Number(latLng.lng);
        const lat = Number(latLng.lat);
        if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
            return null;
        }

        return {
            x: lng,
            y: mapState.imageHeight - lat
        };
    }

    function projectWorldCoordsToMap(rawCoords) {
        const imagePixel = projectWorldCoordsToImagePixel(rawCoords, {
            applyAffine: true
        });
        if (!imagePixel) {
            return null;
        }
        return projectImagePixelToMapLatLng(imagePixel);
    }

    function refreshProjectedCoords() {
        if (!Array.isArray(mapState.houses) || mapState.houses.length === 0) {
            return;
        }

        mapState.houses.forEach(function (house) {
            if (!house || typeof house !== 'object') {
                return;
            }
            house.mapLatLng = projectWorldCoordsToMap(house.coords);
        });
    }

    function formatCalibrationNumber(value) {
        const numeric = Number(value);
        if (!Number.isFinite(numeric)) {
            return '0';
        }
        return numeric.toFixed(4).replace(/\.?0+$/, '');
    }

    function deepClone(value) {
        try {
            return JSON.parse(JSON.stringify(value));
        } catch (_) {
            return null;
        }
    }

    function buildCalibrationSnapshotFromState() {
        return {
            bounds: {
                minX: mapState.bounds.minX,
                maxX: mapState.bounds.maxX,
                minY: mapState.bounds.minY,
                maxY: mapState.bounds.maxY
            },
            imageRect: {
                minX: mapState.imageRect.minX,
                maxX: mapState.imageRect.maxX,
                minY: mapState.imageRect.minY,
                maxY: mapState.imageRect.maxY
            },
            invertY: mapState.invertY === true,
            projectionCorrection: {
                topOffsetX: mapState.projectionCorrection.topOffsetX,
                topOffsetY: mapState.projectionCorrection.topOffsetY,
                bottomOffsetX: mapState.projectionCorrection.bottomOffsetX,
                bottomOffsetY: mapState.projectionCorrection.bottomOffsetY,
                curveX: mapState.projectionCorrection.curveX,
                curveY: mapState.projectionCorrection.curveY,
                warpYPower: mapState.projectionCorrection.warpYPower,
                mapOffsetX: mapState.projectionCorrection.mapOffsetX,
                mapOffsetY: mapState.projectionCorrection.mapOffsetY,
                rotationDeg: mapState.projectionCorrection.rotationDeg,
                scaleX: mapState.projectionCorrection.scaleX,
                scaleY: mapState.projectionCorrection.scaleY,
                anchorX: mapState.projectionCorrection.anchorX,
                anchorY: mapState.projectionCorrection.anchorY,
                affineA: mapState.projectionCorrection.affineA,
                affineB: mapState.projectionCorrection.affineB,
                affineC: mapState.projectionCorrection.affineC,
                affineD: mapState.projectionCorrection.affineD,
                affineTX: mapState.projectionCorrection.affineTX,
                affineTY: mapState.projectionCorrection.affineTY
            }
        };
    }

    function captureCalibrationBaselineFromState() {
        mapState.calibrationBaseline = deepClone(buildCalibrationSnapshotFromState());
    }

    function buildCalibrationConfigSnippet(snapshot) {
        const source = snapshot && typeof snapshot === 'object'
            ? snapshot
            : buildCalibrationSnapshotFromState();

        return [
            'Bounds = {',
            `    minX = ${formatCalibrationNumber(source.bounds.minX)},`,
            `    maxX = ${formatCalibrationNumber(source.bounds.maxX)},`,
            `    minY = ${formatCalibrationNumber(source.bounds.minY)},`,
            `    maxY = ${formatCalibrationNumber(source.bounds.maxY)},`,
            '},',
            'ImageRect = {',
            `    minX = ${formatCalibrationNumber(source.imageRect.minX)},`,
            `    maxX = ${formatCalibrationNumber(source.imageRect.maxX)},`,
            `    minY = ${formatCalibrationNumber(source.imageRect.minY)},`,
            `    maxY = ${formatCalibrationNumber(source.imageRect.maxY)},`,
            '},',
            `InvertY = ${source.invertY === true ? 'true' : 'false'},`,
            'ProjectionCorrection = {',
            `    TopOffsetX = ${formatCalibrationNumber(source.projectionCorrection.topOffsetX)},`,
            `    TopOffsetY = ${formatCalibrationNumber(source.projectionCorrection.topOffsetY)},`,
            `    BottomOffsetX = ${formatCalibrationNumber(source.projectionCorrection.bottomOffsetX)},`,
            `    BottomOffsetY = ${formatCalibrationNumber(source.projectionCorrection.bottomOffsetY)},`,
            `    CurveX = ${formatCalibrationNumber(source.projectionCorrection.curveX)},`,
            `    CurveY = ${formatCalibrationNumber(source.projectionCorrection.curveY)},`,
            `    WarpYPower = ${formatCalibrationNumber(source.projectionCorrection.warpYPower)},`,
            `    MapOffsetX = ${formatCalibrationNumber(source.projectionCorrection.mapOffsetX)},`,
            `    MapOffsetY = ${formatCalibrationNumber(source.projectionCorrection.mapOffsetY)},`,
            `    RotationDeg = ${formatCalibrationNumber(source.projectionCorrection.rotationDeg)},`,
            `    ScaleX = ${formatCalibrationNumber(source.projectionCorrection.scaleX)},`,
            `    ScaleY = ${formatCalibrationNumber(source.projectionCorrection.scaleY)},`,
            `    AnchorX = ${formatCalibrationNumber(source.projectionCorrection.anchorX)},`,
            `    AnchorY = ${formatCalibrationNumber(source.projectionCorrection.anchorY)},`,
            `    AffineA = ${formatCalibrationNumber(source.projectionCorrection.affineA)},`,
            `    AffineB = ${formatCalibrationNumber(source.projectionCorrection.affineB)},`,
            `    AffineC = ${formatCalibrationNumber(source.projectionCorrection.affineC)},`,
            `    AffineD = ${formatCalibrationNumber(source.projectionCorrection.affineD)},`,
            `    AffineTX = ${formatCalibrationNumber(source.projectionCorrection.affineTX)},`,
            `    AffineTY = ${formatCalibrationNumber(source.projectionCorrection.affineTY)},`,
            '},'
        ].join('\n');
    }

    function setCalibrationPanelVisibility() {
        const enabled = mapState.calibrationMode === true;
        $('#job-map-calibration-panel').toggleClass('hidden', !enabled);
        $('#job-map-houses-list').toggleClass('hidden', enabled);

        if (enabled) {
            $('#job-map-empty').addClass('hidden');
        }

        setCalibrationAdvancedMode(mapState.calibrationAdvancedMode === true);
    }

    function setCalibrationAdvancedMode(enabled) {
        const isEnabled = enabled === true;
        mapState.calibrationAdvancedMode = isEnabled;
        $('#job-map-calibration-panel .job-map-advanced-only').toggleClass('hidden', !isEnabled);

        const toggleButton = $('#job-map-calib-toggle-advanced');
        if (toggleButton.length) {
            toggleButton.text(isEnabled ? 'Masquer expert' : 'Mode expert');
            toggleButton.toggleClass('is-active', isEnabled);
        }
    }

    function syncCalibrationInputsFromState() {
        if (!$('#job-map-calibration-panel').length) {
            return;
        }

        const snapshot = buildCalibrationSnapshotFromState();
        $('#job-map-calib-bounds-minx').val(formatCalibrationNumber(snapshot.bounds.minX));
        $('#job-map-calib-bounds-maxx').val(formatCalibrationNumber(snapshot.bounds.maxX));
        $('#job-map-calib-bounds-miny').val(formatCalibrationNumber(snapshot.bounds.minY));
        $('#job-map-calib-bounds-maxy').val(formatCalibrationNumber(snapshot.bounds.maxY));

        $('#job-map-calib-rect-minx').val(formatCalibrationNumber(snapshot.imageRect.minX));
        $('#job-map-calib-rect-maxx').val(formatCalibrationNumber(snapshot.imageRect.maxX));
        $('#job-map-calib-rect-miny').val(formatCalibrationNumber(snapshot.imageRect.minY));
        $('#job-map-calib-rect-maxy').val(formatCalibrationNumber(snapshot.imageRect.maxY));

        $('#job-map-calib-topx').val(formatCalibrationNumber(snapshot.projectionCorrection.topOffsetX));
        $('#job-map-calib-topy').val(formatCalibrationNumber(snapshot.projectionCorrection.topOffsetY));
        $('#job-map-calib-bottomx').val(formatCalibrationNumber(snapshot.projectionCorrection.bottomOffsetX));
        $('#job-map-calib-bottomy').val(formatCalibrationNumber(snapshot.projectionCorrection.bottomOffsetY));
        $('#job-map-calib-curvex').val(formatCalibrationNumber(snapshot.projectionCorrection.curveX));
        $('#job-map-calib-curvey').val(formatCalibrationNumber(snapshot.projectionCorrection.curveY));
        $('#job-map-calib-warpy').val(formatCalibrationNumber(snapshot.projectionCorrection.warpYPower));
        $('#job-map-calib-mapoffsetx').val(formatCalibrationNumber(snapshot.projectionCorrection.mapOffsetX));
        $('#job-map-calib-mapoffsety').val(formatCalibrationNumber(snapshot.projectionCorrection.mapOffsetY));
        $('#job-map-calib-rotationdeg').val(formatCalibrationNumber(snapshot.projectionCorrection.rotationDeg));
        $('#job-map-calib-scalex').val(formatCalibrationNumber(snapshot.projectionCorrection.scaleX));
        $('#job-map-calib-scaley').val(formatCalibrationNumber(snapshot.projectionCorrection.scaleY));
        $('#job-map-calib-anchorx').val(formatCalibrationNumber(snapshot.projectionCorrection.anchorX));
        $('#job-map-calib-anchory').val(formatCalibrationNumber(snapshot.projectionCorrection.anchorY));
        $('#job-map-calib-affinea').val(formatCalibrationNumber(snapshot.projectionCorrection.affineA));
        $('#job-map-calib-affineb').val(formatCalibrationNumber(snapshot.projectionCorrection.affineB));
        $('#job-map-calib-affinec').val(formatCalibrationNumber(snapshot.projectionCorrection.affineC));
        $('#job-map-calib-affined').val(formatCalibrationNumber(snapshot.projectionCorrection.affineD));
        $('#job-map-calib-affinetx').val(formatCalibrationNumber(snapshot.projectionCorrection.affineTX));
        $('#job-map-calib-affinety').val(formatCalibrationNumber(snapshot.projectionCorrection.affineTY));
        $('#job-map-calib-inverty').prop('checked', snapshot.invertY === true);

        $('#job-map-calibration-output').val(buildCalibrationConfigSnippet(snapshot));
        syncCalibrationRefInputsFromState();
        renderCalibrationReferenceMarkers();
    }

    function readCalibrationNumberInput(selector, fallback, minValue, maxValue) {
        const rawValue = $(selector).val();
        return normalizeNumber(rawValue, fallback, minValue, maxValue);
    }

    function normalizeCalibrationRefId(rawRefId) {
        const refNumber = Number(rawRefId);
        if (!Number.isFinite(refNumber) || refNumber < 1 || refNumber > 4) {
            return null;
        }
        return `ref${Math.floor(refNumber)}`;
    }

    function parseCalibrationOptionalNumber(value) {
        const text = String(value == null ? '' : value).trim();
        if (!text) {
            return null;
        }
        const parsed = Number(text);
        return Number.isFinite(parsed) ? parsed : null;
    }

    function setCalibrationStatusMessage(message, isError) {
        mapState.calibrationStatusMessage = String(message || '').trim();
        mapState.calibrationStatusError = isError === true;
        syncCalibrationCaptureStatus();
    }

    function syncCalibrationCaptureStatus() {
        const status = $('#job-map-calib-capture-state');
        if (!status.length) {
            return;
        }

        let message = '';
        let isError = false;
        if (mapState.calibrationCaptureRefId) {
            const refId = mapState.calibrationCaptureRefId.replace('ref', '');
            message = `Capture P${refId}: clique sur la map`;
            isError = false;
        } else if (mapState.calibrationStatusMessage) {
            message = mapState.calibrationStatusMessage;
            isError = mapState.calibrationStatusError === true;
        }

        status.text(message);
        status.toggleClass('is-error', isError);
    }

    function syncCalibrationRefInputsFromState() {
        const refs = mapState.calibrationRefs && typeof mapState.calibrationRefs === 'object'
            ? mapState.calibrationRefs
            : buildDefaultCalibrationRefs();

        for (let index = 1; index <= 4; index += 1) {
            const refId = `ref${index}`;
            const ref = refs[refId] || {};
            const worldX = Number(ref.worldX);
            const worldY = Number(ref.worldY);
            const targetX = Number(ref.targetX);
            const targetY = Number(ref.targetY);

            $(`#job-map-calib-ref${index}-worldx`).val(Number.isFinite(worldX) ? formatCalibrationNumber(worldX) : '');
            $(`#job-map-calib-ref${index}-worldy`).val(Number.isFinite(worldY) ? formatCalibrationNumber(worldY) : '');
            $(`#job-map-calib-ref${index}-mapx`).val(Number.isFinite(targetX) ? formatCalibrationNumber(targetX) : '');
            $(`#job-map-calib-ref${index}-mapy`).val(Number.isFinite(targetY) ? formatCalibrationNumber(targetY) : '');

            const row = $(`.job-map-calibration-ref-row[data-calib-ref="${index}"]`);
            row.toggleClass('is-capturing', mapState.calibrationCaptureRefId === refId);
        }

        syncCalibrationCaptureStatus();
    }

    function updateCalibrationRefsFromInputs() {
        const nextRefs = buildDefaultCalibrationRefs();
        const currentRefs = mapState.calibrationRefs && typeof mapState.calibrationRefs === 'object'
            ? mapState.calibrationRefs
            : buildDefaultCalibrationRefs();

        for (let index = 1; index <= 4; index += 1) {
            const refId = `ref${index}`;
            const current = currentRefs[refId] || {};
            nextRefs[refId] = {
                worldX: parseCalibrationOptionalNumber($(`#job-map-calib-ref${index}-worldx`).val()),
                worldY: parseCalibrationOptionalNumber($(`#job-map-calib-ref${index}-worldy`).val()),
                targetX: parseCalibrationOptionalNumber($(`#job-map-calib-ref${index}-mapx`).val()),
                targetY: parseCalibrationOptionalNumber($(`#job-map-calib-ref${index}-mapy`).val())
            };

            if (!Number.isFinite(nextRefs[refId].targetX)) {
                nextRefs[refId].targetX = Number.isFinite(Number(current.targetX)) ? Number(current.targetX) : null;
            }
            if (!Number.isFinite(nextRefs[refId].targetY)) {
                nextRefs[refId].targetY = Number.isFinite(Number(current.targetY)) ? Number(current.targetY) : null;
            }
        }

        mapState.calibrationRefs = nextRefs;
        mapState.calibrationStatusMessage = '';
        mapState.calibrationStatusError = false;
        syncCalibrationRefInputsFromState();
        renderCalibrationReferenceMarkers();
    }

    function handleCalibrationMapClick(latLng) {
        if (!mapState.calibrationMode || !mapState.calibrationCaptureRefId) {
            return;
        }

        const imagePixel = projectMapLatLngToImagePixel(latLng);
        if (!imagePixel) {
            return;
        }

        const refId = mapState.calibrationCaptureRefId;
        const refs = mapState.calibrationRefs && typeof mapState.calibrationRefs === 'object'
            ? mapState.calibrationRefs
            : buildDefaultCalibrationRefs();

        if (!refs[refId]) {
            refs[refId] = { worldX: null, worldY: null, targetX: null, targetY: null };
        }

        refs[refId].targetX = normalizeNumber(imagePixel.x, 0, -1024, mapState.imageWidth + 1024);
        refs[refId].targetY = normalizeNumber(imagePixel.y, 0, -1024, mapState.imageHeight + 1024);
        mapState.calibrationRefs = refs;
        mapState.calibrationCaptureRefId = null;
        mapState.calibrationStatusMessage = '';
        mapState.calibrationStatusError = false;
        syncCalibrationRefInputsFromState();
        renderCalibrationReferenceMarkers();
    }

    function renderCalibrationReferenceMarkers() {
        if (!mapState.map || !mapState.calibrationRefLayer) {
            return;
        }

        mapState.calibrationRefLayer.clearLayers();
        const refs = mapState.calibrationRefs && typeof mapState.calibrationRefs === 'object'
            ? mapState.calibrationRefs
            : {};

        for (let index = 1; index <= 4; index += 1) {
            const refId = `ref${index}`;
            const ref = refs[refId];
            if (!ref) {
                continue;
            }

            const x = Number(ref.targetX);
            const y = Number(ref.targetY);
            if (!Number.isFinite(x) || !Number.isFinite(y)) {
                continue;
            }

            const latLng = projectImagePixelToMapLatLng({ x: x, y: y });
            if (!Array.isArray(latLng)) {
                continue;
            }

            const isActive = mapState.calibrationCaptureRefId === refId;
            const marker = L.circleMarker(latLng, {
                radius: 7,
                color: isActive ? '#fff8a6' : '#ffc76b',
                weight: 2,
                fillColor: isActive ? '#fff8a6' : '#ffc76b',
                fillOpacity: 0.24
            });
            marker.bindTooltip(`P${index}`, {
                permanent: true,
                direction: 'top',
                className: 'nh-map-calib-ref-label'
            });
            mapState.calibrationRefLayer.addLayer(marker);
        }
    }

    function solveLinearSystem(matrix, vector) {
        const size = Array.isArray(vector) ? vector.length : 0;
        if (!Array.isArray(matrix) || matrix.length !== size || size === 0) {
            return null;
        }

        const m = matrix.map(function (row, rowIndex) {
            const sourceRow = Array.isArray(row) ? row.slice(0, size) : [];
            while (sourceRow.length < size) {
                sourceRow.push(0);
            }
            sourceRow.push(vector[rowIndex]);
            return sourceRow;
        });

        for (let col = 0; col < size; col += 1) {
            let pivotRow = col;
            let pivotAbs = Math.abs(m[col][col]);
            for (let row = col + 1; row < size; row += 1) {
                const absValue = Math.abs(m[row][col]);
                if (absValue > pivotAbs) {
                    pivotAbs = absValue;
                    pivotRow = row;
                }
            }

            if (pivotAbs < 1e-9) {
                return null;
            }

            if (pivotRow !== col) {
                const tmp = m[col];
                m[col] = m[pivotRow];
                m[pivotRow] = tmp;
            }

            const pivot = m[col][col];
            for (let k = col; k <= size; k += 1) {
                m[col][k] /= pivot;
            }

            for (let row = 0; row < size; row += 1) {
                if (row === col) {
                    continue;
                }
                const factor = m[row][col];
                if (Math.abs(factor) < 1e-12) {
                    continue;
                }
                for (let k = col; k <= size; k += 1) {
                    m[row][k] -= factor * m[col][k];
                }
            }
        }

        const solution = [];
        for (let row = 0; row < size; row += 1) {
            solution.push(m[row][size]);
        }
        return solution;
    }

    function solveAffineLeastSquares(pairs) {
        if (!Array.isArray(pairs) || pairs.length < 3) {
            return null;
        }

        const size = 6;
        const ata = [];
        const atb = [];
        for (let i = 0; i < size; i += 1) {
            ata[i] = [];
            atb[i] = 0;
            for (let j = 0; j < size; j += 1) {
                ata[i][j] = 0;
            }
        }

        pairs.forEach(function (pair) {
            const srcX = Number(pair.srcX);
            const srcY = Number(pair.srcY);
            const dstX = Number(pair.dstX);
            const dstY = Number(pair.dstY);
            if (!Number.isFinite(srcX) || !Number.isFinite(srcY) || !Number.isFinite(dstX) || !Number.isFinite(dstY)) {
                return;
            }

            const rows = [
                { coeffs: [srcX, srcY, 0, 0, 1, 0], rhs: dstX },
                { coeffs: [0, 0, srcX, srcY, 0, 1], rhs: dstY }
            ];

            rows.forEach(function (row) {
                for (let i = 0; i < size; i += 1) {
                    atb[i] += row.coeffs[i] * row.rhs;
                    for (let j = 0; j < size; j += 1) {
                        ata[i][j] += row.coeffs[i] * row.coeffs[j];
                    }
                }
            });
        });

        const solution = solveLinearSystem(ata, atb);
        if (!Array.isArray(solution) || solution.length !== size) {
            return null;
        }

        return {
            affineA: solution[0],
            affineB: solution[1],
            affineC: solution[2],
            affineD: solution[3],
            affineTX: solution[4],
            affineTY: solution[5]
        };
    }

    function computePairsBoundingBox(pairs, prefix) {
        let minX = Number.POSITIVE_INFINITY;
        let maxX = Number.NEGATIVE_INFINITY;
        let minY = Number.POSITIVE_INFINITY;
        let maxY = Number.NEGATIVE_INFINITY;
        const keyX = `${prefix}X`;
        const keyY = `${prefix}Y`;

        pairs.forEach(function (pair) {
            const x = Number(pair[keyX]);
            const y = Number(pair[keyY]);
            if (!Number.isFinite(x) || !Number.isFinite(y)) {
                return;
            }
            minX = Math.min(minX, x);
            maxX = Math.max(maxX, x);
            minY = Math.min(minY, y);
            maxY = Math.max(maxY, y);
        });

        if (!Number.isFinite(minX) || !Number.isFinite(maxX) || !Number.isFinite(minY) || !Number.isFinite(maxY)) {
            return null;
        }

        return {
            width: maxX - minX,
            height: maxY - minY
        };
    }

    function validateCalibrationPairsSpread(pairs) {
        const srcBox = computePairsBoundingBox(pairs, 'src');
        const dstBox = computePairsBoundingBox(pairs, 'dst');
        if (!srcBox || !dstBox) {
            return { ok: false, message: 'Points de calibration invalides.' };
        }

        if (srcBox.width < 180 || srcBox.height < 180 || dstBox.width < 180 || dstBox.height < 180) {
            return {
                ok: false,
                message: 'Points trop proches: prends 4 points tres eloignes (N/S/E/O).'
            };
        }

        return { ok: true };
    }

    function computeAffineResidualRmse(affine, pairs) {
        let sum = 0;
        let count = 0;
        pairs.forEach(function (pair) {
            const srcX = Number(pair.srcX);
            const srcY = Number(pair.srcY);
            const dstX = Number(pair.dstX);
            const dstY = Number(pair.dstY);
            if (!Number.isFinite(srcX) || !Number.isFinite(srcY) || !Number.isFinite(dstX) || !Number.isFinite(dstY)) {
                return;
            }

            const px = (srcX * affine.affineA) + (srcY * affine.affineB) + affine.affineTX;
            const py = (srcX * affine.affineC) + (srcY * affine.affineD) + affine.affineTY;
            const dx = px - dstX;
            const dy = py - dstY;
            sum += (dx * dx) + (dy * dy);
            count += 1;
        });

        if (count <= 0) {
            return Number.POSITIVE_INFINITY;
        }
        return Math.sqrt(sum / count);
    }

    function validateAutoAffineSolution(solved, pairs) {
        if (!solved || typeof solved !== 'object') {
            return { ok: false, message: 'Solveur affine: resultat vide.' };
        }

        const normalized = normalizeProjectionCorrection(solved);
        const clampChanged =
            Math.abs(normalized.affineA - solved.affineA) > 0.0001 ||
            Math.abs(normalized.affineB - solved.affineB) > 0.0001 ||
            Math.abs(normalized.affineC - solved.affineC) > 0.0001 ||
            Math.abs(normalized.affineD - solved.affineD) > 0.0001 ||
            Math.abs(normalized.affineTX - solved.affineTX) > 0.01 ||
            Math.abs(normalized.affineTY - solved.affineTY) > 0.01;

        if (clampChanged) {
            return {
                ok: false,
                message: 'Auto-affine invalide (valeurs extremes). Reprends les captures.'
            };
        }

        const det = (normalized.affineA * normalized.affineD) - (normalized.affineB * normalized.affineC);
        if (!Number.isFinite(det) || Math.abs(det) < 0.05 || Math.abs(det) > 6.0) {
            return {
                ok: false,
                message: 'Auto-affine instable (determinant hors plage).'
            };
        }

        const rmse = computeAffineResidualRmse(normalized, pairs);
        if (!Number.isFinite(rmse) || rmse > 140) {
            return {
                ok: false,
                message: 'Auto-affine peu fiable (erreur trop grande). Recalibre les 4 points.'
            };
        }

        return { ok: true, normalized: normalized, rmse: rmse };
    }

    function collectCalibrationPairsFromRefs() {
        const refs = mapState.calibrationRefs && typeof mapState.calibrationRefs === 'object'
            ? mapState.calibrationRefs
            : {};
        const pairs = [];

        for (let index = 1; index <= 4; index += 1) {
            const refId = `ref${index}`;
            const ref = refs[refId];
            if (!ref) {
                return { error: `Point P${index} manquant.` };
            }

            const worldX = Number(ref.worldX);
            const worldY = Number(ref.worldY);
            const targetX = Number(ref.targetX);
            const targetY = Number(ref.targetY);
            if (!Number.isFinite(worldX) || !Number.isFinite(worldY) || !Number.isFinite(targetX) || !Number.isFinite(targetY)) {
                return { error: `Point P${index} incomplet (world + capture requis).` };
            }

            const sourcePixel = projectWorldCoordsToImagePixel(
                { x: worldX, y: worldY },
                { applyAffine: false }
            );
            if (!sourcePixel) {
                return { error: `Point P${index} hors plage de projection.` };
            }

            pairs.push({
                srcX: sourcePixel.x,
                srcY: sourcePixel.y,
                dstX: targetX,
                dstY: targetY
            });
        }

        return { pairs: pairs };
    }

    function runAutoAffineCalibration() {
        updateCalibrationRefsFromInputs();
        const collected = collectCalibrationPairsFromRefs();
        if (!collected || collected.error) {
            setCalibrationStatusMessage(collected && collected.error ? collected.error : 'Points invalides.', true);
            return;
        }

        const spreadCheck = validateCalibrationPairsSpread(collected.pairs);
        if (!spreadCheck.ok) {
            setCalibrationStatusMessage(spreadCheck.message, true);
            return;
        }

        const solvedAffine = solveAffineLeastSquares(collected.pairs);
        if (!solvedAffine) {
            setCalibrationStatusMessage('Echec auto-calibration affine.', true);
            return;
        }

        const affineValidation = validateAutoAffineSolution(solvedAffine, collected.pairs);
        if (!affineValidation.ok) {
            setCalibrationStatusMessage(affineValidation.message, true);
            return;
        }

        const snapshot = buildCalibrationSnapshotFromInputs();
        snapshot.projectionCorrection.affineA = affineValidation.normalized.affineA;
        snapshot.projectionCorrection.affineB = affineValidation.normalized.affineB;
        snapshot.projectionCorrection.affineC = affineValidation.normalized.affineC;
        snapshot.projectionCorrection.affineD = affineValidation.normalized.affineD;
        snapshot.projectionCorrection.affineTX = affineValidation.normalized.affineTX;
        snapshot.projectionCorrection.affineTY = affineValidation.normalized.affineTY;
        applyCalibrationSnapshot(snapshot);
        setCalibrationStatusMessage(`Auto-affine applique (RMSE ${affineValidation.rmse.toFixed(1)} px).`, false);
    }

    function buildCalibrationSnapshotFromInputs() {
        const fallback = buildCalibrationSnapshotFromState();
        return {
            bounds: normalizeBounds({
                minX: readCalibrationNumberInput('#job-map-calib-bounds-minx', fallback.bounds.minX),
                maxX: readCalibrationNumberInput('#job-map-calib-bounds-maxx', fallback.bounds.maxX),
                minY: readCalibrationNumberInput('#job-map-calib-bounds-miny', fallback.bounds.minY),
                maxY: readCalibrationNumberInput('#job-map-calib-bounds-maxy', fallback.bounds.maxY)
            }),
            imageRect: normalizeImageRect({
                minX: readCalibrationNumberInput('#job-map-calib-rect-minx', fallback.imageRect.minX),
                maxX: readCalibrationNumberInput('#job-map-calib-rect-maxx', fallback.imageRect.maxX),
                minY: readCalibrationNumberInput('#job-map-calib-rect-miny', fallback.imageRect.minY),
                maxY: readCalibrationNumberInput('#job-map-calib-rect-maxy', fallback.imageRect.maxY)
            }, mapState.imageWidth, mapState.imageHeight),
            invertY: $('#job-map-calib-inverty').is(':checked'),
            projectionCorrection: normalizeProjectionCorrection({
                topOffsetX: readCalibrationNumberInput('#job-map-calib-topx', fallback.projectionCorrection.topOffsetX),
                topOffsetY: readCalibrationNumberInput('#job-map-calib-topy', fallback.projectionCorrection.topOffsetY),
                bottomOffsetX: readCalibrationNumberInput('#job-map-calib-bottomx', fallback.projectionCorrection.bottomOffsetX),
                bottomOffsetY: readCalibrationNumberInput('#job-map-calib-bottomy', fallback.projectionCorrection.bottomOffsetY),
                curveX: readCalibrationNumberInput('#job-map-calib-curvex', fallback.projectionCorrection.curveX),
                curveY: readCalibrationNumberInput('#job-map-calib-curvey', fallback.projectionCorrection.curveY),
                warpYPower: readCalibrationNumberInput('#job-map-calib-warpy', fallback.projectionCorrection.warpYPower),
                mapOffsetX: readCalibrationNumberInput('#job-map-calib-mapoffsetx', fallback.projectionCorrection.mapOffsetX),
                mapOffsetY: readCalibrationNumberInput('#job-map-calib-mapoffsety', fallback.projectionCorrection.mapOffsetY),
                rotationDeg: readCalibrationNumberInput('#job-map-calib-rotationdeg', fallback.projectionCorrection.rotationDeg),
                scaleX: readCalibrationNumberInput('#job-map-calib-scalex', fallback.projectionCorrection.scaleX),
                scaleY: readCalibrationNumberInput('#job-map-calib-scaley', fallback.projectionCorrection.scaleY),
                anchorX: readCalibrationNumberInput('#job-map-calib-anchorx', fallback.projectionCorrection.anchorX),
                anchorY: readCalibrationNumberInput('#job-map-calib-anchory', fallback.projectionCorrection.anchorY),
                affineA: readCalibrationNumberInput('#job-map-calib-affinea', fallback.projectionCorrection.affineA),
                affineB: readCalibrationNumberInput('#job-map-calib-affineb', fallback.projectionCorrection.affineB),
                affineC: readCalibrationNumberInput('#job-map-calib-affinec', fallback.projectionCorrection.affineC),
                affineD: readCalibrationNumberInput('#job-map-calib-affined', fallback.projectionCorrection.affineD),
                affineTX: readCalibrationNumberInput('#job-map-calib-affinetx', fallback.projectionCorrection.affineTX),
                affineTY: readCalibrationNumberInput('#job-map-calib-affinety', fallback.projectionCorrection.affineTY)
            })
        };
    }

    function applyCalibrationSnapshot(snapshot) {
        if (!snapshot || typeof snapshot !== 'object') {
            return;
        }

        mapState.bounds = normalizeBounds(snapshot.bounds || mapState.bounds);
        mapState.imageRect = normalizeImageRect(
            snapshot.imageRect || mapState.imageRect,
            mapState.imageWidth,
            mapState.imageHeight
        );
        mapState.invertY = normalizeBoolean(snapshot.invertY, mapState.invertY);
        mapState.projectionCorrection = normalizeProjectionCorrection(
            snapshot.projectionCorrection || mapState.projectionCorrection
        );

        refreshProjectedCoords();
        if (mapState.loadedOnce) {
            renderMapTab();
        }
        syncCalibrationInputsFromState();
    }

    function getCalibrationStepValue() {
        return normalizeNumber($('#job-map-calib-step').val(), 4.0, 0.1, 500);
    }

    function nudgeCalibration(direction) {
        const step = getCalibrationStepValue();
        const rotationStep = Math.max(0.05, step * 0.1);
        const snapshot = buildCalibrationSnapshotFromState();

        if (direction === 'left') {
            snapshot.projectionCorrection.mapOffsetX -= step;
        } else if (direction === 'right') {
            snapshot.projectionCorrection.mapOffsetX += step;
        } else if (direction === 'up') {
            snapshot.projectionCorrection.mapOffsetY -= step;
        } else if (direction === 'down') {
            snapshot.projectionCorrection.mapOffsetY += step;
        } else if (direction === 'rotleft') {
            snapshot.projectionCorrection.rotationDeg -= rotationStep;
        } else if (direction === 'rotright') {
            snapshot.projectionCorrection.rotationDeg += rotationStep;
        }

        applyCalibrationSnapshot(snapshot);
    }

    function scheduleCalibrationApplyFromInputs() {
        if (calibrationApplyDebounceTimer) {
            clearTimeout(calibrationApplyDebounceTimer);
        }
        calibrationApplyDebounceTimer = setTimeout(function () {
            calibrationApplyDebounceTimer = null;
            applyCalibrationSnapshot(buildCalibrationSnapshotFromInputs());
        }, 80);
    }

    function setCalibrationCopyButtonLabel(label) {
        $('#job-map-calib-copy').text(label);
        $('#job-map-calib-copy-simple').text(label === 'Copie' ? 'Copie' : 'Copier config');
    }

    function markCalibrationCopied() {
        setCalibrationCopyButtonLabel('Copie');
        if (calibrationCopyFeedbackTimer) {
            clearTimeout(calibrationCopyFeedbackTimer);
        }
        calibrationCopyFeedbackTimer = setTimeout(function () {
            calibrationCopyFeedbackTimer = null;
            setCalibrationCopyButtonLabel('Copier');
        }, 900);
    }

    function legacyCopyText(text) {
        const temp = document.createElement('textarea');
        temp.value = String(text == null ? '' : text);
        temp.setAttribute('readonly', 'readonly');
        temp.style.position = 'fixed';
        temp.style.top = '-9999px';
        temp.style.left = '-9999px';
        temp.style.opacity = '0';
        document.body.appendChild(temp);

        let copied = false;
        try {
            temp.focus();
            temp.select();
            temp.setSelectionRange(0, temp.value.length);
            copied = document.execCommand('copy') === true;
        } catch (_) {
            copied = false;
        }

        document.body.removeChild(temp);
        return copied;
    }

    function copyCalibrationSnippetToClipboard() {
        const textToCopy = buildCalibrationConfigSnippet(buildCalibrationSnapshotFromState());
        const output = $('#job-map-calibration-output');
        output.val(textToCopy);

        if (legacyCopyText(textToCopy)) {
            markCalibrationCopied();
            return;
        }

        if (navigator.clipboard && typeof navigator.clipboard.writeText === 'function') {
            navigator.clipboard.writeText(textToCopy).then(function () {
                markCalibrationCopied();
            }).catch(function () {
                setCalibrationStatusMessage('Copie auto bloquee. Fenetre manuelle ouverte (CTRL+C).', true);
                try {
                    window.prompt('Copie manuelle: CTRL+C puis Entree', textToCopy);
                } catch (_) {
                }
            });
            return;
        }

        setCalibrationStatusMessage('Copie auto bloquee. Fenetre manuelle ouverte (CTRL+C).', true);
        try {
            window.prompt('Copie manuelle: CTRL+C puis Entree', textToCopy);
        } catch (_) {
        }
    }

    function getStatusLabel(status) {
        const normalized = (status || '').toLowerCase();
        if (normalized === 'vacant') {
            return getTranslation('job_house_available', 'Vacant');
        }
        if (normalized === 'agency') {
            return getTranslation('job_house_agency', 'Agence');
        }
        if (normalized === 'sold') {
            return getTranslation('job_house_sold', 'Vendu');
        }
        if (normalized === 'pap') {
            return getTranslation('job_house_pap_contract', 'PaP');
        }
        return getTranslation('status', 'Status');
    }

    function getStatusColor(status) {
        return STATUS_COLORS[(status || '').toLowerCase()] || '#d8dbe2';
    }

    function normalizeStatus(status) {
        const normalized = String(status || '').trim().toLowerCase();
        if (normalized === 'vacant' || normalized === 'agency' || normalized === 'sold' || normalized === 'pap') {
            return normalized;
        }
        return null;
    }

    function resolveHouseStatus(rawHouse) {
        const explicitStatus = normalizeStatus(rawHouse.status);
        if (explicitStatus) {
            return explicitStatus;
        }

        const hasOwner = rawHouse.hasOwner === true;
        const belongsToAgency = rawHouse.belongsToAgency === true;
        const hasPapContract = rawHouse.hasPapContract === true;
        const agencyContractType = String(rawHouse.agencyContractType || '').toLowerCase();

        if (hasPapContract) {
            return 'pap';
        }
        if (agencyContractType === 'rent' || (!hasOwner && belongsToAgency)) {
            return 'agency';
        }
        if (hasOwner) {
            return 'sold';
        }

        return 'vacant';
    }

    function normalizeHouseRecord(rawHouse) {
        if (!rawHouse || typeof rawHouse !== 'object') {
            return null;
        }

        const id = parseInt(rawHouse.id, 10);
        const rawCoords = rawHouse.coords && typeof rawHouse.coords === 'object' ? rawHouse.coords : {};
        const x = Number(rawCoords.x);
        const y = Number(rawCoords.y);
        const z = Number(rawCoords.z || 0);

        if (!Number.isFinite(id) || !Number.isFinite(x) || !Number.isFinite(y)) {
            return null;
        }

        const name = String(rawHouse.name || `Property #${id}`).trim() || `Property #${id}`;
        const zoneName = String(rawHouse.zoneName || '').trim();
        const status = resolveHouseStatus(rawHouse);

        return {
            id: id,
            name: name,
            zoneName: zoneName || getTranslation('job_house_unknown_zone', 'Unknown zone'),
            coords: {
                x: x,
                y: y,
                z: Number.isFinite(z) ? z : 0
            },
            price: Number.isFinite(Number(rawHouse.price)) ? Number(rawHouse.price) : 0,
            interior: Number.isFinite(Number(rawHouse.interior)) ? Number(rawHouse.interior) : 1,
            hasGarage: rawHouse.hasGarage === true,
            belongsToAgency: rawHouse.belongsToAgency === true,
            hasOwner: rawHouse.hasOwner === true,
            hasPapContract: rawHouse.hasPapContract === true,
            agencyContractType: String(rawHouse.agencyContractType || '').toLowerCase() || null,
            status: status,
            mapLatLng: null
        };
    }

    function normalizeExtendedState(extended) {
        const source = extended && typeof extended === 'object' ? extended : {};
        const available = source.available === true;
        const enabled = available && source.agencyMapEnabled === true;
        const canAccess = enabled && source.agencyMapCanAccess === true;

        mapState.available = available;
        mapState.enabled = enabled;
        mapState.canAccess = canAccess;
        mapState.resource = String(source.agencyMapResource || source.resource || mapState.resource || 'next_housing_extended');
        mapState.maxPoints = normalizeInteger(source.agencyMapMaxPoints, mapState.maxPoints || 2000, 50, 10000);
        mapState.maxRenderMarkers = normalizeInteger(
            source.agencyMapMaxRenderMarkers,
            Math.min(mapState.maxPoints || DEFAULT_MAX_RENDER_MARKERS, DEFAULT_MAX_RENDER_MARKERS),
            100,
            3000
        );
        mapState.bounds = normalizeBounds(source.agencyMapBounds || mapState.bounds || DEFAULT_BOUNDS);
        mapState.imageWidth = normalizeInteger(source.agencyMapImageWidth, mapState.imageWidth || DEFAULT_IMAGE_WIDTH, 1024, 16384);
        mapState.imageHeight = normalizeInteger(source.agencyMapImageHeight, mapState.imageHeight || DEFAULT_IMAGE_HEIGHT, 1024, 16384);
        mapState.imageRect = normalizeImageRect(source.agencyMapImageRect, mapState.imageWidth, mapState.imageHeight);
        mapState.invertY = normalizeBoolean(source.agencyMapInvertY, DEFAULT_INVERT_Y);
        mapState.projectionCorrection = normalizeProjectionCorrection(source.agencyMapProjectionCorrection || mapState.projectionCorrection);
        mapState.transform = normalizeTransform(source.agencyMapTransform || mapState.transform || DEFAULT_TRANSFORM);
        refreshProjectedCoords();
        captureCalibrationBaselineFromState();
        syncCalibrationInputsFromState();
    }

    function isMapTabActive() {
        return $('#job-tab-map').hasClass('active');
    }

    function updateTabVisibility() {
        const mapTabButton = $('#job-map-tab-btn');
        const shouldShow = mapState.available && mapState.enabled && mapState.canAccess;
        mapTabButton.toggle(shouldShow);

        if (!shouldShow && isMapTabActive() && typeof window.switchTab === 'function') {
            window.switchTab('houses');
        }
    }

    function setLoading(isLoading) {
        mapState.loading = isLoading === true;
        $('#job-map-loading').toggleClass('hidden', !mapState.loading);
    }

    function showUnavailable(message) {
        const fallback = getTranslation('extended_status_not_detected', 'Next Housing Extended not detected.');
        const resolved = String(message || fallback);
        $('#job-map-unavailable p').text(resolved);
        $('#job-map-unavailable').removeClass('hidden');
        $('#job-map-canvas-wrap').hide();
    }

    function hideUnavailable() {
        $('#job-map-unavailable').addClass('hidden');
        $('#job-map-canvas-wrap').show();
    }

    function mapSignatureFromState() {
        return JSON.stringify({
            bounds: mapState.bounds,
            imageWidth: mapState.imageWidth,
            imageHeight: mapState.imageHeight,
            imageRect: mapState.imageRect,
            invertY: mapState.invertY
        });
    }

    function getLeafletBounds() {
        return [
            [0, 0],
            [mapState.imageHeight, mapState.imageWidth]
        ];
    }

    function destroyMapIfNeeded(newSignature) {
        if (!mapState.map) {
            return;
        }
        if (mapState.mapSignature === newSignature) {
            return;
        }

        try {
            mapState.map.remove();
        } catch (_) {
        }

        mapState.map = null;
        mapState.mapLayer = null;
        mapState.calibrationRefLayer = null;
        mapState.mapMarkersById = {};
        mapState.mapOverlay = null;
        mapState.mapSignature = '';
    }

    function ensureMap() {
        if (typeof L === 'undefined') {
            showUnavailable('Leaflet non charge.');
            return false;
        }

        const container = document.getElementById('job-agency-map');
        if (!container) {
            return false;
        }

        const signature = mapSignatureFromState();
        destroyMapIfNeeded(signature);

        if (mapState.map) {
            mapState.map.invalidateSize();
            return true;
        }

        const imageBounds = getLeafletBounds();
        mapState.map = L.map('job-agency-map', {
            crs: L.CRS.Simple,
            minZoom: -2,
            maxZoom: 6,
            zoomControl: true,
            attributionControl: false,
            preferCanvas: true,
            maxBoundsViscosity: 0.95,
            zoomSnap: 0,
            zoomDelta: 0.5,
            zoomAnimation: false,
            fadeAnimation: false,
            markerZoomAnimation: false,
            inertia: false
        }).setView([mapState.imageHeight * 0.5, mapState.imageWidth * 0.5], 0);

        mapState.mapOverlay = L.imageOverlay(JOB_MAP_IMAGE_PATH, imageBounds).addTo(mapState.map);
        mapState.mapLayer = L.layerGroup().addTo(mapState.map);
        mapState.calibrationRefLayer = L.layerGroup().addTo(mapState.map);
        mapState.mapSignature = signature;
        mapState.map.setMaxBounds(imageBounds);
        mapState.map.fitBounds(imageBounds, { animate: false });
        mapState.map.on('moveend zoomend', function () {
            if (!isMapTabActive() || !mapState.loadedOnce) {
                return;
            }
            renderMarkers();
        });
        mapState.map.on('click', function (event) {
            if (!event || !event.latlng) {
                return;
            }
            handleCalibrationMapClick(event.latlng);
        });
        renderCalibrationReferenceMarkers();

        return true;
    }

    function markerStyle(status, isSelected) {
        const color = getStatusColor(status);
        return {
            radius: isSelected ? 8 : 6,
            color: color,
            weight: isSelected ? 3 : 2,
            fillColor: color,
            fillOpacity: isSelected ? 0.98 : 0.88
        };
    }

    function buildPopupHtml(house) {
        const safeName = escapeHtml(house.name || (`Property #${house.id}`));
        const safeZone = escapeHtml(house.zoneName || getTranslation('job_house_unknown_zone', 'Unknown zone'));
        const statusLabel = escapeHtml(getStatusLabel(house.status));
        const priceLabel = typeof window.formatPrice === 'function'
            ? window.formatPrice(house.price || 0)
            : `${house.price || 0} $`;

        return `
            <div class="nh-map-popup" data-house-id="${house.id}">
                <div class="nh-map-popup-title">${safeName}</div>
                <div class="nh-map-popup-meta">${safeZone}<br>${statusLabel} - ${escapeHtml(priceLabel)}</div>
                <div class="nh-map-popup-actions">
                    <button class="nh-map-popup-btn" data-map-action="gps" data-map-house-id="${house.id}">GPS</button>
                    <button class="nh-map-popup-btn" data-map-action="details" data-map-house-id="${house.id}">Fiche</button>
                </div>
            </div>
        `;
    }

    function setSelectedMarkerStyle() {
        Object.keys(mapState.mapMarkersById).forEach(function (key) {
            const marker = mapState.mapMarkersById[key];
            if (!marker || typeof marker.setStyle !== 'function') {
                return;
            }

            const status = marker._nhStatus || 'vacant';
            const isSelected = Number(key) === Number(mapState.selectedHouseId);
            marker.setStyle(markerStyle(status, isSelected));
        });
    }

    function getRenderableMarkerHouses() {
        const source = Array.isArray(mapState.filteredHouses) ? mapState.filteredHouses : [];
        if (!mapState.map || source.length === 0) {
            return source.slice(0, mapState.maxRenderMarkers);
        }

        const markerLimit = normalizeInteger(
            mapState.maxRenderMarkers,
            Math.min(mapState.maxPoints || DEFAULT_MAX_RENDER_MARKERS, DEFAULT_MAX_RENDER_MARKERS),
            100,
            3000
        );
        const mapBounds = mapState.map.getBounds();
        const latPad = (mapBounds.getNorth() - mapBounds.getSouth()) * 0.2;
        const lngPad = (mapBounds.getEast() - mapBounds.getWest()) * 0.2;
        const minLat = mapBounds.getSouth() - latPad;
        const maxLat = mapBounds.getNorth() + latPad;
        const minLng = mapBounds.getWest() - lngPad;
        const maxLng = mapBounds.getEast() + lngPad;

        const visible = [];
        for (let i = 0; i < source.length; i += 1) {
            const house = source[i];
            const latLng = house && house.mapLatLng;
            if (!Array.isArray(latLng)) {
                continue;
            }

            const lat = Number(latLng[0]);
            const lng = Number(latLng[1]);
            if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
                continue;
            }

            if (lat < minLat || lat > maxLat || lng < minLng || lng > maxLng) {
                continue;
            }

            visible.push(house);
            if (visible.length >= markerLimit) {
                break;
            }
        }

        if (visible.length === 0) {
            return source.slice(0, markerLimit);
        }

        if (mapState.selectedHouseId != null) {
            const selectedId = Number(mapState.selectedHouseId);
            const alreadyIncluded = visible.some(function (house) {
                return Number(house.id) === selectedId;
            });
            if (!alreadyIncluded) {
                const selected = findHouseById(selectedId);
                if (selected && Array.isArray(selected.mapLatLng)) {
                    visible.push(selected);
                }
            }
        }

        return visible;
    }

    function renderMarkers() {
        if (!mapState.map || !mapState.mapLayer) {
            return;
        }

        mapState.mapLayer.clearLayers();
        mapState.mapMarkersById = {};

        getRenderableMarkerHouses().forEach(function (house) {
            if (!Array.isArray(house.mapLatLng)) {
                return;
            }

            const marker = L.circleMarker(house.mapLatLng, markerStyle(house.status, false));
            marker._nhHouseId = house.id;
            marker._nhStatus = house.status;
            marker.bindPopup(buildPopupHtml(house), { closeButton: false, autoPan: true });
            marker.on('click', function () {
                selectHouse(house.id, {
                    center: false,
                    openPopup: true
                });
            });

            mapState.mapLayer.addLayer(marker);
            mapState.mapMarkersById[String(house.id)] = marker;
        });

        setSelectedMarkerStyle();
    }

    function renderStats() {
        $('#job-map-stat-total').text(String(mapState.houses.length));
        $('#job-map-stat-visible').text(String(mapState.filteredHouses.length));
    }

    function buildHouseType(house) {
        if (typeof window.getHouseType === 'function') {
            return window.getHouseType(house.interior);
        }
        return `Interior ${house.interior || 1}`;
    }

    function renderList() {
        const list = $('#job-map-houses-list');
        const empty = $('#job-map-empty');
        list.empty();

        if (mapState.calibrationMode === true) {
            list.addClass('hidden');
            empty.addClass('hidden');
            return;
        }

        list.removeClass('hidden');

        if (!mapState.filteredHouses.length) {
            empty.removeClass('hidden');
            return;
        }

        empty.addClass('hidden');

        mapState.filteredHouses.forEach(function (house) {
            const statusLabel = getStatusLabel(house.status);
            const statusColor = getStatusColor(house.status);
            const priceLabel = typeof window.formatPrice === 'function'
                ? window.formatPrice(house.price || 0)
                : `${house.price || 0} $`;
            const isActive = Number(mapState.selectedHouseId) === Number(house.id);

            const item = $('<div>')
                .addClass('job-map-house-item')
                .attr('data-house-id', house.id);

            if (isActive) {
                item.addClass('is-active');
            }

            const head = $('<div>').addClass('job-map-house-head');
            const titleWrap = $('<div>')
                .append($('<p>').addClass('job-map-house-title').text(house.name || (`Property #${house.id}`)))
                .append($('<p>').addClass('job-map-house-zone').text(house.zoneName || getTranslation('job_house_unknown_zone', 'Unknown zone')));

            const status = $('<span>')
                .addClass('job-map-house-status')
                .text(statusLabel)
                .css({
                    color: statusColor,
                    borderColor: `${statusColor}66`,
                    background: `${statusColor}1A`
                });

            head.append(titleWrap);
            head.append(status);
            item.append(head);

            const meta = $('<div>').addClass('job-map-house-meta');
            const appendMeta = function (label, value) {
                const chip = $('<div>').addClass('job-map-house-chip');
                chip.append($('<span>').addClass('job-map-house-chip-label').text(label));
                chip.append($('<span>').addClass('job-map-house-chip-value').text(value));
                meta.append(chip);
            };

            const garageValue = window.nhGaragesEnabled === false
                ? getTranslation('pap_property_unavailable', 'Unavailable')
                : (house.hasGarage ? getTranslation('job_house_yes', 'Yes') : getTranslation('job_house_no', 'No'));

            appendMeta(getTranslation('job_house_price', 'Price'), priceLabel);
            appendMeta(getTranslation('job_house_type', 'Type'), buildHouseType(house));
            appendMeta(getTranslation('job_house_garage', 'Garage'), garageValue);
            appendMeta(getTranslation('job_house_number', 'Property #'), `#${house.id}`);
            item.append(meta);

            const actions = $('<div>').addClass('job-map-house-actions');
            actions.append(
                $('<button>')
                    .addClass('job-map-house-btn')
                    .attr('data-map-action', 'gps')
                    .attr('data-map-house-id', house.id)
                    .text('GPS')
            );
            actions.append(
                $('<button>')
                    .addClass('job-map-house-btn')
                    .attr('data-map-action', 'details')
                    .attr('data-map-house-id', house.id)
                    .text(getTranslation('job_modal_property_info', 'Details'))
            );
            item.append(actions);

            item.on('click', function (event) {
                if ($(event.target).closest('button').length) {
                    return;
                }
                selectHouse(house.id, { center: true, openPopup: true });
            });

            list.append(item);
        });
    }

    function applyFilters() {
        const search = String(mapState.filterSearch || '').trim().toLowerCase();
        mapState.filteredHouses = mapState.houses.filter(function (house) {
            if (mapState.filterStatus !== 'all' && house.status !== mapState.filterStatus) {
                return false;
            }
            if (mapState.onlyAgency && house.belongsToAgency !== true) {
                return false;
            }
            if (!search) {
                return true;
            }

            const haystack = [
                house.name || '',
                String(house.id || ''),
                house.zoneName || '',
                getStatusLabel(house.status)
            ].join(' ').toLowerCase();

            return haystack.includes(search);
        });
    }

    function renderMapTab() {
        applyFilters();
        renderStats();
        renderList();
        renderMarkers();
    }

    function selectHouse(houseId, options) {
        const opts = options || {};
        const numericId = Number(houseId);
        if (!Number.isFinite(numericId)) {
            return;
        }

        mapState.selectedHouseId = numericId;

        $('#job-map-houses-list .job-map-house-item').removeClass('is-active');
        $(`#job-map-houses-list .job-map-house-item[data-house-id="${numericId}"]`).addClass('is-active');

        let marker = mapState.mapMarkersById[String(numericId)];
        if (!marker && mapState.map && opts.center !== false) {
            const selectedHouse = findHouseById(numericId);
            if (selectedHouse && Array.isArray(selectedHouse.mapLatLng)) {
                mapState.map.panTo(selectedHouse.mapLatLng, { animate: false });
                renderMarkers();
                marker = mapState.mapMarkersById[String(numericId)];
            }
        }

        if (marker && mapState.map) {
            if (opts.center !== false) {
                mapState.map.panTo(marker.getLatLng(), { animate: false });
            }

            if (opts.openPopup === true) {
                marker.openPopup();
            }
        }

        setSelectedMarkerStyle();
    }

    function findHouseById(houseId) {
        return mapState.housesById[String(houseId)] || null;
    }

    function handleHouseAction(action, houseId) {
        const house = findHouseById(houseId);
        if (!house) {
            return;
        }

        if (action === 'gps') {
            const payload = {
                coords: house.coords,
                houseId: house.id
            };
            const resourceName = resolveNuiResourceName();
            $.post(`https://${resourceName}/viewOnMap`, JSON.stringify(payload));
            selectHouse(house.id, { center: true, openPopup: true });
            return;
        }

        if (action === 'details') {
            if (typeof window.nhOpenJobHouseDetails === 'function') {
                window.nhOpenJobHouseDetails(house.id);
            }
            return;
        }
    }

    function normalizeMapResponse(payload) {
        const source = payload && typeof payload === 'object' ? payload : {};
        const houses = Array.isArray(source.houses) ? source.houses : [];
        const normalizedHouses = [];
        const byId = {};

        houses.forEach(function (rawHouse) {
            const house = normalizeHouseRecord(rawHouse);
            if (!house) {
                return;
            }

            normalizedHouses.push(house);
            byId[String(house.id)] = house;
        });

        mapState.houses = normalizedHouses;
        mapState.housesById = byId;
        mapState.maxPoints = normalizeInteger(source.agencyMapMaxPoints, mapState.maxPoints, 50, 10000);
        mapState.maxRenderMarkers = normalizeInteger(
            source.agencyMapMaxRenderMarkers,
            Math.min(mapState.maxPoints || DEFAULT_MAX_RENDER_MARKERS, DEFAULT_MAX_RENDER_MARKERS),
            100,
            3000
        );
        mapState.bounds = normalizeBounds(source.agencyMapBounds || mapState.bounds);
        mapState.imageWidth = normalizeInteger(source.agencyMapImageWidth, mapState.imageWidth || DEFAULT_IMAGE_WIDTH, 1024, 16384);
        mapState.imageHeight = normalizeInteger(source.agencyMapImageHeight, mapState.imageHeight || DEFAULT_IMAGE_HEIGHT, 1024, 16384);
        mapState.imageRect = normalizeImageRect(source.agencyMapImageRect, mapState.imageWidth, mapState.imageHeight);
        mapState.invertY = normalizeBoolean(source.agencyMapInvertY, mapState.invertY);
        mapState.projectionCorrection = normalizeProjectionCorrection(source.agencyMapProjectionCorrection || mapState.projectionCorrection);
        mapState.transform = normalizeTransform(source.agencyMapTransform || mapState.transform);
        refreshProjectedCoords();
        captureCalibrationBaselineFromState();
        syncCalibrationInputsFromState();
    }

    function getMapFetchMessage(payload) {
        const messageKey = String((payload && payload.message) || '').trim();
        if (messageKey === 'not_allowed') {
            return getTranslation('job_notification_must_be_agent_command', 'You must be a real estate agent to use this command.');
        }
        if (messageKey === 'extension_unavailable') {
            return 'Next Housing Extended map unavailable.';
        }
        if (messageKey === 'rate_limited') {
            return 'Map request throttled. Please wait.';
        }
        return 'Unable to load map data.';
    }

    function fetchMapData(forceRefresh, options) {
        const opts = options && typeof options === 'object' ? options : {};
        const showLoader = opts.showLoader !== false;
        const silentRateLimit = opts.silentRateLimit === true;
        const resourceName = resolveNuiResourceName();

        if (showLoader) {
            setLoading(true);
        }
        hideUnavailable();

        $.post(`https://${resourceName}/getExtendedAgencyMapData`, JSON.stringify({
            forceRefresh: forceRefresh === true
        }), function (resp) {
            let payload = null;
            try {
                payload = typeof resp === 'string' ? JSON.parse(resp) : resp;
            } catch (_) {
                payload = null;
            }

            if (!payload || payload.success !== true) {
                if (showLoader) {
                    setLoading(false);
                }
                const errorMessage = getMapFetchMessage(payload);
                if (payload && payload.message === 'rate_limited' && mapState.loadedOnce) {
                    if (!silentRateLimit && typeof window.showJobAlert === 'function') {
                        window.showJobAlert(errorMessage);
                    }
                    return;
                }

                if (!showLoader && mapState.loadedOnce) {
                    return;
                }

                mapState.loadedOnce = false;
                showUnavailable(errorMessage);
                return;
            }

            normalizeMapResponse(payload);
            mapState.loadedOnce = true;

            if (!ensureMap()) {
                mapState.loadedOnce = false;
                showUnavailable('Map initialization failed.');
                if (showLoader) {
                    setLoading(false);
                }
                return;
            }

            renderMapTab();
            if (showLoader) {
                setLoading(false);
            }
            hideUnavailable();

            if (mapState.map) {
                setTimeout(function () {
                    if (mapState.map) {
                        mapState.map.invalidateSize();
                    }
                }, 80);
            }
        }).fail(function () {
            if (showLoader) {
                mapState.loadedOnce = false;
                setLoading(false);
                showUnavailable('Map request failed.');
            }
        });
    }

    function openTab(forceRefresh) {
        if (!mapState.available || !mapState.enabled || !mapState.canAccess) {
            setLoading(false);
            showUnavailable('Next Housing Extended map unavailable.');
            return;
        }

        if (!ensureMap()) {
            setLoading(false);
            showUnavailable('Map initialization failed.');
            return;
        }

        hideUnavailable();

        if (!mapState.loadedOnce || forceRefresh === true) {
            fetchMapData(forceRefresh === true, { showLoader: true });
            return;
        }

        renderMapTab();
        fetchMapData(false, {
            showLoader: false,
            silentRateLimit: true
        });
        if (mapState.map) {
            setTimeout(function () {
                if (mapState.map) {
                    mapState.map.invalidateSize();
                }
            }, 50);
        }
    }

    function resetOnClose() {
        if (mapSearchDebounceTimer) {
            clearTimeout(mapSearchDebounceTimer);
            mapSearchDebounceTimer = null;
        }
        if (calibrationApplyDebounceTimer) {
            clearTimeout(calibrationApplyDebounceTimer);
            calibrationApplyDebounceTimer = null;
        }
        if (calibrationCopyFeedbackTimer) {
            clearTimeout(calibrationCopyFeedbackTimer);
            calibrationCopyFeedbackTimer = null;
        }

        mapState.selectedHouseId = null;
        mapState.filterSearch = '';
        mapState.filterStatus = 'all';
        mapState.onlyAgency = false;
        mapState.calibrationCaptureRefId = null;
        mapState.calibrationStatusMessage = '';
        mapState.calibrationStatusError = false;
        mapState.calibrationAdvancedMode = false;

        $('#job-map-search-input').val('');
        $('#job-map-status-filter').val('all');
        $('#job-map-only-agency').prop('checked', false);
        $('#job-map-houses-list').empty();
        $('#job-map-empty').addClass('hidden');
        setCalibrationCopyButtonLabel('Copier');
        setCalibrationAdvancedMode(false);
        syncCalibrationInputsFromState();
    }

    function bindUi() {
        if (mapState.bindDone) {
            return;
        }

        mapState.bindDone = true;

        $(document)
            .off('input.nhJobMap', '#job-map-search-input')
            .on('input.nhJobMap', '#job-map-search-input', function () {
                mapState.filterSearch = ($(this).val() || '').toString();
                if (isMapTabActive() && mapState.loadedOnce) {
                    if (mapSearchDebounceTimer) {
                        clearTimeout(mapSearchDebounceTimer);
                    }
                    mapSearchDebounceTimer = setTimeout(function () {
                        renderMapTab();
                    }, 90);
                }
            });

        $(document)
            .off('change.nhJobMap', '#job-map-status-filter')
            .on('change.nhJobMap', '#job-map-status-filter', function () {
                mapState.filterStatus = String($(this).val() || 'all').trim().toLowerCase();
                if (mapState.filterStatus !== 'vacant' && mapState.filterStatus !== 'agency' && mapState.filterStatus !== 'sold' && mapState.filterStatus !== 'pap') {
                    mapState.filterStatus = 'all';
                }
                if (isMapTabActive() && mapState.loadedOnce) {
                    renderMapTab();
                }
            });

        $(document)
            .off('change.nhJobMap', '#job-map-only-agency')
            .on('change.nhJobMap', '#job-map-only-agency', function () {
                mapState.onlyAgency = $(this).is(':checked');
                if (isMapTabActive() && mapState.loadedOnce) {
                    renderMapTab();
                }
            });

        $(document)
            .off('click.nhJobMap', '.job-map-house-btn')
            .on('click.nhJobMap', '.job-map-house-btn', function (event) {
                event.preventDefault();
                event.stopPropagation();
                const action = String($(this).attr('data-map-action') || '').trim().toLowerCase();
                const houseId = parseInt($(this).attr('data-map-house-id'), 10);
                if (!Number.isFinite(houseId)) {
                    return;
                }
                handleHouseAction(action, houseId);
            });

        $(document)
            .off('click.nhJobMapPopup', '.nh-map-popup-btn')
            .on('click.nhJobMapPopup', '.nh-map-popup-btn', function (event) {
                event.preventDefault();
                const action = String($(this).attr('data-map-action') || '').trim().toLowerCase();
                const houseId = parseInt($(this).attr('data-map-house-id'), 10);
                if (!Number.isFinite(houseId)) {
                    return;
                }
                handleHouseAction(action, houseId);
            });

        $(document)
            .off('input.nhJobMapCalibration change.nhJobMapCalibration', '.job-map-calibration-input')
            .on('input.nhJobMapCalibration change.nhJobMapCalibration', '.job-map-calibration-input', function () {
                if (!mapState.calibrationMode || !isMapTabActive()) {
                    return;
                }
                scheduleCalibrationApplyFromInputs();
            });

        $(document)
            .off('input.nhJobMapCalibrationRefs change.nhJobMapCalibrationRefs', '.job-map-calibration-ref-input')
            .on('input.nhJobMapCalibrationRefs change.nhJobMapCalibrationRefs', '.job-map-calibration-ref-input', function () {
                if (!mapState.calibrationMode || !isMapTabActive()) {
                    return;
                }
                updateCalibrationRefsFromInputs();
            });

        $(document)
            .off('change.nhJobMapCalibration', '#job-map-calib-inverty')
            .on('change.nhJobMapCalibration', '#job-map-calib-inverty', function () {
                if (!mapState.calibrationMode || !isMapTabActive()) {
                    return;
                }
                applyCalibrationSnapshot(buildCalibrationSnapshotFromInputs());
            });

        $(document)
            .off('click.nhJobMapCalibration', '#job-map-calib-apply')
            .on('click.nhJobMapCalibration', '#job-map-calib-apply', function (event) {
                event.preventDefault();
                applyCalibrationSnapshot(buildCalibrationSnapshotFromInputs());
            });

        $(document)
            .off('click.nhJobMapCalibration', '#job-map-calib-reset')
            .on('click.nhJobMapCalibration', '#job-map-calib-reset', function (event) {
                event.preventDefault();
                const baseline = mapState.calibrationBaseline && typeof mapState.calibrationBaseline === 'object'
                    ? deepClone(mapState.calibrationBaseline)
                    : buildCalibrationSnapshotFromState();
                applyCalibrationSnapshot(baseline);
            });

        $(document)
            .off('click.nhJobMapCalibration', '#job-map-calib-copy')
            .on('click.nhJobMapCalibration', '#job-map-calib-copy', function (event) {
                event.preventDefault();
                copyCalibrationSnippetToClipboard();
            });

        $(document)
            .off('click.nhJobMapCalibration', '#job-map-calib-copy-simple')
            .on('click.nhJobMapCalibration', '#job-map-calib-copy-simple', function (event) {
                event.preventDefault();
                copyCalibrationSnippetToClipboard();
            });

        $(document)
            .off('click.nhJobMapCalibration', '#job-map-calib-toggle-advanced')
            .on('click.nhJobMapCalibration', '#job-map-calib-toggle-advanced', function (event) {
                event.preventDefault();
                setCalibrationAdvancedMode(!(mapState.calibrationAdvancedMode === true));
            });

        $(document)
            .off('click.nhJobMapCalibration', '[data-calib-nudge]')
            .on('click.nhJobMapCalibration', '[data-calib-nudge]', function (event) {
                event.preventDefault();
                const direction = String($(this).attr('data-calib-nudge') || '').trim().toLowerCase();
                if (!direction) {
                    return;
                }
                nudgeCalibration(direction);
            });

        $(document)
            .off('click.nhJobMapCalibration', '[data-calib-capture-ref]')
            .on('click.nhJobMapCalibration', '[data-calib-capture-ref]', function (event) {
                event.preventDefault();
                if (!mapState.map) {
                    setCalibrationStatusMessage('Map indisponible pour capture.', true);
                    return;
                }

                const normalizedRefId = normalizeCalibrationRefId($(this).attr('data-calib-capture-ref'));
                if (!normalizedRefId) {
                    return;
                }
                updateCalibrationRefsFromInputs();
                mapState.calibrationCaptureRefId = normalizedRefId;
                mapState.calibrationStatusMessage = '';
                mapState.calibrationStatusError = false;
                syncCalibrationRefInputsFromState();
                renderCalibrationReferenceMarkers();
            });

        $(document)
            .off('click.nhJobMapCalibration', '[data-calib-clear-ref]')
            .on('click.nhJobMapCalibration', '[data-calib-clear-ref]', function (event) {
                event.preventDefault();
                const normalizedRefId = normalizeCalibrationRefId($(this).attr('data-calib-clear-ref'));
                if (!normalizedRefId) {
                    return;
                }

                const refs = mapState.calibrationRefs && typeof mapState.calibrationRefs === 'object'
                    ? mapState.calibrationRefs
                    : buildDefaultCalibrationRefs();
                refs[normalizedRefId] = {
                    worldX: null,
                    worldY: null,
                    targetX: null,
                    targetY: null
                };
                mapState.calibrationRefs = refs;
                if (mapState.calibrationCaptureRefId === normalizedRefId) {
                    mapState.calibrationCaptureRefId = null;
                }
                mapState.calibrationStatusMessage = '';
                mapState.calibrationStatusError = false;
                syncCalibrationRefInputsFromState();
                renderCalibrationReferenceMarkers();
            });

        $(document)
            .off('click.nhJobMapCalibration', '#job-map-calib-autosolve')
            .on('click.nhJobMapCalibration', '#job-map-calib-autosolve', function (event) {
                event.preventDefault();
                runAutoAffineCalibration();
            });

        $(document)
            .off('click.nhJobMapCalibration', '#job-map-calib-affine-reset')
            .on('click.nhJobMapCalibration', '#job-map-calib-affine-reset', function (event) {
                event.preventDefault();
                const snapshot = buildCalibrationSnapshotFromInputs();
                snapshot.projectionCorrection.affineA = DEFAULT_PROJECTION_CORRECTION.affineA;
                snapshot.projectionCorrection.affineB = DEFAULT_PROJECTION_CORRECTION.affineB;
                snapshot.projectionCorrection.affineC = DEFAULT_PROJECTION_CORRECTION.affineC;
                snapshot.projectionCorrection.affineD = DEFAULT_PROJECTION_CORRECTION.affineD;
                snapshot.projectionCorrection.affineTX = DEFAULT_PROJECTION_CORRECTION.affineTX;
                snapshot.projectionCorrection.affineTY = DEFAULT_PROJECTION_CORRECTION.affineTY;
                applyCalibrationSnapshot(snapshot);
                setCalibrationStatusMessage('Affine reset.', false);
            });
    }

    function onInterfaceOpen(payload) {
        const source = payload && typeof payload === 'object' ? payload : {};
        normalizeExtendedState(source.extended);
        updateTabVisibility();
        setCalibrationPanelVisibility();

        if (isMapTabActive()) {
            openTab(false);
        }
    }

    function onInterfaceClose() {
        resetOnClose();
    }

    function onHousesUpdated() {
        if (!mapState.loadedOnce || !isMapTabActive()) {
            return;
        }
        renderMapTab();
    }

    function updateExtendedState(extended) {
        normalizeExtendedState(extended);
        updateTabVisibility();
        setCalibrationPanelVisibility();

        if (isMapTabActive()) {
            openTab(false);
        }
    }

    window.nhJobMapOnInterfaceOpen = onInterfaceOpen;
    window.nhJobMapOnInterfaceClose = onInterfaceClose;
    window.nhJobMapOnHousesUpdated = onHousesUpdated;
    window.nhJobMapOpenTab = openTab;
    window.nhJobMapUpdateExtendedState = updateExtendedState;

    $(document).ready(function () {
        bindUi();
        updateTabVisibility();
        setCalibrationPanelVisibility();
        syncCalibrationInputsFromState();
    });
})();
