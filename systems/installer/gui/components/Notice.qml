import QtQuick
import QtQuick.Layouts
import qs

// "info", "warning" or "error".
Rectangle {
    id: root

    property string text
    property string kind: "info"
    property string icon: kind === "info" ? "info" : kind === "warning" ? "warning" : "error"

    readonly property color fg: kind === "info" ? Theme.colOnSecondaryContainer : kind === "warning" ? Theme.colOnTertiaryContainer : Theme.colOnErrorContainer

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + 24
    radius: Theme.rounding.normal
    color: kind === "info" ? Theme.secondaryContainer : kind === "warning" ? Theme.tertiaryContainer : Theme.errorContainer

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: 12
        anchors.leftMargin: 16
        spacing: 12
        MaterialSymbol {
            Layout.alignment: Qt.AlignTop
            text: root.icon
            fill: 1
            color: root.fg
        }
        StyledText {
            Layout.fillWidth: true
            text: root.text
            color: root.fg
        }
    }
}
