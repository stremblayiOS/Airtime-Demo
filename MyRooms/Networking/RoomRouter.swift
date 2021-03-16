//
//  RoomRouter.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-02-12.
//

import Alamofire

enum RoomRouter: URLRequestConvertible, RouterProtocol {
    case rooms
    case deleteAll
    case create(room: Room)

    func route() -> Route {
        switch self {
        case .rooms:
            return (.get, "/api/v1/rooms", [:])
        case .deleteAll:
            return (.delete, "/rooms", [:])
        case .create(let room):

            // TODO: Move this logic to an extension
            let encoder = JSONEncoder()
            let data = try! encoder.encode(room)
            let parameters = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }!
            // End of TODO

            return (.post, "/rooms", parameters)
        }
    }

    // TODO: move this logic to `APIService`
    func asURLRequest() throws -> URLRequest {
        let route = self.route()
        var urlRequest = URLRequest(url: try baseUrl().appendingPathComponent(route.path))
        urlRequest.httpMethod = route.method.rawValue

//        let parameters = route.parameters as? Parameters
//        switch self {
//        default:
//            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
//        }
        return urlRequest
    }
}
