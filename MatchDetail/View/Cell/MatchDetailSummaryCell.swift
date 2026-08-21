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
    }

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize,
            weight: .heavy
        )
        label.textColor = ThemeColor.primary
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    override func setHierarchy() {
        contentView.addSubview(scoreLabel)
    }

    override func setLayout() {
        scoreLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.lessThanOrEqualToSuperview()
                .inset(Metrics.contentInset)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        scoreLabel.text = nil
    }

    func configure(presentation: MatchDetailPresentation) {
        scoreLabel.text = presentation.scoreText
    }
}
