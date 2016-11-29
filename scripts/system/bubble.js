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
    var bubbleOverlay = {};
    var updateConnected = null;

    var ASSETS_PATH = Script.resolvePath("assets");
    var TOOLS_PATH = Script.resolvePath("assets/images/tools/");

    function buttonImageURL() {
        return TOOLS_PATH + 'bubble.svg';
    }

    update = function () {
        Overlays.editOverlay(bubbleOverlay.id, {
            position: MyAvatar.position,
            size: MyAvatar.scale * 3
        });
    };

    function createOverlays() {
        bubbleOverlay.id = Overlays.addOverlay("sphere", {
            position: MyAvatar.position,
            size: MyAvatar.scale * 3,
            color: {
                red: 66,
                green: 173,
                blue: 244
            },
            alpha: 0.5,
            solid: true,
            visible: true
        });
    }

    function deleteOverlays() {
        Overlays.deleteOverlay(bubbleOverlay.id);
    }

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
