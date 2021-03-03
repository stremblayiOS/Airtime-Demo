//
//  TabbarViewController.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-02-12.
//

import UIKit

final class TabbarViewController: UITabBarController {

    private let dataAccessService: DataAccessServiceProtocol

    init(dataAccessService: DataAccessServiceProtocol) {
        self.dataAccessService = dataAccessService
        super.init(nibName: nil, bundle: nil)

        createRoom()
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

private extension TabbarViewController {

    func deleteAllRooms() {
        dataAccessService.deleteObject(request: RoomDataAccessRequest.deleteAllRooms, nil)
    }

    func createRoom() {
        // 1. Create the object and set paramaters
        let room = dataAccessService.createObject(Room.self)
        room.name = UUID().uuidString
        room.isLive = Bool.random()

        // 2. Create the request
        let request = RoomDataAccessRequest.create(room: room)

        // 3. Save object
        dataAccessService.saveObject(request: request, nil)
    }
}
