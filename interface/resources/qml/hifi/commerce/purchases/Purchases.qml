//
//  Purchases.qml
//  qml/hifi/commerce/purchases
//
//  Purchases
//
//  Created by Zach Fox on 2017-08-25
//  Copyright 2017 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

import Hifi 1.0 as Hifi
import QtQuick 2.5
import QtQuick.Controls 1.4
import "../../../styles-uit"
import "../../../controls-uit" as HifiControlsUit
import "../../../controls" as HifiControls
import "../wallet" as HifiWallet
import "../common" as HifiCommerceCommon

// references XXX from root context

Rectangle {
    HifiConstants { id: hifi; }

    id: root;
    property string activeView: "initialize";
    property string referrerURL: "";
    property bool securityImageResultReceived: false;
    property bool purchasesReceived: false;
    property bool punctuationMode: false;
    property bool canRezCertifiedItems: false;
    // Style
    color: hifi.colors.white;
    Hifi.QmlCommerce {
        id: commerce;

        onLoginStatusResult: {
            if (!isLoggedIn && root.activeView !== "needsLogIn") {
                root.activeView = "needsLogIn";
            } else if (isLoggedIn) {
                root.activeView = "initialize";
                commerce.account();
            }
        }

        onAccountResult: {
            if (result.status === "success") {
                commerce.getKeyFilePathIfExists();
            } else {
                // unsure how to handle a failure here. We definitely cannot proceed.
            }
        }

        onKeyFilePathIfExistsResult: {
            if (path === "" && root.activeView !== "notSetUp") {
                root.activeView = "notSetUp";
            } else if (path !== "" && root.activeView === "initialize") {
                commerce.getSecurityImage();
            }
        }

        onSecurityImageResult: {
            securityImageResultReceived = true;
            if (!exists && root.activeView !== "notSetUp") { // "If security image is not set up"
                root.activeView = "notSetUp";
            } else if (exists && root.activeView === "initialize") {
                commerce.getWalletAuthenticatedStatus();
            } else if (exists) {
                // just set the source again (to be sure the change was noticed)
                securityImage.source = "";
                securityImage.source = "image://security/securityImage";
            }
        }

        onWalletAuthenticatedStatusResult: {
            if (!isAuthenticated && !passphraseModal.visible) {
                passphraseModal.visible = true;
            } else if (isAuthenticated) {
                sendToScript({method: 'purchases_getIsFirstUse'});
            }
        }

        onInventoryResult: {
            purchasesReceived = true;
            if (result.status !== 'success') {
                console.log("Failed to get purchases", result.message);
            } else {
                purchasesModel.clear();
                purchasesModel.append(result.data.assets);
                filteredPurchasesModel.clear();
                filteredPurchasesModel.append(result.data.assets);
            }
        }
    }

    Rectangle {
        id: lightboxPopup;
        visible: false;
        anchors.fill: parent;
        color: Qt.rgba(0, 0, 0, 0.5);
        z: 999;

        // This object is always used in a popup.
        // This MouseArea is used to prevent a user from being
        //     able to click on a button/mouseArea underneath the popup.
        MouseArea {
            anchors.fill: parent;
            propagateComposedEvents: false;
        }

        Rectangle {
            id: lightbox_noRezPermission;
            anchors.centerIn: parent;
            width: parent.width - 100;
            height: 400;
            color: "white";

            RalewayRegular {
                text: "You don't have permission to rez certified items in this domain.<br><br>" +
                "Use the <b>GO TO app</b> to visit another domain or <b>go to your own sandbox.</b>";
                anchors.top: parent.top;
                anchors.topMargin: 40;
                anchors.left: parent.left;
                anchors.leftMargin: 40;
                anchors.right: parent.right;
                anchors.rightMargin: 40;
                anchors.bottom: buttons.top;
                color: hifi.colors.baseGray;
                size: 20;
                verticalAlignment: Text.AlignTop;
                wrapMode: Text.WordWrap;
            }

            Item {
                id: buttons;
                anchors.bottom: parent.bottom;
                anchors.bottomMargin: 20;
                anchors.left: parent.left;
                anchors.right: parent.right;
                height: 40;

                // "Close" button
                HifiControlsUit.Button {
                    color: hifi.buttons.noneBorderlessGray;
                    colorScheme: hifi.colorSchemes.light;
                    anchors.top: parent.top;
                    anchors.bottom: parent.bottom;
                    anchors.left: parent.left;
                    anchors.leftMargin: 10;
                    width: parent.width/2 - anchors.leftMargin*2;
                    text: "Close"
                    onClicked: {
                        lightboxPopup.visible = false;
                    }
                }

                // "OPEN GO TO" button
                HifiControlsUit.Button {
                    color: hifi.buttons.noneBorderless;
                    colorScheme: hifi.colorSchemes.light;
                    anchors.top: parent.top;
                    anchors.bottom: parent.bottom;
                    anchors.right: parent.right;
                    anchors.rightMargin: 10;
                    width: parent.width/2 - anchors.rightMargin*2;
                    text: "OPEN GO TO"
                    onClicked: {
                        sendToScript({method: 'purchases_openGoTo'});
                    }
                }
            }
        }
    }

    //
    // TITLE BAR START
    //
    HifiCommerceCommon.EmulatedMarketplaceHeader {
        id: titleBarContainer;
        visible: !needsLogIn.visible;
        // Size
        width: parent.width;
        height: 70;
        // Anchors
        anchors.left: parent.left;
        anchors.top: parent.top;

        Connections {
            onSendToParent: {
                if (msg.method === 'needsLogIn' && root.activeView !== "needsLogIn") {
                    root.activeView = "needsLogIn";
                } else {
                    sendToScript(msg);
                }
            }
        }
    }
    //
    // TITLE BAR END
    //

    Rectangle {
        id: initialize;
        visible: root.activeView === "initialize";
        anchors.top: titleBarContainer.bottom;
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right;
        color: hifi.colors.white;

        Component.onCompleted: {
            securityImageResultReceived = false;
            purchasesReceived = false;
            commerce.getLoginStatus();
        }
    }

    HifiWallet.NeedsLogIn {
        id: needsLogIn;
        visible: root.activeView === "needsLogIn";
        anchors.top: parent.top;
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right;

        Connections {
            onSendSignalToWallet: {
                sendToScript(msg);
            }
        }
    }
    Connections {
        target: GlobalServices
        onMyUsernameChanged: {
            commerce.getLoginStatus();
        }
    }

    HifiWallet.PassphraseModal {
        id: passphraseModal;
        visible: false;
        anchors.fill: parent;
        titleBarText: "Purchases";

        Connections {
            onSendSignalToParent: {
                sendToScript(msg);
            }
        }
    }

    FirstUseTutorial {
        id: firstUseTutorial;
        visible: root.activeView === "firstUseTutorial";
        anchors.top: titleBarContainer.bottom;
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right;

        Connections {
            onSendSignalToParent: {
                switch (message.method) {
                    case 'tutorial_skipClicked':
                    case 'tutorial_finished':
                        sendToScript({method: 'purchases_setIsFirstUse'});
                        root.activeView = "purchasesMain";
                        commerce.inventory();
                    break;
                }
            }
        }
    }

    //
    // "WALLET NOT SET UP" START
    //
    Item {
        id: notSetUp;
        visible: root.activeView === "notSetUp";
        anchors.top: titleBarContainer.bottom;
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right;

        RalewayRegular {
            id: notSetUpText;
            text: "<b>Your wallet isn't set up.</b><br><br>Set up your Wallet (no credit card necessary) to claim your <b>free HFC</b> " +
            "and get items from the Marketplace.";
            // Text size
            size: 24;
            // Anchors
            anchors.top: parent.top;
            anchors.bottom: notSetUpActionButtonsContainer.top;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            anchors.right: parent.right;
            anchors.rightMargin: 16;
            // Style
            color: hifi.colors.faintGray;
            wrapMode: Text.WordWrap;
            // Alignment
            horizontalAlignment: Text.AlignHCenter;
            verticalAlignment: Text.AlignVCenter;
        }

        Item {
            id: notSetUpActionButtonsContainer;
            // Size
            width: root.width;
            height: 70;
            // Anchors
            anchors.left: parent.left;
            anchors.bottom: parent.bottom;
            anchors.bottomMargin: 24;

            // "Cancel" button
            HifiControlsUit.Button {
                id: cancelButton;
                color: hifi.buttons.black;
                colorScheme: hifi.colorSchemes.dark;
                anchors.top: parent.top;
                anchors.topMargin: 3;
                anchors.bottom: parent.bottom;
                anchors.bottomMargin: 3;
                anchors.left: parent.left;
                anchors.leftMargin: 20;
                width: parent.width/2 - anchors.leftMargin*2;
                text: "Cancel"
                onClicked: {
                    sendToScript({method: 'purchases_backClicked', referrerURL: referrerURL});
                }
            }

            // "Set Up" button
            HifiControlsUit.Button {
                id: setUpButton;
                color: hifi.buttons.blue;
                colorScheme: hifi.colorSchemes.dark;
                anchors.top: parent.top;
                anchors.topMargin: 3;
                anchors.bottom: parent.bottom;
                anchors.bottomMargin: 3;
                anchors.right: parent.right;
                anchors.rightMargin: 20;
                width: parent.width/2 - anchors.rightMargin*2;
                text: "Set Up Wallet"
                onClicked: {
                    sendToScript({method: 'checkout_setUpClicked'});
                }
            }
        }
    }
    //
    // "WALLET NOT SET UP" END
    //

    //
    // PURCHASES CONTENTS START
    //
    Item {
        id: purchasesContentsContainer;
        visible: root.activeView === "purchasesMain";
        // Anchors
        anchors.left: parent.left;
        anchors.right: parent.right;
        anchors.top: titleBarContainer.bottom;
        anchors.topMargin: 8;
        anchors.bottom: parent.bottom;

        //
        // FILTER BAR START
        //
        Item {
            id: filterBarContainer;
            // Size
            height: 40;
            // Anchors
            anchors.left: parent.left;
            anchors.leftMargin: 8;
            anchors.right: parent.right;
            anchors.rightMargin: 12;
            anchors.top: parent.top;
            anchors.topMargin: 4;

            RalewayRegular {
                id: myPurchasesText;
                anchors.top: parent.top;
                anchors.topMargin: 10;
                anchors.bottom: parent.bottom;
                anchors.bottomMargin: 10;
                anchors.left: parent.left;
                anchors.leftMargin: 4;
                width: paintedWidth;
                text: "My Purchases";
                color: hifi.colors.baseGray;
                size: 28;
            }

            HifiControlsUit.TextField {
                id: filterBar;
                hasRoundedBorder: true;
                property int previousLength: 0;
                anchors.left: myPurchasesText.right;
                anchors.leftMargin: 16;
                anchors.top: parent.top;
                anchors.bottom: parent.bottom;
                anchors.right: parent.right;
                placeholderText: "filter items";

                onTextChanged: {
                    if (filterBar.text.length < previousLength) {
                        filteredPurchasesModel.clear();

                        for (var i = 0; i < purchasesModel.count; i++) {
                            filteredPurchasesModel.append(purchasesModel.get(i));
                        }
                    }

                    for (var i = 0; i < filteredPurchasesModel.count; i++) {
                        if (filteredPurchasesModel.get(i).title.toLowerCase().indexOf(filterBar.text.toLowerCase()) === -1) {
                            filteredPurchasesModel.remove(i);
                            i--;
                        }
                    }
                    previousLength = filterBar.text.length;
                }

                onAccepted: {
                    focus = false;
                }
            }
        }
        //
        // FILTER BAR END
        //

        HifiControlsUit.Separator {
            id: separator;
            colorScheme: 1;
            anchors.left: parent.left;
            anchors.right: parent.right;
            anchors.top: filterBarContainer.bottom;
            anchors.topMargin: 16;
        }

        ListModel {
            id: purchasesModel;
        }
        ListModel {
            id: filteredPurchasesModel;
        }

        Rectangle {
            id: cantRezCertified;
            visible: !root.canRezCertifiedItems;
            color: "#FFC3CD";
            radius: 4;
            border.color: hifi.colors.redAccent;
            border.width: 1;
            anchors.top: separator.bottom;
            anchors.topMargin: 12;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            anchors.right: parent.right;
            anchors.rightMargin: 16;
            height: 80;

            HiFiGlyphs {
                id: lightningIcon;
                text: hifi.glyphs.lightning;
                // Size
                size: 36;
                // Anchors
                anchors.top: parent.top;
                anchors.topMargin: 18;
                anchors.left: parent.left;
                anchors.leftMargin: 12;
                horizontalAlignment: Text.AlignHCenter;
                // Style
                color: hifi.colors.lightGray;
            }

            RalewayRegular {
                text: "You don't have permission to rez certified items in this domain.";
                // Text size
                size: 18;
                // Anchors
                anchors.top: parent.top;
                anchors.topMargin: 4;
                anchors.left: lightningIcon.right;
                anchors.leftMargin: 8;
                anchors.right: helpButton.left;
                anchors.rightMargin: 16;
                anchors.bottom: parent.bottom;
                anchors.bottomMargin: 4;
                // Style
                color: hifi.colors.baseGray;
                wrapMode: Text.WordWrap;
                // Alignment
                verticalAlignment: Text.AlignVCenter;
            }
            
            HifiControlsUit.Button {
                id: helpButton;
                color: hifi.buttons.red;
                colorScheme: hifi.colorSchemes.light;
                anchors.top: parent.top;
                anchors.topMargin: 12;
                anchors.bottom: parent.bottom;
                anchors.bottomMargin: 8;
                anchors.right: parent.right;
                anchors.rightMargin: 12;
                width: height;
                HiFiGlyphs {
                    text: hifi.glyphs.question;
                    // Size
                    size: parent.height*1.3;
                    // Anchors
                    anchors.fill: parent;
                    // Style
                    horizontalAlignment: Text.AlignHCenter;
                    color: hifi.colors.faintGray;
                }

                onClicked: {
                    lightboxPopup.visible = true;
                }
            }
        }

        ListView {
            id: purchasesContentsList;
            visible: purchasesModel.count !== 0;
            clip: true;
            model: filteredPurchasesModel;
            // Anchors
            anchors.top: root.canRezCertifiedItems ? separator.bottom : cantRezCertified.bottom;
            anchors.topMargin: 12;
            anchors.left: parent.left;
            anchors.bottom: parent.bottom;
            width: parent.width;
            delegate: PurchasedItem {
                canRezCertifiedItems: root.canRezCertifiedItems;
                itemName: title;
                itemId: id;
                itemPreviewImageUrl: preview;
                itemHref: root_file_url;
                anchors.topMargin: 12;
                anchors.bottomMargin: 12;

                Connections {
                    onSendToPurchases: {
                        if (msg.method === 'purchases_itemInfoClicked') {
                            sendToScript({method: 'purchases_itemInfoClicked', itemId: itemId});
                        }
                    }
                }
            }
        }

        Item {
            id: noPurchasesAlertContainer;
            visible: !purchasesContentsList.visible && root.purchasesReceived;
            anchors.top: filterBarContainer.bottom;
            anchors.topMargin: 12;
            anchors.left: parent.left;
            anchors.bottom: parent.bottom;
            width: parent.width;

            // Explanitory text
            RalewayRegular {
                id: haventPurchasedYet;
                text: "<b>You haven't purchased anything yet!</b><br><br>Get an item from <b>Marketplace</b> to add it to your <b>Purchases</b>.";
                // Text size
                size: 22;
                // Anchors
                anchors.top: parent.top;
                anchors.topMargin: 150;
                anchors.left: parent.left;
                anchors.leftMargin: 24;
                anchors.right: parent.right;
                anchors.rightMargin: 24;
                height: paintedHeight;
                // Style
                color: hifi.colors.faintGray;
                wrapMode: Text.WordWrap;
                // Alignment
                horizontalAlignment: Text.AlignHCenter;
            }

            // "Set Up" button
            HifiControlsUit.Button {
                color: hifi.buttons.blue;
                colorScheme: hifi.colorSchemes.dark;
                anchors.top: haventPurchasedYet.bottom;
                anchors.topMargin: 20;
                anchors.horizontalCenter: parent.horizontalCenter;
                width: parent.width * 2 / 3;
                height: 50;
                text: "Visit Marketplace";
                onClicked: {
                    sendToScript({method: 'purchases_goToMarketplaceClicked'});
                }
            }
        }
    }
    //
    // PURCHASES CONTENTS END
    //

    HifiControlsUit.Keyboard {
        id: keyboard;
        raised: HMD.mounted && filterBar.focus;
        numeric: parent.punctuationMode;
        anchors {
            bottom: parent.bottom;
            left: parent.left;
            right: parent.right;
        }
    }

    //
    // FUNCTION DEFINITIONS START
    //
    //
    // Function Name: fromScript()
    //
    // Relevant Variables:
    // None
    //
    // Arguments:
    // message: The message sent from the JavaScript, in this case the Marketplaces JavaScript.
    //     Messages are in format "{method, params}", like json-rpc.
    //
    // Description:
    // Called when a message is received from a script.
    //
    function fromScript(message) {
        switch (message.method) {
            case 'updatePurchases':
                referrerURL = message.referrerURL;
                titleBarContainer.referrerURL = message.referrerURL;
                root.canRezCertifiedItems = message.canRezCertifiedItems;
            break;
            case 'purchases_getIsFirstUseResult':
                if (message.isFirstUseOfPurchases && root.activeView !== "firstUseTutorial") {
                    root.activeView = "firstUseTutorial";
                } else if (!message.isFirstUseOfPurchases && root.activeView === "initialize") {
                    root.activeView = "purchasesMain";
                    commerce.inventory();
                }
            break;
            default:
                console.log('Unrecognized message from marketplaces.js:', JSON.stringify(message));
        }
    }
    signal sendToScript(var message);

    //
    // FUNCTION DEFINITIONS END
    //
}
