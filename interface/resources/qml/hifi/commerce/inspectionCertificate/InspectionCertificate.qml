//
//  InspectionCertificate.qml
//  qml/hifi/commerce/inspectionCertificate
//
//  InspectionCertificate
//
//  Created by Zach Fox on 2017-09-14
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

// references XXX from root context

Rectangle {
    HifiConstants { id: hifi; }

    id: root;
    property string marketplaceId: "";
    property string itemName: "--";
    property string itemOwner: "--";
    property string itemEdition: "--";
    // Style
    color: hifi.colors.baseGray;
    Hifi.QmlCommerce {
        id: commerce;
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
        RalewaySemiBold {
            id: titleBarText;
            text: "Certificate";
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

        // Separator
        HifiControlsUit.Separator {
            anchors.left: parent.left;
            anchors.right: parent.right;
            anchors.bottom: parent.bottom;
        }
    }
    //
    // TITLE BAR END
    //

    //
    // "CERTIFICATE" START
    //
    Item {
        id: certificateContainer;
        anchors.top: titleBarContainer.bottom;
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right;

        RalewaySemiBold {
            id: itemNameHeader;
            text: "Item Name";
            // Text size
            size: 20;
            // Anchors
            anchors.top: parent.top;
            anchors.topMargin: 12;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            anchors.right: parent.right;
            anchors.rightMargin: 16;
            height: paintedHeight;
            // Style
            color: hifi.colors.faintGray;
        }
        RalewayRegular {
            id: itemName;
            text: root.itemName;
            // Text size
            size: 24;
            // Anchors
            anchors.top: itemNameHeader.bottom;
            anchors.topMargin: 4;
            anchors.left: itemNameHeader.left;
            anchors.right: itemNameHeader.right;
            height: paintedHeight;
            // Style
            color: hifi.colors.faintGray;
        }
        // "Show In Marketplace" button
        HifiControlsUit.Button {
            id: showInMarketplaceButton;
            color: hifi.buttons.blue;
            colorScheme: hifi.colorSchemes.dark;
            anchors.top: itemName.bottom;
            anchors.topMargin: 4;
            anchors.left: itemName.left;
            width: 200;
            height: 50;
            text: "View In Marketplace"
            onClicked: {
                sendToScript({method: 'inspectionCertificate_showInMarketplaceClicked', itemId: root.marketplaceId});
            }
        }

        RalewaySemiBold {
            id: ownedByHeader;
            text: "Owned By";
            // Text size
            size: 18;
            // Anchors
            anchors.top: showInMarketplaceButton.bottom;
            anchors.topMargin: 20;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            anchors.right: parent.right;
            anchors.rightMargin: 16;
            height: paintedHeight;
            // Style
            color: hifi.colors.faintGray;
        }
        RalewayRegular {
            id: ownedBy;
            text: root.itemOwner;
            // Text size
            size: 20;
            // Anchors
            anchors.top: ownedByHeader.bottom;
            anchors.topMargin: 4;
            anchors.left: ownedByHeader.left;
            anchors.right: ownedByHeader.right;
            height: paintedHeight;
            // Style
            color: hifi.colors.faintGray;
        }

        RalewaySemiBold {
            id: editionHeader;
            text: "Edition";
            // Text size
            size: 18;
            // Anchors
            anchors.top: ownedBy.bottom;
            anchors.topMargin: 20;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            anchors.right: parent.right;
            anchors.rightMargin: 16;
            height: paintedHeight;
            // Style
            color: hifi.colors.faintGray;
        }
        RalewayRegular {
            id: edition;
            text: root.itemEdition;
            // Text size
            size: 20;
            // Anchors
            anchors.top: editionHeader.bottom;
            anchors.topMargin: 4;
            anchors.left: editionHeader.left;
            anchors.right: editionHeader.right;
            height: paintedHeight;
            // Style
            color: hifi.colors.faintGray;
        }

        RalewayRegular {
            id: errorText;
            text: "Here we will display some text if there's an <b>error</b> with the certificate " +
            "(DMCA takedown, invalid cert, location of item updated)";
            // Text size
            size: 20;
            // Anchors
            anchors.top: edition.bottom;
            anchors.topMargin: 40;
            anchors.left: edition.left;
            anchors.right: edition.right;
            anchors.bottom: parent.bottom;
            // Style
            wrapMode: Text.WordWrap;
            color: hifi.colors.redHighlight;
            verticalAlignment: Text.AlignTop;
        }
    }
    //
    // "CERTIFICATE" END
    //

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
            case 'inspectionCertificate_setMarketplaceId':
                root.marketplaceId = message.marketplaceId;
            break;
            case 'inspectionCertificate_setItemInfo':
                root.itemName = message.itemName;
                root.itemOwner = message.itemOwner;
                root.itemEdition = message.itemEdition;
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
