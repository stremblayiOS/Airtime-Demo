//
//  DataAccessError.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-02-16.
//

import Alamofire

//TODO: Change Error to LocalizedError and implement localizations that are user ready.
enum DataAccessError: Error {

    /// Remote request failed with an AlamoFire error.
    case remote(error: AFError)

    /// Remote response was unexpected. Maybe it couldn't be parsed into a JSON.
    case remoteResponseUnexpected

    /// The database issued an error.
    case database(error: NSError)

    /// The DataAccessRequest is invalid as it's missing the remote and local request. It needs at least one.
    case dataAccessRequestInvalid
}
