import QtQuick
import QtQuick.Layouts
import qs

// A settings row: icon, title, description and a switch, on the shell's layer 2.
Rectangle {
    id: root

    property string icon: ""
    property string title
    property string description: ""
    property bool checked: false
    signal toggled(bool checked)

    Layout.fillWidth: true
    implicitHeight: Math.max(64, row.implicitHeight + 24)
    radius: Theme.rounding.small
    color: mouse.containsMouse ? Theme.layer2Hover : Theme.layer2

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 16
        spacing: 16

        MaterialSymbol {
            visible: root.icon !== ""
            text: root.icon
            color: Theme.colOnSurfaceVariant
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            StyledText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Theme.font.normal
            }
            StyledText {
                Layout.fillWidth: true
                visible: root.description !== ""
                text: root.description
                color: Theme.subtext
                font.pixelSize: Theme.font.smaller + 1
            }
        }
        Switch {
            checked: root.checked
            onToggled: c => root.toggled(c)
        }
    }
}
