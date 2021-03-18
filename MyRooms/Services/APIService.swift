//
//  APIService.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2018-01-21.
//  Copyright © 2018 Samuel Tremblay. All rights reserved.
//

import Alamofire

protocol APIServiceProtocol {

    /// Create a data request corresponding to the given URLRequestConvertible object
    ///
    /// - Parameter urlRequestconvertible: URLRequestConvertible object for the request
    /// - Returns: Resulting data request object (JSON data request)
    func dataRequest(for urlRequestconvertible: URLRequestConvertible) -> DataRequest
}

final class APIService: APIServiceProtocol {

    private let session: Session = {
        let session = Session(interceptor: ServiceFactory.resolve(serviceType: AccessTokenAdapter.self))
        return session
    }()
}

internal extension APIService {

    func dataRequest(for urlRequestconvertible: URLRequestConvertible) -> DataRequest {
        session.request(urlRequestconvertible)
    }
}

/// Adapt any outgoing request to protected endpoints to carry the auth token
final class AccessTokenAdapter: RequestInterceptor {

    private let tokenStoreService: TokenStoreServiceProtocol

    init(tokenStoreService: TokenStoreServiceProtocol) {
        self.tokenStoreService = tokenStoreService
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest

        if let token = tokenStoreService.token {
            urlRequest.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        }

        completion(.success(urlRequest))
    }
}
