//
//  GameSettingViewModel.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/13.
//

import Combine
import Foundation

// MARK: - Input

struct GameSettingViewModelInput {

    let viewWillAppear: AnyPublisher<Void, Never>
    let settingChange: AnyPublisher<GameSettingChange, Never>
    let locationRequest: AnyPublisher<Void, Never>
    let startGame: AnyPublisher<Void, Never>
}

// MARK: - Output

struct GameSettingViewModelOutput {

    let state: AnyPublisher<GameSettingState, Never>
    let launchConfiguration: AnyPublisher<GameLaunchConfiguration, Never>
}

// MARK: - Protocol

@MainActor
protocol GameSettingViewModeling: AnyObject {

    func transform(input: GameSettingViewModelInput) -> GameSettingViewModelOutput
}

// MARK: - ViewModel

@MainActor
final class GameSettingViewModel: GameSettingViewModeling {

    private let gameID: DiceGameID
    private let recordStore: any DiceGameRecordStoring
    private let statisticsReader: any GameStatisticsReading
    private let locationCoordinator: any GameLocationCoordinating
    private let stateSubject: CurrentValueSubject<GameSettingState, Never>
    private let launchConfigurationSubject = PassthroughSubject<
        GameLaunchConfiguration,
        Never
    >()
    private var cancellables = Set<AnyCancellable>()
    private var loadRecordsTask: Task<Void, Never>?

    private var state: GameSettingState {
        stateSubject.value
    }

    init(
        gameID: DiceGameID,
        initialState: GameSettingState,
        recordStore: any DiceGameRecordStoring,
        statisticsReader: any GameStatisticsReading,
        locationCoordinator: any GameLocationCoordinating
    ) {
        self.gameID = gameID
        self.recordStore = recordStore
        self.statisticsReader = statisticsReader
        self.locationCoordinator = locationCoordinator
        stateSubject = CurrentValueSubject(initialState)
    }

    deinit {
        loadRecordsTask?.cancel()
    }

    func transform(input: GameSettingViewModelInput) -> GameSettingViewModelOutput {
        cancellables.removeAll()

        input.viewWillAppear
            .sink { [weak self] in
                self?.loadRecords()
            }
            .store(in: &cancellables)

        input.settingChange
            .sink { [weak self] change in
                self?.updateSetting(with: change)
            }
            .store(in: &cancellables)

        input.locationRequest
            .sink { [weak self] in
                self?.locationCoordinator.refreshLocation()
            }
            .store(in: &cancellables)

        input.startGame
            .sink { [weak self] in
                self?.prepareGameLaunch()
            }
            .store(in: &cancellables)

        locationCoordinator.locationState
            .sink { [weak self] locationState in
                self?.applyLocationState(locationState)
            }
            .store(in: &cancellables)

        return GameSettingViewModelOutput(
            state: stateSubject
                .removeDuplicates()
                .eraseToAnyPublisher(),
            launchConfiguration: launchConfigurationSubject.eraseToAnyPublisher()
        )
    }

    private func updateSetting(with change: GameSettingChange) {
        let updatedState = state.applying(change)
        guard updatedState != state else { return }
        stateSubject.send(updatedState)
    }

    private func prepareGameLaunch() {
        guard !state.isLocationRequestInProgress else { return }
        launchConfigurationSubject.send(
            state.launchConfiguration(for: gameID)
        )
    }

    private func applyLocationState(_ locationState: GameCurrentLocationState) {
        updateLocationState(
            Self.makeDetailLocationState(
                from: locationState,
                authorization: locationCoordinator.authorizationState()
            )
        )
    }

    private func updateLocationState(_ locationState: GameSettingLocationState) {
        stateSubject.send(state.updatingLocationState(locationState))
    }

    private func loadRecords() {
        loadRecordsTask?.cancel()
        updateRecordStates(
            recentRecordsState: .loading,
            statisticsState: .loading
        )

        let gameID = gameID
        loadRecordsTask = Task(priority: .userInitiated) { [
            weak self,
            recordStore,
            statisticsReader,
        ] in
            do {
                async let records = recordStore.records(
                    matching: DiceGameRecordQuery(gameID: gameID)
                )
                async let statisticsByGameID = statisticsReader.statistics(
                    for: [gameID]
                )
                let loadedRecords = try await records
                let statistics = try await statisticsByGameID[gameID] ?? .zero
                try Task.checkCancellation()
                self?.apply(records: loadedRecords, statistics: statistics)
            } catch is CancellationError {
                return
            } catch {
                self?.handleRecordLoadFailure()
            }
        }
    }

    private func apply(
        records: [DiceGameMatchRecord],
        statistics: GameStatistics
    ) {
        let displayRecords = records.map {
            GameSettingRecentRecord(record: $0)
        }
        let recentRecords = Array(
            displayRecords.prefix(GameSettingRecentRecordsState.maximumRecordCount)
        )
        let recentRecordsState: GameSettingRecentRecordsState = recentRecords.isEmpty
            ? .empty
            : .content(recentRecords)

        updateRecordStates(
            recentRecordsState: recentRecordsState,
            statisticsState: GameSettingStatisticsState(statistics: statistics)
        )
    }

    private func handleRecordLoadFailure() {
        let message = "請稍後再試"
        updateRecordStates(
            recentRecordsState: .error(message: message),
            statisticsState: .error(message: message)
        )
    }

    private func updateRecordStates(
        recentRecordsState: GameSettingRecentRecordsState,
        statisticsState: GameSettingStatisticsState
    ) {
        stateSubject.send(
            state.updatingRecords(
                recentRecordsState: recentRecordsState,
                statisticsState: statisticsState
            )
        )
    }

    private static func makeDetailLocationState(
        from state: GameCurrentLocationState,
        authorization: GameLocationAuthorizationState
    ) -> GameSettingLocationState {
        switch state {
        case .idle:
            return makeIdleLocationState(authorization: authorization)

        case .refreshing:
            switch authorization {
            case .notDetermined:
                return .requestingAuthorization

            case .authorized:
                return .locating

            case .denied:
                return .authorizationDenied

            case .restricted:
                return .authorizationRestricted

            case .servicesDisabled:
                return .servicesDisabled
            }

        case .located(let snapshot):
            return .located(snapshot.place)

        case .failed(let cachedSnapshot, let error):
            if let error {
                return makeFailedLocationState(error)
            }
            if let cachedSnapshot {
                return .located(cachedSnapshot.place)
            }
            return makeIdleLocationState(authorization: authorization)
        }
    }

    private static func makeIdleLocationState(
        authorization: GameLocationAuthorizationState
    ) -> GameSettingLocationState {
        switch authorization {
        case .notDetermined, .authorized:
            return .notRequested

        case .denied:
            return .authorizationDenied

        case .restricted:
            return .authorizationRestricted

        case .servicesDisabled:
            return .servicesDisabled
        }
    }

    private static func makeFailedLocationState(
        _ error: GameLocationProviderError
    ) -> GameSettingLocationState {
        switch error {
        case .servicesDisabled:
            return .servicesDisabled

        case .authorizationDenied:
            return .authorizationDenied

        case .authorizationRestricted:
            return .authorizationRestricted

        case .locationUnavailable:
            return .locationUnavailable

        case .timedOut:
            return .timedOut

        case .reverseGeocodingFailed:
            return .reverseGeocodingFailed
        }
    }
}
