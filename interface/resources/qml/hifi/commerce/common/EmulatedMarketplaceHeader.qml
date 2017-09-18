//
//  EmulatedMarketplaceHeader.qml
//  qml/hifi/commerce/common
//
//  EmulatedMarketplaceHeader
//
//  Created by Zach Fox on 2017-09-18
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

Rectangle {
    HifiConstants { id: hifi; }

    id: root;

    // Style
    color: hifi.colors.white;

    Hifi.QmlCommerce {
        id: commerce;

        onLoginStatusResult: {
            if (!isLoggedIn) {
                sendToParent({method: "needsLogIn"});
            }
        }

        onAccountResult: {
            if (result.status === "success") {
                commerce.getKeyFilePathIfExists();
            } else {
                // unsure how to handle a failure here. We definitely cannot proceed.
            }
        }
    }

    Component.onCompleted: {
        commerce.getLoginStatus();
    }

    Connections {
        target: GlobalServices
        onMyUsernameChanged: {
            commerce.getLoginStatus();
        }
    }

    Image {
        id: marketplaceHeaderImage;
        source: "images/marketplaceHeaderImage.png";
        anchors.top: parent.top;
        anchors.topMargin: 8;
        anchors.bottom: parent.bottom;
        anchors.bottomMargin: 10;
        anchors.left: parent.left;
        width: 200;
        fillMode: Image.PreserveAspectFit;
    }

    Item {
        id: buttonAndUsernameContainer;
        anchors.left: marketplaceHeaderImage.right;
        anchors.leftMargin: 8;
        anchors.top: parent.top;
        anchors.bottom: parent.bottom;
        anchors.bottomMargin: 10;
        anchors.right: parent.right;
        anchors.rightMargin: 12;

        Rectangle {
            id: myPurchasesLink;
            anchors.right: myUsernameButton.left;
            anchors.rightMargin: 8;
            anchors.verticalCenter: parent.verticalCenter;
            height: 40;
            width: myPurchasesText.paintedWidth + 10;

            RalewaySemiBold {
                id: myPurchasesText;
                text: "My Purchases";
                // Text size
                size: 18;
                // Style
                color: hifi.colors.blueHighlight;
                horizontalAlignment: Text.AlignHCenter;
                verticalAlignment: Text.AlignVCenter;
                // Anchors
                anchors.centerIn: parent;
            }

            MouseArea {
                anchors.fill: parent;
                hoverEnabled: enabled;
                onClicked: {
                    
                }
                onEntered: myPurchasesText.color = hifi.colors.blueAccent;
                onExited: myPurchasesText.color = hifi.colors.blueHighlight;
            }
        }

        Rectangle {
            id: myUsernameButton;
            anchors.right: parent.right;
            anchors.verticalCenter: parent.verticalCenter;
            height: 40;
            width: usernameText.paintedWidth + 40;
            color: "white";
            radius: 4;
            border.width: 1;
            border.color: hifi.colors.lightGray;

            // Username Text
            RalewayRegular {
                id: usernameText;
                text: Account.username;
                // Text size
                size: 18;
                // Style
                color: hifi.colors.baseGray;
                elide: Text.ElideRight;
                horizontalAlignment: Text.AlignHCenter;
                verticalAlignment: Text.AlignVCenter;
                // Anchors
                anchors.centerIn: parent;
            }

            MouseArea {
                anchors.fill: parent;
                hoverEnabled: enabled;
                onClicked: {
                    
                }
                onEntered: usernameText.color = hifi.colors.baseGrayShadow;
                onExited: usernameText.color = hifi.colors.baseGray;
            }
        }
    }
    
    LinearGradient {
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right;
        height: 10;
        start: Qt.point(0, 0);
        end: Qt.point(0, height);
        gradient: Gradient {
            GradientStop { position: 0.0; color: hifi.colors.lightGrayText }
            GradientStop { position: 1.0; color: hifi.colors.white }
        }
    }


    //
    // FUNCTION DEFINITIONS START
    //
    signal sendToParent(var msg);
    //
    // FUNCTION DEFINITIONS END
    //
}
