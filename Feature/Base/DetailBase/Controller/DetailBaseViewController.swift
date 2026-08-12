//
//  DetailBaseViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import SnapKit
import UIKit

// MARK: - DetailCollectionLayoutConfiguring

@MainActor
protocol DetailCollectionLayoutConfiguring: AnyObject {

    var collectionViewHorizontalInset: CGFloat { get }
    var collectionViewSectionInset: UIEdgeInsets { get }

    func collectionViewItemSize(
        in collectionView: UICollectionView,
        at indexPath: IndexPath
    ) -> CGSize
}

extension DetailCollectionLayoutConfiguring {

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

// MARK: - DetailBaseViewController

@MainActor
class DetailBaseViewController: StandardBaseViewController, DetailCollectionLayoutConfiguring {

    // MARK: - Properties

    private let titleText: String

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

    // MARK: - UI Elements

    private(set) lazy var contentView = DetailBaseView()

    var collectionView: UICollectionView {
        contentView.collectionView
    }

    // MARK: - Lifecycle

    init(title: String) {
        titleText = title
        super.init()
    }

    // MARK: - Overridable

    override func setHierarchy() {
        view.addSubview(contentView)
        collectionView.delegate = self
    }

    override func setLayout() {
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func setNavigation() {
        navigationItem.largeTitleDisplayMode = .never
        title = titleText
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

    func collectionViewHeaderSize(
        in collectionView: UICollectionView,
        section: Int
    ) -> CGSize {
        .zero
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension DetailBaseViewController: UICollectionViewDelegateFlowLayout {

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
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        collectionViewHeaderSize(in: collectionView, section: section)
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
