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
    let viewWillAppear: AnyPublisher<Void, Never>
    let shakeMotion: AnyPublisher<Void, Never>
    let locationRequest: AnyPublisher<Void, Never>
    let didRequestRetry: AnyPublisher<Void, Never>
}

// MARK: - Output

struct MainHomeViewModelOutput {

    let state: AnyPublisher<MainHomeState, Never>
    let locationState: AnyPublisher<MainHomeLocationState, Never>
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
    private let statisticsReader: any GameStatisticsReading
    private let locationRefresher: any GameLocationRefreshing

    // MARK: - State

    private let stateSubject = CurrentValueSubject<MainHomeState, Never>(.idle)
    private let locationStateSubject = CurrentValueSubject<MainHomeLocationState, Never>(.idle)
    private let commandSubject = PassthroughSubject<MainHomeViewCommand, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var loadContentTask: Task<Void, Never>?
    private var locationRefreshTask: Task<Void, Never>?

    private var state: MainHomeState {
        stateSubject.value
    }

    // MARK: - Lifecycle

    init(
        configuration: MainHomeConfiguration,
        statisticsReader: any GameStatisticsReading,
        locationRefresher: any GameLocationRefreshing
    ) {
        self.configuration = configuration
        self.statisticsReader = statisticsReader
        self.locationRefresher = locationRefresher
    }

    deinit {
        loadContentTask?.cancel()
        locationRefreshTask?.cancel()
    }

    // MARK: - Public

    func transform(input: MainHomeViewModelInput) -> MainHomeViewModelOutput {
        cancellables.removeAll()

        input.viewDidLoad
            .sink { [weak self] in
                self?.handleViewDidLoad()
            }
            .store(in: &cancellables)

        input.viewWillAppear
            .sink { [weak self] in
                self?.handleViewWillAppear()
            }
            .store(in: &cancellables)

        input.shakeMotion
            .sink { [weak self] in
                self?.handleShakeMotion()
            }
            .store(in: &cancellables)

        input.locationRequest
            .sink { [weak self] in
                self?.handleLocationRequest()
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
            locationState: locationStateSubject
                .removeDuplicates()
                .eraseToAnyPublisher(),
            command: commandSubject.eraseToAnyPublisher()
        )
    }

    // MARK: - Actions

    private func handleViewDidLoad() {
        switch state {
        case .idle:
            loadContent(showsLoadingState: true)

        case .loading:
            break

        case .ready:
            break

        case .failed:
            break
        }
    }

    private func handleViewWillAppear() {
        switch state {
        case .ready:
            loadContent(showsLoadingState: false)

        case .idle, .loading, .failed:
            break
        }
    }

    private func handleRetry() {
        switch state {
        case .failed(let failure) where failure.isRetryable:
            loadContent(showsLoadingState: true)

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

    private func handleLocationRequest() {
        guard locationStateSubject.value == .idle else { return }

        locationStateSubject.send(.refreshing)
        locationRefreshTask = Task(priority: .userInitiated) { [
            weak self,
            locationRefresher,
        ] in
            do {
                try await locationRefresher.refreshLocation()
                try Task.checkCancellation()
                self?.locationStateSubject.send(.idle)
            } catch is CancellationError {
                self?.locationStateSubject.send(.idle)
            } catch {
                self?.locationStateSubject.send(.failed)
            }
        }
    }

    // MARK: - Load

    private func loadContent(showsLoadingState: Bool) {
        switch Self.resolveSnapshot(from: configuration) {
        case .failure(let failure):
            AppLogger.configuration.error(
                "\(failure.logDescription, privacy: .public)"
            )
            updateState(.failed(failure))

        case .success(let snapshot):
            loadStatistics(
                for: snapshot,
                showsLoadingState: showsLoadingState
            )
        }
    }

    private func loadStatistics(
        for snapshot: MainHomeSnapshot,
        showsLoadingState: Bool
    ) {
        loadContentTask?.cancel()
        if showsLoadingState {
            updateState(.loading)
        }

        let games = snapshot.games
        loadContentTask = Task(priority: .userInitiated) { [
            weak self,
            statisticsReader,
        ] in
            do {
                let statisticsByGameID = try await statisticsReader.statistics(
                    for: games.map(\.id)
                )
                try Task.checkCancellation()

                let gameOverviews = games.map { game in
                    GameOverview(
                        game: game,
                        statistics: statisticsByGameID[game.id] ?? .zero
                    )
                }
                self?.updateState(
                    .ready(snapshot.updatingGameResults(gameOverviews))
                )
            } catch is CancellationError {
                return
            } catch {
                self?.handleStatisticsLoadFailure(error)
            }
        }
    }

    private func handleStatisticsLoadFailure(_ error: any Error) {
        AppLogger.persistence.error(
            "MainHome statistics loading failed: \(String(describing: error), privacy: .public)"
        )

        switch state {
        case .ready:
            break

        case .idle, .loading, .failed:
            updateState(.failed(.loadFailed))
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
