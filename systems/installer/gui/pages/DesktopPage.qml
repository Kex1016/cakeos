import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Page {
    title: "Desktop"
    subtitle: "This decides the session, the default apps, and which extras each package group installs."

    Section {
        title: "Desktop environment"
        icon: "desktop_windows"

        StyledText {
            visible: Installer.probing
            text: "Reading the desktops this flake offers..."
            color: Theme.subtext
        }
        Repeater {
            model: Installer.desktops
            ChoiceCard {
                required property var modelData
                icon: modelData.name === "hecate" ? "auto_awesome" : modelData.name === "gnome" ? "footprint" : modelData.name === "plasma" ? "blur_on" : "desktop_windows"
                title: ({ gnome: "GNOME", plasma: "Plasma", hecate: "hecate" })[modelData.name] ?? modelData.name
                description: modelData.description.replace(/^[^-]+ - /, "")
                selected: Installer.desktop === modelData.name
                onClicked: Installer.desktop = modelData.name
            }
        }
    }
}
