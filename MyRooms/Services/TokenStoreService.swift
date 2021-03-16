//
//  TokenStoreService.swift
//  MyRooms
//
//  Created by Samuel Tremblay on 2021-03-15.
//

import Foundation

/// Service protocol definition
protocol TokenStoreServiceProtocol {
    
    /// Read-only property containing the token value from the token store
    var token: String? { get }
    
    /// Add the token to the token store
    ///
    /// - Parameter token: The token to store
    /// - Returns: The boolean result of the operation; success -> 'true', failure -> 'false'
    @discardableResult func addToken(token: String, for type: TokenStoreService.TokenType) -> Bool
    
    /// Remove the token from the token store
    ///
    /// - Returns: The boolean result of the operation; success -> 'true', failure -> 'false'
    @discardableResult func removeToken(for type: TokenStoreService.TokenType) -> Bool
}

final class TokenStoreService: TokenStoreServiceProtocol {

    private let keychainService: KeychainServiceProtocol

    enum TokenType: String {
        case apiToken
    }
    
    required init(keychainService: KeychainServiceProtocol) {
        self.keychainService = keychainService

        addToken(token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyIjoiNWQ4MDEzNGMzZGI2OWE0NDNmNGQ5OGY2IiwiYXBwSWQiOiJjcm9udXMiLCJzYWx0IjoiQlg4M2dIT2RMUER4NkRVVERoUHZvZz09In0.wE6JYUZodUV25NTPYxbqaFaFYcSyN9pYSrgOs3jdyT8", for: .apiToken)
    }
    
    var token: String? {
        keychainService.getValue(forKey: TokenType.apiToken.rawValue)
    }

    @discardableResult func addToken(token: String, for type: TokenStoreService.TokenType) -> Bool {
        keychainService.setValue(value: token, forKey: TokenType.apiToken.rawValue)
    }

    @discardableResult func removeToken(for type: TokenStoreService.TokenType) -> Bool {
        keychainService.removeEntry(forKey: TokenType.apiToken.rawValue)
    }
}
