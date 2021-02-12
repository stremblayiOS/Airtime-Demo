//
//  Bootstrapper.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2018-01-21.
//  Copyright © 2018 Samuel Tremblay. All rights reserved.
//

import Swinject

struct Bootstrapper {
    static let sharedInstance = Bootstrapper()
    private(set) var container = Container()
    
    init() {
        container.register(DatabaseServiceProtocol.self) { _ in DatabaseService() }
        container.register(APIServiceProtocol.self) { _ in APIService() }
        container.register(DataAccessServiceProtocol.self) { resolver in
            DataAccessService(databaseService: resolver.resolve(DatabaseServiceProtocol.self)!,
                              apiService: resolver.resolve(APIServiceProtocol.self)!)
        }
        container.register(TabbarViewController.self) { resolver in
            TabbarViewController(dataAccessService: resolver.resolve(DataAccessServiceProtocol.self)!)
        }
        container.register(MyRoomsViewController.self) { resolver in
            MyRoomsViewController(dataAccessService: resolver.resolve(DataAccessServiceProtocol.self)!)
        }
        container.register(MyRoomsLiveViewController.self) { resolver in
            MyRoomsLiveViewController(dataAccessService: resolver.resolve(DataAccessServiceProtocol.self)!)
        }
    }
    
    static func getContainer() -> Container {
        Bootstrapper.sharedInstance.container
    }
}
