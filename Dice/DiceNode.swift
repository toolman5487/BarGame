//
//  DiceNode.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/2.
//

import UIKit
import SceneKit

final class DiceNode: SCNNode {

    // MARK: - Types

    private enum Metrics {
        static let size: CGFloat = 0.72
        static let chamferRadius = size * 0.08
    }

    private enum Physics {
        static let mass: CGFloat = 0.8
        static let friction: CGFloat = 0.62
        static let rollingFriction: CGFloat = 0.32
        static let restitution: CGFloat = 0.42
        static let angularDamping: CGFloat = 0.42
        static let damping: CGFloat = 0.16
    }

    // MARK: - Lifecycle

    override init() {
        super.init()
        setupDice()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func applyShake(intensity: Double) {
        guard let body = physicsBody else { return }

        let clamped = min(max(intensity, 0.3), 2.5)
        let forceScale = Float(clamped) * 4.0
        let force = SCNVector3(
            Float.random(in: -1...1) * forceScale,
            Float.random(in: 0.4...1.2) * forceScale,
            Float.random(in: -1...1) * forceScale
        )
        let torque = SCNVector4(
            Float.random(in: -1...1),
            Float.random(in: -1...1),
            Float.random(in: -1...1),
            Float(clamped) * 2.5
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
        let box = SCNBox(
            width: Metrics.size,
            height: Metrics.size,
            length: Metrics.size,
            chamferRadius: Metrics.chamferRadius
        )
        box.materials = [
            makePipMaterial(pips: 1),
            makePipMaterial(pips: 2),
            makePipMaterial(pips: 6),
            makePipMaterial(pips: 5),
            makePipMaterial(pips: 3),
            makePipMaterial(pips: 4),
        ]
        geometry = box

        let shape = SCNPhysicsShape(geometry: box, options: [
            SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.convexHull,
        ])
        let body = SCNPhysicsBody(type: .dynamic, shape: shape)
        body.mass = Physics.mass
        body.friction = Physics.friction
        body.rollingFriction = Physics.rollingFriction
        body.restitution = Physics.restitution
        body.angularDamping = Physics.angularDamping
        body.damping = Physics.damping
        body.allowsResting = true
        body.continuousCollisionDetectionThreshold = Metrics.size / 2
        body.categoryBitMask = DicePhysicsCategory.dice
        body.contactTestBitMask = DicePhysicsCategory.dice | DicePhysicsCategory.boundary
        body.collisionBitMask = DicePhysicsCategory.dice | DicePhysicsCategory.boundary
        physicsBody = body
    }

    // MARK: - Materials

    private func makePipMaterial(pips: Int) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = makeDiceFaceImage(pips: pips)
        material.roughness.contents = 0.32
        material.metalness.contents = 0.02
        material.clearCoat.contents = 0.18
        material.clearCoatRoughness.contents = 0.28
        material.lightingModel = .physicallyBased
        return material
    }

    private func makeDiceFaceImage(pips: Int) -> UIImage {
        let size = CGSize(width: 256, height: 256)
        return UIGraphicsImageRenderer(size: size).image { context in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.95, green: 0.94, blue: 0.9, alpha: 1).setFill()
            context.fill(rect)

            let inset: CGFloat = 16
            let faceRect = rect.insetBy(dx: inset, dy: inset)
            let path = UIBezierPath(roundedRect: faceRect, cornerRadius: 24)
            UIColor(white: 0.88, alpha: 1).setStroke()
            path.lineWidth = 4
            path.stroke()

            let pipColor = UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)
            let positions = pipPositions(for: pips, in: faceRect)
            let pipRadius: CGFloat = 18
            for point in positions {
                let pipRect = CGRect(
                    x: point.x - pipRadius,
                    y: point.y - pipRadius,
                    width: pipRadius * 2,
                    height: pipRadius * 2
                )
                pipColor.setFill()
                UIBezierPath(ovalIn: pipRect).fill()
            }
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
