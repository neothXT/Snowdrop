//
//  ClassBuilder.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 26/04/2024.
//

import SwiftSyntax

enum ClassType: String {
    case service
    case mock
    
    func suffix(for name: String) -> String {
        switch self {
        case .service:
            name.lowercased().contains("service") ? "Impl" : "Service"
        case .mock:
            name.lowercased().contains("service") ? "Mock" : "ServiceMock"
        }
    }
}

struct ClassBuilder {
    private init() { }
    
    static func build(type: ClassType, accessModifier: String, name: String, functions: String) -> DeclSyntax {
                """
                \(raw: accessModifier)class \(raw: name)\(raw: type.suffix(for: name)): \(raw: name), Service {
                    \(raw: accessModifier)let baseUrl: URL
                
                    \(raw: accessModifier)var requestBlocks: [String: RequestHandler] = [:]
                    \(raw: accessModifier)var responseBlocks: [String: ResponseHandler] = [:]
                
                    \(raw: accessModifier)var testJSONDictionary: [String: String]?
                
                    \(raw: accessModifier)var decoder: JSONDecoder
                    \(raw: accessModifier)var pinningMode: PinningMode?
                    \(raw: accessModifier)var urlsExcludedFromPinning: [String]
                    \(raw: accessModifier)let verbose: Bool
                
                    \(raw: accessModifier)required init(
                        baseUrl: URL,
                        pinningMode: PinningMode? = nil,
                        urlsExcludedFromPinning: [String] = [],
                        decoder: JSONDecoder = .init(),
                        verbose: Bool = false
                    ) {
                        self.baseUrl = baseUrl
                        self.pinningMode = pinningMode
                        self.urlsExcludedFromPinning = urlsExcludedFromPinning
                        self.decoder = decoder
                        self.verbose = verbose
                    }
                
                \(raw: ClassBuilder.buildBeforeSendingBlockFunc(for: type, accessModifier: accessModifier))
                    
                \(raw: ClassBuilder.buildOnResponseBlockFunc(for: type, accessModifier: accessModifier))
                
                \(raw: functions + ClassBuilder.prepareBasicRequest(for: type))
                }
                """
    }
    
    private static func buildBeforeSendingBlockFunc(for type: ClassType, accessModifier: String) -> String {
        guard type == .service else {
            return """
                \(accessModifier)func addBeforeSendingBlock(for path: String? = nil, _ block: @escaping RequestHandler) {
                    addBeforeSendingBlockCallsCount += 1
                }
            """
        }
        
        return """
            \(accessModifier)func addBeforeSendingBlock(for path: String? = nil, _ block: @escaping RequestHandler) {
                var key = "all"
                if let path {
                    if #available(iOS 16, *) {
                        key = baseUrl.appending(path: path).absoluteString
                    } else {
                        key = baseUrl.appendingPathComponent(path).absoluteString
                    }
                }
                requestBlocks[key] = block
            }
        """
    }
    
    private static func buildOnResponseBlockFunc(for type: ClassType, accessModifier: String) -> String {
        guard type == .service else {
            return """
                \(accessModifier)func addOnResponseBlock(for path: String? = nil, _ block: @escaping ResponseHandler) {
                    addOnResponseBlockCallsCount += 1
                }
            """
        }
        
        return """
            \(accessModifier)func addOnResponseBlock(for path: String? = nil, _ block: @escaping ResponseHandler) {
                var key = "all"
                if let path {
                    if #available(iOS 16, *) {
                        key = baseUrl.appending(path: path).absoluteString
                    } else {
                        key = baseUrl.appendingPathComponent(path).absoluteString
                    }
                }
                responseBlocks[key] = block
            }
        """
    }
    
    static private func prepareBasicRequest(for type: ClassType) -> String {
        guard type == .service else { return "" }
        
        return """
            \n\nprivate func prepareBasicRequest(url: URL, method: String, queryItems: [QueryItem], headers: [String: Any]) -> URLRequest {
            var finalUrl = url
            
            if !queryItems.isEmpty {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                components.queryItems = queryItems.map {
                    $0.toUrlQueryItem()
                }
                finalUrl = components.url!
            }
            
            var request = URLRequest(url: finalUrl)
            request.httpMethod = method
            
            headers.forEach { key, value in
                request.addValue("\\(value)", forHTTPHeaderField: key)
            }
            
            return request
        }
        """
    }
}
