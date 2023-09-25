//
//  UIColor + Ext.swift
//  MusicApp
//
//  Created by Nhat on 5/8/23.
//

import Foundation
import SwiftUI

public extension Color {
    init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        self.init(red: Double(red) / 255.0,
                  green: Double(red) / 255.0,
                  blue: Double(blue) / 255.0,
                  opacity: Double(alpha))
    }
    
    init(rgb: Int, alpha: CGFloat = 1.0) {
        self.init(red: Double((rgb >> 16) & 0xFF) / 255.0,
                  green: Double((rgb >> 8) & 0xFF) / 255.0,
                  blue: Double(rgb & 0xFF) / 255.0,
                  opacity: alpha)
    }
    
    init?(hexString: String) {
        var chars = Array(hexString.hasPrefix("#") ? hexString.dropFirst() : hexString[...])
        let red, green, blue, alpha: CGFloat
        switch chars.count {
        case 3:
            chars = chars.flatMap({ [$0, $0] })
            fallthrough
        case 6:
            chars = ["F", "F"] + chars
            fallthrough
        case 8:
            alpha = Double(strtoul(String(chars[0...1]), nil, 16)) / 255
            red = Double(strtoul(String(chars[2...3]), nil, 16)) / 255
            green = Double(strtoul(String(chars[4...5]), nil, 16)) / 255
            blue = Double(strtoul(String(chars[6...7]), nil, 16)) / 255
        default:
            return nil
        }
        
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    // Color using hexColor
    init(hexString: String, alpha: CGFloat = 1.0) {
        var mHexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        mHexString = mHexString.replacingOccurrences(of: "#",
                                                     with: "",
                                                     options: NSString.CompareOptions.literal,
                                                     range: nil).uppercased()
        
        if mHexString.count < 6 {
            // set for default color
            mHexString = "#1D89DA"
        }
        
        if mHexString.hasPrefix("#") {
            mHexString = String(mHexString.dropFirst())
        }
        
        if mHexString.count == 6 {
            var rgbValue: UInt64 = 0
            Scanner(string: mHexString).scanHexInt64(&rgbValue)
            self.init(red: Double((rgbValue & 0xFF0000) >> 16) / 255,
                      green: Double((rgbValue & 0x00FF00) >> 8) / 255,
                      blue: Double((rgbValue & 0x0000FF)) / 255,
                      opacity: alpha)
        } else {
            var rgbValue: UInt64 = 0
            Scanner(string: mHexString).scanHexInt64(&rgbValue)
            self.init(red: Double((rgbValue & 0xFF000000) >> 24) / 255,
                      green: Double((rgbValue & 0x00FF00) >> 16) / 255,
                      blue: Double((rgbValue & 0xFF00) >> 8) / 255,
                      opacity: Double(rgbValue & 0x0FF) / 255)
        }
    }
}


//MARK: - Extenstion Color

extension Color {
    static let backgroundColor: Color = Color(hexString: "#1C1C1E", alpha: 1.0)
    static let whiteAlpha30: Color = Color(hexString: "#FFFFFF", alpha: 0.3)
    static let headerBackground: Color = Color(hexString: "#26292D", alpha: 1.0)
    static let bottomBackground: Color = Color(hexString: "#41464B", alpha: 1.0)
}

