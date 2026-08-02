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

    private let diceView = GameDiceView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "骰子"
        view.backgroundColor = .systemBackground
        setupDiceView()
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
}
