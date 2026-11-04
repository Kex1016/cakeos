import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Page {
    title: "Software"
    subtitle: "What this machine is for. Each group also installs extras for " + (Installer.desktop || "your desktop") + ". Nothing here is permanent: edit cakeos.groups in gen/cakeos.nix later and rebuild."

    Section {
        title: "Package groups"
        icon: "apps"

        Repeater {
            model: Installer.groupChoices
            SwitchRow {
                required property var modelData
                icon: modelData.icon
                title: modelData.name
                description: modelData.description
                checked: Installer.groups.includes(modelData.id)
                onToggled: c => Installer.groups = Installer.toggled(Installer.groups, modelData.id, c)
            }
        }
    }

    Section {
        title: "Hardware support"
        icon: "devices_other"

        Repeater {
            model: Installer.hardwareChoices
            SwitchRow {
                required property var modelData
                icon: modelData.icon
                title: modelData.name
                description: modelData.description
                checked: Installer.hardware.includes(modelData.id)
                onToggled: c => Installer.hardware = Installer.toggled(Installer.hardware, modelData.id, c)
            }
        }
    }
}
