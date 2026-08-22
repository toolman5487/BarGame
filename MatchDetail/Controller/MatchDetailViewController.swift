//
//  MatchDetailViewController.swift
//  BarGame
//
//  Created by Codex on 2026/8/21.
//

import Combine
import UIKit

@MainActor
final class MatchDetailViewController: DetailBaseViewController {

    private enum NavigationTitleStyle {
        case gameOutcome
        case score
    }

    // MARK: - Dependencies

    private let viewModel: any MatchDetailViewModeling
    private let matchID: UUID
    private let gameID: DiceGameID
    private let outcome: MatchOutcome
    private lazy var router: any MatchDetailRouting = MatchDetailRouter(
        sourceViewController: self,
        screenBuilder: screenBuilder
    )
    private let screenBuilder: any AppScreenBuilding

    // MARK: - Input

    private let viewWillAppearSubject = PassthroughSubject<Void, Never>()
    private let retryRequestSubject = PassthroughSubject<Void, Never>()

    // MARK: - State

    private var state = MatchDetailViewState.idle
    private var sections: [MatchDetailSection] = []
    private var cancellables = Set<AnyCancellable>()
    private var navigationTitleStyle = NavigationTitleStyle.gameOutcome

    // MARK: - UI Elements

    private let navigationTitleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Lifecycle

    init(
        matchID: UUID,
        gameID: DiceGameID,
        outcome: MatchOutcome,
        viewModel: any MatchDetailViewModeling,
        screenBuilder: any AppScreenBuilding
    ) {
        self.matchID = matchID
        self.gameID = gameID
        self.outcome = outcome
        self.viewModel = viewModel
        self.screenBuilder = screenBuilder
        super.init(title: gameID.title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearSubject.send()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Overridable

    override func setHierarchy() {
        super.setHierarchy()
        collectionView.dataSource = self
        collectionView.allowsSelection = true
        collectionView.register(MatchDetailSummaryCell.self)
        collectionView.register(MatchDetailMetricsCell.self)
        collectionView.register(MatchDetailProgressionCell.self)
        collectionView.register(MatchDetailRoundCell.self)
        collectionView.register(MatchDetailPointDistributionCell.self)
        collectionView.register(MatchDetailInformationCell.self)
        collectionView.register(MatchDetailStateCell.self)
        collectionView.register(MatchDetailTitleHeader.self)
    }

    override func setNavigation() {
        super.setNavigation()
        navigationItem.titleView = navigationTitleLabel
        updateNavigationTitle(animated: false)
    }

    override func bind() {
        let input = MatchDetailViewModelInput(
            viewWillAppear: viewWillAppearSubject.eraseToAnyPublisher(),
            retryRequest: retryRequestSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .sink { [weak self] state in
                self?.apply(state)
            }
            .store(in: &cancellables)
    }

    override func collectionViewItemSize(
        in collectionView: UICollectionView,
        at indexPath: IndexPath
    ) -> CGSize {
        let width = max(
            0,
            collectionView.bounds.width
                - collectionViewSectionInset.left
                - collectionViewSectionInset.right
        )

        guard case .content = state,
              sections.indices.contains(indexPath.section)
        else {
            let adjustedInset = collectionView.adjustedContentInset
            let height = collectionView.bounds.height
                - adjustedInset.top
                - adjustedInset.bottom
            return CGSize(
                width: width,
                height: max(BaseHintView.Metrics.preferredHeight, height)
            )
        }

        let height: CGFloat
        switch sections[indexPath.section] {
        case .summary:
            height = MatchDetailSummaryCell.Metrics.preferredHeight

        case .metrics:
            height = MatchDetailMetricsCell.Metrics.preferredHeight

        case .progression:
            height = MatchDetailProgressionCell.Metrics.preferredHeight

        case .rounds:
            height = MatchDetailRoundCell.Metrics.preferredHeight

        case .pointDistribution:
            height = MatchDetailPointDistributionCell.Metrics.preferredHeight

        case .information:
            height = MatchDetailInformationCell.Metrics.preferredHeight
        }

        return CGSize(width: width, height: height)
    }

    override func collectionViewHeaderSize(
        in collectionView: UICollectionView,
        section: Int
    ) -> CGSize {
        guard sections.indices.contains(section),
              sections[section].title != nil
        else { return .zero }

        return CGSize(
            width: collectionView.bounds.width,
            height: MatchDetailTitleHeader.Metrics.preferredHeight
        )
    }

    // MARK: - State Updates

    private func apply(_ state: MatchDetailViewState) {
        self.state = state

        switch state {
        case .idle, .loading, .failed:
            sections = []

        case .content(let presentation):
            sections = makeSections(for: presentation)
        }

        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        updateNavigationTitle(animated: false)
    }

    private func makeSections(
        for presentation: MatchDetailPresentation
    ) -> [MatchDetailSection] {
        var sections: [MatchDetailSection] = [
            .summary,
            .metrics,
        ]

        if presentation.progression.count >= 3 {
            sections.append(.progression)
        }
        if !presentation.rounds.isEmpty {
            sections.append(.rounds)
        }
        if presentation.pointDistribution.contains(where: { $0.count > 0 }) {
            sections.append(.pointDistribution)
        }
        sections.append(.information)
        return sections
    }

    // MARK: - Navigation Title

    private func setNavigationTitleStyle(
        _ style: NavigationTitleStyle,
        animated: Bool
    ) {
        guard navigationTitleStyle != style else { return }
        navigationTitleStyle = style
        updateNavigationTitle(animated: animated)
    }

    private func updateNavigationTitle(animated: Bool) {
        let attributedText: NSAttributedString
        switch navigationTitleStyle {
        case .gameOutcome:
            attributedText = makeGameOutcomeNavigationTitle()

        case .score:
            guard case .content(let presentation) = state else {
                navigationTitleStyle = .gameOutcome
                updateNavigationTitle(animated: animated)
                return
            }
            attributedText = makeScoreNavigationTitle(
                presentation: presentation
            )
        }

        let updates = {
            self.navigationTitleLabel.attributedText = attributedText
            self.navigationTitleLabel.invalidateIntrinsicContentSize()
        }

        guard animated else {
            updates()
            return
        }
        UIView.transition(
            with: navigationTitleLabel,
            duration: 0.2,
            options: .transitionCrossDissolve,
            animations: updates
        )
    }

    private func makeGameOutcomeNavigationTitle() -> NSAttributedString {
        let font = UIFont.preferredFont(forTextStyle: .headline)
        let outcomeAppearance = makeOutcomeAppearance()
        let title = NSMutableAttributedString(
            string: "\(gameID.title) ",
            attributes: [
                .font: font,
                .foregroundColor: ThemeColor.primary,
            ]
        )
        title.append(
            makeNavigationSymbol(
                systemName: outcomeAppearance.systemName,
                color: outcomeAppearance.color,
                font: font
            )
        )
        title.append(
            NSAttributedString(
                string: " \(outcomeAppearance.text)",
                attributes: [
                    .font: font,
                    .foregroundColor: outcomeAppearance.color,
                ]
            )
        )
        return title
    }

    private func makeScoreNavigationTitle(
        presentation: MatchDetailPresentation
    ) -> NSAttributedString {
        let font = UIFont.preferredFont(forTextStyle: .headline)
        let scoreFont = UIFont.monospacedDigitSystemFont(
            ofSize: font.pointSize,
            weight: .semibold
        )
        let title = NSMutableAttributedString()
        title.append(
            makeNavigationSymbol(
                systemName: "trophy.fill",
                color: .systemYellow,
                font: font
            )
        )
        title.append(
            NSAttributedString(
                string: " \(presentation.winScoreText)",
                attributes: [
                    .font: scoreFont,
                    .foregroundColor: ThemeColor.primary,
                ]
            )
        )
        title.append(
            NSAttributedString(
                string: "-",
                attributes: [
                    .font: font,
                    .foregroundColor: ThemeColor.secondary,
                ]
            )
        )
        title.append(
            NSAttributedString(
                string: "\(presentation.lossScoreText) ",
                attributes: [
                    .font: scoreFont,
                    .foregroundColor: ThemeColor.primary,
                ]
            )
        )
        title.append(
            makeNavigationSymbol(
                systemName: "flag.fill",
                color: ThemeColor.primary,
                font: font
            )
        )
        return title
    }

    private func makeNavigationSymbol(
        systemName: String,
        color: UIColor,
        font: UIFont
    ) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(
            systemName: systemName,
            withConfiguration: UIImage.SymbolConfiguration(textStyle: .headline)
        )?.withTintColor(
            color,
            renderingMode: .alwaysOriginal
        )
        attachment.bounds = CGRect(
            x: 0,
            y: (font.capHeight - font.lineHeight) / 2,
            width: font.lineHeight,
            height: font.lineHeight
        )
        return NSAttributedString(attachment: attachment)
    }

    private func makeOutcomeAppearance() -> (
        systemName: String,
        text: String,
        color: UIColor
    ) {
        switch outcome {
        case .win:
            return ("trophy.fill", "勝", .systemYellow)

        case .loss:
            return ("flag.fill", "敗", ThemeColor.primary)

        case .draw:
            return (
                "flag.and.flag.filled.crossed",
                "平",
                ThemeColor.secondary
            )
        }
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === collectionView,
              case .content = state,
              let summaryAttributes = collectionView.collectionViewLayout
                .layoutAttributesForItem(
                    at: IndexPath(item: 0, section: 0)
                )
        else { return }

        let visibleTop = scrollView.contentOffset.y
            + scrollView.adjustedContentInset.top
        let style: NavigationTitleStyle = visibleTop >= summaryAttributes.frame.maxY
            ? .score
            : .gameOutcome
        setNavigationTitleStyle(style, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension MatchDetailViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch state {
        case .idle, .loading, .failed:
            return 1

        case .content:
            return sections.count
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        guard case .content(let presentation) = state else { return 1 }
        guard sections.indices.contains(section) else { return 0 }

        switch sections[section] {
        case .rounds:
            return presentation.rounds.count

        case .summary, .metrics, .progression, .pointDistribution, .information:
            return 1
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard case .content(let presentation) = state else {
            let cell = collectionView.dequeueReusableCell(
                MatchDetailStateCell.self,
                for: indexPath
            )
            cell.configure(state: state)
            cell.retryHandler = { [weak self] in
                self?.retryRequestSubject.send()
            }
            return cell
        }

        guard sections.indices.contains(indexPath.section) else {
            preconditionFailure("Invalid MatchDetail section index: \(indexPath.section)")
        }

        switch sections[indexPath.section] {
        case .summary:
            let cell = collectionView.dequeueReusableCell(
                MatchDetailSummaryCell.self,
                for: indexPath
            )
            cell.configure(presentation: presentation)
            return cell

        case .metrics:
            let cell = collectionView.dequeueReusableCell(
                MatchDetailMetricsCell.self,
                for: indexPath
            )
            cell.configure(metrics: presentation.metrics)
            return cell

        case .progression:
            let cell = collectionView.dequeueReusableCell(
                MatchDetailProgressionCell.self,
                for: indexPath
            )
            cell.configure(items: presentation.progression)
            return cell

        case .rounds:
            guard presentation.rounds.indices.contains(indexPath.item) else {
                preconditionFailure("Invalid MatchDetail round index: \(indexPath.item)")
            }
            let cell = collectionView.dequeueReusableCell(
                MatchDetailRoundCell.self,
                for: indexPath
            )
            cell.configure(item: presentation.rounds[indexPath.item])
            return cell

        case .pointDistribution:
            let cell = collectionView.dequeueReusableCell(
                MatchDetailPointDistributionCell.self,
                for: indexPath
            )
            cell.configure(items: presentation.pointDistribution)
            return cell

        case .information:
            let cell = collectionView.dequeueReusableCell(
                MatchDetailInformationCell.self,
                for: indexPath
            )
            cell.configure(information: presentation.information)
            cell.retryHandler = { [weak self] in
                self?.retryRequestSubject.send()
            }
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == MatchDetailTitleHeader.elementKind,
              sections.indices.contains(indexPath.section),
              let title = sections[indexPath.section].title
        else { return UICollectionReusableView() }

        let header = collectionView.dequeueReusableHeader(
            MatchDetailTitleHeader.self,
            for: indexPath
        )
        header.configure(title: title)
        return header
    }
}

// MARK: - UICollectionViewDelegate

extension MatchDetailViewController {

    func collectionView(
        _ collectionView: UICollectionView,
        shouldSelectItemAt indexPath: IndexPath
    ) -> Bool {
        guard case .content(let presentation) = state,
              sections.indices.contains(indexPath.section),
              sections[indexPath.section] == .rounds
        else { return false }

        return presentation.rounds.indices.contains(indexPath.item)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard case .content(let presentation) = state,
              sections.indices.contains(indexPath.section),
              sections[indexPath.section] == .rounds,
              presentation.rounds.indices.contains(indexPath.item)
        else { return }

        router.route(
            to: .roundDetail(
                matchID: matchID,
                roundID: presentation.rounds[indexPath.item].id
            )
        )
    }
}
