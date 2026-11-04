import QtQuick
import QtQuick.Layouts
import qs

// Outlined text field with a floating label, like the shell's MaterialTextField.
Item {
    id: root

    property string label
    property alias text: input.text
    property bool password: false
    property string error: ""
    property string hint: ""
    readonly property bool focused: input.activeFocus

    Layout.fillWidth: true
    implicitHeight: box.height + (message.visible ? message.implicitHeight + 4 : 0)

    Rectangle {
        id: box
        width: parent.width
        height: 56
        radius: Theme.rounding.verysmall
        color: "transparent"
        border.width: root.focused ? 2 : 1
        border.color: root.error !== "" ? Theme.error : root.focused ? Theme.primary : Theme.outline

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: root.password ? 48 : 16
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.colOnSurface
            selectionColor: Theme.secondaryContainer
            selectedTextColor: Theme.colOnSecondaryContainer
            font.family: Theme.font.main
            font.pixelSize: Theme.font.normal
            echoMode: root.password && !reveal.shown ? TextInput.Password : TextInput.Normal
            clip: true
        }

        StyledText {
            readonly property bool floating: root.focused || input.text.length > 0
            x: 12
            y: floating ? -height / 2 : (box.height - height) / 2
            leftPadding: 4
            rightPadding: 4
            text: root.label
            font.pixelSize: floating ? Theme.font.smaller : Theme.font.normal
            color: root.error !== "" ? Theme.error : root.focused ? Theme.primary : Theme.colOnSurfaceVariant
            // Hides the outline behind the floating label.
            Rectangle {
                z: -1
                anchors.fill: parent
                color: Theme.layer0
                visible: parent.floating
            }
            Behavior on y {
                NumberAnimation {
                    duration: Theme.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.curve
                }
            }
        }

        MaterialSymbol {
            id: reveal
            property bool shown: false
            visible: root.password
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: shown ? "visibility_off" : "visibility"
            color: Theme.colOnSurfaceVariant
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: reveal.shown = !reveal.shown
            }
        }
    }

    StyledText {
        id: message
        anchors.top: box.bottom
        anchors.topMargin: 4
        x: 16
        width: parent.width - 32
        visible: text !== ""
        text: root.error !== "" ? root.error : root.hint
        color: root.error !== "" ? Theme.error : Theme.subtext
        font.pixelSize: Theme.font.smaller
    }
}
