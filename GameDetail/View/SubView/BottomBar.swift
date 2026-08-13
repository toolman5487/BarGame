//
//  BottomBar.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/13.
//

import SnapKit
import UIKit

@MainActor
final class BottomBar: UIView {

    // MARK: - Metrics

    private enum Metrics {
        static let verticalInset: CGFloat = 12
        static let horizontalInset: CGFloat = 16
        static let buttonHeight: CGFloat = 56
        static let dividerHeight: CGFloat = 0.5
    }

    static let contentHeight = Metrics.verticalInset * 2 + Metrics.buttonHeight

    // MARK: - Callback

    var tapHandler: (() -> Void)?

    // MARK: - UI Elements

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let startButton: UIButton = {
        let button = ViewFactory.makeButton()
        button.isUserInteractionEnabled = true
        return button
    }()

    // MARK: - Lifecycle

    init(title: String) {
        super.init(frame: .zero)
        configureButton(title: title)
        setupHierarchy()
        setupLayout()
        setupAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(dividerView)
        addSubview(startButton)
    }

    private func setupLayout() {
        dividerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(Metrics.dividerHeight)
        }

        startButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Metrics.verticalInset)
            make.left.right
                .equalTo(safeAreaLayoutGuide)
                .inset(Metrics.horizontalInset)
            make.height.equalTo(Metrics.buttonHeight)
            make.bottom
                .equalTo(safeAreaLayoutGuide)
                .inset(Metrics.verticalInset)
        }
    }

    private func setupAppearance() {
        backgroundColor = .systemBackground
        startButton.addAction(
            UIAction { [weak self] _ in
                self?.tapHandler?()
            },
            for: .primaryActionTriggered
        )
    }

    private func configureButton(title: String) {
        var configuration = startButton.configuration ?? .prominentGlass()
        configuration.title = title
        startButton.configuration = configuration
    }
}
