pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.modules.common.widgets.haiiro as H

Page {
    id: page

    readonly property string filter: search.text
    readonly property var matches: Installer.timezones.filter(z => z.toLowerCase().includes(filter.toLowerCase().replace(/ /g, "_")))

    label: "timedatectl"

    Line {
        ink: "rose"
        text: "Where in the world is this machine, and what does its keyboard say?"
    }

    Columns {
        Half {
            Heading {
                text: "time zone"
            }
            H.SettingRow {
                Layout.fillWidth: true
                name: "time zone"
                H.HText {
                    text: Installer.timeZone
                    ink: "foam"
                }
            }
            H.PromptLine {
                id: search
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.leftMargin: 8
                path: "/usr/share/zoneinfo"
                input: true
                Component.onCompleted: forceInputFocus()
                Keys.forwardTo: [zones]
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 6
                implicitHeight: 7 * 36 + 8
                color: H.HTokens.base

                ListView {
                    id: zones
                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true
                    model: page.matches
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: page.matches.indexOf(Installer.timeZone)
                    highlightMoveDuration: 0
                    Keys.onUpPressed: if (currentIndex > 0)
                        Installer.timeZone = page.matches[currentIndex - 1]
                    Keys.onDownPressed: if (currentIndex < count - 1)
                        Installer.timeZone = page.matches[Math.max(0, currentIndex + 1)]
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    delegate: H.ListRow {
                        required property string modelData
                        width: zones.width
                        text: modelData.replace(/_/g, " ")
                        match: page.filter.replace(/_/g, " ")
                        selected: Installer.timeZone === modelData
                        onClicked: Installer.timeZone = modelData
                    }
                }
                H.HText {
                    anchors.centerIn: parent
                    visible: zones.count === 0
                    text: Installer.timezones.length === 0 ? "Reading the zone list…" : "No zone matches that."
                    ink: "subtle"
                }
            }
        }

        Half {
            Heading {
                text: "keyboard"
            }
            Line {
                role: "caption"
                ink: "subtle"
                text: "Layouts are kept in the order you pick them, and the first one is the default. Order: " + Installer.keyboardLayouts().join(", ")
            }
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 8
                Repeater {
                    model: Installer.layoutChoices
                    H.Chip {
                        required property string modelData
                        interactive: true
                        text: modelData
                        on: Installer.layouts.includes(modelData)
                        onClicked: {
                            const next = Installer.toggled(Installer.layouts, modelData, !on);
                            if (next.length > 0)
                                Installer.layouts = next;
                        }
                    }
                }
            }
            Toggle {
                Layout.topMargin: 10
                visible: Installer.layouts.includes("hu")
                name: "hungarian qwerty"
                description: "Hungarian keyboards are overwhelmingly QWERTY in practice, not the QWERTZ default xkb ships."
                checked: Installer.huQwerty
                onToggled: c => Installer.huQwerty = c
            }
        }
    }
}
