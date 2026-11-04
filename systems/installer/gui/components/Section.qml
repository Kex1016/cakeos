import QtQuick
import QtQuick.Layouts
import qs

// A titled group of rows, headed like the shell's ContentSection.
ColumnLayout {
    id: root

    property string title
    property string icon: ""
    default property alias content: body.data

    Layout.fillWidth: true
    spacing: 10

    RowLayout {
        spacing: 10
        Rectangle {
            visible: root.icon !== ""
            implicitWidth: 34
            implicitHeight: 34
            radius: Theme.rounding.full
            color: Theme.secondaryContainer
            MaterialSymbol {
                anchors.centerIn: parent
                text: root.icon
                iconSize: 20
                color: Theme.colOnSecondaryContainer
            }
        }
        StyledText {
            text: root.title
            font.pixelSize: Theme.font.larger
            font.weight: Font.Medium
            color: Theme.colOnSecondaryContainer
        }
    }

    ColumnLayout {
        id: body
        Layout.fillWidth: true
        spacing: 4
    }
}
