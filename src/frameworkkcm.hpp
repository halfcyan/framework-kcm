#pragma once

#include <KQuickManagedConfigModule>

#include <QVariantList>

class FrameworkBackend;

class FrameworkKCM : public KQuickManagedConfigModule {
    Q_OBJECT

public:
    FrameworkKCM(QObject *parent, const KPluginMetaData &data);

    Q_INVOKABLE void setPendingSchedule(bool enabled, const QVariantList &schedules);
    void save() override;

Q_SIGNALS:
    void scheduleSaved();

private:
    FrameworkBackend *m_backend = nullptr;
    bool m_pendingScheduleEnabled = false;
    QVariantList m_pendingSchedules;
    bool m_hasPendingSchedule = false;
};
