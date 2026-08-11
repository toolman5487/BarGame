//
//  ErrorView.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/11.
//

import UIKit

@MainActor
final class ErrorView: BaseHintView {

    // MARK: - Types

    enum Content {
        static let defaultTitle = "發生錯誤"
        static let defaultSubtitle = "請稍後再試"
        static let defaultImageSystemName = "exclamationmark.triangle.fill"
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyDefaultContent()
    }

    // MARK: - Configuration

    func configure(message: String, title: String = Content.defaultTitle) {
        configure(
            image: UIImage(systemName: Content.defaultImageSystemName),
            title: title,
            subtitle: message
        )
    }

    func configure(error: Error, title: String = Content.defaultTitle) {
        configure(message: error.localizedDescription, title: title)
    }

    // MARK: - Private

    private func applyDefaultContent() {
        symbolEffect = .wiggle(.once)
        imageView.tintColor = .systemRed
        configure(
            image: UIImage(systemName: Content.defaultImageSystemName),
            title: Content.defaultTitle,
            subtitle: Content.defaultSubtitle
        )
    }
}
