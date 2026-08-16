//
//  GameLocationCoordinating.swift
//  BarGame
//
//  Created by Codex on 2026/8/16.
//

import Combine
import Foundation

@MainActor
protocol GameLocationCoordinating: AnyObject {

    var locationState: AnyPublisher<GameCurrentLocationState, Never> { get }

    func refreshLocation()
    func refreshLocationOnLaunch()
}
