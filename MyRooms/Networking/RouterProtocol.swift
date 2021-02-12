//
//  Router.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2018-01-21.
//  Copyright © 2018 Samuel Tremblay. All rights reserved.
//

import Alamofire
import CoreData

protocol RestfulObject: Codable {
    static var path: String { get }
}

typealias Route = (method: Alamofire.HTTPMethod, path: String, parameters: Any)

protocol RouterProtocol {
    
    func baseUrl() throws -> URL
    func route() throws -> Route
}

extension RouterProtocol {
    
    func baseUrl() throws -> URL {
        guard let baseUrl = URL(string: "INSERT BASE URL") else {
            throw NSError()
        }
        return baseUrl
    }
}
