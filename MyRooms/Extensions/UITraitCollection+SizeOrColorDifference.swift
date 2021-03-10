//
//  TraitCollection.swift
//  MyRooms
//
//  Created by Germán Azcona on 10/03/2021.
//

import UIKit

extension UITraitCollection {

    func hasDifferentSizeOrColor(comparedTo previousTraitCollection: UITraitCollection?) -> Bool {

        var hasDifference = false

        if #available(iOS 13.0, *),
            hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            hasDifference = true
        }
        if preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            hasDifference = true
        }

        return hasDifference
    }
}
