pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.modules.common.widgets.haiiro as H

Page {
    label: "cat groups.nix"
    note: "cakeos.groups, cakeos.hardware"

    Line {
        ink: "rose"
        text: "What is this machine for? Nothing here is forever."
    }
    Gap {}
    Line {
        ink: "subtle"
        text: "Each group also installs extras for " + (Installer.desktop || "your desktop") + ". Change cakeos.groups in gen/cakeos.nix later and rebuild."
    }

    Columns {
        Half {
            Heading {
                text: "package groups"
            }
            Repeater {
                model: Installer.groupChoices
                Toggle {
                    required property var modelData
                    name: modelData.name
                    description: modelData.description
                    checked: Installer.groups.includes(modelData.id)
                    onToggled: c => Installer.groups = Installer.toggled(Installer.groups, modelData.id, c)
                }
            }
        }
        Half {
            Heading {
                text: "hardware"
            }
            Repeater {
                model: Installer.hardwareChoices
                Toggle {
                    required property var modelData
                    name: modelData.name
                    description: modelData.description
                    checked: Installer.hardware.includes(modelData.id)
                    onToggled: c => Installer.hardware = Installer.toggled(Installer.hardware, modelData.id, c)
                }
            }
        }
    }
}
