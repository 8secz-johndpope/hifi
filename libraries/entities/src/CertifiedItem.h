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

#ifndef hifi_CertifiedItem_h
#define hifi_CertifiedItem_h

#include "EntityItem.h"

class CertifiedItem : public EntityItem {
public:
    static EntityItemPointer factory(const EntityItemID& entityID, const EntityItemProperties& properties);

    CertifiedItem(const EntityItemID& entityItemID);

    ALLOW_INSTANTIATION // This class can be instantiated

    // methods for getting/setting all properties of an entity
    virtual EntityItemProperties getProperties(EntityPropertyFlags desiredProperties = EntityPropertyFlags()) const override;
    virtual bool setProperties(const EntityItemProperties& properties) override;

    // TODO: eventually only include properties changed since the params.nodeData->getLastTimeBagEmpty() time
    virtual EntityPropertyFlags getEntityProperties(EncodeBitstreamParams& params) const override;

    virtual void appendSubclassData(OctreePacketData* packetData, EncodeBitstreamParams& params,
        EntityTreeElementExtraEncodeDataPointer modelTreeElementExtraEncodeData,
        EntityPropertyFlags& requestedProperties,
        EntityPropertyFlags& propertyFlags,
        EntityPropertyFlags& propertiesDidntFit,
        int& propertyCount,
        OctreeElement::AppendState& appendState) const override;

    virtual int readEntitySubclassDataFromBuffer(const unsigned char* data, int bytesLeftToRead,
        ReadBitstreamToTreeParams& args,
        EntityPropertyFlags& propertyFlags, bool overwriteLocalData,
        bool& somethingChanged) override;

    QUuid getCertificateID() const;
    void setCertificateID(const QUuid& value);

    virtual void debugDump() const override;

private:
    QUuid _certificateID;
};

#endif // hifi_CertifiedItem_h
