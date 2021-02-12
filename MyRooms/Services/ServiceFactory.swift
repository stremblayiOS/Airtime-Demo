//
//  ServiceFactory.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2018-01-21.
//  Copyright © 2018 Samuel Tremblay. All rights reserved.
//

enum ServiceFactory {

    static func resolve<Service>(serviceType: Service.Type) -> Service {
        Bootstrapper.getContainer().resolve(serviceType)!
    }
}
