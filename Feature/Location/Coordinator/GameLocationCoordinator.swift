//
//  GameLocationCoordinator.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Combine
import Foundation

@MainActor
final class GameLocationCoordinator: GameLocationCoordinating {

    private let locationProvider: any GameLocationProviding
    private let locationCache: any GameLocationCaching
    private let locationStateSubject = CurrentValueSubject<
        GameCurrentLocationState,
        Never
    >(.idle)
    private var refreshTask: Task<Void, Never>?

    var locationState: AnyPublisher<GameCurrentLocationState, Never> {
        locationStateSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    init(
        locationProvider: any GameLocationProviding,
        locationCache: any GameLocationCaching
    ) {
        self.locationProvider = locationProvider
        self.locationCache = locationCache
    }

    deinit {
        refreshTask?.cancel()
    }

    func refreshLocation() {
        startLocationRefresh(priority: .userInitiated)
    }

    func refreshLocationOnLaunch() {
        startLocationRefresh(priority: .utility)
    }

    private func startLocationRefresh(
        priority: TaskPriority
    ) {
        refreshTask?.cancel()
        refreshTask = Task(priority: priority) { [
            weak self,
            locationProvider,
            locationCache,
        ] in
            let cachedSnapshot: GameCurrentLocationSnapshot?
            if let currentSnapshot = self?.locationStateSubject.value.snapshot {
                cachedSnapshot = currentSnapshot
            } else {
                cachedSnapshot = await locationCache.snapshot()
            }
            guard !Task.isCancelled else { return }
            self?.locationStateSubject.send(
                .refreshing(cachedSnapshot: cachedSnapshot)
            )

            do {
                let snapshot = try await locationProvider
                    .currentLocationSnapshot()
                try Task.checkCancellation()
                await locationCache.save(snapshot)
                self?.locationStateSubject.send(.located(snapshot))
            } catch is CancellationError {
                return
            } catch {
                self?.locationStateSubject.send(
                    .failed(cachedSnapshot: cachedSnapshot)
                )
            }
        }
    }
}
