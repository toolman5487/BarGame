//
//  GameDetailStatisticsCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/13.
//

import SnapKit
import UIKit

@MainActor
final class GameDetailStatisticsCell: DetailBaseCollectionViewCell {

    // MARK: - Metrics

    enum Metrics {
        static let preferredHeight: CGFloat = 144
        static let contentInset: CGFloat = 16
        static let rowSpacing: CGFloat = 16
    }

    // MARK: - UI Elements

    private let backgroundButton: UIButton = {
        let button = ViewFactory.makeButton()
        button.isUserInteractionEnabled = false
        return button
    }()

    private let winsView = GameDetailStatisticsMetricView(
        systemName: "trophy.fill",
        tintColor: .systemYellow
    )
    private let drawsView = GameDetailStatisticsMetricView(
        systemName: "flag.and.flag.filled.crossed",
        tintColor: .systemGray
    )
    private let lossesView = GameDetailStatisticsMetricView(
        systemName: "flag.fill",
        tintColor: .label
    )
    private let winRateView = GameDetailStatisticsMetricView(title: "勝率")
    private let scoreDifferenceView = GameDetailStatisticsMetricView(title: "淨勝分")
    private let streakView = GameDetailStatisticsMetricView(title: "近況")

    private lazy var primaryStackView = makeMetricStackView(
        arrangedSubviews: [winsView, drawsView, lossesView]
    )
    private lazy var secondaryStackView = makeMetricStackView(
        arrangedSubviews: [winRateView, scoreDifferenceView, streakView]
    )
    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            primaryStackView,
            secondaryStackView,
        ])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = Metrics.rowSpacing
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeColor.secondary
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(backgroundButton)
        contentView.addSubview(contentStackView)
        contentView.addSubview(statusLabel)
    }

    override func setLayout() {
        backgroundButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Metrics.contentInset)
        }

        statusLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Metrics.contentInset)
            make.centerY.equalToSuperview()
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        apply(state: .empty)
    }

    // MARK: - Configuration

    func configure(state: GameDetailStatisticsState) {
        apply(state: state)
    }

    // MARK: - Private

    private func makeMetricStackView(arrangedSubviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }

    private func apply(state: GameDetailStatisticsState) {
        switch state {
        case .empty:
            contentStackView.isHidden = true
            statusLabel.isHidden = false
            statusLabel.text = "尚無戰績摘要"
            resetMetrics()

        case .content(let statistics):
            contentStackView.isHidden = false
            statusLabel.isHidden = true
            statusLabel.text = nil
            winsView.configure(value: String(statistics.wins))
            drawsView.configure(value: String(statistics.draws))
            lossesView.configure(value: String(statistics.losses))
            winRateView.configure(value: formattedWinRate(statistics.winRate))
            scoreDifferenceView.configure(
                value: formattedScoreDifference(statistics.scoreDifference)
            )
            streakView.configure(value: statistics.currentStreak.displayText)

        case .error(let message):
            contentStackView.isHidden = true
            statusLabel.isHidden = false
            statusLabel.text = "無法載入戰績\n\(message)"
            resetMetrics()
        }
    }

    private func resetMetrics() {
        [
            winsView,
            drawsView,
            lossesView,
            winRateView,
            scoreDifferenceView,
            streakView,
        ].forEach { $0.configure(value: nil) }
    }

    private func formattedWinRate(_ winRate: Double) -> String {
        "\(Int((winRate * 100).rounded()))%"
    }

    private func formattedScoreDifference(_ scoreDifference: Int) -> String {
        scoreDifference > 0 ? "+\(scoreDifference)" : String(scoreDifference)
    }
}

// MARK: - Metric View

@MainActor
private final class GameDetailStatisticsMetricView: UIView {

    private enum Metrics {
        static let indicatorSize: CGFloat = 18
        static let contentSpacing: CGFloat = 4
    }

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize,
            weight: .semibold
        )
        label.textColor = ThemeColor.primary
        label.textAlignment = .center
        label.numberOfLines = 1
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

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize,
            weight: .semibold
        )
        return imageView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            valueLabel,
            titleLabel,
            iconView,
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.spacing = Metrics.contentSpacing
        return stackView
    }()

    init(
        title: String? = nil,
        systemName: String? = nil,
        tintColor: UIColor = ThemeColor.secondary
    ) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.isHidden = title == nil
        iconView.image = systemName.flatMap(UIImage.init(systemName:))
        iconView.tintColor = tintColor
        iconView.isHidden = systemName == nil
        addSubview(stackView)
        iconView.snp.makeConstraints { make in
            make.size.equalTo(Metrics.indicatorSize)
        }
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(value: String?) {
        valueLabel.text = value
    }
}
