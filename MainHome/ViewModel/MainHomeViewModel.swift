//
//  MainHomeViewModel.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/11.
//

import Combine
import Foundation

// MARK: - Input

struct MainHomeViewModelInput {

    let viewDidLoad: AnyPublisher<Void, Never>
    let shakeMotion: AnyPublisher<Void, Never>
}

// MARK: - Output

struct MainHomeViewModelOutput {

    let state: AnyPublisher<MainHomeState, Never>
    let command: AnyPublisher<MainHomeViewCommand, Never>
}

// MARK: - Command

enum MainHomeViewCommand {

    case shakeDice
}

// MARK: - Protocol

@MainActor
protocol MainHomeViewModeling: AnyObject {

    func transform(input: MainHomeViewModelInput) -> MainHomeViewModelOutput
}

// MARK: - ViewModel

@MainActor
final class MainHomeViewModel: MainHomeViewModeling {

    // MARK: - Dependencies

    private let configuration: MainHomeConfiguration

    // MARK: - State

    private let stateSubject = CurrentValueSubject<MainHomeState, Never>(.idle)
    private let commandSubject = PassthroughSubject<MainHomeViewCommand, Never>()
    private var cancellables = Set<AnyCancellable>()

    private var state: MainHomeState {
        stateSubject.value
    }

    // MARK: - Lifecycle

    init(configuration: MainHomeConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Public

    func transform(input: MainHomeViewModelInput) -> MainHomeViewModelOutput {
        cancellables.removeAll()

        input.viewDidLoad
            .sink { [weak self] in
                self?.handleViewDidLoad()
            }
            .store(in: &cancellables)

        input.shakeMotion
            .sink { [weak self] in
                self?.handleShakeMotion()
            }
            .store(in: &cancellables)

        return MainHomeViewModelOutput(
            state: stateSubject
                .removeDuplicates()
                .eraseToAnyPublisher(),
            command: commandSubject.eraseToAnyPublisher()
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

    private func handleShakeMotion() {
        switch state {
        case .idle:
            break

        case .ready:
            commandSubject.send(.shakeDice)
        }
    }

    // MARK: - State Updates

    private func updateState(_ updatedState: MainHomeState) {
        guard state != updatedState else { return }
        stateSubject.send(updatedState)
    }
}
