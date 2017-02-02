//
//  AudioMixerSlave.cpp
//  assignment-client/src/audio
//
//  Created by Zach Pomerantz on 11/22/16.
//  Copyright 2016 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#include <algorithm>

#include <glm/glm.hpp>
#include <glm/gtx/norm.hpp>
#include <glm/gtx/vector_angle.hpp>

#include <LogHandler.h>
#include <NetworkAccessManager.h>
#include <NodeList.h>
#include <Node.h>
#include <OctreeConstants.h>
#include <plugins/PluginManager.h>
#include <plugins/CodecPlugin.h>
#include <udt/PacketHeaders.h>
#include <SharedUtil.h>
#include <StDev.h>
#include <UUID.h>

#include "AudioRingBuffer.h"
#include "AudioMixer.h"
#include "AudioMixerClientData.h"
#include "AvatarAudioStream.h"
#include "InjectedAudioStream.h"
#include "AudioHelpers.h"

#include "AudioMixerSlave.h"

using AudioStreamMap = AudioMixerClientData::AudioStreamMap;

// packet helpers
std::unique_ptr<NLPacket> createAudioPacket(PacketType type, int size, quint16 sequence, QString codec);
void sendMixPacket(const SharedNodePointer& node, AudioMixerClientData& data, QByteArray& buffer);
void sendSilentPacket(const SharedNodePointer& node, AudioMixerClientData& data);
void sendMutePacket(const SharedNodePointer& node, AudioMixerClientData&);
void sendEnvironmentPacket(const SharedNodePointer& node, AudioMixerClientData& data);

// mix helpers
bool shouldIgnoreNode(const SharedNodePointer& listener, const SharedNodePointer& node);
float gainForSource(const AvatarAudioStream& listeningNodeStream, const PositionalAudioStream& streamToAdd,
        const glm::vec3& relativePosition, bool isEcho);
float azimuthForSource(const AvatarAudioStream& listeningNodeStream, const PositionalAudioStream& streamToAdd,
        const glm::vec3& relativePosition);

void AudioMixerSlave::configure(ConstIter begin, ConstIter end, unsigned int frame, float throttlingRatio) {
    _begin = begin;
    _end = end;
    _frame = frame;
    _throttlingRatio = throttlingRatio;
}

void AudioMixerSlave::mix(const SharedNodePointer& node) {
    // check that the node is valid
    AudioMixerClientData* data = (AudioMixerClientData*)node->getLinkedData();
    if (data == nullptr) {
        return;
    }

    // check that the stream is valid
    auto avatarStream = data->getAvatarAudioStream();
    if (avatarStream == nullptr) {
        return;
    }

    // send mute packet, if necessary
    if (AudioMixer::shouldMute(avatarStream->getQuietestFrameLoudness()) || data->shouldMuteClient()) {
        sendMutePacket(node, *data);
    }

    // send audio packets, if necessary
    if (node->getType() == NodeType::Agent && node->getActiveSocket()) {
        ++stats.sumListeners;

        // mix the audio
        bool mixHasAudio = prepareMix(node);

        // send audio packet
        if (mixHasAudio || data->shouldFlushEncoder()) {
            QByteArray encodedBuffer;
            if (mixHasAudio) {
                // encode the audio
                QByteArray decodedBuffer(reinterpret_cast<char*>(_bufferSamples), AudioConstants::NETWORK_FRAME_BYTES_STEREO);
                data->encode(decodedBuffer, encodedBuffer);
            } else {
                // time to flush (resets shouldFlush until the next encode)
                data->encodeFrameOfZeros(encodedBuffer);
            }

            sendMixPacket(node, *data, encodedBuffer);
        } else {
            sendSilentPacket(node, *data);
        }

        // send environment packet
        sendEnvironmentPacket(node, *data);

        // send stats packet (about every second)
        const unsigned int NUM_FRAMES_PER_SEC = (int)ceil(AudioConstants::NETWORK_FRAMES_PER_SEC);
        if (data->shouldSendStats(_frame % NUM_FRAMES_PER_SEC)) {
            data->sendAudioStreamStatsPackets(node);
        }
    }
}

bool AudioMixerSlave::prepareMix(const SharedNodePointer& listener) {
    AvatarAudioStream* listenerAudioStream = static_cast<AudioMixerClientData*>(listener->getLinkedData())->getAvatarAudioStream();
    AudioMixerClientData* listenerData = static_cast<AudioMixerClientData*>(listener->getLinkedData());

    // zero out the mix for this listener
    memset(_mixSamples, 0, sizeof(_mixSamples));

    bool isThrottling = _throttlingRatio > 0.0f;
    std::vector<std::pair<float, SharedNodePointer>> throttledNodes;

    typedef void (AudioMixerSlave::*MixFunctor)(
            AudioMixerClientData&, const QUuid&, const AvatarAudioStream&, const PositionalAudioStream&);
    auto allStreams = [&](const SharedNodePointer& node, MixFunctor mixFunctor) {
        AudioMixerClientData* nodeData = static_cast<AudioMixerClientData*>(node->getLinkedData());
        for (auto& streamPair : nodeData->getAudioStreams()) {
            auto nodeStream = streamPair.second;
            (this->*mixFunctor)(*listenerData, node->getUUID(), *listenerAudioStream, *nodeStream);
        }
    };

    std::for_each(_begin, _end, [&](const SharedNodePointer& node) {
        if (*node == *listener) {
            AudioMixerClientData* nodeData = static_cast<AudioMixerClientData*>(node->getLinkedData());

            // only mix the echo, if requested
            for (auto& streamPair : nodeData->getAudioStreams()) {
                auto nodeStream = streamPair.second;
                if (nodeStream->shouldLoopbackForNode()) {
                    mixStream(*listenerData, node->getUUID(), *listenerAudioStream, *nodeStream);
                }
            }
        } else if (!shouldIgnoreNode(listener, node)) {
            if (!isThrottling) {
                allStreams(node, &AudioMixerSlave::mixStream);
            } else {
                AudioMixerClientData* nodeData = static_cast<AudioMixerClientData*>(node->getLinkedData());

                // compute the node's max relative volume
                float nodeVolume;
                for (auto& streamPair : nodeData->getAudioStreams()) {
                    auto nodeStream = streamPair.second;
                    float distance = glm::length(nodeStream->getPosition() - listenerAudioStream->getPosition());
                    nodeVolume = std::max(nodeStream->getLastPopOutputTrailingLoudness() / distance, nodeVolume);
                }

                // max-heapify the nodes by relative volume
                throttledNodes.push_back(std::make_pair(nodeVolume, node));
                if (!throttledNodes.empty()) {
                    std::push_heap(throttledNodes.begin(), throttledNodes.end());
                }
            }
        }
    });

    if (isThrottling) {
        // pop the loudest nodes off the heap and mix their streams
        int numToRetain = (int)(std::distance(_begin, _end) * (1 - _throttlingRatio));
        for (int i = 0; i < numToRetain; i++) {
            if (throttledNodes.empty()) {
                break;
            }

            std::pop_heap(throttledNodes.begin(), throttledNodes.end());

            auto& node = throttledNodes.back().second;
            allStreams(node, &AudioMixerSlave::mixStream);

            throttledNodes.pop_back();
        }

        // throttle the remaining nodes' streams
        for (const std::pair<float, SharedNodePointer>& nodePair : throttledNodes) {
            auto& node = nodePair.second;
            allStreams(node, &AudioMixerSlave::throttleStream);
        }
    }

    // use the per listener AudioLimiter to render the mixed data...
    listenerData->audioLimiter.render(_mixSamples, _bufferSamples, AudioConstants::NETWORK_FRAME_SAMPLES_PER_CHANNEL);

    // check for silent audio after the peak limiter has converted the samples
    bool hasAudio = false;
    for (int i = 0; i < AudioConstants::NETWORK_FRAME_SAMPLES_STEREO; ++i) {
        if (_bufferSamples[i] != 0) {
            hasAudio = true;
            break;
        }
    }
    return hasAudio;
}

void AudioMixerSlave::throttleStream(AudioMixerClientData& listenerNodeData, const QUuid& sourceNodeID,
        const AvatarAudioStream& listeningNodeStream, const PositionalAudioStream& streamToAdd) {
    addStream(listenerNodeData, sourceNodeID, listeningNodeStream, streamToAdd, true);
}

void AudioMixerSlave::mixStream(AudioMixerClientData& listenerNodeData, const QUuid& sourceNodeID,
        const AvatarAudioStream& listeningNodeStream, const PositionalAudioStream& streamToAdd) {
    addStream(listenerNodeData, sourceNodeID, listeningNodeStream, streamToAdd, false);
}

void AudioMixerSlave::addStream(AudioMixerClientData& listenerNodeData, const QUuid& sourceNodeID,
        const AvatarAudioStream& listeningNodeStream, const PositionalAudioStream& streamToAdd,
        bool throttle) {
    ++stats.totalMixes;

    // to reduce artifacts we call the HRTF functor for every source, even if throttled or silent
    // this ensures the correct tail from last mixed block and the correct spatialization of next first block

    // check if this is a server echo of a source back to itself
    bool isEcho = (&streamToAdd == &listeningNodeStream);

    glm::vec3 relativePosition = streamToAdd.getPosition() - listeningNodeStream.getPosition();

    float distance = glm::max(glm::length(relativePosition), EPSILON);
    float gain = gainForSource(listeningNodeStream, streamToAdd, relativePosition, isEcho);
    float azimuth = isEcho ? 0.0f : azimuthForSource(listeningNodeStream, listeningNodeStream, relativePosition);
    static const int HRTF_DATASET_INDEX = 1;

    if (!streamToAdd.lastPopSucceeded()) {
        bool forceSilentBlock = true;

        if (!streamToAdd.getLastPopOutput().isNull()) {
            bool isInjector = dynamic_cast<const InjectedAudioStream*>(&streamToAdd);

            // in an injector, just go silent - the injector has likely ended
            // in other inputs (microphone, &c.), repeat with fade to avoid the harsh jump to silence
            if (!isInjector) {
                // calculate its fade factor, which depends on how many times it's already been repeated.
                float fadeFactor = calculateRepeatedFrameFadeFactor(streamToAdd.getConsecutiveNotMixedCount() - 1);
                if (fadeFactor > 0.0f) {
                    // apply the fadeFactor to the gain
                    gain *= fadeFactor;
                    forceSilentBlock = false;
                }
            }
        }

        if (forceSilentBlock) {
            // call renderSilent with a forced silent block to reduce artifacts
            // (this is not done for stereo streams since they do not go through the HRTF)
            if (!streamToAdd.isStereo() && !isEcho) {
                // get the existing listener-source HRTF object, or create a new one
                auto& hrtf = listenerNodeData.hrtfForStream(sourceNodeID, streamToAdd.getStreamIdentifier());

                static int16_t silentMonoBlock[AudioConstants::NETWORK_FRAME_SAMPLES_PER_CHANNEL] = {};
                hrtf.renderSilent(silentMonoBlock, _mixSamples, HRTF_DATASET_INDEX, azimuth, distance, gain,
                                  AudioConstants::NETWORK_FRAME_SAMPLES_PER_CHANNEL);

                ++stats.hrtfSilentRenders;
            }

            return;
        }
    }

    // grab the stream from the ring buffer
    AudioRingBuffer::ConstIterator streamPopOutput = streamToAdd.getLastPopOutput();

    // stereo sources are not passed through HRTF
    if (streamToAdd.isStereo()) {
        for (int i = 0; i < AudioConstants::NETWORK_FRAME_SAMPLES_STEREO; ++i) {
            _mixSamples[i] += float(streamPopOutput[i] * gain / AudioConstants::MAX_SAMPLE_VALUE);
        }

        ++stats.manualStereoMixes;
        return;
    }

    // echo sources are not passed through HRTF
    if (isEcho) {
        for (int i = 0; i < AudioConstants::NETWORK_FRAME_SAMPLES_STEREO; i += 2) {
            auto monoSample = float(streamPopOutput[i / 2] * gain / AudioConstants::MAX_SAMPLE_VALUE);
            _mixSamples[i] += monoSample;
            _mixSamples[i + 1] += monoSample;
        }

        ++stats.manualEchoMixes;
        return;
    }

    // get the existing listener-source HRTF object, or create a new one
    auto& hrtf = listenerNodeData.hrtfForStream(sourceNodeID, streamToAdd.getStreamIdentifier());

    streamPopOutput.readSamples(_bufferSamples, AudioConstants::NETWORK_FRAME_SAMPLES_PER_CHANNEL);

    if (streamToAdd.getLastPopOutputLoudness() == 0.0f) {
        // call renderSilent to reduce artifacts
        hrtf.renderSilent(_bufferSamples, _mixSamples, HRTF_DATASET_INDEX, azimuth, distance, gain,
                          AudioConstants::NETWORK_FRAME_SAMPLES_PER_CHANNEL);

        ++stats.hrtfSilentRenders;
        return;
    }

    if (throttle) {
        // call renderSilent with actual frame data and a gain of 0.0f to reduce artifacts
        hrtf.renderSilent(_bufferSamples, _mixSamples, HRTF_DATASET_INDEX, azimuth, distance, 0.0f,
                          AudioConstants::NETWORK_FRAME_SAMPLES_PER_CHANNEL);

        ++stats.hrtfThrottleRenders;
        return;
    }

    hrtf.render(_bufferSamples, _mixSamples, HRTF_DATASET_INDEX, azimuth, distance, gain,
                AudioConstants::NETWORK_FRAME_SAMPLES_PER_CHANNEL);

    ++stats.hrtfRenders;
}

std::unique_ptr<NLPacket> createAudioPacket(PacketType type, int size, quint16 sequence, QString codec) {
    auto audioPacket = NLPacket::create(type, size);
    audioPacket->writePrimitive(sequence);
    audioPacket->writeString(codec);
    return audioPacket;
}

void sendMixPacket(const SharedNodePointer& node, AudioMixerClientData& data, QByteArray& buffer) {
    static const int MIX_PACKET_SIZE =
        sizeof(quint16) + AudioConstants::MAX_CODEC_NAME_LENGTH_ON_WIRE + AudioConstants::NETWORK_FRAME_BYTES_STEREO;
    quint16 sequence = data.getOutgoingSequenceNumber();
    QString codec = data.getCodecName();
    auto mixPacket = createAudioPacket(PacketType::MixedAudio, MIX_PACKET_SIZE, sequence, codec);

    // pack samples
    mixPacket->write(buffer.constData(), buffer.size());

    // send packet
    DependencyManager::get<NodeList>()->sendPacket(std::move(mixPacket), *node);
    data.incrementOutgoingMixedAudioSequenceNumber();
}

void sendSilentPacket(const SharedNodePointer& node, AudioMixerClientData& data) {
    static const int SILENT_PACKET_SIZE =
        sizeof(quint16) + AudioConstants::MAX_CODEC_NAME_LENGTH_ON_WIRE + sizeof(quint16);
    quint16 sequence = data.getOutgoingSequenceNumber();
    QString codec = data.getCodecName();
    auto mixPacket = createAudioPacket(PacketType::SilentAudioFrame, SILENT_PACKET_SIZE, sequence, codec);

    // pack number of samples
    mixPacket->writePrimitive(AudioConstants::NETWORK_FRAME_SAMPLES_STEREO);

    // send packet
    DependencyManager::get<NodeList>()->sendPacket(std::move(mixPacket), *node);
    data.incrementOutgoingMixedAudioSequenceNumber();
}

void sendMutePacket(const SharedNodePointer& node, AudioMixerClientData& data) {
    auto mutePacket = NLPacket::create(PacketType::NoisyMute, 0);
    DependencyManager::get<NodeList>()->sendPacket(std::move(mutePacket), *node);

    // probably now we just reset the flag, once should do it (?)
    data.setShouldMuteClient(false);
}

void sendEnvironmentPacket(const SharedNodePointer& node, AudioMixerClientData& data) {
    bool hasReverb = false;
    float reverbTime, wetLevel;

    auto& reverbSettings = AudioMixer::getReverbSettings();
    auto& audioZones = AudioMixer::getAudioZones();

    AvatarAudioStream* stream = data.getAvatarAudioStream();
    glm::vec3 streamPosition = stream->getPosition();

    // find reverb properties
    for (int i = 0; i < reverbSettings.size(); ++i) {
        AABox box = audioZones[reverbSettings[i].zone];
        if (box.contains(streamPosition)) {
            hasReverb = true;
            reverbTime = reverbSettings[i].reverbTime;
            wetLevel = reverbSettings[i].wetLevel;
            break;
        }
    }

    // check if data changed
    bool dataChanged = (stream->hasReverb() != hasReverb) ||
        (stream->hasReverb() && (stream->getRevebTime() != reverbTime || stream->getWetLevel() != wetLevel));
    if (dataChanged) {
        // update stream
        if (hasReverb) {
            stream->setReverb(reverbTime, wetLevel);
        } else {
            stream->clearReverb();
        }
    }

    // send packet at change or every so often
    float CHANCE_OF_SEND = 0.01f;
    bool sendData = dataChanged || (randFloat() < CHANCE_OF_SEND);

    if (sendData) {
        // size the packet
        unsigned char bitset = 0;
        int packetSize = sizeof(bitset);
        if (hasReverb) {
            packetSize += sizeof(reverbTime) + sizeof(wetLevel);
        }

        // write the packet
        auto envPacket = NLPacket::create(PacketType::AudioEnvironment, packetSize);
        if (hasReverb) {
            setAtBit(bitset, HAS_REVERB_BIT);
        }
        envPacket->writePrimitive(bitset);
        if (hasReverb) {
            envPacket->writePrimitive(reverbTime);
            envPacket->writePrimitive(wetLevel);
        }

        // send the packet
        DependencyManager::get<NodeList>()->sendPacket(std::move(envPacket), *node);
    }
}

bool shouldIgnoreNode(const SharedNodePointer& listener, const SharedNodePointer& node) {
    AudioMixerClientData* listenerData = static_cast<AudioMixerClientData*>(listener->getLinkedData());
    AudioMixerClientData* nodeData = static_cast<AudioMixerClientData*>(node->getLinkedData());

    // when this is true, the AudioMixer will send Audio data to a client about avatars that have ignored them
    bool getsAnyIgnored = listenerData->getRequestsDomainListData() && listener->getCanKick();

    bool ignore = true;

    if (nodeData &&
            // make sure that it isn't being ignored by our listening node
            ((nodeData->getRequestsDomainListData() && node->getCanKick()) || !listener->isIgnoringNodeWithID(node->getUUID())) &&
            // and that it isn't ignoring our listening node
            (getsAnyIgnored || !node->isIgnoringNodeWithID(listener->getUUID())))  {

        // is either node enabling the space bubble / ignore radius?
        if ((listener->isIgnoreRadiusEnabled() || node->isIgnoreRadiusEnabled())) {
            // define the minimum bubble size
            static const glm::vec3 minBubbleSize = glm::vec3(0.3f, 1.3f, 0.3f);
            glm::vec3 boundingBoxCorner, boundingBoxScale;

            listenerData->getSpaceBubbleData(boundingBoxCorner, boundingBoxScale);
            // set up the bounding box for the listener
            AABox listenerBox(boundingBoxCorner, boundingBoxScale);
            if (glm::any(glm::lessThan(boundingBoxScale, minBubbleSize))) {
                listenerBox.setScaleStayCentered(minBubbleSize);
            }

            nodeData->getSpaceBubbleData(boundingBoxCorner, boundingBoxScale);
            // set up the bounding box for the node
            AABox nodeBox(boundingBoxCorner, boundingBoxScale);
            // Clamp the size of the bounding box to a minimum scale
            if (glm::any(glm::lessThan(boundingBoxScale, minBubbleSize))) {
                nodeBox.setScaleStayCentered(minBubbleSize);
            }

            // quadruple the scale of both bounding boxes
            listenerBox.embiggen(4.0f);
            nodeBox.embiggen(4.0f);

            // perform the collision check between the two bounding boxes
            ignore = listenerBox.touches(nodeBox);
        } else {
            ignore = false;
        }
    }

    return ignore;
}

float gainForSource(const AvatarAudioStream& listeningNodeStream, const PositionalAudioStream& streamToAdd,
        const glm::vec3& relativePosition, bool isEcho) {
    float gain = 1.0f;

    float distanceBetween = glm::length(relativePosition);

    if (distanceBetween < EPSILON) {
        distanceBetween = EPSILON;
    }

    if (streamToAdd.getType() == PositionalAudioStream::Injector) {
        gain *= reinterpret_cast<const InjectedAudioStream*>(&streamToAdd)->getAttenuationRatio();
    }

    if (!isEcho && (streamToAdd.getType() == PositionalAudioStream::Microphone)) {
        //  source is another avatar, apply fixed off-axis attenuation to make them quieter as they turn away from listener
        glm::vec3 rotatedListenerPosition = glm::inverse(streamToAdd.getOrientation()) * relativePosition;

        float angleOfDelivery = glm::angle(glm::vec3(0.0f, 0.0f, -1.0f),
                                           glm::normalize(rotatedListenerPosition));

        const float MAX_OFF_AXIS_ATTENUATION = 0.2f;
        const float OFF_AXIS_ATTENUATION_FORMULA_STEP = (1 - MAX_OFF_AXIS_ATTENUATION) / 2.0f;

        float offAxisCoefficient = MAX_OFF_AXIS_ATTENUATION +
        (OFF_AXIS_ATTENUATION_FORMULA_STEP * (angleOfDelivery / PI_OVER_TWO));

        // multiply the current attenuation coefficient by the calculated off axis coefficient
        gain *= offAxisCoefficient;
    }

    float attenuationPerDoublingInDistance = AudioMixer::getAttenuationPerDoublingInDistance();
    auto& zoneSettings = AudioMixer::getZoneSettings();
    auto& audioZones = AudioMixer::getAudioZones();
    for (int i = 0; i < zoneSettings.length(); ++i) {
        if (audioZones[zoneSettings[i].source].contains(streamToAdd.getPosition()) &&
            audioZones[zoneSettings[i].listener].contains(listeningNodeStream.getPosition())) {
            attenuationPerDoublingInDistance = zoneSettings[i].coefficient;
            break;
        }
    }

    const float ATTENUATION_BEGINS_AT_DISTANCE = 1.0f;
    if (distanceBetween >= ATTENUATION_BEGINS_AT_DISTANCE) {

        // translate the zone setting to gain per log2(distance)
        float g = 1.0f - attenuationPerDoublingInDistance;
        g = (g < EPSILON) ? EPSILON : g;
        g = (g > 1.0f) ? 1.0f : g;

        // calculate the distance coefficient using the distance to this node
        float distanceCoefficient = fastExp2f(fastLog2f(g) * fastLog2f(distanceBetween/ATTENUATION_BEGINS_AT_DISTANCE));

        // multiply the current attenuation coefficient by the distance coefficient
        gain *= distanceCoefficient;
    }

    return gain;
}

float azimuthForSource(const AvatarAudioStream& listeningNodeStream, const PositionalAudioStream& streamToAdd,
        const glm::vec3& relativePosition) {
    glm::quat inverseOrientation = glm::inverse(listeningNodeStream.getOrientation());

    //  Compute sample delay for the two ears to create phase panning
    glm::vec3 rotatedSourcePosition = inverseOrientation * relativePosition;

    // project the rotated source position vector onto the XZ plane
    rotatedSourcePosition.y = 0.0f;

    const float SOURCE_DISTANCE_THRESHOLD = 1e-30f;

    if (glm::length2(rotatedSourcePosition) > SOURCE_DISTANCE_THRESHOLD) {
        // produce an oriented angle about the y-axis
        return glm::orientedAngle(glm::vec3(0.0f, 0.0f, -1.0f), glm::normalize(rotatedSourcePosition), glm::vec3(0.0f, -1.0f, 0.0f));
    } else {
        // there is no distance between listener and source - return no azimuth
        return 0;
    }
}
