//
//  RoundDetailTitleHeader.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import UIKit

@MainActor
final class RoundDetailTitleHeader: DetailBaseTitleHeader {
   
    override func setAppearance() {
        super.setAppearance()
        titleLabel.font = .preferredFont(forTextStyle: .title2)
    }
}
