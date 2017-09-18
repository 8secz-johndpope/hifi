//
//  Help.qml
//  qml/hifi/commerce/wallet
//
//  Help
//
//  Created by Zach Fox on 2017-08-18
//  Copyright 2017 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

import Hifi 1.0 as Hifi
import QtQuick 2.5
import QtQuick.Controls 2.2
import "../../../styles-uit"
import "../../../controls-uit" as HifiControlsUit
import "../../../controls" as HifiControls

// references XXX from root context

Item {
    HifiConstants { id: hifi; }

    id: root;

    Hifi.QmlCommerce {
        id: commerce;
    }

    RalewaySemiBold {
        id: helpTitleText;
        text: "Help Topics";
        // Anchors
        anchors.top: parent.top;
        anchors.left: parent.left;
        anchors.leftMargin: 20;
        width: paintedWidth;
        height: 30;
        // Text size
        size: 18;
        // Style
        color: hifi.colors.blueHighlight;
    }
    HifiControlsUit.Button {
        id: clearCachedPassphraseButton;
        color: hifi.buttons.black;
        colorScheme: hifi.colorSchemes.dark;
        anchors.top: parent.top;
        anchors.left: helpTitleText.right;
        anchors.leftMargin: 20;
        height: 40;
        width: 150;
        text: "DBG: Clear Pass";
        onClicked: {
            commerce.setPassphrase("");
            sendSignalToWallet({method: 'passphraseReset'});
        }
    }
    HifiControlsUit.Button {
        id: resetButton;
        color: hifi.buttons.red;
        colorScheme: hifi.colorSchemes.dark;
        anchors.top: clearCachedPassphraseButton.top;
        anchors.left: clearCachedPassphraseButton.right;
        height: 40;
        width: 150;
        text: "DBG: RST Wallet";
        onClicked: {
            commerce.reset();
            sendSignalToWallet({method: 'walletReset'});
        }
    }

    ListModel {
        id: helpModel;

        ListElement {
            question: "What are private keys?"
            answer: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi iaculis pharetra porttitor."
        }
        ListElement {
            question: "Where are my private keys stored?"
            answer: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi iaculis pharetra porttitor."
        }
        ListElement {
            question: "What happens if I lose my passphrase?"
            answer: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi iaculis pharetra porttitor."
        }
        ListElement {
            question: "Do I get charged money when a transaction fails?"
            answer: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi iaculis pharetra porttitor."
        }
        ListElement {
            question: "How do I convert HFC to other currencies?"
            answer: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi iaculis pharetra porttitor."
        }
    }

    ListView {
        id: helpListView;
        ScrollBar.vertical: ScrollBar {
        policy: helpListView.contentHeight > helpListView.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded;
        parent: helpListView.parent;
        anchors.top: helpListView.top;
        anchors.right: helpListView.right;
        anchors.bottom: helpListView.bottom;
        width: 20;
        }
        anchors.top: helpTitleText.bottom;
        anchors.topMargin: 30;
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right
        clip: true;
        model: helpModel;
        delegate: Item {
            property bool isExpanded: false;
            width: parent.width;
            height: isExpanded ? childrenRect.height : questionContainer.height;

            HifiControlsUit.Separator {
            colorScheme: 1;
            visible: index === 0;
            anchors.left: parent.left;
            anchors.right: parent.right;
            anchors.top: parent.top;
            }

            Item {
                id: questionContainer;
                anchors.top: parent.top;
                anchors.left: parent.left;
                width: parent.width;
                height: questionText.paintedHeight + 50;
            
                RalewaySemiBold {
                    id: plusMinusButton;
                    text: isExpanded ? "-" : "+";
                    // Anchors
                    anchors.top: parent.top;
                    anchors.topMargin: isExpanded ? -9 : 0;
                    anchors.bottom: parent.bottom;
                    anchors.left: parent.left;
                    width: 60;
                    // Text size
                    size: 60;
                    // Style
                    color: hifi.colors.white;
                    horizontalAlignment: Text.AlignHCenter;
                    verticalAlignment: Text.AlignVCenter;
                }

                RalewaySemiBold {
                    id: questionText;
                    text: model.question;
                    size: 18;
                    anchors.verticalCenter: parent.verticalCenter;
                    anchors.left: plusMinusButton.right;
                    anchors.leftMargin: 4;
                    anchors.right: parent.right;
                    anchors.rightMargin: 10;
                    wrapMode: Text.WordWrap;
                    height: paintedHeight;
                    color: hifi.colors.white;
                    verticalAlignment: Text.AlignVCenter;
                }

                MouseArea {
                    id: securityTabMouseArea;
                    anchors.fill: parent;
                    onClicked: {
                        isExpanded = !isExpanded;
                    }
                }
            }

            Rectangle {
                id: answerContainer;
                visible: isExpanded;
                color: Qt.rgba(0, 0, 0, 0.5);
                anchors.top: questionContainer.bottom;
                anchors.left: parent.left;
                anchors.right: parent.right;
                height: answerText.paintedHeight + 50;

                RalewayRegular {
                    id: answerText;
                    text: model.answer;
                    size: 18;
                    anchors.verticalCenter: parent.verticalCenter;
                    anchors.left: parent.left;
                    anchors.leftMargin: 80;
                    anchors.right: parent.right;
                    anchors.rightMargin: 10;
                    wrapMode: Text.WordWrap;
                    height: paintedHeight;
                    color: hifi.colors.white;
                }
            }

            HifiControlsUit.Separator {
            colorScheme: 1;
                anchors.left: parent.left;
                anchors.right: parent.right;
                anchors.bottom: parent.bottom;
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
