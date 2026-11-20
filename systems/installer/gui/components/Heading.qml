import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets.haiiro as H

// A foam heading inside a window: the group a few settings or choices belong
// to. The first one in a window sits closer to the top.
H.HText {
    property bool first: false

    Layout.fillWidth: true
    topPadding: first ? 6 : 18
    bottomPadding: 6
    ink: "foam"
}
