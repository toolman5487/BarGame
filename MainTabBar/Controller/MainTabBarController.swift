//
//  MainTabBarController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/7.
//

import UIKit

@MainActor
final class MainTabBarController: UITabBarController {

    // MARK: - Types

    private enum Tab: Int, CaseIterable {

        case diceGame
        case placeholder

        var title: String {
            switch self {
            case .diceGame:
                return "骰子"
            case .placeholder:
                return "頁面"
            }
        }

        var imageName: String {
            switch self {
            case .diceGame:
                return "dice"
            case .placeholder:
                return "square.grid.2x2"
            }
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
    }

    // MARK: - Setup

    private func setupViewControllers() {
        viewControllers = Tab.allCases.map(makeViewController(for:))
    }

    private func makeViewController(for tab: Tab) -> UIViewController {
        let rootViewController: UIViewController

        switch tab {
        case .diceGame:
            rootViewController = DiceGameViewController()
        case .placeholder:
            rootViewController = ViewController()
        }

        rootViewController.title = tab.title
        rootViewController.tabBarItem = UITabBarItem(
            title: tab.title,
            image: UIImage(systemName: tab.imageName),
            tag: tab.rawValue
        )

        return UINavigationController(rootViewController: rootViewController)
    }
}
