pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The hecate shell's look: its Material You roles (read from a colors.json in
// the shell's own format), layers, rounding and fonts. CAKEOS_COLORS points
// it at another colors.json, such as a running shell's generated one.
Singleton {
    id: root

    property var roles: ({})

    function role(name, fallback) {
        return roles[name] ?? fallback;
    }
    function mix(a, b, weight) {
        return Qt.rgba(a.r * weight + b.r * (1 - weight), a.g * weight + b.g * (1 - weight), a.b * weight + b.b * (1 - weight), a.a * weight + b.a * (1 - weight));
    }
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    FileView {
        path: Quickshell.env("CAKEOS_COLORS") || Qt.resolvedUrl("colors.json").toString().replace("file://", "")
        blockLoading: true
        onLoaded: root.roles = JSON.parse(text())
    }

    readonly property url wallpaper: Quickshell.env("CAKEOS_WALLPAPER") ? "file://" + Quickshell.env("CAKEOS_WALLPAPER") : Qt.resolvedUrl("wallpaper.png")

    readonly property color background: role("background", "#181115")
    readonly property color colOnBackground: role("on_background", "#eddfe4")
    readonly property color surfaceContainerLow: role("surface_container_low", "#201a1d")
    readonly property color surfaceContainer: role("surface_container", "#251e21")
    readonly property color surfaceContainerHigh: role("surface_container_high", "#2f282b")
    readonly property color surfaceContainerHighest: role("surface_container_highest", "#3a3236")
    readonly property color colOnSurface: role("on_surface", "#eddfe4")
    readonly property color colOnSurfaceVariant: role("on_surface_variant", "#d4c2ca")
    readonly property color outline: role("outline", "#9d8d94")
    readonly property color outlineVariant: role("outline_variant", "#51434a")
    readonly property color primary: role("primary", "#fab1da")
    readonly property color colOnPrimary: role("on_primary", "#511d3f")
    readonly property color primaryContainer: role("primary_container", "#6b3456")
    readonly property color colOnPrimaryContainer: role("on_primary_container", "#ffd8ec")
    readonly property color secondaryContainer: role("secondary_container", "#58404d")
    readonly property color colOnSecondaryContainer: role("on_secondary_container", "#fbdaeb")
    readonly property color tertiary: role("tertiary", "#f4ba9d")
    readonly property color tertiaryContainer: role("tertiary_container", "#653d27")
    readonly property color colOnTertiaryContainer: role("on_tertiary_container", "#ffdbca")
    readonly property color error: role("error", "#ffb4ab")
    readonly property color colOnError: role("on_error", "#690005")
    readonly property color errorContainer: role("error_container", "#93000a")
    readonly property color colOnErrorContainer: role("on_error_container", "#ffdad6")

    readonly property color layer0: background
    readonly property color layer1: surfaceContainerLow
    readonly property color layer2: surfaceContainer
    readonly property color layer3: surfaceContainerHigh
    readonly property color colOnLayer1: colOnSurfaceVariant
    readonly property color subtext: outline
    readonly property color layer1Hover: mix(layer1, colOnLayer1, 0.92)
    readonly property color layer1Active: mix(layer1, colOnLayer1, 0.85)
    readonly property color layer2Hover: mix(layer2, colOnSurface, 0.90)
    readonly property color layer2Active: mix(layer2, colOnSurface, 0.80)
    readonly property color primaryHover: mix(primary, layer1Hover, 0.87)
    readonly property color primaryActive: mix(primary, layer1Active, 0.7)
    readonly property color secondaryContainerHover: mix(secondaryContainer, colOnSecondaryContainer, 0.90)

    readonly property QtObject rounding: QtObject {
        readonly property int verysmall: 8
        readonly property int small: 12
        readonly property int normal: 17
        readonly property int large: 23
        readonly property int window: 28
        readonly property int full: 9999
    }

    readonly property QtObject font: QtObject {
        readonly property string main: "Rubik"
        readonly property string icon: "Material Symbols Rounded"
        readonly property string mono: "JetBrainsMono Nerd Font"
        readonly property int smaller: 12
        readonly property int small: 15
        readonly property int normal: 16
        readonly property int larger: 19
        readonly property int huge: 22
        readonly property int title: 30
    }

    // The shell's "expressive effects" curve and duration.
    readonly property list<real> curve: [0.34, 0.80, 0.34, 1.00, 1, 1]
    readonly property int duration: 200
}
