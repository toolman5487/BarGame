//
//  MainHomeViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/8.
//

import Combine
import OSLog
import SnapKit
import UIKit

@MainActor
final class MainHomeViewController: MainBaseViewController {

    // MARK: - Types

    private enum Metrics {
        static let dicePreviewAspectRatio: CGFloat = 1.2
    }

    // MARK: - Dependencies

    private let viewModel: any MainHomeViewModeling
    private let screenBuilder: any AppScreenBuilding
    private lazy var router: any MainHomeRouting = MainHomeRouter(
        sourceViewController: self,
        screenBuilder: screenBuilder
    )

    // MARK: - State

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let viewWillAppearSubject = PassthroughSubject<Void, Never>()
    private let shakeMotionSubject = PassthroughSubject<Void, Never>()
    private let didRequestRetrySubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var renderedSnapshot: MainHomeSnapshot?
    private var currentFailure: MainHomeFailure?

    // MARK: - UI Elements

    private let errorView = ErrorView()
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override var collectionViewSectionInset: UIEdgeInsets {
        .zero
    }

    // MARK: - Lifecycle

    init(
        title: String,
        viewModel: any MainHomeViewModeling,
        screenBuilder: any AppScreenBuilding
    ) {
        self.viewModel = viewModel
        self.screenBuilder = screenBuilder
        super.init(title: title)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadSubject.send()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearSubject.send()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateCollectionViewEdgeInsets()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - UIResponder

    override var canBecomeFirstResponder: Bool { true }

    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        shakeMotionSubject.send()
    }

    // MARK: - Overridable

    override func setHierarchy() {
        super.setHierarchy()
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(MainHomeDiceCollectionViewCell.self)
        collectionView.register(MainHomeTitleHeader.self)
        collectionView.register(MainHomeGameResultsCell.self)
        collectionView.register(MainHomeGameListCell.self)
        collectionView.dataSource = self

        view.addSubview(errorView)
        view.addSubview(loadingIndicator)
        errorView.isHidden = true
        configureErrorViewRetry()
    }

    override func setLayout() {
        super.setLayout()
        updateCollectionViewEdgeInsets()

        errorView.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalTo(view.safeAreaLayoutGuide).inset(24)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func collectionViewItemSize(
        in collectionView: UICollectionView,
        at indexPath: IndexPath
    ) -> CGSize {
        let inset = collectionViewSectionInset
        let width = max(
            0,
            collectionView.bounds.width - inset.left - inset.right
        )

        switch section(at: indexPath.section) {
        case .dicePreview:
            return CGSize(width: width, height: width * Metrics.dicePreviewAspectRatio)
        case .gameList(let games):
            let height = MainHomeGameListCell.preferredHeight(
                forWidth: width,
                itemCount: games.count
            )
            return CGSize(width: width, height: height)
        case .gameResults:
            return CGSize(width: width, height: MainHomeGameResultsCell.Metrics.preferredHeight)
        }
    }

    override func collectionViewHeaderSize(
        in collectionView: UICollectionView,
        section: Int
    ) -> CGSize {
        guard let renderedSnapshot,
              renderedSnapshot.sections.indices.contains(section)
        else { return .zero }

        let title = renderedSnapshot.sections[section].headerTitle
        guard !title.isEmpty else {
            return .zero
        }
        return CGSize(
            width: collectionView.bounds.width,
            height: MainBaseTitleHeader.Metrics.preferredHeight
        )
    }

    override func bind() {
        let input = MainHomeViewModelInput(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            viewWillAppear: viewWillAppearSubject.eraseToAnyPublisher(),
            shakeMotion: shakeMotionSubject.eraseToAnyPublisher(),
            didRequestRetry: didRequestRetrySubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .sink { [weak self] state in
                self?.apply(state)
            }
            .store(in: &cancellables)

        output.command
            .sink { [weak self] command in
                self?.execute(command)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    private func shakeVisibleDice() {
        collectionView.visibleCells
            .compactMap { $0 as? MainHomeDiceCollectionViewCell }
            .forEach { $0.shakeDice() }
    }

    private func handleGameResultTap(_ result: GameOverview) {
        AppLogger.domain.debug(
            "Selected game result: \(result.id.rawValue, privacy: .public)"
        )
    }

    @objc
    private func handleErrorViewTap() {
        guard currentFailure?.isRetryable == true else { return }
        didRequestRetrySubject.send()
    }

    // MARK: - Private

    private func section(at index: Int) -> MainHomeSection {
        guard let renderedSnapshot else {
            preconditionFailure("MainHome snapshot must be ready before requesting sections")
        }
        return renderedSnapshot.sections[index]
    }

    private func configureErrorViewRetry() {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(handleErrorViewTap)
        )
        errorView.addGestureRecognizer(tap)
        errorView.isUserInteractionEnabled = true
    }

    private func updateCollectionViewEdgeInsets() {
        let bottom = view.safeAreaInsets.bottom
        let edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
        collectionView.contentInset = edgeInsets
        collectionView.scrollIndicatorInsets = edgeInsets
        collectionView.verticalScrollIndicatorInsets = edgeInsets
    }

    // MARK: - State Updates

    private func apply(_ state: MainHomeState) {
        switch state {
        case .idle:
            renderedSnapshot = nil
            currentFailure = nil
            collectionView.isHidden = true
            errorView.isHidden = true
            loadingIndicator.stopAnimating()
            collectionView.reloadData()

        case .loading:
            renderedSnapshot = nil
            currentFailure = nil
            collectionView.isHidden = true
            errorView.isHidden = true
            loadingIndicator.startAnimating()
            collectionView.reloadData()

        case .ready(let snapshot):
            renderedSnapshot = snapshot
            currentFailure = nil
            collectionView.isHidden = false
            errorView.isHidden = true
            loadingIndicator.stopAnimating()
            collectionView.reloadData()
            collectionView.collectionViewLayout.invalidateLayout()

        case .failed(let failure):
            renderedSnapshot = nil
            currentFailure = failure
            collectionView.isHidden = true
            errorView.isHidden = false
            loadingIndicator.stopAnimating()
            errorView.configure(message: failure.message, title: failure.title)
            collectionView.reloadData()
        }
    }

    private func execute(_ command: MainHomeViewCommand) {
        switch command {
        case .shakeDice:
            shakeVisibleDice()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension MainHomeViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        renderedSnapshot?.sections.count ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        renderedSnapshot == nil ? 0 : 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch section(at: indexPath.section) {
        case .dicePreview:
            return collectionView.dequeueReusableCell(
                MainHomeDiceCollectionViewCell.self,
                for: indexPath
            )
        case .gameList(let games):
            let cell = collectionView.dequeueReusableCell(
                MainHomeGameListCell.self,
                for: indexPath
            )
            cell.configure(games: games)
            cell.gameTapHandler = { [weak self] game in
                self?.router.route(to: .game(game))
            }
            return cell
        case .gameResults(let results):
            let cell = collectionView.dequeueReusableCell(
                MainHomeGameResultsCell.self,
                for: indexPath
            )
            cell.configure(results: results)
            cell.tapHandler = { [weak self] result in
                self?.handleGameResultTap(result)
            }
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == MainHomeTitleHeader.elementKind else {
            return UICollectionReusableView()
        }

        let header = collectionView.dequeueReusableHeader(
            MainHomeTitleHeader.self,
            for: indexPath
        )
        header.configure(
            title: renderedSnapshot?.sections[indexPath.section].headerTitle ?? ""
        )
        return header
    }
}
