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
        setupTabBarAppearance()
        setupViewControllers()
    }

    // MARK: - Setup

    private func setupTabBarAppearance() {
        let appearance = makeTabBarAppearance()

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .label
        tabBar.unselectedItemTintColor = .secondaryLabel
        tabBar.backgroundColor = .systemBackground
        tabBar.isTranslucent = true
        tabBar.barStyle = .default
        tabBar.itemPositioning = .automatic
        tabBar.itemSpacing = 0
        tabBar.itemWidth = 0
        tabBar.selectionIndicatorImage = nil
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()
        tabBar.clipsToBounds = false
        tabBar.layer.masksToBounds = false
    }

    private func makeTabBarAppearance() -> UITabBarAppearance {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .systemBackground
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        appearance.shadowColor = .separator
        appearance.shadowImage = UIImage()

        configureItemAppearance(
            appearance.stackedLayoutAppearance,
            normalColor: .secondaryLabel,
            selectedColor: .label
        )
        configureItemAppearance(
            appearance.inlineLayoutAppearance,
            normalColor: .secondaryLabel,
            selectedColor: .label
        )
        configureItemAppearance(
            appearance.compactInlineLayoutAppearance,
            normalColor: .secondaryLabel,
            selectedColor: .label
        )

        return appearance
    }

    private func configureItemAppearance(
        _ itemAppearance: UITabBarItemAppearance,
        normalColor: UIColor,
        selectedColor: UIColor
    ) {
        let normalFont = UIFont.preferredFont(forTextStyle: .caption2)
        let selectedFont = UIFont.preferredFont(forTextStyle: .caption2)

        itemAppearance.normal.iconColor = normalColor
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor,
            .font: normalFont,
        ]
        itemAppearance.normal.badgeBackgroundColor = .systemRed
        itemAppearance.normal.badgeTextAttributes = [
            .foregroundColor: UIColor.white,
        ]
        itemAppearance.normal.badgePositionAdjustment = UIOffset(horizontal: 0, vertical: 0)

        itemAppearance.selected.iconColor = selectedColor
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: selectedFont,
        ]
        itemAppearance.selected.badgeBackgroundColor = .systemRed
        itemAppearance.selected.badgeTextAttributes = [
            .foregroundColor: UIColor.white,
        ]
        itemAppearance.selected.badgePositionAdjustment = UIOffset(horizontal: 0, vertical: 0)

        itemAppearance.disabled.iconColor = .tertiaryLabel
        itemAppearance.disabled.titleTextAttributes = [
            .foregroundColor: UIColor.tertiaryLabel,
            .font: normalFont,
        ]
        itemAppearance.disabled.badgeBackgroundColor = .systemRed
        itemAppearance.disabled.badgeTextAttributes = [
            .foregroundColor: UIColor.white,
        ]
        itemAppearance.disabled.badgePositionAdjustment = UIOffset(horizontal: 0, vertical: 0)

        itemAppearance.focused.iconColor = selectedColor
        itemAppearance.focused.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: selectedFont,
        ]
        itemAppearance.focused.badgeBackgroundColor = .systemRed
        itemAppearance.focused.badgeTextAttributes = [
            .foregroundColor: UIColor.white,
        ]
        itemAppearance.focused.badgePositionAdjustment = UIOffset(horizontal: 0, vertical: 0)
    }

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
