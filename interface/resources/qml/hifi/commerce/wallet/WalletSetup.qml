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
            color: hifi.colors.faintGray;
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
            color: hifi.colors.faintGray;
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
            color: hifi.colors.faintGray;
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
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right;

        // Text below title bar
        RalewaySemiBold {
            id: securityImageTitleHelper;
            text: "Choose a Security Pic:";
            // Text size
            size: 24;
            // Anchors
            anchors.top: parent.top;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            height: 50;
            width: paintedWidth;
            // Style
            color: hifi.colors.faintGray;
            // Alignment
            horizontalAlignment: Text.AlignHLeft;
            verticalAlignment: Text.AlignVCenter;
        }

        SecurityImageSelection {
            id: securityImageSelection;
            // Anchors
            anchors.top: securityImageTitleHelper.bottom;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            anchors.right: parent.right;
            anchors.rightMargin: 16;
            height: 280;

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
            anchors.leftMargin: 16;
            anchors.right: parent.right;
            anchors.rightMargin: 16;
            height: paintedHeight;
            // Style
            color: hifi.colors.faintGray;
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
                color: hifi.buttons.black;
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
        id: choosePassphraseContainer;
        visible: root.activeView === "step_3";
        // Anchors
        anchors.top: titleBarContainer.bottom;
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right;

        onVisibleChanged: {
            if (visible) {
                commerce.getWalletAuthenticatedStatus();
            }
        }

        // Text below title bar
        RalewaySemiBold {
            id: passphraseTitleHelper;
            text: "Choose a Secure Passphrase";
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
            color: hifi.colors.faintGray;
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
                color: hifi.buttons.black;
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
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right;

        // Text below title bar
        RalewaySemiBold {
            id: keysReadyTitleHelper;
            text: "Your Private Keys are Ready";
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
            color: hifi.colors.faintGray;
            // Alignment
            horizontalAlignment: Text.AlignHLeft;
            verticalAlignment: Text.AlignVCenter;
        }

        // Text below checkbox
        RalewayRegular {
            id: explanationText;
            text: "Your money and purchases are secured with private keys that only you have access to. " +
            "<b>If they are lost, you will not be able to access your money or purchases.</b><br><br>" +
            "<b>To protect your privacy, High Fidelity has no access to your private keys and cannot " +
            "recover them for any reason.<br><br>To safeguard your private keys, backup this file on a regular basis:</b>";
            // Text size
            size: 16;
            // Anchors
            anchors.top: keysReadyTitleHelper.bottom;
            anchors.topMargin: 16;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            anchors.right: parent.right;
            anchors.rightMargin: 16;
            height: paintedHeight;
            // Style
            color: hifi.colors.faintGray;
            wrapMode: Text.WordWrap;
            // Alignment
            horizontalAlignment: Text.AlignHLeft;
            verticalAlignment: Text.AlignVCenter;
        }

        HifiControlsUit.TextField {
            id: keyFilePath;
            anchors.top: explanationText.bottom;
            anchors.topMargin: 10;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            anchors.right: clipboardButton.left;
            height: 40;
            readOnly: true;

            onVisibleChanged: {
                if (visible) {
                    commerce.getKeyFilePathIfExists();
                }
            }
        }
        HifiControlsUit.Button {
            id: clipboardButton;
            color: hifi.buttons.black;
            colorScheme: hifi.colorSchemes.dark;
            anchors.right: parent.right;
            anchors.rightMargin: 16;
            anchors.top: keyFilePath.top;
            anchors.bottom: keyFilePath.bottom;
            width: height;
            HiFiGlyphs {
                text: hifi.glyphs.question;
                // Size
                size: parent.height*1.3;
                // Anchors
                anchors.fill: parent;
                // Style
                horizontalAlignment: Text.AlignHCenter;
                color: enabled ? hifi.colors.white : hifi.colors.faintGray;
            }

            onClicked: {
                Window.copyToClipboard(keyFilePath.text);
            }
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
            // "Next" button
            HifiControlsUit.Button {
                id: keysReadyPageNextButton;
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
