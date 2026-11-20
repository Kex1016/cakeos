import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.modules.common.widgets.haiiro as H

Page {
    id: page

    // every prompt on the page lines up after the longest one
    readonly property int promptWidth: Math.max(hostname.naturalPromptWidth, username.naturalPromptWidth, userPass.naturalPromptWidth, userAgain.naturalPromptWidth, rootPass.naturalPromptWidth, rootAgain.naturalPromptWidth)

    label: "passwd"
    note: "passwords are hashed before they reach the disk"

    Line {
        ink: "rose"
        text: "The machine wants a name, and so do you."
    }

    Columns {
        Half {
            Heading {
                text: "this computer"
            }
            Field {
                id: hostname
                promptWidth: page.promptWidth
                user: "root"
                label: "hostname"
                text: Installer.hostname
                onEdited: t => Installer.hostname = t
                error: Installer.hostnameValid ? "" : "Letters, digits and dashes, starting with a letter or digit."
                Component.onCompleted: focusInput()
            }

            Heading {
                text: "you"
            }
            Field {
                id: username
                promptWidth: page.promptWidth
                user: "root"
                label: "username"
                text: Installer.username
                onEdited: t => Installer.username = t
                error: Installer.usernameValid ? "" : "Lowercase letters, digits, - and _, starting with a letter."
            }
            Field {
                id: userPass
                promptWidth: page.promptWidth
                user: Installer.username
                label: "password"
                password: true
                text: Installer.userPassword
                onEdited: t => Installer.userPassword = t
            }
            Field {
                id: userAgain
                promptWidth: page.promptWidth
                user: Installer.username
                label: "again"
                password: true
                text: Installer.userPasswordConfirm
                onEdited: t => Installer.userPasswordConfirm = t
                error: text.length > 0 && text !== Installer.userPassword ? "That's not the same password." : ""
            }
            Toggle {
                Layout.topMargin: 6
                name: "log in automatically"
                description: "Skip the login screen and start " + Installer.username + "'s session at boot."
                checked: Installer.autoLogin
                onToggled: c => Installer.autoLogin = c
            }
        }
        Half {
            Heading {
                text: "root"
            }
            Field {
                id: rootPass
                promptWidth: page.promptWidth
                user: "root"
                label: "password"
                password: true
                text: Installer.rootPassword
                onEdited: t => Installer.rootPassword = t
            }
            Field {
                id: rootAgain
                promptWidth: page.promptWidth
                user: "root"
                label: "again"
                password: true
                text: Installer.rootPasswordConfirm
                onEdited: t => Installer.rootPasswordConfirm = t
                error: text.length > 0 && text !== Installer.rootPassword ? "That's not the same password." : ""
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: Installer.mainframeDevice !== ""
                spacing: 0

                Heading {
                    text: "data disk"
                }
                Toggle {
                    name: "set up the Mainframe data disk"
                    description: "Found " + Installer.mainframeDevice + ". It is mounted at /large and grafted into your home as ~/Documents, ~/Downloads, ~/Projects and friends."
                    checked: Installer.mainframe
                    onToggled: c => Installer.mainframe = c
                }
                Toggle {
                    enabled: Installer.mainframe
                    name: "also link ~/.ssh to the data disk"
                    description: "Your keys are there on first boot. This turns off the flake's ssh config module, which would otherwise overwrite the config on the disk."
                    checked: Installer.mainframeSsh
                    onToggled: c => Installer.mainframeSsh = c
                }
            }
        }
    }
}
