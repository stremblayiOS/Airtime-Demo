//
//  DataAccessService.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2020-11-10.
//  Copyright © 2020 Samuel Tremblay. All rights reserved.
//

import Alamofire
import Combine

/// Service protocol definition
protocol DataAccessServiceProtocol {

    /// Create an instance of NSManagedObject along with the desired managed context
    /// Warning: It doesn't save the object. You may want to call this to prepare a `DataAccessor` for `func saveObject()`
    ///
    /// - Parameters:
    ///   - type: The type of the managed object you want to create
    ///
    /// - Returns: A newly created instance ready be saved
    func createObject<T: Object>(_ type: T.Type) -> T

    /// Generic funtion to retrieve an object according to the given data accessor request
    ///
    /// - Parameters:
    ///   - request: The data accessor request used to retrieve the object
    ///   - closure: Callback triggered once the object has been retrieved. If the object, did not previously exsist in the local db, it will now have been downloaded and saved into the db
    func getObject<T>(request: DataAccessRequest, _ closure: ((Result<T, DataAccessError>) -> Void)?) where T: Object

    /// Generic funtion to retrieve all objects according to the given data accessor request
    ///
    /// - Parameters:
    ///   - request: The data accessor request used to retrieve the objects
    ///   - closure: Callback triggered once the objects have been retrieved. If the objects, did not previously exsist in the local db, they will now have been downloaded and saved into the db
    //func getObjects<T>(request: DataAccessRequest, _ closure: ((Result<[T], DataAccessError>) -> Void)?) where T: Object
    func getObjects<T>(type: T.Type, request: DataAccessRequest) -> AnyPublisher<[T], DataAccessError> where T: Object, T: Codable

    /// Generic funtion to create/update an object according to the given data accessor request
    ///
    /// - Parameters:
    ///   - request: The data accessor request used to create/update the object
    ///   - closure: Callback triggered once the object has been created/updated. If the object, did not previously exsist in the local db, it will now have been saved remotely as well as locally
    func saveObject<T>(request: DataAccessRequest, _ closure: ((Result<T, DataAccessError>) -> Void)?) where T: Object

    /// Delete an object according to the given data accessor request
    ///
    /// - Parameters:
    ///   - request: The data accessor request used to create/update the object
    ///   - closure: Callback triggered once the object has been deleted. The object will have been deleted remotely as well locally
    func deleteObject(request: DataAccessRequest, _ closure: ((Result<Void, DataAccessError>) -> Void)?)
}

final class DataAccessService: DataAccessServiceProtocol {

    private let databaseService: DatabaseServiceProtocol
    private let apiService: APIServiceProtocol

    private var cancellableBag = Set<AnyCancellable>()

    required init(databaseService: DatabaseServiceProtocol, apiService: APIServiceProtocol) {
        self.databaseService = databaseService
        self.apiService = apiService
    }

    func createObject<T: Object>(_ type: T.Type) -> T {
        databaseService.createObject(type)
    }

    func getObject<T>(request: DataAccessRequest, _ closure: ((Result<T, DataAccessError>) -> Void)?) where T: Object {

        if let localRequest = request.localRequest, let objectId = localRequest.id {
            let result: Result<T, NSError> = databaseService.getObject(id: objectId)

            switch result {
            case .success(let object):
                closure?(.success(object))
            case .failure(let error):
                closure?(.failure(.database(error: error)))
            }
        }
    }

    func getObjects<T>(request: DataAccessRequest, _ closure: ((Result<[T], DataAccessError>) -> Void)?) where T: Object {

        if let localRequest = request.localRequest {
            let result: Result<[T], NSError> = databaseService.getObjects(predicate: localRequest.filter)

            switch result {
            case .success(let objects):
                closure?(.success(objects))
            case .failure(let error):
                closure?(.failure(.database(error: error)))
            }
        }
    }

    func saveObject<T>(request: DataAccessRequest, _ closure: ((Result<T, DataAccessError>) -> Void)?) where T: Object {
        if let _ = request.localRequest {
            databaseService.save()
        }
    }

    func deleteObject(request: DataAccessRequest, _ closure: ((Result<Void, DataAccessError>) -> Void)?) {
        if let _ = request.localRequest {
            databaseService.deleteObjects(object: request.type, predicate: nil)
        }
    }

    // Combine implementations

    func getObjects<T>(type: T.Type, request: DataAccessRequest) -> AnyPublisher<[T], DataAccessError> where T: Object, T: Codable {

        typealias ResulPublisher = AnyPublisher<[T], DataAccessError>

        switch (request.localRequest, request.remoteRequest) {
        case (nil, nil):
            return Fail(outputType: [T].self, failure: DataAccessError.dataAccessRequestInvalid)
                .eraseToAnyPublisher()

        case (nil, let remoteRequest?):
            return getObjectsPublisher(for: remoteRequest, dataAccessRequest: request)

        case (let localRequest?, nil):
            return getObjectsPublisher(for: localRequest, dataAccessRequest: request)

        case (let localRequest?, let remoteRequest?):
            let local: ResulPublisher = getObjectsPublisher(for: localRequest, dataAccessRequest: request)
            let remote: ResulPublisher = getObjectsPublisher(for: remoteRequest, dataAccessRequest: request)

            return Publishers
                .Merge(local, remote)
                .eraseToAnyPublisher()
        }
    }

//
//    func getObjects<T>(request: DataAccessRequestConvertible, _ closure: ((Response<Results<T>, DataAccessError>) -> Void)?) where T : Object, T : Decodable {
//        if let result: Results<T> = fetchObjectsWithRequest(request: request), !result.isEmpty {
//            closure?(.success(result))
//        } else {
//            apiService?.dataRequest(for: request.remoteDataAccessor).responseArray(completionHandler: { [weak self] (response: DataResponse<[T]>) in
//                switch response.result {
//                case .success(let objects):
//                    do {
//                        try self?.databaseService?.commitTransactions {
//                            self?.databaseService?.saveObjects(objects: objects)
//                        }
//                        if let result: Results<T> = self?.fetchObjectsWithRequest(request: request) {
//                            closure?(.success(result))
//                        }
//                    } catch {
//                        closure?(.failure(.database))
//                    }
//                case .failure:
//                    guard let statusCode = response.response?.statusCode, let errorType = RemoteError(statusCode: statusCode) else {
//                        return
//                    }
//                    closure?(.failure(.remote(error: errorType)))
//                }
//            })
//        }
//    }
//
//    func getObject<T>(request: DataAccessRequestConvertible, _ closure: ((Response<T, DataAccessError>) -> Void)?) where T: Codable, T: Object {
//        apiService?.dataRequest(for: request.remoteDataAccessor).responseObject { [weak self] (response: DataResponse<T>) in
//            switch response.result {
//            case .success(let object):
//                do {
//                    try self?.databaseService?.commitTransactions {
//                        self?.databaseService?.saveObject(object: object)
//                    }
//                    closure?(.success(object))
//                } catch {
//                    closure?(.failure(.database))
//                }
//            case .failure:
//                guard let statusCode = response.response?.statusCode, let errorType = RemoteError(statusCode: statusCode) else {
//                    return
//                }
//                closure?(.failure(.remote(error: errorType)))
//            }
//        }
//    }
//
//    func saveObject<T>(request: DataAccessRequestConvertible, _ closure: ((Response<T, DataAccessError>) -> Void)?) where T: Codable, T: Object {
//        apiService?.dataRequest(for: request.remoteDataAccessor).responseObject { [weak self] (response: DataResponse<T>) in
//            switch response.result {
//            case .success(let object):
//                do {
//                    try self?.databaseService?.commitTransactions {
//                        self?.databaseService?.saveObject(object: object)
//                    }
//                    closure?(.success(object))
//                } catch {
//                    closure?(.failure(.database))
//                }
//            case .failure:
//                guard let statusCode = response.response?.statusCode, let errorType = RemoteError(statusCode: statusCode) else {
//                    return
//                }
//                closure?(.failure(.remote(error: errorType)))
//            }
//        }
//    }
//
//    func deleteObject(request: DataAccessRequestConvertible, _ closure: ((Response<Void, DataAccessError>) -> Void)?) {
//        apiService?.dataRequest(for: request.remoteDataAccessor).response() { response in
//            if let _ = response.error {
//                guard let statusCode = response.response?.statusCode, let errorType = RemoteError(statusCode: statusCode) else {
//                    return
//                }
//                closure?(.failure(.remote(error: errorType)))
//                return
//            }
//            guard let object = request.localDataAccessor.object else {
//                closure?(.failure(.database))
//                return
//            }
//            do {
//                closure?(.success(Void()))
//            } catch {
//                closure?(.failure(.database))
//            }
//        }
//    }
}

//private extension DataAccessService {
//
//    func fetchObjectsWithRequest<T>(request: DataAccessRequestConvertible) -> Results<T>? {
//        if let filter = request.localDataAccessor.filter, let propertySortKey = request.localDataAccessor.propertySortKey {
//            return databaseService?.getObjects(filter: filter, sortByKeyPath: propertySortKey)
//        } else if let filter = request.localDataAccessor.filter {
//            return databaseService?.getObjects(filter: filter)
//        } else if let propertySortKey = request.localDataAccessor.propertySortKey {
//            return databaseService?.getObjects(sortByKeyPath: propertySortKey)
//        } else {
//            return databaseService?.getObjects()
//        }
//    }
//}


// MARK: - Get Objects Publishers
private extension DataAccessService {

    private func getObjectsPublisher<T>(
        for localRequest: LocalRequest,
        dataAccessRequest: DataAccessRequest) -> AnyPublisher<[T], DataAccessError>
    where T: Object, T: Codable {

        return databaseService.getObjects(predicate: localRequest.filter)
            .mapError({ error -> DataAccessError in
                .database(error: error)
            })
            .eraseToAnyPublisher()
    }

    private func getObjectsPublisher<T>(
        for remoteRequest: RemoteRequest,
        dataAccessRequest: DataAccessRequest) -> AnyPublisher<[T], DataAccessError>
    where T: Object, T: Codable {
        return apiService
            .dataRequest(for: remoteRequest)
            .publishResponse(using: JSONResponseSerializer())
            // We are decoding here and then again on the next step, we should only get the Data here and
            // decode from data once on the next step. we could even use the .decode() function in Combine.
            .tryCompactMap { [weak self] (response) throws -> [T]? in

                switch response.result {
                case .success(let result):
                    guard let result = result as? [[String: Any]]
                    else { throw DataAccessError.remoteResponseUnexpected }
                    // I think it would be better if we decoded into a work context in the background that's a child of the view context
                    // so only when we save there will the viewContext be updated.
                    let objects: [T] = result.compactMap { self?.databaseService.decodeObject(with: $0) }
                    if let _ = dataAccessRequest.localRequest {
                        self?.databaseService.save()
                        // Don't send values as the local request should already be observing changes
                        // through the db when we save.
                        return nil
                    } else {
                        return objects
                    }

                case .failure(let error):
                    if let _ = dataAccessRequest.localRequest {
                        // Ignore errors so we don't finish the publisher and further database events can be
                        // observed.
                        return nil
                    } else {
                        throw DataAccessError.remote(error: error)
                    }
                }
            }
            .mapError { error -> DataAccessError in
                return error as? DataAccessError ?? .remoteResponseUnexpected
                //this will always be a DataAcessError as AlamoFire doesn't use combine's failure to report errors.
            }
            .eraseToAnyPublisher()
    }
}
