//
//  MainTabBarViewModel.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/9.
//

import Combine
import Foundation

// MARK: - Input

struct MainTabBarViewModelInput {

    let viewDidLoad: AnyPublisher<Void, Never>
    let didSelectTab: AnyPublisher<MainTab, Never>
}

// MARK: - Output

struct MainTabBarViewModelOutput {

    let state: AnyPublisher<MainTabBarState, Never>
}

// MARK: - Protocol

@MainActor
protocol MainTabBarViewModeling: AnyObject {

    func transform(input: MainTabBarViewModelInput) -> MainTabBarViewModelOutput
}

// MARK: - ViewModel

@MainActor
final class MainTabBarViewModel: MainTabBarViewModeling {

    // MARK: - Properties

    private let configuration: MainTabBarConfiguration
    private let stateSubject = CurrentValueSubject<MainTabBarState, Never>(.idle)
    private var cancellables = Set<AnyCancellable>()

    private var state: MainTabBarState {
        stateSubject.value
    }

    // MARK: - Lifecycle

    init(configuration: MainTabBarConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Public

    func transform(input: MainTabBarViewModelInput) -> MainTabBarViewModelOutput {
        cancellables.removeAll()

        input.viewDidLoad
            .sink { [weak self] in
                self?.handleViewDidLoad()
            }
            .store(in: &cancellables)

        input.didSelectTab
            .sink { [weak self] tab in
                self?.handleSelectedTab(tab)
            }
            .store(in: &cancellables)

        return MainTabBarViewModelOutput(
            state: stateSubject
                .removeDuplicates()
                .eraseToAnyPublisher()
        )
    }

    // MARK: - Actions

    private func handleViewDidLoad() {
        switch state {
        case .idle:
            updateState(.ready(configuration.initialContent))

        case .ready:
            break
        }
    }

    private func handleSelectedTab(_ tab: MainTab) {
        switch state {
        case .idle:
            break

        case .ready(let content):
            guard content.selectedTab != tab else { return }
            guard content.items.contains(where: { $0.tab == tab }) else { return }

            updateState(
                .ready(
                    MainTabBarContent(
                        items: content.items,
                        selectedTab: tab
                    )
                )
            )
        }
    }

    // MARK: - State Updates

    private func updateState(_ updatedState: MainTabBarState) {
        guard state != updatedState else { return }
        stateSubject.send(updatedState)
    }
}
