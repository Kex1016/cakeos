import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Page {
    title: "System"
    subtitle: "Swap, kernel and what lives in RAM. Detected " + Installer.ramGb + " GB of memory."

    Section {
        title: "Swap"
        icon: "swap_horiz"

        TextField {
            Layout.topMargin: 8
            label: "Swap size"
            text: Installer.swapSize
            onTextChanged: Installer.swapSize = text.toUpperCase()
            hint: "A number followed by G or M, such as 16G."
            error: Installer.swapValid ? "" : "Use a size like 16G or 512M."
        }
    }

    Section {
        title: "Kernel"
        icon: "memory"

        Repeater {
            model: Installer.kernelChoices
            ChoiceCard {
                required property var modelData
                icon: modelData.icon
                title: modelData.name
                description: modelData.description
                selected: Installer.kernel === modelData.id
                onClicked: Installer.kernel = modelData.id
            }
        }
    }

    Section {
        visible: Installer.ramGb > 16
        title: "Memory-backed directories"
        icon: "speed"

        SwitchRow {
            icon: "folder_zip"
            title: "/tmp and /var/cache on tmpfs"
            description: "Faster, and less wear on the disk."
            checked: Installer.tmpfsTmp
            onToggled: c => Installer.tmpfsTmp = c
        }
        SwitchRow {
            icon: "settings_backup_restore"
            title: "/etc on tmpfs"
            description: "Impermanence: /etc is rebuilt from the configuration at every boot. Needs about 1 GB of RAM."
            checked: Installer.tmpfsEtc
            onToggled: c => Installer.tmpfsEtc = c
        }
    }
}
