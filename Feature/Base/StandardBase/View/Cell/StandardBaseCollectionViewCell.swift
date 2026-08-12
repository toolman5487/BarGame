//
//  StandardBaseCollectionViewCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import SnapKit
import UIKit

@MainActor
class StandardBaseCollectionViewCell: UICollectionViewCell {

    // MARK: - Reuse

    static var reuseIdentifier: String {
        String(describing: Self.self)
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setHierarchy()
        setLayout()
        setAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    // MARK: - Overridable

    func setHierarchy() {}

    func setLayout() {}

    func setAppearance() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
}

// MARK: - UICollectionView Helpers

extension UICollectionView {

    func register(_ cellType: StandardBaseCollectionViewCell.Type) {
        register(cellType, forCellWithReuseIdentifier: cellType.reuseIdentifier)
    }

    func dequeueReusableCell<Cell: StandardBaseCollectionViewCell>(
        _ cellType: Cell.Type,
        for indexPath: IndexPath
    ) -> Cell {
        guard let cell = dequeueReusableCell(
            withReuseIdentifier: cellType.reuseIdentifier,
            for: indexPath
        ) as? Cell else {
            preconditionFailure("Unable to dequeue \(cellType.reuseIdentifier)")
        }
        return cell
    }
}
