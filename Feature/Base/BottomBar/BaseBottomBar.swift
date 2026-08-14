//
//  BaseBottomBar.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/14.
//

import SnapKit
import UIKit

@MainActor
class BaseBottomBar: UIView {

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

    var isEnabled: Bool {
        get { actionButton.isEnabled }
        set { actionButton.isEnabled = newValue }
    }

    var dividerColor: UIColor? {
        get { dividerView.backgroundColor }
        set { dividerView.backgroundColor = newValue }
    }

    // MARK: - UI Elements

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let actionButton: UIButton = {
        let button = ViewFactory.makeButton()
        button.isUserInteractionEnabled = true
        return button
    }()

    // MARK: - Lifecycle

    init(title: String) {
        super.init(frame: .zero)
        setActionTitle(title)
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
        addSubview(actionButton)
    }

    private func setupLayout() {
        dividerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(Metrics.dividerHeight)
        }

        actionButton.snp.makeConstraints { make in
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
        actionButton.addAction(
            UIAction { [weak self] _ in
                self?.tapHandler?()
            },
            for: .primaryActionTriggered
        )
    }

    final func setActionTitle(_ title: String) {
        var configuration = actionButton.configuration ?? .prominentGlass()
        configuration.title = title
        actionButton.configuration = configuration
    }
}
