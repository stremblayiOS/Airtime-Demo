//
//  KeychainService.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-03-15.
//

import Foundation
import SwiftKeychainWrapper

/// Service protocol definition
protocol KeychainServiceProtocol {
    
    /// Get the value for the given key from the application keychain
    ///
    /// - Parameter key: The key used to store the value in the keychain
    /// - Returns: The value entry in the keychain for 'key'
    func getValue(forKey key: String) -> String?
    
    /// Set the value for the given key in the application keychain
    ///
    /// - Parameters:
    ///   - value: The value to be set in the keychain
    ///   - forKey: The key used to store the value in the keychain
    /// - Returns: The boolean result of the operation; success -> 'true', failure -> 'false'
    func setValue(value: String, forKey: String) -> Bool
    
    /// Remove an entry for a given key from the keychain
    ///
    /// - Parameter key: The key used to store the value in the keychain
    /// - Returns: The boolean result of the operation; success -> 'true', failure -> 'false'
    func removeEntry(forKey key: String) -> Bool
    
    /// Clear all entries from the keychain
    ///
    /// - Returns: The boolean result of the operation; success -> 'true', failure -> 'false'
    func clearKeychain() -> Bool
}

final class KeychainService: KeychainServiceProtocol {

    private let keychainWrapper: KeychainWrapper

    required init(serviceIdentifier identifier: String) {
        keychainWrapper = KeychainWrapper(serviceName: identifier)
    }

    func getValue(forKey key: String) -> String? {
        keychainWrapper.string(forKey: key)
    }

    func setValue(value: String, forKey: String) -> Bool {
        keychainWrapper.set(value, forKey: forKey)
    }

    func removeEntry(forKey key: String) -> Bool {
        keychainWrapper.removeObject(forKey: key)
    }

    func clearKeychain() -> Bool {
        keychainWrapper.removeAllKeys()
    }
}
