import QtQuick
import qs.modules.common.widgets.haiiro

// The haiiro background, drawn by the installer itself: cage has no blob
// background of its own (hecate draws it in the compositor). The same
// simulation as the design system's Blobs board and hecate's
// [background.blobs] defaults: 6px cells, metaballs r²/(d²+0.01) summed
// within 3r, a 4x4 Bayer ramp into three tones, merges that keep area up to
// radius 24, new blobs drifting in from off-screen under 85% of the target.
//
// It runs on the CPU so it looks the same with or without GL. `fps` caps the
// steps; `still` (reduced motion) settles 300 steps of 0.1s and draws once.
Item {
    id: root

    property int cell: 6
    property int density: 700
    property int countMin: 6
    property int countMax: 60
    property real radiusMax: 24
    property real speedMin: 1.5
    property real speedMax: 6
    property int fps: 30
    property bool still: HTokens.cut
    property bool running: true
    property color ground: HTokens.base
    property color halo: HTokens.overlay
    property color core: HTokens.highlightMed

    readonly property int cols: Math.max(1, Math.ceil(width / cell))
    readonly property int rows: Math.max(1, Math.ceil(height / cell))

    property var blobs: []
    property var field: null
    property int target: 0
    property real last: 0

    readonly property var bayer: [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5].map(v => (v + 0.5) / 16)

    function rnd(a, b) {
        return a + Math.random() * (b - a);
    }
    function radius() {
        return 2 + Math.pow(Math.random(), 2) * 7;
    }
    function add(x, y, r, ang) {
        const s = rnd(speedMin, speedMax);
        blobs.push({
            x: x,
            y: y,
            r: r,
            vx: Math.cos(ang) * s,
            vy: Math.sin(ang) * s
        });
    }
    function spawn() {
        const W = cols, H = rows, r = radius(), side = Math.floor(Math.random() * 4), m = 3 * r;
        let x, y;
        if (side === 0) {
            x = -m;
            y = rnd(0, H);
        } else if (side === 1) {
            x = W + m;
            y = rnd(0, H);
        } else if (side === 2) {
            x = rnd(0, W);
            y = -m;
        } else {
            x = rnd(0, W);
            y = H + m;
        }
        add(x, y, r, Math.atan2(H / 2 - y, W / 2 - x) + rnd(-0.6, 0.6));
    }

    function reset() {
        if (width <= 0 || height <= 0)
            return;
        field = new Float32Array(cols * rows);
        target = Math.max(countMin, Math.min(countMax, Math.round(cols * rows / density)));
        blobs = [];
        for (let i = 0; i < target; i++)
            add(rnd(0, cols), rnd(0, rows), radius(), rnd(0, Math.PI * 2));
        if (still)
            for (let i = 0; i < 300; i++)
                step(0.1);
        canvas.requestPaint();
    }

    function step(dt) {
        const W = cols, H = rows, bs = blobs;
        for (const b of bs) {
            b.x += b.vx * dt;
            b.y += b.vy * dt;
        }
        for (let i = 0; i < bs.length; i++) {
            for (let j = i + 1; j < bs.length; j++) {
                const a = bs[i], c = bs[j];
                const d = Math.hypot(a.x - c.x, a.y - c.y);
                const nr = Math.sqrt(a.r * a.r + c.r * c.r);
                if (d <= Math.max(a.r, c.r) && nr <= radiusMax) {
                    const wa = a.r * a.r, wc = c.r * c.r, w = wa + wc;
                    a.x = (a.x * wa + c.x * wc) / w;
                    a.y = (a.y * wa + c.y * wc) / w;
                    a.vx = (a.vx * wa + c.vx * wc) / w;
                    a.vy = (a.vy * wa + c.vy * wc) / w;
                    let s = Math.hypot(a.vx, a.vy);
                    if (s < 1e-3) {
                        const ang = rnd(0, Math.PI * 2);
                        a.vx = Math.cos(ang);
                        a.vy = Math.sin(ang);
                        s = 1;
                    }
                    if (s < speedMin) {
                        a.vx *= speedMin / s;
                        a.vy *= speedMin / s;
                    }
                    a.r = nr;
                    bs.splice(j, 1);
                    j--;
                }
            }
        }
        for (let i = bs.length - 1; i >= 0; i--) {
            const b = bs[i], m = 3 * b.r + 2;
            if ((b.x < -m && b.vx <= 0) || (b.x > W + m && b.vx >= 0) || (b.y < -m && b.vy <= 0) || (b.y > H + m && b.vy >= 0))
                bs.splice(i, 1);
        }
        while (bs.length < target * 0.85)
            spawn();
    }

    onColsChanged: reset()
    onRowsChanged: reset()
    onStillChanged: reset()
    Component.onCompleted: reset()

    Rectangle {
        anchors.fill: parent
        color: root.ground
    }

    // One canvas pixel per cell, scaled up with hard edges.
    Canvas {
        id: canvas
        width: root.cols
        height: root.rows
        scale: root.cell
        transformOrigin: Item.TopLeft
        smooth: false
        antialiasing: false
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Immediate

        onPaint: {
            const field = root.field;
            if (!field)
                return;
            const W = root.cols, H = root.rows, bayer = root.bayer;
            field.fill(0);
            for (const b of root.blobs) {
                const R = 3 * b.r, r2 = b.r * b.r;
                const x0 = Math.max(0, Math.floor(b.x - R)), x1 = Math.min(W - 1, Math.ceil(b.x + R));
                const y0 = Math.max(0, Math.floor(b.y - R)), y1 = Math.min(H - 1, Math.ceil(b.y + R));
                for (let y = y0; y <= y1; y++) {
                    const dy = y + 0.5 - b.y, dy2 = dy * dy, row = y * W;
                    for (let x = x0; x <= x1; x++) {
                        const dx = x + 0.5 - b.x;
                        field[row + x] += r2 / (dx * dx + dy2 + 0.01);
                    }
                }
            }
            const ctx = getContext("2d");
            ctx.fillStyle = root.ground;
            ctx.fillRect(0, 0, W, H);
            // Runs of one tone per row: far fewer calls than one per cell.
            const tones = [null, root.halo, root.core];
            for (let y = 0; y < H; y++) {
                const row = y * W, by = (y & 3) * 4;
                let run = 0, start = 0;
                for (let x = 0; x <= W; x++) {
                    let tone = 0;
                    if (x < W) {
                        const f = field[row + x], t = bayer[by + (x & 3)];
                        tone = (f - 0.9) / 0.5 > t ? 2 : (f - 0.3) / 0.75 > t ? 1 : 0;
                    }
                    if (tone !== run) {
                        if (run !== 0) {
                            ctx.fillStyle = tones[run];
                            ctx.fillRect(start, y, x - start, 1);
                        }
                        run = tone;
                        start = x;
                    }
                }
            }
        }
    }

    Timer {
        interval: Math.round(1000 / Math.max(1, root.fps))
        repeat: true
        running: root.running && !root.still && root.visible && root.field !== null
        onTriggered: {
            const now = Date.now();
            const dt = root.last > 0 ? Math.min(0.1, (now - root.last) / 1000) : interval / 1000;
            root.last = now;
            root.step(dt);
            canvas.requestPaint();
        }
        onRunningChanged: root.last = 0
    }
}
