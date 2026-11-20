pragma Singleton
import Quickshell

// What the haiiro kit (modules/common/widgets/haiiro, copied from the hecate
// input at build time) reads its tokens from. The installer has none of the
// shell's Appearance: everything but `transition.cut` falls back to the kit's
// tokens.json values. CAKEOS_REDUCED_MOTION=1, or the software renderer the
// launcher falls back to without GL (where the pixelate effect would cost the
// CPU every frame), turns every transition into a cut.
Singleton {
    readonly property bool software: Quickshell.env("QT_QUICK_BACKEND") === "software"
    readonly property bool reducedMotion: Quickshell.env("CAKEOS_REDUCED_MOTION") === "1"
    readonly property var haiiro: ({
            transition: {
                cut: reducedMotion || software
            }
        })
}
