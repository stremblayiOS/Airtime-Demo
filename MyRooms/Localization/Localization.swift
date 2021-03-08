//
//  Localization.swift
//  MyRooms
//
//  Created by Germán Azcona on 08/03/2021.
//

import Foundation

/// Defines a localizable protocol for easily creating localization keys
protocol Localizable: RawRepresentable where RawValue == String {
}

/// Default implementation
extension Localizable {

    var localized: String { NSLocalizedString(rawValue, comment: "") }

    func localized(args: CVarArg...) -> String {
        String(format: localized, locale: Locale.current, arguments: args)
    }
}
