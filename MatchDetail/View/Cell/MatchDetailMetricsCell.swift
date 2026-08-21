//
//  MatchDetailMetricsCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/21.
//

import SnapKit
import UIKit

@MainActor
final class MatchDetailMetricsCell: DetailBaseCollectionViewCell {

    enum Metrics {
        static let preferredHeight: CGFloat = 104
        static let verticalCardInset: CGFloat = 4
        static let contentInset: CGFloat = 16
    }

    private let backgroundButton = ViewFactory.makeButton()
    private let metricViews = (0..<4).map { _ in MatchDetailMetricView() }

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: metricViews)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
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
            make.top.bottom.equalToSuperview().inset(Metrics.verticalCardInset)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalTo(backgroundButton).inset(Metrics.contentInset)
        }
    }

    func configure(metrics: [MatchDetailMetric]) {
        for (index, view) in metricViews.enumerated() {
            guard metrics.indices.contains(index) else {
                view.configure(metric: nil)
                continue
            }
            view.configure(metric: metrics[index])
        }
    }
}

@MainActor
private final class MatchDetailMetricView: UIView {

    private enum Metrics {
        static let spacing: CGFloat = 4
    }

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize,
            weight: .semibold
        )
        label.textColor = ThemeColor.primary
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ThemeColor.secondary
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Metrics.spacing
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(4)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(metric: MatchDetailMetric?) {
        valueLabel.text = metric?.value
        titleLabel.text = metric?.title
    }
}
