import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Page {
    title: "Disk"
    subtitle: "Where CakeOS goes. USB drives and disks under 50 GB are not listed."

    Notice {
        kind: "warning"
        text: "Everything on the selected disk will be erased."
    }

    Section {
        title: "Target disk"
        icon: "hard_drive"

        StyledText {
            visible: Installer.probing
            text: "Looking for disks..."
            color: Theme.subtext
        }
        Notice {
            visible: !Installer.probing && Installer.disks.length === 0
            kind: "error"
            text: "No suitable disk found. CakeOS needs a non-USB disk of at least 50 GB."
        }
        Repeater {
            model: Installer.disks
            ChoiceCard {
                required property var modelData
                icon: "hard_drive"
                title: modelData.model
                description: modelData.path
                trailing: modelData.size
                selected: Installer.disk === modelData.path
                onClicked: Installer.disk = modelData.path
            }
        }
    }
}
