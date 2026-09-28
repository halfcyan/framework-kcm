#include "frameworkbackend.hpp"

#include <cassert>
#include <QCoreApplication>

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    const auto status = parsePowerStatus(QStringLiteral("AC is:            connected\nBattery SoC:      67%\nBattery charging"));
    assert(status.has_value());
    assert(status->chargePercent == 67);
    assert(status->acConnected);
    assert(status->state == QStringLiteral("charging"));
    assert(parseChargeLimit(QStringLiteral("Minimum 0%, Maximum 80%")).value() == 80);
    assert(!parsePowerStatus(QStringLiteral("not a power response")).has_value());

    qputenv("FRAMEWORK_KCM_FIXTURE", "1");
    FrameworkBackend backend;
    assert(backend.fixtureMode());
    assert(backend.chargePercent() == 67);
    assert(backend.acConnected());
    backend.setChargeLimit(60);
    assert(backend.chargeLimit() == 60);
    assert(backend.lastError().isEmpty());

    const auto checkProfile = [](const char *name, bool keyboard, bool fingerprint, bool tablet, bool touchscreen) {
        qputenv("FRAMEWORK_KCM_FIXTURE_MODEL", name);
        FrameworkBackend profile;
        assert(profile.supportsKeyboardBacklight() == keyboard);
        assert(profile.supportsFingerprintBrightness() == fingerprint);
        assert(profile.supportsTabletMode() == tablet);
        assert(profile.supportsTouchscreen() == touchscreen);
    };
    checkProfile("framework-12", false, false, true, true);
    checkProfile("framework-12-gen2", true, false, true, true);
    checkProfile("framework-13", true, true, false, false);
    checkProfile("framework-13-pro", true, true, false, true);
}
