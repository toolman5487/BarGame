//
//  PlaceholderCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/11.
//

import UIKit

@MainActor
final class PlaceholderCell: UICollectionViewCell {

    // MARK: - Layout

    private enum Layout {
        static let cornerRadiusRatio: CGFloat = 0.12
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .tertiarySystemGroupedBackground
        contentView.clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = contentView.bounds.height * Layout.cornerRadiusRatio
    }
}
