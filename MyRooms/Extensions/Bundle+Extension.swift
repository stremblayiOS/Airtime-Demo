//
//  Bundle+Extension.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-03-15.
//

import Foundation

extension Bundle {

    class var baseUrlString: String? {
        Bundle.main.infoDictionary?["API_BASE_URL"] as? String
    }
}
