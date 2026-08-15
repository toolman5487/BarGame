//
//  GameDetailViewModel.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/13.
//

import Combine
import Foundation

// MARK: - Input

struct GameDetailViewModelInput {

    let viewWillAppear: AnyPublisher<Void, Never>
    let settingChange: AnyPublisher<GameDetailSettingChange, Never>
    let locationRequest: AnyPublisher<Void, Never>
    let startGame: AnyPublisher<Void, Never>
}

// MARK: - Output

struct GameDetailViewModelOutput {

    let state: AnyPublisher<GameDetailState, Never>
    let launchConfiguration: AnyPublisher<GameLaunchConfiguration, Never>
}

// MARK: - Protocol

@MainActor
protocol GameDetailViewModeling: AnyObject {

    func transform(input: GameDetailViewModelInput) -> GameDetailViewModelOutput
}

// MARK: - ViewModel

@MainActor
final class GameDetailViewModel: GameDetailViewModeling {

    private let gameID: DiceGameID
    private let recordStore: any DiceGameRecordStoring
    private let locationProvider: any GameLocationProviding
    private let locationCache: any GameLocationCaching
    private let stateSubject: CurrentValueSubject<GameDetailState, Never>
    private let launchConfigurationSubject = PassthroughSubject<
        GameLaunchConfiguration,
        Never
    >()
    private var cancellables = Set<AnyCancellable>()
    private var loadRecordsTask: Task<Void, Never>?
    private var cachedLocationTask: Task<Void, Never>?
    private var locationTask: Task<Void, Never>?

    private var state: GameDetailState {
        stateSubject.value
    }

    init(
        gameID: DiceGameID,
        initialState: GameDetailState,
        recordStore: any DiceGameRecordStoring,
        locationProvider: any GameLocationProviding,
        locationCache: any GameLocationCaching
    ) {
        self.gameID = gameID
        self.recordStore = recordStore
        self.locationProvider = locationProvider
        self.locationCache = locationCache
        stateSubject = CurrentValueSubject(initialState)
    }

    deinit {
        loadRecordsTask?.cancel()
        cachedLocationTask?.cancel()
        locationTask?.cancel()
    }

    func transform(input: GameDetailViewModelInput) -> GameDetailViewModelOutput {
        cancellables.removeAll()

        input.viewWillAppear
            .sink { [weak self] in
                self?.loadCachedLocation()
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
                self?.requestCurrentLocation()
            }
            .store(in: &cancellables)

        input.startGame
            .sink { [weak self] in
                self?.prepareGameLaunch()
            }
            .store(in: &cancellables)

        return GameDetailViewModelOutput(
            state: stateSubject
                .removeDuplicates()
                .eraseToAnyPublisher(),
            launchConfiguration: launchConfigurationSubject.eraseToAnyPublisher()
        )
    }

    private func updateSetting(with change: GameDetailSettingChange) {
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

    private func requestCurrentLocation() {
        locationTask?.cancel()

        switch locationProvider.authorizationState() {
        case .notDetermined:
            updateLocationState(.requestingAuthorization)

        case .authorized:
            updateLocationState(.locating)

        case .denied:
            updateLocationState(.authorizationDenied)
            return

        case .restricted:
            updateLocationState(.authorizationRestricted)
            return

        case .servicesDisabled:
            updateLocationState(.servicesDisabled)
            return
        }

        locationTask = Task { [
            weak self,
            locationProvider,
            locationCache,
        ] in
            do {
                let snapshot = try await locationProvider.currentLocationSnapshot()
                try Task.checkCancellation()
                await locationCache.save(snapshot)
                self?.updateLocationState(.located(snapshot))
            } catch is CancellationError {
                return
            } catch let error as GameLocationProviderError {
                self?.handleLocationError(error)
            } catch {
                self?.updateLocationState(.locationUnavailable)
            }
        }
    }

    private func handleLocationError(_ error: GameLocationProviderError) {
        switch error {
        case .servicesDisabled:
            updateLocationState(.servicesDisabled)

        case .authorizationDenied:
            updateLocationState(.authorizationDenied)

        case .authorizationRestricted:
            updateLocationState(.authorizationRestricted)

        case .locationUnavailable:
            updateLocationState(.locationUnavailable)

        case .timedOut:
            updateLocationState(.timedOut)

        case .reverseGeocodingFailed:
            updateLocationState(.reverseGeocodingFailed)
        }
    }

    private func updateLocationState(_ locationState: GameDetailLocationState) {
        stateSubject.send(state.updatingLocationState(locationState))
    }

    private func loadCachedLocation() {
        cachedLocationTask?.cancel()
        cachedLocationTask = Task { [weak self, locationCache] in
            let snapshot = await locationCache.snapshot()
            guard !Task.isCancelled else { return }

            guard let self,
                  !state.isLocationRequestInProgress
            else { return }

            guard let snapshot else {
                updateLocationStateFromAuthorization()
                return
            }

            updateLocationState(.located(snapshot))
        }
    }

    private func updateLocationStateFromAuthorization() {
        switch locationProvider.authorizationState() {
        case .notDetermined:
            updateLocationState(.notRequested)

        case .authorized:
            updateLocationState(.notRequested)

        case .denied:
            updateLocationState(.authorizationDenied)

        case .restricted:
            updateLocationState(.authorizationRestricted)

        case .servicesDisabled:
            updateLocationState(.servicesDisabled)
        }
    }

    private func loadRecords() {
        loadRecordsTask?.cancel()
        updateRecordStates(
            recentRecordsState: .loading,
            statisticsState: .loading
        )

        let gameID = gameID
        loadRecordsTask = Task { [weak self, recordStore] in
            do {
                let records = try await recordStore.records(
                    matching: DiceGameRecordQuery(gameID: gameID)
                )
                try Task.checkCancellation()
                self?.apply(records)
            } catch is CancellationError {
                return
            } catch {
                self?.handleRecordLoadFailure()
            }
        }
    }

    private func apply(_ records: [DiceGameMatchRecord]) {
        let displayRecords = records.map { GameDetailRecentRecord(record: $0) }
        let recentRecords = Array(
            displayRecords.prefix(GameDetailRecentRecordsState.maximumRecordCount)
        )
        let recentRecordsState: GameDetailRecentRecordsState = recentRecords.isEmpty
            ? .empty
            : .content(recentRecords)

        updateRecordStates(
            recentRecordsState: recentRecordsState,
            statisticsState: GameDetailStatisticsState(records: displayRecords)
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
        recentRecordsState: GameDetailRecentRecordsState,
        statisticsState: GameDetailStatisticsState
    ) {
        stateSubject.send(
            state.updatingRecords(
                recentRecordsState: recentRecordsState,
                statisticsState: statisticsState
            )
        )
    }
}
