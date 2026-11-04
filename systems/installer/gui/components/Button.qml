import QtQuick
import QtQuick.Layouts
import qs

// "filled", "tonal", "text" or "danger", as in the shell's dialogs.
Rectangle {
    id: root

    property string text
    property string icon: ""
    property string kind: "filled"
    property bool enabled: true
    signal clicked

    readonly property color base: kind === "filled" ? Theme.primary : kind === "tonal" ? Theme.secondaryContainer : kind === "danger" ? Theme.error : "transparent"
    readonly property color content: kind === "filled" ? Theme.colOnPrimary : kind === "tonal" ? Theme.colOnSecondaryContainer : kind === "danger" ? Theme.colOnError : Theme.primary

    implicitHeight: 40
    implicitWidth: row.implicitWidth + 40
    radius: Theme.rounding.full
    opacity: enabled ? 1 : 0.4
    color: {
        if (!enabled)
            return base;
        if (kind === "text")
            return mouse.pressed ? Theme.alpha(Theme.primary, 0.16) : mouse.containsMouse ? Theme.alpha(Theme.primary, 0.08) : base;
        return mouse.pressed ? Theme.mix(base, content, 0.8) : mouse.containsMouse ? Theme.mix(base, content, 0.9) : base;
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curve
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        MaterialSymbol {
            visible: root.icon !== ""
            text: root.icon
            iconSize: 20
            color: root.content
        }
        StyledText {
            text: root.text
            color: root.content
            font.weight: Font.Medium
            wrapMode: Text.NoWrap
        }
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
