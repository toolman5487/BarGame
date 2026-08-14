//
//  MainHomeViewModel.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/11.
//

import Combine
import Foundation
import OSLog

// MARK: - Input

struct MainHomeViewModelInput {

    let viewDidLoad: AnyPublisher<Void, Never>
    let shakeMotion: AnyPublisher<Void, Never>
    let didRequestRetry: AnyPublisher<Void, Never>
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

        input.didRequestRetry
            .sink { [weak self] in
                self?.handleRetry()
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
            loadContent()

        case .loading:
            break

        case .ready:
            break

        case .failed:
            break
        }
    }

    private func handleRetry() {
        switch state {
        case .failed(let failure) where failure.isRetryable:
            loadContent()

        case .idle:
            break

        case .loading:
            break

        case .ready:
            break

        case .failed:
            break
        }
    }

    private func handleShakeMotion() {
        switch state {
        case .ready:
            commandSubject.send(.shakeDice)

        case .idle:
            break

        case .loading:
            break

        case .failed:
            break
        }
    }

    // MARK: - Load

    private func loadContent() {
        updateState(.loading)

        switch Self.resolveSnapshot(from: configuration) {
        case .success(let snapshot):
            updateState(.ready(snapshot))

        case .failure(let failure):
            AppLogger.configuration.error(
                "\(failure.logDescription, privacy: .public)"
            )
            updateState(.failed(failure))
        }
    }

    private static func resolveSnapshot(
        from configuration: MainHomeConfiguration
    ) -> Result<MainHomeSnapshot, MainHomeFailure> {
        let snapshot = configuration.snapshot

        guard !snapshot.sections.isEmpty else {
            return .failure(
                .contentUnavailable(reason: .emptySections)
            )
        }

        let hasEmptyGameList = snapshot.sections.contains { section in
            guard case .gameList(let games) = section else { return false }
            return games.isEmpty
        }
        if hasEmptyGameList {
            return .failure(
                .contentUnavailable(reason: .missingGames)
            )
        }

        return .success(snapshot)
    }

    // MARK: - State Updates

    private func updateState(_ updatedState: MainHomeState) {
        guard state != updatedState else { return }
        stateSubject.send(updatedState)
    }
}
