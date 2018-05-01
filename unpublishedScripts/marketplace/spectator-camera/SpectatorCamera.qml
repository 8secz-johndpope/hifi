//
//  SpectatorCamera.qml
//  qml/hifi
//
//  Spectator Camera v2.0
//
//  Created by Zach Fox on 2018-04-18
//  Copyright 2018 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

import Hifi 1.0 as Hifi
import QtQuick 2.7
import "qrc:////qml//styles-uit" as HifiStylesUit
import "qrc:////qml//controls-uit" as HifiControlsUit
import "qrc:////qml//controls" as HifiControls
import "qrc:////qml//hifi" as Hifi

Rectangle {
    HifiStylesUit.HifiConstants { id: hifi; }

    id: root;
    property bool processing360Snapshot: false;
    // Style
    color: hifi.colors.baseGray;

    // The letterbox used for popup messages
    Hifi.LetterboxMessage {
        id: letterboxMessage;
        z: 998; // Force the popup on top of everything else
    }
    function letterbox(headerGlyph, headerText, message) {
        letterboxMessage.headerGlyph = headerGlyph;
        letterboxMessage.headerText = headerText;
        letterboxMessage.text = message;
        letterboxMessage.visible = true;
        letterboxMessage.popupRadius = 0;
    }

    //
    // TITLE BAR START
    //
    Item {
        id: titleBarContainer;
        // Size
        width: root.width;
        height: 40;
        // Anchors
        anchors.left: parent.left;
        anchors.top: parent.top;

        // "Spectator" text
        HifiStylesUit.RalewaySemiBold {
            id: titleBarText;
            text: "Spectator Camera";
            // Text size
            size: hifi.fontSizes.overlayTitle;
            // Anchors
            anchors.fill: parent;
            anchors.leftMargin: 16;
            // Style
            color: hifi.colors.lightGrayText;
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
    // SPECTATOR APP DESCRIPTION START
    //
    Item {
        id: spectatorDescriptionContainer;
        // Size
        width: root.width;
        height: childrenRect.height;
        // Anchors
        anchors.left: parent.left;
        anchors.top: titleBarContainer.bottom;

        // (i) Glyph
        HifiStylesUit.HiFiGlyphs {
            id: spectatorDescriptionGlyph;
            text: hifi.glyphs.info;
            // Size
            width: 20;
            height: parent.height;
            size: 60;
            // Anchors
            anchors.left: parent.left;
            anchors.leftMargin: 20;
            anchors.top: parent.top;
            anchors.topMargin: 0;
            // Style
            color: hifi.colors.lightGrayText;
            horizontalAlignment: Text.AlignHLeft;
            verticalAlignment: Text.AlignTop;
        }

        // "Spectator" app description text
        HifiStylesUit.RalewayLight {
            id: spectatorDescriptionText;
            text: "Spectator lets you change what your monitor displays while you're using a VR headset. Use Spectator when streaming and recording video.";
            // Text size
            size: 14;
            // Size
            width: 350;
            height: paintedHeight;
            // Anchors
            anchors.top: parent.top;
            anchors.topMargin: 15;
            anchors.left: spectatorDescriptionGlyph.right;
            anchors.leftMargin: 40;
            // Style
            color: hifi.colors.lightGrayText;
            wrapMode: Text.Wrap;
            // Alignment
            horizontalAlignment: Text.AlignHLeft;
            verticalAlignment: Text.AlignVCenter;
        }

        // "Learn More" text
        HifiStylesUit.RalewayRegular {
            id: spectatorLearnMoreText;
            text: "Learn More About Spectator";
            // Text size
            size: 14;
            // Size
            width: paintedWidth;
            height: paintedHeight;
            // Anchors
            anchors.top: spectatorDescriptionText.bottom;
            anchors.topMargin: 10;
            anchors.left: spectatorDescriptionText.anchors.left;
            anchors.leftMargin: spectatorDescriptionText.anchors.leftMargin;
            // Style
            color: hifi.colors.blueAccent;
            wrapMode: Text.WordWrap;
            font.underline: true;
            // Alignment
            horizontalAlignment: Text.AlignHLeft;
            verticalAlignment: Text.AlignVCenter;

            MouseArea {
                anchors.fill: parent;
                hoverEnabled: enabled;
                onClicked: {
                    letterbox(hifi.glyphs.question,
                        "Spectator Camera",
                        "By default, your monitor shows a preview of what you're seeing in VR. " +
                        "Using the Spectator Camera app, your monitor can display the view " +
                        "from a virtual hand-held camera - perfect for taking selfies or filming " +
                        "your friends!<br>" +
                        "<h3>Streaming and Recording</h3>" +
                        "We recommend OBS for streaming and recording the contents of your monitor to services like " +
                        "Twitch, YouTube Live, and Facebook Live.<br><br>" +
                        "To get started using OBS, click this link now. The page will open in an external browser:<br>" +
                        '<font size="4"><a href="https://obsproject.com/forum/threads/official-overview-guide.402/">OBS Official Overview Guide</a></font>');
                }
                onEntered: parent.color = hifi.colors.blueHighlight;
                onExited: parent.color = hifi.colors.blueAccent;
            }
        }

        // Separator
        HifiControlsUit.Separator {
            anchors.left: parent.left;
            anchors.right: parent.right;
            anchors.top: spectatorLearnMoreText.bottom;
            anchors.topMargin: spectatorDescriptionText.anchors.topMargin;
        }
    }
    //
    // SPECTATOR APP DESCRIPTION END
    //

    Rectangle {
        z: 999;
        id: processingSnapshot;
        anchors.fill: parent;
        visible: false//root.processing360Snapshot;
        color: Qt.rgba(0.0, 0.0, 0.0, 0.85);        

        // This object is always used in a popup.
        // This MouseArea is used to prevent a user from being
        //     able to click on a button/mouseArea underneath the popup/section.
        MouseArea {
            anchors.fill: parent;
            hoverEnabled: true;
            propagateComposedEvents: false;
        }
                
        AnimatedImage {
            id: processingImage;
            source: "processing.gif"
            width: 74;
            height: width;
            anchors.verticalCenter: parent.verticalCenter;
            anchors.horizontalCenter: parent.horizontalCenter;
        }

        HifiStylesUit.RalewaySemiBold {
            text: "Processing...";
            // Anchors
            anchors.top: processingImage.bottom;
            anchors.topMargin: 4;
            anchors.horizontalCenter: parent.horizontalCenter;
            width: paintedWidth;
            // Text size
            size: 26;
            // Style
            color: hifi.colors.white;
            verticalAlignment: Text.AlignVCenter;
        }
    }

    //
    // SPECTATOR CONTROLS START
    //
    Item {
        id: spectatorControlsContainer;
        // Size
        height: root.height - spectatorDescriptionContainer.height - titleBarContainer.height;
        // Anchors
        anchors.top: spectatorDescriptionContainer.bottom;
        anchors.topMargin: 8;
        anchors.left: parent.left;
        anchors.leftMargin: 25;
        anchors.right: parent.right;
        anchors.rightMargin: anchors.leftMargin;

        // "Camera On" Button
        HifiControlsUit.Button {
			property bool camIsOn: false;

            id: cameraToggleButton;
			color: camIsOn ? hifi.buttons.red : hifi.buttons.blue;
			colorScheme: hifi.colorSchemes.dark;
            anchors.left: parent.left;
            anchors.top: parent.top;
			anchors.right: parent.right;
			height: 40;
            text: camIsOn ? "TURN OFF SPECTATOR CAMERA" : "TURN ON SPECTATOR CAMERA";
            onClicked: {
				camIsOn = !camIsOn;
                sendToScript({method: (camIsOn ? 'spectatorCameraOn' : 'spectatorCameraOff')});
                sendToScript({method: 'updateCameravFoV', vFoV: fieldOfViewSlider.value});
            }
        }

        // Instructions or Preview
        Rectangle {
            id: spectatorCameraImageContainer;
            anchors.left: parent.left;
            anchors.top: cameraToggleButton.bottom;
            anchors.topMargin: 8;
            anchors.right: parent.right;
            height: 250;
            color: cameraToggleButton.camIsOn ? "transparent" : "black";

            AnimatedImage {
                source: "static.gif"
                visible: !cameraToggleButton.camIsOn;
                anchors.fill: parent;
                opacity: 0.15;
            }

            // Instructions (visible when display texture isn't set)
            HifiStylesUit.FiraSansRegular {
                id: spectatorCameraInstructions;
                text: "Turn on Spectator Camera for a preview\nof " + (HMD.active ? "what your monitor shows." : "the camera's view.");
                size: 16;
                color: hifi.colors.lightGrayText;
                visible: !cameraToggleButton.camIsOn;
                anchors.fill: parent;
                horizontalAlignment: Text.AlignHCenter;
                verticalAlignment: Text.AlignVCenter;
            }

            // Spectator Camera Preview
            Hifi.ResourceImageItem {
                id: spectatorCameraPreview;
                visible: cameraToggleButton.camIsOn;
                url: monitorShowsSwitch.checked || !HMD.active ? "resource://spectatorCameraFrame" : "resource://hmdPreviewFrame";
                ready: cameraToggleButton.camIsOn;
                mirrorVertically: true;
                anchors.fill: parent;
                onVisibleChanged: {
                    ready = cameraToggleButton.camIsOn;
                    update();
                }
            }
        }

        Item {
            id: fieldOfView;
            anchors.top: spectatorCameraImageContainer.bottom;
            anchors.topMargin: 8;
            anchors.left: parent.left;
            anchors.leftMargin: 8;
            anchors.right: parent.right;
            height: 35;

            HifiStylesUit.FiraSansRegular {
                id: fieldOfViewLabel;
                text: "Field of View (" + fieldOfViewSlider.value + "\u00B0): ";
                size: 16;
                color: hifi.colors.lightGrayText;
                anchors.left: parent.left;
                anchors.top: parent.top;
                anchors.bottom: parent.bottom;
                width: 140;
                horizontalAlignment: Text.AlignLeft;
                verticalAlignment: Text.AlignVCenter;
            }

            HifiControlsUit.Slider {
                id: fieldOfViewSlider;
                anchors.top: parent.top;
                anchors.bottom: parent.bottom;
                anchors.right: resetvFoV.left;
                anchors.rightMargin: 8;
                anchors.left: fieldOfViewLabel.right;
                anchors.leftMargin: 8;
                colorScheme: hifi.colorSchemes.dark;
                from: 10.0;
                to: 120.0;
                value: 45.0;
                stepSize: 1;

                onValueChanged: {
                    sendToScript({method: 'updateCameravFoV', vFoV: value});
                }
                onPressedChanged: {
                    if (!pressed) {
                        sendToScript({method: 'updateCameravFoV', vFoV: value});
                    }
                }
            }

            HifiControlsUit.GlyphButton {
                id: resetvFoV;
                anchors.verticalCenter: parent.verticalCenter;
                anchors.right: parent.right;
                anchors.rightMargin: 6;
                height: parent.height - 8;
                width: height;
                glyph: hifi.glyphs.reload;
                onClicked: {
                    fieldOfViewSlider.value = 45.0;
                }
            }
        }


        // "Monitor Shows" Switch Label Glyph
        HifiStylesUit.HiFiGlyphs {
            id: monitorShowsSwitchLabelGlyph;
            visible: HMD.active;
            text: hifi.glyphs.screen;
            size: 32;
            color: hifi.colors.blueHighlight;
            anchors.top: fieldOfView.bottom;
            anchors.topMargin: 8;
            anchors.left: parent.left;
        }
        // "Monitor Shows" Switch Label
        HifiStylesUit.RalewayLight {
            id: monitorShowsSwitchLabel;
            visible: HMD.active;
            text: "MONITOR SHOWS:";
            anchors.top: fieldOfView.bottom;
            anchors.topMargin: 20;
            anchors.left: monitorShowsSwitchLabelGlyph.right;
            anchors.leftMargin: 6;
            size: 16;
            width: paintedWidth;
            height: paintedHeight;
            color: hifi.colors.lightGrayText;
            verticalAlignment: Text.AlignVCenter;
        }
        // "Monitor Shows" Switch
        HifiControlsUit.Switch {
            id: monitorShowsSwitch;
            visible: HMD.active;
            height: 30;
            anchors.left: parent.left;
            anchors.right: parent.right;
            anchors.top: monitorShowsSwitchLabel.bottom;
            anchors.topMargin: 10;
            labelTextOff: "HMD Preview";
            labelTextOn: "Camera View";
            labelGlyphOnText: hifi.glyphs.alert;
            onCheckedChanged: {
                sendToScript({method: 'setMonitorShowsCameraView', params: checked});
            }
        }

        // "Switch View From Controller" Checkbox
        HifiControlsUit.CheckBox {
            id: switchViewFromControllerCheckBox;
            visible: HMD.active;
            colorScheme: hifi.colorSchemes.dark;
            anchors.left: parent.left;
            anchors.top: monitorShowsSwitch.bottom;
            anchors.topMargin: 14;
            text: "";
            boxSize: 24;
            onClicked: {
                sendToScript({method: 'changeSwitchViewFromControllerPreference', params: checked});
            }
        }

        // "Take Snapshot" Checkbox
        HifiControlsUit.CheckBox {
            id: takeSnapshotFromControllerCheckBox;
            visible: HMD.active;
            colorScheme: hifi.colorSchemes.dark;
            anchors.left: parent.left;
            anchors.top: switchViewFromControllerCheckBox.bottom;
            anchors.topMargin: 10;
            text: "";
            boxSize: 24;
            onClicked: {
                sendToScript({method: 'changeTakeSnapshotFromControllerPreference', params: checked});
            }
        }

		HifiControlsUit.Button {
			id: takeSnapshotButton;
            enabled: cameraToggleButton.camIsOn;
            text: "Take Still Snapshot";
			colorScheme: hifi.colorSchemes.dark;
			color: hifi.buttons.blue;
			anchors.top: takeSnapshotFromControllerCheckBox.visible ? takeSnapshotFromControllerCheckBox.bottom : fieldOfView.bottom;
			anchors.topMargin: 8;
			anchors.left: parent.left;
            width: parent.width/2 - 10;
			height: 40;
			onClicked: {
				sendToScript({method: 'takeSecondaryCameraSnapshot'});
			}
		}
		HifiControlsUit.Button {
			id: take360SnapshotButton;
            enabled: cameraToggleButton.camIsOn;
            text: "Take 360 Snapshot";
			colorScheme: hifi.colorSchemes.dark;
			color: hifi.buttons.blue;
			anchors.top: takeSnapshotFromControllerCheckBox.visible ? takeSnapshotFromControllerCheckBox.bottom : fieldOfView.bottom;
			anchors.topMargin: 8;
			anchors.right: parent.right;
            width: parent.width/2 - 10;
			height: 40;
			onClicked: {
                root.processing360Snapshot = true;
				sendToScript({method: 'takeSecondaryCamera360Snapshot'});
			}
		}
    }
    //
    // SPECTATOR CONTROLS END
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
    // message: The message sent from the SpectatorCamera JavaScript.
    //     Messages are in format "{method, params}", like json-rpc.
    //
    // Description:
    // Called when a message is received from spectatorCamera.js.
    //
    function fromScript(message) {
        switch (message.method) {
        case 'updateSpectatorCameraCheckbox':
            cameraToggleButton.camIsOn = message.params;
        break;
        case 'updateMonitorShowsSwitch':
            monitorShowsSwitch.checked = message.params;
        break;
        case 'updateControllerMappingCheckbox':
            switchViewFromControllerCheckBox.checked = message.switchViewSetting;
            switchViewFromControllerCheckBox.enabled = true;
            takeSnapshotFromControllerCheckBox.checked = message.takeSnapshotSetting;
            takeSnapshotFromControllerCheckBox.enabled = true;

            if (message.controller === "OculusTouch") {
                switchViewFromControllerCheckBox.text = "Clicking Touch's Left Thumbstick Switches Monitor View";
				takeSnapshotFromControllerCheckBox.text = "Clicking Touch's Right Thumbstick Takes Snapshot";
            } else if (message.controller === "Vive") {
                switchViewFromControllerCheckBox.text = "Clicking Left Thumb Pad Switches Monitor View";
				takeSnapshotFromControllerCheckBox.text = "Clicking Right Thumb Pad Takes Snapshot";
            } else {
                switchViewFromControllerCheckBox.text = "Pressing Ctrl+0 Switches Monitor View";
                switchViewFromControllerCheckBox.checked = true;
                switchViewFromControllerCheckBox.enabled = false;
				takeSnapshotFromControllerCheckBox.visible = false;
            }
        break;
        case 'finishedProcessing360Snapshot':
            root.processing360Snapshot = false;
        break;
        default:
            console.log('Unrecognized message from spectatorCamera.js:', JSON.stringify(message));
        }
    }
    signal sendToScript(var message);

    //
    // FUNCTION DEFINITIONS END
    //
}
