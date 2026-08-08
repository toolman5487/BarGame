//
//  AppLogger.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/2.
//

import Foundation
import OSLog

// MARK: - AppLogCategory

nonisolated enum AppLogCategory: String, CaseIterable, Sendable {

    case app = "App"
    case lifecycle = "Lifecycle"
    case network = "Network"
    case connectivity = "Connectivity"
    case decoding = "Decoding"
    case persistence = "Persistence"
    case keychain = "Keychain"
    case authentication = "Authentication"
    case navigation = "Navigation"
    case ui = "UI"
    case cache = "Cache"
    case performance = "Performance"
    case backgroundTask = "BackgroundTask"
    case notifications = "Notifications"
    case deeplink = "Deeplink"
    case sync = "Sync"
    case media = "Media"
    case analytics = "Analytics"
    case security = "Security"
    case thirdParty = "ThirdParty"
    case domain = "Domain"
    case search = "Search"
    case configuration = "Configuration"

    nonisolated var logger: Logger {
        Logger(subsystem: AppLogger.subsystem, category: rawValue)
    }
}

// MARK: - AppLogger

nonisolated enum AppLogger {

    static let subsystem = Bundle.main.bundleIdentifier ?? "willyhsu.co.BarGame"

    static let app = AppLogCategory.app.logger
    static let lifecycle = AppLogCategory.lifecycle.logger
    static let network = AppLogCategory.network.logger
    static let connectivity = AppLogCategory.connectivity.logger
    static let decoding = AppLogCategory.decoding.logger
    static let persistence = AppLogCategory.persistence.logger
    static let keychain = AppLogCategory.keychain.logger
    static let authentication = AppLogCategory.authentication.logger
    static let navigation = AppLogCategory.navigation.logger
    static let ui = AppLogCategory.ui.logger
    static let cache = AppLogCategory.cache.logger
    static let performance = AppLogCategory.performance.logger
    static let backgroundTask = AppLogCategory.backgroundTask.logger
    static let notifications = AppLogCategory.notifications.logger
    static let deeplink = AppLogCategory.deeplink.logger
    static let sync = AppLogCategory.sync.logger
    static let media = AppLogCategory.media.logger
    static let analytics = AppLogCategory.analytics.logger
    static let security = AppLogCategory.security.logger
    static let thirdParty = AppLogCategory.thirdParty.logger
    static let domain = AppLogCategory.domain.logger
    static let search = AppLogCategory.search.logger
    static let configuration = AppLogCategory.configuration.logger
}
