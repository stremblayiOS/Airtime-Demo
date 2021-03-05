//
//  DataAccessError.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-02-16.
//

import Alamofire

enum DataAccessError: Error {
    case remote(error: AFError)
    case database
}
