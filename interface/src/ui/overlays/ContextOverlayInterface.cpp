//
//  ContextOverlayInterface.cpp
//  interface/src/ui/overlays
//
//  Created by Zach Fox on 2017-07-14.
//  Copyright 2017 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#include "ContextOverlayInterface.h"
#include "Application.h"

#include <EntityTreeRenderer.h>
#include <NetworkingConstants.h>
#include <NetworkAccessManager.h>
#include <QtNetwork/QNetworkRequest>
#include <QtNetwork/QNetworkReply>
#include <commerce/Ledger.h>

#include <PointerManager.h>

#ifndef MIN
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#endif

static const float CONTEXT_OVERLAY_TABLET_OFFSET = 30.0f; // Degrees
static const float CONTEXT_OVERLAY_TABLET_ORIENTATION = 210.0f; // Degrees
static const float CONTEXT_OVERLAY_TABLET_DISTANCE = 0.65F; // Meters
ContextOverlayInterface::ContextOverlayInterface() {
    // "context_overlay" debug log category disabled by default.
    // Create your own "qtlogging.ini" file and set your "QT_LOGGING_CONF" environment variable
    // if you'd like to enable/disable certain categories.
    // More details: http://doc.qt.io/qt-5/qloggingcategory.html#configuring-categories
    QLoggingCategory::setFilterRules(QStringLiteral("hifi.context_overlay.debug=false"));

    _entityScriptingInterface = DependencyManager::get<EntityScriptingInterface>();
    _avatarManager = DependencyManager::get<AvatarManager>();
    _hmdScriptingInterface = DependencyManager::get<HMDScriptingInterface>();
    _tabletScriptingInterface = DependencyManager::get<TabletScriptingInterface>();
    _selectionScriptingInterface = DependencyManager::get<SelectionScriptingInterface>();

    _entityPropertyFlags += PROP_POSITION;
    _entityPropertyFlags += PROP_ROTATION;
    _entityPropertyFlags += PROP_MARKETPLACE_ID;
    _entityPropertyFlags += PROP_DIMENSIONS;
    _entityPropertyFlags += PROP_REGISTRATION_POINT;
    _entityPropertyFlags += PROP_CERTIFICATE_ID;
    _entityPropertyFlags += PROP_CLIENT_ONLY;
    _entityPropertyFlags += PROP_OWNING_AVATAR_ID;

    auto entityScriptingInterface = DependencyManager::get<EntityScriptingInterface>().data();
    connect(_entityScriptingInterface.data(), &EntityScriptingInterface::mousePressOnEntity, this, &ContextOverlayInterface::createOrDestroyContextOverlay_entity);
    connect(_entityScriptingInterface.data(), &EntityScriptingInterface::hoverEnterEntity, this, &ContextOverlayInterface::contextOverlays_hoverEnterEntity);
    connect(_entityScriptingInterface.data(), &EntityScriptingInterface::hoverLeaveEntity, this, &ContextOverlayInterface::contextOverlays_hoverLeaveEntity);
    connect(_entityScriptingInterface.data(), &EntityScriptingInterface::deletingEntity, this, &ContextOverlayInterface::deletingEntity);
    connect(_tabletScriptingInterface->getTablet("com.highfidelity.interface.tablet.system"), &TabletProxy::tabletShownChanged, this, [&]() {
        if (_contextOverlayJustClicked && _hmdScriptingInterface->isMounted()) {
            QUuid tabletFrameID = _hmdScriptingInterface->getCurrentTabletFrameID();
            auto myAvatar = DependencyManager::get<AvatarManager>()->getMyAvatar();
            glm::quat cameraOrientation = qApp->getCamera().getOrientation();
            QVariantMap props;
            float sensorToWorldScale = myAvatar->getSensorToWorldScale();
            props.insert("position", vec3toVariant(myAvatar->getEyePosition() + glm::quat(glm::radians(glm::vec3(0.0f, CONTEXT_OVERLAY_TABLET_OFFSET, 0.0f))) * ((CONTEXT_OVERLAY_TABLET_DISTANCE * sensorToWorldScale) * (cameraOrientation * Vectors::FRONT))));
            props.insert("orientation", quatToVariant(cameraOrientation * glm::quat(glm::radians(glm::vec3(0.0f, CONTEXT_OVERLAY_TABLET_ORIENTATION, 0.0f)))));
            qApp->getOverlays().editOverlay(tabletFrameID, props);
            _contextOverlayJustClicked = false;
        }
    });
    connect(&qApp->getOverlays(), &Overlays::mousePressOnOverlay, this, &ContextOverlayInterface::contextOverlays_mousePressOnOverlay);
    connect(&qApp->getOverlays(), &Overlays::hoverEnterOverlay, this, &ContextOverlayInterface::contextOverlays_hoverEnterOverlay);
    connect(&qApp->getOverlays(), &Overlays::hoverLeaveOverlay, this, &ContextOverlayInterface::contextOverlays_hoverLeaveOverlay);

    connect(_avatarManager.data(), &AvatarManager::avatarRemovedEvent, this, &ContextOverlayInterface::avatarRemovedEvent);
    connect(_avatarManager.data(), &AvatarManager::mousePressPointerEvent, this, &ContextOverlayInterface::createOrDestroyContextOverlay_avatar);
    connect(_avatarManager.data(), &AvatarManager::hoverEnterPointerEvent, this, &ContextOverlayInterface::contextOverlays_hoverEnterAvatar);
    connect(_avatarManager.data(), &AvatarManager::hoverLeavePointerEvent, this, &ContextOverlayInterface::contextOverlays_hoverLeaveAvatar);

    {
        _selectionScriptingInterface->enableListHighlight("contextOverlayHighlightList", QVariantMap());
    }

    auto nodeList = DependencyManager::get<NodeList>();
    auto& packetReceiver = nodeList->getPacketReceiver();
    packetReceiver.registerListener(PacketType::ChallengeOwnershipReply, this, "handleChallengeOwnershipReplyPacket");
    _challengeOwnershipTimeoutTimer.setSingleShot(true);
}

static const xColor CONTEXT_OVERLAY_COLOR = { 255, 255, 255 };
static const float CONTEXT_OVERLAY_INSIDE_DISTANCE = 1.0f; // in meters
static const float CONTEXT_OVERLAY_SIZE = 0.09f; // in meters, same x and y dims
static const float CONTEXT_OVERLAY_OFFSET_DISTANCE = 0.1f;
static const float CONTEXT_OVERLAY_OFFSET_ANGLE = 5.0f;
static const float CONTEXT_OVERLAY_UNHOVERED_ALPHA = 0.85f;
static const float CONTEXT_OVERLAY_HOVERED_ALPHA = 1.0f;
static const float CONTEXT_OVERLAY_UNHOVERED_PULSEMIN = 0.6f;
static const float CONTEXT_OVERLAY_UNHOVERED_PULSEMAX = 1.0f;
static const float CONTEXT_OVERLAY_UNHOVERED_PULSEPERIOD = 1.0f;
static const float CONTEXT_OVERLAY_UNHOVERED_COLORPULSE = 1.0f;

void ContextOverlayInterface::setEnabled(bool enabled) {
    _enabled = enabled;
}

bool ContextOverlayInterface::createOrDestroyContextOverlay_entity(const EntityItemID& entityItemID, const PointerEvent& event) {
    // Destroy the existing overlay if one exists
    if ((entityItemID != _currentObjectWithContextOverlay.first && !_currentObjectWithContextOverlay.first.isNull())) {
        destroyContextOverlay(_currentObjectWithContextOverlay.first, (ObjectWithOverlayType)_currentObjectWithContextOverlay.second, event);
    }

    if (_enabled && event.getButton() == PointerEvent::SecondaryButton && contextOverlayFilterPassed(entityItemID)) {
        qCDebug(context_overlay) << "Creating Context Overlay on top of entity with ID: " << entityItemID;

        // Update the cached "Current Entity with Context Overlay" variable
        setCurrentObjectWithContextOverlay(qMakePair(entityItemID, (int)ENTITY));

        enableEntityHighlight(entityItemID);

        // Add all necessary variables to the stack
        EntityItemProperties entityProperties = _entityScriptingInterface->getEntityProperties(entityItemID, _entityPropertyFlags);
        glm::vec3 cameraPosition = qApp->getCamera().getPosition();
        glm::vec3 entityDimensions = entityProperties.getDimensions();
        glm::vec3 entityPosition = entityProperties.getPosition();
        glm::vec3 contextOverlayPosition;
        glm::vec2 contextOverlayDimensions;

        // Update the cached Entity Marketplace ID
        _entityMarketplaceID = entityProperties.getMarketplaceID();

        // Update the position of the overlay if the registration point of the entity
        // isn't default
        if (entityProperties.getRegistrationPoint() != glm::vec3(0.5f)) {
            glm::vec3 adjustPos = entityProperties.getRegistrationPoint() - glm::vec3(0.5f);
            entityPosition = entityPosition - (entityProperties.getRotation() * (adjustPos * entityProperties.getDimensions()));
        }

        AABox boundingBox = AABox(entityPosition - (entityDimensions / 2.0f), entityDimensions * 2.0f);

        // Here, we determine the position and dimensions of the Context Overlay.
        if (boundingBox.contains(cameraPosition)) {
            // If the camera is inside the box...
            // ...position the Context Overlay 1 meter in front of the camera.
            contextOverlayPosition = cameraPosition + CONTEXT_OVERLAY_INSIDE_DISTANCE * (qApp->getCamera().getOrientation() * Vectors::FRONT);
            contextOverlayDimensions = glm::vec2(CONTEXT_OVERLAY_SIZE, CONTEXT_OVERLAY_SIZE) * glm::distance(contextOverlayPosition, cameraPosition);
        } else {
            // Rotate the Context Overlay some number of degrees offset from the entity
            // along the line cast from your head to the entity's bounding box.
            glm::vec3 direction = glm::normalize(entityPosition - cameraPosition);
            float distance;
            BoxFace face;
            glm::vec3 normal;
            boundingBox.findRayIntersection(cameraPosition, direction, distance, face, normal);
            float offsetAngle = -CONTEXT_OVERLAY_OFFSET_ANGLE;
            if (event.getID() == 1) { // "1" is left hand
                offsetAngle *= -1.0f;
            }
            contextOverlayPosition = cameraPosition +
                (glm::quat(glm::radians(glm::vec3(0.0f, offsetAngle, 0.0f)))) * (direction * (distance - CONTEXT_OVERLAY_OFFSET_DISTANCE));
            contextOverlayDimensions = glm::vec2(CONTEXT_OVERLAY_SIZE, CONTEXT_OVERLAY_SIZE) * glm::distance(contextOverlayPosition, cameraPosition);
        }

        // Finally, setup and draw the Context Overlay
        if (_contextOverlayID == UNKNOWN_OVERLAY_ID || !qApp->getOverlays().isAddedOverlay(_contextOverlayID)) {
            _contextOverlay = std::make_shared<Image3DOverlay>();
            _contextOverlay->setAlpha(CONTEXT_OVERLAY_UNHOVERED_ALPHA);
            _contextOverlay->setPulseMin(CONTEXT_OVERLAY_UNHOVERED_PULSEMIN);
            _contextOverlay->setPulseMax(CONTEXT_OVERLAY_UNHOVERED_PULSEMAX);
            _contextOverlay->setColorPulse(CONTEXT_OVERLAY_UNHOVERED_COLORPULSE);
            _contextOverlay->setIgnoreRayIntersection(false);
            _contextOverlay->setDrawInFront(true);
            _contextOverlay->setURL(PathUtils::resourcesUrl() + "images/inspect-icon.png");
            _contextOverlay->setIsFacingAvatar(true);
            _contextOverlayID = qApp->getOverlays().addOverlay(_contextOverlay);
        }
        _contextOverlay->setWorldPosition(contextOverlayPosition);
        _contextOverlay->setDimensions(contextOverlayDimensions);
        _contextOverlay->setWorldOrientation(entityProperties.getRotation());
        _contextOverlay->setVisible(true);

        return true;
    }
    return false;
}

bool ContextOverlayInterface::createOrDestroyContextOverlay_avatar(const QUuid& avatarID, const PointerEvent& event) {
    // Destroy the existing overlay if one exists
    if ((avatarID != _currentObjectWithContextOverlay.first && !_currentObjectWithContextOverlay.first.isNull())) {
        destroyContextOverlay(_currentObjectWithContextOverlay.first, (ObjectWithOverlayType)_currentObjectWithContextOverlay.second, event);
    }

    if (_enabled && event.getButton() == PointerEvent::SecondaryButton) {
        qCDebug(context_overlay) << "Creating Context Overlay on top of avatar with ID: " << avatarID;

        // Update the cached "Current Entity with Context Overlay" variable
        setCurrentObjectWithContextOverlay(qMakePair(avatarID, (int)AVATAR));

        enableAvatarHighlight(avatarID);

        // Add all necessary variables to the stack
        glm::vec3 avatarPosition = _avatarManager->getAvatar(avatarID)->getPosition();
        glm::vec3 avatarGlobalBoundingBoxCorner = _avatarManager->getAvatar(avatarID)->getGlobalBoundingBoxCorner();
        glm::vec3 avatarGlobalBoundingBoxDimensions = 2.0f * (avatarGlobalBoundingBoxCorner - _avatarManager->getAvatar(avatarID)->getGlobalPosition());
        AABox avatarBoundingBox = AABox(avatarGlobalBoundingBoxCorner, avatarGlobalBoundingBoxDimensions);
        glm::vec3 cameraPosition = qApp->getCamera().getPosition();
        glm::vec3 contextOverlayPosition;
        glm::vec2 contextOverlayDimensions;

        // Update the cached Entity Marketplace ID
        _entityMarketplaceID = QString();

        // Rotate the Context Overlay some number of degrees offset from the entity
        // along the line cast from your head to the avatar's bounding box.
        glm::vec3 direction = glm::normalize(avatarPosition - cameraPosition);
        float distance;
        BoxFace face;
        glm::vec3 normal;
        avatarBoundingBox.findRayIntersection(cameraPosition, direction, distance, face, normal);
        float offsetAngle = -CONTEXT_OVERLAY_OFFSET_ANGLE;
        if (event.getID() == 1) { // "1" is left hand
            offsetAngle *= -1.0f;
        }
        contextOverlayPosition = cameraPosition +
            (glm::quat(glm::radians(glm::vec3(0.0f, offsetAngle, 0.0f)))) * (direction * (distance - CONTEXT_OVERLAY_OFFSET_DISTANCE));
        contextOverlayDimensions = glm::vec2(CONTEXT_OVERLAY_SIZE, CONTEXT_OVERLAY_SIZE) * glm::distance(contextOverlayPosition, cameraPosition);

        // Finally, setup and draw the Context Overlay
        if (_contextOverlayID == UNKNOWN_OVERLAY_ID || !qApp->getOverlays().isAddedOverlay(_contextOverlayID)) {
            _contextOverlay = std::make_shared<Image3DOverlay>();
            _contextOverlay->setAlpha(CONTEXT_OVERLAY_UNHOVERED_ALPHA);
            _contextOverlay->setPulseMin(CONTEXT_OVERLAY_UNHOVERED_PULSEMIN);
            _contextOverlay->setPulseMax(CONTEXT_OVERLAY_UNHOVERED_PULSEMAX);
            _contextOverlay->setColorPulse(CONTEXT_OVERLAY_UNHOVERED_COLORPULSE);
            _contextOverlay->setIgnoreRayIntersection(false);
            _contextOverlay->setDrawInFront(true);
            _contextOverlay->setURL(PathUtils::resourcesUrl() + "images/inspect-icon.png");
            _contextOverlay->setIsFacingAvatar(true);
            _contextOverlayID = qApp->getOverlays().addOverlay(_contextOverlay);
        }
        _contextOverlay->setWorldPosition(contextOverlayPosition);
        _contextOverlay->setDimensions(contextOverlayDimensions);
        _contextOverlay->setWorldOrientation(_avatarManager->getAvatar(avatarID)->getOrientation());
        _contextOverlay->setVisible(true);

        return true;
    }
    return false;
}

bool ContextOverlayInterface::contextOverlayFilterPassed(const EntityItemID& entityItemID) {
    EntityItemProperties entityProperties = _entityScriptingInterface->getEntityProperties(entityItemID, _entityPropertyFlags);
    Setting::Handle<bool> _settingSwitch{ "commerce", true };
    if (_settingSwitch.get()) {
        return (entityProperties.getCertificateID().length() != 0);
    } else {
        return (entityProperties.getMarketplaceID().length() != 0);
    }
}

bool ContextOverlayInterface::destroyContextOverlay(const QUuid& objectID, const ObjectWithOverlayType& objectType, const PointerEvent& event) {
    if (_contextOverlayID != UNKNOWN_OVERLAY_ID) {
        if (objectType == ENTITY || objectType == AVATAR) {
            if (objectType == ENTITY) {
                qCDebug(context_overlay) << "Destroying Context Overlay on top of entity with ID: " << objectID;
                disableEntityHighlight(objectID);
            } else if (objectType == AVATAR) {
                qCDebug(context_overlay) << "Destroying Context Overlay on top of avatar with ID: " << objectID;
                disableAvatarHighlight(objectID);
            }
            setCurrentObjectWithContextOverlay(qMakePair(QUuid(), NONE));
            _entityMarketplaceID.clear();
            // Destroy the Context Overlay
            qApp->getOverlays().deleteOverlay(_contextOverlayID);
            _contextOverlay = NULL;
            _contextOverlayID = UNKNOWN_OVERLAY_ID;
            return true;
        } else {
            return false;
        }
    }
    return false;
}

bool ContextOverlayInterface::destroyContextOverlay(const QUuid& objectID, const ObjectWithOverlayType& objectType) {
    return ContextOverlayInterface::destroyContextOverlay(objectID, objectType, PointerEvent());
}

void ContextOverlayInterface::contextOverlays_mousePressOnOverlay(const OverlayID& overlayID, const PointerEvent& event) {
    if (overlayID == _contextOverlayID  && event.getButton() == PointerEvent::PrimaryButton) {
        qCDebug(context_overlay) << "Clicked Context Overlay. Object ID:" << _currentObjectWithContextOverlay.first << "Overlay ID:" << overlayID;
        Setting::Handle<bool> _settingSwitch{ "commerce", true };
        if (_settingSwitch.get()) {
            openInspectionCertificate();
        } else {
            openMarketplace();
        }
        emit contextOverlayClicked(_currentObjectWithContextOverlay.first);
        _contextOverlayJustClicked = true;
    }
}

void ContextOverlayInterface::contextOverlays_hoverEnterOverlay(const OverlayID& overlayID, const PointerEvent& event) {
    if (_contextOverlayID != UNKNOWN_OVERLAY_ID && _contextOverlay) {
        qCDebug(context_overlay) << "Started hovering over Context Overlay. Overlay ID:" << overlayID;
        _contextOverlay->setColor(CONTEXT_OVERLAY_COLOR);
        _contextOverlay->setColorPulse(0.0f); // pulse off
        _contextOverlay->setPulsePeriod(0.0f); // pulse off
        _contextOverlay->setAlpha(CONTEXT_OVERLAY_HOVERED_ALPHA);
    }
}

void ContextOverlayInterface::contextOverlays_hoverLeaveOverlay(const OverlayID& overlayID, const PointerEvent& event) {
    if (_contextOverlayID != UNKNOWN_OVERLAY_ID && _contextOverlay) {
        qCDebug(context_overlay) << "Stopped hovering over Context Overlay. Overlay ID:" << overlayID;
        _contextOverlay->setColor(CONTEXT_OVERLAY_COLOR);
        _contextOverlay->setColorPulse(CONTEXT_OVERLAY_UNHOVERED_COLORPULSE);
        _contextOverlay->setPulsePeriod(CONTEXT_OVERLAY_UNHOVERED_PULSEPERIOD);
        _contextOverlay->setAlpha(CONTEXT_OVERLAY_UNHOVERED_ALPHA);
    }
}

void ContextOverlayInterface::contextOverlays_hoverEnterEntity(const EntityItemID& entityID, const PointerEvent& event) {
    bool isMouse = event.getID() == PointerManager::MOUSE_POINTER_ID || DependencyManager::get<PointerManager>()->isMouse(event.getID());
    if (contextOverlayFilterPassed(entityID) && _enabled && !isMouse) {
        enableEntityHighlight(entityID);
    }
}

void ContextOverlayInterface::contextOverlays_hoverLeaveEntity(const EntityItemID& entityID, const PointerEvent& event) {
    bool isMouse = event.getID() == PointerManager::MOUSE_POINTER_ID || DependencyManager::get<PointerManager>()->isMouse(event.getID());
    if (_currentObjectWithContextOverlay.first != entityID && _enabled && !isMouse) {
        disableEntityHighlight(entityID);
    }
}

void ContextOverlayInterface::contextOverlays_hoverEnterAvatar(const QUuid& avatarID, const PointerEvent& event) {
    bool isMouse = event.getID() == PointerManager::MOUSE_POINTER_ID || DependencyManager::get<PointerManager>()->isMouse(event.getID());
    qDebug() << "ZRF HOVER ENTER AVATAR";
    enableAvatarHighlight(avatarID);
    if (/*contextOverlayFilterPassed(avatarID) && */_enabled && !isMouse) {
        enableAvatarHighlight(avatarID);
    }
}

void ContextOverlayInterface::contextOverlays_hoverLeaveAvatar(const QUuid& avatarID, const PointerEvent& event) {
    bool isMouse = event.getID() == PointerManager::MOUSE_POINTER_ID || DependencyManager::get<PointerManager>()->isMouse(event.getID());
    qDebug() << "ZRF HOVER LEAVE AVATAR";
    disableAvatarHighlight(avatarID);
    if (/*_currentEntityWithContextOverlay != entityID && */_enabled && !isMouse) {
        disableAvatarHighlight(avatarID);
    }
}

void ContextOverlayInterface::requestOwnershipVerification(const QUuid& entityID) {

    setLastInspectedEntity(entityID);

    EntityItemProperties entityProperties = _entityScriptingInterface->getEntityProperties(_lastInspectedEntity, _entityPropertyFlags);

    auto nodeList = DependencyManager::get<NodeList>();

    if (entityProperties.getClientOnly()) {
        if (entityProperties.verifyStaticCertificateProperties()) {
            SharedNodePointer entityServer = nodeList->soloNodeOfType(NodeType::EntityServer);

            if (entityServer) {
                QNetworkAccessManager& networkAccessManager = NetworkAccessManager::getInstance();
                QNetworkRequest networkRequest;
                networkRequest.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);
                networkRequest.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
                QUrl requestURL = NetworkingConstants::METAVERSE_SERVER_URL();
                requestURL.setPath("/api/v1/commerce/proof_of_purchase_status/transfer");
                QJsonObject request;
                request["certificate_id"] = entityProperties.getCertificateID();
                networkRequest.setUrl(requestURL);

                QNetworkReply* networkReply = NULL;
                networkReply = networkAccessManager.put(networkRequest, QJsonDocument(request).toJson());

                connect(networkReply, &QNetworkReply::finished, [=]() {
                    QJsonObject jsonObject = QJsonDocument::fromJson(networkReply->readAll()).object();
                    jsonObject = jsonObject["data"].toObject();

                    if (networkReply->error() == QNetworkReply::NoError) {
                        if (!jsonObject["invalid_reason"].toString().isEmpty()) {
                            qCDebug(entities) << "invalid_reason not empty";
                        } else if (jsonObject["transfer_status"].toArray().first().toString() == "failed") {
                            qCDebug(entities) << "'transfer_status' is 'failed'";
                        } else if (jsonObject["transfer_status"].toArray().first().toString() == "pending") {
                            qCDebug(entities) << "'transfer_status' is 'pending'";
                        } else {
                            QString ownerKey = jsonObject["transfer_recipient_key"].toString();

                            QByteArray certID = entityProperties.getCertificateID().toUtf8();
                            QByteArray text = DependencyManager::get<EntityTreeRenderer>()->getTree()->computeNonce(certID, ownerKey);
                            QByteArray nodeToChallengeByteArray = entityProperties.getOwningAvatarID().toRfc4122();

                            int certIDByteArraySize = certID.length();
                            int textByteArraySize = text.length();
                            int nodeToChallengeByteArraySize = nodeToChallengeByteArray.length();

                            auto challengeOwnershipPacket = NLPacket::create(PacketType::ChallengeOwnershipRequest,
                                certIDByteArraySize + textByteArraySize + nodeToChallengeByteArraySize + 3 * sizeof(int),
                                true);
                            challengeOwnershipPacket->writePrimitive(certIDByteArraySize);
                            challengeOwnershipPacket->writePrimitive(textByteArraySize);
                            challengeOwnershipPacket->writePrimitive(nodeToChallengeByteArraySize);
                            challengeOwnershipPacket->write(certID);
                            challengeOwnershipPacket->write(text);
                            challengeOwnershipPacket->write(nodeToChallengeByteArray);
                            nodeList->sendPacket(std::move(challengeOwnershipPacket), *entityServer);

                            // Kickoff a 10-second timeout timer that marks the cert if we don't get an ownership response in time
                            if (thread() != QThread::currentThread()) {
                                QMetaObject::invokeMethod(this, "startChallengeOwnershipTimer");
                                return;
                            } else {
                                startChallengeOwnershipTimer();
                            }
                        }
                    } else {
                        qCDebug(entities) << "Call to" << networkReply->url() << "failed with error" << networkReply->error() <<
                            "More info:" << networkReply->readAll();
                    }

                    networkReply->deleteLater();
                });
            } else {
                qCWarning(context_overlay) << "Couldn't get Entity Server!";
            }
        } else {
            auto ledger = DependencyManager::get<Ledger>();
            _challengeOwnershipTimeoutTimer.stop();
            emit ledger->updateCertificateStatus(entityProperties.getCertificateID(), (uint)(ledger->CERTIFICATE_STATUS_STATIC_VERIFICATION_FAILED));
            emit DependencyManager::get<WalletScriptingInterface>()->ownershipVerificationFailed(_lastInspectedEntity);
            qCDebug(context_overlay) << "Entity" << _lastInspectedEntity << "failed static certificate verification!";
        }
    }
}

static const QString INSPECTION_CERTIFICATE_QML_PATH = "hifi/commerce/inspectionCertificate/InspectionCertificate.qml";
void ContextOverlayInterface::openInspectionCertificate() {
    // lets open the tablet to the inspection certificate QML
    if (!_currentObjectWithContextOverlay.first.isNull() && _entityMarketplaceID.length() > 0) {
        auto tablet = dynamic_cast<TabletProxy*>(_tabletScriptingInterface->getTablet("com.highfidelity.interface.tablet.system"));
        tablet->loadQMLSource(INSPECTION_CERTIFICATE_QML_PATH);
        _hmdScriptingInterface->openTablet();

        setLastInspectedEntity(_currentObjectWithContextOverlay.first);
        requestOwnershipVerification(_lastInspectedEntity);
    }
}

static const QString MARKETPLACE_BASE_URL = NetworkingConstants::METAVERSE_SERVER_URL().toString() + "/marketplace/items/";

void ContextOverlayInterface::openMarketplace() {
    // lets open the tablet and go to the current item in
    // the marketplace (if the current entity has a
    // marketplaceID)
    if (!_currentObjectWithContextOverlay.first.isNull() && _entityMarketplaceID.length() > 0) {
        auto tablet = dynamic_cast<TabletProxy*>(_tabletScriptingInterface->getTablet("com.highfidelity.interface.tablet.system"));
        // construct the url to the marketplace item
        QString url = MARKETPLACE_BASE_URL + _entityMarketplaceID;
        QString MARKETPLACES_INJECT_SCRIPT_PATH = "file:///" + qApp->applicationDirPath() + "/scripts/system/html/js/marketplacesInject.js";
        tablet->gotoWebScreen(url, MARKETPLACES_INJECT_SCRIPT_PATH);
        _hmdScriptingInterface->openTablet();
        _isInMarketplaceInspectionMode = true;
    }
}

void ContextOverlayInterface::enableEntityHighlight(const EntityItemID& entityItemID) {
    _selectionScriptingInterface->addToSelectedItemsList("contextOverlayHighlightList", "entity", entityItemID);
}

void ContextOverlayInterface::disableEntityHighlight(const EntityItemID& entityItemID) {
    _selectionScriptingInterface->removeFromSelectedItemsList("contextOverlayHighlightList", "entity", entityItemID);
}

void ContextOverlayInterface::enableAvatarHighlight(const QUuid& avatarID) {
    _selectionScriptingInterface->addToSelectedItemsList("contextOverlayHighlightList", "avatar", avatarID);
}

void ContextOverlayInterface::disableAvatarHighlight(const QUuid& avatarID) {
    _selectionScriptingInterface->removeFromSelectedItemsList("contextOverlayHighlightList", "avatar", avatarID);
}

void ContextOverlayInterface::deletingEntity(const EntityItemID& entityID) {
    if (_currentObjectWithContextOverlay.first == entityID) {
        destroyContextOverlay(_currentObjectWithContextOverlay.first, (ObjectWithOverlayType)_currentObjectWithContextOverlay.second, PointerEvent());
    }
}

void ContextOverlayInterface::avatarRemovedEvent(const QUuid& sessionUUID) {
    if (_currentObjectWithContextOverlay.first == sessionUUID) {
        destroyContextOverlay(_currentObjectWithContextOverlay.first, (ObjectWithOverlayType)_currentObjectWithContextOverlay.second, PointerEvent());
    }
}

void ContextOverlayInterface::startChallengeOwnershipTimer() {
    auto ledger = DependencyManager::get<Ledger>();
    EntityItemProperties entityProperties = _entityScriptingInterface->getEntityProperties(_lastInspectedEntity, _entityPropertyFlags);

    connect(&_challengeOwnershipTimeoutTimer, &QTimer::timeout, this, [=]() {
        qCDebug(entities) << "Ownership challenge timed out for" << _lastInspectedEntity;
        emit ledger->updateCertificateStatus(entityProperties.getCertificateID(), (uint)(ledger->CERTIFICATE_STATUS_VERIFICATION_TIMEOUT));
        emit DependencyManager::get<WalletScriptingInterface>()->ownershipVerificationFailed(_lastInspectedEntity);
    });

    _challengeOwnershipTimeoutTimer.start(5000);
}

void ContextOverlayInterface::handleChallengeOwnershipReplyPacket(QSharedPointer<ReceivedMessage> packet, SharedNodePointer sendingNode) {
    auto ledger = DependencyManager::get<Ledger>();

    _challengeOwnershipTimeoutTimer.stop();

    int certIDByteArraySize;
    int textByteArraySize;

    packet->readPrimitive(&certIDByteArraySize);
    packet->readPrimitive(&textByteArraySize);

    QString certID(packet->read(certIDByteArraySize));
    QString text(packet->read(textByteArraySize));

    EntityItemID id;
    bool verificationSuccess = DependencyManager::get<EntityTreeRenderer>()->getTree()->verifyNonce(certID, text, id);

    if (verificationSuccess) {
        emit ledger->updateCertificateStatus(certID, (uint)(ledger->CERTIFICATE_STATUS_VERIFICATION_SUCCESS));
        emit DependencyManager::get<WalletScriptingInterface>()->ownershipVerificationSuccess(_lastInspectedEntity);
    } else {
        emit ledger->updateCertificateStatus(certID, (uint)(ledger->CERTIFICATE_STATUS_OWNER_VERIFICATION_FAILED));
        emit DependencyManager::get<WalletScriptingInterface>()->ownershipVerificationFailed(_lastInspectedEntity);
    }
}
