import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets.haiiro as H

// A line of text that wraps: body copy, rose narration (`ink: "rose"`), a love
// warning, a subtle caption.
H.HText {
    Layout.fillWidth: true
    wrapMode: Text.Wrap
    lineHeightMode: Text.FixedHeight
}
