//
//  DiceArena.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/2.
//

import UIKit
import SceneKit

final class DiceArena {

    // MARK: - Properties

    let scene = SCNScene()
    let cameraNode = SCNNode()

    private let leftWallNode: SCNNode
    private let rightWallNode: SCNNode
    private let ceilingNode: SCNNode

    // MARK: - Lifecycle

    init() {
        leftWallNode = Self.makeBoundaryWall(
            width: 0.25,
            height: 4,
            length: 5.0,
            restitution: 0.95
        )
        rightWallNode = Self.makeBoundaryWall(
            width: 0.25,
            height: 4,
            length: 5.0,
            restitution: 0.95
        )
        ceilingNode = Self.makeBoundaryWall(
            width: 8,
            height: 0.25,
            length: 5.0,
            restitution: 0.95
        )
        setupScene()
    }

    // MARK: - Public

    func attach(dice: SCNNode) {
        dice.position = SCNVector3(0, 1.5, 0)
        scene.rootNode.addChildNode(dice)
    }

    func updateSideWalls(for viewBounds: CGSize) {
        guard viewBounds.width > 1,
              viewBounds.height > 1,
              let camera = cameraNode.camera else { return }

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
        cameraNode.position = SCNVector3(0, 1.2, 5.5)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 400
        ambient.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambient)

        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 800
        keyLight.light?.castsShadow = true
        keyLight.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(keyLight)

        let floor = SCNNode(geometry: SCNFloor())
        floor.geometry?.firstMaterial?.diffuse.contents = UIColor(white: 0.12, alpha: 1)
        floor.geometry?.firstMaterial?.roughness.contents = 0.8
        floor.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        floor.physicsBody?.friction = 0.85
        floor.physicsBody?.restitution = 0.45
        Self.configureBoundaryPhysics(floor.physicsBody)
        scene.rootNode.addChildNode(floor)

        addBoundaryWalls()
    }

    private func addBoundaryWalls() {
        let wallThickness: CGFloat = 0.25
        let wallHeight: CGFloat = 4
        let depthSpan: CGFloat = 5.0
        let halfDepth = Float(depthSpan / 2)

        let frontWall = Self.makeBoundaryWall(
            width: 8,
            height: wallHeight,
            length: wallThickness,
            restitution: 0.9
        )
        frontWall.position = SCNVector3(0, Float(wallHeight / 2), -halfDepth)
        scene.rootNode.addChildNode(frontWall)

        let backWall = Self.makeBoundaryWall(
            width: 8,
            height: wallHeight,
            length: wallThickness,
            restitution: 0.9
        )
        backWall.position = SCNVector3(0, Float(wallHeight / 2), halfDepth)
        scene.rootNode.addChildNode(backWall)

        ceilingNode.position = SCNVector3(0, 3.0, 0)
        scene.rootNode.addChildNode(ceilingNode)

        leftWallNode.position = SCNVector3(-2.0, Float(wallHeight / 2), 0)
        scene.rootNode.addChildNode(leftWallNode)

        rightWallNode.position = SCNVector3(2.0, Float(wallHeight / 2), 0)
        scene.rootNode.addChildNode(rightWallNode)
    }

    // MARK: - Boundaries

    private static func configureBoundaryPhysics(_ body: SCNPhysicsBody?) {
        body?.categoryBitMask = DicePhysicsCategory.boundary
        body?.contactTestBitMask = DicePhysicsCategory.dice
        body?.collisionBitMask = DicePhysicsCategory.dice
        body?.restitution = max(body?.restitution ?? 0, 0.85)
        body?.friction = body?.friction ?? 0.2
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
        wall.physicsBody?.restitution = restitution
        wall.physicsBody?.friction = 0.15
        configureBoundaryPhysics(wall.physicsBody)
        return wall
    }
}
