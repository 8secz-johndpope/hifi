//
//  modalContainer.qml
//  qml/hifi/commerce/wallet
//
//  modalContainer
//
//  Created by Zach Fox on 2017-08-17
//  Copyright 2017 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

import Hifi 1.0 as Hifi
import QtQuick 2.5
import QtGraphicalEffects 1.0
import QtQuick.Controls 1.4
import "../../../styles-uit"
import "../../../controls-uit" as HifiControlsUit
import "../../../controls" as HifiControls

// references XXX from root context

Item {
    HifiConstants { id: hifi; }

    id: root;
    property string activeView: "step_1";
    property string lastPage;
    property bool hasShownSecurityImageTip: false;

    LinearGradient {
        anchors.fill: parent;
        start: Qt.point(parent.width, 0);
        end: Qt.point(0, parent.width);
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1A7E8E" }
            GradientStop { position: 1.0; color: "#45366E" }
        }
    }

    Hifi.QmlCommerce {
        id: commerce;

        onSecurityImageResult: {
            if (!exists && root.lastPage === "step_2") {
                // ERROR! Invalid security image.
                root.activeView = "step_2";
            }
        }

        onWalletAuthenticatedStatusResult: {
            if (isAuthenticated) {
                root.activeView = "step_4";
            } else {
                root.activeView = "step_3";
            }
        }

        onKeyFilePathIfExistsResult: {
            keyFilePath.text = path;
        }
    }


    //
    // TITLE BAR START
    //
    Item {
        id: titleBarContainer;
        // Size
        width: parent.width;
        height: 50;
        // Anchors
        anchors.left: parent.left;
        anchors.top: parent.top;

        // Title Bar text
        RalewayRegular {
            id: titleBarText;
            text: "Wallet Setup - Step " + root.activeView.split("_")[1] + " of 4";
            // Text size
            size: hifi.fontSizes.overlayTitle;
            // Anchors
            anchors.top: parent.top;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            anchors.bottom: parent.bottom;
            width: paintedWidth;
            // Style
            color: hifi.colors.white;
            // Alignment
            horizontalAlignment: Text.AlignHLeft;
            verticalAlignment: Text.AlignVCenter;
        }
    }
    //
    // TITLE BAR END
    //
    
    //
    // FIRST PAGE START
    //
    Item {
        id: firstPageContainer;
        visible: root.activeView === "step_1";
        // Anchors
        anchors.top: titleBarContainer.bottom;
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right;

        RalewayRegular {
            id: firstPage_text01;
            text: "Let's set up your wallet!";
            // Text size
            size: 26;
            // Anchors
            anchors.top: parent.top;
            anchors.topMargin: 100;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            anchors.right: parent.right;
            anchors.rightMargin: 16;
            height: paintedHeight;
            width: paintedWidth;
            // Style
            color: hifi.colors.white;
            wrapMode: Text.WordWrap;
            // Alignment
            horizontalAlignment: Text.AlignHCenter;
            verticalAlignment: Text.AlignVCenter;
        }

        RalewayRegular {
            id: firstPage_text02;
            text: "Set up your wallet to claim your <b>free High Fidelity Coin (HFC)</b> and get items from the Marketplace.<br><br>" +
            "No credit card is required.";
            // Text size
            size: 18;
            // Anchors
            anchors.top: firstPage_text01.bottom;
            anchors.topMargin: 40;
            anchors.left: parent.left;
            anchors.leftMargin: 65;
            anchors.right: parent.right;
            anchors.rightMargin: 65;
            height: paintedHeight;
            width: paintedWidth;
            // Style
            color: hifi.colors.white;
            wrapMode: Text.WordWrap;
            // Alignment
            horizontalAlignment: Text.AlignHCenter;
            verticalAlignment: Text.AlignVCenter;
        }

        // "Set Up" button
        HifiControlsUit.Button {
            id: firstPage_setUpButton;
            color: hifi.buttons.blue;
            colorScheme: hifi.colorSchemes.dark;
            anchors.top: firstPage_text02.bottom;
            anchors.topMargin: 40;
            anchors.horizontalCenter: parent.horizontalCenter;
            width: parent.width/2;
            height: 50;
            text: "Set Up Wallet";
            onClicked: {
                root.activeView = "step_2";
            }
        }

        // "Cancel" button
        HifiControlsUit.Button {
            color: hifi.buttons.none;
            colorScheme: hifi.colorSchemes.dark;
            anchors.top: firstPage_setUpButton.bottom;
            anchors.topMargin: 20;
            anchors.horizontalCenter: parent.horizontalCenter;
            width: parent.width/2;
            height: 50;
            text: "Cancel";
            onClicked: {
                sendSignalToWallet({method: 'walletSetup_cancelClicked'});
            }
        }   
    }
    //
    // FIRST PAGE END
    //

    //
    // SECURITY IMAGE SELECTION START
    //
    Item {
        id: securityImageContainer;
        visible: root.activeView === "step_2";
        // Anchors
        anchors.top: titleBarContainer.bottom;
        anchors.topMargin: 30;
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.leftMargin: 16;
        anchors.right: parent.right;
        anchors.rightMargin: 16;

        // Text below title bar
        RalewayRegular {
            id: securityImageTitleHelper;
            text: "Choose a Security Pic:";
            // Text size
            size: 24;
            // Anchors
            anchors.top: parent.top;
            anchors.left: parent.left;
            height: 50;
            width: paintedWidth;
            // Style
            color: hifi.colors.white;
            // Alignment
            horizontalAlignment: Text.AlignHLeft;
            verticalAlignment: Text.AlignVCenter;
        }

        SecurityImageSelection {
            id: securityImageSelection;
            // Anchors
            anchors.top: securityImageTitleHelper.bottom;
            anchors.left: parent.left;
            anchors.right: parent.right;
            height: 300;

            Connections {
                onSendSignalToWallet: {
                    sendSignalToWallet(msg);
                }
            }
        }

        // Text below security images
        RalewayRegular {
            text: "<b>Your security picture shows you that the service asking for your passphrase is authorized.</b> You can change your secure picture at any time.";
            // Text size
            size: 18;
            // Anchors
            anchors.top: securityImageSelection.bottom;
            anchors.topMargin: 40;
            anchors.left: parent.left;
            anchors.right: parent.right;
            height: paintedHeight;
            // Style
            color: hifi.colors.white;
            wrapMode: Text.WordWrap;
            // Alignment
            horizontalAlignment: Text.AlignHLeft;
            verticalAlignment: Text.AlignVCenter;
        }

        // Navigation Bar
        Item {
            // Size
            width: parent.width;
            height: 50;
            // Anchors:
            anchors.left: parent.left;
            anchors.bottom: parent.bottom;
            anchors.bottomMargin: 50;

            // "Back" button
            HifiControlsUit.Button {
                color: hifi.buttons.noneBorderlessWhite;
                colorScheme: hifi.colorSchemes.dark;
                anchors.top: parent.top;
                anchors.bottom: parent.bottom;
                anchors.left: parent.left;
                anchors.leftMargin: 20;
                width: 200;
                text: "Back"
                onClicked: {
                    root.activeView = "step_1";
                }
            }

            // "Next" button
            HifiControlsUit.Button {
                enabled: securityImageSelection.currentIndex !== -1;
                color: hifi.buttons.blue;
                colorScheme: hifi.colorSchemes.dark;
                anchors.top: parent.top;
                anchors.bottom: parent.bottom;
                anchors.right: parent.right;
                anchors.rightMargin: 20;
                width: 200;
                text: "Next";
                onClicked: {
                    root.lastPage = "step_2";
                    var securityImagePath = securityImageSelection.getImagePathFromImageID(securityImageSelection.getSelectedImageIndex())
                    commerce.chooseSecurityImage(securityImagePath);
                    root.activeView = "step_3";
                    passphraseSelection.clearPassphraseFields();
                }
            }
        }
    }
    //
    // SECURITY IMAGE SELECTION END
    //

    //
    // SECURE PASSPHRASE SELECTION START
    //

    Item {
        id: securityImageTip;
        visible: false;
        z: 999;
        anchors.fill: root;
        
        // This object is always used in a popup.
        // This MouseArea is used to prevent a user from being
        //     able to click on a button/mouseArea underneath the popup.
        MouseArea {
            anchors.fill: parent;
            propagateComposedEvents: false;
        }

        Item {
            id: holePunch;
            height: 180;
            width: 230;
            anchors.right: parent.right;
            anchors.top: parent.top;
            anchors.topMargin: 135;
        }        
        Rectangle {
            id: leftMaskRect;
            anchors.top: parent.top;
            anchors.bottom: parent.bottom;
            anchors.left: parent.left;
            anchors.right: holePunch.left;
            color: "black";
            opacity: 0.9;
        }
        Rectangle {
            id: topMaskRect;
            anchors.top: parent.top;
            anchors.bottom: holePunch.top;
            anchors.left: leftMaskRect.right;
            anchors.right: parent.right;
            color: "black";
            opacity: leftMaskRect.opacity;
        }
        Rectangle {
            id: bottomMaskRect;
            anchors.top: holePunch.bottom;
            anchors.bottom: parent.bottom;
            anchors.left: leftMaskRect.right;
            anchors.right: parent.right;
            color: "black";
            opacity: leftMaskRect.opacity;
        }

        RalewayRegular {
            id: tipText;
            text: '<font size="5">Tip:</font><br><br>When you see your security picture like this, you know ' +
            "the page asking for your passphrase is legitimate.";
            // Text size
            size: 18;
            // Anchors
            anchors.bottom: parent.bottom;
            anchors.bottomMargin: 230;
            anchors.left: parent.left;
            anchors.leftMargin: 60;
            height: paintedHeight;
            width: 210;
            // Style
            color: hifi.colors.white;
            wrapMode: Text.WordWrap;
            // Alignment
            horizontalAlignment: Text.AlignHCenter;
        }

        // "Got It" button
        HifiControlsUit.Button {
            id: tipGotItButton;
            color: hifi.buttons.blue;
            colorScheme: hifi.colorSchemes.dark;
            anchors.top: tipText.bottom;
            anchors.topMargin: 20;
            anchors.horizontalCenter: tipText.horizontalCenter;
            height: 50;
            width: 150;
            text: "Got It";
            onClicked: {
                root.hasShownSecurityImageTip = true;
                securityImageTip.visible = false;
            }
        }
    }
    Item {
        id: choosePassphraseContainer;
        visible: root.activeView === "step_3";
        // Anchors
        anchors.top: titleBarContainer.bottom;
        anchors.topMargin: 30;
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right;

        onVisibleChanged: {
            if (visible) {
                commerce.getWalletAuthenticatedStatus();
                if (!root.hasShownSecurityImageTip) {
                    securityImageTip.visible = true;
                }
            }
        }

        // Text below title bar
        RalewayRegular {
            id: passphraseTitleHelper;
            text: "Set Your Passphrase:";
            // Text size
            size: 24;
            // Anchors
            anchors.top: parent.top;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            anchors.right: parent.right;
            anchors.rightMargin: 16;
            height: 50;
            // Style
            color: hifi.colors.white;
            // Alignment
            horizontalAlignment: Text.AlignHLeft;
            verticalAlignment: Text.AlignVCenter;
        }

        PassphraseSelection {
            id: passphraseSelection;
            anchors.top: passphraseTitleHelper.bottom;
            anchors.topMargin: 30;
            anchors.left: parent.left;
            anchors.right: parent.right;
            anchors.bottom: passphraseNavBar.top;

            Connections {
                onSendMessageToLightbox: {
                    if (msg.method === 'statusResult') {
                    } else {
                        sendSignalToWallet(msg);
                    }
                }
            }
        }

        // Navigation Bar
        Item {
            id: passphraseNavBar;
            // Size
            width: parent.width;
            height: 50;
            // Anchors:
            anchors.left: parent.left;
            anchors.bottom: parent.bottom;
            anchors.bottomMargin: 50;

            // "Back" button
            HifiControlsUit.Button {
                color: hifi.buttons.noneBorderlessWhite;
                colorScheme: hifi.colorSchemes.dark;
                anchors.top: parent.top;
                anchors.bottom: parent.bottom;
                anchors.left: parent.left;
                anchors.leftMargin: 20;
                width: 200;
                text: "Back"
                onClicked: {
                    root.lastPage = "step_3";
                    root.activeView = "step_2";
                }
            }

            // "Next" button
            HifiControlsUit.Button {
                id: passphrasePageNextButton;
                color: hifi.buttons.blue;
                colorScheme: hifi.colorSchemes.dark;
                anchors.top: parent.top;
                anchors.bottom: parent.bottom;
                anchors.right: parent.right;
                anchors.rightMargin: 20;
                width: 200;
                text: "Next";
                onClicked: {
                    if (passphraseSelection.validateAndSubmitPassphrase()) {
                        root.lastPage = "step_3";
                        commerce.generateKeyPair();
                        root.activeView = "step_4";
                    }
                }
            }
        }
    }
    //
    // SECURE PASSPHRASE SELECTION END
    //

    //
    // PRIVATE KEYS READY START
    //
    Item {
        id: privateKeysReadyContainer;
        visible: root.activeView === "step_4";
        // Anchors
        anchors.top: titleBarContainer.bottom;
        anchors.topMargin: 30;
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right;

        // Text below title bar
        RalewayRegular {
            id: keysReadyTitleHelper;
            text: "Back Up Your Private Keys";
            // Text size
            size: 24;
            // Anchors
            anchors.top: parent.top;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            anchors.right: parent.right;
            anchors.rightMargin: 16;
            height: 50;
            // Style
            color: hifi.colors.white;
            // Alignment
            horizontalAlignment: Text.AlignHLeft;
            verticalAlignment: Text.AlignVCenter;
        }

        Rectangle {
            id: pathAndInstructionsContainer;
            anchors.top: keysReadyTitleHelper.bottom;
            anchors.topMargin: 8;
            anchors.left: parent.left;
            anchors.right: parent.right;
            height: 200;
            color: Qt.rgba(0, 0, 0, 0.5);

            Item {
                id: instructions01Container;
                anchors.fill: parent;
            
                HifiControlsUit.Button {
                    id: clipboardButton;
                    color: hifi.buttons.black;
                    colorScheme: hifi.colorSchemes.dark;
                    anchors.left: parent.left;
                    anchors.leftMargin: 30;
                    anchors.top: parent.top;
                    anchors.topMargin: 45;
                    height: 24;
                    width: height;
                    HiFiGlyphs {
                        text: hifi.glyphs.question;
                        // Size
                        size: parent.height*1.3;
                        // Anchors
                        anchors.fill: parent;
                        // Style
                        horizontalAlignment: Text.AlignHCenter;
                        color: enabled ? hifi.colors.blueHighlight : hifi.colors.faintGray;
                    }

                    onClicked: {
                        Window.copyToClipboard(keyFilePath.text);
                    }
                }
                RalewayRegular {
                    id: keyFilePath;
                    size: 18;
                    anchors.top: clipboardButton.top;
                    anchors.left: clipboardButton.right;
                    anchors.leftMargin: 8;
                    anchors.right: parent.right;
                    anchors.rightMargin: 30;
                    height: paintedHeight;
                    wrapMode: Text.WordWrap;
                    color: hifi.colors.blueHighlight;

                    onVisibleChanged: {
                        if (visible) {
                            commerce.getKeyFilePathIfExists();
                        }
                    }
                }

                // "Open Instructions" button
                HifiControlsUit.Button {
                    id: openInstructionsButton;
                    color: hifi.buttons.blue;
                    colorScheme: hifi.colorSchemes.dark;
                    anchors.top: keyFilePath.bottom;
                    anchors.topMargin: 30;
                    anchors.left: parent.left;
                    anchors.leftMargin: 30;
                    anchors.right: parent.right;
                    anchors.rightMargin: 30;
                    height: 40;
                    text: "Open Instructions for Later";
                    onClicked: {
                        instructions01Container.visible = false;
                        instructions02Container.visible = true;
                        keysReadyPageFinishButton.visible = true;
                        sendSignalToWallet({method: 'walletSetup_openInstructions'});
                    }
                }
            }

            Item {
                id: instructions02Container;
                anchors.fill: parent;
                visible: false;

                RalewayRegular {
                    text: "All set!<br>Instructions for backing up your keys have been opened on your desktop. " +
                    "Be sure to look them over after your session.";
                    size: 22;
                    anchors.fill: parent;
                    anchors.leftMargin: 30;
                    anchors.rightMargin: 30;
                    wrapMode: Text.WordWrap;
                    color: hifi.colors.white;
                    horizontalAlignment: Text.AlignHCenter;
                    verticalAlignment: Text.AlignVCenter;
                }
            }
        }

        // Text below checkbox
        RalewayRegular {
            id: explanationText;
            text: "To protect your privacy, you control your private keys. High Fidelity has no access to your private keys and cannot " +
            "recover them for you.<br><br><b>If they are lost, you will not be able to access your money or purchases.</b>";
            // Text size
            size: 20;
            // Anchors
            anchors.top: pathAndInstructionsContainer.bottom;
            anchors.topMargin: 24;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            anchors.right: parent.right;
            anchors.rightMargin: 16;
            height: paintedHeight;
            // Style
            color: hifi.colors.white;
            wrapMode: Text.WordWrap;
            // Alignment
            horizontalAlignment: Text.AlignHCenter;
            verticalAlignment: Text.AlignVCenter;
        }

        // Navigation Bar
        Item {
            // Size
            width: parent.width;
            height: 50;
            // Anchors:
            anchors.left: parent.left;
            anchors.bottom: parent.bottom;
            anchors.bottomMargin: 50;
            // "Finish" button
            HifiControlsUit.Button {
                id: keysReadyPageFinishButton;
                visible: false;
                color: hifi.buttons.blue;
                colorScheme: hifi.colorSchemes.dark;
                anchors.top: parent.top;
                anchors.bottom: parent.bottom;
                anchors.right: parent.right;
                anchors.rightMargin: 20;
                width: 200;
                text: "Finish";
                onClicked: {
                    root.visible = false;
                    sendSignalToWallet({method: 'walletSetup_finished'});
                }
            }
        }
    }
    //
    // PRIVATE KEYS READY END
    //

    //
    // FUNCTION DEFINITIONS START
    //
    signal sendSignalToWallet(var msg);
    //
    // FUNCTION DEFINITIONS END
    //
}
