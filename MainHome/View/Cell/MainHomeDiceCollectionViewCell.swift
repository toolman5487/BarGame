//
//  MainHomeDiceCollectionViewCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/9.
//

import SnapKit
import UIKit

@MainActor
final class MainHomeDiceCollectionViewCell: MainBaseCollectionViewCell {

    // MARK: - UI Elements

    private let diceView = GameDiceView(
        configuration: GameDiceViewConfiguration(
            initialDiceCount: 12,
            maximumDiceCount: 12,
            preferredEdgeLength: 0.62,
            preferredCameraDistance: 3.8,
            sceneAppearance: .systemBackground,
            cameraViewpoint: .horizontal
        )
    )

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(diceView)
    }

    override func setLayout() {
        diceView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .systemBackground
    }

    // MARK: - Public

    func shakeDice(intensity: Double = 1.2) {
        diceView.shake(intensity: intensity)
    }
}
