//
//  MainTabBarController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/7.
//

import Combine
import UIKit

@MainActor
final class MainTabBarController: UITabBarController {

    // MARK: - Dependencies

    private let viewModel: any MainTabBarViewModeling
    private let screenBuilder: any AppScreenBuilding

    // MARK: - State

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let didSelectTabSubject = PassthroughSubject<MainTab, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var hasConfiguredTabs = false

    // MARK: - Lifecycle

    init(
        viewModel: any MainTabBarViewModeling,
        screenBuilder: any AppScreenBuilding
    ) {
        self.viewModel = viewModel
        self.screenBuilder = screenBuilder
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        delegate = self
        bind()
        viewDidLoadSubject.send()
    }

    // MARK: - Binding

    private func bind() {
        let input = MainTabBarViewModelInput(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            didSelectTab: didSelectTabSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.state
            .sink { [weak self] state in
                self?.apply(state)
            }
            .store(in: &cancellables)
    }

    // MARK: - State Updates

    private func apply(_ state: MainTabBarState) {
        switch state {
        case .idle:
            break

        case .ready(let content):
            applyReady(content)
        }
    }

    private func applyReady(_ content: MainTabBarContent) {
        if !hasConfiguredTabs {
            configureTabs(with: content.items)
            hasConfiguredTabs = true
        }

        selectTab(content.selectedTab, in: content.items)
    }

    private func selectTab(_ tab: MainTab, in items: [MainTabItem]) {
        guard let index = items.firstIndex(where: { $0.tab == tab }) else {
            return
        }
        selectedIndex = index
    }

    // MARK: - Setup

    private func configureAppearance() {
        tabBar.tintColor = ThemeColor.primary
    }
    private func configureTabs(with items: [MainTabItem]) {
        viewControllers = items.map { item in
            let rootViewController = makeRootViewController(for: item)
            rootViewController.tabBarItem = UITabBarItem(
                title: item.title,
                image: UIImage(systemName: item.imageSystemName),
                selectedImage: UIImage(systemName: item.selectedImageSystemName)
            )
            rootViewController.tabBarItem.tag = item.tab.rawValue
            rootViewController.tabBarItem.badgeColor = .systemRed

            let navigationController = UINavigationController(rootViewController: rootViewController)
            navigationController.tabBarItem = rootViewController.tabBarItem
            return navigationController
        }
    }

    private func makeRootViewController(for item: MainTabItem) -> UIViewController {
        screenBuilder.makeRootViewController(for: item)
    }
}

// MARK: - UITabBarControllerDelegate

extension MainTabBarController: UITabBarControllerDelegate {

    func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController
    ) {
        guard let tab = MainTab(rawValue: viewController.tabBarItem.tag) else {
            return
        }
        didSelectTabSubject.send(tab)
    }
}
