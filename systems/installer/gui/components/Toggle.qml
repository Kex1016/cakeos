import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets.haiiro as H

// An on/off setting: a SettingRow with a chip that flips on click, space or enter.
H.SettingRow {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    Layout.fillWidth: true

    H.Chip {
        interactive: true
        on: root.checked
        text: root.checked ? "on" : "off"
        onClicked: root.toggled(!root.checked)
    }

    MouseArea {
        parent: root
        anchors.fill: parent
        z: -1
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
