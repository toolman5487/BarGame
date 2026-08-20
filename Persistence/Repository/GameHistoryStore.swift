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
}

@ModelActor
actor GameHistoryStore {}

extension GameHistoryStore: GameStatisticsReading {

    func statistics(
        for gameIDs: [DiceGameID]
    ) throws -> [DiceGameID: GameStatistics] {
        let requestedGameIDs = Set(gameIDs)
        guard !requestedGameIDs.isEmpty else { return [:] }

        var statisticsByGameID = Dictionary(
            uniqueKeysWithValues: requestedGameIDs.map { ($0, GameStatistics.zero) }
        )
        let records = try records(matching: DiceGameRecordQuery())
        let recordsByGameID = Dictionary(
            grouping: records.filter { requestedGameIDs.contains($0.gameID) },
            by: \.gameID
        )

        for gameID in requestedGameIDs {
            statisticsByGameID[gameID] = Self.makeStatistics(
                from: recordsByGameID[gameID] ?? []
            )
        }

        return statisticsByGameID
    }

    private static func makeStatistics(
        from records: [DiceGameMatchRecord]
    ) -> GameStatistics {
        guard !records.isEmpty else { return .zero }

        var wins = 0
        var losses = 0
        var draws = 0
        var totalPoints = 0

        for record in records {
            switch record.outcome {
            case .win:
                wins += 1

            case .loss:
                losses += 1

            case .draw:
                draws += 1
            }

            totalPoints += record.totalPoints
        }

        return GameStatistics(
            wins: wins,
            losses: losses,
            draws: draws,
            totalPoints: totalPoints,
            currentStreak: makeCurrentStreak(from: records)
        )
    }

    private static func makeCurrentStreak(
        from records: [DiceGameMatchRecord]
    ) -> MatchOutcomeStreak? {
        guard let outcome = records.first?.outcome else { return nil }
        let count = records.prefix { $0.outcome == outcome }.count

        switch outcome {
        case .win:
            return .win(count)

        case .loss:
            return .loss(count)

        case .draw:
            return .draw(count)
        }
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
            GameLocationSnapshot(address: $0, locality: event.locality)
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
            locationName: context.location?.detailAddress,
            locality: context.location?.area
        )
        modelContext.insert(event)
        return event
    }

    private func validate(
        _ event: StoredGameEvent,
        matches context: GameEventContext
    ) throws {
        guard event.timeZoneIdentifier == context.timeZoneIdentifier,
              event.locationName == context.location?.detailAddress,
              event.locality == context.location?.area else {
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
