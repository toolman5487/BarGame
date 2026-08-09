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
            initialDiceCount: 2,
            maximumDiceCount: 2,
            preferredEdgeLength: 1.0
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
        accessibilityLabel = "骰子"
    }

    // MARK: - Public

    func shakeDice(intensity: Double = 1.2) {
        diceView.shake(intensity: intensity)
    }
}
