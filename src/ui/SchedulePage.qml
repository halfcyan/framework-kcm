import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import org.kde.frameworkkcm

KCMUtils.ScrollViewKCM {
    id: root

    property bool scheduleEnabled: false
    property var dayNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    property var dayLabels: [i18n("Monday"), i18n("Tuesday"), i18n("Wednesday"), i18n("Thursday"), i18n("Friday"), i18n("Saturday"), i18n("Sunday")]
    property string scheduleError: ""
    property var reportedErrors: []
    property bool changesSaved: false

    header: ColumnLayout {
        Kirigami.InlineMessage {
            visible: root.scheduleError.length > 0
            type: Kirigami.MessageType.Error
            text: root.scheduleError
            topPadding: Kirigami.Units.largeSpacing
            bottomPadding: Kirigami.Units.largeSpacing
            Layout.fillWidth: true
        }
        Kirigami.InlineMessage {
            visible: root.changesSaved
            type: Kirigami.MessageType.Positive
            text: i18n("Changes saved!")
            topPadding: Kirigami.Units.largeSpacing
            bottomPadding: Kirigami.Units.largeSpacing
            Layout.fillWidth: true
        }
    }

    FrameworkBackend {
        id: backend
    }

    ListModel {
        id: schedules
        ListElement {
            days: "Mon,Tue,Wed,Thu,Fri"; time: "08:00"; limit: 80
        }
    }

    Timer {
        id: saveTimer
        interval: 400
        repeat: false
        onTriggered: root.saveSchedules()
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

    Component.onDestruction: {
        saveTimer.stop()
        if (root.validateSchedules()) {
            root.saveSchedules()
            kcm.save()
        }
    }

    Timer {
        id: errorTimer
        interval: 5000
        repeat: false
        onTriggered: root.scheduleError = ""
    }

    function daysForSchedule(value) {
        return value.split(",")
    }

    function collectSchedules() {
        const result = [];
        const seen = {};
        const errors = [];
        for (let i = 0; i < schedules.count; ++i) {
            const entry = schedules.get(i);
            const days = daysForSchedule(entry.days);
            if (days.length === 0 || (days.length === 1 && days[0] === "")) {
                errors.push(i18n("Schedule %1 must have at least one weekday.", i + 1))
            }
            if (!/^(?:[01]\d|2[0-3]):[0-5]\d$/.test(entry.time)) {
                errors.push(i18n("Schedule %1 must use a valid time in HH:MM format.", i + 1))
            }
            for (let j = 0; j < days.length; ++j) {
                const key = days[j] + "|" + entry.time;
                if (seen[key] === true) {
                    const error = i18n("%1 at %2 is already used by another schedule.", days[j], entry.time);
                    if (errors.indexOf(error) < 0) {
                        errors.push(error)
                    }
                }
                seen[key] = true
            }
            result.push({days: days, time: entry.time, limit: entry.limit})
        }
        return {entries: result, errors: errors}
    }

    function validateSchedules() {
        if (!root.scheduleEnabled) {
            scheduleError = ""
            reportedErrors = []
            return true
        }
        const collected = collectSchedules();
        const active = collected.errors;
        const retained = [];
        const newlyReported = [];
        for (let i = 0; i < active.length; ++i) {
            if (reportedErrors.indexOf(active[i]) >= 0) {
                retained.push(active[i])
            } else {
                newlyReported.push(active[i])
            }
        }
        reportedErrors = retained.concat(newlyReported)
        if (newlyReported.length > 0) {
            scheduleError = newlyReported.join("\n")
            errorTimer.restart()
        } else if (active.length === 0) {
            scheduleError = ""
            reportedErrors = []
        }
        return active.length === 0
    }

    function saveSchedules() {
        const collected = collectSchedules();
        if (collected.errors.length > 0) {
            return
        }
        kcm.setPendingSchedule(root.scheduleEnabled, collected.entries)
    }

    function queueSave() {
        validateSchedules()
        saveTimer.restart()
    }

    function toggleDay(index, day, checked) {
        const entry = schedules.get(index);
        const days = daysForSchedule(entry.days);
        const position = days.indexOf(day);
        if (checked && position < 0) {
            days.push(day)
        } else if (!checked && position >= 0) {
            days.splice(position, 1)
        }
        schedules.setProperty(index, "days", days.join(","))
    }

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
                Layout.preferredHeight: Kirigami.Units.largeSpacing
            }

            Kirigami.Heading {
                text: i18n("Charge schedule")
                level: 1
            }

            Controls.Label {
                text: i18n("Create as many schedule entries as you need. Each entry can use different days, times, and charge limits.")
                color: Kirigami.Theme.disabledTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Controls.CheckBox {
                text: i18n("Apply charge schedules")
                checked: root.scheduleEnabled
                onToggled: {
                    root.scheduleEnabled = checked
                    root.queueSave()
                }
            }

            Repeater {
                model: schedules
                delegate: Controls.Frame
                {
                    id: scheduleCard
                    required property int index
                    required property string days
                    required property string time
                    required property int limit
                    property int scheduleIndex: index
                    Layout.fillWidth: true
                    padding: Kirigami.Units.largeSpacing * 2

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            Layout.fillWidth: true
                            Controls.Label {
                                text: i18n("Schedule %1", index + 1); font.bold: true; Layout.fillWidth: true
                            }
                            Controls.Button {
                                icon.name: "list-remove"
                                display: Controls.AbstractButton.IconOnly
                                enabled: schedules.count > 1
                                Accessible.name: i18n("Remove schedule")
                                onClicked: {
                                    schedules.remove(index)
                                    root.queueSave()
                                }
                            }
                        }

                        Controls.Label {
                            text: i18n("Days"); font.bold: true
                        }
                        Flow {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            Repeater {
                                model: root.dayLabels
                                delegate: Controls.CheckBox
                                {
                                    required property int index
                                    text: root.dayLabels[index]
                                    enabled: root.scheduleEnabled
                                    checked: scheduleCard.days.split(",").indexOf(root.dayNames[index]) >= 0
                                    onToggled: {
                                        root.toggleDay(scheduleCard.scheduleIndex, root.dayNames[index], checked)
                                        root.queueSave()
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Controls.Label {
                                text: i18n("Time"); font.bold: true
                            }
                            Controls.TextField {
                                Layout.fillWidth: true
                                enabled: root.scheduleEnabled
                                text: scheduleCard.time
                                placeholderText: "HH:MM"
                                onEditingFinished: {
                                    schedules.setProperty(scheduleCard.scheduleIndex, "time", text)
                                    root.queueSave()
                                }
                            }
                            Controls.Label {
                                text: i18n("Charge limit"); font.bold: true
                            }
                            Controls.Slider {
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                                enabled: root.scheduleEnabled
                                from: 20;
                                to: 100; stepSize: 5
                                value: scheduleCard.limit
                                onMoved: {
                                    schedules.setProperty(scheduleCard.scheduleIndex, "limit", value)
                                    root.queueSave()
                                }
                            }
                            Controls.Label {
                                text: i18n("%1%", scheduleCard.limit); Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                            }
                        }
                    }
                }
            }

            Controls.Button {
                text: i18n("Add schedule")
                icon.name: "list-add"
                enabled: root.scheduleEnabled
                onClicked: {
                    schedules.append({days: "Mon,Tue,Wed,Thu,Fri", time: "12:00", limit: 80})
                    root.queueSave()
                }
            }
        }
    }
}
