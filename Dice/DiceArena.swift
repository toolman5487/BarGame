//
//  DiceArena.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/2.
//

import UIKit
import SceneKit

final class DiceArena {

    // MARK: - Types

    private enum CameraTransition {
        static let perspectiveHeight: Float = 1.2
        static let perspectiveDistance: Float = 5.5
        static let topDownHeight: Float = 7
        static let duration: TimeInterval = 0.8
    }

    private enum Physics {
        static let gravity: Float = 9.8
        static let lateralGravityScale: Float = 3
        static let floorRestitution: CGFloat = 0.28
        static let floorFriction: CGFloat = 0.68
        static let wallRestitution: CGFloat = 0.48
        static let wallFriction: CGFloat = 0.35
    }

    private enum Appearance {
        static let woodTextureSize = CGSize(width: 512, height: 512)
        static let woodTextureScale: Float = 2
        static let floorReflectivity: CGFloat = 0
    }

    private enum RenderingCategory {
        static let floor = 1 << 1
    }

    // MARK: - Properties

    let scene = SCNScene()
    let cameraNode = SCNNode()

    private let leftWallNode: SCNNode
    private let rightWallNode: SCNNode
    private let frontWallNode: SCNNode
    private let backWallNode: SCNNode
    private let ceilingNode: SCNNode
    private var viewportSize: CGSize = .zero

    // MARK: - Lifecycle

    init() {
        leftWallNode = Self.makeBoundaryWall(
            width: 0.25,
            height: 4,
            length: 8,
            restitution: Physics.wallRestitution
        )
        rightWallNode = Self.makeBoundaryWall(
            width: 0.25,
            height: 4,
            length: 8,
            restitution: Physics.wallRestitution
        )
        frontWallNode = Self.makeBoundaryWall(
            width: 8,
            height: 4,
            length: 0.25,
            restitution: Physics.wallRestitution
        )
        backWallNode = Self.makeBoundaryWall(
            width: 8,
            height: 4,
            length: 0.25,
            restitution: Physics.wallRestitution
        )
        ceilingNode = Self.makeBoundaryWall(
            width: 8,
            height: 0.25,
            length: 8,
            restitution: Physics.wallRestitution
        )
        setupScene()
    }

    // MARK: - Public

    func attach(dice: SCNNode, at position: SCNVector3) {
        dice.position = position
        scene.rootNode.addChildNode(dice)
    }

    func showTopDownView() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = CameraTransition.duration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        cameraNode.position = SCNVector3(0, CameraTransition.topDownHeight, 0)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        SCNTransaction.commit()
        updateViewportBoundaries(for: viewportSize)
    }

    func showPerspectiveView() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = CameraTransition.duration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        cameraNode.position = SCNVector3(
            0,
            CameraTransition.perspectiveHeight,
            CameraTransition.perspectiveDistance
        )
        cameraNode.look(at: SCNVector3(0, 0, 0))
        SCNTransaction.commit()
        updateViewportBoundaries(for: viewportSize)
    }

    func updateGravity(deviceTiltX: Double, deviceTiltY: Double) {
        scene.physicsWorld.gravity = SCNVector3(
            Float(deviceTiltX) * Physics.lateralGravityScale,
            -Physics.gravity,
            -Float(deviceTiltY) * Physics.lateralGravityScale
        )
    }

    func updateViewportBoundaries(for viewBounds: CGSize) {
        guard viewBounds.width > 1,
              viewBounds.height > 1,
              let camera = cameraNode.camera else { return }

        viewportSize = viewBounds
        let aspect = Float(viewBounds.width / viewBounds.height)
        let fovRadians = Float(camera.fieldOfView) * .pi / 180
        let playPoint = SCNVector3(0, 0.5, 0)
        let cameraPosition = cameraNode.position
        let deltaX = playPoint.x - cameraPosition.x
        let deltaY = playPoint.y - cameraPosition.y
        let deltaZ = playPoint.z - cameraPosition.z
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)
        let halfHeight = distance * tan(fovRadians / 2)
        let halfWidth = halfHeight * aspect
        let halfDepth = halfWidth / aspect

        let wallThickness: Float = 0.25
        let wallHeight: Float = 4
        let innerEdgeInset: Float = 0.02

        leftWallNode.position = SCNVector3(
            -halfWidth - wallThickness / 2 + innerEdgeInset,
            wallHeight / 2,
            0
        )
        rightWallNode.position = SCNVector3(
            halfWidth + wallThickness / 2 - innerEdgeInset,
            wallHeight / 2,
            0
        )

        frontWallNode.position = SCNVector3(
            0,
            wallHeight / 2,
            -halfDepth - wallThickness / 2 + innerEdgeInset
        )
        backWallNode.position = SCNVector3(
            0,
            wallHeight / 2,
            halfDepth + wallThickness / 2 - innerEdgeInset
        )

        let topEdgeY = playPoint.y + halfHeight - innerEdgeInset
        ceilingNode.position = SCNVector3(
            0,
            topEdgeY + wallThickness / 2,
            0
        )
    }

    // MARK: - Setup

    private func setupScene() {
        scene.background.contents = UIColor.black

        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 45
        cameraNode.camera?.wantsHDR = true
        cameraNode.camera?.wantsExposureAdaptation = true
        cameraNode.camera?.exposureOffset = -0.15
        cameraNode.camera?.motionBlurIntensity = 0.08
        cameraNode.position = SCNVector3(
            0,
            CameraTransition.perspectiveHeight,
            CameraTransition.perspectiveDistance
        )
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        addLighting()

        let floorGeometry = SCNFloor()
        floorGeometry.reflectivity = Appearance.floorReflectivity
        floorGeometry.firstMaterial = Self.makeWoodMaterial()

        let floor = SCNNode(geometry: floorGeometry)
        floor.categoryBitMask = RenderingCategory.floor
        floor.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        Self.configureBoundaryPhysics(
            floor.physicsBody,
            restitution: Physics.floorRestitution,
            friction: Physics.floorFriction
        )
        scene.rootNode.addChildNode(floor)

        addBoundaryWalls()
    }

    private func addLighting() {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 180
        ambient.light?.color = UIColor(red: 0.86, green: 0.94, blue: 0.9, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 720
        keyLight.light?.castsShadow = true
        keyLight.light?.shadowSampleCount = 16
        keyLight.light?.shadowRadius = 6
        keyLight.light?.shadowBias = 0.015
        keyLight.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(keyLight)

        let centerLight = SCNNode()
        centerLight.light = SCNLight()
        centerLight.light?.type = .spot
        centerLight.light?.intensity = 360
        centerLight.light?.color = UIColor(red: 1, green: 0.95, blue: 0.84, alpha: 1)
        centerLight.light?.categoryBitMask = RenderingCategory.floor
        centerLight.light?.spotInnerAngle = 38
        centerLight.light?.spotOuterAngle = 96
        centerLight.light?.attenuationStartDistance = 2
        centerLight.light?.attenuationEndDistance = 8
        centerLight.position = SCNVector3(0, 5.5, 0)
        centerLight.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        scene.rootNode.addChildNode(centerLight)
    }

    private func addBoundaryWalls() {
        let wallHeight: CGFloat = 4
        let initialHalfDepth: Float = 2.5

        frontWallNode.position = SCNVector3(0, Float(wallHeight / 2), -initialHalfDepth)
        scene.rootNode.addChildNode(frontWallNode)

        backWallNode.position = SCNVector3(0, Float(wallHeight / 2), initialHalfDepth)
        scene.rootNode.addChildNode(backWallNode)

        ceilingNode.position = SCNVector3(0, 3.0, 0)
        scene.rootNode.addChildNode(ceilingNode)

        leftWallNode.position = SCNVector3(-2.0, Float(wallHeight / 2), 0)
        scene.rootNode.addChildNode(leftWallNode)

        rightWallNode.position = SCNVector3(2.0, Float(wallHeight / 2), 0)
        scene.rootNode.addChildNode(rightWallNode)
    }

    // MARK: - Boundaries

    private static func configureBoundaryPhysics(
        _ body: SCNPhysicsBody?,
        restitution: CGFloat,
        friction: CGFloat
    ) {
        body?.categoryBitMask = DicePhysicsCategory.boundary
        body?.contactTestBitMask = DicePhysicsCategory.dice
        body?.collisionBitMask = DicePhysicsCategory.dice
        body?.restitution = restitution
        body?.friction = friction
    }

    private static func makeBoundaryWall(
        width: CGFloat,
        height: CGFloat,
        length: CGFloat,
        restitution: CGFloat
    ) -> SCNNode {
        let wall = SCNNode(geometry: SCNBox(
            width: width,
            height: height,
            length: length,
            chamferRadius: 0
        ))
        wall.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        wall.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        configureBoundaryPhysics(
            wall.physicsBody,
            restitution: restitution,
            friction: Physics.wallFriction
        )
        return wall
    }

    // MARK: - Materials

    private static func makeWoodMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = makeWoodDiffuseTexture()
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        material.diffuse.mipFilter = .linear
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(
            Appearance.woodTextureScale,
            Appearance.woodTextureScale,
            1
        )
        material.normal.contents = makeWoodNormalTexture()
        material.normal.wrapS = .repeat
        material.normal.wrapT = .repeat
        material.normal.mipFilter = .linear
        material.normal.intensity = 0.24
        material.normal.contentsTransform = material.diffuse.contentsTransform
        material.roughness.contents = 0.72
        material.metalness.contents = 0
        return material
    }

    private static func makeWoodDiffuseTexture() -> UIImage {
        UIGraphicsImageRenderer(size: Appearance.woodTextureSize).image { context in
            let bounds = CGRect(origin: .zero, size: Appearance.woodTextureSize)
            UIColor(red: 0.2, green: 0.085, blue: 0.035, alpha: 1).setFill()
            context.fill(bounds)

            let graphicsContext = context.cgContext
            let plankWidth = bounds.width / 4

            for plankIndex in 0..<4 {
                let plankRect = CGRect(
                    x: CGFloat(plankIndex) * plankWidth,
                    y: 0,
                    width: plankWidth,
                    height: bounds.height
                )
                let brightnessOffset = CGFloat(plankIndex % 3) * 0.012
                graphicsContext.setFillColor(
                    UIColor(
                        red: 0.19 + brightnessOffset,
                        green: 0.075 + brightnessOffset,
                        blue: 0.03,
                        alpha: 0.5
                    ).cgColor
                )
                graphicsContext.fill(plankRect)

                guard plankIndex > 0 else { continue }
                let seamX = plankRect.minX
                graphicsContext.setStrokeColor(
                    UIColor(red: 0.055, green: 0.02, blue: 0.008, alpha: 0.72).cgColor
                )
                graphicsContext.setLineWidth(2)
                graphicsContext.move(to: CGPoint(x: seamX, y: 0))
                graphicsContext.addLine(to: CGPoint(x: seamX, y: bounds.height))
                graphicsContext.strokePath()
            }

            for grainIndex in 0..<84 {
                let isHighlight = grainIndex % 4 == 0
                let color = isHighlight
                    ? UIColor(red: 0.48, green: 0.24, blue: 0.1, alpha: 0.22)
                    : UIColor(red: 0.07, green: 0.022, blue: 0.008, alpha: 0.3)
                graphicsContext.setStrokeColor(color.cgColor)
                graphicsContext.setLineWidth(isHighlight ? 0.7 : 0.45)
                graphicsContext.addPath(woodGrainPath(index: grainIndex, in: bounds).cgPath)
                graphicsContext.strokePath()
            }

            drawWoodKnot(
                center: CGPoint(x: bounds.width * 0.28, y: bounds.height * 0.32),
                in: graphicsContext
            )
            drawWoodKnot(
                center: CGPoint(x: bounds.width * 0.76, y: bounds.height * 0.7),
                in: graphicsContext
            )
        }
    }

    private static func makeWoodNormalTexture() -> UIImage {
        UIGraphicsImageRenderer(size: Appearance.woodTextureSize).image { context in
            let bounds = CGRect(origin: .zero, size: Appearance.woodTextureSize)
            UIColor(red: 0.5, green: 0.5, blue: 1, alpha: 1).setFill()
            context.fill(bounds)

            let graphicsContext = context.cgContext
            for grainIndex in 0..<84 {
                let path = woodGrainPath(index: grainIndex, in: bounds)
                graphicsContext.saveGState()
                graphicsContext.translateBy(x: -0.65, y: 0)
                graphicsContext.setStrokeColor(
                    UIColor(red: 0.56, green: 0.5, blue: 0.98, alpha: 0.82).cgColor
                )
                graphicsContext.setLineWidth(0.8)
                graphicsContext.addPath(path.cgPath)
                graphicsContext.strokePath()
                graphicsContext.restoreGState()

                graphicsContext.saveGState()
                graphicsContext.translateBy(x: 0.65, y: 0)
                graphicsContext.setStrokeColor(
                    UIColor(red: 0.44, green: 0.5, blue: 0.98, alpha: 0.82).cgColor
                )
                graphicsContext.setLineWidth(0.8)
                graphicsContext.addPath(path.cgPath)
                graphicsContext.strokePath()
                graphicsContext.restoreGState()
            }

            let plankWidth = bounds.width / 4
            for plankIndex in 1..<4 {
                let seamX = CGFloat(plankIndex) * plankWidth
                graphicsContext.setStrokeColor(
                    UIColor(red: 0.58, green: 0.5, blue: 0.97, alpha: 1).cgColor
                )
                graphicsContext.setLineWidth(1)
                graphicsContext.move(to: CGPoint(x: seamX - 1, y: 0))
                graphicsContext.addLine(to: CGPoint(x: seamX - 1, y: bounds.height))
                graphicsContext.strokePath()

                graphicsContext.setStrokeColor(
                    UIColor(red: 0.42, green: 0.5, blue: 0.97, alpha: 1).cgColor
                )
                graphicsContext.move(to: CGPoint(x: seamX + 1, y: 0))
                graphicsContext.addLine(to: CGPoint(x: seamX + 1, y: bounds.height))
                graphicsContext.strokePath()
            }
        }
    }

    private static func woodGrainPath(index: Int, in bounds: CGRect) -> UIBezierPath {
        let lineSpacing = bounds.width / 84
        let baseX = CGFloat(index) * lineSpacing
        let phase = CGFloat(index * 17 % 29) / 29 * .pi * 2
        let primaryFrequency = 0.018 + CGFloat(index % 5) * 0.0015
        let secondaryFrequency = 0.048 + CGFloat(index % 3) * 0.002
        let amplitude = 1.2 + CGFloat(index % 4) * 0.55
        let path = UIBezierPath()

        for positionY in stride(from: CGFloat.zero, through: bounds.height, by: 8) {
            let primaryWave = CGFloat(sin(Double(positionY * primaryFrequency + phase)))
            let secondaryWave = CGFloat(sin(Double(positionY * secondaryFrequency + phase * 0.7)))
            let point = CGPoint(
                x: baseX + primaryWave * amplitude + secondaryWave * 0.65,
                y: positionY
            )

            if positionY == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        return path
    }

    private static func drawWoodKnot(center: CGPoint, in context: CGContext) {
        for ringIndex in 0..<4 {
            let horizontalRadius = CGFloat(10 + ringIndex * 7)
            let verticalRadius = CGFloat(5 + ringIndex * 4)
            let ring = CGRect(
                x: center.x - horizontalRadius,
                y: center.y - verticalRadius,
                width: horizontalRadius * 2,
                height: verticalRadius * 2
            )
            context.setStrokeColor(
                UIColor(red: 0.055, green: 0.018, blue: 0.006, alpha: 0.42).cgColor
            )
            context.setLineWidth(1)
            context.strokeEllipse(in: ring)
        }
    }
}
