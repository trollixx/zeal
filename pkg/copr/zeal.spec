# RPM spec for Zeal, built on Fedora COPR.
#
# The Version tag is a placeholder overridden by the release automation, which
# passes --define "zeal_version <version>" when building the source RPM (see
# .github/workflows/publish-copr.yaml). A plain build with no override produces
# 0.0.0, matching the AUR PKGBUILD convention. CMake already installs the binary,
# .desktop file, AppStream metainfo, and icons under the prefix on Linux
# (see assets/freedesktop/CMakeLists.txt), so %%cmake_install needs no extra glue.
# toml++ and cpp-httplib are header-only and bundled in src/contrib, so they are
# not BuildRequires.

Name:           zeal
Version:        %{?zeal_version}%{!?zeal_version:0.0.0}
Release:        1%{?dist}
Summary:        Simple offline documentation browser

License:        GPL-3.0-or-later
URL:            https://zealdocs.org
Source0:        https://github.com/zealdocs/zeal/archive/refs/tags/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cmake >= 3.25.1
BuildRequires:  extra-cmake-modules
BuildRequires:  gcc-c++
BuildRequires:  ninja-build

BuildRequires:  qt6-qtbase-devel
BuildRequires:  qt6-qtsvg-devel
BuildRequires:  qt6-qtwebchannel-devel
BuildRequires:  qt6-qtwebengine-devel

BuildRequires:  libarchive-devel
BuildRequires:  sqlite-devel
BuildRequires:  mesa-libGL-devel
BuildRequires:  vulkan-headers
BuildRequires:  libX11-devel
BuildRequires:  libxcb-devel
BuildRequires:  xcb-util-keysyms-devel
BuildRequires:  libxkbcommon-devel

Requires:       hicolor-icon-theme

%description
Zeal is a simple offline documentation browser inspired by Dash. It offers
access to over 200 docsets covering various libraries and APIs.

  * Quickly search documentation using a customisable global hotkey from any
    place in your workspace.
  * Search in multiple sets of documentation at once.
  * Don't be dependent on your internet connection.
  * Integrate Zeal with Emacs, Sublime Text, or Vim.

%prep
%autosetup -n %{name}-%{version}

%build
%cmake -GNinja -DCMAKE_BUILD_TYPE=Release
%cmake_build

%install
%cmake_install

%files
%license COPYING
%doc README.md
%{_bindir}/zeal
%{_datadir}/applications/org.zealdocs.zeal.desktop
%{_datadir}/metainfo/org.zealdocs.zeal.appdata.xml
%{_datadir}/icons/hicolor/*/apps/zeal*

%changelog
* Mon Jun 01 2026 Zeal Release <release@zealdocs.org> - 0.0.0-1
- Placeholder entry; the release automation regenerates this for each upload.
