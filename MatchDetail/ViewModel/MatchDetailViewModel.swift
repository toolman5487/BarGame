//
//  MatchDetailViewModel.swift
//  BarGame
//
//  Created by Codex on 2026/8/21.
//

import Combine
import Foundation
import OSLog

struct MatchDetailViewModelInput {

    let viewWillAppear: AnyPublisher<Void, Never>
    let retryRequest: AnyPublisher<Void, Never>
}

struct MatchDetailViewModelOutput {

    let state: AnyPublisher<MatchDetailViewState, Never>
}

@MainActor
protocol MatchDetailViewModeling: AnyObject {

    func transform(
        input: MatchDetailViewModelInput
    ) -> MatchDetailViewModelOutput
}

@MainActor
final class MatchDetailViewModel: MatchDetailViewModeling {

    // MARK: - Dependencies

    private let recordID: UUID
    private let recordStore: any DiceGameRecordStoring
    private let locationGeocoder: any MatchDetailLocationGeocoding

    // MARK: - State

    private let stateSubject = CurrentValueSubject<
        MatchDetailViewState,
        Never
    >(.idle)
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?

    // MARK: - Lifecycle

    init(
        recordID: UUID,
        recordStore: any DiceGameRecordStoring,
        locationGeocoder: any MatchDetailLocationGeocoding
    ) {
        self.recordID = recordID
        self.recordStore = recordStore
        self.locationGeocoder = locationGeocoder
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Public

    func transform(
        input: MatchDetailViewModelInput
    ) -> MatchDetailViewModelOutput {
        cancellables.removeAll()

        input.viewWillAppear
            .sink { [weak self] in
                self?.loadMatch()
            }
            .store(in: &cancellables)

        input.retryRequest
            .sink { [weak self] in
                self?.loadMatch()
            }
            .store(in: &cancellables)

        return MatchDetailViewModelOutput(
            state: stateSubject
                .removeDuplicates()
                .eraseToAnyPublisher()
        )
    }

    // MARK: - Load

    private func loadMatch() {
        loadTask?.cancel()
        stateSubject.send(.loading)

        loadTask = Task(priority: .userInitiated) { [
            weak self,
            locationGeocoder,
            recordID,
            recordStore,
        ] in
            do {
                let record = try await recordStore.record(withID: recordID)
                try Task.checkCancellation()

                guard let record else {
                    self?.stateSubject.send(.failed(.recordNotFound))
                    return
                }

                let loadingPresentation = MatchDetailPresentation(
                    record: record,
                    mapState: .loading
                )
                self?.stateSubject.send(.content(loadingPresentation))

                guard let address = loadingPresentation
                    .information
                    .geocodingAddress
                else { return }

                let mapState: MatchDetailMapState
                do {
                    let coordinate = try await locationGeocoder.coordinate(
                        for: address
                    )
                    try Task.checkCancellation()
                    mapState = .located(coordinate)
                } catch is CancellationError {
                    return
                } catch {
                    AppLogger.search.warning(
                        "Match location geocoding failed: \(String(describing: error), privacy: .public)"
                    )
                    mapState = .unavailable
                }

                self?.stateSubject.send(
                    .content(
                        MatchDetailPresentation(
                            record: record,
                            mapState: mapState
                        )
                    )
                )
            } catch is CancellationError {
                return
            } catch {
                AppLogger.persistence.error(
                    "Match detail loading failed: \(String(describing: error), privacy: .public)"
                )
                self?.stateSubject.send(.failed(.loadFailed))
            }
        }
    }
}
