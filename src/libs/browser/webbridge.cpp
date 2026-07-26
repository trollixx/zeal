// Copyright (C) Oleg Shparber, et al. <https://zealdocs.org>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "webbridge.h"

#include <core/application.h>

#include <QDesktopServices>
#include <QLatin1StringView>
#include <QUrl>

#include <algorithm>
#include <array>

namespace Zeal::Browser {

namespace {
using Qt::Literals::StringLiterals::operator""_L1;

constexpr std::array AllowedShortUrlKeys =
    {"discord"_L1, "github"_L1, "report-bug"_L1, "telegram"_L1, "website"_L1, "x"_L1};
} // namespace

WebBridge::WebBridge(QObject *parent)
    : QObject(parent)
{
}

void WebBridge::openShortUrl(const QString &key)
{
    const auto matchesKey = [&key](QLatin1StringView allowed) {
        return allowed == key;
    };

    if (std::ranges::none_of(AllowedShortUrlKeys, matchesKey)) {
        return;
    }

    QDesktopServices::openUrl(QUrl(QStringLiteral("https://go.zealdocs.org/l/") + key));
}

void WebBridge::triggerAction(const QString &action)
{
    emit actionTriggered(action);
}

QString WebBridge::appVersion()
{
    return Core::Application::versionString();
}

} // namespace Zeal::Browser
