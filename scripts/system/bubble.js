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
    var bubbleOverlayArray = [];
    var bubbleOverlayRotation = Quat.fromVec3Degrees({ x: 90, y: 0, z: 0 });
    var updateConnected = null;

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
    }

    function createOverlays() {
        for (var i = 0; i < 25; i++) {
            bubbleOverlayArray.push(Overlays.addOverlay("circle3d", {
                position: { x: MyAvatar.position.x, y: MyAvatar.position.y + i * (MyAvatar.scale * 0.07) - MyAvatar.scale * 0.8, z: MyAvatar.position.z },
                outerRadius: Settings.getValue("IgnoreRadius") * MyAvatar.scale,
                innerRadius: Settings.getValue("IgnoreRadius") * MyAvatar.scale * 0.75,
                rotation: bubbleOverlayRotation,
                color: {
                    red: 66,
                    green: 173,
                    blue: 244
                },
                alpha: 0.9,
                solid: true,
                visible: true,
                ignoreRayIntersection: true
            }));
        }
        bubbleOverlayTimestamp = Date.now();
    }

    update = function () {
        var overlayAlpha = 0.9 - ((Date.now() - bubbleOverlayTimestamp) / 5000);
        if (overlayAlpha > 0) {
            for (var i = 0; i < bubbleOverlayArray.length; i++) {
                Overlays.editOverlay(bubbleOverlayArray[i], {
                    position: { x: MyAvatar.position.x, y: MyAvatar.position.y + i * (MyAvatar.scale * 0.07) - MyAvatar.scale * 0.8, z: MyAvatar.position.z },
                    outerRadius: Settings.getValue("IgnoreRadius") * MyAvatar.scale,
                    innerRadius: Settings.getValue("IgnoreRadius") * MyAvatar.scale * 0.75,
                    alpha: overlayAlpha
                });
            }
        } else {
            deleteOverlays();
            if (updateConnected === true) {
                Script.update.disconnect(update);
            }
        }
    };

    function onBubbleToggled() {
        var bubbleActive = Users.getIgnoreRadiusEnabled();
        button.writeProperty('buttonState', bubbleActive ? 0 : 1);
        button.writeProperty('defaultState', bubbleActive ? 0 : 1);
        button.writeProperty('hoverState', bubbleActive ? 2 : 3);
        if (bubbleActive) {
            createOverlays();
            Script.update.connect(update);
            updateConnected = true;
        } else {
            deleteOverlays();
            if (updateConnected === true) {
                Script.update.disconnect(update);
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

    // cleanup the toolbar button and overlays when script is stopped
    Script.scriptEnding.connect(function () {
        toolbar.removeButton('bubble');
        button.clicked.disconnect(Users.toggleIgnoreRadius);
        Users.ignoreRadiusEnabledChanged.disconnect(onBubbleToggled);
        deleteOverlays();
        if (updateConnected !== null) {
            Script.update.disconnect(update);
        }
    });

}()); // END LOCAL_SCOPE
