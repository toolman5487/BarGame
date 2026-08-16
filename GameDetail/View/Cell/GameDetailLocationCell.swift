//
//  GameDetailLocationCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import SnapKit
import UIKit

@MainActor
final class GameDetailLocationCell: DetailBaseCollectionViewCell {

    enum Metrics {
        static let preferredHeight: CGFloat = 112
        static let contentInset: CGFloat = 16
        static let contentSpacing: CGFloat = 12
        static let actionControlSize: CGFloat = 44
    }

    var locationRequest: (() -> Void)?

    private let actionButton = ViewFactory.makeIconButton(
        systemName: "location.fill"
    )

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = ThemeColor.primary
        label.textAlignment = .right
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = ThemeColor.secondary
        label.textAlignment = .right
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 4
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            actionButton,
            textStackView,
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Metrics.contentSpacing
        return stackView
    }()

    override func setHierarchy() {
        contentView.addSubview(contentStackView)
    }

    override func setLayout() {
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Metrics.contentInset)
        }

        actionButton.snp.makeConstraints { make in
            make.size.equalTo(Metrics.actionControlSize)
        }
    }

    override func setAppearance() {
        super.setAppearance()
        titleLabel.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )
        subtitleLabel.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )
        actionButton.addAction(
            UIAction { [weak self] _ in
                self?.locationRequest?()
            },
            for: .primaryActionTriggered
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        actionButton.isEnabled = false
        actionButton.accessibilityLabel = nil
        locationRequest = nil
    }

    func configure(state: GameDetailLocationState) {
        let presentation = state.presentation
        titleLabel.text = presentation.title
        subtitleLabel.text = presentation.subtitle
        actionButton.accessibilityLabel = presentation.actionTitle
        actionButton.isEnabled = presentation.isActionEnabled
        setActionIcon(systemName: presentation.actionSystemName)
    }

    private func setActionIcon(systemName: String) {
        var configuration = actionButton.configuration
        configuration?.image = UIImage(systemName: systemName)
        actionButton.configuration = configuration
    }
}
