//
//  GameHistoryStore+Sessions.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import Foundation
import SwiftData

private nonisolated enum MatchDeletionPlan {

    case matchOnly(session: StoredGameSession?)
    case matchAndSession(
        session: StoredGameSession,
        event: StoredGameEvent?
    )
    case matchSessionAndEvent(
        session: StoredGameSession,
        event: StoredGameEvent
    )
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

        let coordinate: GameCoordinate?
        if let latitude = event.locationLatitude,
           let longitude = event.locationLongitude {
            let storedCoordinate = GameCoordinate(
                latitude: latitude,
                longitude: longitude
            )
            coordinate = storedCoordinate.isValid ? storedCoordinate : nil
        } else {
            coordinate = nil
        }
        let location = event.locationName.map { detailAddress in
            GameLocationSnapshot(
                area: event.locality,
                detailAddress: detailAddress,
                coordinate: coordinate
            )
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
        switch makeDeletionPlan(for: match) {
        case .matchOnly(let session):
            if let session {
                recalculateDateRange(
                    for: session,
                    excludingMatchID: match.id
                )
            }
            modelContext.delete(match)

        case .matchAndSession(let session, let event):
            if let event {
                recalculateEventDateRange(
                    for: event,
                    excludingMatchID: match.id
                )
            }
            modelContext.delete(match)
            modelContext.delete(session)

        case .matchSessionAndEvent(let session, let event):
            modelContext.delete(match)
            modelContext.delete(session)
            modelContext.delete(event)
        }

        try modelContext.save()
    }

    // MARK: - Private

    private func makeDeletionPlan(
        for match: StoredGameMatch
    ) -> MatchDeletionPlan {
        guard let session = match.session else {
            return .matchOnly(session: nil)
        }
        guard session.matches.count == 1 else {
            return .matchOnly(session: session)
        }
        guard let event = session.event else {
            return .matchAndSession(session: session, event: nil)
        }
        guard event.sessions.count == 1 else {
            return .matchAndSession(session: session, event: event)
        }
        return .matchSessionAndEvent(session: session, event: event)
    }

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
            locality: context.location?.area,
            locationLatitude: context.location?.coordinate?.latitude,
            locationLongitude: context.location?.coordinate?.longitude
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
              event.locality == context.location?.area,
              event.locationLatitude
                == context.location?.coordinate?.latitude,
              event.locationLongitude
                == context.location?.coordinate?.longitude else {
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
