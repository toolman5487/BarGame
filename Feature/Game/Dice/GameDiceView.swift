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

        let initialDiceCountState: DiceCountState
        let maximumDiceCount: Int
        let preferredEdgeLength: CGFloat?
        let preferredCameraDistance: Float?
        let sceneAppearance: DiceSceneAppearance
        let cameraViewpoint: DiceCameraViewpoint
        let showsPhysicsShapes: Bool

        init(
            initialDiceCount: Int? = nil,
            maximumDiceCount: Int,
            preferredEdgeLength: CGFloat? = nil,
            preferredCameraDistance: Float? = nil,
            sceneAppearance: DiceSceneAppearance = .walnut,
            cameraViewpoint: DiceCameraViewpoint = .elevated,
            showsPhysicsShapes: Bool = false
        ) {
            let validatedMaximumDiceCount = max(maximumDiceCount, 1)
            self.init(
                initialDiceCountState: DiceCountState(
                    resolving: initialDiceCount,
                    default: 1,
                    within: 1...validatedMaximumDiceCount
                ),
                maximumDiceCount: validatedMaximumDiceCount,
                preferredEdgeLength: preferredEdgeLength,
                preferredCameraDistance: preferredCameraDistance,
                sceneAppearance: sceneAppearance,
                cameraViewpoint: cameraViewpoint,
                showsPhysicsShapes: showsPhysicsShapes
            )
        }

        init(
            initialDiceCountState: DiceCountState,
            maximumDiceCount: Int,
            preferredEdgeLength: CGFloat? = nil,
            preferredCameraDistance: Float? = nil,
            sceneAppearance: DiceSceneAppearance = .walnut,
            cameraViewpoint: DiceCameraViewpoint = .elevated,
            showsPhysicsShapes: Bool = false
        ) {
            let validatedMaximumDiceCount = max(maximumDiceCount, 1)
            self.initialDiceCountState = initialDiceCountState.limited(
                to: 1...validatedMaximumDiceCount
            )
            self.maximumDiceCount = validatedMaximumDiceCount
            self.preferredEdgeLength = preferredEdgeLength
            self.preferredCameraDistance = preferredCameraDistance
            self.sceneAppearance = sceneAppearance
            self.cameraViewpoint = cameraViewpoint
            self.showsPhysicsShapes = showsPhysicsShapes
        }
    }

    private enum MotionTuning {
        static let updateInterval: TimeInterval = 1.0 / 60.0
        static let minimumImpulseMagnitude = 0.22
        static let impulseCooldown: CFTimeInterval = 0.09
        static let horizontalImpulseScale: Float = 4.8
        static let verticalImpulseScale: Float = 4
        static let angularImpulseScale: Float = 0.72
        static let minimumTumblingImpulse: Float = 0.75
        static let linearImpulseJitterRatio: Float = 0.16
        static let angularImpulseJitterRatio: Float = 0.1
    }

    private enum ImpactFeedback {
        static let minimumImpulse: Float = 0.05
        static let fullIntensityImpulse: Float = 3.4
        static let minimumSpeed: Float = 1.1
        static let fullIntensitySpeed: Float = 9
        static let cooldown: CFTimeInterval = 0.06
    }

    private enum DiceSizing {
        static let largestEdgeLength: CGFloat = 0.72
        static let smallestEdgeLength: CGFloat = 0.44

        static func edgeLength(for diceCount: Int, maximumDiceCount: Int) -> CGFloat {
            guard maximumDiceCount > 1 else { return largestEdgeLength }

            let progress = CGFloat(diceCount - 1) / CGFloat(maximumDiceCount - 1)
            return largestEdgeLength - (largestEdgeLength - smallestEdgeLength) * progress
        }
    }

    private enum DiceSpawnMetrics {
        static let ringRadius: Float = 0.82
        static let maximumDiceCountPerLayer = 8
        static let initialHeight: Float = 1.4
        static let verticalLayerSpacing: Float = 0.7
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
        sceneView.backgroundColor = .systemBackground
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
            cameraViewpoint: configuration.cameraViewpoint,
            preferredCameraDistance: configuration.preferredCameraDistance
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

    func shake(intensity: Double = 1.2) {
        guard !isInteractionLocked else { return }
        diceNodes.forEach { $0.applyShake(intensity: intensity) }
    }

    func setInteractionLocked(_ isLocked: Bool) {
        guard isInteractionLocked != isLocked else { return }

        isInteractionLocked = isLocked
        arena.setPhysicsSimulationPaused(isLocked)
    }

    func currentValues() -> [Int] {
        diceNodes.map(\.topFaceValue)
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
        configurePhysicsShapeDebugging()
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
        switch configuration.initialDiceCountState {
        case .defaulted(let diceCount):
            let edgeLength = edgeLength(for: diceCount)
            for position in spawnPositions(for: diceCount) {
                makeDiceNode(edgeLength: edgeLength, at: position)
            }

        case .configured(let diceCount):
            let edgeLength = edgeLength(for: diceCount)
            for position in spawnPositions(for: diceCount) {
                makeDiceNode(edgeLength: edgeLength, at: position)
            }

        case .empty:
            break
        }
        sceneView.scene = arena.scene
        sceneView.pointOfView = arena.cameraNode
    }

    private func configurePhysicsShapeDebugging() {
        #if DEBUG
        if configuration.showsPhysicsShapes {
            sceneView.debugOptions.insert(.showPhysicsShapes)
        }
        #endif
    }

    private func makeDiceNode(
        edgeLength: CGFloat,
        at position: SCNVector3
    ) {
        let diceNode = DiceNode(
            edgeLength: edgeLength,
            referenceEdgeLength: referenceEdgeLength
        )
        diceNodes.append(diceNode)
        arena.attach(dice: diceNode, at: position)
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

    private var referenceEdgeLength: CGFloat {
        configuration.preferredEdgeLength ?? DiceSizing.largestEdgeLength
    }

    private func spawnPositions(for diceCount: Int) -> [SCNVector3] {
        guard diceCount > 1 else {
            return [SCNVector3(0, DiceSpawnMetrics.initialHeight, 0)]
        }

        let maximumDiceCountPerLayer = DiceSpawnMetrics.maximumDiceCountPerLayer
        let layerCount = (
            diceCount + maximumDiceCountPerLayer - 1
        ) / maximumDiceCountPerLayer
        let minimumDiceCountPerLayer = diceCount / layerCount
        let layersWithAdditionalDie = diceCount % layerCount

        return (0..<layerCount).flatMap { layerIndex in
            let diceCountInLayer = minimumDiceCountPerLayer + (
                layerIndex < layersWithAdditionalDie ? 1 : 0
            )
            let angleBetweenDice = 2 * Float.pi / Float(diceCountInLayer)
            let layerAngleOffset = layerIndex.isMultiple(of: 2)
                ? 0
                : angleBetweenDice / 2
            let height = DiceSpawnMetrics.initialHeight +
                Float(layerIndex) * DiceSpawnMetrics.verticalLayerSpacing

            return (0..<diceCountInLayer).map { diceIndex in
                let angle = Float(diceIndex) * angleBetweenDice + layerAngleOffset
                return SCNVector3(
                    cos(angle) * DiceSpawnMetrics.ringRadius,
                    height,
                    sin(angle) * DiceSpawnMetrics.ringRadius
                )
            }
        }
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

        let linearImpulse = SCNVector3(
            Float(acceleration.x) * MotionTuning.horizontalImpulseScale,
            Float(magnitude) * MotionTuning.verticalImpulseScale,
            -Float(acceleration.y) * MotionTuning.horizontalImpulseScale
        )
        let angularImpulse = makeAngularImpulse(
            rotationRate: sample.rotationRate,
            fallbackIntensity: Float(magnitude)
        )

        diceNodes.forEach { diceNode in
            diceNode.applyMotionImpulse(
                linearImpulse: linearImpulse.addingRandomJitter(
                    ratio: MotionTuning.linearImpulseJitterRatio,
                    intensity: Float(magnitude)
                ),
                angularImpulse: angularImpulse.addingRandomJitter(
                    ratio: MotionTuning.angularImpulseJitterRatio
                )
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

    private func makeAngularImpulse(
        rotationRate: MotionVector,
        fallbackIntensity: Float
    ) -> SCNVector4 {
        let x = Float(rotationRate.x)
        let y = Float(rotationRate.z)
        let z = -Float(rotationRate.y)
        let rotationMagnitude = sqrt(x * x + y * y + z * z)
        let horizontalAxisMagnitude = sqrt(x * x + z * z)
        let impulseMagnitude = max(
            rotationMagnitude * MotionTuning.angularImpulseScale,
            fallbackIntensity,
            MotionTuning.minimumTumblingImpulse
        )

        guard horizontalAxisMagnitude > 0.01 else {
            let fallbackAxisAngle = Float.random(in: 0...(2 * .pi))
            return SCNVector4(
                cos(fallbackAxisAngle),
                0,
                sin(fallbackAxisAngle),
                impulseMagnitude
            )
        }

        return SCNVector4(
            x / horizontalAxisMagnitude,
            0,
            z / horizontalAxisMagnitude,
            impulseMagnitude
        )
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
            case .unsupportedHardware:
                AppLogger.ui.notice("\(error.logDescription, privacy: .public)")

            case .engineUnavailable:
                AppLogger.ui.notice("\(error.logDescription, privacy: .public)")

            case .engineCreationFailed:
                AppLogger.ui.error("\(error.logDescription, privacy: .public)")

            case .engineStartFailed:
                AppLogger.ui.error("\(error.logDescription, privacy: .public)")

            case .patternCreationFailed:
                AppLogger.ui.error("\(error.logDescription, privacy: .public)")

            case .playerCreationFailed:
                AppLogger.ui.error("\(error.logDescription, privacy: .public)")

            case .playbackFailed:
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

private extension SCNVector4 {

    func addingRandomJitter(ratio: Float) -> SCNVector4 {
        let clampedRatio = min(max(ratio, 0), 0.5)
        let jitteredX = x + Float.random(in: -clampedRatio...clampedRatio)
        let jitteredY = y + Float.random(in: -clampedRatio...clampedRatio)
        let jitteredZ = z + Float.random(in: -clampedRatio...clampedRatio)
        let axisMagnitude = sqrt(
            jitteredX * jitteredX +
                jitteredY * jitteredY +
                jitteredZ * jitteredZ
        )

        guard axisMagnitude > .ulpOfOne else {
            return SCNVector4(1, 0, 0, w)
        }

        let magnitudeScale = Float.random(
            in: (1 - clampedRatio)...(1 + clampedRatio)
        )
        return SCNVector4(
            jitteredX / axisMagnitude,
            jitteredY / axisMagnitude,
            jitteredZ / axisMagnitude,
            w * magnitudeScale
        )
    }
}
