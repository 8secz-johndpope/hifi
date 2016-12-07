//
//  UsersScriptingInterface.cpp
//  libraries/script-engine/src
//
//  Created by Stephen Birarda on 2016-07-11.
//  Copyright 2016 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#include "UsersScriptingInterface.h"

#include <NodeList.h>
#include <AvatarSpaceBubble.h>

UsersScriptingInterface::UsersScriptingInterface() {
    // emit a signal when kick permissions have changed
    auto nodeList = DependencyManager::get<NodeList>();
    connect(nodeList.data(), &LimitedNodeList::canKickChanged, this, &UsersScriptingInterface::canKickChanged);
    connect(nodeList.data(), &AvatarSpaceBubble::spaceBubbleEnabledChanged, this, &UsersScriptingInterface::spaceBubbleEnabledChanged);
}

void UsersScriptingInterface::ignore(const QUuid& nodeID) {
    // ask the NodeList to ignore this user (based on the session ID of their node)
    DependencyManager::get<NodeList>()->ignoreNodeBySessionID(nodeID);
}

void UsersScriptingInterface::kick(const QUuid& nodeID) {
    // ask the NodeList to kick the user with the given session ID
    DependencyManager::get<NodeList>()->kickNodeBySessionID(nodeID);
}

void UsersScriptingInterface::mute(const QUuid& nodeID) {
    // ask the NodeList to mute the user with the given session ID
    DependencyManager::get<NodeList>()->muteNodeBySessionID(nodeID);
}

bool UsersScriptingInterface::getCanKick() {
    // ask the NodeList to return our ability to kick
    return DependencyManager::get<NodeList>()->getThisNodeCanKick();
}

void UsersScriptingInterface::toggleSpaceBubble() {
    DependencyManager::get<AvatarSpaceBubble>()->toggleSpaceBubble();
}

void UsersScriptingInterface::enableSpaceBubble() {
    DependencyManager::get<AvatarSpaceBubble>()->enableSpaceBubble();
}

void UsersScriptingInterface::disableSpaceBubble() {
    DependencyManager::get<AvatarSpaceBubble>()->disableSpaceBubble();
}

void UsersScriptingInterface::setSpaceBubbleScaleFactor(float spaceBubbleScaleFactor, bool enabled) {
    DependencyManager::get<AvatarSpaceBubble>()->ignoreNodesInSpaceBubble(spaceBubbleScaleFactor, enabled);
}

float UsersScriptingInterface::getSpaceBubbleScaleFactor() {
    return DependencyManager::get<AvatarSpaceBubble>()->getSpaceBubbleScaleFactor();
}

bool UsersScriptingInterface::getSpaceBubbleEnabled() {
    return DependencyManager::get<AvatarSpaceBubble>()->getSpaceBubbleEnabled();
}
