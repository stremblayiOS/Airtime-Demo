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
public typealias RemoteRequest = URLRequestConvertible
public typealias LocalRequest = (object: Object?, id: String?, filter: NSPredicate?, propertySortKey: String?, ascending: Bool)

public protocol DataAccessRequest {
    var remoteRequest: RemoteRequest? { get }
    var localRequest: LocalRequest? { get }
    var type: Object.Type { get }
}
