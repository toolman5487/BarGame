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
        try DiceGameRecordValidator.validate(record)

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
        try DiceGameRecordValidator.validate(record)

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

        DiceGameRecordSynchronizer.update(
            match,
            from: record,
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
        let matches = try storedMatches(sortOrder: query.sortOrder)
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
        let filteredRecords = records
            .filter { record in
                guard let outcome = query.outcome else { return true }
                return record.outcome == outcome
            }
            .filter { record in
                guard let dateInterval = query.dateInterval else { return true }
                return record.playedAt >= dateInterval.start
                    && record.playedAt < dateInterval.end
            }
            .sorted { first, second in
                switch query.sortOrder {
                case .newest:
                    return first.playedAt > second.playedAt

                case .oldest:
                    return first.playedAt < second.playedAt
                }
            }

        guard let limit = query.limit else { return filteredRecords }
        return Array(filteredRecords.prefix(limit))
    }

    // MARK: - Query

    private func storedMatches(
        sortOrder: DiceGameRecordSortOrder
    ) throws -> [StoredGameMatch] {
        let sortBy: [SortDescriptor<StoredGameMatch>]
        switch sortOrder {
        case .newest:
            sortBy = [
                SortDescriptor(\StoredGameMatch.playedAt, order: .reverse),
            ]

        case .oldest:
            sortBy = [
                SortDescriptor(\StoredGameMatch.playedAt, order: .forward),
            ]
        }
        return try modelContext.fetch(
            FetchDescriptor<StoredGameMatch>(sortBy: sortBy)
        )
    }

}
