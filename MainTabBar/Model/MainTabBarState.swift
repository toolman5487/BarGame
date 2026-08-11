//
//  MainTabBarState.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/9.
//

import Foundation

// MARK: - Tab

nonisolated enum MainTab: Int, CaseIterable, Sendable {

    case home = 0
    case pageA = 1
    case pageB = 2
    case pageC = 3
    
}

// MARK: - Item

nonisolated struct MainTabItem: Equatable, Sendable {

    let tab: MainTab
    let title: String
    let imageSystemName: String
    let selectedImageSystemName: String
}

// MARK: - Content

nonisolated struct MainTabBarContent: Equatable, Sendable {

    let items: [MainTabItem]
    let selectedTab: MainTab
}

// MARK: - Configuration

nonisolated struct MainTabBarConfiguration: Sendable {

    static let standard = MainTabBarConfiguration(
        items: [
            MainTabItem(
                tab: .home,
                title: "遊戲",
                imageSystemName: "dice",
                selectedImageSystemName: "dice.fill"
            ),
            MainTabItem(
                tab: .pageA,
                title: "頁面A",
                imageSystemName: "flag.2.crossed",
                selectedImageSystemName: "flag.pattern.checkered.2.crossed"
            ),
            MainTabItem(
                tab: .pageB,
                title: "首頁B",
                imageSystemName: "person",
                selectedImageSystemName: "person.fill"
            ),
            MainTabItem(
                tab: .pageC,
                title: "首頁C",
                imageSystemName: "gearshape",
                selectedImageSystemName: "gearshape.fill"
            ),
        ],
        selectedTab: .home
    )

    let items: [MainTabItem]
    let selectedTab: MainTab

    var initialContent: MainTabBarContent {
        MainTabBarContent(
            items: items,
            selectedTab: selectedTab
        )
    }
}

// MARK: - State

nonisolated enum MainTabBarState: Equatable, Sendable {

    case idle
    case ready(MainTabBarContent)
}
