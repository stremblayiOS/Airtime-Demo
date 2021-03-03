//
//  TabbarViewController.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-02-12.
//

import UIKit

final class TabbarViewController: UITabBarController {

//    private let databaseService: DatabaseServiceProtocol // Wrong

    private let dataAccessService: DataAccessServiceProtocol

//    init(databaseService: DatabaseServiceProtocol) {
//        self.databaseService = databaseService
//        super.init(nibName: nil, bundle: nil)
//
//        databaseService.deleteAllData()
//
//        let room: Room = databaseService.managedObject(with: Room.self)
//        room.name = UUID().uuidString
//        room.isLive = Bool.random()
//
//        databaseService.save()
//    }

    init(dataAccessService: DataAccessServiceProtocol) {
        self.dataAccessService = dataAccessService
        super.init(nibName: nil, bundle: nil)

        // 1. Start on a clean state
        dataAccessService.deleteObject(request: RoomDataAccessRequest.deleteAllRooms, nil)

        // 2. Create the object and set paramaters
        let room = dataAccessService.createObject(Room.self)
        room.name = UUID().uuidString
        room.isLive = Bool.random()

        // 3. Save object
        dataAccessService.saveObject<Room>(request: RoomDataAccessRequest.create(room: room), nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let myRoomsViewController = ServiceFactory.resolve(serviceType: MyRoomsViewController.self)
        let myRoomsLiveViewController = ServiceFactory.resolve(serviceType: MyRoomsLiveViewController.self)

        viewControllers = [myRoomsViewController, myRoomsLiveViewController]
    }
}
