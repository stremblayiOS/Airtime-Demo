//
//  RoomDataAccessor.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-02-12.
//

import CoreData

enum RoomDataAccessRequest: DataAccessRequest {
    case myRooms
    case myRoomsLive
    case create(room: Room)
    case deleteAllRooms
    case deleteAllRoomsOnlyLocally

    var remoteRequest: RemoteRequest? {
        switch self {
        case .myRooms:
            return RoomRouter.rooms
        case .myRoomsLive:
            return RoomRouter.rooms
        case .create(let room):
            return RoomRouter.create(room: room)
        case .deleteAllRooms:
            return RoomRouter.deleteAll
        case .deleteAllRoomsOnlyLocally:
            return nil
        }
    }

    var localRequest: LocalRequest? {
        switch self {
        case .myRooms:
            return (object: nil, id: nil, filter: nil, propertySortKey: nil, ascending: true)
        case .myRoomsLive:
            return (object: nil, id: nil, filter: NSPredicate(format: "live == true"), propertySortKey: nil, ascending: true)
        case .create(let room):
            return (object: room, id: nil, filter: nil, propertySortKey: nil, ascending: true)
        case .deleteAllRooms:
            return (object: nil, id: nil, filter: nil, propertySortKey: nil, ascending: true)
        case .deleteAllRoomsOnlyLocally:
            return (object: nil, id: nil, filter: nil, propertySortKey: nil, ascending: true)
        }
    }

    var type: Object.Type {
        Room.self
    }
}
