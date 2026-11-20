import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.modules.common.widgets.haiiro as H

Page {
    id: page

    readonly property var kernel: Installer.kernelChoices.find(k => k.id === Installer.kernel) ?? Installer.kernelChoices[0]

    label: "cat system.nix"

    Line {
        ink: "rose"
        text: "The machine has " + Installer.ramGb + " GB of memory. A few things depend on that."
    }

    Columns {
        Half {
            Heading {
                text: "swap"
            }
            H.SettingRow {
                Layout.fillWidth: true
                name: "swap partition"
                description: "Its own partition on the same disk. The default is picked from your memory."
                H.Spin {
                    value: parseInt(Installer.swapSize) || 1
                    from: 1
                    to: 256
                    text: Installer.swapSize
                    onMoved: v => Installer.swapSize = v + "G"
                }
            }

            Heading {
                text: "kernel"
            }
            H.SettingRow {
                Layout.fillWidth: true
                name: "kernel"
                description: page.kernel.description + "."
                H.Segmented {
                    model: Installer.kernelChoices.map(k => k.name)
                    currentIndex: Math.max(0, Installer.kernelChoices.findIndex(k => k.id === Installer.kernel))
                    onActivated: i => Installer.kernel = Installer.kernelChoices[i].id
                }
            }
        }
        Half {
            ColumnLayout {
                Layout.fillWidth: true
                visible: Installer.ramGb > 16
                spacing: 0

                Heading {
                    text: "memory"
                }
                Toggle {
                    name: "/tmp and /var/cache in RAM"
                    description: "Faster, and less wear on the disk."
                    checked: Installer.tmpfsTmp
                    onToggled: c => Installer.tmpfsTmp = c
                }
                Toggle {
                    name: "/etc in RAM"
                    description: "Impermanence: /etc is rebuilt from the configuration at every boot. Needs about 1 GB of RAM."
                    checked: Installer.tmpfsEtc
                    onToggled: c => Installer.tmpfsEtc = c
                }
            }
        }
    }
}
