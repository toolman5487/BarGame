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
        static let preferredHeight: CGFloat = 96
        static let contentInset: CGFloat = 16
        static let contentSpacing: CGFloat = 12
        static let iconSize: CGFloat = 24
        static let iconContainerSize: CGFloat = 32
        static let actionButtonWidth: CGFloat = 72
        static let actionButtonHeight: CGFloat = 44
    }

    var locationRequest: (() -> Void)?

    private let backgroundButton: UIButton = {
        let button = ViewFactory.makeButton()
        button.isUserInteractionEnabled = false
        return button
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.primary
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            textStyle: .title3,
            scale: .medium
        )
        return imageView
    }()

    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private let iconContainerView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = ThemeColor.primary
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = ThemeColor.secondary
        label.numberOfLines = 2
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

    private let actionButton: UIButton = {
        let button = ViewFactory.makeButton()
        button.isUserInteractionEnabled = true
        return button
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            iconContainerView,
            textStackView,
            actionButton,
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Metrics.contentSpacing
        return stackView
    }()

    override func setHierarchy() {
        contentView.addSubview(backgroundButton)
        contentView.addSubview(contentStackView)
        iconContainerView.addSubview(iconImageView)
        iconContainerView.addSubview(activityIndicator)
    }

    override func setLayout() {
        backgroundButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Metrics.contentInset)
        }

        iconContainerView.snp.makeConstraints { make in
            make.size.equalTo(Metrics.iconContainerSize)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(Metrics.iconSize)
        }

        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        actionButton.snp.makeConstraints { make in
            make.width.equalTo(Metrics.actionButtonWidth)
            make.height.equalTo(Metrics.actionButtonHeight)
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
        iconImageView.image = nil
        iconImageView.isHidden = false
        activityIndicator.stopAnimating()
        titleLabel.text = nil
        subtitleLabel.text = nil
        actionButton.isHidden = true
        setActionTitle(nil)
        locationRequest = nil
    }

    func configure(state: GameDetailLocationState) {
        let presentation = state.presentation
        iconImageView.image = UIImage(systemName: presentation.symbolSystemName)
        titleLabel.text = presentation.title
        subtitleLabel.text = presentation.subtitle
        setActionTitle(presentation.actionTitle)
        actionButton.isHidden = presentation.actionTitle == nil
        iconImageView.isHidden = presentation.showsActivityIndicator

        if presentation.showsActivityIndicator {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    private func setActionTitle(_ title: String?) {
        var configuration = actionButton.configuration ?? .prominentGlass()
        configuration.title = title
        actionButton.configuration = configuration
    }
}
