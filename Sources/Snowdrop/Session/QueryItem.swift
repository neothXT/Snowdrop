//
//  QueryItem.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 19/02/2024.
//

import Foundation

public struct QueryItem {
    public let key: String
    public let value: Any
    
    public init(key: String, value: Any) {
        self.key = key
        self.value = value
    }
    
    public func toUrlQueryItem() -> URLQueryItem {
        .init(name: key, value: "\(value)")
    }
}
