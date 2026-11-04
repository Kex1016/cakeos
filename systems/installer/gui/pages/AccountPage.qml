import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Page {
    title: "Account"
    subtitle: "The machine's name, your user and the root password."

    Section {
        title: "This computer"
        icon: "computer"

        TextField {
            Layout.topMargin: 8
            label: "Hostname"
            text: Installer.hostname
            onTextChanged: Installer.hostname = text
            error: Installer.hostnameValid ? "" : "Letters, digits and dashes, starting with a letter or digit."
        }
    }

    Section {
        title: "You"
        icon: "person"

        TextField {
            Layout.topMargin: 8
            label: "Username"
            text: Installer.username
            onTextChanged: Installer.username = text
            error: Installer.usernameValid ? "" : "Lowercase letters, digits, - and _, starting with a letter."
        }
        TextField {
            Layout.topMargin: 12
            label: "Password"
            password: true
            text: Installer.userPassword
            onTextChanged: Installer.userPassword = text
        }
        TextField {
            Layout.topMargin: 12
            label: "Confirm password"
            password: true
            text: Installer.userPasswordConfirm
            onTextChanged: Installer.userPasswordConfirm = text
            error: text.length > 0 && text !== Installer.userPassword ? "The passwords do not match." : ""
        }
        SwitchRow {
            Layout.topMargin: 12
            icon: "login"
            title: "Log in automatically"
            description: "Skip the login screen and start " + Installer.username + "'s session at boot."
            checked: Installer.autoLogin
            onToggled: c => Installer.autoLogin = c
        }
    }

    Section {
        title: "Root"
        icon: "admin_panel_settings"

        TextField {
            Layout.topMargin: 8
            label: "Root password"
            password: true
            text: Installer.rootPassword
            onTextChanged: Installer.rootPassword = text
        }
        TextField {
            Layout.topMargin: 12
            label: "Confirm root password"
            password: true
            text: Installer.rootPasswordConfirm
            onTextChanged: Installer.rootPasswordConfirm = text
            error: text.length > 0 && text !== Installer.rootPassword ? "The passwords do not match." : ""
        }
    }

    Section {
        visible: Installer.mainframeDevice !== ""
        title: "Data disk"
        icon: "storage"

        SwitchRow {
            icon: "storage"
            title: "Set up the Mainframe data disk"
            description: "Found " + Installer.mainframeDevice + ". It is mounted at /large and grafted into your home as ~/Documents, ~/Downloads, ~/Projects and friends."
            checked: Installer.mainframe
            onToggled: c => Installer.mainframe = c
        }
        SwitchRow {
            visible: Installer.mainframe
            icon: "key"
            title: "Also link ~/.ssh to the data disk"
            description: "Your keys are there on first boot. This turns off the flake's ssh config module, which would otherwise overwrite the config on the disk."
            checked: Installer.mainframeSsh
            onToggled: c => Installer.mainframeSsh = c
        }
    }
}
