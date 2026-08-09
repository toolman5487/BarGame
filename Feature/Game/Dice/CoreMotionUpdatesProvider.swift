//
//  CoreMotionUpdatesProvider.swift
//  BarGame
//
//  Created by Codex on 2026/8/7.
//

import CoreMotion
import Foundation

nonisolated struct MotionVector: Sendable {

    let x: Double
    let y: Double
    let z: Double
}

nonisolated struct DeviceMotionSample: Sendable {

    let gravity: MotionVector
    let userAcceleration: MotionVector
    let rotationRate: MotionVector
}

nonisolated enum MotionUpdateError: Error, Sendable {

    case unavailable
    case updateFailed(message: String)

    var logDescription: String {
        switch self {
        case .unavailable:
            return "Motion sensors are not available"
        case .updateFailed(let message):
            return "Motion update failed: \(message)"
        }
    }
}

nonisolated enum MotionUpdate: Sendable {

    case deviceMotion(DeviceMotionSample)
    case accelerometer(MotionVector)
    case failed(MotionUpdateError)
}

nonisolated protocol MotionUpdatesProviding: Sendable {

    func makeUpdates(interval: TimeInterval) async -> AsyncStream<MotionUpdate>
}

actor CoreMotionUpdatesProvider: MotionUpdatesProviding {

    private let motionManager: CMMotionManager
    private var activeContinuation: AsyncStream<MotionUpdate>.Continuation?
    private var activeStreamID: UUID?

    init() {
        motionManager = CMMotionManager()
    }

    func makeUpdates(interval: TimeInterval) -> AsyncStream<MotionUpdate> {
        stopUpdates()

        let streamID = UUID()
        activeStreamID = streamID
        let (stream, continuation) = AsyncStream<MotionUpdate>.makeStream(
            bufferingPolicy: .bufferingNewest(1)
        )

        activeContinuation = continuation
        continuation.onTermination = { @Sendable [weak self] _ in
            Task { [weak self] in
                await self?.stopUpdates(for: streamID)
            }
        }

        if motionManager.isDeviceMotionAvailable {
            startDeviceMotionUpdates(
                interval: interval,
                continuation: continuation
            )
        } else if motionManager.isAccelerometerAvailable {
            startAccelerometerUpdates(
                interval: interval,
                continuation: continuation
            )
        } else {
            continuation.yield(.failed(.unavailable))
            continuation.finish()
        }

        return stream
    }

    private func stopUpdates() {
        activeStreamID = nil
        activeContinuation?.finish()
        activeContinuation = nil
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
    }

    private func startDeviceMotionUpdates(
        interval: TimeInterval,
        continuation: AsyncStream<MotionUpdate>.Continuation
    ) {
        motionManager.deviceMotionUpdateInterval = interval
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: .main
        ) { motion, error in
            if let motion {
                continuation.yield(
                    .deviceMotion(
                        DeviceMotionSample(
                            gravity: MotionVector(
                                x: motion.gravity.x,
                                y: motion.gravity.y,
                                z: motion.gravity.z
                            ),
                            userAcceleration: MotionVector(
                                x: motion.userAcceleration.x,
                                y: motion.userAcceleration.y,
                                z: motion.userAcceleration.z
                            ),
                            rotationRate: MotionVector(
                                x: motion.rotationRate.x,
                                y: motion.rotationRate.y,
                                z: motion.rotationRate.z
                            )
                        )
                    )
                )
            } else if let error {
                continuation.yield(
                    .failed(.updateFailed(message: error.localizedDescription))
                )
                continuation.finish()
            }
        }
    }

    private func startAccelerometerUpdates(
        interval: TimeInterval,
        continuation: AsyncStream<MotionUpdate>.Continuation
    ) {
        motionManager.accelerometerUpdateInterval = interval
        motionManager.startAccelerometerUpdates(to: .main) { data, error in
            if let acceleration = data?.acceleration {
                continuation.yield(
                    .accelerometer(
                        MotionVector(
                            x: acceleration.x,
                            y: acceleration.y,
                            z: acceleration.z
                        )
                    )
                )
            } else if let error {
                continuation.yield(
                    .failed(.updateFailed(message: error.localizedDescription))
                )
                continuation.finish()
            }
        }
    }

    private func stopUpdates(for streamID: UUID) {
        guard activeStreamID == streamID else { return }
        stopUpdates()
    }
}
