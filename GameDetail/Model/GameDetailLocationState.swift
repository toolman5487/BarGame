//
//  GameDetailLocationState.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import Foundation

nonisolated enum GameDetailLocationState: Equatable, Sendable {

    case notRequested
    case requestingAuthorization
    case locating
    case located(GameLocationSnapshot)
    case servicesDisabled
    case authorizationDenied
    case authorizationRestricted
    case locationUnavailable
    case timedOut
    case reverseGeocodingFailed

    var isRequestInProgress: Bool {
        switch self {
        case .requestingAuthorization:
            return true

        case .locating:
            return true

        case .notRequested:
            return false

        case .located:
            return false

        case .servicesDisabled:
            return false

        case .authorizationDenied:
            return false

        case .authorizationRestricted:
            return false

        case .locationUnavailable:
            return false

        case .timedOut:
            return false

        case .reverseGeocodingFailed:
            return false
        }
    }

    var snapshot: GameLocationSnapshot? {
        switch self {
        case .located(let snapshot):
            return snapshot

        case .notRequested:
            return nil

        case .requestingAuthorization:
            return nil

        case .locating:
            return nil

        case .servicesDisabled:
            return nil

        case .authorizationDenied:
            return nil

        case .authorizationRestricted:
            return nil

        case .locationUnavailable:
            return nil

        case .timedOut:
            return nil

        case .reverseGeocodingFailed:
            return nil
        }
    }

    var presentation: GameDetailLocationPresentation {
        switch self {
        case .notRequested:
            return GameDetailLocationPresentation(
                title: "尚未取得地點",
                subtitle: "取得目前位置並加入這次賽局",
                actionTitle: "定位",
                actionSystemName: "location.fill",
                isActionEnabled: true
            )

        case .requestingAuthorization:
            return GameDetailLocationPresentation(
                title: "等待定位權限",
                subtitle: "請選擇是否允許 App 使用目前位置",
                actionTitle: "正在取得位置",
                actionSystemName: "location.fill.viewfinder",
                isActionEnabled: false
            )

        case .locating:
            return GameDetailLocationPresentation(
                title: "正在取得地點",
                subtitle: "只會記錄這次賽局的位置",
                actionTitle: "正在取得位置",
                actionSystemName: "location.fill.viewfinder",
                isActionEnabled: false
            )

        case .located(let snapshot):
            return GameDetailLocationPresentation(
                title: snapshot.name,
                subtitle: snapshot.locality ?? "已加入這次賽局",
                actionTitle: "更新",
                actionSystemName: "location.fill",
                isActionEnabled: true
            )

        case .servicesDisabled:
            return GameDetailLocationPresentation(
                title: "定位服務已關閉",
                subtitle: "請至系統設定開啟定位服務",
                actionTitle: "重試",
                actionSystemName: "location.slash.fill",
                isActionEnabled: true
            )

        case .authorizationDenied:
            return GameDetailLocationPresentation(
                title: "未允許定位權限",
                subtitle: "請至系統設定允許 BarGame 使用位置",
                actionTitle: "重試",
                actionSystemName: "location.slash.fill",
                isActionEnabled: true
            )

        case .authorizationRestricted:
            return GameDetailLocationPresentation(
                title: "定位功能受到限制",
                subtitle: "目前裝置不允許 App 取得位置",
                actionTitle: "無法使用定位",
                actionSystemName: "location.slash.fill",
                isActionEnabled: false
            )

        case .locationUnavailable:
            return GameDetailLocationPresentation(
                title: "目前無法取得位置",
                subtitle: "請移至訊號較佳的位置後再試",
                actionTitle: "重試",
                actionSystemName: "location.slash.fill",
                isActionEnabled: true
            )

        case .timedOut:
            return GameDetailLocationPresentation(
                title: "取得位置逾時",
                subtitle: "請稍後重新定位",
                actionTitle: "重試",
                actionSystemName: "location.slash.fill",
                isActionEnabled: true
            )

        case .reverseGeocodingFailed:
            return GameDetailLocationPresentation(
                title: "無法辨識地點名稱",
                subtitle: "請確認網路連線後再試",
                actionTitle: "重試",
                actionSystemName: "location.slash.fill",
                isActionEnabled: true
            )
        }
    }
}

nonisolated struct GameDetailLocationPresentation: Equatable, Sendable {

    let title: String
    let subtitle: String
    let actionTitle: String
    let actionSystemName: String
    let isActionEnabled: Bool
}
