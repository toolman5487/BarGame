//
//  DiceGameRecordStore.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/14.
//

import Foundation

nonisolated protocol DiceGameRecordStoring: Sendable {

    func insert(_ record: DiceGameMatchRecord) async throws
    func update(_ record: DiceGameMatchRecord) async throws
    func deleteRecord(withID id: UUID) async throws
    func record(withID id: UUID) async throws -> DiceGameMatchRecord?
    func records(matching query: DiceGameRecordQuery) async throws -> [DiceGameMatchRecord]
}

nonisolated enum DiceGameRecordStoreError: Error, Equatable, Sendable {

    case duplicateRecord(UUID)
    case recordNotFound(UUID)
    case invalidMatchStructure(UUID)
    case invalidDiceValues
    case invalidStoredRecord(UUID)
    case gameIdentityMismatch(UUID)
    case immutableSessionChanged(UUID)
}
