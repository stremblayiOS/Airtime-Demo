//
//  Room+CoreDataProperties.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-02-12.
//
//

import Foundation
import CoreData


extension Room {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Room> {
        NSFetchRequest<Room>(entityName: String(describing: self))
    }

    @NSManaged public var uid: String
    @NSManaged public var isLive: Bool
    @NSManaged public var name: String
}

extension Room: Identifiable {

}
