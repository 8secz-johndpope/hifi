"use strict";

//
//  bubble.js
//  scripts/system/
//
//  Created by Brad Hefta-Gaub on 11/18/2016
//  Copyright 2016 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//
/* global Toolbars, Script, Users, Overlays, AvatarList, Controller, Camera, getControllerWorldLocation */


(function () { // BEGIN LOCAL_SCOPE

    // grab the toolbar
    var toolbar = Toolbars.getToolbar("com.highfidelity.interface.toolbar.system");
    var bubbleOverlayTimestamp;
    var bubbleButtonFlashState = false;
    var bubbleButtonTimestamp;
    var ignoreRadius = Settings.getValue("IgnoreRadius");
    var bubbleOverlay = Overlays.addOverlay("model", {
        url: Script.resolvePath("assets/models/bubble-v3.fbx"),
        dimensions: { x: 1.0, y: 0.5, z: 1.0 },
        position: { x: MyAvatar.position.x, y: (-MyAvatar.scale * 2) + (MyAvatar.position.y + MyAvatar.scale * 0.35), z: MyAvatar.position.z },
        rotation: Quat.fromPitchYawRollDegrees(MyAvatar.bodyPitch, 0, MyAvatar.bodyRoll),
        scale: { x: ignoreRadius, y: MyAvatar.scale, z: ignoreRadius },
        visible: false,
        ignoreRayIntersection: true
    });
    var bubbleActivateSound = SoundCache.getSound(Script.resolvePath("assets/sounds/bubble.wav"));
    var updateConnected = false;

    var ASSETS_PATH = Script.resolvePath("assets");
    var TOOLS_PATH = Script.resolvePath("assets/images/tools/");

    function buttonImageURL() {
        return TOOLS_PATH + 'bubble.svg';
    }

    function hideOverlays() {
        Overlays.editOverlay(bubbleOverlay, {
            visible: false
        });
        bubbleButtonFlashState = false;
    }

    function createOverlays() {
        ignoreRadius = Settings.getValue("IgnoreRadius");
        Audio.playSound(bubbleActivateSound, {
            position: { x: MyAvatar.position.x, y: MyAvatar.position.y, z: MyAvatar.position.z },
            localOnly: true,
            volume: 0.4
        });
        if (updateConnected === true) {
            hideOverlays();
            updateConnected = false;
            Script.update.disconnect(update);
        }

        Overlays.editOverlay(bubbleOverlay, {
            visible: true
        });
        bubbleOverlayTimestamp = Date.now();
        bubbleButtonTimestamp = bubbleOverlayTimestamp;
        Script.update.connect(update);
        updateConnected = true;
    }

    function enteredIgnoreRadius() {
        createOverlays();
    }

    update = function () {
        var timestamp = Date.now();
        var delay = (timestamp - bubbleOverlayTimestamp);
        var overlayAlpha = 1.0 - (delay / 3000);
        if (overlayAlpha > 0) {
            // Flash button
            if ((timestamp - bubbleButtonTimestamp) >= 500) {
                button.writeProperty('buttonState', bubbleButtonFlashState ? 0 : 1);
                button.writeProperty('defaultState', bubbleButtonFlashState ? 0 : 1);
                button.writeProperty('hoverState', bubbleButtonFlashState ? 2 : 3);
                bubbleButtonTimestamp = timestamp;
                bubbleButtonFlashState = !bubbleButtonFlashState;
            }

            if (delay < 750) {
                Overlays.editOverlay(bubbleOverlay, {
                    position: { x: MyAvatar.position.x, y: ((-((750 - delay) / 750)) * MyAvatar.scale * 2) + (MyAvatar.position.y + MyAvatar.scale * 0.35), z: MyAvatar.position.z },
                    rotation: Quat.fromPitchYawRollDegrees(MyAvatar.bodyPitch, 0, MyAvatar.bodyRoll),
                    scale: { x: ignoreRadius, y: ((1 - ((750 - delay) / 750)) * MyAvatar.scale), z: ignoreRadius }
                });
            } else {
                Overlays.editOverlay(bubbleOverlay, {
                    position: { x: MyAvatar.position.x, y: (MyAvatar.position.y + MyAvatar.scale * 0.35), z: MyAvatar.position.z },
                    rotation: Quat.fromPitchYawRollDegrees(MyAvatar.bodyPitch, 0, MyAvatar.bodyRoll),
                    scale: { x: ignoreRadius, y: MyAvatar.scale, z: ignoreRadius }
                });
            }
        } else {
            hideOverlays();
            if (updateConnected === true) {
                Script.update.disconnect(update);
                updateConnected = false;
            }
            var bubbleActive = Users.getIgnoreRadiusEnabled();
            button.writeProperty('buttonState', bubbleActive ? 0 : 1);
            button.writeProperty('defaultState', bubbleActive ? 0 : 1);
            button.writeProperty('hoverState', bubbleActive ? 2 : 3);
        }
    };

    function onBubbleToggled() {
        var bubbleActive = Users.getIgnoreRadiusEnabled();
        button.writeProperty('buttonState', bubbleActive ? 0 : 1);
        button.writeProperty('defaultState', bubbleActive ? 0 : 1);
        button.writeProperty('hoverState', bubbleActive ? 2 : 3);
        if (bubbleActive) {
            createOverlays();
        } else {
            hideOverlays();
            if (updateConnected === true) {
                Script.update.disconnect(update);
                updateConnected = false;
            }
        }
    }

    // setup the mod button and add it to the toolbar
    var button = toolbar.addButton({
        objectName: 'bubble',
        imageURL: buttonImageURL(),
        visible: true,
        alpha: 0.9
    });
    onBubbleToggled();

    button.clicked.connect(Users.toggleIgnoreRadius);
    Users.ignoreRadiusEnabledChanged.connect(onBubbleToggled);
    Users.enteredIgnoreRadius.connect(enteredIgnoreRadius);

    // cleanup the toolbar button and overlays when script is stopped
    Script.scriptEnding.connect(function () {
        toolbar.removeButton('bubble');
        button.clicked.disconnect(Users.toggleIgnoreRadius);
        Users.ignoreRadiusEnabledChanged.disconnect(onBubbleToggled);
        Users.enteredIgnoreRadius.disconnect(enteredIgnoreRadius);
        Overlays.deleteOverlay(bubbleOverlay);
        bubbleButtonFlashState = false;
        if (updateConnected === true) {
            Script.update.disconnect(update);
        }
    });

}()); // END LOCAL_SCOPE
