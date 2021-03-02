//
//  DataAccessService2.swift
//  MyRooms
//
//  Created by Germán Azcona on 02/03/2021.
//

import Foundation
import Combine
import CoreData
import Alamofire

typealias RemoteRequest = RemoteDataAccessor
typealias LocalRequest = LocalDataAccessor

class DataAccessRequest<T> {

    var remoteRequest: RemoteRequest //rename to RemoteRequest? because delete is not an accessor is an request or operation
    var localRequest: LocalRequest //rename to LocalRequest?

    init(remote: RemoteRequest, local: LocalRequest) {
        self.remoteRequest = remote
        self.localRequest = local
    }
}

struct Endpoint: RemoteDataAccessor {

    var method: Alamofire.HTTPMethod
    var path: String
    var parameters: Any?

    func baseUrl() throws -> URL {
        guard let baseUrl = URL(string: "INSERT BASE URL") else {
            throw NSError()
        }
        return baseUrl
    }

    func asURLRequest() throws -> URLRequest {
        var urlRequest = URLRequest(url: try baseUrl().appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue

        switch parameters {
        case let parameters as Parameters:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
        case let encodable as Encodable:
            if let data = encodable.encodeAsJSONData(),
               let parameters = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Parameters {
                urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
            }
        default: break
        }
        return urlRequest
    }
}

extension Encodable {
    func encodeAsJSONData() -> Data? { try? JSONEncoder().encode(self) }
}

class RoomRequests {

    static var all = DataAccessRequest<[Room]>(
        remote: Endpoint(method: .get, path: "/rooms", parameters: nil),
        local: (object: nil, id: nil, filter: nil, propertySortKey: nil, ascending: true)
    )

    static func create(room: Room) -> DataAccessRequest<Room> {
        DataAccessRequest<Room>(
            remote: Endpoint(method: .post, path: "/room/new", parameters: room),
            local: (object: nil, id: nil, filter: nil, propertySortKey: nil, ascending: true)
        )
    }

    static func room(id: Int) -> DataAccessRequest<Room> {
        DataAccessRequest<Room>(
            remote: Endpoint(method: .get, path: "/room", parameters: ["id": id]),
            local: (object: nil, id: nil, filter: nil, propertySortKey: nil, ascending: true)
        )
    }
}

struct DataAccessService2 {

    // Ties nsmanagedobject type in DataAccessRequest into
    func execute<T>(request: DataAccessRequest<T>, _ closure: ((Result<T, DataAccessError>) -> Void)?) {

        //determine if it's a get, update, create or delete and do the right thing.

    }

    func test() {

        //More readable and less ambiguous. Harder to missuse as you can't getObjects and pass a createRequest.
        execute(request: RoomRequests.all) { (result: Result<[Room], DataAccessError>) in

        }
    }

}
