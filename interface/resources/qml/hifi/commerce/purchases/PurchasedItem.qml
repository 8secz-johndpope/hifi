//
//  PurchasedItem.qml
//  qml/hifi/commerce/purchases
//
//  PurchasedItem
//
//  Created by Zach Fox on 2017-08-25
//  Copyright 2017 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

import Hifi 1.0 as Hifi
import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import "../../../styles-uit"
import "../../../controls-uit" as HifiControlsUit
import "../../../controls" as HifiControls
import "../wallet" as HifiWallet
import TabletScriptingInterface 1.0

Item {
    HifiConstants { id: hifi; }

    id: root;
    property string purchaseStatus;
    property string itemName;
    property string itemId;
    property string itemPreviewImageUrl;
    property string itemHref;
    property string certificateId;
    property int displayedItemCount;
    property int itemEdition;
    property int numberSold;
    property int limitedRun;
    property string itemType;
    property var itemTypesArray: ["entity", "wearable", "contentSet", "app", "avatar"];
    property var buttonTextNormal: ["REZ", "WEAR", "REPLACE", "INSTALL", "WEAR"];
    property var buttonTextClicked: ["REZZED", "WORN", "REPLACED", "INSTALLED", "WORN"]
    property var buttonGlyph: [hifi.glyphs.wand, hifi.glyphs.hat, hifi.glyphs.globe, hifi.glyphs.install, hifi.glyphs.avatar];
    property bool showConfirmation: false;
    property bool hasPermissionToRezThis;
    property bool cardBackVisible;
    property bool isInstalled;
    property string upgradeUrl;
    property string upgradeTitle;
    property bool isShowingMyItems;

    property string originalStatusText;
    property string originalStatusColor;

    height: 102;
    width: parent.width;

    Connections {
        target: Commerce;
        
        onContentSetChanged: {
            if (contentSetHref === root.itemHref) {
                showConfirmation = true;
            }
        }

        onAppInstalled: {
            if (appHref === root.itemHref) {
                root.isInstalled = true;
            }
        }

        onAppUninstalled: {
            if (appHref === root.itemHref) {
                root.isInstalled = false;
            }
        }
    }

    Connections {
        target: MyAvatar;

        onSkeletonModelURLChanged: {
            if (skeletonModelURL === root.itemHref) {
                showConfirmation = true;
            }
        }
    }

    onItemTypeChanged: {
        if ((itemType === "entity" && (!Entities.canRezCertified() && !Entities.canRezTmpCertified())) ||
            (itemType === "contentSet" && !Entities.canReplaceContent())) {
            root.hasPermissionToRezThis = false;
        } else {
            root.hasPermissionToRezThis = true;
        }
    }

    onShowConfirmationChanged: {
        if (root.showConfirmation) {
            rezzedNotifContainer.visible = true;
            rezzedNotifContainerTimer.start();
            UserActivityLogger.commerceEntityRezzed(root.itemId, "purchases", root.itemType);
            root.showConfirmation = false;
        }
    }

    Rectangle {
        id: background;
        z: 10;
        color: Qt.rgba(0, 0, 0, 0.25);
        anchors.fill: parent;
    }

    Flipable {
        id: flipable;
        z: 50;
        anchors.left: parent.left;
        anchors.right: parent.right;
        anchors.top: parent.top;
        height: root.height - 2;

        front: mainContainer;
        back: Rectangle {
            anchors.fill: parent;
            color: hifi.colors.white;

            Item {
                id: closeContextMenuContainer;
                anchors.right: parent.right;
                anchors.rightMargin: 8;
                anchors.top: parent.top;
                anchors.topMargin: 8;
                width: 30;
                height: width;
            
                HiFiGlyphs {
                    id: closeContextMenuGlyph;
                    text: hifi.glyphs.close;
                    anchors.fill: parent;
                    size: 26;
                    horizontalAlignment: Text.AlignHCenter;
                    verticalAlignment: Text.AlignVCenter;
                    color: hifi.colors.black;
                }

                MouseArea {
                    anchors.fill: parent;
                    hoverEnabled: enabled;
                    onClicked: {
                        root.sendToPurchases({ method: 'flipCard', closeAll: true });
                    }
                    onEntered: {
                        closeContextMenuGlyph.text = hifi.glyphs.closeInverted;
                    }
                    onExited: {
                        closeContextMenuGlyph.text = hifi.glyphs.close;
                    }
                }
            }

            Rectangle {
                id: contextCard;
                z: 2;
                anchors.left: parent.left;
                anchors.leftMargin: 30;
                anchors.top: parent.top;
                anchors.bottom: parent.bottom;
                anchors.right: closeContextMenuContainer.left;
                anchors.rightMargin: 8;
                color: hifi.colors.white;
            }

            Rectangle {
                id: permissionExplanationCard;
                z: 1;
                anchors.left: parent.left;
                anchors.leftMargin: 30;
                anchors.top: parent.top;
                anchors.bottom: parent.bottom;
                anchors.right: closeContextMenuContainer.left;
                anchors.rightMargin: 8;
                color: hifi.colors.white;

                RalewayRegular {
                    id: permissionExplanationText;
                    anchors.fill: parent;
                    text: {
                        if (root.itemType === "contentSet") {
                            "You do not have 'Replace Content' permissions in this domain. <a href='#replaceContentPermission'>Learn more</a>";
                        } else if (root.itemType === "entity") {
                            "You do not have 'Rez Certified' permissions in this domain. <a href='#rezCertifiedPermission'>Learn more</a>";
                        } else {
                            "Hey! You're not supposed to see this. How is it even possible that you're here? Are you a developer???"
                        }
                    }
                    size: 16;
                    color: hifi.colors.baseGray;
                    wrapMode: Text.WordWrap;
                    verticalAlignment: Text.AlignVCenter;

                    onLinkActivated: {
                        sendToPurchases({method: 'showPermissionsExplanation', itemType: root.itemType});
                    }
                }
            }
        }
        
        transform: Rotation {
            id: rotation;
            origin.x: flipable.width/2;
            origin.y: flipable.height/2;
            axis.x: 1;
            axis.y: 0;
            axis.z: 0;
            angle: 0;
        }

        states: State {
            name: "back";
            PropertyChanges {
                target: rotation;
                angle: 180;
            }
            when: root.cardBackVisible;
        }

        transitions: Transition {
            NumberAnimation {
                target: rotation;
                property: "angle";
                duration: 400;
            }
        }
    }

    Rectangle {
        id: mainContainer;
        z: 51;
        // Style
        color: hifi.colors.white;
        // Size
        anchors.left: parent.left;
        anchors.right: parent.right;
        anchors.top: parent.top;
        height: root.height - 2;

        Image {
            id: itemPreviewImage;
            source: root.itemPreviewImageUrl;
            anchors.left: parent.left;
            anchors.top: parent.top;
            anchors.bottom: parent.bottom;
            width: height * 1.78;
            fillMode: Image.PreserveAspectCrop;

            MouseArea {
                anchors.fill: parent;
                onClicked: {
                    sendToPurchases({method: 'purchases_itemInfoClicked', itemId: root.itemId});
                }
            }
        }

        RalewayRegular {
            id: itemName;
            anchors.top: parent.top;
            anchors.topMargin: 4;
            anchors.left: itemPreviewImage.right;
            anchors.leftMargin: 10;
            anchors.right: contextMenuButtonContainer.left;
            anchors.rightMargin: 4;
            height: paintedHeight;
            // Text size
            size: 20;
            // Style
            color: hifi.colors.black;
            text: root.itemName;
            elide: Text.ElideRight;
            // Alignment
            horizontalAlignment: Text.AlignLeft;
            verticalAlignment: Text.AlignVCenter;

            MouseArea {
                anchors.fill: parent;
                hoverEnabled: enabled;
                onClicked: {
                    sendToPurchases({method: 'purchases_itemInfoClicked', itemId: root.itemId});
                }
                onEntered: {
                    itemName.color = hifi.colors.blueHighlight;
                }
                onExited: {
                    itemName.color = hifi.colors.black;
                }
            }
        }

        RalewayRegular {
            id: editionNumberText;
            visible: root.displayedItemCount > 1 && !statusContainer.visible;
            anchors.left: itemName.left;
            anchors.right: itemName.right;
            anchors.top: itemName.bottom;
            anchors.topMargin: 4;
            anchors.bottom: buttonContainer.top;
            anchors.bottomMargin: 4;
            width: itemName.width;
            text: "Edition #" + root.itemEdition;
            size: 13;
            color: hifi.colors.black;
            verticalAlignment: Text.AlignVCenter;
        }

        Item {
            id: statusContainer;
            visible: root.purchaseStatus === "pending" || root.purchaseStatus === "invalidated" || root.numberSold > -1;
            anchors.left: itemName.left;
            anchors.right: itemName.right;
            anchors.top: itemName.bottom;
            anchors.topMargin: 4;
            anchors.bottom: buttonContainer.top;
            anchors.bottomMargin: 4;

            RalewayRegular {
                id: statusText;
                anchors.left: parent.left;
                anchors.top: parent.top;
                anchors.bottom: parent.bottom;
                width: paintedWidth;
                text: {
                        if (root.purchaseStatus === "pending") {
                            "PENDING..."
                        } else if (root.purchaseStatus === "invalidated") {
                            "INVALIDATED"
                        } else if (root.numberSold > -1) {
                            ("Sales: " + root.numberSold + "/" + (root.limitedRun === -1 ? "\u221e" : root.limitedRun))
                        } else {
                            ""
                        }
                    }
                size: 13;
                color: {
                        if (root.purchaseStatus === "pending") {
                            hifi.colors.blueAccent
                        } else if (root.purchaseStatus === "invalidated") {
                            hifi.colors.redAccent
                        } else {
                            hifi.colors.baseGray
                        }
                    }
                verticalAlignment: Text.AlignTop;
            }
        
            HiFiGlyphs {
                id: statusIcon;
                text: {
                        if (root.purchaseStatus === "pending") {
                            hifi.glyphs.question
                        } else if (root.purchaseStatus === "invalidated") {
                            hifi.glyphs.question
                        } else {
                            ""
                        }
                    }
                // Size
                size: 36;
                // Anchors
                anchors.top: parent.top;
                anchors.topMargin: -8;
                anchors.left: statusText.right;
                anchors.bottom: parent.bottom;
                // Style
                color: {
                        if (root.purchaseStatus === "pending") {
                            hifi.colors.blueAccent
                        } else if (root.purchaseStatus === "invalidated") {
                            hifi.colors.redAccent
                        } else {
                            hifi.colors.baseGray
                        }
                    }
                verticalAlignment: Text.AlignTop;
            }

            MouseArea {
                anchors.fill: parent;
                hoverEnabled: enabled;
                onClicked: {
                    if (root.purchaseStatus === "pending") {
                        sendToPurchases({method: 'showPendingLightbox'});
                    } else if (root.purchaseStatus === "invalidated") {
                        sendToPurchases({method: 'showInvalidatedLightbox'});
                    }
                }
                onEntered: {
                    if (root.purchaseStatus === "pending") {
                        statusText.color = hifi.colors.blueHighlight;
                        statusIcon.color = hifi.colors.blueHighlight;
                    } else if (root.purchaseStatus === "invalidated") {
                        statusText.color = hifi.colors.redAccent;
                        statusIcon.color = hifi.colors.redAccent;
                    }
                }
                onExited: {
                    if (root.purchaseStatus === "pending") {
                        statusText.color = hifi.colors.blueAccent;
                        statusIcon.color = hifi.colors.blueAccent;
                    } else if (root.purchaseStatus === "invalidated") {
                        statusText.color = hifi.colors.redHighlight;
                        statusIcon.color = hifi.colors.redHighlight;
                    }
                }
            }
        }

        Item {
            id: contextMenuButtonContainer;
            anchors.right: parent.right;
            anchors.rightMargin: 8;
            anchors.top: parent.top;
            anchors.topMargin: 8;
            width: 30;
            height: width;

            property bool upgradeAvailable: root.upgradeUrl !== "" && !root.isShowingMyItems;
            
            HiFiGlyphs {
                id: contextMenuGlyph;
                text: "\ue019"
                anchors.fill: parent;
                size: 46;
                horizontalAlignment: Text.AlignHCenter;
                verticalAlignment: Text.AlignVCenter;
                color: contextMenuButtonContainer.upgradeAvailable ? hifi.colors.redAccent : hifi.colors.black;
            }

            MouseArea {
                anchors.fill: parent;
                hoverEnabled: enabled;
                onClicked: {
                    contextCard.z = 1;
                    permissionExplanationCard.z = 0;
                    root.sendToPurchases({ method: 'flipCard' });
                }
                onEntered: {
                    contextMenuGlyph.color = contextMenuButtonContainer.upgradeAvailable ? hifi.colors.redHighlight : hifi.colors.blueHighlight;
                }
                onExited: {
                    contextMenuGlyph.color = contextMenuButtonContainer.upgradeAvailable ? hifi.colors.redAccent : hifi.colors.black;
                }
            }
        }
        
        Rectangle {
            id: rezzedNotifContainer;
            z: 998;
            visible: false;
            color: "#1FC6A6";
            anchors.fill: buttonContainer;
            MouseArea {
                anchors.fill: parent;
                propagateComposedEvents: false;
                hoverEnabled: true;
            }

            RalewayBold {
                anchors.fill: parent;
                text: (root.buttonTextClicked)[itemTypesArray.indexOf(root.itemType)];
                size: 15;
                color: hifi.colors.white;
                verticalAlignment: Text.AlignVCenter;
                horizontalAlignment: Text.AlignHCenter;
            }

            Timer {
                id: rezzedNotifContainerTimer;
                interval: 2000;
                onTriggered: rezzedNotifContainer.visible = false
            }
        }
        Button {
            id: buttonContainer;
            property int color: hifi.buttons.blue;
            property int colorScheme: hifi.colorSchemes.light;

            anchors.left: itemName.left;
            anchors.bottom: parent.bottom;
            anchors.bottomMargin: 8;
            width: 160;
            height: 40;
            enabled: root.hasPermissionToRezThis &&
                root.purchaseStatus !== "invalidated" &&
                MyAvatar.skeletonModelURL !== root.itemHref;

            onHoveredChanged: {
                if (hovered) {
                    Tablet.playSound(TabletEnums.ButtonHover);
                }
            }
    
            onFocusChanged: {
                if (focus) {
                    Tablet.playSound(TabletEnums.ButtonHover);
                }
            }
            
            onClicked: {
                Tablet.playSound(TabletEnums.ButtonClick);
                /*if (root.isInGiftMode) {
                    sendToPurchases({method: 'giftAsset', itemName: root.itemName, certId: root.certificateId})
                } else */if (root.itemType === "contentSet") {
                    sendToPurchases({method: 'showReplaceContentLightbox', itemHref: root.itemHref});
                } else if (root.itemType === "avatar") {
                    sendToPurchases({method: 'showChangeAvatarLightbox', itemName: root.itemName, itemHref: root.itemHref});
                } else if (root.itemType === "app") {
                    // "Run" and "Uninstall" buttons are separate.
                    Commerce.installApp(root.itemHref);
                } else {
                    sendToPurchases({method: 'purchases_rezClicked', itemHref: root.itemHref, itemType: root.itemType});
                    root.showConfirmation = true;
                }
            }

            style: ButtonStyle {
                background: Rectangle {
                    radius: 4;
                    gradient: Gradient {
                        GradientStop {
                            position: 0.2
                            color: {
                                if (!control.enabled) {
                                    hifi.buttons.disabledColorStart[control.colorScheme]
                                } else if (control.pressed) {
                                    hifi.buttons.pressedColor[control.color]
                                } else if (control.hovered) {
                                    hifi.buttons.hoveredColor[control.color]
                                } else {
                                    hifi.buttons.colorStart[control.color]
                                }
                            }
                        }
                        GradientStop {
                            position: 1.0
                            color: {
                                if (!control.enabled) {
                                    hifi.buttons.disabledColorFinish[control.colorScheme]
                                } else if (control.pressed) {
                                    hifi.buttons.pressedColor[control.color]
                                } else if (control.hovered) {
                                    hifi.buttons.hoveredColor[control.color]
                                } else {
                                    hifi.buttons.colorFinish[control.color]
                                }
                            }
                        }
                    }
                }

                label: Item {
                    TextMetrics {
                        id: rezIconTextMetrics;
                        font: rezIcon.font;
                        text: rezIcon.text;
                    }
                    HiFiGlyphs {
                        id: rezIcon;
                        text: (root.buttonGlyph)[itemTypesArray.indexOf(root.itemType)];
                        anchors.right: rezIconLabel.left;
                        anchors.rightMargin: 2;
                        anchors.verticalCenter: parent.verticalCenter;
                        size: 36;
                        horizontalAlignment: Text.AlignHCenter;
                        color: enabled ? hifi.buttons.textColor[control.color]
                                        : hifi.buttons.disabledTextColor[control.colorScheme]
                    }
                    TextMetrics {
                        id: rezIconLabelTextMetrics;
                        font: rezIconLabel.font;
                        text: rezIconLabel.text;
                    }
                    RalewayBold {
                        id: rezIconLabel;
                        text: MyAvatar.skeletonModelURL === root.itemHref ? "CURRENT" : (root.buttonTextNormal)[itemTypesArray.indexOf(root.itemType)];
                        anchors.verticalCenter: parent.verticalCenter;
                        width: rezIconLabelTextMetrics.width;
                        x: parent.width/2 - rezIconLabelTextMetrics.width/2 + rezIconTextMetrics.width/2;
                        size: 15;
                        font.capitalization: Font.AllUppercase;
                        verticalAlignment: Text.AlignVCenter;
                        horizontalAlignment: Text.AlignHCenter;
                        color: enabled ? hifi.buttons.textColor[control.color]
                                        : hifi.buttons.disabledTextColor[control.colorScheme]
                    }
                }
            }
        }
        HiFiGlyphs {
            id: noPermissionGlyph;
            visible: !root.hasPermissionToRezThis;
            anchors.verticalCenter: buttonContainer.verticalCenter;
            anchors.left: buttonContainer.right;
            text: hifi.glyphs.info;
            // Size
            size: 44;
            width: 32;
            // Style
            color: hifi.colors.redAccent;
            
            MouseArea {
                anchors.fill: parent;
                hoverEnabled: true;

                onEntered: {
                    noPermissionGlyph.color = hifi.colors.redHighlight;
                }
                onExited: {
                    noPermissionGlyph.color = hifi.colors.redAccent;
                }
                onClicked: {
                    contextCard.z = 0;
                    permissionExplanationCard.z = 1;
                    root.sendToPurchases({ method: 'flipCard' });
                }
            }
        }
    }

    //
    // FUNCTION DEFINITIONS START
    //
    signal sendToPurchases(var msg);
    //
    // FUNCTION DEFINITIONS END
    //
}
