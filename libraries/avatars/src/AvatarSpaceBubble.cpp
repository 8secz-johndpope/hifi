//
//  AvatarSpaceBubble.cpp
//  libraries/avatars/src
//
//  Created by Zach Fox on 12/6/2016.
//  Copyright 2016 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#include "AvatarSpaceBubble.h"

void AvatarSpaceBubble::parseSpaceBubbleIgnoreRequestMessage(QSharedPointer<ReceivedMessage> message) {
    bool enabled;
    float spaceBubbleScaleFactor;
    message->readPrimitive(&enabled);
    message->readPrimitive(&spaceBubbleScaleFactor);
    _spaceBubbleEnabled.set(enabled);
    _spaceBubbleScaleFactor.set(spaceBubbleScaleFactor);
}

void AvatarSpaceBubble::updateNodesSpaceBubbleParameters(float spaceBubbleScaleFactor, bool enabled) {
    bool isEnabledChange = _spaceBubbleEnabled.get() != enabled;
    _spaceBubbleEnabled.set(enabled);
    _spaceBubbleScaleFactor.set(spaceBubbleScaleFactor);

    DependencyManager::get<LimitedNodeList>()->eachMatchingNode([](const SharedNodePointer& node)->bool {
        return (node->getType() == NodeType::AudioMixer || node->getType() == NodeType::AvatarMixer);
    }, [this](const SharedNodePointer& destinationNode) {
        sendSpaceBubbleStateToNode(destinationNode);
    });
    if (isEnabledChange) {
        emit spaceBubbleEnabledChanged(enabled);
    }
}

void AvatarSpaceBubble::sendSpaceBubbleStateToNode(const SharedNodePointer& destinationNode) {
    auto ignorePacket = NLPacket::create(PacketType::SpaceBubbleIgnoreRequest, sizeof(bool) + sizeof(float), true);
    ignorePacket->writePrimitive(_spaceBubbleEnabled.get());
    ignorePacket->writePrimitive(_spaceBubbleScaleFactor.get());
    DependencyManager::get<NodeList>()->sendPacket(std::move(ignorePacket), *destinationNode);
}
