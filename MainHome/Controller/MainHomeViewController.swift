//
//  MainHomeViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/8.
//

import Combine
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

    // MARK: - State

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let shakeMotionSubject = PassthroughSubject<Void, Never>()
    private let didRequestRetrySubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var renderedContent: MainHomeContent?
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
        viewModel: any MainHomeViewModeling
    ) {
        self.viewModel = viewModel
        super.init(title: title)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadSubject.send()
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

        switch item(at: indexPath) {
        case .dicePreview:
            return CGSize(width: width, height: width * Metrics.dicePreviewAspectRatio)
        case .gameList:
            let height = MainHomeGameListCell.preferredHeight(
                forWidth: width,
                itemCount: renderedContent?.games.count ?? 0
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
        guard let renderedContent,
              renderedContent.sections.indices.contains(section)
        else { return .zero }

        let title = renderedContent.sections[section].headerTitle
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

    @objc
    private func handleErrorViewTap() {
        guard currentFailure?.isRetryable == true else { return }
        didRequestRetrySubject.send()
    }

    // MARK: - Private

    private func item(at indexPath: IndexPath) -> MainHomeItem {
        guard let renderedContent else {
            preconditionFailure("MainHome content must be ready before requesting items")
        }
        return renderedContent.sections[indexPath.section].items[indexPath.item]
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
            renderedContent = nil
            currentFailure = nil
            collectionView.isHidden = true
            errorView.isHidden = true
            loadingIndicator.stopAnimating()
            collectionView.reloadData()

        case .loading:
            renderedContent = nil
            currentFailure = nil
            collectionView.isHidden = true
            errorView.isHidden = true
            loadingIndicator.startAnimating()
            collectionView.reloadData()

        case .ready(let content):
            renderedContent = content
            currentFailure = nil
            collectionView.isHidden = false
            errorView.isHidden = true
            loadingIndicator.stopAnimating()
            collectionView.reloadData()
            collectionView.collectionViewLayout.invalidateLayout()

        case .failed(let failure):
            renderedContent = nil
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
        renderedContent?.sections.count ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        renderedContent?.sections[section].items.count ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch item(at: indexPath) {
        case .dicePreview:
            return collectionView.dequeueReusableCell(
                MainHomeDiceCollectionViewCell.self,
                for: indexPath
            )
        case .gameList:
            let cell = collectionView.dequeueReusableCell(
                MainHomeGameListCell.self,
                for: indexPath
            )
            cell.configure(games: renderedContent?.games ?? [])
            return cell
        case .gameResults:
            let cell = collectionView.dequeueReusableCell(
                MainHomeGameResultsCell.self,
                for: indexPath
            )
            cell.configure(results: renderedContent?.results ?? [])
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
            title: renderedContent?.sections[indexPath.section].headerTitle ?? ""
        )
        return header
    }
}

// MARK: - Composition

extension MainHomeViewController {

    convenience init(
        title: String,
        configuration: MainHomeConfiguration = .standard
    ) {
        let viewModel = MainHomeViewModel(configuration: configuration)
        self.init(title: title, viewModel: viewModel)
    }
}
