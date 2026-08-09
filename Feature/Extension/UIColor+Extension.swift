//
//  UIColor+Extension.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/9.
//

import UIKit

extension UIColor {
    static func hex(_ value: String) -> UIColor? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let hexValue = trimmedValue.hasPrefix("#")
            ? String(trimmedValue.dropFirst())
            : trimmedValue

        guard hexValue.count == 6 || hexValue.count == 8,
              let colorValue = UInt64(hexValue, radix: 16)
        else {
            return nil
        }

        let hasAlpha = hexValue.count == 8
        let redShift = hasAlpha ? 24 : 16
        let greenShift = hasAlpha ? 16 : 8
        let blueShift = hasAlpha ? 8 : 0
        let alpha = hasAlpha ? colorValue & 0xFF : 0xFF

        return UIColor(
            red: CGFloat((colorValue >> redShift) & 0xFF) / 255,
            green: CGFloat((colorValue >> greenShift) & 0xFF) / 255,
            blue: CGFloat((colorValue >> blueShift) & 0xFF) / 255,
            alpha: CGFloat(alpha) / 255
        )
    }
}
