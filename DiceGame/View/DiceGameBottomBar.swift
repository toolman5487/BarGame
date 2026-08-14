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

    func configure(with action: DiceGamePrimaryAction) {
        switch action {
        case .confirmResult(let isEnabled):
            setActionTitle("確定")
            self.isEnabled = isEnabled

        case .startNextRound(let isEnabled):
            setActionTitle("下一賽局")
            self.isEnabled = isEnabled
        }
    }
}
