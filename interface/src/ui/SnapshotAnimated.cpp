//
//  SnapshotAnimated.cpp
//  interface/src/ui
//
//  Created by Zach Fox on 11/14/16.
//  Copyright 2016 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#include <QtCore/QDateTime>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtGui/QImage>

#include "SnapshotAnimated.h"


SnapshotAnimated::SnapshotAnimated(QString pathStill, float aspectRatio, Application* app, QSharedPointer<WindowScriptingInterface> dm) {
    // Define the output location of the still and animated snapshots.
    snapshotStillPath = pathStill;
    snapshotAnimatedPath = pathStill;
    snapshotAnimatedPath.replace("jpg", "gif");
    snapshotAnimatedAspectRatio = aspectRatio;
    snapshotAnimatedApp = app;
    snapshotAnimatedDM = dm;
    snapshotAnimatedTimestamp = 0;
    snapshotAnimatedFirstFrameTimestamp = 0;
    snapshotAnimatedLastWriteFrameDuration = 0;
    // Reset the current animated snapshot last frame duration
    snapshotAnimatedLastWriteFrameDuration = SNAPSNOT_ANIMATED_INITIAL_WRITE_DURATION_MSEC;
}

void snapshotAnimatedSetupAndRun(QString pathStill, float aspectRatio, Application* app, QSharedPointer<WindowScriptingInterface> dm) {
    SnapshotAnimated* snapshotAnimatedProcessor = new SnapshotAnimated(pathStill, aspectRatio, app, dm);
    snapshotAnimatedProcessor->initialize();
}

bool SnapshotAnimated::process() {

    usleep(USECS_PER_SECOND / SNAPSNOT_ANIMATED_TARGET_FRAMERATE);

    // Get a screenshot from the display, then scale the screenshot down,
    // then convert it to the image format the GIF library needs,
    // then save all that to the QImage named "frame"
    QImage frame(snapshotAnimatedApp->getActiveDisplayPlugin()->getScreenshot(snapshotAnimatedAspectRatio));
    frame = frame.scaledToWidth(SNAPSNOT_ANIMATED_WIDTH).convertToFormat(QImage::Format_RGBA8888);

    // If this is an intermediate or the final frame...
    if (snapshotAnimatedTimestamp > 0) {
        // Variable used to determine how long the current frame took to pack
        qint64 framePackStartTime = QDateTime::currentMSecsSinceEpoch();
        // Write the frame to the gif
        GifWriteFrame(&(snapshotAnimatedGifWriter),
            (uint8_t*)frame.bits(),
            frame.width(),
            frame.height(),
            round(((float)(framePackStartTime - snapshotAnimatedTimestamp + snapshotAnimatedLastWriteFrameDuration)) / 10));
        // Record the current frame timestamp
        snapshotAnimatedTimestamp = QDateTime::currentMSecsSinceEpoch();
        // Record how long it took for the current frame to pack
        snapshotAnimatedLastWriteFrameDuration = snapshotAnimatedTimestamp - framePackStartTime;
        // If that was the last frame...
        if ((snapshotAnimatedTimestamp - snapshotAnimatedFirstFrameTimestamp) >= (SNAPSNOT_ANIMATED_DURATION_MSEC)) {
            // Reset the current frame timestamp
            snapshotAnimatedTimestamp = 0;
            snapshotAnimatedFirstFrameTimestamp = 0;
            // Write out the end of the GIF
            GifEnd(&(snapshotAnimatedGifWriter));
            // Let the dependency manager know that the snapshots have been taken.
            emit snapshotAnimatedDM->snapshotTaken(snapshotStillPath, snapshotAnimatedPath, false);
            this->terminate();
            delete this;
        }
        // If that was the first frame...
    }
    else {
        // Write out the header and beginning of the GIF file
        GifBegin(&(snapshotAnimatedGifWriter), qPrintable(snapshotAnimatedPath), frame.width(), frame.height(), SNAPSNOT_ANIMATED_FRAME_DELAY_MSEC / 10);
        // Write the first to the gif
        GifWriteFrame(&(snapshotAnimatedGifWriter),
            (uint8_t*)frame.bits(),
            frame.width(),
            frame.height(),
            SNAPSNOT_ANIMATED_FRAME_DELAY_MSEC / 10);
        // Record the current frame timestamp
        snapshotAnimatedTimestamp = QDateTime::currentMSecsSinceEpoch();
        snapshotAnimatedFirstFrameTimestamp = snapshotAnimatedTimestamp;
    }
    return true;
}
