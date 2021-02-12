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

    /// Generic function to save an object to the db
    ///
    /// - Parameter object: The object to save
    /// - Returns: The saved object
    func saveObject<T>(object: T) where T: Object

    /// Generic function to save multiple objects to the db
    ///
    /// - Parameter objects: The objects to save
    /// - Returns: The saved objects
    func saveObjects<T>(objects: [T]) where T: Codable, T: Object

    /// Generic function to retrieve a single object from the db according to a primary key
    ///
    /// - Parameter id: The object's primary key
    /// - Returns: The found object, otherwise nil
    func getObject<T: Object>(id: String) -> Result<T, Error>

    /// Generic function to retrieve multiple objects from the db
    ///
    /// - Returns: The retrieved results object. If nil, no objects were found
    func getObjects<T: Object>() -> Result<[T], Error>
    func getObjects<T: Object>(with localDataAccessor: LocalDataAccessor) -> Result<[T], Error>

    /// Delete a given object from the db
    ///
    /// - Parameter object: The object to delete
    func deleteObject(object: Object)

    func save()

    func managedObject<T: Object>(with type: T.Type) -> T

    func deleteAllData()
}

final class DatabaseService: DatabaseServiceProtocol {

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MyRooms")
        container.loadPersistentStores(completionHandler: { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    private lazy var managedContext: NSManagedObjectContext = persistentContainer.viewContext

    private var subscribers = Set<AnyCancellable>()

    required init() {
        NotificationCenter.default
            .publisher(for: UIScene.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.save()
            })
            .store(in: &subscribers)
    }

    func managedObject<T: Object>(with type: T.Type) -> T {
        T(context: managedContext)
    }

    func saveObject<T>(object: T) where T: Object {

//        let encoder = JSONEncoder()
//        let jsonData = try! encoder.encode(object)
//
//        let decoder = JSONDecoder()
//        decoder.userInfo[CodingUserInfoKey.managedObjectContext] = managedContext
//
//        let _ = try! decoder.decode(T.self, from: jsonData)

        save()
    }

    func saveObjects<T: Object>(objects: [T]) {


    }

    func getObject<T: Object>(id: String) -> Result<T, Error> {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        do {
            return .success(try managedContext.fetch(fetchRequest).first!)
        } catch {
            return .failure(error)
        }
    }

    func getObject<T: Object>(predicate: NSPredicate? = nil) -> Result<T, Error> {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        fetchRequest.predicate = predicate
        do {
            return .success(try managedContext.fetch(fetchRequest).first!)
        } catch {
            return .failure(error)
        }
    }

    func getObjects<T: Object>() -> Result<[T], Error> {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        // Revert this to true on production
//        fetchRequest.returnsObjectsAsFaults = false
        do {
            return .success(try managedContext.fetch(fetchRequest))
        } catch {
            return .failure(error)
        }
    }

    func getObjects<T: Object>(with localDataAccessor: LocalDataAccessor) -> Result<[T], Error> {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
        
        // Revert this to true on production
//        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.predicate = localDataAccessor.filter
        do {
            return .success(try managedContext.fetch(fetchRequest))
        } catch {
            return .failure(error)
        }
    }

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

    func deleteObjects(object: Object, predicate: NSPredicate? = nil) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Object.fetchRequest()
        fetchRequest.predicate = predicate
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        do {
            let result = try managedContext.execute(batchDeleteRequest) as! NSBatchDeleteResult
            let changes: [AnyHashable: Any] = [
                NSDeletedObjectsKey: result.result as! [NSManagedObjectID]
            ]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [managedContext])
            save()
        } catch {
            fatalError("Error deleting objects: \(error.localizedDescription)")
        }
    }

    func save() {
        guard managedContext.hasChanges else { return }
        do {
            try managedContext.save()
        } catch {
            fatalError("Error saving objects: \(error.localizedDescription)")
        }
    }

    func clearAllObjects() {
        guard let firstStoreURL = managedContext.persistentStoreCoordinator?.persistentStores.first?.url else {
            print("Missing first store URL - could not destroy")
            return
        }
        do {
            try managedContext.persistentStoreCoordinator?.destroyPersistentStore(at: firstStoreURL, ofType: "", options: [:])
        } catch {
            // Error Handling
        }
    }

    func deleteAllData() {

        // This doesn't work: need to figure out why
        managedContext.reset()
        save()


//        guard let firstStoreURL = managedContext.persistentStoreCoordinator?.persistentStores.first?.url else {
//            print("Missing first store URL - could not destroy")
//            return
//        }
//
//        do {
//            try managedContext.persistentStoreCoordinator?.destroyPersistentStore(at: firstStoreURL, ofType: NSSQLiteStoreType, options: nil)
//        } catch  {
//            print("Unable to destroy persistent store: \(error) - \(error.localizedDescription)")
//        }

//        guard
//            let persistentStore = managedContext.persistentStoreCoordinator?.persistentStores.last,
//            let url = managedContext.persistentStoreCoordinator?.url(for: persistentStore)
//        else {
//            return
//        }
//        try? managedContext.persistentStoreCoordinator?.remove(persistentStore)
//        try? FileManager.default.removeItem(at: url)
//        let _ = try? managedContext.persistentStoreCoordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: "MyRooms", at: url, options: nil)
//
//        persistentContainer.loadPersistentStores(completionHandler: { storeDescription, error in
//            if let error = error as NSError? {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        })


        //create a store  NSPersistentContainer
//        let persistentContainer = NSPersistentContainer(name: "ModelFileName")
//        //configure settings
//        let url = NSPersistentContainer.defaultDirectoryURL()
//        let path = url.appendingPathComponent(persistentContainer.name)
//        description.shouldAddStoreAsynchronously = true;//write to disk should happen on background thread
//        self.persistentContainer.persistentStoreDescriptions = [description]
//        //load the store
//        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error {
//                  fatalError("Unresolved error \(error), \(error.localizedDescription)")
//            }
//            //configure context for main view to automatically merge changes
//            persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
//        });
//        //in the view controller you can access the view context by calling
//        persistentContainer.viewContext
//        //if you need to make changes you can call
//        persistentContainer.performBackgroundTask { context in
//
//        }
//        //or you can get a background context
//        let context = persistentContainer.newBackgroundContext()
//        context.perform({
//
//        })
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

extension NSManagedObject {

    func shallowCopy() -> NSManagedObject? {
        guard let context = managedObjectContext, let entityName = entity.name else { return nil }
        let copy = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        let attributes = entity.attributesByName
        for (attrKey, _) in attributes {
            copy.setValue(value(forKey: attrKey), forKey: attrKey)
        }
        return copy
    }
}
