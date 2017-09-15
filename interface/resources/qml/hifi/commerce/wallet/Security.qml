//
//  Security.qml
//  qml/hifi/commerce/wallet
//
//  Security
//
//  Created by Zach Fox on 2017-08-18
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

    Hifi.QmlCommerce {
        id: commerce;

        onSecurityImageResult: {
            if (exists) { // "If security image is set up"
                var path = "image://security/securityImage";
                topSecurityImage.source = "";
                topSecurityImage.source = path;
                changeSecurityImageImage.source = "";
                changeSecurityImageImage.source = path;
            }
        }

        onKeyFilePathIfExistsResult: {
            keyFilePath.text = path;
        }
    }

    SecurityImageModel {
        id: securityImageModel;
    }

    // Username Text
    RalewayRegular {
        id: usernameText;
        text: Account.username;
        // Text size
        size: 24;
        // Style
        color: hifi.colors.faintGray;
        elide: Text.ElideRight;
        // Anchors
        anchors.top: securityImageContainer.top;
        anchors.bottom: securityImageContainer.bottom;
        anchors.left: parent.left;
        anchors.right: securityImageContainer.left;
    }
    

    // Security Image
    Item {
        id: securityImageContainer;
        // Anchors
        anchors.top: instructionsText.top;
        anchors.left: passphraseField.right;
        anchors.leftMargin: 8;
        anchors.right: parent.right;
        anchors.rightMargin: 8;
        anchors.bottom: passphraseFieldAgain.bottom;
        Image {
            id: topSecurityImage;
            anchors.top: parent.top;
            anchors.left: parent.left;
            anchors.right: parent.right;
            anchors.bottom: iconAndTextContainer.top;
            fillMode: Image.PreserveAspectFit;
            mipmap: true;
            source: "image://security/securityImage";
            cache: false;
            onVisibleChanged: {
                commerce.getSecurityImage();
            }
        }
        Item {
            id: iconAndTextContainer;
            anchors.left: topSecurityImage.left;
            anchors.right: topSecurityImage.right;
            anchors.bottom: parent.bottom;
            height: 22;
            // Lock icon
            Image {
                id: lockIcon;
                source: "images/lockIcon.png";
                anchors.bottom: parent.bottom;
                anchors.left: parent.left;
                anchors.leftMargin: 26;
                height: 22;
                width: height;
                mipmap: true;
                verticalAlignment: Text.AlignBottom;
            }
            // "Security image" text below pic
            RalewayRegular {
                id: securityPicText;
                text: "SECURITY PIC";
                // Text size
                size: 12;
                // Anchors
                anchors.bottom: parent.bottom;
                anchors.right: parent.right;
                anchors.rightMargin: lockIcon.anchors.leftMargin;
                width: paintedWidth;
                height: 22;
                // Style
                color: hifi.colors.faintGray;
                // Alignment
                horizontalAlignment: Text.AlignRight;
                verticalAlignment: Text.AlignBottom;
            }
        }
    }

    Item {
        id: securityContainer;
        anchors.top: securityImageContainer.bottom;
        anchors.topMargin: 20;
        anchors.left: parent.left;
        anchors.right: parent.right;
        height: childrenRect.height;

        RalewayRegular {
            id: securityText;
            text: "Security";
            // Anchors
            anchors.top: parent.top;
            anchors.left: parent.left;
            anchors.right: parent.right;
            height: 30;
            // Text size
            size: 22;
            // Style
            color: hifi.colors.faintGray;
        }

        Item {
            id: changePassphraseContainer;
            anchors.top: securityText.bottom;
            anchors.topMargin: 16;
            anchors.left: parent.left;
            anchors.right: parent.right;
            height: 75;

            Image {
                id: changePassphraseImage;
                // Anchors
                anchors.top: parent.top;
                anchors.left: parent.left;
                height: parent.height;
                width: height;
                source: "images/lockIcon.png";
                fillMode: Image.PreserveAspectFit;
                mipmap: true;
                cache: false;
                visible: false;
            }
            ColorOverlay {
                anchors.fill: changePassphraseImage;
                source: changePassphraseImage;
                color: "white"
            }
            // "Change Passphrase" button
            HifiControlsUit.Button {
                id: changePassphraseButton;
                color: hifi.buttons.black;
                colorScheme: hifi.colorSchemes.dark;
                anchors.verticalCenter: parent.verticalCenter;
                anchors.left: changePassphraseImage.right;
                anchors.leftMargin: 16;
                width: 250;
                height: 50;
                text: "Change My Passphrase";
                onClicked: {
                    sendSignalToWallet({method: 'walletSecurity_changePassphrase'});
                }
            }
        }

        Item {
            id: changeSecurityImageContainer;
            anchors.top: changePassphraseContainer.bottom;
            anchors.topMargin: 8;
            anchors.left: parent.left;
            anchors.right: parent.right;
            height: 75;

            Image {
                id: changeSecurityImageImage;
                // Anchors
                anchors.top: parent.top;
                anchors.left: parent.left;
                height: parent.height;
                width: height;
                fillMode: Image.PreserveAspectFit;
                mipmap: true;
                cache: false;
                source: "image://security/securityImage";
            }
            // "Change Security Image" button
            HifiControlsUit.Button {
                id: changeSecurityImageButton;
                color: hifi.buttons.black;
                colorScheme: hifi.colorSchemes.dark;
                anchors.verticalCenter: parent.verticalCenter;
                anchors.left: changeSecurityImageImage.right;
                anchors.leftMargin: 16;
                width: 250;
                height: 50;
                text: "Change My Security Image";
                onClicked: {
                    sendSignalToWallet({method: 'walletSecurity_changeSecurityImage'});
                }
            }
        }
    }

    Item {
        id: yourPrivateKeysContainer;
        anchors.top: securityContainer.bottom;
        anchors.topMargin: 20;
        anchors.left: parent.left;
        anchors.right: parent.right;
        height: childrenRect.height;

        RalewaySemiBold {
            id: yourPrivateKeysText;
            text: "Your Private Keys";
            // Anchors
            anchors.top: parent.top;
            anchors.left: parent.left;
            anchors.right: parent.right;
            height: 30;
            // Text size
            size: 22;
            // Style
            color: hifi.colors.faintGray;
        }

        // Text below "your private keys"
        RalewayRegular {
            id: explanitoryText;
            text: "Your money and purchases are secured with private keys that only you " +
            "have access to. <b>If they are lost, you will not be able to access your money or purchases. " +
            "To safeguard your private keys, back up this file regularly:</b>";
            // Text size
            size: 18;
            // Anchors
            anchors.top: yourPrivateKeysText.bottom;
            anchors.topMargin: 10;
            anchors.left: parent.left;
            anchors.right: parent.right;
            height: paintedHeight;
            // Style
            color: hifi.colors.faintGray;
            wrapMode: Text.WordWrap;
            // Alignment
            horizontalAlignment: Text.AlignLeft;
            verticalAlignment: Text.AlignVCenter;
        }
        HifiControlsUit.TextField {
            id: keyFilePath;
            anchors.top: explanitoryText.bottom;
            anchors.topMargin: 10;
            anchors.left: parent.left;
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
    // message: The message sent from the JavaScript.
    //     Messages are in format "{method, params}", like json-rpc.
    //
    // Description:
    // Called when a message is received from a script.
    //
    function fromScript(message) {
        switch (message.method) {
            default:
                console.log('Unrecognized message from wallet.js:', JSON.stringify(message));
        }
    }
    signal sendSignalToWallet(var msg);
    //
    // FUNCTION DEFINITIONS END
    //
}
