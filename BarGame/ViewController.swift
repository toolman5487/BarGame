//
//  ViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/2.
//

import UIKit
import SnapKit

@MainActor
final class ViewController: UIViewController {

    // MARK: - Types

    private enum DiceViewMode {
        case perspective
        case topDown
    }

    private let diceView = GameDiceView()
    private let actionButton = UIButton(type: .system)
    private var diceViewMode: DiceViewMode = .perspective

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "骰子"
        view.backgroundColor = .systemBackground
        setupNavigationItems()
        setupDiceView()
        setupActionButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }

    override var canBecomeFirstResponder: Bool { true }

    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        diceView.shake()
    }

    private func setupDiceView() {
        view.addSubview(diceView)
        diceView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupNavigationItems() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addDice)
        )
    }

    private func setupActionButton() {
        updateActionButtonConfiguration()
        actionButton.addTarget(self, action: #selector(handleActionButtonTap), for: .touchUpInside)

        view.addSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(56)
        }
    }

    private func updateActionButtonConfiguration() {
        var configuration = UIButton.Configuration.glass()
        configuration.imagePadding = 8
        configuration.cornerStyle = .large
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updatedAttributes = attributes
            updatedAttributes.font = .preferredFont(forTextStyle: .headline)
            return updatedAttributes
        }

        switch diceViewMode {
        case .perspective:
            configuration.title = "確定"
            configuration.image = UIImage(systemName: "checkmark")

        case .topDown:
            configuration.title = "返回"
            configuration.image = UIImage(systemName: "arrow.backward")
        }

        actionButton.configuration = configuration
    }

    @objc
    private func addDice() {
        diceView.addDice()
    }

    @objc
    private func handleActionButtonTap() {
        switch diceViewMode {
        case .perspective:
            diceView.showTopDownView()
            diceViewMode = .topDown

        case .topDown:
            diceView.showPerspectiveView()
            diceViewMode = .perspective
        }

        updateActionButtonConfiguration()
    }
}
