//
//  CoreLocationGameLocationProvider.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import CoreLocation
import Foundation
import MapKit

nonisolated struct CoreLocationGameLocationProvider: GameLocationProviding {

    private enum Configuration {
        static let timeout: Duration = .seconds(5)
    }

    func authorizationState() -> GameLocationAuthorizationState {
        switch CLLocationManager().authorizationStatus {
        case .notDetermined:
            return .notDetermined

        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized

        case .denied:
            return .denied

        case .restricted:
            return .restricted

        @unknown default:
            return .restricted
        }
    }

    func currentLocationSnapshot() async throws -> GameCurrentLocationSnapshot {
        try validateAuthorizationState()
        let location = try await currentLocation()
        let place = try await reverseGeocodePlace(for: location)
        return GameCurrentLocationSnapshot(
            coordinate: GameCoordinate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ),
            place: place,
            horizontalAccuracy: location.horizontalAccuracy,
            capturedAt: location.timestamp
        )
    }

    private func validateAuthorizationState() throws {
        switch authorizationState() {
        case .notDetermined, .authorized:
            return

        case .denied:
            throw GameLocationProviderError.authorizationDenied

        case .restricted:
            throw GameLocationProviderError.authorizationRestricted

        case .servicesDisabled:
            throw GameLocationProviderError.servicesDisabled
        }
    }

    private func currentLocation() async throws -> CLLocation {
        let priority = Task<Never, Never>.currentPriority
        return try await withThrowingTaskGroup(of: CLLocation.self) { group in
            group.addTask(priority: priority) {
                try await waitForLocationUpdate()
            }
            group.addTask(priority: priority) {
                try await Task.sleep(for: Configuration.timeout)
                throw GameLocationProviderError.timedOut
            }

            guard let location = try await group.next() else {
                throw GameLocationProviderError.locationUnavailable
            }
            group.cancelAll()
            return location
        }
    }

    private func waitForLocationUpdate() async throws -> CLLocation {
        let updates = CLLocationUpdate.liveUpdates(.default)

        for try await update in updates {
            try Task.checkCancellation()

            if update.authorizationDeniedGlobally {
                throw GameLocationProviderError.servicesDisabled
            }

            if update.authorizationRestricted {
                throw GameLocationProviderError.authorizationRestricted
            }

            if update.authorizationDenied {
                throw GameLocationProviderError.authorizationDenied
            }

            if update.locationUnavailable {
                throw GameLocationProviderError.locationUnavailable
            }

            guard let location = update.location,
                  location.horizontalAccuracy >= 0
            else { continue }

            return location
        }

        throw GameLocationProviderError.locationUnavailable
    }

    private func reverseGeocodePlace(
        for location: CLLocation
    ) async throws -> GameLocationSnapshot {
        guard let request = MKReverseGeocodingRequest(location: location) else {
            throw GameLocationProviderError.reverseGeocodingFailed
        }

        let mapItems: [MKMapItem]
        do {
            mapItems = try await request.mapItems
        } catch {
            throw GameLocationProviderError.reverseGeocodingFailed
        }

        guard let mapItem = mapItems.first,
              let address = firstNonemptyString(
                mapItem.addressRepresentations?.fullAddress(
                    includingRegion: false,
                    singleLine: true
                ),
                mapItem.address?.fullAddress,
                mapItem.address?.shortAddress,
                mapItem.name
            )
        else {
            throw GameLocationProviderError.reverseGeocodingFailed
        }

        let locality = firstNonemptyString(
            mapItem.addressRepresentations?.cityName,
            mapItem.addressRepresentations?.cityWithContext
        )
        return GameLocationSnapshot(
            address: address,
            locality: locality,
            coordinate: GameCoordinate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        )
    }

    private func firstNonemptyString(_ values: String?...) -> String? {
        values.lazy
            .compactMap { value -> String? in
                guard let value else { return nil }
                let trimmedValue = value.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                return trimmedValue.isEmpty ? nil : trimmedValue
            }
            .first
    }
}
