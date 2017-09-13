//
//  CertifiedItem.cpp
//  libraries/entities/src
//
//  Created by Zach Fox on 2017-09-13
//  Copyright 2017 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#include "CertifiedItem.h"

#include <QDebug>

#include "EntitiesLogging.h"
#include "EntityItemProperties.h"
#include "EntityTree.h"
#include "EntityTreeElement.h"


EntityItemPointer CertifiedItem::factory(const EntityItemID& entityID, const EntityItemProperties& properties) {
    EntityItemPointer entity{ new CertifiedItem(entityID) };
    entity->setProperties(properties);
    return entity;
}

CertifiedItem::CertifiedItem(const EntityItemID& entityItemID) :
    EntityItem(entityItemID)
{
    _type = EntityTypes::Certified;
}

EntityItemProperties CertifiedItem::getProperties(EntityPropertyFlags desiredProperties) const {

    EntityItemProperties properties = EntityItem::getProperties(desiredProperties); // get the properties from our base 

    COPY_ENTITY_PROPERTY_TO_PROPERTIES(certificateID, getCertificateID);

    return properties;
}

bool CertifiedItem::setProperties(const EntityItemProperties& properties) {
    bool somethingChanged = false;
    somethingChanged = EntityItem::setProperties(properties); // set the properties in our base class

    SET_ENTITY_PROPERTY_FROM_PROPERTIES(certificateID, setCertificateID);

    if (somethingChanged) {
        bool wantDebug = false;
        if (wantDebug) {
            uint64_t now = usecTimestampNow();
            int elapsed = now - getLastEdited();
            qCDebug(entities) << "CertifiedItem::setProperties() AFTER update... edited AGO=" << elapsed <<
                "now=" << now << " getLastEdited()=" << getLastEdited();
        }
        setLastEdited(properties._lastEdited);
    }
    return somethingChanged;
}

int CertifiedItem::readEntitySubclassDataFromBuffer(const unsigned char* data, int bytesLeftToRead,
    ReadBitstreamToTreeParams& args,
    EntityPropertyFlags& propertyFlags, bool overwriteLocalData,
    bool& somethingChanged) {

    int bytesRead = 0;
    const unsigned char* dataAt = data;

    READ_ENTITY_PROPERTY(PROP_CERTIFICATE_ID, QUuid, setCertificateID);

    return bytesRead;
}


// TODO: eventually only include properties changed since the params.nodeData->getLastTimeBagEmpty() time
EntityPropertyFlags CertifiedItem::getEntityProperties(EncodeBitstreamParams& params) const {
    EntityPropertyFlags requestedProperties = EntityItem::getEntityProperties(params);
    requestedProperties += PROP_CERTIFICATE_ID;
    return requestedProperties;
}

void CertifiedItem::appendSubclassData(OctreePacketData* packetData, EncodeBitstreamParams& params,
    EntityTreeElementExtraEncodeDataPointer modelTreeElementExtraEncodeData,
    EntityPropertyFlags& requestedProperties,
    EntityPropertyFlags& propertyFlags,
    EntityPropertyFlags& propertiesDidntFit,
    int& propertyCount,
    OctreeElement::AppendState& appendState) const {

    bool successPropertyFits = true;

    APPEND_ENTITY_PROPERTY(PROP_CERTIFICATE_ID, getCertificateID());
}

void CertifiedItem::debugDump() const {
    quint64 now = usecTimestampNow();
    qCDebug(entities) << "   CERTIFIED EntityItem id:" << getEntityItemID() << "---------------------------------------------";
    qCDebug(entities) << "            certificate ID:" << _certificateID;
    qCDebug(entities) << "             getLastEdited:" << debugTime(getLastEdited(), now);
}


QUuid CertifiedItem::getCertificateID() const {
    return _certificateID;
}

void CertifiedItem::setCertificateID(const QUuid& value) {
    withWriteLock([&] {
        _certificateID = value;
    });
}
