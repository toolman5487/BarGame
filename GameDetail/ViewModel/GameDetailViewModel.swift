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
    private let stateSubject: CurrentValueSubject<GameDetailState, Never>
    private let launchConfigurationSubject = PassthroughSubject<
        GameLaunchConfiguration,
        Never
    >()
    private var cancellables = Set<AnyCancellable>()
    private var loadRecordsTask: Task<Void, Never>?

    private var state: GameDetailState {
        stateSubject.value
    }

    init(
        gameID: DiceGameID,
        initialState: GameDetailState,
        recordStore: any DiceGameRecordStoring
    ) {
        self.gameID = gameID
        self.recordStore = recordStore
        stateSubject = CurrentValueSubject(initialState)
    }

    deinit {
        loadRecordsTask?.cancel()
    }

    func transform(input: GameDetailViewModelInput) -> GameDetailViewModelOutput {
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
        launchConfigurationSubject.send(
            state.launchConfiguration(for: gameID)
        )
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
