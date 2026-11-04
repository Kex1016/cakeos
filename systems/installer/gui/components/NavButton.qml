import QtQuick
import qs

// A navigation rail entry: icon in a pill when toggled, label beside it.
Item {
    id: root

    property string icon
    property string text
    property bool toggled: false
    property bool done: false
    property bool enabled: true
    signal clicked

    implicitWidth: 200
    implicitHeight: 48
    opacity: enabled ? 1 : 0.38

    Rectangle {
        anchors.fill: parent
        anchors.rightMargin: 12
        radius: Theme.rounding.full
        color: root.toggled ? Theme.secondaryContainer : mouse.pressed ? Theme.layer1Active : mouse.containsMouse ? Theme.layer1Hover : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: Theme.duration
            }
        }
    }

    MaterialSymbol {
        id: icon
        x: 18
        anchors.verticalCenter: parent.verticalCenter
        text: root.done && !root.toggled ? "check_circle" : root.icon
        fill: root.toggled ? 1 : 0
        iconSize: 24
        color: root.toggled ? Theme.colOnSecondaryContainer : root.done ? Theme.primary : Theme.colOnLayer1
    }

    StyledText {
        anchors.left: icon.right
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        font.pixelSize: 14
        font.weight: root.toggled ? Font.Medium : Font.Normal
        color: root.toggled ? Theme.colOnSecondaryContainer : Theme.colOnLayer1
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
