//
//  GameHistoryStore+DiceGameRecords.swift
//  BarGame
//
//  Created by Codex on 2026/8/14.
//

import Foundation
import SwiftData

extension GameHistoryStore: DiceGameRecordStoring {

    func insert(_ record: DiceGameMatchRecord) throws {
        try DiceGameRecordMapper.validate(record)

        guard try storedMatch(withID: record.id) == nil else {
            throw DiceGameRecordStoreError.duplicateRecord(record.id)
        }

        let session = try resolveSession(for: record.sessionContext)
        let match = DiceGameRecordMapper.makeStoredMatch(
            from: record,
            sequence: nextMatchSequence(in: session),
            session: session
        )
        modelContext.insert(match)
        updateDateRange(for: session, playedAt: record.playedAt)
        try modelContext.save()
    }

    func update(_ record: DiceGameMatchRecord) throws {
        try DiceGameRecordMapper.validate(record)

        guard let match = try storedMatch(withID: record.id) else {
            throw DiceGameRecordStoreError.recordNotFound(record.id)
        }
        guard let session = match.session,
              session.id == record.sessionContext.id,
              session.event?.id == record.sessionContext.event.id,
              session.categoryID == record.sessionContext.identity.categoryID.rawValue,
              session.gameTypeID == record.sessionContext.identity.typeID.rawValue,
              session.variantID == record.gameID.rawValue,
              session.rulesVersion == record.sessionContext.rulesVersion else {
            throw DiceGameRecordStoreError.immutableSessionChanged(record.id)
        }
        guard let round = match.rounds.min(by: { $0.sequence < $1.sequence }),
              let roll = round.diceRolls.min(by: { $0.sequence < $1.sequence }) else {
            throw DiceGameRecordStoreError.invalidStoredRecord(record.id)
        }

        match.outcomeRawValue = record.outcome.rawValue
        match.playedAt = record.playedAt
        round.startedAt = record.playedAt
        round.endedAt = record.playedAt
        roll.rolledAt = record.playedAt
        DiceGameRecordMapper.replaceDiceResults(
            in: roll,
            with: record.diceResult.values,
            modelContext: modelContext
        )
        recalculateDateRange(for: session)
        try modelContext.save()
    }

    func deleteRecord(withID id: UUID) throws {
        guard let match = try storedMatch(withID: id) else {
            throw DiceGameRecordStoreError.recordNotFound(id)
        }
        try deleteMatchAndEmptyAncestors(match)
    }

    func record(withID id: UUID) throws -> DiceGameMatchRecord? {
        guard let match = try storedMatch(withID: id),
              let session = match.session,
              session.categoryID == GameCategoryID.dice.rawValue else {
            return nil
        }
        return try DiceGameRecordMapper.makeRecord(
            from: match,
            sessionContext: sessionContext(from: session)
        )
    }

    func records(
        matching query: DiceGameRecordQuery
    ) throws -> [DiceGameMatchRecord] {
        let matches = try storedMatches(matching: query)
        let records = try matches.compactMap { match -> DiceGameMatchRecord? in
            guard let session = match.session,
                  session.categoryID == GameCategoryID.dice.rawValue else {
                return nil
            }
            if let gameID = query.gameID,
               session.variantID != gameID.rawValue {
                return nil
            }
            return try DiceGameRecordMapper.makeRecord(
                from: match,
                sessionContext: sessionContext(from: session)
            )
        }

        guard let limit = query.limit else { return records }
        return Array(records.prefix(limit))
    }

    // MARK: - Query

    private func storedMatches(
        matching query: DiceGameRecordQuery
    ) throws -> [StoredGameMatch] {
        let sortBy: [SortDescriptor<StoredGameMatch>]
        switch query.sortOrder {
        case .newest:
            sortBy = [
                SortDescriptor(\StoredGameMatch.playedAt, order: .reverse),
            ]

        case .oldest:
            sortBy = [
                SortDescriptor(\StoredGameMatch.playedAt, order: .forward),
            ]
        }

        switch (query.outcome, query.dateInterval) {
        case (nil, nil):
            return try modelContext.fetch(
                FetchDescriptor<StoredGameMatch>(sortBy: sortBy)
            )

        case (.some(let outcome), nil):
            let outcomeRawValue = outcome.rawValue
            return try modelContext.fetch(
                FetchDescriptor<StoredGameMatch>(
                    predicate: #Predicate { $0.outcomeRawValue == outcomeRawValue },
                    sortBy: sortBy
                )
            )

        case (nil, .some(let dateInterval)):
            let start = dateInterval.start
            let end = dateInterval.end
            return try modelContext.fetch(
                FetchDescriptor<StoredGameMatch>(
                    predicate: #Predicate {
                        $0.playedAt >= start && $0.playedAt < end
                    },
                    sortBy: sortBy
                )
            )

        case (.some(let outcome), .some(let dateInterval)):
            let outcomeRawValue = outcome.rawValue
            let start = dateInterval.start
            let end = dateInterval.end
            return try modelContext.fetch(
                FetchDescriptor<StoredGameMatch>(
                    predicate: #Predicate {
                        $0.outcomeRawValue == outcomeRawValue
                            && $0.playedAt >= start
                            && $0.playedAt < end
                    },
                    sortBy: sortBy
                )
            )
        }
    }
}
