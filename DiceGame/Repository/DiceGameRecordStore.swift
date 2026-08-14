//
//  DiceGameRecordStore.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/14.
//

import Foundation

nonisolated protocol DiceGameRecordStoring: Sendable {

    func save(_ record: DiceGameMatchRecord) async throws
    func records(for gameID: DiceGameID) async -> [DiceGameMatchRecord]
}

actor DiceGameRecordStore: DiceGameRecordStoring {

    static let shared = DiceGameRecordStore()

    private var recordsByGameID: [DiceGameID: [DiceGameMatchRecord]] = [:]

    func save(_ record: DiceGameMatchRecord) {
        recordsByGameID[record.gameID, default: []].insert(record, at: 0)
    }

    func records(for gameID: DiceGameID) -> [DiceGameMatchRecord] {
        recordsByGameID[gameID, default: []]
    }
}
