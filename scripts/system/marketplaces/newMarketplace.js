//
//  newMarketplace.js
//
//  Created by Zach Fox on 2018-03-23.
//  Copyright 2018 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

/* global Tablet, Script, HMD, UserActivityLogger, Entities, Account, Wallet, ContextOverlay, Settings, Camera, Vec3,
   Quat, MyAvatar, Clipboard, Menu, Grid, Uuid, GlobalServices, openLoginWindow, Overlays, SoundCache,
   DesktopPreviewProvider */
/* eslint indent: ["error", 4, { "outerIIFEBody": 0 }] */

var selectionDisplay = null; // for gridTool.js to ignore

(function () { // BEGIN LOCAL_SCOPE
    var METAVERSE_SERVER_URL = Account.metaverseServerURL;

    // Function Name: startup()
    //
    // Description:
    //   -startup() will be called when the script is loaded.
    //
    // Relevant Variables:
    //   -tablet: The tablet instance to be modified.
    var tablet = null;
    function startup() {
        tablet = Tablet.getTablet("com.highfidelity.interface.tablet.system");
        addOrRemoveButton(false);
        tablet.screenChanged.connect(onTabletScreenChanged);
    }

    // Function Name: addOrRemoveButton()
    //
    // Description:
    //   -Used to add or remove the app button from the HUD/tablet. Set the "isShuttingDown" argument
    //    to true if you're calling this function upon script shutdown.
    //
    // Relevant Variables:
    //   -button: The tablet button.
    //   -buttonName: The name of the button.
    var button = false;
    var buttonName = "MARKET";
    var NORMAL_ICON = Script.resolvePath("market-i.svg");
    var NORMAL_ACTIVE = Script.resolvePath("market-a.svg");
    var WAITING_ICON = Script.resolvePath("market-i-msg.svg");
    var WAITING_ACTIVE = Script.resolvePath("market-a-msg.svg");
    function addOrRemoveButton(isShuttingDown) {
        if (!tablet) {
            print("Warning in addOrRemoveButton(): 'tablet' undefined!");
            return;
        }
        if (!button && !isShuttingDown) {
            button = tablet.addButton({
                icon: NORMAL_ICON,
                activeIcon: NORMAL_ACTIVE,
                text: buttonName,
                sortOrder: 9
            });
            button.clicked.connect(onTabletButtonClicked);
        } else if (button) {
            button.clicked.disconnect(onTabletButtonClicked);
            tablet.removeButton(button);
            button = false;
        } else {
            print("ERROR adding/removing MARKET button!");
        }
    }

    // Function Name: wireEventBridge()
    //
    // Description:
    //   -Used to connect/disconnect the script's response to the tablet's "fromQml" signal. Set the "on" argument to enable or
    //    disable to event bridge.
    //
    // Relevant Variables:
    //   -hasEventBridge: true/false depending on whether we've already connected the event bridge.
    var hasEventBridge = false;
    function wireEventBridge(on) {
        if (!tablet) {
            print("Warning in wireEventBridge(): 'tablet' undefined!");
            return;
        }
        if (on) {
            if (!hasEventBridge) {
                tablet.fromQml.connect(fromQml);
                hasEventBridge = true;
            }
        } else {
            if (hasEventBridge) {
                tablet.fromQml.disconnect(fromQml);
                hasEventBridge = false;
            }
        }
    }

    // Function Name: onTabletButtonClicked()
    //
    // Description:
    //   -Fired when the app button is pressed.
    //
    // Relevant Variables:
    //   -MARKETPLACE_QML_SOURCE: The path to the app QML
    //   -onMarketplaceScreen: true/false depending on whether we're looking at the app.
    var MARKETPLACE_QML_PATH = "hifi/commerce/marketplace/NewMarketplace.qml";
    var MARKETPLACE_CHECKOUT_QML_PATH = "hifi/commerce/checkout/Checkout.qml";
    var onMarketplaceScreen = false;
    function onTabletButtonClicked() {
        if (!tablet) {
            print("Warning in onTabletButtonClicked(): 'tablet' undefined!");
            return;
        }
        if (onMarketplaceScreen) {
            // In Toolbar Mode, `gotoHomeScreen` will close the app window.
            tablet.gotoHomeScreen();
        } else {
            tablet.loadQMLSource(MARKETPLACE_QML_PATH);
        }
    }

    // Function Name: onTabletScreenChanged()
    //
    // Description:
    //   -Called when the TabletScriptingInterface::screenChanged() signal is emitted. The "type" argument can be either the string
    //    value of "Home", "Web", "Menu", "QML", or "Closed". The "url" argument is only valid for Web and QML.
    function onTabletScreenChanged(type, url) {
        onMarketplaceScreen = (type === "QML" && url === MARKETPLACE_QML_PATH);
        onCheckoutScreen = (type === "QML" && url === MARKETPLACE_CHECKOUT_QML_PATH);
        wireEventBridge(onMarketplaceScreen || onCheckoutScreen);

        if (onMarketplaceScreen) {
            Wallet.refreshWalletStatus();
        }

        if (button) {
            button.editProperties({ isActive: onMarketplaceScreen });
        }
    }

    // Function Name: sendToQml()
    //
    // Description:
    //   -Use this function to send a message to the QML (i.e. to change appearances). The "message" argument is what is sent to
    //    the QML in the format "{method, params}", like json-rpc. See also fromQml().
    function sendToQml(message) {
        tablet.sendToQml(message);
    }

    // Function Name: fromQml()
    //
    // Description:
    //   -Called when a message is received from the app's QML. The "message" argument is what is sent from the QML
    //    in the format "{method, params}", like json-rpc. See also sendToQml().
    function fromQml(message) {
        switch (message.method) {
            case "buyItem":
                tablet.pushOntoStack(MARKETPLACE_CHECKOUT_QML_PATH);
                tablet.sendToQml({
                    method: 'updateCheckoutQML', params: {
                        itemId: message.itemId
                    }
                });
                break;
            case "checkout_cancelClicked":
                tablet.loadQMLSource(MARKETPLACE_QML_PATH);
                tablet.sendToQml({ method: 'loadItemInfo', itemId: message.itemId });
                break;
            default:
                print('Unrecognized message from NewMarketplace.qml:', JSON.stringify(message));
                break;
        }
    }

    // Function Name: shutdown()
    //
    // Description:
    //   -shutdown() will be called when the script ends (i.e. is stopped).
    function shutdown() {
        addOrRemoveButton(true);
        if (tablet) {
            tablet.screenChanged.disconnect(onTabletScreenChanged);
            if (onMarketplaceScreen) {
                tablet.gotoHomeScreen();
            }
        }
    }

    // These functions will be called when the script is loaded.
    startup();
    Script.scriptEnding.connect(shutdown);

}()); // END LOCAL_SCOPE
