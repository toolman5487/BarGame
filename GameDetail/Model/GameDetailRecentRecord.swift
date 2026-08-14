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
    let playerScore: Int
    let opponentScore: Int
    let subtitle: String

    var scoreText: String {
        "\(playerScore) - \(opponentScore)"
    }
}

// MARK: - State

nonisolated enum GameDetailRecentRecordsState: Equatable, Sendable {

    static let maximumRecordCount = 10

    case empty
    case content([GameDetailRecentRecord])
    case error(message: String)

    static func sample() -> GameDetailRecentRecordsState {
        .content([
            GameDetailRecentRecord(
                id: UUID(),
                outcome: .win,
                playerScore: 2,
                opponentScore: 1,
                subtitle: "今天 21:14"
            ),
            GameDetailRecentRecord(
                id: UUID(),
                outcome: .loss,
                playerScore: 0,
                opponentScore: 2,
                subtitle: "今天 18:02"
            ),
            GameDetailRecentRecord(
                id: UUID(),
                outcome: .win,
                playerScore: 2,
                opponentScore: 1,
                subtitle: "昨天 23:41"
            ),
            GameDetailRecentRecord(
                id: UUID(),
                outcome: .win,
                playerScore: 3,
                opponentScore: 2,
                subtitle: "昨天 20:15"
            ),
            GameDetailRecentRecord(
                id: UUID(),
                outcome: .win,
                playerScore: 2,
                opponentScore: 0,
                subtitle: "8/11 22:08"
            ),
            GameDetailRecentRecord(
                id: UUID(),
                outcome: .loss,
                playerScore: 1,
                opponentScore: 2,
                subtitle: "8/11 19:33"
            ),
            GameDetailRecentRecord(
                id: UUID(),
                outcome: .win,
                playerScore: 3,
                opponentScore: 2,
                subtitle: "8/10 16:27"
            ),
            GameDetailRecentRecord(
                id: UUID(),
                outcome: .win,
                playerScore: 4,
                opponentScore: 3,
                subtitle: "8/09 21:55"
            ),
            GameDetailRecentRecord(
                id: UUID(),
                outcome: .loss,
                playerScore: 0,
                opponentScore: 1,
                subtitle: "8/08 14:12"
            ),
            GameDetailRecentRecord(
                id: UUID(),
                outcome: .win,
                playerScore: 3,
                opponentScore: 1,
                subtitle: "8/07 23:01"
            ),
        ])
    }
}
