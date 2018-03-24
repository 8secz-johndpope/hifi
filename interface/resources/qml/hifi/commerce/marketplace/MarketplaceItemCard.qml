//
//  MarketplaceItemCard.qml
//
//  MarketplaceItemCard
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
import QtGraphicalEffects 1.0
import "qrc:////qml//styles-uit" as HifiStylesUit
import "qrc:////qml//controls-uit" as HifiControlsUit
import TabletScriptingInterface 1.0

Item {
    HifiStylesUit.HifiConstants { id: hifi; }

    id: root;
	property string itemId;
	property string title;
	property string imageUrl;

    height: 200;
    width: parent.width;

    Rectangle {
        id: mainContainer;
        // Style
        color: hifi.colors.white;
        // Size
        anchors.left: parent.left;
        anchors.leftMargin: 16;
        anchors.right: parent.right;
        anchors.rightMargin: 16;
        anchors.verticalCenter: parent.verticalCenter;
        height: root.height - 10;

		Image {
			source: root.imageUrl;
			fillMode: Image.PreserveAspectCrop;
			anchors.top: parent.top;
			anchors.left: parent.left;
			anchors.bottom: parent.bottom;
			width: parent.height * 1.7;
		}

		Rectangle {
			color: Qt.rgba(0, 0, 0, 0.8);
			anchors.top: parent.top;
			anchors.left: parent.left;
			anchors.right: parent.right;
			height: 40;
			
			HifiStylesUit.RalewayBold {
				id: itemTitle;
				text: root.title;
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

		MouseArea {
			anchors.fill: parent;
			onClicked: {
				sendToParent({ method: "marketplaceItemClicked", itemId: root.itemId });
			}
		}
    }

    DropShadow {
        anchors.fill: mainContainer;
        horizontalOffset: 0;
        verticalOffset: 4;
        radius: 4.0;
        samples: 9
        color: Qt.rgba(0, 0, 0, 0.25);
        source: mainContainer;
    }

    //
    // FUNCTION DEFINITIONS START
    //
    signal sendToParent(var msg);
    //
    // FUNCTION DEFINITIONS END
    //
}
