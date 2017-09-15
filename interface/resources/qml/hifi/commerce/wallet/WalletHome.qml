//
//  WalletHome.qml
//  qml/hifi/commerce/wallet
//
//  WalletHome
//
//  Created by Zach Fox on 2017-08-18
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
    property bool historyReceived: false;

    Hifi.QmlCommerce {
        id: commerce;

        onSecurityImageResult: {
            if (exists) {
                // just set the source again (to be sure the change was noticed)
                securityImage.source = "";
                securityImage.source = "image://security/securityImage";
            }
        }

        onBalanceResult : {
            balanceText.text = result.data.balance;
        }

        onHistoryResult : {
            historyReceived = true;
            if (result.status === 'success') {
                transactionHistoryModel.clear();
                transactionHistoryModel.append(result.data.history);
            }
        }
    }

    SecurityImageModel {
        id: securityImageModel;
    }

    Connections {
        target: GlobalServices
        onMyUsernameChanged: {
            usernameText.text = Account.username;
        }
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
        anchors.right: hfcBalanceContainer.left;
    }

    // HFC Balance Container
    Item {
        id: hfcBalanceContainer;
        // Anchors
        anchors.top: securityImageContainer.top;
        anchors.right: securityImageContainer.left;
        anchors.rightMargin: 16;
        width: 175;
        height: 60;
        Rectangle {
            id: hfcBalanceField;
            color: hifi.colors.darkGray;
            anchors.right: parent.right;
            anchors.left: parent.left;
            anchors.bottom: parent.bottom;
            height: parent.height - 15;

            // "HFC" balance label
            FiraSansRegular {
                id: balanceLabel;
                text: "HFC";
                // Text size
                size: 20;
                // Anchors
                anchors.top: parent.top;
                anchors.bottom: parent.bottom;
                anchors.right: hfcBalanceField.right;
                anchors.rightMargin: 4;
                width: paintedWidth;
                // Style
                color: hifi.colors.lightGrayText;
                // Alignment
                horizontalAlignment: Text.AlignRight;
                verticalAlignment: Text.AlignVCenter;

                onVisibleChanged: {
                    if (visible) {
                        historyReceived = false;
                        commerce.balance();
                        commerce.history();
                    }
                }
            }

            // Balance Text
            FiraSansSemiBold {
                id: balanceText;
                text: "--";
                // Text size
                size: 28;
                // Anchors
                anchors.top: parent.top;
                anchors.bottom: parent.bottom;
                anchors.left: parent.left;
                anchors.right: balanceLabel.left;
                anchors.rightMargin: 4;
                // Style
                color: hifi.colors.lightGrayText;
                // Alignment
                horizontalAlignment: Text.AlignRight;
                verticalAlignment: Text.AlignVCenter;
            }
        }
        // "balance" text above field
        RalewayRegular {
            text: "balance";
            // Text size
            size: 12;
            // Anchors
            anchors.top: parent.top;
            anchors.bottom: hfcBalanceField.top;
            anchors.bottomMargin: 4;
            anchors.left: hfcBalanceField.left;
            anchors.right: hfcBalanceField.right;
            // Style
            color: hifi.colors.faintGray;
            // Alignment
            horizontalAlignment: Text.AlignLeft;
            verticalAlignment: Text.AlignVCenter;
        }
    }

    // Security Image
    Item {
        id: securityImageContainer;
        // Anchors
        anchors.top: parent.top;
        anchors.right: parent.right;
        width: 75;
        height: childrenRect.height;
        Image {
            id: securityImage;
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
            anchors.left: securityImage.left;
            anchors.right: securityImage.right;
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

    // Recent Activity
    Item {
        id: recentActivityContainer;
        anchors.top: securityImageContainer.bottom;
        anchors.topMargin: 8;
        anchors.left: parent.left;
        anchors.right: parent.right;
        anchors.bottom: parent.bottom;

        RalewayRegular {
            id: recentActivityText;
            text: "Recent Activity";
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
        ListModel {
            id: transactionHistoryModel;
        }
        Rectangle {
            anchors.top: recentActivityText.bottom;
            anchors.topMargin: 4;
            anchors.bottom: parent.bottom;
            anchors.left: parent.left;
            anchors.right: parent.right;
            color: "white";

            ListView {
                id: transactionHistory;
                anchors.centerIn: parent;
                width: parent.width - 12;
                height: parent.height - 12;
                visible: transactionHistoryModel.count !== 0;
                clip: true;
                model: transactionHistoryModel;
                delegate: Item {
                    width: parent.width;
                    height: transactionText.height + 30;
                    FiraSansRegular {
                        id: transactionText;
                        text: model.text;
                        // Style
                        size: 18;
                        width: parent.width;
                        height: paintedHeight;
                        anchors.verticalCenter: parent.verticalCenter;
                        color: "black";
                        wrapMode: Text.WordWrap;
                        // Alignment
                        horizontalAlignment: Text.AlignLeft;
                        verticalAlignment: Text.AlignVCenter;
                    }

                    HifiControlsUit.Separator {
                        anchors.left: parent.left;
                        anchors.right: parent.right;
                        anchors.bottom: parent.bottom;
                    }
                }
                onAtYEndChanged: {
                    if (transactionHistory.atYEnd) {
                        console.log("User scrolled to the bottom of 'Recent Activity'.");
                        // Grab next page of results and append to model
                    }
                }
            }

            // This should never be visible (since you immediately get 100 HFC)
            FiraSansRegular {
                id: emptyTransationHistory;
                size: 24;
                visible: !transactionHistory.visible && root.historyReceived;
                text: "Recent Activity Unavailable";
                anchors.fill: parent;
                horizontalAlignment: Text.AlignHCenter;
                verticalAlignment: Text.AlignVCenter;
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
