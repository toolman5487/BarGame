//
//  MainHomeGameResultsCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/11.
//

import SnapKit
import UIKit

@MainActor
final class MainHomeGameResultsCell: MainBaseCollectionViewCell {

    // MARK: - Layout

    enum Layout {
        static let preferredHeight = BaseHintView.Layout.preferredHeight
    }

    // MARK: - UI Elements

    private let emptyView = MainHomeResultEmptyView()

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(emptyView)
    }

    override func setLayout() {
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .systemBackground
    }
}

// MARK: - MainHomeResultEmptyView

@MainActor
final class MainHomeResultEmptyView: BaseHintView {

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyDefaultContent()
    }

    // MARK: - Private

    private func applyDefaultContent() {
        symbolEffect = .wiggle(.repeating)
        configure(
            image: UIImage(systemName: "flag.pattern.checkered.2.crossed"),
            title: "尚無戰績",
            subtitle: "完成一場遊戲吧!"
        )
    }
}
