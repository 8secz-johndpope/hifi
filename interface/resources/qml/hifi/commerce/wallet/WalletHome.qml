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
        color: hifi.colors.white;
        elide: Text.ElideRight;
        // Anchors
        anchors.top: parent.top;
        anchors.left: parent.left;
        anchors.leftMargin: 20;
        width: parent.width/2;
        height: 80;
    }

    // HFC Balance Container
    Item {
        id: hfcBalanceContainer;
        // Anchors
        anchors.top: parent.top;
        anchors.right: parent.right;
        anchors.leftMargin: 20;
        width: parent.width/2;
        height: 80;

        // "HFC" balance label
        FiraSansRegular {
            id: balanceLabel;
            text: "HFC";
            // Text size
            size: 20;
            // Anchors
            anchors.left: parent.left;
            anchors.top: parent.top;
            anchors.bottom: parent.bottom;
            width: paintedWidth;
            // Style
            color: hifi.colors.white;
            // Alignment
            horizontalAlignment: Text.AlignLeft;
            verticalAlignment: Text.AlignVCenter;
        }

        // Balance Text
        FiraSansRegular {
            id: balanceText;
            text: "--";
            // Text size
            size: 28;
            // Anchors
            anchors.top: balanceLabel.top;
            anchors.bottom: balanceLabel.bottom;
            anchors.left: balanceLabel.right;
            anchors.leftMargin: 10;
            anchors.right: parent.right;
            anchors.rightMargin: 4;
            // Style
            color: hifi.colors.white;
            // Alignment
            verticalAlignment: Text.AlignVCenter;

            onVisibleChanged: {
                if (visible) {
                    historyReceived = false;
                    commerce.balance();
                    commerce.history();
                }
            }
        }

        // "balance" text below field
        RalewayRegular {
            text: "BALANCE (HFC)";
            // Text size
            size: 14;
            // Anchors
            anchors.top: balanceLabel.top;
            anchors.topMargin: balanceText.paintedHeight + 10;
            anchors.bottom: balanceLabel.bottom;
            anchors.left: balanceText.left;
            anchors.right: balanceText.right;
            height: paintedHeight;
            // Style
            color: hifi.colors.white;
        }
    }

    // Recent Activity
    Rectangle {
        id: recentActivityContainer;
        anchors.left: parent.left;
        anchors.right: parent.right;
        anchors.bottom: parent.bottom;
        height: 440;
        color: hifi.colors.faintGray;

        RalewaySemiBold {
            id: recentActivityText;
            text: "Recent Activity";
            // Anchors
            anchors.top: parent.top;
            anchors.topMargin: 26;
            anchors.left: parent.left;
            anchors.leftMargin: 30;
            anchors.right: parent.right;
            anchors.rightMargin: 30;
            height: 30;
            // Text size
            size: 22;
            // Style
            color: hifi.colors.baseGray;
        }
        ListModel {
            id: transactionHistoryModel;
        }
        Item {
            anchors.top: recentActivityText.bottom;
            anchors.topMargin: 26;
            anchors.bottom: parent.bottom;
            anchors.left: parent.left;
            anchors.leftMargin: 24;
            anchors.right: parent.right;
            anchors.rightMargin: 24;

            HifiControlsUit.Separator {
                colorScheme: 1;
                anchors.left: parent.left;
                anchors.leftMargin: 6;
                anchors.right: parent.right;
                anchors.rightMargin: 6;
                anchors.top: parent.top;
            }

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
                    AnonymousProRegular {
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
                    colorScheme: 1;
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
