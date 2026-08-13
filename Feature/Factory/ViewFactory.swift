//
//  ViewFactory.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/11.
//

import Foundation
import UIKit

// MARK: - GlassLabelView

@MainActor
final class GlassLabelView: UIView {

    // MARK: - UI Elements

    private let glassView: UIVisualEffectView = {
        let view = UIVisualEffectView(
            effect: UIGlassEffect(style: .regular)
        )
        view.cornerConfiguration = .capsule()
        return view
    }()

    private let textLabel = UILabel()

    // MARK: - Properties

    private let contentInsets: NSDirectionalEdgeInsets

    // MARK: - Lifecycle

    fileprivate init(
        font: UIFont,
        textColor: UIColor,
        textAlignment: NSTextAlignment,
        numberOfLines: Int,
        contentInsets: NSDirectionalEdgeInsets
    ) {
        self.contentInsets = contentInsets
        super.init(frame: .zero)
        textLabel.font = font
        textLabel.textColor = textColor
        textLabel.textAlignment = textAlignment
        textLabel.numberOfLines = numberOfLines
        textLabel.lineBreakMode = numberOfLines == 1
            ? .byTruncatingTail
            : .byWordWrapping
        isUserInteractionEnabled = false
        setupHierarchy()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(text: String?) {
        textLabel.text = text
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(glassView)
        glassView.contentView.addSubview(textLabel)
    }

    private func setupLayout() {
        glassView.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textLabel.topAnchor.constraint(
                equalTo: glassView.contentView.topAnchor,
                constant: contentInsets.top
            ),
            textLabel.leadingAnchor.constraint(
                equalTo: glassView.contentView.leadingAnchor,
                constant: contentInsets.leading
            ),
            textLabel.bottomAnchor.constraint(
                equalTo: glassView.contentView.bottomAnchor,
                constant: -contentInsets.bottom
            ),
            textLabel.trailingAnchor.constraint(
                equalTo: glassView.contentView.trailingAnchor,
                constant: -contentInsets.trailing
            ),
        ])
    }
}

// MARK: - ViewFactory

@MainActor
enum ViewFactory {

    static func makeGlassLabel(
        textStyle: UIFont.TextStyle = .body,
        textColor: UIColor = ThemeColor.primary,
        textAlignment: NSTextAlignment = .natural,
        numberOfLines: Int = 0,
        contentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 12,
            bottom: 8,
            trailing: 12
        )
    ) -> GlassLabelView {
        makeGlassLabel(
            font: .preferredFont(forTextStyle: textStyle),
            textColor: textColor,
            textAlignment: textAlignment,
            numberOfLines: numberOfLines,
            contentInsets: contentInsets
        )
    }

    static func makeGlassLabel(
        font: UIFont,
        textColor: UIColor = ThemeColor.primary,
        textAlignment: NSTextAlignment = .natural,
        numberOfLines: Int = 0,
        contentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 12,
            bottom: 8,
            trailing: 12
        )
    ) -> GlassLabelView {
        GlassLabelView(
            font: font,
            textColor: textColor,
            textAlignment: textAlignment,
            numberOfLines: numberOfLines,
            contentInsets: contentInsets
        )
    }

    static func makeButton() -> UIButton {
        let button = UIButton(type: .system)
        button.configuration = makeButtonConfiguration()
        button.isUserInteractionEnabled = false
        return button
    }

    static func makeIconButton(systemName: String) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = makeButtonConfiguration()
        configuration.image = UIImage(systemName: systemName)
        configuration.contentInsets = .zero
        configuration.cornerStyle = .capsule
        button.configuration = configuration
        return button
    }

    private static func makeButtonConfiguration() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.prominentGlass()
        configuration.baseBackgroundColor = .clear
        configuration.cornerStyle = .large
        configuration.titleAlignment = .center
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .preferredFont(forTextStyle: .subheadline)
            return outgoing
        }
        return configuration
    }
}
