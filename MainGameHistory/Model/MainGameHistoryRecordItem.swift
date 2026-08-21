//
//  MainGameHistoryRecordItem.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

nonisolated struct MainGameHistoryRecordItem: Equatable, Identifiable, Sendable {

    let id: UUID
    let gameID: DiceGameID
    let outcome: MatchOutcome
    let outcomeText: String
    let resultText: String
    let gameTitleText: String
    let timeText: String

    init(
        record: DiceGameMatchRecord,
        calendar: Calendar = .current
    ) {
        id = record.id
        gameID = record.gameID
        outcome = record.outcome
        switch record.outcome {
        case .win:
            outcomeText = "勝"

        case .loss:
            outcomeText = "敗"

        case .draw:
            outcomeText = "平"
        }

        resultText = "\(record.roundWins) - \(record.roundLosses)"
        gameTitleText = record.gameID.title

        timeText = Self.makeDateText(
            for: record.playedAt,
            calendar: calendar
        )
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

}
