import QtQuick
import QtQuick.Layouts
import qs

// Material 3 filter chip.
Rectangle {
    id: root

    property string text
    property bool selected: false
    signal clicked

    implicitHeight: 34
    implicitWidth: row.implicitWidth + 24
    radius: Theme.rounding.verysmall
    color: selected ? Theme.secondaryContainer : mouse.containsMouse ? Theme.layer2Hover : "transparent"
    border.width: selected ? 0 : 1
    border.color: Theme.outlineVariant

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        MaterialSymbol {
            visible: root.selected
            text: "check"
            iconSize: 18
            color: Theme.colOnSecondaryContainer
        }
        StyledText {
            text: root.text
            wrapMode: Text.NoWrap
            color: root.selected ? Theme.colOnSecondaryContainer : Theme.colOnSurfaceVariant
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
