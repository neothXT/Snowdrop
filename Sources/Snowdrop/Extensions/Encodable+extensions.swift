//
//  Encodable+extensions.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

extension Encodable {
    public func toJsonData() throws -> Data {
        try JSONEncoder().encode(self)
    }
    
    public func toDictionary(options: EncodableConversionOptions = .init(rawValue: 0)) -> [String: Any] {
        guard let data = try? toJsonData(), var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        
        if !options.contains(.keepEmptyCollections) {
            json = (removeEmptyCollections(from: json) as? [String: Any]) ?? [:]
        }
        
        return json
    }
    
    private func removeEmptyCollections(from input: Any) -> Any {
        switch input {
        case let input as [Any?]:
            var array = input
            array.enumerated().forEach { index, value in
                guard let value else {
                    array.remove(at: index)
                    return
                }
                guard let count = collectionCountOrNil(value) else {
                    if valueOrNil(value) == nil {
                        array.remove(at: index)
                    }
                    return
                }
                if count == 0 {
                    array.remove(at: index)
                } else {
                    array[index] = removeEmptyCollections(from: value)
                }
            }
            return array
            
        case let input as [String: Any?]:
            var dict = input
            dict.forEach { key, value in
                guard let value else {
                    dict.removeValue(forKey: key)
                    return
                }
                guard let count = collectionCountOrNil(value) else {
                    if valueOrNil(value) == nil {
                        dict.removeValue(forKey: key)
                    }
                    return
                }
                if count == 0 {
                    dict.removeValue(forKey: key)
                } else {
                    dict[key] = removeEmptyCollections(from: value)
                }
            }
            return dict
            
        default:
            return input
        }
    }
    
    fileprivate func collectionCountOrNil(_ value: Any) -> Int? {
        switch value {
        case let value as Array<Any>:
            value.count
        case let value as Dictionary<String, Any>:
            value.count
        default:
            nil
        }
    }
}

fileprivate extension Optional where Wrapped: Collection {
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}

public struct EncodableConversionOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// Keeps empty collections in final output
    public static let keepEmptyCollections = EncodableConversionOptions(rawValue: 1 << 0)
}

func valueOrNil(_ value: Any) -> Any? {
    switch value {
    case Optional<Any>.none:
        return nil
    case Optional<Any>.some(let val):
        return val
    default:
        return value
    }
}
