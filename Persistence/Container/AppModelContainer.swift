//
//  AppModelContainer.swift
//  BarGame
//
//  Created by Codex on 2026/8/14.
//

import Foundation
import SwiftData

nonisolated enum AppModelContainer {

    static let shared: ModelContainer = {
        do {
            return try make()
        } catch {
            fatalError("Unable to create the SwiftData store: \(error.localizedDescription)")
        }
    }()

    static func make(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: BarGameSchemaV1.self)
        let configuration = ModelConfiguration(
            "BarGame",
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            cloudKitDatabase: .none
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: BarGameMigrationPlan.self,
            configurations: configuration
        )
    }
}
