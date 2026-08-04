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
    private let lockButton = UIButton(type: .system)
    private var diceViewMode: DiceViewMode = .perspective
    private var isDiceLocked = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "骰子"
        view.backgroundColor = .systemBackground
        setupNavigationItems()
        setupDiceView()
        setupControlButtons()
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
        guard motion == .motionShake, !isDiceLocked else { return }
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

    private func setupControlButtons() {
        updateActionButtonConfiguration()
        actionButton.addTarget(self, action: #selector(handleActionButtonTap), for: .touchUpInside)
        updateLockButtonConfiguration()
        lockButton.addTarget(self, action: #selector(handleLockButtonTap), for: .touchUpInside)

        view.addSubview(actionButton)
        view.addSubview(lockButton)

        actionButton.snp.makeConstraints { make in
            make.leading.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.size.equalTo(56)
        }

        lockButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.size.equalTo(56)
        }
    }

    private func updateActionButtonConfiguration() {
        var configuration = UIButton.Configuration.glass()
        configuration.cornerStyle = .capsule

        switch diceViewMode {
        case .perspective:
            configuration.image = UIImage(systemName: "checkmark")
            actionButton.accessibilityLabel = "確認結果"

        case .topDown:
            configuration.image = UIImage(systemName: "arrow.backward")
            actionButton.accessibilityLabel = "返回擲骰"
        }

        actionButton.configuration = configuration
    }

    private func updateLockButtonConfiguration() {
        var configuration = UIButton.Configuration.glass()
        configuration.cornerStyle = .capsule
        configuration.image = UIImage(systemName: isDiceLocked ? "lock.fill" : "lock.open")
        configuration.baseForegroundColor = isDiceLocked ? .systemOrange : .label

        lockButton.configuration = configuration
        lockButton.isEnabled = diceViewMode == .perspective
        lockButton.accessibilityLabel = lockButton.isEnabled
            ? (isDiceLocked ? "解鎖骰子" : "鎖定骰子")
            : "骰子已鎖定"
        lockButton.accessibilityValue = isDiceLocked ? "已鎖定" : "未鎖定"
    }

    private func setDiceLocked(_ isLocked: Bool) {
        isDiceLocked = isLocked
        diceView.setInteractionLocked(isLocked)
        navigationItem.rightBarButtonItem?.isEnabled = !isLocked
        updateLockButtonConfiguration()
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
            setDiceLocked(true)

        case .topDown:
            diceView.showPerspectiveView()
            diceViewMode = .perspective
            setDiceLocked(false)
        }

        updateActionButtonConfiguration()
    }

    @objc
    private func handleLockButtonTap() {
        guard diceViewMode == .perspective else { return }
        setDiceLocked(!isDiceLocked)
    }
}
