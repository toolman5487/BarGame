//
//  RoundDetailStateCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import SnapKit
import UIKit

@MainActor
final class RoundDetailStateCell: DetailBaseCollectionViewCell {

    var retryHandler: (() -> Void)?

    private let hintView = BaseHintView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func setHierarchy() {
        contentView.addSubview(hintView)
        contentView.addSubview(activityIndicator)
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
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        retryHandler = nil
        activityIndicator.stopAnimating()
        hintView.isHidden = true
        isUserInteractionEnabled = false
    }

    func configure(state: RoundDetailViewState) {
        switch state {
        case .idle, .loading:
            isUserInteractionEnabled = false
            hintView.isHidden = true
            activityIndicator.startAnimating()

        case .content:
            isUserInteractionEnabled = false
            hintView.isHidden = true
            activityIndicator.stopAnimating()

        case .failed(let failure):
            isUserInteractionEnabled = failure.canRetry
            activityIndicator.stopAnimating()
            hintView.isHidden = false
            hintView.symbolEffect = .pulse(.repeating)
            hintView.configure(
                image: UIImage(systemName: "exclamationmark.triangle"),
                title: failure.title,
                subtitle: failure.message
            )
        }
    }

    @objc
    private func handleRetryTap() {
        retryHandler?()
    }
}
