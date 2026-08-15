//
//  GameHistoryStore.swift
//  BarGame
//
//  Created by Codex on 2026/8/14.
//

import Foundation
import SwiftData

nonisolated enum GameHistoryStoreError: Error, Equatable, Sendable {

    case eventContextMismatch(UUID)
    case sessionContextMismatch(UUID)
    case invalidStoredSession(UUID)
    case invalidStoredOutcome(UUID)
}

@ModelActor
actor GameHistoryStore {}

extension GameHistoryStore: GameStatisticsReading {

    func statistics(
        for gameIDs: [DiceGameID]
    ) throws -> [DiceGameID: GameStatistics] {
        let requestedGameIDs = Set(gameIDs)
        guard !requestedGameIDs.isEmpty else { return [:] }

        let diceCategoryID = GameCategoryID.dice.rawValue
        let descriptor = FetchDescriptor<StoredGameMatch>(
            predicate: #Predicate { match in
                match.session?.categoryID == diceCategoryID
            }
        )
        let matches = try modelContext.fetch(descriptor)
        var statisticsByGameID = Dictionary(
            uniqueKeysWithValues: requestedGameIDs.map { ($0, GameStatistics.zero) }
        )

        for match in matches {
            guard let variantID = match.session?.variantID,
                  let gameID = DiceGameID(rawValue: variantID),
                  requestedGameIDs.contains(gameID) else {
                continue
            }
            guard let outcome = GameOutcome(rawValue: match.outcomeRawValue) else {
                throw GameHistoryStoreError.invalidStoredOutcome(match.id)
            }

            let currentStatistics = statisticsByGameID[gameID, default: .zero]
            switch outcome {
            case .win:
                statisticsByGameID[gameID] = GameStatistics(
                    wins: currentStatistics.wins + 1,
                    losses: currentStatistics.losses
                )

            case .loss:
                statisticsByGameID[gameID] = GameStatistics(
                    wins: currentStatistics.wins,
                    losses: currentStatistics.losses + 1
                )
            }
        }

        return statisticsByGameID
    }
}

extension GameHistoryStore {

    func resolveSession(
        for context: GameSessionContext
    ) throws -> StoredGameSession {
        let event = try storedEvent(withID: context.event.id)
            ?? insertEvent(from: context.event)

        try validate(event, matches: context.event)

        if let session = try storedSession(withID: context.id) {
            try validate(session, matches: context)
            return session
        }

        let session = StoredGameSession(
            id: context.id,
            categoryID: context.identity.categoryID.rawValue,
            gameTypeID: context.identity.typeID.rawValue,
            variantID: context.identity.variantID,
            rulesVersion: context.rulesVersion,
            startedAt: context.startedAt,
            endedAt: context.startedAt,
            event: event
        )
        modelContext.insert(session)
        return session
    }

    func storedMatch(withID id: UUID) throws -> StoredGameMatch? {
        var descriptor = FetchDescriptor<StoredGameMatch>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func sessionContext(
        from session: StoredGameSession
    ) throws -> GameSessionContext {
        guard let event = session.event,
              let categoryID = GameCategoryID(rawValue: session.categoryID),
              let typeID = GameTypeID(rawValue: session.gameTypeID) else {
            throw GameHistoryStoreError.invalidStoredSession(session.id)
        }

        let location = event.locationName.map {
            GameLocationSnapshot(name: $0, locality: event.locality)
        }
        let eventContext = GameEventContext(
            id: event.id,
            startedAt: event.startedAt,
            timeZoneIdentifier: event.timeZoneIdentifier,
            location: location
        )
        return GameSessionContext(
            id: session.id,
            event: eventContext,
            identity: GameIdentity(
                categoryID: categoryID,
                typeID: typeID,
                variantID: session.variantID
            ),
            rulesVersion: session.rulesVersion,
            startedAt: session.startedAt
        )
    }

    func nextMatchSequence(in session: StoredGameSession) -> Int {
        (session.matches.map(\.sequence).max() ?? 0) + 1
    }

    func updateDateRange(
        for session: StoredGameSession,
        playedAt: Date
    ) {
        session.startedAt = min(session.startedAt, playedAt)
        session.endedAt = max(session.endedAt ?? playedAt, playedAt)

        guard let event = session.event else { return }
        event.startedAt = min(event.startedAt, playedAt)
        event.endedAt = max(event.endedAt ?? playedAt, playedAt)
    }

    func recalculateDateRange(
        for session: StoredGameSession,
        excludingMatchID: UUID? = nil
    ) {
        let playedDates = session.matches
            .filter { $0.id != excludingMatchID }
            .map(\.playedAt)

        if let firstDate = playedDates.min(), let lastDate = playedDates.max() {
            session.startedAt = firstDate
            session.endedAt = lastDate
        }

        if let event = session.event {
            recalculateEventDateRange(
                for: event,
                excludingMatchID: excludingMatchID
            )
        }
    }

    func deleteMatchAndEmptyAncestors(_ match: StoredGameMatch) throws {
        let session = match.session
        let event = session?.event
        let deletesSession = session?.matches.count == 1
        let deletesEvent = deletesSession && event?.sessions.count == 1

        if !deletesSession, let session {
            recalculateDateRange(for: session, excludingMatchID: match.id)
        } else if !deletesEvent, let event {
            recalculateEventDateRange(for: event, excludingMatchID: match.id)
        }

        modelContext.delete(match)

        if deletesSession, let session {
            modelContext.delete(session)
        }
        if deletesEvent, let event {
            modelContext.delete(event)
        }

        try modelContext.save()
    }

    // MARK: - Private

    private func storedEvent(withID id: UUID) throws -> StoredGameEvent? {
        var descriptor = FetchDescriptor<StoredGameEvent>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func storedSession(withID id: UUID) throws -> StoredGameSession? {
        var descriptor = FetchDescriptor<StoredGameSession>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func insertEvent(
        from context: GameEventContext
    ) -> StoredGameEvent {
        let event = StoredGameEvent(
            id: context.id,
            startedAt: context.startedAt,
            endedAt: context.startedAt,
            timeZoneIdentifier: context.timeZoneIdentifier,
            locationName: context.location?.name,
            locality: context.location?.locality
        )
        modelContext.insert(event)
        return event
    }

    private func validate(
        _ event: StoredGameEvent,
        matches context: GameEventContext
    ) throws {
        guard event.timeZoneIdentifier == context.timeZoneIdentifier,
              event.locationName == context.location?.name,
              event.locality == context.location?.locality else {
            throw GameHistoryStoreError.eventContextMismatch(context.id)
        }
    }

    private func validate(
        _ session: StoredGameSession,
        matches context: GameSessionContext
    ) throws {
        guard session.event?.id == context.event.id,
              session.categoryID == context.identity.categoryID.rawValue,
              session.gameTypeID == context.identity.typeID.rawValue,
              session.variantID == context.identity.variantID,
              session.rulesVersion == context.rulesVersion else {
            throw GameHistoryStoreError.sessionContextMismatch(context.id)
        }
    }

    private func recalculateEventDateRange(
        for event: StoredGameEvent,
        excludingMatchID: UUID? = nil
    ) {
        let playedDates = event.sessions
            .flatMap(\.matches)
            .filter { $0.id != excludingMatchID }
            .map(\.playedAt)

        if let firstDate = playedDates.min(), let lastDate = playedDates.max() {
            event.startedAt = firstDate
            event.endedAt = lastDate
        }
    }
}
