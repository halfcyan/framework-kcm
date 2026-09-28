%global _version 0.1.0

Name:           framework-kcm
Version:        %{_version}^%{autogitversion}
Release:        1%{?dist}
Summary:        KDE settings pane for Framework Laptop hardware

License:        GPL-3.0-or-later
URL:            https://github.com/halfcyan/framework-kcm
Source0:        https://github.com/halfcyan/framework-kcm/archive/%{autogitcommit}.tar.gz

BuildSystem:    cmake

BuildRequires:  cmake
BuildRequires:  extra-cmake-modules
BuildRequires:  gcc-c++
BuildRequires:  kf6-kcmutils-devel
BuildRequires:  kf6-kconfig-devel
BuildRequires:  kf6-kcoreaddons-devel
BuildRequires:  kf6-ki18n-devel
BuildRequires:  kf6-kirigami-devel
BuildRequires:  qt6-qtbase-devel
BuildRequires:  qt6-qtdeclarative-devel
BuildRequires:  anda-srpm-macros

Requires:       framework-system

%description
Framework KCM is a KDE System Settings pane for configuring Framework Laptop
hardware. It provides battery and hardware controls through framework_tool.

%files
%license LICENSE
%doc README.md
%{_libdir}/qt6/plugins/plasma/kcms/systemsettings/kcm_framework.so
%{_datadir}/applications/kcm_framework.desktop

%changelog
* Mon Sep 28 2026 Cypress Reed <cypress@fyralabs.com>
- Initial package
