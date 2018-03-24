
//  MarketplaceScriptingInterface.h
//  interface/src/scripting
//
//  Created by Zach Fox on 2018-03-23.
//  Copyright 2018 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#ifndef hifi_MarketplaceScriptingInterface_h
#define hifi_MarketplaceScriptingInterface_h

#include <QtCore/QObject>
#include <QtNetwork/QNetworkReply>
#include <DependencyManager.h>
#include "AccountManager.h"

class MarketplaceScriptingInterface : public QObject, public Dependency {
    Q_OBJECT

public:
    MarketplaceScriptingInterface();

    Q_INVOKABLE void items();
    Q_INVOKABLE void items(const QString& marketplaceID);

signals:
    void itemsResult(QJsonObject result);

public slots:
    void itemsSuccess(QNetworkReply& reply);
    void itemsFailure(QNetworkReply& reply);

private:
    QJsonObject apiResponse(const QString& label, QNetworkReply& reply);
    QJsonObject failResponse(const QString& label, QNetworkReply& reply);
    void send(const QString& endpoint, const QString& success, const QString& fail, QNetworkAccessManager::Operation method, AccountManagerAuth::Type authType, QJsonObject request);
};

#endif // hifi_WalletScriptingInterface_h
