//
//  GameSettingTitleHeader.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import UIKit

@MainActor
final class GameSettingTitleHeader: DetailBaseTitleHeader {

    override func setAppearance() {
        super.setAppearance()
        titleLabel.font = .preferredFont(forTextStyle: .title2)
    }
}
