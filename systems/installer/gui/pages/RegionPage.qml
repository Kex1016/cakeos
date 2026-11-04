import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components

Page {
    id: page

    property string filter: ""
    readonly property var matches: Installer.timezones.filter(z => z.toLowerCase().includes(filter.toLowerCase().replace(/ /g, "_")))

    title: "Region"
    subtitle: "Time zone and keyboard layouts."

    Section {
        title: "Time zone"
        icon: "schedule"

        StyledText {
            text: Installer.timeZone
            font.pixelSize: Theme.font.huge
            color: Theme.primary
        }
        TextField {
            Layout.topMargin: 8
            label: "Search time zones"
            onTextChanged: page.filter = text
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 6
            implicitHeight: 240
            radius: Theme.rounding.small
            color: Theme.layer2

            ListView {
                id: zones
                anchors.fill: parent
                anchors.margins: 6
                clip: true
                model: page.matches
                ScrollBar.vertical: ScrollBar {}
                delegate: Rectangle {
                    required property string modelData
                    width: zones.width
                    height: 36
                    radius: Theme.rounding.verysmall
                    color: Installer.timeZone === modelData ? Theme.secondaryContainer : zoneMouse.containsMouse ? Theme.layer2Hover : "transparent"
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 12
                        text: parent.modelData.replace(/_/g, " ")
                        color: Installer.timeZone === parent.modelData ? Theme.colOnSecondaryContainer : Theme.colOnSurface
                    }
                    MouseArea {
                        id: zoneMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Installer.timeZone = parent.modelData
                    }
                }
            }
        }
    }

    Section {
        title: "Keyboard layouts"
        icon: "keyboard"

        Flow {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 8
            Repeater {
                model: Installer.layoutChoices
                Chip {
                    required property string modelData
                    text: modelData
                    selected: Installer.layouts.includes(modelData)
                    onClicked: {
                        const next = Installer.toggled(Installer.layouts, modelData, !selected);
                        if (next.length > 0)
                            Installer.layouts = next;
                    }
                }
            }
        }
        SwitchRow {
            Layout.topMargin: 8
            visible: Installer.layouts.includes("hu")
            icon: "keyboard_alt"
            title: "Hungarian QWERTY"
            description: "Hungarian keyboards are overwhelmingly QWERTY in practice, not the QWERTZ default xkb ships."
            checked: Installer.huQwerty
            onToggled: c => Installer.huQwerty = c
        }
    }
}
