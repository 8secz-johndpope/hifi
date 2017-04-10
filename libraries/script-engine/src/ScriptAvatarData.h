//
//  ScriptAvatarData.h
//  libraries/script-engine/src
//
//  Created by Zach Fox on 2017-04-10.
//  Copyright 2017 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#ifndef hifi_ScriptAvatarData_h
#define hifi_ScriptAvatarData_h

#include <QtCore/QObject>
#include <AvatarData.h>
#include <SpatiallyNestable.h>

class ScriptAvatarData : public QObject, public SpatiallyNestable {
    Q_OBJECT

    //
    // PHYSICAL PROPERTIES: POSITION AND ORIENTATION
    //
    Q_PROPERTY(glm::vec3 position READ getPosition)
    Q_PROPERTY(float scale READ getTargetScale)
    Q_PROPERTY(glm::vec3 handPosition READ getHandPosition)
    Q_PROPERTY(float bodyPitch READ getBodyPitch)
    Q_PROPERTY(float bodyYaw READ getBodyYaw)
    Q_PROPERTY(float bodyRoll READ getBodyRoll)
    Q_PROPERTY(glm::quat orientation READ getOrientation)
    Q_PROPERTY(glm::quat headOrientation READ getHeadOrientation)
    Q_PROPERTY(float headPitch READ getHeadPitch)
    Q_PROPERTY(float headYaw READ getHeadYaw)
    Q_PROPERTY(float headRoll READ getHeadRoll)
    //
    // PHYSICAL PROPERTIES: VELOCITY
    //
    Q_PROPERTY(glm::vec3 velocity READ getVelocity)
    Q_PROPERTY(glm::vec3 angularVelocity READ getAngularVelocity)

    //
    // IDENTIFIER PROPERTIES
    //
    Q_PROPERTY(QUuid sessionUUID READ getSessionUUID)
    Q_PROPERTY(QString displayName READ getDisplayName NOTIFY displayNameChanged)
    Q_PROPERTY(QString sessionDisplayName READ getSessionDisplayName)

    //
    // ATTACHMENT AND JOINT PROPERTIES
    //
    Q_PROPERTY(QString skeletonModelURL READ getSkeletonModelURLFromScript)
    Q_PROPERTY(QVector<AttachmentData> attachmentData READ getAttachmentData)
    Q_PROPERTY(QStringList jointNames READ getJointNames)

    //
    // AUDIO PROPERTIES
    //
    Q_PROPERTY(float audioLoudness READ getAudioLoudness)
    Q_PROPERTY(float audioAverageLoudness READ getAudioAverageLoudness)

    //
    // MATRIX PROPERTIES
    //
    Q_PROPERTY(glm::mat4 sensorToWorldMatrix READ getSensorToWorldMatrix)
    Q_PROPERTY(glm::mat4 controllerLeftHandMatrix READ getControllerLeftHandMatrix)
    Q_PROPERTY(glm::mat4 controllerRightHandMatrix READ getControllerRightHandMatrix)

public:
    ScriptAvatarData(AvatarSharedPointer avatarData);

    //
    // PHYSICAL PROPERTIES: POSITION AND ORIENTATION
    //
    using SpatiallyNestable::getPosition;
    virtual glm::vec3 getPosition() const override;
    const float getTargetScale();
    const glm::vec3 getHandPosition();
    const float getBodyPitch();
    const float getBodyYaw();
    const float getBodyRoll();
    const glm::quat getOrientation();
    const glm::quat getHeadOrientation();
    const float getHeadPitch();
    const float getHeadYaw();
    const float getHeadRoll();
    //
    // PHYSICAL PROPERTIES: VELOCITY
    //
    const glm::vec3 getVelocity();
    const glm::vec3 getAngularVelocity();

    //
    // IDENTIFIER PROPERTIES
    //
    const QUuid getSessionUUID() const;
    const QString getDisplayName();
    const QString getSessionDisplayName();

    //
    // ATTACHMENT AND JOINT PROPERTIES
    //
    const QString getSkeletonModelURLFromScript();
    const QVector<AttachmentData> getAttachmentData();
    const QStringList getJointNames();
    /// Returns the index of the joint with the specified name, or -1 if not found/unknown.
    Q_INVOKABLE virtual int getJointIndex(const QString& name) const;
    Q_INVOKABLE char getHandState() const;
    Q_INVOKABLE virtual glm::quat getJointRotation(int index) const;
    Q_INVOKABLE virtual glm::vec3 getJointTranslation(int index) const;

    //
    // AUDIO PROPERTIES
    //
    const float getAudioLoudness();
    const float getAudioAverageLoudness();

    //
    // MATRIX PROPERTIES
    //
    const glm::mat4 getSensorToWorldMatrix();
    const glm::mat4 getControllerLeftHandMatrix();
    const glm::mat4 getControllerRightHandMatrix();
    
signals:
    void displayNameChanged();

public slots:
    glm::quat getAbsoluteJointRotationInObjectFrame(int index) const;
    glm::vec3 getAbsoluteJointTranslationInObjectFrame(int index) const;

private:
    std::weak_ptr<AvatarData> _avatarData;
};

Q_DECLARE_METATYPE(AvatarSharedPointer)

QScriptValue avatarDataToScriptValue(QScriptEngine* engine, const AvatarSharedPointer& in);
void avatarDataFromScriptValue(const QScriptValue& object, AvatarSharedPointer& out);

#endif // hifi_ScriptAvatarData_h
