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
            localOnly: true,
            volume: 0.5
        });
        if (updateConnected === true) {
            deleteOverlays();
            updateConnected = false;
            Script.update.disconnect(update);
        }
        bubbleOverlayArray.push(Overlays.addOverlay("model", {
            url: Script.resolvePath("assets/models/bubble-v1.fbx"),
            dimensions: { x: 2.03, y: 0.73, z: 2.03 },
            position: { x: MyAvatar.position.x, y: MyAvatar.position.y + MyAvatar.scale * 0.4, z: MyAvatar.position.z },
            scale: { x: Settings.getValue("IgnoreRadius") / 2, y: 0.5, z: Settings.getValue("IgnoreRadius") / 2 },
            alpha: 1.0,
            visible: true,
            ignoreRayIntersection: true
        }));
        //for (var i = 0; i < 25; i++) {
        //    bubbleOverlayArray.push(Overlays.addOverlay("circle3d", {
        //        position: { x: MyAvatar.position.x, y: MyAvatar.position.y + i * (MyAvatar.scale * 0.07) - MyAvatar.scale * 0.8, z: MyAvatar.position.z },
        //        outerRadius: Settings.getValue("IgnoreRadius") * MyAvatar.scale,
        //        innerRadius: Settings.getValue("IgnoreRadius") * MyAvatar.scale * 0.75,
        //        rotation: bubbleOverlayRotation,
        //        color: {
        //            red: 66,
        //            green: 173,
        //            blue: 244
        //        },
        //        alpha: 1.0,
        //        solid: true,
        //        visible: true,
        //        ignoreRayIntersection: true
        //    }));
        //}
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
        var overlayAlpha = 1.0 - ((timestamp - bubbleOverlayTimestamp) / 5000);
        if (overlayAlpha > 0) {
            // Flash button
            if ((timestamp - bubbleButtonTimestamp) >= 500) {
                button.writeProperty('buttonState', bubbleButtonFlashState ? 1 : 0);
                button.writeProperty('defaultState', bubbleButtonFlashState ? 1 : 0);
                button.writeProperty('hoverState', bubbleButtonFlashState ? 3 : 2);
                bubbleButtonTimestamp = timestamp;
                bubbleButtonFlashState = !bubbleButtonFlashState;
            }

            Overlays.editOverlay(bubbleOverlayArray[0], {
                position: { x: MyAvatar.position.x, y: MyAvatar.position.y + MyAvatar.scale * 0.4, z: MyAvatar.position.z },
                scale: { x: Settings.getValue("IgnoreRadius") / 2, y: 0.5, z: Settings.getValue("IgnoreRadius") / 2 },
                alpha: overlayAlpha
            });
            //for (var i = 1; i < bubbleOverlayArray.length; i++) {
            //    Overlays.editOverlay(bubbleOverlayArray[i], {
            //        position: { x: MyAvatar.position.x, y: MyAvatar.position.y + i * (MyAvatar.scale * 0.07) - MyAvatar.scale * 0.8, z: MyAvatar.position.z },
            //        outerRadius: Settings.getValue("IgnoreRadius") * MyAvatar.scale,
            //        innerRadius: Settings.getValue("IgnoreRadius") * MyAvatar.scale * 0.75,
            //        alpha: overlayAlpha
            //    });
            //}
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
