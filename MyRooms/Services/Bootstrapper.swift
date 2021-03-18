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
        container.register(KeychainServiceProtocol.self) { _ in KeychainService(serviceIdentifier: "com.keychain.MyRooms") }
        container.register(TokenStoreServiceProtocol.self) { resolver in
            TokenStoreService(keychainService: resolver.resolve(KeychainServiceProtocol.self)!)
        }
        container.register(APIServiceProtocol.self) { _ in APIService() }
        container.register(AccessTokenAdapter.self) { resolver in
            AccessTokenAdapter(tokenStoreService: resolver.resolve(TokenStoreServiceProtocol.self)!)
        }
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
