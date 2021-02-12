//
//  DataAccessRequestConvertible.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2020-11-10.
//  Copyright © 2020 Samuel Tremblay. All rights reserved.
//

import Foundation
import Alamofire
import CoreData

public typealias Object = NSManagedObject
public typealias RemoteDataAccessor = URLRequestConvertible
public typealias LocalDataAccessor = (object: Object?, id: String?, filter: NSPredicate?, propertySortKey: String?, ascending: Bool)

public protocol DataAccessRequestConvertible {
    var remoteDataAccessor: RemoteDataAccessor { get }
    var localDataAccessor: LocalDataAccessor { get }
    var storageLocation: StorageLocation { get }
}

public enum StorageLocation {
    case both
    case remoteOnly
    case localOnly
}
