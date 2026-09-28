# SPDX-License-Identifier: GPL-2.0-or-later

kcmutils_add_qml_kcm(kcm_framework
    SOURCES
        frameworkbackend.cpp
        frameworkkcm.cpp
)

target_link_libraries(kcm_framework
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        KF6::ConfigCore
        KF6::CoreAddons
        KF6::I18n
        KF6::KCMUtilsQuick
)
