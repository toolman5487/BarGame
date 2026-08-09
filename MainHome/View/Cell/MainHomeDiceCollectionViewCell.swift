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
        configuration: GameDiceView.Configuration(
            initialDiceCount: 6,
            maximumDiceCount: 6,
            preferredEdgeLength: 1.0,
            sceneAppearance: .systemBackground
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
        accessibilityLabel = "骰子"
    }

    // MARK: - Public

    func shakeDice(intensity: Double = 1.2) {
        diceView.shake(intensity: intensity)
    }
}
