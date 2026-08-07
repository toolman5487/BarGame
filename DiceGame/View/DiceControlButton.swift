//
//  DiceControlButton.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/7.
//

import UIKit

@MainActor
final class DiceControlButton: UIButton {

    // MARK: - Types

    struct Configuration {

        let image: UIImage?
        let foregroundColor: UIColor
        let isEnabled: Bool
    }

    // MARK: - Properties

    let control: DiceGameControl

    // MARK: - Lifecycle

    init(control: DiceGameControl) {
        self.control = control
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func configure(with configuration: Configuration) {
        var buttonConfiguration = UIButton.Configuration.glass()
        buttonConfiguration.cornerStyle = .capsule
        buttonConfiguration.image = configuration.image
        buttonConfiguration.baseForegroundColor = configuration.foregroundColor
        self.configuration = buttonConfiguration
        isEnabled = configuration.isEnabled
    }
}
