//
//  UsersScriptingInterface.h
//  libraries/script-engine/src
//
//  Created by Stephen Birarda on 2016-07-11.
//  Copyright 2016 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#pragma once

#ifndef hifi_UsersScriptingInterface_h
#define hifi_UsersScriptingInterface_h

#include <DependencyManager.h>

/**jsdoc
* @namespace Users
*/
class UsersScriptingInterface : public QObject, public Dependency {
    Q_OBJECT
    SINGLETON_DEPENDENCY

    Q_PROPERTY(bool canKick READ getCanKick)

public:
    UsersScriptingInterface();

public slots:

    /**jsdoc
    * Ignore another user.
    * @function Users.ignore
    * @param {nodeID} nodeID The node or session ID of the user you want to ignore.
    */
    void ignore(const QUuid& nodeID);

    /**jsdoc
    * Kick another user.
    * @function Users.kick
    * @param {nodeID} nodeID The node or session ID of the user you want to kick.
    */
    void kick(const QUuid& nodeID);

    /**jsdoc
    * Mute another user.
    * @function Users.mute
    * @param {nodeID} nodeID The node or session ID of the user you want to mute.
    */
    void mute(const QUuid& nodeID);

    /**jsdoc
    * Returns `true` if the DomainServer will allow this Node/Avatar to make kick
    * @function Users.getCanKick
    * @return {bool} `true` if the client can kick other users, `false` if not.
    */
    bool getCanKick();

    /**jsdoc
    * Toggle the state of the space bubble feature
    * @function Users.toggleSpaceBubble
    */
    void toggleSpaceBubble();

    /**jsdoc
    * Enables the space bubble feature.
    * @function Users.enableSpaceBubble
    */
    void enableSpaceBubble();

    /**jsdoc
    * Disables the space bubble feature.
    * @function Users.disableSpaceBubble
    */
    void disableSpaceBubble();

    /**jsdoc
    * sets the parameters for the space bubble feature.
    * @function Users.setSpaceBubble
    * @param {number} spaceBubbleScaleFactor The scale factor for the auto-ignore-in-space-bubble feature
    * @param {bool} [enabled=true] Whether the space bubble feature should be enabled
    */
    void setSpaceBubbleScaleFactor(float spaceBubbleScaleFactor, bool enabled = true);

    /**jsdoc
    * Returns the scale factor of the space bubble if it is enabled.
    * @function Users.getSpaceBubbleScaleFactor
    * @return {number} scale factor of the ignore feature
    */
    float getSpaceBubbleScaleFactor();

    /**jsdoc
    * Returns `true` if the ignore in radius feature is enabled
    * @function Users.getSpaceBubbleEnabled
    * @return {bool} `true` if the space bubble feature is enabled, `false` if not.
    */
    bool getSpaceBubbleEnabled();

signals:
    void canKickChanged(bool canKick);
    void spaceBubbleEnabledChanged(bool isEnabled);

    /**jsdoc
    * Notifies scripts that another user has entered your space bubble
    * @function Users.enteredSpaceBubble
    */
    void enteredSpaceBubble();
};


#endif // hifi_UsersScriptingInterface_h
