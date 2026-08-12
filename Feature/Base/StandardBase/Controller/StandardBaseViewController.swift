//
//  StandardBaseViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/8.
//

import UIKit

@MainActor
class StandardBaseViewController: RootBaseViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBaseView()
        setHierarchy()
        setLayout()
        setAppearance()
        setNavigation()
        bind()
    }

    // MARK: - Overridable

    func setHierarchy() {}

    func setLayout() {}

    func setAppearance() {}

    func setNavigation() {}

    func bind() {}
}

// MARK: - Private

private extension StandardBaseViewController {

    func configureBaseView() {
        view.backgroundColor = .systemBackground
    }
}
