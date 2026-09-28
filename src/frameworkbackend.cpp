#include "frameworkbackend.hpp"

#include <QProcess>
#include <QDir>
#include <QFile>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QSet>

#include <algorithm>

std::optional<PowerStatus> parsePowerStatus(const QString &output)
{
    const auto charge = QRegularExpression(QStringLiteral("(?:Battery SoC|Charge level):\\s*(\\d+)%"))
                            .match(output);
    if (!charge.hasMatch()) {
        return std::nullopt;
    }

    PowerStatus status;
    status.chargePercent = charge.captured(1).toInt();
    status.acConnected = output.contains(QStringLiteral("AC is:            connected"));
    const auto state = QRegularExpression(QStringLiteral("Battery (charging|discharging|not charging)"))
                           .match(output);
    status.state = state.hasMatch() ? state.captured(1) : QStringLiteral("unknown");
    return status;
}

std::optional<int> parseChargeLimit(const QString &output)
{
    const auto match = QRegularExpression(QStringLiteral("Maximum\\s+(\\d+)%")).match(output);
    if (!match.hasMatch()) {
        return std::nullopt;
    }
    return match.captured(1).toInt();
}

FrameworkBackend::FrameworkBackend(QObject *parent)
    : QObject(parent)
{
    m_fixtureMode = qEnvironmentVariableIntValue("FRAMEWORK_KCM_FIXTURE") != 0;
    m_fixtureModel = qEnvironmentVariable("FRAMEWORK_KCM_FIXTURE_MODEL").toLower();
    probeCapabilities();
    refresh();
}

void FrameworkBackend::probeCapabilities()
{
    if (m_fixtureMode) {
        // Profiles model the hardware differences relevant to this KCM.
        if (m_fixtureModel == QStringLiteral("framework-12") || m_fixtureModel == QStringLiteral("12")) {
            m_supportsKeyboardBacklight = false;
            m_supportsFingerprintBrightness = false;
            m_supportsInputDeck = true;
            m_supportsTabletMode = true;
            m_supportsTouchscreen = true;
        } else if (m_fixtureModel == QStringLiteral("framework-12-gen2") || m_fixtureModel == QStringLiteral("framework-12-2nd-gen") ||
                   m_fixtureModel == QStringLiteral("12-gen2")) {
            m_supportsKeyboardBacklight = true;
            m_supportsFingerprintBrightness = false;
            m_supportsInputDeck = true;
            m_supportsTabletMode = true;
            m_supportsTouchscreen = true;
        } else if (m_fixtureModel == QStringLiteral("framework-13") || m_fixtureModel == QStringLiteral("13")) {
            m_supportsKeyboardBacklight = true;
            m_supportsFingerprintBrightness = true;
            m_supportsInputDeck = true;
            m_supportsTabletMode = false;
            m_supportsTouchscreen = false;
        } else if (m_fixtureModel == QStringLiteral("framework-13-pro") || m_fixtureModel == QStringLiteral("13-pro")) {
            m_supportsKeyboardBacklight = true;
            m_supportsFingerprintBrightness = true;
            m_supportsInputDeck = true;
            m_supportsTabletMode = false;
            m_supportsTouchscreen = true;
        } else {
            m_supportsKeyboardBacklight = true;
            m_supportsFingerprintBrightness = true;
            m_supportsInputDeck = true;
            m_supportsTabletMode = true;
            m_supportsTouchscreen = true;
        }
        return;
    }

    const auto tool = findTool();
    if (tool.isEmpty()) {
        return;
    }

    QProcess features;
    features.start(tool, {QStringLiteral("--features")});
    if (!features.waitForFinished(5000) || features.exitCode() != 0) {
        return;
    }

    const auto output = QString::fromLocal8Bit(features.readAllStandardOutput()).toLower();
    const auto supported = [&output](const QStringList &names) {
        for (const auto &name : names) {
            const qsizetype index = output.indexOf(name);
            if (index >= 0) {
                const auto lineStart = output.lastIndexOf(QLatin1Char('\n'), index) + 1;
                const auto lineEnd = output.indexOf(QLatin1Char('\n'), index);
                const auto line = output.mid(lineStart, lineEnd < 0 ? -1 : lineEnd - lineStart);
                if (!line.contains(QStringLiteral("not supported")) && !line.contains(QStringLiteral("unsupported")) &&
                    !line.contains(QStringLiteral("false"))) {
                    return true;
                }
            }
        }
        return false;
    };

    m_supportsKeyboardBacklight = supported({QStringLiteral("keyboard backlight"), QStringLiteral("kblight")});
    m_supportsFingerprintBrightness = supported({QStringLiteral("fingerprint"), QStringLiteral("fp-brightness")});
    m_supportsInputDeck = supported({QStringLiteral("input deck"), QStringLiteral("inputdeck")});
    m_supportsTabletMode = supported({QStringLiteral("tablet mode"), QStringLiteral("tablet-mode")});
    m_supportsTouchscreen = supported({QStringLiteral("touchscreen")});
}

QString FrameworkBackend::findTool() const
{
    for (const auto &name : {QStringLiteral("framework_tool"), QStringLiteral("framework-tool"), QStringLiteral("framework-system")}) {
        const auto path = QStandardPaths::findExecutable(name);
        if (!path.isEmpty()) {
            return path;
        }
    }
    return {};
}

void FrameworkBackend::setError(const QString &error)
{
    if (m_lastError == error) {
        return;
    }
    m_lastError = error;
    Q_EMIT errorChanged();
}

void FrameworkBackend::run(const QStringList &arguments, bool refreshAfter)
{
    if (m_fixtureMode) {
        if (arguments.value(0) == QStringLiteral("--charge-limit")) {
            m_chargeLimit = arguments.value(1).toInt();
            if (refreshAfter) {
                m_status.chargePercent = std::min(m_status.chargePercent, m_chargeLimit);
            }
        }
        setError({});
        Q_EMIT statusChanged();
        return;
    }

    const auto tool = findTool();
    if (tool.isEmpty()) {
        setError(tr("framework_tool was not found. Install framework-system first."));
        return;
    }

    QProcess process;
    process.start(tool, arguments);
    if (!process.waitForFinished(5000)) {
        process.kill();
        setError(tr("The Framework tool did not finish in time."));
        return;
    }
    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        const auto message = QString::fromLocal8Bit(process.readAllStandardError()).trimmed();
        setError(message.isEmpty() ? tr("The Framework tool could not change this setting. Administrative privileges may be required.") : message);
        return;
    }
    setError({});
    if (refreshAfter) {
        refresh();
    }
}

void FrameworkBackend::refresh()
{
    if (m_fixtureMode) {
        m_status = {67, true, QStringLiteral("charging")};
        if (m_chargeLimit < 0) {
            m_chargeLimit = 80;
        }
        setError({});
        Q_EMIT statusChanged();
        return;
    }

    const auto tool = findTool();
    if (tool.isEmpty()) {
        setError(tr("framework_tool was not found. Install framework-system first."));
        return;
    }

    QProcess power;
    power.start(tool, {QStringLiteral("--power")});
    power.waitForFinished(5000);
    if (const auto status = parsePowerStatus(QString::fromLocal8Bit(power.readAllStandardOutput()))) {
        m_status = *status;
    }

    QProcess limit;
    limit.start(tool, {QStringLiteral("--charge-limit")});
    limit.waitForFinished(5000);
    if (const auto value = parseChargeLimit(QString::fromLocal8Bit(limit.readAllStandardOutput()))) {
        m_chargeLimit = *value;
    }
    Q_EMIT statusChanged();
}

void FrameworkBackend::setChargeLimit(int limit)
{
    run({QStringLiteral("--charge-limit"), QString::number(std::clamp(limit, 20, 100))}, true);
}

void FrameworkBackend::setFullCharge() { run({QStringLiteral("--charge-limit"), QStringLiteral("100")}, true); }
void FrameworkBackend::setKeyboardBacklight(int percent) { run({QStringLiteral("--kblight"), QString::number(std::clamp(percent, 0, 100))}); }
void FrameworkBackend::setFingerprintBrightness(int percent) { run({QStringLiteral("--fp-brightness"), QString::number(std::clamp(percent, 0, 100))}); }
void FrameworkBackend::setInputDeckMode(const QString &mode) { run({QStringLiteral("--inputdeck-mode"), mode}); }
void FrameworkBackend::setTabletMode(const QString &mode) { run({QStringLiteral("--tablet-mode"), mode}); }
void FrameworkBackend::setTouchscreenEnabled(bool enabled) { run({QStringLiteral("--touchscreen-enable"), enabled ? QStringLiteral("true") : QStringLiteral("false")}); }

void FrameworkBackend::configureSchedule(bool enabled, const QVariantList &schedules)
{
    if (m_fixtureMode) {
        Q_UNUSED(enabled)
        Q_UNUSED(schedules)
        setError({});
        return;
    }

    const auto configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + QStringLiteral("/systemd/user");
    QDir().mkpath(configDir);
    if (!enabled) {
        QFile::remove(configDir + QStringLiteral("/framework-charge-limit.service"));
        QFile::remove(configDir + QStringLiteral("/framework-charge-limit.timer"));
        for (int index = 0; index < 100; ++index) {
            QFile::remove(configDir + QStringLiteral("/framework-charge-limit-%1.service").arg(index));
            QFile::remove(configDir + QStringLiteral("/framework-charge-limit-%1.timer").arg(index));
        }
        QProcess::startDetached(QStringLiteral("systemctl"), {QStringLiteral("--user"), QStringLiteral("daemon-reload")});
        QProcess::startDetached(QStringLiteral("systemctl"), {QStringLiteral("--user"), QStringLiteral("disable"), QStringLiteral("--now"), QStringLiteral("framework-charge-limit-*.timer")});
        return;
    }

    const auto tool = findTool();
    const auto timePattern = QRegularExpression(QStringLiteral("^([01]\\d|2[0-3]):[0-5]\\d$"));
    QSet<QString> scheduleKeys;
    if (tool.isEmpty() || schedules.isEmpty()) {
        setError(tr("Add at least one schedule and install framework-system."));
        return;
    }

    for (int index = 0; index < 100; ++index) {
        if (index == 0) {
            QFile::remove(configDir + QStringLiteral("/framework-charge-limit.service"));
            QFile::remove(configDir + QStringLiteral("/framework-charge-limit.timer"));
        }
        QFile::remove(configDir + QStringLiteral("/framework-charge-limit-%1.service").arg(index));
        QFile::remove(configDir + QStringLiteral("/framework-charge-limit-%1.timer").arg(index));
    }
    QProcess::startDetached(QStringLiteral("systemctl"), {QStringLiteral("--user"), QStringLiteral("disable"), QStringLiteral("--now"), QStringLiteral("framework-charge-limit-*.timer")});

    for (qsizetype index = 0; index < schedules.size(); ++index) {
        const auto schedule = schedules.at(index).toMap();
        const auto days = schedule.value(QStringLiteral("days")).toStringList();
        const auto time = schedule.value(QStringLiteral("time")).toString();
        const auto limit = std::clamp(schedule.value(QStringLiteral("limit")).toInt(), 20, 100);
        if (days.isEmpty() || !timePattern.match(time).hasMatch()) {
            setError(tr("Each schedule needs at least one day and a valid time in HH:MM format."));
            return;
        }
        for (const auto &day : days) {
            const auto key = day + QLatin1Char('|') + time;
            if (scheduleKeys.contains(key)) {
                setError(tr("The same weekday and time cannot be scheduled more than once."));
                return;
            }
            scheduleKeys.insert(key);
        }

        const auto servicePath = configDir + QStringLiteral("/framework-charge-limit-%1.service").arg(index);
        const auto timerPath = configDir + QStringLiteral("/framework-charge-limit-%1.timer").arg(index);
        QFile serviceFile(servicePath);
        QFile timerFile(timerPath);
        if (!serviceFile.open(QIODevice::WriteOnly | QIODevice::Truncate) || !timerFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            setError(tr("Could not write the user systemd schedule."));
            return;
        }
        serviceFile.write(QStringLiteral("[Unit]\nDescription=Apply Framework battery charge limit\n\n[Service]\nType=oneshot\nExecStart=%1 --charge-limit %2\n").arg(tool, QString::number(limit)).toUtf8());
        QString timerContents = QStringLiteral("[Unit]\nDescription=Framework battery charge limit schedule\n\n[Timer]\n");
        for (const auto &day : days) {
            timerContents += QStringLiteral("OnCalendar=%1 *-*-* %2:00\n").arg(day, time);
        }
        timerContents += QStringLiteral("Persistent=true\n\n[Install]\nWantedBy=timers.target\n");
        timerFile.write(timerContents.toUtf8());
    }
    QProcess::startDetached(QStringLiteral("systemctl"), {QStringLiteral("--user"), QStringLiteral("daemon-reload")});
    for (qsizetype index = 0; index < schedules.size(); ++index) {
        QProcess::startDetached(QStringLiteral("systemctl"), {QStringLiteral("--user"), QStringLiteral("enable"), QStringLiteral("--now"), QStringLiteral("framework-charge-limit-%1.timer").arg(index)});
    }
    setError({});
}
