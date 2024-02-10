//
//  AccessTokenStorage.swift
//  Netty
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

public protocol AccessTokenStorage {
    func store(_ token: AccessToken?, for storingLabel: String)
    func fetch(for storingLabel: String) -> AccessToken?
    func delete(for storingLabel: String) -> Bool
}

public class DefaultStorage: AccessTokenStorage {
    private var tokens: [String: AccessToken] = [:]
    
    public func store(_ token: AccessToken?, for storingLabel: String) {
        guard let token = token else { return }
        tokens[storingLabel] = token
    }
    
    public func fetch(for storingLabel: String) -> AccessToken? {
        tokens[storingLabel]
    }
    
    public func delete(for storingLabel: String) -> Bool {
        guard tokens.keys.contains(storingLabel) else {
            return false
        }
        
        tokens.removeValue(forKey: storingLabel)
        return true
    }
}
