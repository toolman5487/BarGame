//
//  GameLocationCoordinator.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

@MainActor
final class GameLocationCoordinator: GameLocationRefreshing {

    private let locationProvider: any GameLocationProviding
    private let locationCache: any GameLocationCaching
    private var refreshTask: Task<Void, any Error>?

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

    func refreshLocation() async throws {
        let task = startLocationRefresh(
            removesCachedSnapshot: false,
            priority: .userInitiated
        )
        try await task.value
    }

    func refreshLocationOnLaunch() {
        startLocationRefresh(
            removesCachedSnapshot: true,
            priority: .utility
        )
    }

    @discardableResult
    private func startLocationRefresh(
        removesCachedSnapshot: Bool,
        priority: TaskPriority
    ) -> Task<Void, any Error> {
        refreshTask?.cancel()
        let task = Task(priority: priority) { [locationProvider, locationCache] in
            if removesCachedSnapshot {
                await locationCache.removeSnapshot()
            }

            let snapshot = try await locationProvider.currentLocationSnapshot()
            try Task.checkCancellation()
            await locationCache.save(snapshot)
        }
        refreshTask = task
        return task
    }
}
