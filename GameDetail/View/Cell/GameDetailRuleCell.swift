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
        static let stepSize: CGFloat = 32
        static let stepCornerRadius: CGFloat = stepSize / 2
    }

    // MARK: - UI Elements

    private let stepContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        view.layer.cornerRadius = Metrics.stepCornerRadius
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let stepLabel: UILabel = {
        let label = UILabel()
        let baseFont = UIFont.monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
            weight: .semibold
        )
        label.font = baseFont
        label.textColor = .systemBlue
        label.textAlignment = .center
        return label
    }()

    private let ruleLabelView = ViewFactory.makeGlassLabel()

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(stepContainerView)
        stepContainerView.addSubview(stepLabel)
        contentView.addSubview(ruleLabelView)
    }

    override func setLayout() {
        stepContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(Metrics.horizontalInset)
            make.centerY.equalToSuperview()
            make.size.equalTo(Metrics.stepSize)
        }

        stepLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        ruleLabelView.snp.makeConstraints { make in
            make.left.equalTo(stepContainerView.snp.right).offset(Metrics.contentSpacing)
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
        stepLabel.text = nil
        ruleLabelView.configure(text: nil)
    }

    // MARK: - Configuration

    func configure(rule: GameDetailRule) {
        stepLabel.text = String(rule.step)
        ruleLabelView.configure(text: rule.text)
    }
}
