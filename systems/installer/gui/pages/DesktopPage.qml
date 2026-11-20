import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.modules.common.widgets.haiiro as H

Page {
    label: "ls desktops/"
    note: "switch later with cakeos-wm"

    Line {
        ink: "rose"
        text: "Each desktop brings its own session, apps and extras. Pick the one you will live in."
    }

    Heading {
        text: "desktops"
    }
    Line {
        visible: Installer.probing
        ink: "subtle"
        text: "Reading the desktops this flake offers…"
    }
    ChoiceList {
        model: Installer.desktops.map(d => ({
                    key: d.name,
                    title: d.name,
                    description: d.description.replace(/^[^-]+ - /, ""),
                    meta: d.name === "hecate" ? "haiiro" : ""
                }))
        current: Installer.desktop
        onChosen: key => Installer.desktop = key
    }
}
