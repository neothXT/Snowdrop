//
//  Recoverable.swift
//  Netty
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

public protocol Recoverable {
    static var onAuthRetry: ((Self) async throws -> AccessTokenConvertible)? { get set }
}
