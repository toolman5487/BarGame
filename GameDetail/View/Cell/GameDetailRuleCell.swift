//
//  GameDetailRuleCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import SnapKit
import UIKit

@MainActor
final class GameDetailRuleCell: DetailBaseCollectionViewCell {

    // MARK: - Metrics

    private enum Metrics {
        static let horizontalInset: CGFloat = 16
        static let glassVerticalInset: CGFloat = 4
        static let contentSpacing: CGFloat = 12
        static let stepSize: CGFloat = 44
    }

    // MARK: - UI Elements

    private let stepLabelView: GlassLabelView = {
        let baseFont = UIFont.monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize,
            weight: .regular
        )
        return ViewFactory.makeGlassLabel(
            font: baseFont,
            textColor: ThemeColor.primary,
            textAlignment: .center,
            numberOfLines: 1,
            contentInsets: NSDirectionalEdgeInsets(
                top: 0,
                leading: 0,
                bottom: 0,
                trailing: 0
            )
        )
    }()

    private let ruleLabelView = ViewFactory.makeGlassLabel(textStyle: .body)

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(stepLabelView)
        contentView.addSubview(ruleLabelView)
    }

    override func setLayout() {
        stepLabelView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(Metrics.horizontalInset)
            make.centerY.equalToSuperview()
            make.size.equalTo(Metrics.stepSize)
        }

        ruleLabelView.snp.makeConstraints { make in
            make.left.equalTo(stepLabelView.snp.right).offset(Metrics.contentSpacing)
            make.right.equalToSuperview().inset(Metrics.horizontalInset)
            make.top.bottom.equalToSuperview().inset(Metrics.glassVerticalInset)
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stepLabelView.configure(text: nil)
        ruleLabelView.configure(text: nil)
    }

    // MARK: - Configuration

    func configure(rule: GameDetailRule) {
        stepLabelView.configure(text: String(rule.step))
        ruleLabelView.configure(text: rule.text)
    }
}
