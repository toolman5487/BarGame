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

    private let items = MainHomeItem.allCases

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

        switch items[indexPath.item] {
        case .dicePreview:
            return CGSize(width: width, height: width * Layout.dicePreviewAspectRatio)
        }
    }

    // MARK: - Actions

    private func shakeVisibleDice() {
        collectionView.visibleCells
            .compactMap { $0 as? MainHomeDiceCollectionViewCell }
            .forEach { $0.shakeDice() }
    }

    // MARK: - Private

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

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch items[indexPath.item] {
        case .dicePreview:
            return collectionView.dequeueReusableCell(
                MainHomeDiceCollectionViewCell.self,
                for: indexPath
            )
        }
    }
}
