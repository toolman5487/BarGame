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

    // MARK: - Metrics

    private enum Metrics {
        static let horizontalInset: CGFloat = 12
        static let verticalInset: CGFloat = 8
    }

    // MARK: - UI Elements

    private let glassView: UIVisualEffectView = {
        let view = UIVisualEffectView(
            effect: UIGlassEffect(style: .regular)
        )
        view.cornerConfiguration = .capsule()
        return view
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = ThemeColor.primary
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle

    fileprivate override init(frame: CGRect) {
        super.init(frame: frame)
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
                constant: Metrics.verticalInset
            ),
            textLabel.leadingAnchor.constraint(
                equalTo: glassView.contentView.leadingAnchor,
                constant: Metrics.horizontalInset
            ),
            textLabel.bottomAnchor.constraint(
                equalTo: glassView.contentView.bottomAnchor,
                constant: -Metrics.verticalInset
            ),
            textLabel.trailingAnchor.constraint(
                equalTo: glassView.contentView.trailingAnchor,
                constant: -Metrics.horizontalInset
            ),
        ])
    }
}

// MARK: - ViewFactory

@MainActor
enum ViewFactory {

    static func makeGlassLabel() -> GlassLabelView {
        GlassLabelView()
    }

    static func makeButton() -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.prominentGlass()
        configuration.baseBackgroundColor = .clear
        configuration.cornerStyle = .large
        configuration.titleAlignment = .center
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .preferredFont(forTextStyle: .subheadline)
            return outgoing
        }
        button.configuration = configuration
        button.isUserInteractionEnabled = false
        return button
    }
}
