//
//  DataAccessError.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-02-16.
//

enum DataAccessError: Error {
    case remote(error: RemoteError)
    case database
}

enum RemoteError: Error, CustomStringConvertible {

    case internalServerError
    case unauthorized
    case forbidden
    case notFound
    case invalidData

    init?(statusCode: Int) {
        switch statusCode {
        case 401:
            self = .unauthorized
        case 403:
            self = .forbidden
        case 404:
            self = .notFound
        case 422:
            self = .invalidData
        case 500...599:
            self = .internalServerError
        default:
            return nil
        }
    }

    var description: String {
        switch self {
        case .internalServerError:
            return "Internal server error"
        case .forbidden:
            return "Forbidden"
        case .unauthorized:
            return "Unauthorized"
        case .notFound:
            return "Not found"
        case .invalidData:
            return "Data could not be processed"
        }
    }
}
