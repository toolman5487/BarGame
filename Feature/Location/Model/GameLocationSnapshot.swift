//
//  GameLocationSnapshot.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

nonisolated struct GameLocationSnapshot: Codable, Equatable, Sendable {

    let area: String?
    let detailAddress: String

    init(address: String, locality: String?) {
        let components = Self.makeAddressComponents(
            from: address,
            fallbackArea: locality
        )
        self.init(
            area: components.area,
            detailAddress: components.detailAddress
        )
    }

    private init(area: String?, detailAddress: String) {
        self.area = area
        self.detailAddress = detailAddress
    }

    private enum CodingKeys: String, CodingKey {
        case area
        case detailAddress
        case legacyAddress = "address"
        case legacyName = "name"
        case legacyLocality = "locality"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let detailAddress = try container.decodeIfPresent(
            String.self,
            forKey: .detailAddress
        ) {
            self.init(
                area: try container.decodeIfPresent(
                    String.self,
                    forKey: .area
                ),
                detailAddress: detailAddress
            )
        } else {
            let address = try container.decodeIfPresent(
                String.self,
                forKey: .legacyAddress
            ) ?? container.decode(String.self, forKey: .legacyName)
            let locality = try container.decodeIfPresent(
                String.self,
                forKey: .legacyLocality
            )
            self.init(address: address, locality: locality)
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(area, forKey: .area)
        try container.encode(detailAddress, forKey: .detailAddress)
    }

    private static func makeAddressComponents(
        from rawAddress: String,
        fallbackArea: String?
    ) -> (area: String?, detailAddress: String) {
        let address = trimmingAddressPrefix(from: rawAddress)

        if let components = makeTaiwanAddressComponents(from: address) {
            return components
        }

        guard let fallbackArea = normalizedArea(fallbackArea) else {
            return (nil, address)
        }

        let detailAddress = removingAreaPrefix(
            fallbackArea,
            from: address
        )
        return (
            fallbackArea,
            detailAddress.isEmpty ? address : detailAddress
        )
    }

    private static func makeTaiwanAddressComponents(
        from address: String
    ) -> (area: String, detailAddress: String)? {
        guard let cityEndIndex = address.firstIndex(where: {
            $0 == "縣" || $0 == "市"
        }) else {
            return nil
        }

        let cityTerminator = address[cityEndIndex]
        let districtStartIndex = address.index(after: cityEndIndex)
        let maximumDistrictEndIndex = address.index(
            districtStartIndex,
            offsetBy: 6,
            limitedBy: address.endIndex
        ) ?? address.endIndex
        let districtTerminators: Set<Character> = cityTerminator == "縣"
            ? ["市", "鄉", "鎮", "區"]
            : ["區"]
        let districtRange = districtStartIndex..<maximumDistrictEndIndex

        guard let districtEndIndex = address[districtRange].firstIndex(
            where: { districtTerminators.contains($0) }
        ) else {
            return nil
        }

        let detailStartIndex = address.index(after: districtEndIndex)
        let detailAddress = trimmingSeparators(
            from: String(address[detailStartIndex...])
        )
        guard !detailAddress.isEmpty else { return nil }

        let area = normalizedArea(
            String(address[...districtEndIndex])
        )
        guard let area else { return nil }
        return (area, detailAddress)
    }

    private static func trimmingAddressPrefix(from address: String) -> String {
        var result = address.trimmingCharacters(in: .whitespacesAndNewlines)
        result.removeFirst(
            result.prefix { $0.isNumber || $0.isWhitespace }.count
        )

        for country in ["台灣", "臺灣"] where result.hasPrefix(country) {
            result.removeFirst(country.count)
            break
        }

        return trimmingSeparators(from: result)
    }

    private static func removingAreaPrefix(
        _ area: String,
        from address: String
    ) -> String {
        let canonicalArea = canonicalized(area)
        let canonicalAddress = canonicalized(address)
        guard canonicalAddress.hasPrefix(canonicalArea) else {
            return address
        }

        let prefixEndIndex = address.index(
            address.startIndex,
            offsetBy: area.count,
            limitedBy: address.endIndex
        ) ?? address.endIndex
        return trimmingSeparators(from: String(address[prefixEndIndex...]))
    }

    private static func normalizedArea(_ area: String?) -> String? {
        guard let area else { return nil }
        let normalized = area
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "，", with: "")
        return normalized.isEmpty ? nil : normalized
    }

    private static func canonicalized(_ value: String) -> String {
        value.replacingOccurrences(of: "臺", with: "台")
    }

    private static func trimmingSeparators(from value: String) -> String {
        value.trimmingCharacters(
            in: .whitespacesAndNewlines.union(
                CharacterSet(charactersIn: ",，")
            )
        )
    }
}
