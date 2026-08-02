//
//  GameDiceView.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/2.
//

import UIKit
import SceneKit
import CoreHaptics
import CoreMotion
import SnapKit
import OSLog

final class GameDiceView: UIView {

    // MARK: - Types

    private enum HapticError: Error {
        case unsupportedHardware
        case engineUnavailable
        case engineCreationFailed(underlying: Error)
        case engineStartFailed(underlying: Error)
        case patternCreationFailed(underlying: Error)
        case playerCreationFailed(underlying: Error)
        case playbackFailed(underlying: Error)

        var logDescription: String {
            switch self {
            case .unsupportedHardware:
                return "Device does not support Core Haptics"
            case .engineUnavailable:
                return "Haptic engine is not available"
            case .engineCreationFailed(let underlying):
                return "Failed to create haptic engine: \(underlying.localizedDescription)"
            case .engineStartFailed(let underlying):
                return "Failed to start haptic engine: \(underlying.localizedDescription)"
            case .patternCreationFailed(let underlying):
                return "Failed to create haptic pattern: \(underlying.localizedDescription)"
            case .playerCreationFailed(let underlying):
                return "Failed to create haptic player: \(underlying.localizedDescription)"
            case .playbackFailed(let underlying):
                return "Failed to play haptic: \(underlying.localizedDescription)"
            }
        }
    }

    // MARK: - Properties

    private let sceneView = SCNView()
    private let hintLabel = UILabel()
    private let motionManager = CMMotionManager()
    private let arena = DiceArena()
    private let diceNode = DiceNode()

    private var hapticEngine: CHHapticEngine?
    private var lastImpulseTime: CFTimeInterval = 0
    private var lastImpactHapticTime: CFTimeInterval = 0

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        stopMotionUpdates()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        arena.updateSideWalls(for: bounds.size)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startMotionUpdates()
            arena.updateSideWalls(for: bounds.size)
        } else {
            stopMotionUpdates()
        }
    }

    // MARK: - Public

    func shake(intensity: Double = 1.2) {
        diceNode.applyShake(intensity: intensity)
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .black
        setupSceneView()
        setupHintLabel()
        setupScene()
        setupHaptics()
    }

    private func setupSceneView() {
        sceneView.backgroundColor = .black
        sceneView.antialiasingMode = .multisampling4X
        sceneView.allowsCameraControl = false
        sceneView.isPlaying = true
        addSubview(sceneView)
        sceneView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupHintLabel() {
        hintLabel.text = "搖晃手機讓骰子晃動"
        hintLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        hintLabel.font = .preferredFont(forTextStyle: .subheadline)
        hintLabel.textAlignment = .center
        addSubview(hintLabel)
        hintLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(24)
        }
    }

    private func setupScene() {
        arena.scene.physicsWorld.contactDelegate = self
        arena.attach(dice: diceNode)
        sceneView.scene = arena.scene
        sceneView.pointOfView = arena.cameraNode
        sceneView.autoenablesDefaultLighting = false
    }

    // MARK: - Motion

    private func startMotionUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }
        guard !motionManager.isAccelerometerActive else { return }

        motionManager.accelerometerUpdateInterval = 1.0 / 60.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }

            let acceleration = data.acceleration
            let magnitude = sqrt(
                acceleration.x * acceleration.x +
                acceleration.y * acceleration.y +
                acceleration.z * acceleration.z
            )
            let shakeIntensity = abs(magnitude - 1.0)
            guard shakeIntensity > 0.35 else { return }

            let now = CACurrentMediaTime()
            guard now - self.lastImpulseTime > 0.08 else { return }
            self.lastImpulseTime = now
            self.diceNode.applyShake(intensity: shakeIntensity)
        }
    }

    private func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
    }

    // MARK: - Haptics

    private func setupHaptics() {
        do {
            try prepareHapticEngine()
        } catch HapticError.unsupportedHardware {
            hapticEngine = nil
            AppLogger.ui.notice("\(HapticError.unsupportedHardware.logDescription, privacy: .public)")
        } catch let error as HapticError {
            hapticEngine = nil
            AppLogger.ui.error("\(error.logDescription, privacy: .public)")
        } catch {
            hapticEngine = nil
            AppLogger.ui.error("Unknown haptic setup error: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func prepareHapticEngine() throws {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            throw HapticError.unsupportedHardware
        }

        let engine: CHHapticEngine
        do {
            engine = try CHHapticEngine()
        } catch {
            throw HapticError.engineCreationFailed(underlying: error)
        }

        engine.resetHandler = { [weak self] in
            self?.handleHapticEngineReset()
        }
        engine.stoppedHandler = { [weak self] reason in
            self?.handleHapticEngineStopped(reason: reason)
        }

        do {
            try engine.start()
        } catch {
            throw HapticError.engineStartFailed(underlying: error)
        }

        hapticEngine = engine
    }

    private func handleHapticEngineReset() {
        do {
            guard let engine = hapticEngine else {
                throw HapticError.engineUnavailable
            }
            do {
                try engine.start()
            } catch {
                throw HapticError.engineStartFailed(underlying: error)
            }
            AppLogger.ui.info("Haptic engine restarted")
        } catch let error as HapticError {
            hapticEngine = nil
            AppLogger.ui.error("Haptic engine reset failed: \(error.logDescription, privacy: .public)")
        } catch {
            hapticEngine = nil
            AppLogger.ui.error("Haptic engine reset failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func handleHapticEngineStopped(reason: CHHapticEngine.StoppedReason) {
        AppLogger.ui.warning("Haptic engine stopped, reason: \(String(describing: reason), privacy: .public)")
        hapticEngine = nil
    }

    private func playImpactHaptic(intensity: Float) {
        do {
            try performImpactHaptic(intensity: intensity)
        } catch let error as HapticError {
            switch error {
            case .unsupportedHardware, .engineUnavailable:
                return
            case .engineCreationFailed, .engineStartFailed,
                 .patternCreationFailed, .playerCreationFailed, .playbackFailed:
                AppLogger.ui.error("\(error.logDescription, privacy: .public)")
            }
        } catch {
            AppLogger.ui.error("Unknown haptic playback error: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func performImpactHaptic(intensity: Float) throws {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            throw HapticError.unsupportedHardware
        }
        guard let engine = hapticEngine else {
            throw HapticError.engineUnavailable
        }

        let clamped = min(max(intensity, 0.25), 1.0)

        do {
            try engine.start()
        } catch {
            throw HapticError.engineStartFailed(underlying: error)
        }

        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: clamped)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0
        )

        let pattern: CHHapticPattern
        do {
            pattern = try CHHapticPattern(events: [event], parameters: [])
        } catch {
            throw HapticError.patternCreationFailed(underlying: error)
        }

        let player: CHHapticPatternPlayer
        do {
            player = try engine.makePlayer(with: pattern)
        } catch {
            throw HapticError.playerCreationFailed(underlying: error)
        }

        do {
            try player.start(atTime: 0)
        } catch {
            throw HapticError.playbackFailed(underlying: error)
        }
    }
}

// MARK: - SCNPhysicsContactDelegate

extension GameDiceView: SCNPhysicsContactDelegate {

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard let bodyA = contact.nodeA.physicsBody,
              let bodyB = contact.nodeB.physicsBody else { return }

        let categories = bodyA.categoryBitMask | bodyB.categoryBitMask
        guard categories == (DicePhysicsCategory.dice | DicePhysicsCategory.boundary) else { return }

        let speed = DiceNode.impactSpeed(for: contact)
        guard speed > 0.8 else { return }

        let now = CACurrentMediaTime()
        guard now - lastImpactHapticTime > 0.06 else { return }
        lastImpactHapticTime = now

        let intensity = min(speed / 6.0, 1.0)
        DispatchQueue.main.async { [weak self] in
            self?.playImpactHaptic(intensity: intensity)
        }
    }
}
