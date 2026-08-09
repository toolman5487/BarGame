//
//  MainHomeViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/8.
//

import UIKit

@MainActor
final class MainHomeViewController: MainBaseViewController {

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

    // MARK: - UIResponder

    override var canBecomeFirstResponder: Bool { true }

    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        shakeVisibleDice()
    }

    // MARK: - Overridable

    override func setHierarchy() {
        super.setHierarchy()
        collectionView.register(MainHomeDiceCollectionViewCell.self)
        collectionView.dataSource = self
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
            return CGSize(width: width, height: width * 2 / 3)
        }
    }

    // MARK: - Actions

    private func shakeVisibleDice() {
        collectionView.visibleCells
            .compactMap { $0 as? MainHomeDiceCollectionViewCell }
            .forEach { $0.shakeDice() }
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
