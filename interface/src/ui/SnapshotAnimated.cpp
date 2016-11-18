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

QTimer SnapshotAnimated::snapshotAnimatedTimer;
qint64 SnapshotAnimated::snapshotAnimatedTimestamp = 0;
qint64 SnapshotAnimated::snapshotAnimatedFirstFrameTimestamp = 0;
bool SnapshotAnimated::snapshotAnimatedTimerRunning = false;
QString SnapshotAnimated::snapshotAnimatedPath;
QString SnapshotAnimated::snapshotStillPath;
QVector<QImage> SnapshotAnimated::snapshotAnimatedFrameVector;
QVector<qint64> SnapshotAnimated::snapshotAnimatedFrameDelayVector;

GifWriter SnapshotAnimatedProcessor::snapshotAnimatedGifWriter;


Setting::Handle<bool> SnapshotAnimated::alsoTakeAnimatedSnapshot("alsoTakeAnimatedSnapshot", true);
Setting::Handle<float> SnapshotAnimated::snapshotAnimatedDuration("snapshotAnimatedDuration", SNAPSNOT_ANIMATED_DURATION_SECS);

void SnapshotAnimated::saveSnapshotAnimated(QString pathStill, float aspectRatio, Application* app, QSharedPointer<WindowScriptingInterface> dm) {
    // If we're not in the middle of capturing an animated snapshot...
    if (SnapshotAnimated::snapshotAnimatedFirstFrameTimestamp == 0) {
        // Define the output location of the still and animated snapshots.
        SnapshotAnimated::snapshotStillPath = pathStill;
        SnapshotAnimated::snapshotAnimatedPath = pathStill;
        SnapshotAnimated::snapshotAnimatedPath.replace("jpg", "gif");

        // Ensure the snapshot timer is Precise (attempted millisecond precision)
        SnapshotAnimated::snapshotAnimatedTimer.setTimerType(Qt::PreciseTimer);

        // Connect the snapshotAnimatedTimer QTimer to the lambda slot function
        QObject::connect(&(SnapshotAnimated::snapshotAnimatedTimer), &QTimer::timeout, [=] {
            if (SnapshotAnimated::snapshotAnimatedTimerRunning) {
                // Get a screenshot from the display, then scale the screenshot down,
                // then convert it to the image format the GIF library needs,
                // then save all that to the QImage named "frame"
                QImage frame(app->getActiveDisplayPlugin()->getScreenshot(aspectRatio));
                frame = frame.scaledToWidth(SNAPSNOT_ANIMATED_WIDTH);
                snapshotAnimatedFrameVector.push_back(frame);

                // If that was the first frame...
                if (SnapshotAnimated::snapshotAnimatedFirstFrameTimestamp == 0) {
                    // Record the current frame timestamp
                    SnapshotAnimated::snapshotAnimatedTimestamp = QDateTime::currentMSecsSinceEpoch();
                    // Record the first frame timestamp
                    SnapshotAnimated::snapshotAnimatedFirstFrameTimestamp = SnapshotAnimated::snapshotAnimatedTimestamp;
                    snapshotAnimatedFrameDelayVector.push_back(SNAPSNOT_ANIMATED_FRAME_DELAY_MSEC / 10);
                // If this is an intermediate or the final frame...
                } else {
                    // Push the current frame delay onto the vector
                    snapshotAnimatedFrameDelayVector.push_back(round(((float)(QDateTime::currentMSecsSinceEpoch() - SnapshotAnimated::snapshotAnimatedTimestamp)) / 10));
                    // Record the current frame timestamp
                    SnapshotAnimated::snapshotAnimatedTimestamp = QDateTime::currentMSecsSinceEpoch();

                    // If that was the last frame...
                    if ((SnapshotAnimated::snapshotAnimatedTimestamp - SnapshotAnimated::snapshotAnimatedFirstFrameTimestamp) >= (SnapshotAnimated::snapshotAnimatedDuration.get() * MSECS_PER_SECOND)) {
                        // Reset the current frame timestamp
                        SnapshotAnimated::snapshotAnimatedTimestamp = 0;
                        SnapshotAnimated::snapshotAnimatedFirstFrameTimestamp = 0;

                        // Stop the snapshot QTimer. This action by itself DOES NOT GUARANTEE
                        // that the slot will not be called again in the future.
                        // See: http://lists.qt-project.org/pipermail/qt-interest-old/2009-October/013926.html
                        SnapshotAnimated::snapshotAnimatedTimer.stop();
                        SnapshotAnimated::snapshotAnimatedTimerRunning = false;

                        // Kick off the thread that'll pack the frames into the GIF
                        SnapshotAnimatedProcessor* snapshotAnimatedGifProcessor = new SnapshotAnimatedProcessor(
                            SnapshotAnimated::snapshotStillPath,
                            SnapshotAnimated::snapshotAnimatedPath,
                            &SnapshotAnimated::snapshotAnimatedFrameVector,
                            &SnapshotAnimated::snapshotAnimatedFrameDelayVector,
                            dm);
                        snapshotAnimatedGifProcessor->initialize();
                    }
                }
            }
        });

        // Start the snapshotAnimatedTimer QTimer - argument for this is in milliseconds
        SnapshotAnimated::snapshotAnimatedTimer.start(SNAPSNOT_ANIMATED_FRAME_DELAY_MSEC);
        SnapshotAnimated::snapshotAnimatedTimerRunning = true;
    // If we're already in the middle of capturing an animated snapshot...
    } else {
        // Just tell the dependency manager that the capture of the still snapshot has taken place.
        emit dm->snapshotTaken(pathStill, "", false);
    }
}

SnapshotAnimatedProcessor::SnapshotAnimatedProcessor(QString outputPathStill, QString outputPathAnimated, QVector<QImage>* frameVector, QVector<qint64>* frameDelayVector, QSharedPointer<WindowScriptingInterface> dm){
    snapshotStillPath = outputPathStill;
    snapshotAnimatedPath = outputPathAnimated;
    snapshotAnimatedFrameVector = frameVector;
    snapshotAnimatedFrameDelayVector = frameDelayVector;
    snapshotAnimatedDM = dm;
}

bool SnapshotAnimatedProcessor::process() {
    // Create the GIF from the temporary files
    // Write out the header and beginning of the GIF file
    GifBegin(
        &(SnapshotAnimatedProcessor::snapshotAnimatedGifWriter),
        qPrintable(snapshotAnimatedPath),
        (*snapshotAnimatedFrameVector)[0].width(),
        (*snapshotAnimatedFrameVector)[0].height(),
        SNAPSNOT_ANIMATED_FRAME_DELAY_MSEC / 10);
    for (int itr = 0; itr < (*snapshotAnimatedFrameVector).size(); itr++) {
        // Write each frame to the GIF
        GifWriteFrame(&(SnapshotAnimatedProcessor::snapshotAnimatedGifWriter),
            (uint8_t*)(*snapshotAnimatedFrameVector)[itr].convertToFormat(QImage::Format_RGBA8888).bits(),
            (*snapshotAnimatedFrameVector)[itr].width(),
            (*snapshotAnimatedFrameVector)[itr].height(),
            (*snapshotAnimatedFrameDelayVector)[itr]);
    }
    // Write out the end of the GIF
    GifEnd(&(SnapshotAnimatedProcessor::snapshotAnimatedGifWriter));

    // Clear out the frame and frame delay vectors
    (*snapshotAnimatedFrameVector).clear();
    (*snapshotAnimatedFrameDelayVector).clear();

    // Let the dependency manager know that the snapshots have been taken.
    emit snapshotAnimatedDM->snapshotTaken(snapshotStillPath, snapshotAnimatedPath, false);

    this->terminate();
    delete this;

    return true;
}
