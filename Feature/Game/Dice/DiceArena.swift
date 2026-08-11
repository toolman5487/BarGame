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

    private enum Camera {
        static let elevatedHeight: Float = 3.4
        static let elevatedFocusHeight: Float = 0.35
        static let horizontalHeight: Float = 0.5
        static let horizontalFocusHeight: Float = 1.1
        static let defaultPerspectiveDistance: Float = 5.4
        static let fieldOfView: CGFloat = 42
        static let topDownHeight: Float = 7
        static let transitionDuration: TimeInterval = 0.8
    }

    private enum Physics {
        static let gravity: Float = 10.4
        static let lateralGravityScale: Float = 4.2
        static let simulationTimeStep: TimeInterval = 1.0 / 120.0
        static let floorRestitution: CGFloat = 0.4
        static let floorFriction: CGFloat = 0.52
        static let wallRestitution: CGFloat = 0.4
        static let wallFriction: CGFloat = 0.38
    }

    private enum Appearance {
        static let woodTextureScale: Float = 2
        static let floorReflectivity: CGFloat = 0
        static let lightingEnvironmentIntensity: CGFloat = 0.45
    }

    private enum TransparentCup {
        static let wallThickness: CGFloat = 0.2
        static let wallHeight: CGFloat = 4
        static let wallLength: CGFloat = 8
        static let wallSlopeRadians: Float = .pi / 30
        static let innerEdgeInset: Float = 0.02
    }

    private enum SceneAsset {
        static let directory = "SceneAssets.scnassets"
        static let walnutBaseColor = "WalnutBaseColor"
        static let walnutNormal = "WalnutNormal"
        static let walnutRoughness = "WalnutRoughness"
        static let walnutAmbientOcclusion = "WalnutAmbientOcclusion"
        static let warmLightingEnvironment = "BrownPhotostudio07"
    }

    private enum RenderingCategory {
        static let floor = 1 << 1
    }

    // MARK: - Properties

    let scene = SCNScene()
    let cameraNode = SCNNode()

    private let sceneAppearance: DiceSceneAppearance
    private let cameraViewpoint: DiceCameraViewpoint
    private let cameraDistance: Float
    private let leftWallNode: SCNNode
    private let rightWallNode: SCNNode
    private let frontWallNode: SCNNode
    private let backWallNode: SCNNode
    private let ceilingNode: SCNNode
    private var viewportSize: CGSize = .zero

    // MARK: - Lifecycle

    init(
        sceneAppearance: DiceSceneAppearance,
        cameraViewpoint: DiceCameraViewpoint,
        preferredCameraDistance: Float?
    ) {
        self.sceneAppearance = sceneAppearance
        self.cameraViewpoint = cameraViewpoint
        cameraDistance = preferredCameraDistance ?? Camera.defaultPerspectiveDistance
        leftWallNode = Self.makeBoundaryWall(
            width: TransparentCup.wallThickness,
            height: TransparentCup.wallHeight,
            length: TransparentCup.wallLength,
            restitution: Physics.wallRestitution
        )
        rightWallNode = Self.makeBoundaryWall(
            width: TransparentCup.wallThickness,
            height: TransparentCup.wallHeight,
            length: TransparentCup.wallLength,
            restitution: Physics.wallRestitution
        )
        frontWallNode = Self.makeBoundaryWall(
            width: TransparentCup.wallLength,
            height: TransparentCup.wallHeight,
            length: TransparentCup.wallThickness,
            restitution: Physics.wallRestitution
        )
        backWallNode = Self.makeBoundaryWall(
            width: TransparentCup.wallLength,
            height: TransparentCup.wallHeight,
            length: TransparentCup.wallThickness,
            restitution: Physics.wallRestitution
        )
        ceilingNode = Self.makeBoundaryWall(
            width: TransparentCup.wallLength,
            height: TransparentCup.wallThickness,
            length: TransparentCup.wallLength,
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
        SCNTransaction.animationDuration = Camera.transitionDuration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        cameraNode.position = SCNVector3(0, Camera.topDownHeight, 0)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        SCNTransaction.commit()
        updateViewportBoundaries(for: viewportSize)
    }

    func showPerspectiveView() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = Camera.transitionDuration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        cameraNode.position = perspectiveCameraPosition
        cameraNode.look(at: focusPoint)
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
        let playPoint = focusPoint
        let cameraPosition = cameraNode.position
        let deltaX = playPoint.x - cameraPosition.x
        let deltaY = playPoint.y - cameraPosition.y
        let deltaZ = playPoint.z - cameraPosition.z
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)
        let halfHeight = distance * tan(fovRadians / 2)
        let halfWidth = halfHeight * aspect
        let halfDepth = halfWidth / aspect

        let wallThickness = Float(TransparentCup.wallThickness)
        let wallHeight = Float(TransparentCup.wallHeight)
        let innerEdgeInset = TransparentCup.innerEdgeInset

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
        leftWallNode.eulerAngles = SCNVector3(0, 0, TransparentCup.wallSlopeRadians)
        rightWallNode.eulerAngles = SCNVector3(0, 0, -TransparentCup.wallSlopeRadians)

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
        frontWallNode.eulerAngles = SCNVector3(-TransparentCup.wallSlopeRadians, 0, 0)
        backWallNode.eulerAngles = SCNVector3(TransparentCup.wallSlopeRadians, 0, 0)

        let topEdgeY = playPoint.y + halfHeight - innerEdgeInset
        ceilingNode.position = SCNVector3(
            0,
            topEdgeY + wallThickness / 2,
            0
        )
    }

    // MARK: - Setup

    private func setupScene() {
        scene.background.contents = sceneAppearance.backgroundColor
        scene.physicsWorld.timeStep = Physics.simulationTimeStep

        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = Camera.fieldOfView
        cameraNode.camera?.wantsHDR = true
        cameraNode.camera?.wantsExposureAdaptation = true
        cameraNode.camera?.exposureOffset = -0.15
        cameraNode.camera?.motionBlurIntensity = 0.08
        cameraNode.position = perspectiveCameraPosition
        cameraNode.look(at: focusPoint)
        scene.rootNode.addChildNode(cameraNode)

        configureLightingEnvironment()
        addLighting()

        let floorGeometry = SCNFloor()
        floorGeometry.reflectivity = Appearance.floorReflectivity
        floorGeometry.firstMaterial = floorMaterial

        let floor = SCNNode(geometry: floorGeometry)
        floor.categoryBitMask = RenderingCategory.floor
        floor.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        Self.configureBoundaryPhysics(
            floor.physicsBody,
            restitution: Physics.floorRestitution,
            friction: Physics.floorFriction
        )
        scene.rootNode.addChildNode(floor)

        addTransparentCupBoundaries()
    }

    private func configureLightingEnvironment() {
        guard let environmentURL = Self.sceneAssetURL(
            named: SceneAsset.warmLightingEnvironment,
            fileExtension: "hdr"
        ) else { return }

        scene.lightingEnvironment.contents = environmentURL
        scene.lightingEnvironment.intensity = Appearance.lightingEnvironmentIntensity
    }

    private func addLighting() {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 60
        ambient.light?.color = UIColor(red: 0.72, green: 0.46, blue: 0.26, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 420
        keyLight.light?.color = UIColor(red: 1, green: 0.68, blue: 0.38, alpha: 1)
        keyLight.light?.castsShadow = true
        keyLight.light?.shadowColor = UIColor.black.withAlphaComponent(0.28)
        keyLight.light?.shadowSampleCount = 32
        keyLight.light?.shadowRadius = 12
        keyLight.light?.shadowBias = 0.015
        keyLight.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(keyLight)

        let centerLight = SCNNode()
        centerLight.light = SCNLight()
        centerLight.light?.type = .spot
        centerLight.light?.intensity = 160
        centerLight.light?.color = UIColor(red: 1, green: 0.52, blue: 0.22, alpha: 1)
        centerLight.light?.categoryBitMask = RenderingCategory.floor
        centerLight.light?.spotInnerAngle = 24
        centerLight.light?.spotOuterAngle = 110
        centerLight.light?.attenuationStartDistance = 2
        centerLight.light?.attenuationEndDistance = 8
        centerLight.position = SCNVector3(0, 5.5, 0)
        centerLight.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        scene.rootNode.addChildNode(centerLight)
    }

    private func addTransparentCupBoundaries() {
        let initialHalfDepth: Float = 2.5

        frontWallNode.position = SCNVector3(
            0,
            Float(TransparentCup.wallHeight / 2),
            -initialHalfDepth
        )
        scene.rootNode.addChildNode(frontWallNode)

        backWallNode.position = SCNVector3(
            0,
            Float(TransparentCup.wallHeight / 2),
            initialHalfDepth
        )
        scene.rootNode.addChildNode(backWallNode)

        ceilingNode.position = SCNVector3(0, 3.0, 0)
        scene.rootNode.addChildNode(ceilingNode)

        leftWallNode.position = SCNVector3(
            -2.0,
            Float(TransparentCup.wallHeight / 2),
            0
        )
        scene.rootNode.addChildNode(leftWallNode)

        rightWallNode.position = SCNVector3(
            2.0,
            Float(TransparentCup.wallHeight / 2),
            0
        )
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
        let wallGeometry = SCNBox(
            width: width,
            height: height,
            length: length,
            chamferRadius: 0
        )
        let transparentMaterial = SCNMaterial()
        transparentMaterial.diffuse.contents = UIColor.clear
        transparentMaterial.transparency = 0
        transparentMaterial.lightingModel = .constant
        transparentMaterial.writesToDepthBuffer = false
        transparentMaterial.readsFromDepthBuffer = false
        wallGeometry.firstMaterial = transparentMaterial

        let wall = SCNNode(geometry: wallGeometry)
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
        configureWoodTexture(
            material.diffuse,
            named: SceneAsset.walnutBaseColor,
            fallback: UIColor(red: 0.2, green: 0.085, blue: 0.035, alpha: 1)
        )
        configureWoodTexture(
            material.normal,
            named: SceneAsset.walnutNormal,
            fallback: UIColor(red: 0.5, green: 0.5, blue: 1, alpha: 1),
            intensity: 0.35
        )
        configureWoodTexture(
            material.roughness,
            named: SceneAsset.walnutRoughness,
            fallback: 0.72
        )
        configureWoodTexture(
            material.ambientOcclusion,
            named: SceneAsset.walnutAmbientOcclusion,
            fallback: UIColor.white,
            intensity: 0.65
        )
        material.metalness.contents = 0
        return material
    }

    private static func configureWoodTexture(
        _ property: SCNMaterialProperty,
        named resourceName: String,
        fallback: Any,
        intensity: CGFloat = 1
    ) {
        if let textureURL = sceneAssetURL(named: resourceName, fileExtension: "png") {
            property.contents = textureURL
        } else {
            property.contents = fallback
        }

        property.wrapS = .repeat
        property.wrapT = .repeat
        property.minificationFilter = .linear
        property.magnificationFilter = .linear
        property.mipFilter = .linear
        property.maxAnisotropy = 8
        property.intensity = intensity
        property.contentsTransform = SCNMatrix4MakeScale(
            Appearance.woodTextureScale,
            Appearance.woodTextureScale,
            1
        )
    }

    private static func sceneAssetURL(
        named resourceName: String,
        fileExtension: String
    ) -> URL? {
        Bundle.main.url(
            forResource: resourceName,
            withExtension: fileExtension,
            subdirectory: SceneAsset.directory
        )
        ?? Bundle.main.url(
            forResource: resourceName,
            withExtension: fileExtension
        )
    }

    private var floorMaterial: SCNMaterial {
        switch sceneAppearance {
        case .walnut:
            return Self.makeWoodMaterial()

        case .systemBackground:
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.clear
            material.transparency = 0
            material.writesToDepthBuffer = false
            material.readsFromDepthBuffer = false
            return material
        }
    }

    private var perspectiveCameraPosition: SCNVector3 {
        SCNVector3(
            0,
            cameraHeight,
            cameraDistance
        )
    }

    private var focusPoint: SCNVector3 {
        SCNVector3(0, cameraFocusHeight, 0)
    }

    private var cameraHeight: Float {
        switch cameraViewpoint {
        case .elevated:
            return Camera.elevatedHeight

        case .horizontal:
            return Camera.horizontalHeight
        }
    }

    private var cameraFocusHeight: Float {
        switch cameraViewpoint {
        case .elevated:
            return Camera.elevatedFocusHeight

        case .horizontal:
            return Camera.horizontalFocusHeight
        }
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
