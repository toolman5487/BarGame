//
//  MainGameHistoryRecordItem.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

nonisolated struct MainGameHistoryRecordItem: Equatable, Identifiable, Sendable {

    let id: UUID
    let gameTitle: String
    let outcome: GameOutcome
    let outcomeText: String
    let resultText: String
    let metadataText: String

    init(
        record: DiceGameMatchRecord,
        calendar: Calendar = .current
    ) throws {
        guard let diceResult = record.latestConfirmedRoll?.result else {
            throw DiceGameMatchRecordError.missingConfirmedRoll(record.id)
        }

        id = record.id
        gameTitle = record.gameID.title
        outcome = record.outcome
        outcomeText = record.outcome == .win ? "勝" : "敗"

        let diceText = diceResult.values
            .map(String.init)
            .joined(separator: "、")
        switch record.rounds.count {
        case 1:
            resultText = "\(diceResult.total) 點 · \(diceText)"

        default:
            resultText = "\(record.rounds.count) 回合 · 最後 \(diceResult.total) 點"
        }

        let dateText = Self.makeDateText(
            for: record.playedAt,
            calendar: calendar
        )
        let locationText = Self.makeLocationText(
            from: record.sessionContext.event.location
        )
        metadataText = "\(dateText) · \(locationText)"
    }

    private static func makeDateText(
        for date: Date,
        calendar: Calendar
    ) -> String {
        let time = date.formatted(.dateTime.hour().minute())

        if calendar.isDateInToday(date) {
            return "今天 \(time)"
        }
        if calendar.isDateInYesterday(date) {
            return "昨天 \(time)"
        }

        return date.formatted(
            .dateTime.year().month(.twoDigits).day(.twoDigits).hour().minute()
        )
    }

    private static func makeLocationText(
        from location: GameLocationSnapshot?
    ) -> String {
        guard let location else {
            return "未記錄地點"
        }

        guard let locality = location.locality,
              locality != location.name else {
            return location.name
        }

        return "\(locality)／\(location.name)"
    }
}
