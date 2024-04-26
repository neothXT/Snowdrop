//
//  ClassBuilder.swift
//
//
//  Created by Maciej Burdzicki on 26/04/2024.
//

import SwiftSyntax

enum ClassType: String {
    case service = "Service"
    case mock = "ServiceMock"
}

struct ClassBuilder {
    static func printOutcome(type: ClassType, accessModifier: String, name: String, functions: String) -> DeclSyntax {
                """
                \(raw: accessModifier)class \(raw: name)\(raw: type.rawValue): \(raw: name), Service {
                    \(raw: accessModifier)let baseUrl: URL
                
                    \(raw: accessModifier)var requestBlocks: [String: RequestHandler] = [:]
                    \(raw: accessModifier)var responseBlocks: [String: ResponseHandler] = [:]
                
                    \(raw: accessModifier)required init(baseUrl: URL) {
                        self.baseUrl = baseUrl
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
                }
                """
    }
}
