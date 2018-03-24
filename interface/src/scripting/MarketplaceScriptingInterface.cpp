//
//  WalletScriptingInterface.cpp
//  interface/src/scripting
//
//  Created by Zach Fox on 2018-03-23.
//  Copyright 2018 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#include <QJsonDocument>

#include "MarketplaceScriptingInterface.h"
#include "commerce/CommerceLogging.h"
#include <NetworkingConstants.h>
#include <AddressManager.h>

MarketplaceScriptingInterface::MarketplaceScriptingInterface() {

}


void MarketplaceScriptingInterface::send(const QString& endpoint, const QString& success, const QString& fail, QNetworkAccessManager::Operation method, AccountManagerAuth::Type authType, QJsonObject request) {
    auto accountManager = DependencyManager::get<AccountManager>();
    const QString URL = "/api/v1/marketplace/";
    JSONCallbackParameters callbackParams(this, success, this, fail);
    qCInfo(commerce) << "Sending" << endpoint << QJsonDocument(request).toJson(QJsonDocument::Compact);
    accountManager->sendRequest(URL + endpoint,
        authType,
        method,
        callbackParams,
        QJsonDocument(request).toJson());
}
QJsonObject MarketplaceScriptingInterface::apiResponse(const QString& label, QNetworkReply& reply) {
    QByteArray response = reply.readAll();
    QJsonObject data = QJsonDocument::fromJson(response).object();
    qInfo(commerce) << label << "response" << QJsonDocument(data).toJson(QJsonDocument::Compact);
    return data;
}
// Non-200 responses are not json:
QJsonObject MarketplaceScriptingInterface::failResponse(const QString& label, QNetworkReply& reply) {
    QString response = reply.readAll();
    qWarning(commerce) << "FAILED" << label << response;
    QJsonObject result
    {
        { "status", "fail" },
        { "message", response }
    };
    return result;
}
#define ApiHandler(NAME) void MarketplaceScriptingInterface::NAME##Success(QNetworkReply& reply) { emit NAME##Result(apiResponse(#NAME, reply)); }
#define FailHandler(NAME) void MarketplaceScriptingInterface::NAME##Failure(QNetworkReply& reply) { emit NAME##Result(failResponse(#NAME, reply)); }
#define Handler(NAME) ApiHandler(NAME) FailHandler(NAME)
Handler(items)

void MarketplaceScriptingInterface::items() {
    send("items", "itemsSuccess", "itemsFailure", QNetworkAccessManager::GetOperation, AccountManagerAuth::None, QJsonObject());
}

void MarketplaceScriptingInterface::items(const QString& marketplaceID) {
    send(QString("items/" + marketplaceID), "itemsSuccess", "itemsFailure", QNetworkAccessManager::GetOperation, AccountManagerAuth::None, QJsonObject());
}
