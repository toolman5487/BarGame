//
//  MatchDetailLocationGeocoder.swift
//  BarGame
//
//  Created by Codex on 2026/8/21.
//

import CoreLocation
import Foundation
import MapKit

nonisolated protocol MatchDetailLocationGeocoding: Sendable {

    func coordinate(for address: String) async throws -> GameCoordinate
}

nonisolated enum MatchDetailLocationGeocodingError: Error, Equatable, Sendable {

    case invalidAddress
    case locationNotFound
}

nonisolated struct MapKitMatchDetailLocationGeocoder: MatchDetailLocationGeocoding {

    func coordinate(for address: String) async throws -> GameCoordinate {
        guard let request = MKGeocodingRequest(addressString: address) else {
            throw MatchDetailLocationGeocodingError.invalidAddress
        }

        let mapItems = try await request.mapItems
        guard let coordinate = mapItems.first?.location.coordinate,
              CLLocationCoordinate2DIsValid(coordinate)
        else {
            throw MatchDetailLocationGeocodingError.locationNotFound
        }

        return GameCoordinate(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}
