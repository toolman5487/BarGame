//
//  ViewFactory.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/11.
//

import Foundation
import UIKit

@MainActor
enum ViewFactory {

    static func makeButton() -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.prominentGlass()
        configuration.baseBackgroundColor = .clear
        configuration.cornerStyle = .large
        configuration.titleAlignment = .center
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .preferredFont(forTextStyle: .subheadline)
            return outgoing
        }
        button.configuration = configuration
        button.isUserInteractionEnabled = false
        return button
    }
}
