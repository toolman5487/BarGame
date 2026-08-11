//
//  PlaceholderCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/11.
//

import Foundation
import SnapKit
import UIKit

@MainActor
final class PlaceholderCell: UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .tertiarySystemGroupedBackground
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
