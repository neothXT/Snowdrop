//
//  ClassBuilder.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 26/04/2024.
//

import SwiftSyntax

enum ClassType: String {
    case service = "Service"
    case mock = "ServiceMock"
}

struct ClassBuilder {
    static func build(type: ClassType, accessModifier: String, name: String, functions: String) -> DeclSyntax {
                """
                \(raw: accessModifier)class \(raw: name)\(raw: type.rawValue): \(raw: name), Service {
                    \(raw: accessModifier)let baseUrl: URL
                
                    \(raw: accessModifier)var requestBlocks: [String: RequestHandler] = [:]
                    \(raw: accessModifier)var responseBlocks: [String: ResponseHandler] = [:]
                
                    \(raw: accessModifier)var decoder: JSONDecoder
                    \(raw: accessModifier)var pinningMode: PinningMode?
                    \(raw: accessModifier)var urlsExcludedFromPinning: [String]
                
                    \(raw: accessModifier)required init(
                        baseUrl: URL,
                        pinningMode: PinningMode? = nil,
                        urlsExcludedFromPinning: [String] = [],
                        decoder: JSONDecoder = .init()
                    ) {
                        self.baseUrl = baseUrl
                        self.pinningMode = pinningMode
                        self.urlsExcludedFromPinning = urlsExcludedFromPinning
                        self.decoder = decoder
                    }
                
                    \(raw: accessModifier)func addBeforeSendingBlock(for path: String? = nil, _ block: @escaping RequestHandler) {
                        var key = "all"
                        if let path {
                            key = baseUrl.appending(path: path).absoluteString
                        }
                        requestBlocks[key] = block
                    }
                    
                    \(raw: accessModifier)func addOnResponseBlock(for path: String? = nil, _ block: @escaping ResponseHandler) {
                        var key = "all"
                        if let path {
                            key = baseUrl.appending(path: path).absoluteString
                        }
                        responseBlocks[key] = block
                    }
                
                \(raw: functions)
                
                    private func prepareBasicRequest(url: URL, method: String, queryItems: [QueryItem], headers: [String: Any]) -> URLRequest {
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
                }
                """
    }
}
