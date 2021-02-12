//
//  RoomDataAccessor.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-02-12.
//

import CoreData

enum RoomDataAccessor: DataAccessRequestConvertible {
    case myRooms
    case myRoomsLive
    case deleteAllRooms
    case create(room: Room)

    var remoteDataAccessor: RemoteDataAccessor {
        switch self {
        case .myRooms:
            return RoomRouter.rooms
        case .myRoomsLive:
            return RoomRouter.rooms
        case .deleteAllRooms:
            return RoomRouter.deleteAll
        case .create(let room):
            return RoomRouter.create(room: room)
        }
    }

    var localDataAccessor: LocalDataAccessor {
        switch self {
        case .myRooms:
            return (object: nil, id: nil, filter: nil, propertySortKey: nil, ascending: true)
        case .myRoomsLive:
            return (object: nil, id: nil, filter: NSPredicate(format: "isLive == true"), propertySortKey: nil, ascending: true)
        case .deleteAllRooms:
            return (object: nil, id: nil, filter: nil, propertySortKey: nil, ascending: true)
        case .create(let room):
            return (object: room, id: nil, filter: nil, propertySortKey: nil, ascending: true)
        }
    }

    // Ignore: Experimental
    var storageLocation: StorageLocation {
        switch self {
        case .create:
            return .localOnly
        default:
            return .both
        }
    }
}
