//
//  DiceControlCollectionViewCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/7.
//

import SnapKit
import UIKit

@MainActor
final class DiceControlCollectionViewCell: UICollectionViewCell {

    // MARK: - Types

    struct Configuration {

        let image: UIImage?
        let foregroundColor: UIColor
        let isEnabled: Bool
    }

    // MARK: - Properties

    static let reuseIdentifier = String(describing: DiceControlCollectionViewCell.self)

    private let button: UIButton = {
        let button = UIButton(type: .system)
        button.isUserInteractionEnabled = false
        return button
    }()

    override var isHighlighted: Bool {
        didSet {
            button.isHighlighted = isHighlighted
        }
    }

    override var isSelected: Bool {
        didSet {
            button.isSelected = isSelected
        }
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
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
        button.configuration = buttonConfiguration
        button.isEnabled = configuration.isEnabled
        isUserInteractionEnabled = configuration.isEnabled
    }

    // MARK: - Setup

    private func setupButton() {
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
