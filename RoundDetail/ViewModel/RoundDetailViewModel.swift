//
//  RoundDetailViewModel.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import Combine
import Foundation
import OSLog

struct RoundDetailViewModelInput {

    let viewWillAppear: AnyPublisher<Void, Never>
    let retryRequest: AnyPublisher<Void, Never>
}

struct RoundDetailViewModelOutput {

    let state: AnyPublisher<RoundDetailViewState, Never>
}

@MainActor
protocol RoundDetailViewModeling: AnyObject {

    func transform(
        input: RoundDetailViewModelInput
    ) -> RoundDetailViewModelOutput
}

@MainActor
final class RoundDetailViewModel: RoundDetailViewModeling {

    // MARK: - Dependencies

    private let matchID: UUID
    private let roundID: UUID
    private let recordStore: any DiceGameRecordStoring

    // MARK: - State

    private let stateSubject = CurrentValueSubject<
        RoundDetailViewState,
        Never
    >(.idle)
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?

    // MARK: - Lifecycle

    init(
        matchID: UUID,
        roundID: UUID,
        recordStore: any DiceGameRecordStoring
    ) {
        self.matchID = matchID
        self.roundID = roundID
        self.recordStore = recordStore
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Public

    func transform(
        input: RoundDetailViewModelInput
    ) -> RoundDetailViewModelOutput {
        cancellables.removeAll()

        input.viewWillAppear
            .sink { [weak self] in
                self?.loadRound()
            }
            .store(in: &cancellables)

        input.retryRequest
            .sink { [weak self] in
                self?.loadRound()
            }
            .store(in: &cancellables)

        return RoundDetailViewModelOutput(
            state: stateSubject
                .removeDuplicates()
                .eraseToAnyPublisher()
        )
    }

    // MARK: - Load

    private func loadRound() {
        loadTask?.cancel()
        stateSubject.send(.loading)

        loadTask = Task(priority: .userInitiated) { [
            weak self,
            matchID,
            recordStore,
            roundID,
        ] in
            do {
                let record = try await recordStore.record(withID: matchID)
                try Task.checkCancellation()

                guard let record else {
                    self?.stateSubject.send(.failed(.matchNotFound))
                    return
                }
                guard let round = record.rounds.first(
                    where: { $0.id == roundID }
                ) else {
                    self?.stateSubject.send(.failed(.roundNotFound))
                    return
                }
                guard let presentation = RoundDetailPresentation(
                    record: record,
                    round: round
                ) else {
                    self?.stateSubject.send(.failed(.invalidRoundData))
                    return
                }

                self?.stateSubject.send(.content(presentation))
            } catch is CancellationError {
                return
            } catch {
                AppLogger.persistence.error(
                    "Round detail loading failed: \(String(describing: error), privacy: .public)"
                )
                self?.stateSubject.send(.failed(.loadFailed))
            }
        }
    }
}
