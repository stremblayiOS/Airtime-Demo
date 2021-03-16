//
//  DatabaseService.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2020-11-10.
//  Copyright © 2020 Samuel Tremblay. All rights reserved.
//

import CoreData
import Combine
import UIKit

/// Service protocol definition
protocol DatabaseServiceProtocol {

    /// Create an instance of NSManagedObject along with the desired managed context
    /// Warning: It doesn't save the object. You need to call `func save()` for that.
    ///
    /// - Parameters:
    ///   - type: The type of the managed object you want to create
    ///
    /// - Returns: A newly created instance ready be saved
    func createObject<T: Object>(_ type: T.Type) -> T

    func decodeObject<T: Decodable>(with JSON: [AnyHashable: Any], managedObjectContext: NSManagedObjectContext?) -> T?

    func managedObjectContext(_ contextType: DatabaseService.ContextType) -> NSManagedObjectContext

    /// Function to save the context if there is any changes to save
    ///
    func save(managedObjectContext: NSManagedObjectContext)

    /// Generic function to retrieve a single object from the db according to a primary key
    ///
    /// - Parameter id: The object's primary key
    /// - Returns: The found object, otherwise nil
    func getObject<T: Object>(id: String) -> Result<T, NSError>

    /// Generic function to retrieve multiple objects from the db
    ///
    /// - Returns: The retrieved results object. If nil, no objects were found
    func getObjects<T: Object>(predicate: NSPredicate?) -> Result<[T], NSError>
    func getObjects<T: Object>(predicate: NSPredicate?) -> ManagedObjectChangesPublisher<T>

    /// Delete a given object from the db
    ///
    /// - Parameter object: The object to delete
    func deleteObject(object: Object)

    // TODO: Missing Doc
    func deleteObjects(object: Object.Type, predicate: NSPredicate?)

    // TODO: Missing Doc
    func deleteAllData()
}

final class DatabaseService: DatabaseServiceProtocol {

    enum ContextType {
        case main
        case background
        case temporary
    }

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MyRooms")
        container.loadPersistentStores(completionHandler: { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    private lazy var managedObjectContext: NSManagedObjectContext = {
        let managedObjectContext = persistentContainer.viewContext
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return managedObjectContext
    }()

    private lazy var backgroundManagedObjectContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.parent = self.managedObjectContext
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return managedObjectContext
    }()

    private lazy var temporaryManagedObjectContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.parent = self.managedObjectContext
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return managedObjectContext
    }()

    private var subscribers = Set<AnyCancellable>()

    required init() {
        NotificationCenter.default
            .publisher(for: UIScene.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.save(managedObjectContext: self.managedObjectContext)
            })
            .store(in: &subscribers)
    }

    func createObject<T: Object>(_ type: T.Type) -> T {
        T(context: managedObjectContext)
    }

    func decodeObject<T: Decodable>(with JSON: [AnyHashable: Any], managedObjectContext: NSManagedObjectContext?) -> T? {
        do {
            let data = try JSONSerialization.data(withJSONObject: JSON, options: .prettyPrinted)
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext] = managedObjectContext ?? self.managedObjectContext
            return try decoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    func managedObjectContext(_ contextType: DatabaseService.ContextType) -> NSManagedObjectContext {
        switch contextType {
            case .main:
                return managedObjectContext
            case .background:
                return backgroundManagedObjectContext
            case .temporary:
                return temporaryManagedObjectContext
        }
    }

    func getObject<T: Object>(id: String) -> Result<T, NSError> {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        do {
            return .success(try managedObjectContext.fetch(fetchRequest).first!)
        } catch {
            return .failure(error as NSError)
        }
    }

    func getObject<T: Object>(predicate: NSPredicate? = nil) -> Result<T, NSError> {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        fetchRequest.predicate = predicate
        do {
            return .success(try managedObjectContext.fetch(fetchRequest).first!)
        } catch {
            return .failure(error as NSError)
        }
    }

    func getObjects<T: Object>(predicate: NSPredicate?) -> Result<[T], NSError> {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        fetchRequest.predicate = predicate
        // Revert this to true on production
//        fetchRequest.returnsObjectsAsFaults = false
        do {
            let objects = try managedObjectContext.fetch(fetchRequest)
            return .success(objects)
        } catch {
            return .failure(error as NSError)
        }
    }

    // Start using combine

    func getObjects<T: Object>(predicate: NSPredicate?) -> ManagedObjectChangesPublisher<T> {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        return managedObjectContext.changesPublisher(for: fetchRequest)
    }

//    func getObjects<T: Object>(with localDataAccessor: LocalDataAccessor) -> Result<[T], Error> {
//        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
//        
//        // Revert this to true on production
////        fetchRequest.returnsObjectsAsFaults = false
//        fetchRequest.predicate = localDataAccessor.filter
//        do {
//            return .success(try managedContext.fetch(fetchRequest))
//        } catch {
//            return .failure(error)
//        }
//    }

    func deleteObject(object: Object) {

//        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Page.fetchRequest()
//        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Page.isTrash), NSNumber(value: true))
//        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//        batchDeleteRequest.resultType = .resultTypeObjectIDs
//        do {
//            let result = try viewContext.execute(batchDeleteRequest) as! NSBatchDeleteResult
//            let changes: [AnyHashable: Any] = [
//                NSDeletedObjectsKey: result.result as! [NSManagedObjectID]
//            ]
//            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
//            save()
//        } catch {


    }

    func deleteObjects(object: Object.Type, predicate: NSPredicate? = nil) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: String(describing: object))
        fetchRequest.predicate = predicate
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        do {
            let result = try managedObjectContext.execute(batchDeleteRequest) as! NSBatchDeleteResult
            let changes: [AnyHashable: Any] = [
                NSDeletedObjectsKey: result.result as! [NSManagedObjectID]
            ]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [managedObjectContext])
            save(managedObjectContext: managedObjectContext)
        } catch {
            fatalError("Error deleting objects: \(error.localizedDescription)")
        }
    }

    func save(managedObjectContext: NSManagedObjectContext) {
        guard managedObjectContext != self.managedObjectContext(.temporary), managedObjectContext.hasChanges else { return }
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Error saving objects: \(error.localizedDescription)")
        }
    }

    func clearAllObjects() {
        guard let firstStoreURL = managedObjectContext.persistentStoreCoordinator?.persistentStores.first?.url else {
            print("Missing first store URL - could not destroy")
            return
        }
        do {
            try managedObjectContext.persistentStoreCoordinator?.destroyPersistentStore(at: firstStoreURL, ofType: "", options: [:])
        } catch {
            // Error Handling
        }
    }

    func deleteAllData() {
        // TODO
    }

    enum ChangeType {
      case inserted, deleted, updated

      var userInfoKey: String {
        switch self {
        case .inserted:
            return NSInsertedObjectIDsKey
        case .deleted:
            return NSDeletedObjectIDsKey
        case .updated:
            return NSUpdatedObjectIDsKey
        }
      }
    }

    func publisher<T: Object>(for managedObject: T, in context: NSManagedObjectContext, changeTypes: [ChangeType]) -> AnyPublisher<(object: T?, type: ChangeType), Never> {
      let notification = NSManagedObjectContext.didMergeChangesObjectIDsNotification
      return NotificationCenter.default.publisher(for: notification, object: context).compactMap { notification in
          for type in changeTypes {
            if let object = self.managedObject(with: managedObject.objectID, changeType: type, from: notification, in: context) as? T {
              return (object, type)
            }
          }
          return nil
        }
        .eraseToAnyPublisher()
    }

    func managedObject(with id: NSManagedObjectID, changeType: ChangeType, from notification: Notification, in context: NSManagedObjectContext) -> Object? {
      guard
        let objects = notification.userInfo?[changeType.userInfoKey] as? Set<NSManagedObjectID>,
        objects.contains(id)
      else {
        return nil
      }
      return context.object(with: id)
    }
}
