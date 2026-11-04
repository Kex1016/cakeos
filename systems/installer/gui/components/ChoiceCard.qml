import QtQuick
import QtQuick.Layouts
import qs

// One option out of several (disks, desktops, kernels).
Rectangle {
    id: root

    property string icon: ""
    property string title
    property string description: ""
    property string trailing: ""
    property bool selected: false
    signal clicked

    Layout.fillWidth: true
    implicitHeight: Math.max(72, row.implicitHeight + 28)
    radius: selected ? Theme.rounding.large : Theme.rounding.small
    color: selected ? Theme.secondaryContainer : mouse.containsMouse ? Theme.layer2Hover : Theme.layer2

    Behavior on radius {
        NumberAnimation {
            duration: Theme.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curve
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: Theme.duration
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 18
        spacing: 14

        Rectangle {
            visible: root.icon !== ""
            implicitWidth: 44
            implicitHeight: 44
            radius: Theme.rounding.full
            color: root.selected ? Theme.primary : Theme.surfaceContainerHighest
            MaterialSymbol {
                anchors.centerIn: parent
                text: root.icon
                fill: root.selected ? 1 : 0
                color: root.selected ? Theme.colOnPrimary : Theme.colOnSurfaceVariant
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            StyledText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Theme.font.normal
                font.weight: Font.Medium
                color: root.selected ? Theme.colOnSecondaryContainer : Theme.colOnSurface
            }
            StyledText {
                Layout.fillWidth: true
                visible: root.description !== ""
                text: root.description
                color: root.selected ? Theme.colOnSecondaryContainer : Theme.subtext
                opacity: root.selected ? 0.8 : 1
                font.pixelSize: Theme.font.smaller + 1
            }
        }
        StyledText {
            visible: root.trailing !== ""
            text: root.trailing
            color: root.selected ? Theme.colOnSecondaryContainer : Theme.colOnSurfaceVariant
            wrapMode: Text.NoWrap
        }
        MaterialSymbol {
            text: root.selected ? "check_circle" : "radio_button_unchecked"
            fill: root.selected ? 1 : 0
            color: root.selected ? Theme.colOnSecondaryContainer : Theme.outline
        }
    }
}
