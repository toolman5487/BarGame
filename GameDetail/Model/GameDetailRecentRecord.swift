//
//  GameDetailRecentRecord.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/13.
//

import Foundation

// MARK: - Record

nonisolated struct GameDetailRecentRecord: Equatable, Identifiable, Sendable {

    let id: UUID
    let outcome: GameOutcome
    let points: Int
    let subtitle: String

    var resultText: String {
        "\(points) 點"
    }

    init(
        record: DiceGameMatchRecord,
        calendar: Calendar = .current
    ) throws {
        guard let diceResult = record.latestConfirmedRoll?.result else {
            throw DiceGameMatchRecordError.missingConfirmedRoll(record.id)
        }

        id = record.id
        outcome = record.outcome
        points = diceResult.total
        subtitle = Self.makeSubtitle(for: record.playedAt, calendar: calendar)
    }

    private static func makeSubtitle(
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
            .dateTime.month(.twoDigits).day(.twoDigits).hour().minute()
        )
    }
}

// MARK: - State

nonisolated enum GameDetailRecentRecordsState: Equatable, Sendable {

    static let maximumRecordCount = 10

    case loading
    case empty
    case content([GameDetailRecentRecord])
    case error(message: String)
}
