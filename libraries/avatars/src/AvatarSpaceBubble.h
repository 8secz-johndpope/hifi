//
//  AvatarSpaceBubble.h
//  libraries/avatars/src
//
//  Created by Zach Fox on 12/6/2016.
//  Copyright 2016 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#ifndef hifi_AvatarSpaceBubble_h
#define hifi_AvatarSpaceBubble_h

#include <DependencyManager.h>
#include <LimitedNodeList.h>
#include <NLPacket.h>
#include <Node.h>
#include <NodeList.h>
#include <SettingHandle.h>

class AvatarSpaceBubble {
    Q_OBJECT
    SINGLETON_DEPENDENCY

public:
    float getSpaceBubbleScaleFactor() const { return _spaceBubbleEnabled.get() ? _spaceBubbleScaleFactor.get() : 0.0f; }
    bool getSpaceBubbleEnabled() const { return  _spaceBubbleEnabled.get(); }

    void updateNodesSpaceBubbleParameters(float spaceBubbleScaleFactor, bool enabled = true);
    void parseSpaceBubbleIgnoreRequestMessage(QSharedPointer<ReceivedMessage> message);

    void toggleSpaceBubble() { updateNodesSpaceBubbleParameters(getSpaceBubbleScaleFactor(), !getSpaceBubbleEnabled()); }
    void enableSpaceBubble() { updateNodesSpaceBubbleParameters(getSpaceBubbleScaleFactor(), true); }
    void disableSpaceBubble() { updateNodesSpaceBubbleParameters(getSpaceBubbleScaleFactor(), false); }

private:
    void sendSpaceBubbleStateToNode(const SharedNodePointer& destinationNode);
    Setting::Handle<bool> _spaceBubbleEnabled{ "SpaceBubbleEnabled", true };
    Setting::Handle<float> _spaceBubbleScaleFactor{ "SpaceBubbleScaleFactor", 1.5f };

signals:
    void spaceBubbleEnabledChanged(bool isIgnored);
};


#endif
