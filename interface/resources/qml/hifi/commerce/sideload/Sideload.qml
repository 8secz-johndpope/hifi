//
//  Sideload.qml
//  qml/hifi/commerce/sideload
//
//  Sideload
//
//  Created by Zach Fox on 2018-09-05
//  Copyright 2018 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

import Hifi 1.0 as Hifi
import QtQuick 2.5
import "../../../styles-uit" as HifiStylesUit
import "../../../controls-uit" as HifiControlsUit

Rectangle {
    HifiStylesUit.HifiConstants { id: hifi; }

    id: root;
    property string installedApps;
    // Style
    color: hifi.colors.white;

    Connections {
        target: Commerce;

        onAppInstalled: {
            root.installedApps = Commerce.getInstalledApps(appID);
        }

        onAppUninstalled: {
            root.installedApps = Commerce.getInstalledApps();
        }

        Component.onCompleted: {
            root.installedApps = Commerce.getInstalledApps();
        }
    }

    HifiStylesUit.RalewayRegular {
        id: installedAppsHeader;
        anchors.top: parent.top;
        anchors.left: parent.left;
        anchors.leftMargin: 12;
        height: 80;
        width: paintedWidth;
        text: "All Installed Marketplace Apps";
        color: hifi.colors.black;
        size: 22;
    }

    ListView {
        id: installedAppsList;
        clip: true;
        model: installedAppsModel;
        snapMode: ListView.SnapToItem;
        // Anchors
        anchors.top: installedAppsHeader.bottom;
        anchors.left: parent.left;
        anchors.bottom: sideloadAppFromUrlContainer.visible ? sideloadAppFromUrlContainer.top : sideloadAppFromUrlButton.top;
        width: parent.width;
        delegate: Item {
            width: parent.width;
            height: 40;
                
            HifiStylesUit.RalewayRegular {
                text: model.appUrl;
                // Text size
                size: 16;
                // Anchors
                anchors.left: parent.left;
                anchors.leftMargin: 12;
                height: parent.height;
                anchors.right: sideloadAppOpenButton.left;
                anchors.rightMargin: 8;
                elide: Text.ElideRight;
                // Style
                color: hifi.colors.black;
                // Alignment
                verticalAlignment: Text.AlignVCenter;

                MouseArea {
                    anchors.fill: parent;
                    onClicked: {
                        Window.copyToClipboard((model.appUrl).slice(0, -9));
                    }
                }
            }

            HifiControlsUit.Button {
                id: sideloadAppOpenButton;
                text: "OPEN";
                color: hifi.buttons.blue;
                colorScheme: hifi.colorSchemes.dark;
                anchors.top: parent.top;
                anchors.topMargin: 2;
                anchors.bottom: parent.bottom;
                anchors.bottomMargin: 2;
                anchors.right: uninstallGlyph.left;
                anchors.rightMargin: 8;
                width: 80;
                onClicked: {
                    Commerce.openApp(model.appUrl);
                }
            }
            
            HifiStylesUit.HiFiGlyphs {
                id: uninstallGlyph;
                text: hifi.glyphs.close;
                color: hifi.colors.black;
                size: 22;
                anchors.top: parent.top;
                anchors.right: parent.right;
                anchors.rightMargin: 6;
                width: 35;
                height: parent.height;
                horizontalAlignment: Text.AlignHCenter;
                MouseArea {
                    anchors.fill: parent;
                    hoverEnabled: true;
                    onEntered: {
                        parent.text = hifi.glyphs.closeInverted;
                    }
                    onExited: {
                        parent.text = hifi.glyphs.close;
                    }
                    onClicked: {
                        Commerce.uninstallApp(model.appUrl);
                    }
                }
            }
        }
    }
    Item {
        id: sideloadAppFromUrlContainer;
        visible: false;
        height: childrenRect.height;
        anchors.bottom: sideloadAppFromDiskButton.top;
        anchors.bottomMargin: 8;
        anchors.left: parent.left;
        anchors.leftMargin: 8;
        anchors.right: parent.right;
        anchors.rightMargin: 8;

        HifiControlsUit.TextField {
            id: url;
            placeholderText: "URL to .app.json";
            colorScheme: hifi.colorSchemes.light;
            // Anchors
            anchors.top: parent.top;
            anchors.left: parent.left;
            anchors.right: parent.right;
            height: 50;
            activeFocusOnPress: true;
            activeFocusOnTab: true;

            onAccepted: {
                Commerce.installApp(url.text);
                sideloadAppFromUrlContainer.visible = false;
                sideloadAppFromUrlButton.visible = true;
            }
        }
        
        HifiControlsUit.Button {
            color: hifi.buttons.white;
            colorScheme: hifi.colorSchemes.light;
            anchors.top: url.bottom;
            anchors.topMargin: 8;
            anchors.left: parent.left;
            width: parent.width/2 - 32;
            height: 40;
            text: "CANCEL";
            onClicked: {
                sideloadAppFromUrlContainer.visible = false;
                sideloadAppFromUrlButton.visible = true;
                sideloadAppFromDiskButton.enabled = true;
            }
        }
        HifiControlsUit.Button {
            color: hifi.buttons.blue;
            colorScheme: hifi.colorSchemes.light;
            anchors.top: url.bottom;
            anchors.topMargin: 8;
            anchors.right: parent.right;
            width: parent.width/2 - 32;
            height: 40;
            text: "INSTALL APP";
            onClicked: {
                sideloadAppFromUrlButton.visible = true;
                sideloadAppFromUrlContainer.visible = false;
                sideloadAppFromDiskButton.enabled = true;
                Commerce.installApp(url.text);
            }
        }
    }

    HifiControlsUit.Button {
        id: sideloadAppFromUrlButton;
        color: hifi.buttons.blue;
        colorScheme: hifi.colorSchemes.light;
        anchors.bottom: sideloadAppFromDiskButton.top;
        anchors.bottomMargin: 8;
        anchors.left: parent.left;
        anchors.leftMargin: 8;
        anchors.right: parent.right;
        anchors.rightMargin: 8;
        height: 40;
        text: "SIDELOAD APP FROM URL";
        onClicked: {
            sideloadAppFromDiskButton.enabled = false;
            sideloadAppFromUrlButton.visible = false;
            sideloadAppFromUrlContainer.visible = true;
        }
    }
    HifiControlsUit.Button {
        id: sideloadAppFromDiskButton;
        color: hifi.buttons.blue;
        colorScheme: hifi.colorSchemes.dark;
        anchors.bottom: parent.bottom;
        anchors.bottomMargin: 8;
        anchors.left: parent.left;
        anchors.leftMargin: 8;
        anchors.right: parent.right;
        anchors.rightMargin: 8;
        height: 40;
        text: "SIDELOAD APP FROM LOCAL DISK";
        onClicked: {
            Window.browseChanged.connect(onFileOpenChanged); 
            Window.browseAsync("Locate your app's .app.json file", "", "*.app.json");
        }
    }
    
    //
    // FUNCTION DEFINITIONS START
    //
    function onFileOpenChanged(filename) {
        // disconnect the event, otherwise the requests will stack up
        try { // Not all calls to onFileOpenChanged() connect an event.
            Window.browseChanged.disconnect(onFileOpenChanged);
        } catch (e) {
            console.log('Purchases.qml ignoring', e);
        }
        if (filename) {
            Commerce.installApp(filename);
        }
    }
    ListModel {
        id: installedAppsModel;
    }
    onInstalledAppsChanged: {
        installedAppsModel.clear();
        var installedAppsArray = root.installedApps.split(",");
        var installedAppsObject = [];
        // "- 1" because the last app string ends with ","
        for (var i = 0; i < installedAppsArray.length - 1; i++) {
            installedAppsObject[i] = {
                "appUrl": installedAppsArray[i]
            }
        }
        installedAppsModel.append(installedAppsObject);
    }
    //
    // FUNCTION DEFINITIONS END
    //
}
