#include "frameworkkcm.hpp"
#include "frameworkbackend.hpp"

#include <QQmlEngine>

#include <KPluginFactory>

K_PLUGIN_CLASS_WITH_JSON(FrameworkKCM, "kcm_framework.json")

FrameworkKCM::FrameworkKCM(QObject *parent, const KPluginMetaData &data)
    : KQuickManagedConfigModule(parent, data)
{
    m_backend = new FrameworkBackend(this);
    qmlRegisterType<FrameworkBackend>("org.kde.frameworkkcm", 1, 0, "FrameworkBackend");
    setButtons(Help | Apply | Default);
}

void FrameworkKCM::setPendingSchedule(bool enabled, const QVariantList &schedules)
{
    m_pendingScheduleEnabled = enabled;
    m_pendingSchedules = schedules;
    m_hasPendingSchedule = true;
    setNeedsSave(true);
}

void FrameworkKCM::save()
{
    if (m_hasPendingSchedule) {
        m_backend->configureSchedule(m_pendingScheduleEnabled, m_pendingSchedules);
        if (m_backend->lastError().isEmpty()) {
            m_hasPendingSchedule = false;
            setNeedsSave(false);
            Q_EMIT scheduleSaved();
        }
    }
    KQuickManagedConfigModule::save();
}

#include "frameworkkcm.moc"
