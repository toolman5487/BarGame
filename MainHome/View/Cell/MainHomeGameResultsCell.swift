//
//  MainHomeGameResultsCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/11.
//

import SnapKit
import UIKit

// MARK: - MainHomeResultEmptyView

@MainActor
final class MainHomeResultEmptyView: BaseHintView {

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyDefaultContent()
    }

    // MARK: - Private

    private func applyDefaultContent() {
        symbolEffect = .wiggle(.repeating)
        configure(
            image: UIImage(systemName: "flag.pattern.checkered.2.crossed"),
            title: "尚無戰績",
            subtitle: "完成一場遊戲吧！"
        )
    }
}

@MainActor
final class MainHomeGameResultsCell: MainBaseCollectionViewCell {

    // MARK: - Metrics

    enum Metrics {
        static let itemSize = CGSize(width: 280, height: 144)
        static let interitemSpacing: CGFloat = 12
        static let contentInset = UIEdgeInsets(
            top: 16,
            left: 16,
            bottom: 16,
            right: 16
        )
        static let preferredHeight = itemSize.height
            + contentInset.top
            + contentInset.bottom
    }

    // MARK: - UI Elements

    private let emptyView = MainHomeResultEmptyView()
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeFlowLayout()
        )
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.isDirectionalLockEnabled = true
        collectionView.decelerationRate = .fast
        collectionView.allowsSelection = false
        collectionView.delaysContentTouches = false
        collectionView.dataSource = self
        collectionView.register(MainHomeGameResultItemCell.self)
        return collectionView
    }()

    // MARK: - Callback

    var tapHandler: ((GameOverview) -> Void)?

    // MARK: - State

    private var results: [GameOverview] = []

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(collectionView)
        contentView.addSubview(emptyView)
    }

    override func setLayout() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .systemBackground
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        results = []
        tapHandler = nil
        collectionView.setContentOffset(.zero, animated: false)
        updateContentVisibility()
        collectionView.reloadData()
    }

    // MARK: - Configuration

    func configure(results: [GameOverview]) {
        self.results = results
        updateContentVisibility()
        collectionView.reloadData()
    }

    // MARK: - Private

    private func makeFlowLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = Metrics.itemSize
        layout.minimumLineSpacing = Metrics.interitemSpacing
        layout.sectionInset = Metrics.contentInset
        return layout
    }

    private func updateContentVisibility() {
        let isEmpty = results.isEmpty
        collectionView.isHidden = isEmpty
        emptyView.isHidden = !isEmpty
    }
}

// MARK: - UICollectionViewDataSource

extension MainHomeGameResultsCell: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        results.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            MainHomeGameResultItemCell.self,
            for: indexPath
        )
        let result = results[indexPath.item]
        cell.configure(result: result)
        cell.tapHandler = { [weak self] in
            self?.tapHandler?(result)
        }
        return cell
    }
}

// MARK: - MainHomeGameResultItemCell

@MainActor
final class MainHomeGameResultItemCell: MainBaseCollectionViewCell {

    // MARK: - Metrics

    private enum Metrics {
        static let contentInset: CGFloat = 16
        static let verticalInset: CGFloat = 16
        static let scoreSpacing: CGFloat = 4
        static let iconSpacing: CGFloat = 8
    }

    // MARK: - Callback

    var tapHandler: (() -> Void)?

    // MARK: - UI Elements

    private let backgroundButton: UIButton = {
        let button = ViewFactory.makeButton()
        button.isUserInteractionEnabled = true
        return button
    }()

    private let gameTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title2)
        label.textColor = ThemeColor.primary
        label.numberOfLines = 1
        label.textAlignment = .center
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private let winsScoreView = ScoreMetricView(
        systemName: "trophy.fill",
        tintColor: .systemYellow,
        imagePlacement: .leading
    )

    private let lossesScoreView = ScoreMetricView(
        systemName: "flag.fill",
        tintColor: .label,
        imagePlacement: .trailing
    )

    private let scoreSeparatorLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title2)
        label.text = "-"
        label.textColor = ThemeColor.secondary
        label.textAlignment = .center
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var scoreboardStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            winsScoreView,
            scoreSeparatorLabel,
            lossesScoreView,
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = Metrics.scoreSpacing
        stackView.isUserInteractionEnabled = false
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            gameTitleLabel,
            scoreboardStackView,
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(backgroundButton)
        contentView.addSubview(contentStackView)
    }

    override func setLayout() {
        backgroundButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Metrics.verticalInset)
            make.bottom.equalToSuperview().inset(Metrics.verticalInset / 2)
            make.left.right.equalToSuperview().inset(Metrics.contentInset)
        }

        scoreboardStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .clear
        backgroundButton.addAction(
            UIAction { [weak self] _ in
                self?.tapHandler?()
            },
            for: .primaryActionTriggered
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tapHandler = nil
        gameTitleLabel.text = nil
        winsScoreView.apply(value: nil)
        lossesScoreView.apply(value: nil)
    }

    // MARK: - Configuration

    func configure(result: GameOverview) {
        gameTitleLabel.text = result.game.title
        winsScoreView.apply(value: result.statistics.wins)
        lossesScoreView.apply(value: result.statistics.losses)
    }

    // MARK: - ScoreMetricView

    @MainActor
    private final class ScoreMetricView: UIView {

        enum ImagePlacement {
            case leading
            case trailing
        }

        private let imagePlacement: ImagePlacement

        private let valueLabel: UILabel = {
            let label = UILabel()
            label.font = .monospacedDigitSystemFont(
                ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize,
                weight: .bold
            )
            label.numberOfLines = 1
            label.textAlignment = .center
            return label
        }()

        private let iconView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
                pointSize: UIFont.preferredFont(forTextStyle: .title2).pointSize,
                weight: .regular
            )
            return imageView
        }()

        private lazy var stackView: UIStackView = {
            let arrangedSubviews: [UIView]
            switch imagePlacement {
            case .leading:
                arrangedSubviews = [iconView, valueLabel]

            case .trailing:
                arrangedSubviews = [valueLabel, iconView]
            }

            let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.spacing = Metrics.iconSpacing
            return stackView
        }()

        init(
            systemName: String,
            tintColor: UIColor,
            imagePlacement: ImagePlacement
        ) {
            self.imagePlacement = imagePlacement
            super.init(frame: .zero)
            iconView.image = UIImage(systemName: systemName)
            iconView.tintColor = tintColor
            valueLabel.textColor = ThemeColor.primary
            backgroundColor = .clear
            addSubview(stackView)

            stackView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.top.greaterThanOrEqualToSuperview()
                make.bottom.lessThanOrEqualToSuperview()

                switch imagePlacement {
                case .leading:
                    make.left.greaterThanOrEqualToSuperview()
                    make.right.equalToSuperview()

                case .trailing:
                    make.left.equalToSuperview()
                    make.right.lessThanOrEqualToSuperview()
                }
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func apply(value: Int?) {
            valueLabel.text = value.map(String.init)
        }
    }
}
