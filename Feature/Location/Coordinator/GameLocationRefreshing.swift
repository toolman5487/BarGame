//
//  GameLocationRefreshing.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

@MainActor
protocol GameLocationRefreshing: AnyObject {

    func refreshLocation() async throws
}
