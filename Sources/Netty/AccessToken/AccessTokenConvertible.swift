//
//  AccessTokenConvertible.swift
//  Netty
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

public protocol AccessTokenConvertible: Codable {
    
    /// Converts object to AccessToken
    func convert() -> AccessToken?
}

public struct AccessToken: AccessTokenConvertible {
    public let access_token: String
    public let token_type: String
    public let expires_in: Int?
    public let refresh_token: String?
    public let scope: String?
    
    public init(access_token: String, token_type: String = "", expires_in: Int? = nil, refresh_token: String? = nil, scope: String? = nil) {
        self.access_token = access_token
        self.token_type = token_type
        self.expires_in = expires_in
        self.refresh_token = refresh_token
        self.scope = scope
    }
    
    public func convert() -> AccessToken? {
        self
    }
}
