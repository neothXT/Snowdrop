//
//  Snowdrop.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

public typealias RequestHandler = (URLRequest) -> URLRequest
public typealias ResponseHandler = (Data, HTTPURLResponse) -> (Data)

public struct Snowdrop {
    public static let core = Core()
}

// MARK: Core

public extension Snowdrop {
    struct Core {
        fileprivate init() { /* NOP */ }
    }
}
