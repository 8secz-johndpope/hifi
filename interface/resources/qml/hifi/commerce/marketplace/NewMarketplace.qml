//
//  NewMarketplace.qml
//
//  New Marketplace App
//
//  Created by Zach Fox on 2018-03-23
//  Copyright 2018 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

import Hifi 1.0 as Hifi
import QtQuick 2.6
import QtQuick.Controls 2.2
import "../common" as HifiCommerceCommon
import "qrc:////qml//styles-uit" as HifiStylesUit
import "qrc:////qml//controls-uit" as HifiControlsUit

Rectangle {
    HifiStylesUit.HifiConstants { id: hifi; }

    id: root;
    property string activeView: "initialize";
    property bool itemsReceived: false;

    // Style
    color: hifi.colors.darkGray;
    

    Connections {
        target: Commerce;

        onSecurityImageResult: {
            if (exists) {
                titleBarSecurityImage.source = "";
                titleBarSecurityImage.source = "image://security/securityImage";
            }
        }
    }
	
    Connections {
        target: Marketplace;

		onItemsResult: {
            if (result.current_page && result.status !== 'success') {
                console.log("Failed to get marketplace items", result.message);
			} else {
				// Looking at multiple items (i.e. the front page)
				if (result.current_page) {
					itemsModel.clear();
					itemsModel.append(result.data.items);

					root.activeView = "mainMarketplace";
				// Looking at individual item page
				} else {
					individualItem.itemId = result.id;
					individualItem.itemTitle = result.title;
					individualItem.imageUrl = result.large_preview_url;
					root.activeView = "individualItem";
				}
				
				root.itemsReceived = true;
			}
		}
	}

    Rectangle {
        id: initialize;
        visible: root.activeView === "initialize";
        anchors.top: titleBarContainer.bottom;
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right;
        color: root.color;

        Component.onCompleted: {
            Commerce.getSecurityImage();
        }
    }

    HifiCommerceCommon.CommerceLightbox {
        id: lightboxPopup;
        visible: false;
        anchors.fill: parent;
    }

    //
    // TITLE BAR START
    //
    Item {
        id: titleBarContainer;
        // Size
        width: root.width;
        height: 50;
        // Anchors
        anchors.left: parent.left;
        anchors.top: parent.top;

        // Title bar text
        HifiStylesUit.RalewaySemiBold {
            id: titleBarText;
            text: "Marketplace";
            // Text size
            size: hifi.fontSizes.overlayTitle;
            // Anchors
            anchors.top: parent.top;
            anchors.bottom: parent.bottom;
            anchors.left: parent.left;
            anchors.leftMargin: 16;
            width: paintedWidth;
            // Style
            color: hifi.colors.lightGrayText;
            // Alignment
            horizontalAlignment: Text.AlignHLeft;
            verticalAlignment: Text.AlignVCenter;
        }

        Image {
            id: titleBarSecurityImage;
            source: "";
            visible: titleBarSecurityImage.source !== "";
            anchors.right: parent.right;
            anchors.rightMargin: 6;
            anchors.top: parent.top;
            anchors.topMargin: 6;
            anchors.bottom: parent.bottom;
            anchors.bottomMargin: 6;
            width: height;
            mipmap: true;
            cache: false;

            MouseArea {
                enabled: titleBarSecurityImage.visible;
                anchors.fill: parent;
                onClicked: {
                    lightboxPopup.titleText = "Your Security Pic";
                    lightboxPopup.bodyImageSource = titleBarSecurityImage.source;
                    lightboxPopup.bodyText = lightboxPopup.securityPicBodyText;
                    lightboxPopup.button1text = "CLOSE";
                    lightboxPopup.button1method = "root.visible = false;"
                    lightboxPopup.visible = true;
                }
            }
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

    Rectangle {
        id: loading;
        z: 997;
        visible: !root.itemsReceived;
        anchors.top: titleBarContainer.bottom;
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.right: parent.right;
        color: root.color;

        // This object is always used in a popup.
        // This MouseArea is used to prevent a user from being
        //     able to click on a button/mouseArea underneath the popup/section.
        MouseArea {
            anchors.fill: parent;
            hoverEnabled: true;
            propagateComposedEvents: false;
        }
                
        AnimatedImage {
            id: loadingImage;
            source: "../common/images/loader-blue.gif"
            width: 74;
            height: width;
            anchors.verticalCenter: parent.verticalCenter;
            anchors.horizontalCenter: parent.horizontalCenter;
        }
    }
	
    ListModel {
        id: itemsModel;
    }

	ListView {
		id: itemsListView;
		visible: root.activeView === "mainMarketplace";
		clip: true;
        model: itemsModel;
        snapMode: ListView.SnapToItem;
		anchors.top: titleBarContainer.bottom;
		anchors.topMargin: 8;
		anchors.bottom: parent.bottom;
		anchors.left: parent.left;
		anchors.right: parent.right;

        delegate: MarketplaceItemCard {
            anchors.topMargin: 10;
            anchors.bottomMargin: 10;
			width: parent.width;
			height: 200;

			itemId: model.id;
			title: model.title;
			imageUrl: model.large_preview_url;

            Connections {
                onSendToParent: {
                    if (msg.method === 'marketplaceItemClicked') {
						root.itemsReceived = false;
						Marketplace.items(msg.itemId);
					} else {
						console.log("Unrecognized message from MarketplaceItemCard!");
					}
				}
			}
		}
	}

	Rectangle {
		id: individualItem;
		property string itemId;
		property string itemTitle;
		property string imageUrl;

		visible: root.activeView === "individualItem";
		anchors.top: titleBarContainer.bottom;
		anchors.topMargin: 8;
		anchors.bottom: parent.bottom;
		anchors.left: parent.left;
		anchors.right: parent.right;

		Rectangle {
            id: individualItem_titleBar;
			color: Qt.rgba(0, 0, 0, 0.8);
			anchors.top: parent.top;
			anchors.left: parent.left;
			anchors.right: parent.right;
			height: 40;
			
			HifiStylesUit.RalewayBold {
				id: itemTitle;
				text: individualItem.itemTitle;
				anchors.top: parent.top;
				anchors.topMargin: 4;
				anchors.left: parent.left;
				anchors.leftMargin: 8;
				anchors.right: parent.right;
				anchors.rightMargin: 8;
				height: parent.height;
				size: 24;
				color: hifi.colors.white;
				elide: Text.ElideRight;
				horizontalAlignment: Text.AlignLeft;
				verticalAlignment: Text.AlignTop;
			}
		}

		Image {
            id: individualItem_itemImage;
			source: individualItem.imageUrl;
			fillMode: Image.PreserveAspectCrop;
			anchors.top: individualItem_titleBar.bottom;
			anchors.left: parent.left;
			anchors.right: parent.right;
			height: width / 1.7;
		}

        HifiControlsUit.Button {
            id: individualItem_buyButton;
            color: hifi.buttons.blue;
            colorScheme: hifi.colorSchemes.dark;
            anchors.top: individualItem_itemImage.bottom;
			anchors.topMargin: 8;
            anchors.horizontalCenter: parent.horizontalCenter;
			width: 160;
            height: 44;
            text: "BUY"
            onClicked: {
                sendToScript({method: "buyItem", itemId: individualItem.itemId });
            }
        }

        HifiControlsUit.Button {
            id: individualItem_backButton;
            color: hifi.buttons.blue;
            colorScheme: hifi.colorSchemes.dark;
            anchors.bottom: parent.bottom;
			anchors.bottomMargin: 8;
            anchors.left: parent.left;
			anchors.leftMargin: 8;
			width: 130;
            height: 44;
            text: "BACK"
            onClicked: {
				root.itemsReceived = false;
				Marketplace.items(root.itemId);
				resetIndividualItem();
            }
        }
	}
	
    //
    // FUNCTION DEFINITIONS START
	//
	function resetIndividualItem() {
		individualItem.itemId = "";
		individualItem.itemTitle = "";
		individualItem.imageUrl = "";
	}

    //
    // Function Name: fromScript()
    //
    // Relevant Variables:
    // None
    //
    // Arguments:
    // message: The message sent from the app JavaScript.
    //     Messages are in format "{method, params}", like json-rpc.
    //
    // Description:
    // Called when a message is received from app .js.
    //
    function fromScript(message) {
        switch (message.method) {
        case "loadFrontPage":
			root.itemsReceived = false;
			Marketplace.items();
        case "loadItemInfo":
			root.itemsReceived = false;
			Marketplace.items(message.itemId);
        break;
        default:
            console.log('Unrecognized message from newMarketplace.js:', JSON.stringify(message));
			break;
		}
    }

    signal sendToScript(var message);

    //
    // FUNCTION DEFINITIONS END
    //
}
