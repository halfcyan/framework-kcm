#pragma once

#include <QObject>

#include <optional>

struct PowerStatus {
    int chargePercent = -1;
    bool acConnected = false;
    QString state;
};

std::optional<PowerStatus> parsePowerStatus(const QString &output);
std::optional<int> parseChargeLimit(const QString &output);

class FrameworkBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(int chargePercent READ chargePercent NOTIFY statusChanged)
    Q_PROPERTY(bool acConnected READ acConnected NOTIFY statusChanged)
    Q_PROPERTY(QString batteryState READ batteryState NOTIFY statusChanged)
    Q_PROPERTY(int chargeLimit READ chargeLimit NOTIFY statusChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY errorChanged)
    Q_PROPERTY(bool fixtureMode READ fixtureMode CONSTANT)
    Q_PROPERTY(QString fixtureModel READ fixtureModel CONSTANT)
    Q_PROPERTY(bool supportsKeyboardBacklight READ supportsKeyboardBacklight CONSTANT)
    Q_PROPERTY(bool supportsFingerprintBrightness READ supportsFingerprintBrightness CONSTANT)
    Q_PROPERTY(bool supportsInputDeck READ supportsInputDeck CONSTANT)
    Q_PROPERTY(bool supportsTabletMode READ supportsTabletMode CONSTANT)
    Q_PROPERTY(bool supportsTouchscreen READ supportsTouchscreen CONSTANT)

public:
    explicit FrameworkBackend(QObject *parent = nullptr);

    [[nodiscard]] int chargePercent() const { return m_status.chargePercent; }
    [[nodiscard]] bool acConnected() const { return m_status.acConnected; }
    [[nodiscard]] QString batteryState() const { return m_status.state; }
    [[nodiscard]] int chargeLimit() const { return m_chargeLimit; }
    [[nodiscard]] QString lastError() const { return m_lastError; }
    [[nodiscard]] bool fixtureMode() const { return m_fixtureMode; }
    [[nodiscard]] QString fixtureModel() const { return m_fixtureModel; }
    [[nodiscard]] bool supportsKeyboardBacklight() const { return m_supportsKeyboardBacklight; }
    [[nodiscard]] bool supportsFingerprintBrightness() const { return m_supportsFingerprintBrightness; }
    [[nodiscard]] bool supportsInputDeck() const { return m_supportsInputDeck; }
    [[nodiscard]] bool supportsTabletMode() const { return m_supportsTabletMode; }
    [[nodiscard]] bool supportsTouchscreen() const { return m_supportsTouchscreen; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void setChargeLimit(int limit);
    Q_INVOKABLE void setFullCharge();
    Q_INVOKABLE void setKeyboardBacklight(int percent);
    Q_INVOKABLE void setFingerprintBrightness(int percent);
    Q_INVOKABLE void setInputDeckMode(const QString &mode);
    Q_INVOKABLE void setTabletMode(const QString &mode);
    Q_INVOKABLE void setTouchscreenEnabled(bool enabled);
    Q_INVOKABLE void configureSchedule(bool enabled, const QVariantList &schedules);

Q_SIGNALS:
    void statusChanged();
    void errorChanged();

private:
    void run(const QStringList &arguments, bool refreshAfter = false);
    static QString findTool();
    void setError(const QString &error);
    void probeCapabilities();

    PowerStatus m_status;
    int m_chargeLimit = -1;
    QString m_lastError;
    bool m_fixtureMode = false;
    QString m_fixtureModel;
    bool m_supportsKeyboardBacklight = false;
    bool m_supportsFingerprintBrightness = false;
    bool m_supportsInputDeck = false;
    bool m_supportsTabletMode = false;
    bool m_supportsTouchscreen = false;
};
