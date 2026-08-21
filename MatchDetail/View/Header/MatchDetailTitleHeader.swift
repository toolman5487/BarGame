//
//  MatchDetailTitleHeader.swift
//  BarGame
//
//  Created by Codex on 2026/8/21.
//

import UIKit

@MainActor
final class MatchDetailTitleHeader: DetailBaseTitleHeader {

    override func setAppearance() {
        super.setAppearance()
        titleLabel.font = .preferredFont(forTextStyle: .title2)
    }
}
