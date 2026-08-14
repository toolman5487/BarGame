//
//  DiceGameBottomBar.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/14.
//

import UIKit

@MainActor
final class DiceGameBottomBar: BaseBottomBar {

    init() {
        super.init(title: "確定")
        backgroundColor = .clear
        dividerColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
