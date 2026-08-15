//
//  GameLocationProviderError.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

nonisolated enum GameLocationProviderError: Error, Equatable, Sendable {

    case servicesDisabled
    case authorizationDenied
    case authorizationRestricted
    case locationUnavailable
    case timedOut
    case reverseGeocodingFailed
}
