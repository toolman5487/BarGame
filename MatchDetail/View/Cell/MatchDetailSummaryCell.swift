//
//  MatchDetailSummaryCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/21.
//

import SnapKit
import UIKit

@MainActor
final class MatchDetailSummaryCell: DetailBaseCollectionViewCell {

    enum Metrics {
        static let preferredHeight: CGFloat = 96
        static let contentInset: CGFloat = 16
        static let contentSpacing: CGFloat = 8
        static let iconSize: CGFloat = 32
    }

    private let winIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "trophy.fill"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemYellow
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            textStyle: .title1,
            scale: .medium
        )
        return imageView
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let lossIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "flag.fill"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            textStyle: .title1,
            scale: .medium
        )
        return imageView
    }()

    private lazy var scoreboardStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            winIconView,
            scoreLabel,
            lossIconView,
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Metrics.contentSpacing
        return stackView
    }()

    override func setHierarchy() {
        contentView.addSubview(scoreboardStackView)
    }

    override func setLayout() {
        winIconView.snp.makeConstraints { make in
            make.size.equalTo(Metrics.iconSize)
        }
        lossIconView.snp.makeConstraints { make in
            make.size.equalTo(Metrics.iconSize)
        }
        scoreboardStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.lessThanOrEqualToSuperview()
                .inset(Metrics.contentInset)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        scoreLabel.attributedText = nil
    }

    func configure(presentation: MatchDetailPresentation) {
        scoreLabel.attributedText = makeScoreAttributedText(
            winScoreText: presentation.winScoreText,
            lossScoreText: presentation.lossScoreText
        )
    }

    private func makeScoreAttributedText(
        winScoreText: String,
        lossScoreText: String
    ) -> NSAttributedString {
        let scoreFont = UIFont.monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize,
            weight: .heavy
        )
        let scoreAttributes: [NSAttributedString.Key: Any] = [
            .font: scoreFont,
            .foregroundColor: ThemeColor.primary,
        ]
        let separatorAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .title1),
            .foregroundColor: ThemeColor.secondary,
        ]

        let attributedText = NSMutableAttributedString(
            string: winScoreText,
            attributes: scoreAttributes
        )
        attributedText.append(
            NSAttributedString(
                string: "-",
                attributes: separatorAttributes
            )
        )
        attributedText.append(
            NSAttributedString(
                string: lossScoreText,
                attributes: scoreAttributes
            )
        )
        return attributedText
    }
}
