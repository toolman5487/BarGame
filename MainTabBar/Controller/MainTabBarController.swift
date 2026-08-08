//
//  MainTabBarController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/7.
//

import UIKit

@MainActor
final class MainTabBarController: UITabBarController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
    }

    // MARK: - Setup

    private func setupViewControllers() {
        let mainHomeViewController = MainHomeViewController()
        mainHomeViewController.title = "首頁"
        mainHomeViewController.tabBarItem = UITabBarItem(
            title: "首頁",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        mainHomeViewController.tabBarItem.tag = 0
        mainHomeViewController.tabBarItem.badgeColor = .systemRed

        let viewController = ViewController()
        viewController.title = "頁面"
        viewController.tabBarItem = UITabBarItem(
            title: "頁面",
            image: UIImage(systemName: "square.grid.2x2"),
            selectedImage: UIImage(systemName: "square.grid.2x2.fill")
        )
        viewController.tabBarItem.tag = 1
        viewController.tabBarItem.badgeColor = .systemRed

        viewControllers = [
            UINavigationController(rootViewController: mainHomeViewController),
            UINavigationController(rootViewController: viewController),
        ]
    }
}
