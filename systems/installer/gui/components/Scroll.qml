import QtQuick
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets.haiiro as H

// A ScrollView with the window's thin scrollbar: a foam thumb on a muted track,
// square, no fades.
ScrollView {
    id: root

    contentWidth: availableWidth
    clip: true
    // Qt's software renderer does not clip shapes (the chips' dashed frames),
    // so there the content is drawn through a layer, which does.
    layer.enabled: Appearance.software
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical: ScrollBar {
        parent: root
        x: root.width - width
        height: root.availableHeight
        policy: root.contentHeight > root.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        width: 4
        padding: 0
        minimumSize: 0.08
        background: Rectangle {
            color: H.HTokens.muted
        }
        contentItem: Rectangle {
            implicitWidth: 4
            color: H.HTokens.foam
        }
    }
}
