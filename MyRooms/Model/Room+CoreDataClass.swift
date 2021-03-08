//
//  Room+CoreDataClass.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-02-12.
//
//

import Foundation
import CoreData

public class Room: NSManagedObject, Codable {

    enum CodingKeys: CodingKey {
        case id
        case name
        case isLive
    }

    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        self.init(context: context)

        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.id = try container.decode(String.self, forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.isLive = try container.decode(Bool.self, forKey: .isLive)
        } catch {
            print(error.localizedDescription)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isLive, forKey: .isLive)
    }
}

// TODO: Move this
extension CodingUserInfoKey {
  static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}

// TODO: Move this
enum DecoderConfigurationError: Error {
  case missingManagedObjectContext
}
