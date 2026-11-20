import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.modules.common.widgets.haiiro as H

Page {
    label: "lsblk"
    note: "USB drives and disks under 50 GB are left out"

    Line {
        ink: "rose"
        text: "Pick the disk CakeOS will live on."
    }
    Line {
        ink: "love"
        text: "Everything on it is erased."
    }

    Heading {
        text: "disks"
    }
    Line {
        visible: Installer.probing
        ink: "subtle"
        text: "Looking for disks…"
    }
    Line {
        visible: !Installer.probing && Installer.disks.length === 0
        ink: "love"
        text: "No disk fits. CakeOS needs a disk of at least 50 GB that is not a USB drive."
    }
    ChoiceList {
        id: list
        model: Installer.disks.map(d => ({
                    key: d.path,
                    title: d.model,
                    description: d.path,
                    meta: d.size
                }))
        current: Installer.disk
        onChosen: key => Installer.disk = key
        Component.onCompleted: forceActiveFocus()
    }
    Buttons {
        visible: !Installer.probing && Installer.disks.length === 0
        H.InkButton {
            text: "look again"
            ink: "c1"
            onClicked: Installer.refresh()
        }
    }
}
