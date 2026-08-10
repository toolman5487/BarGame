//
//  DiceNode.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/2.
//

import UIKit
import SceneKit

nonisolated final class DiceNode: SCNNode {

    // MARK: - Types

    private enum Metrics {
        static let minimumEdgeLength: CGFloat = 0.1
        static let chamferRatio: CGFloat = 0.08
        static let collisionChamferRatio: CGFloat = 0.02
        static let collisionInsetRatio: CGFloat = 0.003
        static let collisionMargin: CGFloat = 0
        static let continuousCollisionThresholdRatio: CGFloat = 0.2
    }

    private enum Physics {
        static let mass: CGFloat = 0.7
        static let friction: CGFloat = 0.44
        static let rollingFriction: CGFloat = 0.06
        static let restitution: CGFloat = 0.42
        static let angularDamping: CGFloat = 0.08
        static let damping: CGFloat = 0.035
    }

    private enum Appearance {
        static let textureDimension = 256
        static let faceInset: CGFloat = 16
        static let pipRadius: CGFloat = 18
        static let normalStrength: CGFloat = 0.42
        static let materialRoughness: CGFloat = 0.34
        static let clearCoatIntensity: CGFloat = 0.22
        static let clearCoatRoughness: CGFloat = 0.24
    }

    private var edgeLength: CGFloat

    // MARK: - Lifecycle

    init(edgeLength: CGFloat) {
        self.edgeLength = max(edgeLength, Metrics.minimumEdgeLength)
        super.init()
        setupDice()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func resize(to edgeLength: CGFloat) {
        let updatedEdgeLength = max(edgeLength, Metrics.minimumEdgeLength)
        guard abs(self.edgeLength - updatedEdgeLength) > .ulpOfOne else { return }

        let previousBody = physicsBody
        self.edgeLength = updatedEdgeLength
        updateVisibleGeometry()

        let updatedBody = makePhysicsBody()
        updatedBody.isAffectedByGravity = previousBody?.isAffectedByGravity ?? true
        updatedBody.velocity = previousBody?.velocity ?? SCNVector3Zero
        updatedBody.angularVelocity = previousBody?.angularVelocity ?? SCNVector4Zero
        physicsBody = updatedBody
    }

    func applyShake(intensity: Double) {
        guard let body = physicsBody else { return }

        let clamped = min(max(intensity, 0.3), 2.8)
        let forceScale = Float(clamped) * 6.2
        let force = SCNVector3(
            Float.random(in: -1...1) * forceScale,
            Float.random(in: 0.5...1.4) * forceScale,
            Float.random(in: -1...1) * forceScale
        )
        let torque = SCNVector4(
            Float.random(in: -1...1),
            Float.random(in: -1...1),
            Float.random(in: -1...1),
            Float(clamped) * 3.8
        )

        if body.isResting {
            body.velocity = SCNVector3(0, 0.1, 0)
        }
        body.applyForce(force, asImpulse: true)
        body.applyTorque(torque, asImpulse: true)
    }

    func applyMotionImpulse(force: SCNVector3, torque: SCNVector4) {
        guard let body = physicsBody else { return }

        if body.isResting {
            body.velocity = SCNVector3(0, 0.1, 0)
        }
        body.applyForce(force, asImpulse: true)
        body.applyTorque(torque, asImpulse: true)
    }

    func setLocked(_ isLocked: Bool) {
        guard let body = physicsBody else { return }

        body.isAffectedByGravity = !isLocked
        guard isLocked else { return }

        body.clearAllForces()
        body.velocity = SCNVector3Zero
        body.angularVelocity = SCNVector4Zero
    }

    nonisolated static func impactSpeed(for contact: SCNPhysicsContact) -> Float {
        let diceBody: SCNPhysicsBody?
        if contact.nodeA.physicsBody?.categoryBitMask == DicePhysicsCategory.dice {
            diceBody = contact.nodeA.physicsBody
        } else {
            diceBody = contact.nodeB.physicsBody
        }

        guard let velocity = diceBody?.velocity else { return 0 }
        return sqrt(
            velocity.x * velocity.x +
            velocity.y * velocity.y +
            velocity.z * velocity.z
        )
    }

    // MARK: - Setup

    private func setupDice() {
        let visibleBox = makeVisibleGeometry()
        geometry = visibleBox
        physicsBody = makePhysicsBody()
    }

    private func makeVisibleGeometry() -> SCNBox {
        let visibleBox = SCNBox(
            width: edgeLength,
            height: edgeLength,
            length: edgeLength,
            chamferRadius: chamferRadius
        )
        visibleBox.materials = [
            makePipMaterial(pips: 1),
            makePipMaterial(pips: 2),
            makePipMaterial(pips: 6),
            makePipMaterial(pips: 5),
            makePipMaterial(pips: 3),
            makePipMaterial(pips: 4),
        ]
        return visibleBox
    }

    private func updateVisibleGeometry() {
        guard let visibleBox = geometry as? SCNBox else {
            geometry = makeVisibleGeometry()
            return
        }

        visibleBox.width = edgeLength
        visibleBox.height = edgeLength
        visibleBox.length = edgeLength
        visibleBox.chamferRadius = chamferRadius
    }

    private func makePhysicsBody() -> SCNPhysicsBody {
        let collisionBox = SCNBox(
            width: collisionEdgeLength,
            height: collisionEdgeLength,
            length: collisionEdgeLength,
            chamferRadius: collisionChamferRadius
        )
        let shape = SCNPhysicsShape(geometry: collisionBox, options: [
            SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.convexHull,
            SCNPhysicsShape.Option.collisionMargin: Metrics.collisionMargin,
        ])
        let body = SCNPhysicsBody(type: .dynamic, shape: shape)
        body.mass = Physics.mass
        body.friction = Physics.friction
        body.rollingFriction = Physics.rollingFriction
        body.restitution = Physics.restitution
        body.angularDamping = Physics.angularDamping
        body.damping = Physics.damping
        body.allowsResting = true
        body.continuousCollisionDetectionThreshold = continuousCollisionThreshold
        body.categoryBitMask = DicePhysicsCategory.dice
        body.contactTestBitMask = DicePhysicsCategory.dice | DicePhysicsCategory.boundary
        body.collisionBitMask = DicePhysicsCategory.dice | DicePhysicsCategory.boundary
        return body
    }

    private var chamferRadius: CGFloat {
        edgeLength * Metrics.chamferRatio
    }

    private var collisionInset: CGFloat {
        edgeLength * Metrics.collisionInsetRatio
    }

    private var collisionEdgeLength: CGFloat {
        edgeLength - collisionInset * 2
    }

    private var collisionChamferRadius: CGFloat {
        max(edgeLength * Metrics.collisionChamferRatio - collisionInset, 0)
    }

    private var continuousCollisionThreshold: CGFloat {
        edgeLength * Metrics.continuousCollisionThresholdRatio
    }

    // MARK: - Materials

    private func makePipMaterial(pips: Int) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = makeDiceFaceImage(pips: pips)
        material.normal.contents = makeDiceFaceNormalImage(pips: pips)
        material.normal.intensity = 0.45
        material.roughness.contents = Appearance.materialRoughness
        material.metalness.contents = 0.0
        material.clearCoat.contents = Appearance.clearCoatIntensity
        material.clearCoatRoughness.contents = Appearance.clearCoatRoughness
        material.lightingModel = .physicallyBased
        material.locksAmbientWithDiffuse = true
        material.diffuse.mipFilter = .linear
        material.normal.mipFilter = .linear
        return material
    }

    private func makeDiceFaceImage(pips: Int) -> UIImage {
        let dimension = CGFloat(Appearance.textureDimension)
        let size = CGSize(width: dimension, height: dimension)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let rect = CGRect(origin: .zero, size: size)
            let graphicsContext = context.cgContext
            let ivoryColors = [
                UIColor(red: 0.96, green: 0.95, blue: 0.91, alpha: 1).cgColor,
                UIColor(red: 0.91, green: 0.9, blue: 0.86, alpha: 1).cgColor,
            ] as CFArray

            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: ivoryColors,
                locations: [0, 1]
            ) {
                graphicsContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: rect.minX, y: rect.minY),
                    end: CGPoint(x: rect.maxX, y: rect.maxY),
                    options: []
                )
            }

            drawSurfaceGrain(in: rect, seed: pips, context: context)

            let faceRect = rect.insetBy(
                dx: Appearance.faceInset,
                dy: Appearance.faceInset
            )
            let positions = pipPositions(for: pips, in: faceRect)
            for point in positions {
                drawPip(at: point, context: graphicsContext)
            }
        }
    }

    private func drawSurfaceGrain(
        in rect: CGRect,
        seed: Int,
        context: UIGraphicsImageRendererContext
    ) {
        for index in 0..<48 {
            let x = CGFloat((index * 73 + seed * 19) % Appearance.textureDimension)
            let y = CGFloat((index * 47 + seed * 31) % Appearance.textureDimension)
            let grainRect = CGRect(x: x, y: y, width: 1, height: 1).intersection(rect)
            let brightness = index.isMultiple(of: 2) ? 0.25 : 1
            UIColor(white: brightness, alpha: 0.015).setFill()
            context.fill(grainRect)
        }
    }

    private func drawPip(at point: CGPoint, context: CGContext) {
        let radius = Appearance.pipRadius
        let pipRect = CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        let shadowRect = pipRect.insetBy(dx: -2, dy: -2).offsetBy(dx: 0, dy: 2)

        context.setFillColor(UIColor.black.withAlphaComponent(0.26).cgColor)
        context.fillEllipse(in: shadowRect)

        context.saveGState()
        context.addEllipse(in: pipRect)
        context.clip()

        let pipColors = [
            UIColor(red: 0.18, green: 0.18, blue: 0.2, alpha: 1).cgColor,
            UIColor(red: 0.025, green: 0.025, blue: 0.035, alpha: 1).cgColor,
        ] as CFArray
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: pipColors,
            locations: [0, 1]
        ) {
            context.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: point.x - 5, y: point.y - 6),
                startRadius: 1,
                endCenter: point,
                endRadius: radius,
                options: [.drawsAfterEndLocation]
            )
        }
        context.restoreGState()

        context.setStrokeColor(UIColor.white.withAlphaComponent(0.16).cgColor)
        context.setLineWidth(1)
        context.strokeEllipse(in: pipRect.insetBy(dx: 1, dy: 1))
    }

    private func makeDiceFaceNormalImage(pips: Int) -> UIImage {
        let dimension = Appearance.textureDimension
        let size = CGSize(width: dimension, height: dimension)
        let faceRect = CGRect(origin: .zero, size: size).insetBy(
            dx: Appearance.faceInset,
            dy: Appearance.faceInset
        )
        let pipCenters = pipPositions(for: pips, in: faceRect)
        var pixels = [UInt8](repeating: 0, count: dimension * dimension * 4)

        for row in 0..<dimension {
            for column in 0..<dimension {
                let point = CGPoint(x: CGFloat(column) + 0.5, y: CGFloat(row) + 0.5)
                let normal = pipNormal(at: point, pipCenters: pipCenters)
                let pixelIndex = (row * dimension + column) * 4
                pixels[pixelIndex] = normalMapComponent(normal.x)
                pixels[pixelIndex + 1] = normalMapComponent(normal.y)
                pixels[pixelIndex + 2] = normalMapComponent(normal.z)
                pixels[pixelIndex + 3] = 255
            }
        }

        let data = Data(pixels) as CFData
        guard let provider = CGDataProvider(data: data),
              let image = CGImage(
                width: dimension,
                height: dimension,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: dimension * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else {
            return makeNeutralNormalImage()
        }

        return UIImage(cgImage: image)
    }

    private func pipNormal(at point: CGPoint, pipCenters: [CGPoint]) -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        for center in pipCenters {
            let normalizedX = (point.x - center.x) / Appearance.pipRadius
            let normalizedY = (point.y - center.y) / Appearance.pipRadius
            let distance = sqrt(normalizedX * normalizedX + normalizedY * normalizedY)
            guard distance < 1, distance > 0 else { continue }

            let slope = sin(distance * .pi) * Appearance.normalStrength
            let x = -normalizedX / distance * slope
            let y = normalizedY / distance * slope
            let z = sqrt(max(0, 1 - x * x - y * y))
            return (x, y, z)
        }

        return (0, 0, 1)
    }

    private func normalMapComponent(_ value: CGFloat) -> UInt8 {
        let normalizedValue = min(max(value * 0.5 + 0.5, 0), 1)
        return UInt8(normalizedValue * 255)
    }

    private func makeNeutralNormalImage() -> UIImage {
        let dimension = CGFloat(Appearance.textureDimension)
        let size = CGSize(width: dimension, height: dimension)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(red: 0.5, green: 0.5, blue: 1, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func pipPositions(for pips: Int, in rect: CGRect) -> [CGPoint] {
        let left = rect.minX + rect.width * 0.25
        let centerX = rect.midX
        let right = rect.minX + rect.width * 0.75
        let top = rect.minY + rect.height * 0.25
        let centerY = rect.midY
        let bottom = rect.minY + rect.height * 0.75

        switch pips {
        case 1:
            return [CGPoint(x: centerX, y: centerY)]
        case 2:
            return [
                CGPoint(x: left, y: top),
                CGPoint(x: right, y: bottom),
            ]
        case 3:
            return [
                CGPoint(x: left, y: top),
                CGPoint(x: centerX, y: centerY),
                CGPoint(x: right, y: bottom),
            ]
        case 4:
            return [
                CGPoint(x: left, y: top),
                CGPoint(x: right, y: top),
                CGPoint(x: left, y: bottom),
                CGPoint(x: right, y: bottom),
            ]
        case 5:
            return [
                CGPoint(x: left, y: top),
                CGPoint(x: right, y: top),
                CGPoint(x: centerX, y: centerY),
                CGPoint(x: left, y: bottom),
                CGPoint(x: right, y: bottom),
            ]
        case 6:
            return [
                CGPoint(x: left, y: top),
                CGPoint(x: right, y: top),
                CGPoint(x: left, y: centerY),
                CGPoint(x: right, y: centerY),
                CGPoint(x: left, y: bottom),
                CGPoint(x: right, y: bottom),
            ]
        default:
            return [CGPoint(x: centerX, y: centerY)]
        }
    }
}
