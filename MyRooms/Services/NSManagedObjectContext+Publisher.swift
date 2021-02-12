//
//  NSManagedObjectContext+Publisher.swift
//  reMark
//
//  Created by Gary Philipp on 12/10/20.
//

import CoreData
import Combine

extension NSManagedObjectContext {
    func changesPublisher<Object: NSManagedObject>(for fetchRequest: NSFetchRequest<Object>) -> ManagedObjectChangesPublisher<Object> {
        ManagedObjectChangesPublisher(fetchRequest: fetchRequest, context: self)
    }
}

// MARK: - Publisher
public final class ManagedObjectChangesPublisher<ResultType>: Publisher where ResultType: NSFetchRequestResult {
    
    let fetchRequest: NSFetchRequest<ResultType>
    let context: NSManagedObjectContext
    
    public init(fetchRequest: NSFetchRequest<ResultType>, context: NSManagedObjectContext) {
        self.fetchRequest = fetchRequest
        self.context = context
    }
    
    public typealias Output = [ResultType]
    public typealias Failure = NSError
    
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
        subscriber.receive(subscription: ManagedObjectChangesSubscription(subscriber: subscriber, fetchRequest: fetchRequest, context: context))
    }
    
    public var value: Output? {
        return try? context.fetch(fetchRequest)
    }

    // MARK: - Subscription
    final class ManagedObjectChangesSubscription<SubscriberType, ResultType>: NSObject, Subscription, NSFetchedResultsControllerDelegate
    where
        SubscriberType: Subscriber,
        SubscriberType.Input == [ResultType],
        SubscriberType.Failure == NSError,
        ResultType: NSFetchRequestResult
    {
        private(set) var subscriber: SubscriberType?
        private(set) var fetchRequest: NSFetchRequest<ResultType>?
        private(set) var context: NSManagedObjectContext?
        private(set) var fetchController: NSFetchedResultsController<ResultType>?
        
        init(subscriber: SubscriberType, fetchRequest: NSFetchRequest<ResultType>, context: NSManagedObjectContext) {
            self.subscriber = subscriber
            self.fetchRequest = fetchRequest
            self.context = context
        }
        
        func request(_ demand: Subscribers.Demand) {
            guard demand > 0,
                  let subscriber = subscriber,
                  let fetchRequest = fetchRequest,
                  let context = context else { return }
            
            fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil,cacheName: nil)
            fetchController?.delegate = self
            
            do {
                try fetchController?.performFetch()
                if let fetchedObjects = fetchController?.fetchedObjects {
                    _ = subscriber.receive(fetchedObjects)
                }
            } catch {
                subscriber.receive(completion: .failure(error as NSError))
            }
        }
        
        func cancel() {
            subscriber = nil
            fetchController = nil
            fetchRequest = nil
            context = nil
        }
        
        // MARK: - NSFetchedResultsControllerDelegate
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            guard let subscriber = subscriber,
                  controller == self.fetchController else { return }
            
            if let fetchedObjects = self.fetchController?.fetchedObjects {
                _ = subscriber.receive(fetchedObjects)
            }
        }
    }
}
