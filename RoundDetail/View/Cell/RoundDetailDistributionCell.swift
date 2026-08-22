//
//  RoundDetailDistributionCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import SnapKit
import UIKit

@MainActor
final class RoundDetailDistributionCell: DetailBaseCollectionViewCell {

    enum Metrics {
        static let preferredHeight: CGFloat = 104
        static let verticalInset: CGFloat = 4
        static let contentInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
    }

    private let backgroundButton = ViewFactory.makeButton()
    private let metricViews = (1...6).map {
        RoundDetailDistributionMetricView(faceValue: $0)
    }

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: metricViews)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = Metrics.itemSpacing
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    override func setHierarchy() {
        contentView.addSubview(backgroundButton)
        contentView.addSubview(contentStackView)
    }

    override func setLayout() {
        backgroundButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(Metrics.verticalInset)
        }
        contentStackView.snp.makeConstraints { make in
            make.edges.equalTo(backgroundButton).inset(Metrics.contentInset)
        }
    }

    func configure(items: [RoundDetailDistributionItem]) {
        let itemsByFaceValue = Dictionary(
            uniqueKeysWithValues: items.map { ($0.faceValue, $0) }
        )
        for metricView in metricViews {
            metricView.configure(
                count: itemsByFaceValue[metricView.faceValue]?.count ?? 0
            )
        }
    }
}

@MainActor
private final class RoundDetailDistributionMetricView: UIView {

    let faceValue: Int

    private let faceLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize,
            weight: .semibold
        )
        label.textColor = ThemeColor.primary
        label.textAlignment = .center
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize,
            weight: .regular
        )
        label.textColor = ThemeColor.secondary
        label.textAlignment = .center
        return label
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [faceLabel, countLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 4
        return stackView
    }()

    init(faceValue: Int) {
        self.faceValue = faceValue
        super.init(frame: .zero)
        faceLabel.text = String(faceValue)
        addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(count: Int) {
        countLabel.text = "× \(count)"
        faceLabel.textColor = count > 0
            ? ThemeColor.primary
            : ThemeColor.secondary
    }
}
