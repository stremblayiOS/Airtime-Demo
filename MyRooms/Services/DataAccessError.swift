//
//  DataAccessError.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-02-16.
//

import Alamofire

enum DataAccessError: Error {
    case remote(error: AFError)
    case remoteResponseUnexpected
    case database(error: NSError)

    /// The DataAccessRequest is invalid as it's missing the remote and local request. It needs at least one.
    case dataAccessRequestInvalid
}
