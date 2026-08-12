//
//  GameDetailStartCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import SnapKit
import UIKit

@MainActor
final class GameDetailStartCell: DetailBaseCollectionViewCell {

    // MARK: - Callback

    var tapHandler: (() -> Void)?

    // MARK: - UI Elements

    private let startButton: UIButton = {
        let button = ViewFactory.makeButton()
        button.isUserInteractionEnabled = true
        return button
    }()

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(startButton)
    }

    override func setLayout() {
        startButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func setAppearance() {
        super.setAppearance()
        startButton.addAction(
            UIAction { [weak self] _ in
                self?.tapHandler?()
            },
            for: .primaryActionTriggered
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tapHandler = nil
    }

    // MARK: - Configuration

    func configure(title: String) {
        var configuration = startButton.configuration ?? .prominentGlass()
        configuration.title = title
        startButton.configuration = configuration
    }
}
