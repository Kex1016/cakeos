import QtQuick
import qs

// Material 3 switch, sized like the shell's StyledSwitch.
Rectangle {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 52
    implicitHeight: 32
    radius: Theme.rounding.full
    color: checked ? Theme.primary : Theme.surfaceContainerHighest
    border.width: checked ? 0 : 2
    border.color: Theme.outline

    Behavior on color {
        ColorAnimation {
            duration: Theme.duration
        }
    }

    Rectangle {
        readonly property real size: root.checked || mouse.pressed ? 24 : 16
        width: mouse.pressed ? 28 : size
        height: size
        radius: Theme.rounding.full
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 4 : (mouse.pressed ? 2 : 8)
        color: root.checked ? Theme.colOnPrimary : Theme.outline

        Behavior on x {
            NumberAnimation {
                duration: Theme.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.curve
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: Theme.duration
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
