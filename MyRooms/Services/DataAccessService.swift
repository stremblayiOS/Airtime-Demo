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
            databaseService.save(managedObjectContext: databaseService.managedObjectContext(.main))
        }
    }

    func deleteObject(request: DataAccessRequest, _ closure: ((Result<Void, DataAccessError>) -> Void)?) {
        if let _ = request.localRequest {
            databaseService.deleteObjects(object: request.type, predicate: nil)
        }
    }

    // Combine implementations

    func getObjects<T>(type: T.Type, request: DataAccessRequest) -> AnyPublisher<[T], DataAccessError> where T: Object, T: Codable {

        typealias ResultPublisher = AnyPublisher<[T], DataAccessError>

        switch (request.localRequest, request.remoteRequest) {
        case (nil, nil):
            return Fail(outputType: [T].self, failure: DataAccessError.dataAccessRequestInvalid).eraseToAnyPublisher()

        case (nil, let remoteRequest?):
            return getObjectsPublisher(for: remoteRequest, dataAccessRequest: request)

        case (let localRequest?, nil):
            return getObjectsPublisher(for: localRequest, dataAccessRequest: request)

        case (let localRequest?, let remoteRequest?):
            let local: ResultPublisher = getObjectsPublisher(for: localRequest, dataAccessRequest: request)
            let remote: ResultPublisher = getObjectsPublisher(for: remoteRequest, dataAccessRequest: request)

            return Publishers.Merge(local, remote).eraseToAnyPublisher()
        }
    }
}

// MARK: - Get Objects Publishers
private extension DataAccessService {

    func getObjectsPublisher<T>(for localRequest: LocalRequest, dataAccessRequest: DataAccessRequest) -> AnyPublisher<[T], DataAccessError> where T: Object, T: Codable {
        databaseService
            .getObjects(predicate: localRequest.filter)
            .mapError { error -> DataAccessError in
                .database(error: error)
            }
            .eraseToAnyPublisher()
    }

    func getObjectsPublisher<T>(for remoteRequest: RemoteRequest, dataAccessRequest: DataAccessRequest) -> AnyPublisher<[T], DataAccessError> where T: Object, T: Codable {
        apiService
            .dataRequest(for: remoteRequest)
            .publishResponse(using: JSONResponseSerializer())
            // We are decoding here and then again on the next step, we should only get the Data here and
            // decode from data once on the next step. we could even use the .decode() function in Combine.
            .tryCompactMap { [weak self] response throws -> [T]? in
                guard let self = self else { return nil }

                switch response.result {
                case .success(let result):
                    guard let result = result as? [[String: Any]] else { throw DataAccessError.remoteResponseUnexpected }

                    if let _ = dataAccessRequest.localRequest {
                        let managedObjectContext = self.databaseService.managedObjectContext(.background)
                        managedObjectContext.performAndWait {
                            let _: [T] = result.compactMap {
                                self.databaseService.decodeObject(with: $0, managedObjectContext: managedObjectContext)
                            }
                            self.databaseService.save(managedObjectContext: managedObjectContext)
                        }
                        // Don't send values as the local request should already be observing changes
                        // through the db when we save.
                        return nil
                    } else {
                        let managedObjectContext = self.databaseService.managedObjectContext(.temporary)
                        return result.compactMap {
                            self.databaseService.decodeObject(with: $0, managedObjectContext: managedObjectContext)
                        }
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
                error as? DataAccessError ?? .remoteResponseUnexpected
                //this will always be a DataAcessError as AlamoFire doesn't use combine's failure to report errors.
            }
            .eraseToAnyPublisher()
    }
}
