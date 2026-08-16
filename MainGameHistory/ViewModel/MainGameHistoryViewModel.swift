//
//  MainGameHistoryViewModel.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Combine
import Foundation
import OSLog

// MARK: - Input

struct MainGameHistoryViewModelInput {

    let viewWillAppear: AnyPublisher<Void, Never>
    let filterChange: AnyPublisher<MainGameHistoryFilterChange, Never>
    let retryRequest: AnyPublisher<Void, Never>
}

// MARK: - Output

struct MainGameHistoryViewModelOutput {

    let state: AnyPublisher<MainGameHistoryViewState, Never>
}

// MARK: - Protocol

@MainActor
protocol MainGameHistoryViewModeling: AnyObject {

    func transform(
        input: MainGameHistoryViewModelInput
    ) -> MainGameHistoryViewModelOutput
}

// MARK: - ViewModel

@MainActor
final class MainGameHistoryViewModel: MainGameHistoryViewModeling {

    // MARK: - Configuration

    private enum Configuration {
        static let loadingStateDelay: Duration = .milliseconds(300)
    }

    // MARK: - Dependencies

    private let recordStore: any DiceGameRecordStoring
    private let calendar: Calendar

    // MARK: - State

    private let stateSubject = CurrentValueSubject<
        MainGameHistoryViewState,
        Never
    >(.initial)
    private var cancellables = Set<AnyCancellable>()
    private var loadRecordsTask: Task<Void, Never>?
    private var loadingStateTask: Task<Void, Never>?

    private var state: MainGameHistoryViewState {
        stateSubject.value
    }

    // MARK: - Lifecycle

    init(
        recordStore: any DiceGameRecordStoring,
        calendar: Calendar = .current
    ) {
        self.recordStore = recordStore
        self.calendar = calendar
    }

    deinit {
        loadRecordsTask?.cancel()
        loadingStateTask?.cancel()
    }

    // MARK: - Public

    func transform(
        input: MainGameHistoryViewModelInput
    ) -> MainGameHistoryViewModelOutput {
        cancellables.removeAll()

        input.viewWillAppear
            .sink { [weak self] in
                self?.loadRecordsForCurrentFilter()
            }
            .store(in: &cancellables)

        input.filterChange
            .sink { [weak self] change in
                self?.applyFilterChange(change)
            }
            .store(in: &cancellables)

        input.retryRequest
            .sink { [weak self] in
                self?.handleRetryRequest()
            }
            .store(in: &cancellables)

        return MainGameHistoryViewModelOutput(
            state: stateSubject
                .removeDuplicates()
                .eraseToAnyPublisher()
        )
    }

    // MARK: - Actions

    private func applyFilterChange(_ change: MainGameHistoryFilterChange) {
        let updatedFilter = state.filter.applying(change)
        guard updatedFilter != state.filter else { return }
        loadRecords(for: updatedFilter)
    }

    private func handleRetryRequest() {
        guard case .failed = state.contentState else { return }
        loadRecordsForCurrentFilter()
    }

    // MARK: - Load

    private func loadRecordsForCurrentFilter() {
        loadRecords(for: state.filter)
    }

    private func loadRecords(for filter: MainGameHistoryFilter) {
        loadRecordsTask?.cancel()
        loadingStateTask?.cancel()

        let retainedContentState: MainGameHistoryContentState
        switch state.contentState {
        case .records, .empty:
            retainedContentState = state.contentState

        case .idle, .loading, .failed:
            retainedContentState = .idle
        }
        updateState(
            MainGameHistoryViewState(
                filter: filter,
                contentState: retainedContentState
            )
        )

        loadingStateTask = Task(priority: .userInitiated) { [weak self] in
            do {
                try await Task.sleep(for: Configuration.loadingStateDelay)
                try Task.checkCancellation()
                self?.showLoadingState(for: filter)
            } catch {
                return
            }
        }

        let calendar = calendar
        let query = filter.query
        loadRecordsTask = Task(priority: .userInitiated) { [
            weak self,
            recordStore,
        ] in
            do {
                let records = try await recordStore.records(matching: query)
                try Task.checkCancellation()
                let items = try records.map {
                    try MainGameHistoryRecordItem(
                        record: $0,
                        calendar: calendar
                    )
                }
                self?.applyLoadedItems(items, for: filter)
            } catch is CancellationError {
                return
            } catch {
                self?.handleLoadFailure(error, for: filter)
            }
        }
    }

    private func applyLoadedItems(
        _ items: [MainGameHistoryRecordItem],
        for filter: MainGameHistoryFilter
    ) {
        guard state.filter == filter else { return }
        loadingStateTask?.cancel()

        let contentState: MainGameHistoryContentState
        if items.isEmpty {
            contentState = .empty(
                filter.hasActiveConditions ? .noFilterResults : .noRecords
            )
        } else {
            contentState = .records(items)
        }

        updateState(
            MainGameHistoryViewState(
                filter: filter,
                contentState: contentState
            )
        )
    }

    private func handleLoadFailure(
        _ error: any Error,
        for filter: MainGameHistoryFilter
    ) {
        guard state.filter == filter else { return }
        loadingStateTask?.cancel()

        AppLogger.persistence.error(
            "Game history loading failed: \(String(describing: error), privacy: .public)"
        )
        updateState(
            MainGameHistoryViewState(
                filter: filter,
                contentState: .failed(.loadFailed)
            )
        )
    }

    // MARK: - State Updates

    private func showLoadingState(for filter: MainGameHistoryFilter) {
        guard state.filter == filter else { return }
        updateState(
            MainGameHistoryViewState(
                filter: filter,
                contentState: .loading
            )
        )
    }

    private func updateState(_ updatedState: MainGameHistoryViewState) {
        guard updatedState != state else { return }
        stateSubject.send(updatedState)
    }
}
