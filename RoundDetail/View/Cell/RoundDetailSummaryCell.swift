//
//  RoundDetailSummaryCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import SnapKit
import UIKit

@MainActor
final class RoundDetailSummaryCell: DetailBaseCollectionViewCell {

    enum Metrics {
        static let preferredHeight: CGFloat = 96
        static let contentInset: CGFloat = 16
        static let contentSpacing: CGFloat = 8
        static let iconSize: CGFloat = 32
    }

    private let outcomeIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            textStyle: .title1,
            scale: .medium
        )
        return imageView
    }()

    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let diceIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "dice.fill"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.primary
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            textStyle: .title1,
            scale: .medium
        )
        return imageView
    }()

    private lazy var summaryStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            outcomeIconView,
            pointsLabel,
            diceIconView,
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Metrics.contentSpacing
        return stackView
    }()

    override func setHierarchy() {
        contentView.addSubview(summaryStackView)
    }

    override func setLayout() {
        outcomeIconView.snp.makeConstraints { make in
            make.size.equalTo(Metrics.iconSize)
        }
        diceIconView.snp.makeConstraints { make in
            make.size.equalTo(Metrics.iconSize)
        }
        summaryStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.lessThanOrEqualToSuperview()
                .inset(Metrics.contentInset)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        outcomeIconView.image = nil
        pointsLabel.attributedText = nil
    }

    func configure(presentation: RoundDetailPresentation) {
        pointsLabel.attributedText = makePointsAttributedText(
            pointsText: presentation.totalPointsText
        )

        switch presentation.outcome {
        case .win:
            outcomeIconView.image = UIImage(systemName: "trophy.fill")
            outcomeIconView.tintColor = .systemYellow

        case .loss:
            outcomeIconView.image = UIImage(systemName: "flag.fill")
            outcomeIconView.tintColor = ThemeColor.primary
        }
    }

    private func makePointsAttributedText(
        pointsText: String
    ) -> NSAttributedString {
        let pointsFont = UIFont.monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize,
            weight: .heavy
        )
        let attributedText = NSMutableAttributedString(
            string: pointsText,
            attributes: [
                .font: pointsFont,
                .foregroundColor: ThemeColor.primary,
            ]
        )
        attributedText.append(
            NSAttributedString(
                string: " 點",
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .title1),
                    .foregroundColor: ThemeColor.secondary,
                ]
            )
        )
        return attributedText
    }
}
