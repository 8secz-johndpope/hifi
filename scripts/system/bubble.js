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
    var bubbleOverlayArray = [];
    var bubbleOverlayRotation = Quat.fromVec3Degrees({ x: 90, y: 0, z: 0 });
    var bubbleActivateSound = SoundCache.getSound(Script.resolvePath("assets/sounds/bubble.wav"));
    var updateConnected = false;
    var overlayScale, overlayYRotation, overlayYPos;

    var ASSETS_PATH = Script.resolvePath("assets");
    var TOOLS_PATH = Script.resolvePath("assets/images/tools/");

    function buttonImageURL() {
        return TOOLS_PATH + 'bubble.svg';
    }

    function deleteOverlays() {
        for (var i = 0; i < bubbleOverlayArray.length; i++) {
            Overlays.deleteOverlay(bubbleOverlayArray[i]);
        }
        bubbleOverlayArray = [];
        bubbleButtonFlashState = false;
    }

    function createOverlays() {
        Audio.playSound(bubbleActivateSound, {
            position: { x: MyAvatar.position.x, y: MyAvatar.position.y, z: MyAvatar.position.z },
            localOnly: true,
            volume: 0.7
        });
        if (updateConnected === true) {
            deleteOverlays();
            updateConnected = false;
            Script.update.disconnect(update);
        }

        overlayScale = Settings.getValue("IgnoreRadius");
        overlayYPos = MyAvatar.position.y + MyAvatar.scale * 0.4;

        bubbleOverlayArray.push(Overlays.addOverlay("model", {
            url: Script.resolvePath("assets/models/bubble-v3.fbx"),
            dimensions: { x: 1.0, y: 0.5, z: 1.0 },
            position: { x: MyAvatar.position.x, y: overlayYPos, z: MyAvatar.position.z },
            rotation: Quat.fromPitchYawRollDegrees(MyAvatar.bodyPitch, 0, MyAvatar.bodyRoll),
            scale: { x: overlayScale, y: 1.0, z: overlayScale },
            visible: true,
            ignoreRayIntersection: true
        }));
        bubbleOverlayArray.push(Overlays.addOverlay("model", {
            url: Script.resolvePath("assets/models/ring-v1.fbx"),
            dimensions: { x: 1.0, y: 0.0025, z: 1.0 },
            position: { x: MyAvatar.position.x, y: overlayYPos + 0.2, z: MyAvatar.position.z },
            rotation: Quat.fromPitchYawRollDegrees(MyAvatar.bodyPitch, 0, MyAvatar.bodyRoll),
            scale: { x: overlayScale * 1.1, y: 1.0, z: overlayScale * 1.1 },
            visible: true,
            ignoreRayIntersection: true
        }));
        bubbleOverlayArray.push(Overlays.addOverlay("model", {
            url: Script.resolvePath("assets/models/ring-v1.fbx"),
            dimensions: { x: 1.0, y: 0.0025, z: 1.0 },
            position: { x: MyAvatar.position.x, y: overlayYPos, z: MyAvatar.position.z },
            rotation: Quat.fromPitchYawRollDegrees(MyAvatar.bodyPitch, 0, MyAvatar.bodyRoll),
            scale: { x: overlayScale * 1.1, y: 1.0, z: overlayScale * 1.1 },
            visible: true,
            ignoreRayIntersection: true
        }));
        bubbleOverlayArray.push(Overlays.addOverlay("model", {
            url: Script.resolvePath("assets/models/ring-v1.fbx"),
            dimensions: { x: 1.0, y: 0.0025, z: 1.0 },
            position: { x: MyAvatar.position.x, y: overlayYPos - 0.2, z: MyAvatar.position.z },
            rotation: Quat.fromPitchYawRollDegrees(MyAvatar.bodyPitch, 0, MyAvatar.bodyRoll),
            scale: { x: overlayScale * 1.1, y: 1.0, z: overlayScale * 1.1 },
            visible: true,
            ignoreRayIntersection: true
        }));
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
        var overlayAlpha = 1.0 - (delay / 5000);
        if (overlayAlpha > 0) {
            // Flash button
            if ((timestamp - bubbleButtonTimestamp) >= 500) {
                button.writeProperty('buttonState', bubbleButtonFlashState ? 1 : 0);
                button.writeProperty('defaultState', bubbleButtonFlashState ? 1 : 0);
                button.writeProperty('hoverState', bubbleButtonFlashState ? 3 : 2);
                bubbleButtonTimestamp = timestamp;
                bubbleButtonFlashState = !bubbleButtonFlashState;
            }

            overlayScale = Settings.getValue("IgnoreRadius") * ((5000 - delay) / 1500);
            overlayYPos = MyAvatar.position.y + MyAvatar.scale * 0.4;
            overlayYRotation = delay / 100;
            var avatarXPos = MyAvatar.position.x;
            var avatarZPos = MyAvatar.position.z;
            var avatarPitch = MyAvatar.bodyPitch;
            var avatarRoll = MyAvatar.bodyRoll;

            if (delay >= 3500) {
                Overlays.editOverlay(bubbleOverlayArray[0], {
                    position: { x: avatarXPos, y: overlayYPos, z: avatarZPos },
                    rotation: Quat.fromPitchYawRollDegrees(avatarPitch, 0, avatarRoll),
                    scale: {
                        x: overlayScale,
                        y: 1.0,
                        z: overlayScale
                    },
                });
                Overlays.editOverlay(bubbleOverlayArray[1], {
                    position: { x: avatarXPos, y: overlayYPos + 0.2, z: avatarZPos },
                    rotation: Quat.fromPitchYawRollDegrees(avatarPitch, -overlayYRotation, avatarRoll),
                    scale: {
                        x: overlayScale,
                        y: 1.0,
                        z: overlayScale
                    },
                });
                Overlays.editOverlay(bubbleOverlayArray[2], {
                    position: { x: avatarXPos, y: overlayYPos, z: avatarZPos },
                    rotation: Quat.fromPitchYawRollDegrees(avatarPitch, overlayYRotation, avatarRoll),
                    scale: {
                        x: overlayScale,
                        y: 1.0,
                        z: overlayScale
                    },
                });
                Overlays.editOverlay(bubbleOverlayArray[3], {
                    position: { x: avatarXPos, y: overlayYPos - 0.2, z: avatarZPos },
                    rotation: Quat.fromPitchYawRollDegrees(avatarPitch, -overlayYRotation, avatarRoll),
                    scale: {
                        x: overlayScale,
                        y: 1.0,
                        z: overlayScale
                    },
                });
            } else {
                Overlays.editOverlay(bubbleOverlayArray[0], {
                    position: { x: avatarXPos, y: overlayYPos, z: avatarZPos },
                    rotation: Quat.fromPitchYawRollDegrees(avatarPitch, 0, avatarRoll),
                });
                Overlays.editOverlay(bubbleOverlayArray[1], {
                    position: { x: avatarXPos, y: overlayYPos + 0.2, z: avatarZPos },
                    rotation: Quat.fromPitchYawRollDegrees(avatarPitch, -(delay / 100), avatarRoll),
                });
                Overlays.editOverlay(bubbleOverlayArray[2], {
                    position: { x: avatarXPos, y: overlayYPos, z: avatarZPos },
                    rotation: Quat.fromPitchYawRollDegrees(avatarPitch, (delay / 100), avatarRoll),
                });
                Overlays.editOverlay(bubbleOverlayArray[3], {
                    position: { x: avatarXPos, y: overlayYPos - 0.2, z: avatarZPos },
                    rotation: Quat.fromPitchYawRollDegrees(avatarPitch, -(delay / 100), avatarRoll),
                });
            }
        } else {
            deleteOverlays();
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
            deleteOverlays();
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
        deleteOverlays();
        if (updateConnected === true) {
            Script.update.disconnect(update);
        }
    });

}()); // END LOCAL_SCOPE
