import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import org.kde.frameworkkcm

KCMUtils.ScrollViewKCM {
    id: root

    property int selectedLimit: backend.chargeLimit > 0 ? backend.chargeLimit : 80
    property int keyboardBrightness: 50
    property int fingerprintBrightness: 50
    property bool changesSaved: false

    header: Kirigami.InlineMessage {
        visible: root.changesSaved
        type: Kirigami.MessageType.Positive
        text: i18n("Changes saved!")
        topPadding: Kirigami.Units.largeSpacing
        bottomPadding: Kirigami.Units.largeSpacing
    }

    Timer {
        id: savedTimer
        interval: 3000
        repeat: false
        onTriggered: root.changesSaved = false
    }

    Connections {
        target: kcm
        function onScheduleSaved() {
            root.changesSaved = true
            savedTimer.restart()
        }
    }

    FrameworkBackend { id: backend }

    view: Flickable {
        id: view
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true

        ColumnLayout {
            id: content
            width: view.width - Kirigami.Units.largeSpacing * 2
            x: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            Item {
                Layout.preferredHeight: Kirigami.Units.largeSpacing / 2
            }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            ColumnLayout {
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Heading {
                    text: i18n("Framework Laptop")
                    level: 1
                }
                Controls.Label {
                    text: i18n("Battery and hardware controls")
                    color: Kirigami.Theme.disabledTextColor
                }
            }

            Item { Layout.fillWidth: true }

            Controls.Button {
                text: i18n("Refresh")
                icon.name: "view-refresh"
                onClicked: backend.refresh()
            }
        }

        Controls.Frame {
            Layout.fillWidth: true
            padding: Kirigami.Units.largeSpacing

            RowLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.largeSpacing * 2

                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 9

                    Rectangle {
                        id: batteryBody
                        anchors.centerIn: parent
                        width: Kirigami.Units.gridUnit * 4
                        height: Kirigami.Units.gridUnit * 7
                        radius: Kirigami.Units.smallSpacing
                        color: Kirigami.Theme.backgroundColor
                        border.width: 3
                        border.color: Kirigami.Theme.textColor
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: parent.height * Math.max(0, Math.min(100, backend.chargePercent)) / 100
                            color: backend.chargePercent <= 20 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.highlightColor
                        }

                        Controls.Label {
                            anchors.centerIn: parent
                            text: backend.chargePercent < 0 ? "--" : i18n("%1%", backend.chargePercent)
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: batteryBody.horizontalCenter
                        anchors.bottom: batteryBody.top
                        width: Kirigami.Units.smallSpacing * 2
                        height: Kirigami.Units.smallSpacing
                        color: Kirigami.Theme.textColor
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Controls.Label {
                        text: backend.chargePercent < 0 ? i18n("Battery unavailable") : backend.batteryState.length > 0 ? backend.batteryState.charAt(0).toUpperCase() + backend.batteryState.slice(1) : i18n("Unknown")
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
                    }
                    Controls.Label {
                        text: backend.acConnected ? i18n("AC power connected") : i18n("Running on battery")
                        color: Kirigami.Theme.disabledTextColor
                    }
                    Kirigami.Separator { Layout.fillWidth: true }
                    Controls.Label {
                        text: backend.chargeLimit > 0 ? i18n("Charge limit: %1%", backend.chargeLimit) : i18n("Charge limit unavailable")
                    }
                }
            }
        }

        Kirigami.Heading {
            text: i18n("Battery health")
            level: 2
        }

        Controls.Frame {
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.largeSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing * 2

                    ColumnLayout {
                        Layout.fillWidth: true
                        Controls.Label {
                            text: i18n("Maximum charge")
                            font.bold: true
                        }
                        Controls.Label {
                            text: i18n("Stop charging before full capacity to reduce battery wear.")
                            color: Kirigami.Theme.disabledTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        Controls.Slider {
                            Layout.fillWidth: true
                            from: 20; to: 100; stepSize: 5
                            value: root.selectedLimit
                            onMoved: root.selectedLimit = value
                        }
                        Controls.Label {
                            text: i18n("%1%", root.selectedLimit)
                            color: Kirigami.Theme.highlightColor
                        }
                        Controls.Button {
                            text: i18n("Apply charge limit")
                            onClicked: backend.setChargeLimit(root.selectedLimit)
                        }
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: Kirigami.Theme.disabledTextColor
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Controls.Label {
                            text: i18n("One-time override")
                            font.bold: true
                        }
                        Controls.Label {
                            text: i18n("Temporarily allow the battery to charge to 100%.")
                            color: Kirigami.Theme.disabledTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        Item { Layout.fillHeight: true }
                        Controls.Button {
                            text: i18n("Charge to 100% once")
                            icon.name: "battery-full"
                            onClicked: backend.setFullCharge()
                        }
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Heading {
                        text: i18n("Charge schedule")
                        level: 3
                    }
                    Controls.Label {
                        text: i18n("Automatically apply a charge limit each day.")
                        color: Kirigami.Theme.disabledTextColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    Controls.Button {
                        text: i18n("Configure schedule")
                        icon.name: "configure"
                        onClicked: kcm.push("SchedulePage.qml")
                    }
                }
            }
        }

        Kirigami.Heading {
            text: i18n("Framework controls")
            level: 2
        }

        Controls.Frame {
            Layout.fillWidth: true
            padding: Kirigami.Units.largeSpacing * 2
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.largeSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing * 2

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        visible: backend.supportsKeyboardBacklight || backend.supportsFingerprintBrightness
                        Controls.Label { visible: backend.supportsKeyboardBacklight; text: i18n("Keyboard backlight"); font.bold: true }
                        Controls.Label {
                            visible: backend.supportsKeyboardBacklight
                            text: i18n("Set the brightness of the built-in keyboard lighting.")
                            color: Kirigami.Theme.disabledTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        }
                        Controls.Slider {
                            visible: backend.supportsKeyboardBacklight
                            Layout.fillWidth: true
                            from: 0; to: 100
                            value: root.keyboardBrightness
                            onMoved: {
                                root.keyboardBrightness = value
                                backend.setKeyboardBacklight(value)
                            }
                        }
                        Controls.Label { visible: backend.supportsKeyboardBacklight; text: i18n("%1%", root.keyboardBrightness); color: Kirigami.Theme.disabledTextColor }
                        Kirigami.Separator { visible: backend.supportsKeyboardBacklight && backend.supportsFingerprintBrightness; Layout.fillWidth: true }
                        Item {
                            visible: backend.supportsKeyboardBacklight && backend.supportsFingerprintBrightness
                            Layout.preferredHeight: Kirigami.Units.smallSpacing * 2
                        }
                        Controls.Label { visible: backend.supportsFingerprintBrightness; text: i18n("Fingerprint LED"); font.bold: true }
                        Controls.Label {
                            visible: backend.supportsFingerprintBrightness
                            text: i18n("Adjust the brightness of the fingerprint reader indicator.")
                            color: Kirigami.Theme.disabledTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        Controls.Slider {
                            visible: backend.supportsFingerprintBrightness
                            Layout.fillWidth: true
                            from: 0; to: 100
                            value: root.fingerprintBrightness
                            onMoved: {
                                root.fingerprintBrightness = value
                                backend.setFingerprintBrightness(value)
                            }
                        }
                        Controls.Label { visible: backend.supportsFingerprintBrightness; text: i18n("%1%", root.fingerprintBrightness); color: Kirigami.Theme.disabledTextColor }
                    }

                    Rectangle {
                        visible: (backend.supportsKeyboardBacklight || backend.supportsFingerprintBrightness) &&
                            (backend.supportsInputDeck || backend.supportsTabletMode)
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: Kirigami.Theme.disabledTextColor
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        visible: backend.supportsInputDeck || backend.supportsTabletMode
                        Controls.Label { visible: backend.supportsInputDeck; text: i18n("Input deck"); font.bold: true }
                        Controls.Label {
                            visible: backend.supportsInputDeck
                            text: i18n("Auto detects the keyboard and touchpad. Always on or off overrides detection.")
                            color: Kirigami.Theme.disabledTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        }
                        Controls.ComboBox {
                            Layout.fillWidth: true
                            visible: backend.supportsInputDeck
                            model: [i18n("Auto"), i18n("Always on"), i18n("Always off")]
                            onActivated: backend.setInputDeckMode(["auto", "on", "off"][currentIndex])
                        }
                        Item {
                            visible: backend.supportsInputDeck && backend.supportsTabletMode
                            Layout.preferredHeight: Kirigami.Units.smallSpacing * 2
                        }
                        Kirigami.Separator { visible: backend.supportsInputDeck && backend.supportsTabletMode; Layout.fillWidth: true }
                        Item {
                            visible: backend.supportsInputDeck && backend.supportsTabletMode
                            Layout.preferredHeight: Kirigami.Units.smallSpacing * 2
                        }
                        Controls.Label { visible: backend.supportsTabletMode; text: i18n("Tablet mode"); font.bold: true }
                        Controls.Label {
                            visible: backend.supportsTabletMode
                            text: i18n("Follow sensors automatically, or force tablet or laptop behavior.")
                            color: Kirigami.Theme.disabledTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        }
                        Controls.ComboBox {
                            visible: backend.supportsTabletMode
                            Layout.fillWidth: true
                            model: [i18n("Follow sensors"), i18n("Tablet"), i18n("Laptop")]
                            onActivated: backend.setTabletMode(["auto", "tablet", "laptop"][currentIndex])
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing

                    Controls.CheckBox {
                        visible: backend.supportsTouchscreen
                        text: i18n("Touchscreen enabled")
                        checked: true
                        onToggled: backend.setTouchscreenEnabled(checked)
                    }
                    Controls.Label {
                        visible: backend.supportsTouchscreen
                        text: i18n("Enable or disable the Framework touchscreen.")
                        color: Kirigami.Theme.disabledTextColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: Kirigami.Units.largeSpacing
        }
    }
}
}
