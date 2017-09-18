//
//  PassphraseModal.qml
//  qml/hifi/commerce/wallet
//
//  PassphraseModal
//
//  Created by Zach Fox on 2017-08-31
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

// references XXX from root context

Item {
    HifiConstants { id: hifi; }

    id: root;
    z: 998;
    property bool keyboardRaised: false;
    property string titleBarIcon: "";
    property string titleBarText: "";

    Image {
        anchors.fill: parent;
        source: "images/wallet-bg.jpg";
    }

    Hifi.QmlCommerce {
        id: commerce;

        onSecurityImageResult: {
            passphraseModalSecurityImage.source = "";
            passphraseModalSecurityImage.source = "image://security/securityImage";
        }

        onWalletAuthenticatedStatusResult: {
            submitPassphraseInputButton.enabled = true;
            if (!isAuthenticated) {
                errorText.text = "Authentication failed - please try again.";
            } else {
                root.visible = false;
            }
        }
    }

    // This object is always used in a popup.
    // This MouseArea is used to prevent a user from being
    //     able to click on a button/mouseArea underneath the popup.
    MouseArea {
        anchors.fill: parent;
        propagateComposedEvents: false;
    }
    
    // This will cause a bug -- if you bring up passphrase selection in HUD mode while
    // in HMD while having HMD preview enabled, then move, then finish passphrase selection,
    // HMD preview will stay off.
    // TODO: Fix this unlikely bug
    onVisibleChanged: {
        if (visible) {
            passphraseField.focus = true;
            sendSignalToParent({method: 'disableHmdPreview'});
        } else {
            sendSignalToParent({method: 'maybeEnableHmdPreview'});
        }
    }

    Item {
        id: titleBar;
        anchors.top: parent.top;
        anchors.left: parent.left;
        anchors.right: parent.right;
        height: 50;
        Image {
            id: titleBarIcon;
            anchors.top: parent.top;
            anchors.left: parent.left;
            anchors.bottom: parent.bottom;
            width: height;
            fillMode: Image.PreserveAspectFit;
            mipmap: true;
            source: root.titleBarIcon;
        }
        RalewaySemiBold {
            id: titleBarText;
            text: root.titleBarText;
            anchors.top: parent.top;
            anchors.left: titleBarIcon.right;
            anchors.leftMargin: 8;
            anchors.bottom: parent.bottom;
            anchors.right: parent.right;
            size: 20;
            color: hifi.colors.white;
            verticalAlignment: Text.AlignVCenter;
        }
    }

    Item {
        id: passphraseContainer;
        anchors.top: titleBar.bottom;
        anchors.left: parent.left;
        anchors.leftMargin: 8;
        anchors.right: parent.right;
        anchors.rightMargin: 8;
        height: 250;

        RalewaySemiBold {
            id: instructionsText;
            text: "Please Enter Your Passphrase";
            size: 24;
            anchors.top: parent.top;
            anchors.topMargin: 30;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            width: passphraseField.width;
            height: paintedHeight;
            // Style
            color: hifi.colors.white;
            // Alignment
            horizontalAlignment: Text.AlignLeft;
        }

        // Error text above buttons
        RalewaySemiBold {
            id: errorText;
            text: "";
            // Text size
            size: 16;
            // Anchors
            anchors.bottom: passphraseField.top;
            anchors.bottomMargin: 4;
            anchors.left: passphraseField.left;
            anchors.right: parent.right;
            height: 20;
            // Style
            color: hifi.colors.redHighlight;
        }

        HifiControlsUit.TextField {
            id: passphraseField;
            anchors.top: instructionsText.bottom;
            anchors.topMargin: 40;
            anchors.left: instructionsText.left;
            width: 260;
            height: 50;
            echoMode: TextInput.Password;
            placeholderText: "passphrase";

            onFocusChanged: {
                root.keyboardRaised = focus;
            }

            MouseArea {
                anchors.fill: parent;

                onClicked: {
                    parent.focus = true;
                    root.keyboardRaised = true;
                }
            }

            onAccepted: {
                submitPassphraseInputButton.enabled = false;
                commerce.setPassphrase(passphraseField.text);
            }
        }

        // Show passphrase text
        HifiControlsUit.CheckBox {
            id: showPassphrase;
            colorScheme: hifi.colorSchemes.dark;
            anchors.left: passphraseField.left;
            anchors.top: passphraseField.bottom;
            anchors.topMargin: 8;
            height: 30;
            text: "Show passphrase";
            boxSize: 24;
            onClicked: {
                passphraseField.echoMode = checked ? TextInput.Normal : TextInput.Password;
            }
        }

        // Security Image
        Item {
            id: securityImageContainer;
            // Anchors
            anchors.top: passphraseField.top;
            anchors.left: passphraseField.right;
            anchors.leftMargin: 8;
            anchors.right: parent.right;
            anchors.rightMargin: 8;
            height: 145;
            Image {
                id: passphraseModalSecurityImage;
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
                anchors.left: passphraseModalSecurityImage.left;
                anchors.right: passphraseModalSecurityImage.right;
                anchors.bottom: parent.bottom;
                height: 24;
                // Lock icon
                Image {
                    id: lockIcon;
                    source: "images/lockIcon.png";
                    anchors.bottom: parent.bottom;
                    anchors.left: parent.left;
                    anchors.leftMargin: 30;
                    height: 22;
                    width: height;
                    mipmap: true;
                    verticalAlignment: Text.AlignBottom;
                }
                // "Security image" text below pic
                RalewayRegular {
                    id: securityImageText;
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
                    color: hifi.colors.white;
                    // Alignment
                    horizontalAlignment: Text.AlignRight;
                    verticalAlignment: Text.AlignBottom;
                }
            }
        }
        
        //
        // ACTION BUTTONS START
        //
        Item {
            id: passphrasePopupActionButtonsContainer;
            // Anchors
            anchors.left: passphraseField.left;
            anchors.right: passphraseField.right;
            anchors.bottom: parent.bottom;

            // "Cancel" button
            HifiControlsUit.Button {
                id: cancelPassphraseInputButton;
                color: hifi.buttons.noneBorderlessWhite;
                colorScheme: hifi.colorSchemes.dark;
                anchors.bottom: parent.bottom;
                height: 40;
                anchors.left: parent.left;
                width: parent.width/2 - 4;
                text: "Cancel"
                onClicked: {
                    sendSignalToParent({method: 'passphrasePopup_cancelClicked'});
                }
            }

            // "Submit" button
            HifiControlsUit.Button {
                id: submitPassphraseInputButton;
                color: hifi.buttons.blue;
                colorScheme: hifi.colorSchemes.dark;
                anchors.bottom: parent.bottom;
                height: 40;
                anchors.right: parent.right;
                width: parent.width/2 -4;
                text: "Submit"
                onClicked: {
                    submitPassphraseInputButton.enabled = false;
                    commerce.setPassphrase(passphraseField.text);
                }
            }
        }
    }

    Item {
        id: keyboardContainer;
        z: 999;
        visible: keyboard.raised;
        property bool punctuationMode: false;
        anchors {
            bottom: parent.bottom;
            left: parent.left;
            right: parent.right;
        }

        Image {
            id: lowerKeyboardButton;
            source: "images/lowerKeyboard.png";
            anchors.horizontalCenter: parent.horizontalCenter;
            anchors.bottom: keyboard.top;
            height: 30;
            width: 120;

            MouseArea {
                anchors.fill: parent;

                onClicked: {
                    root.keyboardRaised = false;
                }
            }
        }

        HifiControlsUit.Keyboard {
            id: keyboard;
            raised: HMD.mounted && root.keyboardRaised;
            numeric: parent.punctuationMode;
            anchors {
                bottom: parent.bottom;
                left: parent.left;
                right: parent.right;
            }
        }
    }

    signal sendSignalToParent(var msg);
}
