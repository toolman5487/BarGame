//
//  MatchDetailPointDistributionCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/21.
//

import SnapKit
import UIKit

@MainActor
final class MatchDetailPointDistributionCell: DetailBaseCollectionViewCell {

    enum Metrics {
        static let preferredHeight: CGFloat = 336
        static let horizontalInset: CGFloat = 16
        static let rowSpacing: CGFloat = 0
    }

    private let rows = (1...6).map { MatchDetailDistributionRow(faceValue: $0) }

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: rows)
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = Metrics.rowSpacing
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    override func setHierarchy() {
        contentView.addSubview(contentStackView)
    }

    override func setLayout() {
        contentStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Metrics.horizontalInset)
            make.top.bottom.equalToSuperview()
        }
    }

    func configure(items: [MatchDetailPointDistributionItem]) {
        let maximumCount = max(items.map(\.count).max() ?? 0, 1)
        let itemsByFaceValue = Dictionary(
            uniqueKeysWithValues: items.map { ($0.faceValue, $0) }
        )

        for row in rows {
            row.configure(
                item: itemsByFaceValue[row.faceValue],
                maximumCount: maximumCount
            )
        }
    }
}

@MainActor
private final class MatchDetailDistributionRow: UIView {

    private enum Metrics {
        static let faceSize: CGFloat = 44
        static let countWidth: CGFloat = 32
        static let horizontalSpacing: CGFloat = 12
        static let barHeight: CGFloat = 8
    }

    let faceValue: Int

    private let faceLabelView: GlassLabelView = {
        let baseFont = UIFont.monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize,
            weight: .regular
        )
        return ViewFactory.makeGlassLabel(
            font: baseFont,
            textColor: ThemeColor.primary,
            textAlignment: .center,
            numberOfLines: 1,
            contentInsets: .zero
        )
    }()

    private let trackView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemFill
        view.layer.cornerRadius = Metrics.barHeight / 2
        view.layer.masksToBounds = true
        return view
    }()

    private let fillView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemYellow
        view.layer.cornerRadius = Metrics.barHeight / 2
        view.layer.masksToBounds = true
        return view
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize,
            weight: .regular
        )
        label.textColor = ThemeColor.secondary
        label.textAlignment = .right
        return label
    }()

    private var fillWidthConstraint: Constraint?

    init(faceValue: Int) {
        self.faceValue = faceValue
        super.init(frame: .zero)
        faceLabelView.configure(text: String(faceValue))
        setupHierarchy()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        item: MatchDetailPointDistributionItem?,
        maximumCount: Int
    ) {
        let count = item?.count ?? 0
        countLabel.text = String(count)
        let ratio = CGFloat(count) / CGFloat(maximumCount)
        fillWidthConstraint?.deactivate()
        fillView.snp.makeConstraints { make in
            if count == 0 {
                fillWidthConstraint = make.width.equalTo(0).constraint
            } else {
                fillWidthConstraint = make.width
                    .equalTo(trackView)
                    .multipliedBy(ratio)
                    .constraint
            }
        }
    }

    private func setupHierarchy() {
        addSubview(faceLabelView)
        addSubview(trackView)
        trackView.addSubview(fillView)
        addSubview(countLabel)
    }

    private func setupLayout() {
        faceLabelView.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.size.equalTo(Metrics.faceSize)
        }

        countLabel.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.width.equalTo(Metrics.countWidth)
        }

        trackView.snp.makeConstraints { make in
            make.left.equalTo(faceLabelView.snp.right)
                .offset(Metrics.horizontalSpacing)
            make.right.equalTo(countLabel.snp.left).offset(-Metrics.horizontalSpacing)
            make.centerY.equalToSuperview()
            make.height.equalTo(Metrics.barHeight)
        }

        fillView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            fillWidthConstraint = make.width.equalTo(0).constraint
        }
    }
}
