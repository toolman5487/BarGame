//
//  GameDiceView.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/2.
//

import UIKit
import SceneKit
import CoreHaptics
import SnapKit
import OSLog

nonisolated enum DiceSceneAppearance: Sendable {
    case walnut
    case systemBackground
}

nonisolated enum DiceCameraViewpoint: Sendable {
    case elevated
    case horizontal
}

@MainActor
final class GameDiceView: UIView {

    // MARK: - Types

    nonisolated struct Configuration: Sendable {

        let initialDiceCount: Int
        let maximumDiceCount: Int
        let preferredEdgeLength: CGFloat?
        let sceneAppearance: DiceSceneAppearance
        let cameraViewpoint: DiceCameraViewpoint

        init(
            initialDiceCount: Int,
            maximumDiceCount: Int,
            preferredEdgeLength: CGFloat? = nil,
            sceneAppearance: DiceSceneAppearance = .walnut,
            cameraViewpoint: DiceCameraViewpoint = .elevated
        ) {
            self.initialDiceCount = initialDiceCount
            self.maximumDiceCount = maximumDiceCount
            self.preferredEdgeLength = preferredEdgeLength
            self.sceneAppearance = sceneAppearance
            self.cameraViewpoint = cameraViewpoint
        }
    }

    private enum MotionTuning {
        static let updateInterval: TimeInterval = 1.0 / 60.0
        static let minimumImpulseMagnitude = 0.28
        static let impulseCooldown: CFTimeInterval = 0.12
        static let horizontalForceScale: Float = 3.6
        static let verticalForceScale: Float = 2.8
        static let rotationScale: Float = 0.35
        static let forceJitterRatio: Float = 0.12
    }

    private enum ImpactFeedback {
        static let minimumImpulse: Float = 0.03
        static let fullIntensityImpulse: Float = 2.2
        static let minimumSpeed: Float = 0.8
        static let fullIntensitySpeed: Float = 6
        static let cooldown: CFTimeInterval = 0.06
    }

    private enum DiceSizing {
        static let largestEdgeLength: CGFloat = 0.72
        static let smallestEdgeLength: CGFloat = 0.44

        static func edgeLength(for diceCount: Int, maximumDiceCount: Int) -> CGFloat {
            let upperBound = max(maximumDiceCount, 1)
            let boundedCount = min(max(diceCount, 1), upperBound)
            guard upperBound > 1 else { return largestEdgeLength }

            let progress = CGFloat(boundedCount - 1) / CGFloat(upperBound - 1)
            return largestEdgeLength - (largestEdgeLength - smallestEdgeLength) * progress
        }
    }

    private enum DiceSpawnLayout {
        static let ringRadius: Float = 0.82
        static let positionsPerRing = 7
        static let baseHeight: Float = 1.4
        static let layerHeight: Float = 0.7
    }

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

    // MARK: - UI Elements

    private let sceneView: SCNView = {
        let sceneView = SCNView()
        sceneView.backgroundColor = .black
        sceneView.antialiasingMode = .multisampling4X
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.isPlaying = true
        return sceneView
    }()

    // MARK: - Dependencies

    private let configuration: Configuration
    private let motionUpdatesProvider: any MotionUpdatesProviding
    private let arena: DiceArena
    private let fallbackImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)

    // MARK: - State

    private var diceNodes: [DiceNode] = []
    private var isInteractionLocked = false
    private var hapticEngine: CHHapticEngine?
    private var lastImpulseTime: CFTimeInterval = 0
    private var lastImpactHapticTime: CFTimeInterval = 0
    private var motionUpdatesTask: Task<Void, Never>?
    private var applicationLifecycleTask: Task<Void, Never>?

    // MARK: - Lifecycle

    convenience init(configuration: Configuration) {
        self.init(
            configuration: configuration,
            motionUpdatesProvider: CoreMotionUpdatesProvider()
        )
    }

    init(
        configuration: Configuration,
        motionUpdatesProvider: any MotionUpdatesProviding
    ) {
        self.configuration = configuration
        self.motionUpdatesProvider = motionUpdatesProvider
        arena = DiceArena(
            sceneAppearance: configuration.sceneAppearance,
            cameraViewpoint: configuration.cameraViewpoint
        )
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        sceneView.backgroundColor = configuration.sceneAppearance.backgroundColor
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        motionUpdatesTask?.cancel()
        applicationLifecycleTask?.cancel()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        arena.updateViewportBoundaries(for: bounds.size)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startMotionUpdates()
            arena.updateViewportBoundaries(for: bounds.size)
        } else {
            stopMotionUpdates()
        }
    }

    // MARK: - Public

    var canAddDice: Bool {
        !isInteractionLocked && diceNodes.count < configuration.maximumDiceCount
    }

    func shake(intensity: Double = 1.2) {
        guard !isInteractionLocked else { return }
        diceNodes.forEach { $0.applyShake(intensity: intensity) }
    }

    @discardableResult
    func addDice() -> Bool {
        guard canAddDice else { return false }

        let diceNode = makeDiceNode()
        diceNode.applyShake(intensity: 0.7)
        return true
    }

    func setInteractionLocked(_ isLocked: Bool) {
        isInteractionLocked = isLocked
        diceNodes.forEach { $0.setLocked(isLocked) }
    }

    func showTopDownView() {
        arena.showTopDownView()
    }

    func showPerspectiveView() {
        arena.showPerspectiveView()
    }

    // MARK: - Setup

    private func setup() {
        setupViewHierarchy()
        setupViewLayout()
        setupScene()
        setupHaptics()
        observeApplicationLifecycle()
    }

    private func setupViewHierarchy() {
        addSubview(sceneView)
    }

    private func setupViewLayout() {
        sceneView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupScene() {
        arena.scene.physicsWorld.contactDelegate = self
        for _ in 0..<configuration.initialDiceCount {
            makeDiceNode()
        }
        sceneView.scene = arena.scene
        sceneView.pointOfView = arena.cameraNode
    }

    @discardableResult
    private func makeDiceNode() -> DiceNode {
        let updatedDiceCount = diceNodes.count + 1
        let edgeLength = edgeLength(for: updatedDiceCount)
        diceNodes.forEach { $0.resize(to: edgeLength) }

        let diceNode = DiceNode(edgeLength: edgeLength)
        let position = spawnPosition(for: diceNodes.count)
        diceNodes.append(diceNode)
        arena.attach(dice: diceNode, at: position)
        return diceNode
    }

    private func edgeLength(for diceCount: Int) -> CGFloat {
        if let preferredEdgeLength = configuration.preferredEdgeLength {
            return preferredEdgeLength
        }

        return DiceSizing.edgeLength(
            for: diceCount,
            maximumDiceCount: configuration.maximumDiceCount
        )
    }

    private func spawnPosition(for index: Int) -> SCNVector3 {
        guard index > 0 else {
            return SCNVector3(0, DiceSpawnLayout.baseHeight, 0)
        }

        let adjustedIndex = index - 1
        let ringIndex = adjustedIndex % DiceSpawnLayout.positionsPerRing
        let verticalLayer = adjustedIndex / DiceSpawnLayout.positionsPerRing
        let angle = Float(ringIndex) * 2 * .pi / Float(DiceSpawnLayout.positionsPerRing)
        return SCNVector3(
            cos(angle) * DiceSpawnLayout.ringRadius,
            DiceSpawnLayout.baseHeight + Float(verticalLayer) * DiceSpawnLayout.layerHeight,
            sin(angle) * DiceSpawnLayout.ringRadius
        )
    }

    // MARK: - Motion

    private func startMotionUpdates() {
        guard motionUpdatesTask == nil else { return }

        motionUpdatesTask = Task { [weak self, motionUpdatesProvider] in
            let updates = await motionUpdatesProvider.makeUpdates(
                interval: MotionTuning.updateInterval
            )
            for await update in updates {
                guard let self else { return }
                handleMotionUpdate(update)
            }
        }
    }

    private func stopMotionUpdates() {
        motionUpdatesTask?.cancel()
        motionUpdatesTask = nil
    }

    private func handleMotionUpdate(_ update: MotionUpdate) {
        switch update {
        case .deviceMotion(let sample):
            handleDeviceMotion(sample)
        case .accelerometer(let acceleration):
            handleAccelerometerUpdate(acceleration)
        case .failed(let error):
            AppLogger.ui.error("\(error.logDescription, privacy: .public)")
        }
    }

    private func handleDeviceMotion(_ sample: DeviceMotionSample) {
        guard !isInteractionLocked else { return }

        arena.updateGravity(
            deviceTiltX: sample.gravity.x,
            deviceTiltY: sample.gravity.y
        )

        let acceleration = sample.userAcceleration
        let magnitude = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )
        guard magnitude > MotionTuning.minimumImpulseMagnitude else { return }

        let now = CACurrentMediaTime()
        guard now - lastImpulseTime > MotionTuning.impulseCooldown else { return }
        lastImpulseTime = now

        let force = SCNVector3(
            Float(acceleration.x) * MotionTuning.horizontalForceScale,
            Float(magnitude) * MotionTuning.verticalForceScale,
            -Float(acceleration.y) * MotionTuning.horizontalForceScale
        )
        let torque = makeTorque(
            rotationRate: sample.rotationRate,
            fallbackIntensity: Float(magnitude)
        )

        diceNodes.forEach { diceNode in
            diceNode.applyMotionImpulse(
                force: force.addingRandomJitter(
                    ratio: MotionTuning.forceJitterRatio,
                    intensity: Float(magnitude)
                ),
                torque: torque
            )
        }
    }

    private func handleAccelerometerUpdate(_ acceleration: MotionVector) {
        let magnitude = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )
        let shakeIntensity = abs(magnitude - 1.0)
        guard shakeIntensity > 0.35 else { return }

        let now = CACurrentMediaTime()
        guard now - lastImpulseTime > MotionTuning.impulseCooldown else { return }
        lastImpulseTime = now
        shake(intensity: shakeIntensity)
    }

    private func makeTorque(
        rotationRate: MotionVector,
        fallbackIntensity: Float
    ) -> SCNVector4 {
        let x = Float(rotationRate.x)
        let y = Float(rotationRate.z)
        let z = -Float(rotationRate.y)
        let magnitude = sqrt(x * x + y * y + z * z)

        guard magnitude > 0.01 else {
            return SCNVector4(1, 0, 0, fallbackIntensity)
        }

        let angle = max(magnitude * MotionTuning.rotationScale, fallbackIntensity)
        return SCNVector4(x / magnitude, y / magnitude, z / magnitude, angle)
    }

    // MARK: - Haptics

    private func setupHaptics() {
        fallbackImpactFeedbackGenerator.prepare()

        do {
            try prepareHapticEngineIfNeeded()
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

    private func observeApplicationLifecycle() {
        applicationLifecycleTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(
                named: UIApplication.didBecomeActiveNotification
            )
            for await _ in notifications {
                guard let self else { return }
                setupHaptics()
            }
        }
    }

    private func prepareHapticEngineIfNeeded() throws {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            throw HapticError.unsupportedHardware
        }

        if let engine = hapticEngine {
            do {
                try engine.start()
                return
            } catch {
                hapticEngine = nil
                AppLogger.ui.warning(
                    "Existing haptic engine failed to restart: \(error.localizedDescription, privacy: .public)"
                )
            }
        }

        try prepareHapticEngine()
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
            Task { @MainActor [weak self] in
                self?.handleHapticEngineReset()
            }
        }
        engine.stoppedHandler = { [weak self] reason in
            Task { @MainActor [weak self] in
                self?.handleHapticEngineStopped(reason: reason)
            }
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
                AppLogger.ui.notice("\(error.logDescription, privacy: .public)")
            case .engineCreationFailed, .engineStartFailed,
                 .patternCreationFailed, .playerCreationFailed, .playbackFailed:
                AppLogger.ui.error("\(error.logDescription, privacy: .public)")
            }
            playFallbackImpact(intensity: intensity)
        } catch {
            AppLogger.ui.error("Unknown haptic playback error: \(error.localizedDescription, privacy: .public)")
            playFallbackImpact(intensity: intensity)
        }
    }

    private func performImpactHaptic(intensity: Float) throws {
        try prepareHapticEngineIfNeeded()

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

    private func playFallbackImpact(intensity: Float) {
        let clamped = min(max(intensity, 0.25), 1.0)
        fallbackImpactFeedbackGenerator.impactOccurred(intensity: CGFloat(clamped))
        fallbackImpactFeedbackGenerator.prepare()
    }

    private func handleImpactFeedback(
        collisionImpulse: Float,
        impactSpeed: Float
    ) {
        guard collisionImpulse > ImpactFeedback.minimumImpulse ||
                impactSpeed > ImpactFeedback.minimumSpeed else { return }

        let now = CACurrentMediaTime()
        guard now - lastImpactHapticTime > ImpactFeedback.cooldown else { return }
        lastImpactHapticTime = now

        let impulseIntensity = min(
            collisionImpulse / ImpactFeedback.fullIntensityImpulse,
            1.0
        )
        let speedIntensity = min(
            impactSpeed / ImpactFeedback.fullIntensitySpeed,
            1.0
        )
        playImpactHaptic(intensity: max(impulseIntensity, speedIntensity))
    }
}

private extension DiceSceneAppearance {

    var backgroundColor: UIColor {
        switch self {
        case .walnut:
            return .black

        case .systemBackground:
            return .systemBackground
        }
    }
}

// MARK: - SCNPhysicsContactDelegate

extension GameDiceView: SCNPhysicsContactDelegate {

    nonisolated func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard let bodyA = contact.nodeA.physicsBody,
              let bodyB = contact.nodeB.physicsBody else { return }

        let categories = bodyA.categoryBitMask | bodyB.categoryBitMask
        let isBoundaryImpact = categories == (
            DicePhysicsCategory.dice | DicePhysicsCategory.boundary
        )
        let isDiceImpact = bodyA.categoryBitMask == DicePhysicsCategory.dice &&
            bodyB.categoryBitMask == DicePhysicsCategory.dice
        guard isBoundaryImpact || isDiceImpact else { return }

        let collisionImpulse = Float(contact.collisionImpulse)
        let impactSpeed = DiceNode.impactSpeed(for: contact)

        Task { @MainActor [weak self] in
            self?.handleImpactFeedback(
                collisionImpulse: collisionImpulse,
                impactSpeed: impactSpeed
            )
        }
    }
}

private extension SCNVector3 {

    func addingRandomJitter(ratio: Float, intensity: Float) -> SCNVector3 {
        let jitter = ratio * intensity
        return SCNVector3(
            x + Float.random(in: -jitter...jitter),
            y + Float.random(in: -jitter...jitter),
            z + Float.random(in: -jitter...jitter)
        )
    }
}
