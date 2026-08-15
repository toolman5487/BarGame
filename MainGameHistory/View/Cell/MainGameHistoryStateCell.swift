//
//  MainGameHistoryStateCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import SnapKit
import UIKit

@MainActor
final class MainGameHistoryStateCell: MainBaseCollectionViewCell {

    // MARK: - Callback

    var retryHandler: (() -> Void)?

    // MARK: - UI Elements

    private let hintView = BaseHintView()

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        retryHandler = nil
        isUserInteractionEnabled = false
    }

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(hintView)
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(handleRetryTap)
        )
        contentView.addGestureRecognizer(tapGesture)
    }

    override func setLayout() {
        hintView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(contentState: MainGameHistoryContentState) {
        switch contentState {
        case .idle, .loading:
            isUserInteractionEnabled = false
            hintView.isHidden = true

        case .empty(let reason):
            isUserInteractionEnabled = false
            hintView.isHidden = false
            hintView.symbolEffect = .wiggle(.repeating)
            hintView.configure(
                image: UIImage(systemName: "flag.pattern.checkered.2.crossed"),
                title: reason.title,
                subtitle: reason.message
            )

        case .failed(let failure):
            isUserInteractionEnabled = true
            hintView.isHidden = false
            hintView.symbolEffect = .pulse(.repeating)
            hintView.configure(
                image: UIImage(systemName: "exclamationmark.triangle"),
                title: failure.title,
                subtitle: failure.message
            )

        case .records:
            isUserInteractionEnabled = false
            hintView.isHidden = true
            hintView.symbolEffect = .none
            hintView.configure()
        }
    }

    // MARK: - Actions

    @objc
    private func handleRetryTap() {
        retryHandler?()
    }
}
