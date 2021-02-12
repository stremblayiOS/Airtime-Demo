//
//  RepositoryRouter.swift
//  Github Trends
//
//  Created by Samuel Tremblay on 2018-01-21.
//  Copyright © 2018 Samuel Tremblay. All rights reserved.
//

import Alamofire

enum RepositoryRouter: URLRequestConvertible, RouterProtocol {

    case getAll
    case getReadme(repository: Repository)
    case getRepositoryDetails(name: String)
    
    func route() throws -> Route {
        switch self {
        case .getAll:
            return (.get, "repos", [:])
        case .getReadme(let repository):
            return (.get, "repos/\(repository.fullName ?? "")/readme", [:])
        case .getRepositoryDetails(let name):
            return (.get, "repos/\(name)", [:])
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let route = try self.route()
        var urlRequest = URLRequest(url: try baseUrl().appendingPathComponent(route.path))
        urlRequest.httpMethod = route.method.rawValue
        
        let parameters = route.parameters as? Parameters
        switch self {
            case .getAll, .getReadme, .getRepositoryDetails:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        }
        return urlRequest
    }
}
