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

        deleteAllRooms()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let myRoomsViewController = ServiceFactory.resolve(serviceType: MyRoomsViewController.self)
        let myRoomsLiveViewController = ServiceFactory.resolve(serviceType: MyRoomsLiveViewController.self)

        viewControllers = [UINavigationController(rootViewController: myRoomsViewController),
                           UINavigationController(rootViewController: myRoomsLiveViewController)]
    }
}

private extension TabbarViewController {

    func deleteAllRooms() {
        dataAccessService.deleteObject(request: RoomDataAccessRequest.deleteAllRooms, nil)
    }
}
