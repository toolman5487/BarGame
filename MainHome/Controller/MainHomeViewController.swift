//
//  MainHomeViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/8.
//

import UIKit

@MainActor
final class MainHomeViewController: MainBaseViewController {

    // MARK: - Types

    private enum Layout {
        static let dicePreviewAspectRatio: CGFloat = 1.2
    }

    // MARK: - State

    private let sections = MainHomeSection.standard
    private let gameListItemCount = MainHomeGameListCell.Layout.defaultItemCount

    override var collectionViewSectionInset: UIEdgeInsets {
        .zero
    }

    // MARK: - Lifecycle

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
        shakeVisibleDice()
    }

    // MARK: - Overridable

    override func setHierarchy() {
        super.setHierarchy()
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(MainHomeDiceCollectionViewCell.self)
        collectionView.register(MainHomeGameListCell.self)
        collectionView.register(MainHomeTitleHeader.self)
        collectionView.dataSource = self
    }

    override func setLayout() {
        super.setLayout()
        updateCollectionViewEdgeInsets()
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
            return CGSize(width: width, height: width * Layout.dicePreviewAspectRatio)
        case .gameList:
            let height = MainHomeGameListCell.preferredHeight(
                forWidth: width,
                itemCount: gameListItemCount
            )
            return CGSize(width: width, height: height)
        }
    }

    override func collectionViewHeaderSize(
        in collectionView: UICollectionView,
        section: Int
    ) -> CGSize {
        let title = sections[section].headerTitle
        guard !title.isEmpty else {
            return .zero
        }
        return CGSize(
            width: collectionView.bounds.width,
            height: MainBaseTitleHeader.Layout.preferredHeight
        )
    }

    // MARK: - Actions

    private func shakeVisibleDice() {
        collectionView.visibleCells
            .compactMap { $0 as? MainHomeDiceCollectionViewCell }
            .forEach { $0.shakeDice() }
    }

    // MARK: - Private

    private func item(at indexPath: IndexPath) -> MainHomeItem {
        sections[indexPath.section].items[indexPath.item]
    }

    private func updateCollectionViewEdgeInsets() {
        let bottom = view.safeAreaInsets.bottom
        let edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
        collectionView.contentInset = edgeInsets
        collectionView.scrollIndicatorInsets = edgeInsets
        collectionView.verticalScrollIndicatorInsets = edgeInsets
    }
}

// MARK: - UICollectionViewDataSource

extension MainHomeViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        sections[section].items.count
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
            cell.configure(itemCount: gameListItemCount)
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
        header.configure(title: sections[indexPath.section].headerTitle)
        return header
    }
}
