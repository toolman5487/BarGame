//
//  MainBaseViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/8.
//

import SnapKit
import UIKit

// MARK: - MainCollectionLayoutConfiguring

@MainActor
protocol MainCollectionLayoutConfiguring: AnyObject {

    var collectionViewHorizontalInset: CGFloat { get }
    var collectionViewSectionInset: UIEdgeInsets { get }

    func collectionViewItemSize(
        in collectionView: UICollectionView,
        at indexPath: IndexPath
    ) -> CGSize
}

extension MainCollectionLayoutConfiguring {

    var collectionViewHorizontalInset: CGFloat {
        16
    }

    var collectionViewSectionInset: UIEdgeInsets {
        UIEdgeInsets(
            top: 0,
            left: collectionViewHorizontalInset,
            bottom: 0,
            right: collectionViewHorizontalInset
        )
    }

    func collectionViewItemSize(
        in collectionView: UICollectionView,
        at indexPath: IndexPath
    ) -> CGSize {
        let inset = collectionViewSectionInset
        let width = max(
            0,
            collectionView.bounds.width - inset.left - inset.right
        )
        return CGSize(width: width, height: 56)
    }
}

// MARK: - MainBaseViewController

@MainActor
class MainBaseViewController: StandardBaseViewController, MainCollectionLayoutConfiguring {

    // MARK: - UI Elements

    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeCollectionViewLayout()
        )
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .automatic
        collectionView.delegate = self
        return collectionView
    }()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    // MARK: - Overridable

    override func setHierarchy() {
        view.addSubview(collectionView)
    }

    override func setLayout() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func setNavigation() {
        navigationItem.largeTitleDisplayMode = .always
    }

    func makeCollectionViewLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = collectionViewSectionInset
        return layout
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainBaseViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionViewItemSize(in: collectionView, at: indexPath)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        collectionViewSectionInset
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        0
    }
}
